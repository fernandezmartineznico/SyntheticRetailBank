"""
Snowflake Connection Management
Handles Snowflake session creation and connection management
"""

import streamlit as st
from snowflake.snowpark import Session
from snowflake.snowpark.exceptions import SnowparkSQLException


@st.cache_resource
def get_snowflake_session():
    """
    Create and cache Snowflake session
    
    Returns:
        Session: Snowflake Snowpark session
    """
    try:
        # Get credentials from Streamlit secrets
        connection_parameters = {
            "account": st.secrets["snowflake"]["account"],
            "user": st.secrets["snowflake"]["user"],
            "password": st.secrets["snowflake"]["password"],
            "warehouse": st.secrets["snowflake"]["warehouse"],
            "database": st.secrets["snowflake"]["database"],
            "schema": st.secrets["snowflake"]["schema"],
            "role": st.secrets["snowflake"]["role"]
        }
        
        session = Session.builder.configs(connection_parameters).create()
        return session
    
    except KeyError as e:
        raise Exception(f"Missing Snowflake credential: {e}. Please configure .streamlit/secrets.toml")
    except Exception as e:
        raise Exception(f"Failed to connect to Snowflake: {e}")


def test_connection():
    """
    Test Snowflake connection
    
    Returns:
        bool: True if connection successful, False otherwise
    """
    try:
        session = get_snowflake_session()
        result = session.sql("SELECT CURRENT_VERSION()").collect()
        return len(result) > 0
    except Exception:
        return False


def execute_query(query: str):
    """
    Execute SQL query and return results as pandas DataFrame
    
    Args:
        query: SQL query string
        
    Returns:
        pandas.DataFrame: Query results
    """
    try:
        session = get_snowflake_session()
        df = session.sql(query).to_pandas()
        return df
    except SnowparkSQLException as e:
        raise Exception(f"SQL execution failed: {e}")
    except Exception as e:
        raise Exception(f"Query execution failed: {e}")

