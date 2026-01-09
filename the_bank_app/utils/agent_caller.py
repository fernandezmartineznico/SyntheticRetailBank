"""
Snowflake Cortex AI Agent REST API Caller
Handles agent invocation via REST API instead of SQL functions.
"""

import requests
import json
import snowflake.connector
import urllib3
import streamlit as st

# Disable SSL warnings for demo environment
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def call_agent_rest_api(session, agent_full_name: str, question: str, timeout: int = 60) -> dict:
    """
    Call Snowflake Cortex AI Agent using REST API.
    
    Args:
        session: Snowflake session object
        agent_full_name: Full agent name like "AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRM_CUSTOMER_360"
        question: Question to ask the agent
        timeout: Request timeout in seconds
        
    Returns:
        dict with keys: 'success', 'response', 'error', 'raw_stream'
    """
    result = {
        'success': False,
        'response': None,
        'error': None,
        'raw_stream': []
    }
    
    temp_conn = None  # Track connection for cleanup
    
    try:
        # Parse agent full name
        parts = agent_full_name.split('.')
        if len(parts) != 3:
            result['error'] = f"Invalid agent name format. Expected DATABASE.SCHEMA.AGENT_NAME, got {agent_full_name}"
            return result
        
        database, schema, agent_name = parts
        
        # Get connection and token
        # For LOCAL Streamlit, create a fresh connection using secrets.toml
        account = None
        token = None
        
        try:
            # Check if we have Streamlit secrets (local Streamlit)
            if hasattr(st, 'secrets') and 'snowflake' in st.secrets:
                secrets = st.secrets["snowflake"]
                account = secrets["account"]
                
                # Create a fresh connection to get a valid REST token
                # This is the SAME approach as test_single_agent.py
                config = {
                    "account": secrets["account"],
                    "user": secrets["user"],
                    "warehouse": secrets.get("warehouse"),
                    "database": secrets.get("database"),
                    "schema": secrets.get("schema"),
                    "role": secrets.get("role"),
                }
                
                # Add password (can be JWT token or regular password)
                if "password" in secrets:
                    config["password"] = secrets["password"]
                
                # Set authenticator if specified
                if "authenticator" in secrets:
                    config["authenticator"] = secrets["authenticator"]
                
                # Create connection and get REST token
                temp_conn = snowflake.connector.connect(**config)
                token = temp_conn.rest.token
                
                # Keep connection alive during request (don't close yet)
                
            # Fallback: try to extract from existing Snowpark session (for SiS)
            elif hasattr(session, '_conn') and session._conn:
                try:
                    raw_conn = session._conn._conn  # Get inner connector
                    
                    # Get account
                    cursor = raw_conn.cursor()
                    cursor.execute("SELECT CURRENT_ACCOUNT()")
                    account = cursor.fetchone()[0]
                    cursor.close()
                    
                    # Extract REST token
                    if hasattr(raw_conn, 'rest') and hasattr(raw_conn.rest, 'token'):
                        token = raw_conn.rest.token
                    else:
                        result['error'] = "Could not extract REST token from session"
                        return result
                except Exception as e:
                    result['error'] = f"Session token extraction failed: {e}"
                    return result
            else:
                result['error'] = "No Snowflake connection or secrets available"
                return result
            
            # Validate
            if not account or not token:
                result['error'] = f"Missing auth: account={bool(account)}, token={bool(token)}"
                return result
                
        except Exception as e:
            if temp_conn:
                temp_conn.close()
            result['error'] = f"Auth error: {str(e)}"
            return result
        
        # Build REST API URL
        if '.snowflakecomputing.com' not in account:
            base_url = f"https://{account}.snowflakecomputing.com"
        else:
            base_url = f"https://{account}"
        
        endpoint = f"/api/v2/databases/{database}/schemas/{schema}/agents/{agent_name}:run"
        url = base_url + endpoint
        
        # Headers (Snowflake Token format works best)
        headers = {
            "Authorization": f"Snowflake Token=\"{token}\"",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        # Payload
        payload = {
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": question
                        }
                    ]
                }
            ]
        }
        
        # Make request (streaming response)
        response = requests.post(
            url, 
            headers=headers, 
            json=payload, 
            timeout=timeout, 
            verify=False,  # SSL verification disabled for demo
            stream=True
        )
        
        if response.status_code != 200:
            result['error'] = f"HTTP {response.status_code}: {response.text}"
            return result
        
        # Handle Server-Sent Events (SSE) streaming response
        thinking_chunks = []
        text_chunks = []
        error_messages = []
        current_event = None
        
        for line in response.iter_lines():
            if line:
                decoded_line = line.decode('utf-8')
                result['raw_stream'].append(decoded_line)
                
                # Track event type
                if decoded_line.startswith('event: '):
                    current_event = decoded_line[7:].strip()
                    continue
                
                # Parse SSE format: "event: ..." and "data: ..."
                if decoded_line.startswith('data: '):
                    try:
                        data_json = decoded_line[6:].strip()
                        if data_json == '[DONE]':
                            break
                        
                        data = json.loads(data_json)
                        
                        # Separate thinking from final text response based on event type
                        if 'text' in data:
                            text_content = data['text']
                            
                            # Only collect from specific event types
                            if current_event == 'response.thinking.delta':
                                # This is internal reasoning - collect separately
                                thinking_chunks.append(text_content)
                            elif current_event == 'response.text.delta':
                                # This is the final answer to show user
                                text_chunks.append(text_content)
                        
                        # Check for error messages
                        if 'error' in data:
                            error_messages.append(data.get('error', {}).get('message', str(data['error'])))
                        
                        # Check for status messages
                        if 'status' in data and data['status'] == 'error':
                            error_messages.append(data.get('message', 'Unknown error'))
                    
                    except json.JSONDecodeError as je:
                        # Skip non-JSON lines
                        pass
        
        # Check for errors first
        if error_messages:
            result['error'] = ' | '.join(error_messages)
            return result
        
        # Combine all text chunks (excluding thinking)
        if text_chunks:
            result['response'] = ''.join(text_chunks)
            result['thinking'] = ''.join(thinking_chunks) if thinking_chunks else None
            result['success'] = True
        else:
            result['error'] = f"No response received from agent (empty stream). Received {len(result['raw_stream'])} lines, event types: {current_event}"
        
        # Clean up temporary connection if we created one
        if temp_conn:
            temp_conn.close()
        
        return result
    
    except requests.exceptions.Timeout:
        if temp_conn:
            temp_conn.close()
        result['error'] = f"Request timeout after {timeout}s"
        return result
    
    except Exception as e:
        if temp_conn:
            temp_conn.close()
        result['error'] = f"Error calling agent: {str(e)}"
        return result


def parse_sse_stream_for_analysis(raw_stream: list) -> dict:
    """
    Parse SSE stream for detailed analysis.
    
    Returns:
        {
            'thinking_blocks': [...],
            'query_attempts': [...],
            'text_responses': [...],
            'errors': [...]
        }
    """
    structured = {
        'thinking_blocks': [],
        'query_attempts': [],
        'text_responses': [],
        'errors': []
    }
    
    current_event = None
    
    for line in raw_stream:
        if line.startswith('event: '):
            current_event = line[7:].strip()
            continue
        
        if line.startswith('data: '):
            try:
                data_json = line[6:].strip()
                if data_json == '[DONE]':
                    continue
                
                data = json.loads(data_json)
                
                # Extract thinking
                if current_event and 'thinking' in current_event:
                    if 'text' in data:
                        structured['thinking_blocks'].append(data['text'])
                
                # Extract queries
                if current_event and 'tool_use' in current_event:
                    if 'input' in data and 'query' in data.get('input', {}):
                        structured['query_attempts'].append(data['input']['query'])
                
                # Extract text responses
                if current_event and 'text' in current_event:
                    if 'text' in data:
                        structured['text_responses'].append(data['text'])
                
                # Extract errors
                if 'text' in data:
                    text_lower = data['text'].lower()
                    if any(kw in text_lower for kw in ["can't answer", 'ambiguous', 'unclear', 'error']):
                        structured['errors'].append(data['text'])
            
            except json.JSONDecodeError:
                pass
    
    return structured

