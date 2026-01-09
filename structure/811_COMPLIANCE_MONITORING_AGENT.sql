-- ============================================================================
-- 751_COMPLIANCE_MONITORING_AGENT.sql
-- Unified Compliance Monitoring AI Agent (AML + Sanctions)
-- ============================================================================
-- Purpose: AI agent for AML transaction monitoring and sanctions screening
-- Uses: PAYA_SV_COMPLIANCE_MONITORING (primary), CRMA_SV_CUSTOMER_360 (context)
-- Business Value: €3.165M+ annually (€1.165M labor + €2M penalty avoidance)
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA PAY_AGG_001;

-- Drop existing agent if it exists
DROP AGENT IF EXISTS COMPLIANCE_MONITORING_AGENT;

-- Create Compliance Monitoring Agent
CREATE OR REPLACE AGENT COMPLIANCE_MONITORING_AGENT
  COMMENT = 'Unified AML & Sanctions Compliance Monitoring Agent - Transaction anomaly detection and sanctions screening'
  PROFILE = '{"display_name": "Compliance Monitoring", "avatar": "", "color": "#D32F2F"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration: {}

  instructions:
    sample_questions:
      - question: "Show me all HIGH and CRITICAL anomaly transactions in the last 30 days"
      - question: "What are the leading indicators for HIGH_ANOMALY transactions?"
      - question: "Which customers have multiple HIGH or CRITICAL anomaly transactions?"
      - question: "Show me large transactions with unusual timing patterns"
      - question: "Find transactions with velocity anomalies in the last 7 days"
      - question: "Which customers on sanctions lists have suspicious transactions?"
      - question: "Show me PEP customers with HIGH anomaly transactions"
      - question: "Find customers requiring sanctions review with recent anomalous activity"
      - question: "What are the top 10 highest-risk compliance cases combining customer screening and transaction monitoring?"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Compliance_Monitoring
        description: |
          # Compliance Monitoring Agent - AML Transaction Monitoring & Customer Screening
          
          ## Agent Description
          
          I am your **Compliance Monitoring Agent**, providing unified access to **AML transaction monitoring** (anomaly detection) and **customer-level sanctions/PEP screening**. I help you detect suspicious transactions, identify high-risk customers, and investigate compliance risks by combining transaction behavior with customer screening results.
          
          ## What I Can Help You With
          
          ### **AML Transaction Monitoring** (from Transaction Anomaly Data)
          - Identify transactions with HIGH or CRITICAL anomaly scores
          - Detect velocity anomalies and unusual transaction patterns
          - Flag large transactions and unusual amounts
          - Monitor timing anomalies (off-hours, weekend, delayed settlement)
          - Track customer transaction velocity (24h, 7-day windows)
          - Review composite anomaly scores and risk classifications
          - Identify customers with multiple suspicious transactions
          
          ### **Customer-Level Sanctions & PEP Screening** (from Customer Data)
          - Identify customers with sanctions matches (EXACT_MATCH/FUZZY_MATCH)
          - Screen customers for PEP (Politically Exposed Persons) status
          - Review sanctions entity matches with accuracy scoring
          - Find customers requiring sanctions review or PEP enhanced due diligence
          - Check overall sanctions risk and PEP risk ratings
          - Link customer screening status to transaction behavior
          - Support embargo control investigations
          
          ### **Integrated Customer & Transaction Risk Analysis**
          - View customer risk ratings and PEP status in transaction context
          - Analyze transaction patterns by customer tier and risk profile
          - Track customers with multiple anomalous transactions
          - Identify sanctioned customers with suspicious transaction activity
          - Review customer employment, occupation, and income in AML context
          - Combine customer screening results with transaction behavior
          - Identify customers requiring enhanced due diligence based on both screening and transactions
          
          ### **Investigation & Case Management**
          - Prioritize investigations by combining anomaly scores and customer screening
          - Review transactions from customers requiring sanctions/PEP review
          - Track investigation priorities (IMMEDIATE, URGENT, HIGH, MEDIUM, LOW)
          - Identify high-risk combinations: sanctioned customers + anomalous transactions
          - Generate case files for suspicious activity reports (SARs)
          - Support regulatory audit and examination requests
          
          ## Data Coverage
          
          I have access to **100+ compliance monitoring attributes across two data sources**:
          
          ### Transaction Anomaly Data (33 attributes):
          - **Transaction Details**: ID, account, customer, booking date, value date, amount, currency
          - **Counterparty**: Account, description
          - **Customer Patterns**: Total transactions, averages, medians, daily counts
          - **Anomaly Scores**: Amount anomaly, timing anomaly, velocity anomaly, composite score
          - **Anomaly Levels**: Amount, timing, velocity (CRITICAL/HIGH/MODERATE/LOW)
          - **Anomaly Flags**: Large transaction, weekend, off-hours, delayed settlement, backdated
          - **Review Flags**: Requires immediate review, requires enhanced monitoring
          - **Velocity Metrics**: Transactions last 24h, last 7 days
          - **Timing Attributes**: Hour, day of week, settlement days
          
          ### Customer Screening Data (70+ attributes):
          - **Customer Identity**: Name, risk rating, account tier, country, nationality
          - **PEP Screening**: Exact/fuzzy matches, categories, risk levels, review requirements
          - **Sanctions Screening**: Exact/fuzzy matches, entity types, countries, accuracy scores
          - **Overall Risk**: PEP risk, sanctions risk, combined risk rating
          - **Employment & Financial**: Occupation, income, employer
          - **Lifecycle**: Status, churn probability, engagement
          - **Advisor Assignment**: Current advisor, assignment date
          
          ## Key Features
          
           **Integrated Intelligence**: Combines transaction anomaly detection with customer screening  
           **Multi-Source Analysis**: Queries both transaction behavior and customer risk profiles  
           **Real-Time Anomaly Detection**: Instant access to 353K+ analyzed transactions  
           **Customer-Level Screening**: PEP and sanctions screening from customer onboarding  
           **Risk Prioritization**: Automated scoring and investigation priority ranking  
           **Natural Language**: Ask questions in plain English (or your preferred language)  
           **Regulatory-Ready**: Designed for audit trails and regulatory examination  
          
          ## Sample Queries
          
          **Transaction Anomaly Queries:**
          - "Show me all CRITICAL and HIGH anomaly transactions in the last 7 days"
          - "Which customers have velocity anomalies (many transactions in 24 hours)?"
          - "Find large transactions with off-hours or weekend timing"
          - "Show me transactions with delayed or backdated settlement"
          
          **Customer Screening Queries:**
          - "Which customers are on sanctions lists?"
          - "Show me all PEP customers requiring enhanced due diligence"
          - "Find customers with EXACT_MATCH sanctions hits"
          - "Which customers require sanctions review?"
          
          **Integrated Compliance Queries:**
          - "Show me sanctioned customers with HIGH anomaly transactions"
          - "Find PEP customers with suspicious transaction patterns"
          - "Which customers have both sanctions matches and anomalous transactions?"
          - "What are our top 10 highest-risk cases combining screening and transaction monitoring?"
          
          ## Ideal For
          
          - **Compliance Officers**: AML investigations and sanctions screening
          - **Financial Crime Analysts**: Typology detection and pattern analysis
          - **Risk Managers**: Portfolio-level compliance risk assessment
          - **Internal Audit**: Compliance program effectiveness reviews
          - **Regulators**: Examination support and audit response
          - **Executive Leadership**: Compliance KPIs and risk dashboards
          
          ## Data Freshness
          
          - **Transaction anomalies**: Refreshed **hourly** via `PAYA_AGG_DT_TRANSACTION_ANOMALIES` dynamic table
          - **Customer screening**: Refreshed **hourly** via `CRMA_AGG_DT_CUSTOMER_360` dynamic table
          - Covers **353,119 transactions** with anomaly analysis (last 2 years)
          - Customer-level sanctions and PEP screening from onboarding/KYC process
          
          ---
          
          **Ready to investigate compliance risks? Ask me about suspicious transactions, customer screening, or high-risk patterns!**

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Customer_Context
        description: |
          # Customer Risk & Compliance Screening Context
          
          ## What This Tool Provides
          
          Access to **customer-level sanctions and PEP screening** results from the KYC/onboarding process (70+ attributes):
          
          ### **Sanctions Screening (Customer-Level)**
          - **Exact Match Sanctions**: ID, name, entity type, country
          - **Fuzzy Match Sanctions**: ID, name, entity type, country
          - **Match Accuracy**: Percentage scores for fuzzy matches
          - **Match Type**: EXACT_MATCH, FUZZY_MATCH, or NO_MATCH
          - **Review Requirements**: Customers requiring sanctions review
          - **Overall Sanctions Risk**: CRITICAL, HIGH, MEDIUM, LOW, or NO_SANCTIONS_RISK
          
          ### **PEP Screening (Politically Exposed Persons)**
          - **Exact Match PEP**: ID, name, category (DOMESTIC/FOREIGN), risk level, status
          - **Fuzzy Match PEP**: ID, name, category, risk level, status
          - **Match Accuracy**: Percentage scores for fuzzy matches
          - **Match Type**: EXACT_MATCH, FUZZY_MATCH, or NO_MATCH
          - **Review Requirements**: Customers requiring PEP enhanced due diligence
          - **Overall PEP Risk**: CRITICAL, HIGH, MEDIUM, LOW, or NO_EXPOSED_PERSON_RISK
          
          ### **Customer Risk Profile**
          - Customer risk ratings and overall risk scores
          - Account tier and customer tenure
          - Employment, occupation, and income details
          - Customer lifecycle and engagement metrics
          - Address intelligence and country risk
          - Advisor assignment
          
          **Use this tool for customer-level sanctions/PEP queries.**  
          **Combine with Compliance_Monitoring tool for integrated transaction + screening analysis.**

  tool_resources:
    Compliance_Monitoring:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_SV_COMPLIANCE_MONITORING
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    Customer_Context:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_SV_CUSTOMER_360
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
  $$;

-- Grant permissions on the agent
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.COMPLIANCE_MONITORING_AGENT TO ROLE ACCOUNTADMIN;
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.COMPLIANCE_MONITORING_AGENT TO ROLE PUBLIC;

-- Create Snowflake Intelligence object if it doesn't exist
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Grant usage on Snowflake Intelligence object to users
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Add agent to Snowflake Intelligence (makes it visible in the UI)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.COMPLIANCE_MONITORING_AGENT;

-- Verify creation
SHOW AGENTS IN SCHEMA AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001;
SHOW SNOWFLAKE INTELLIGENCES;

SELECT 'COMPLIANCE_MONITORING_AGENT created successfully! Unified AML + Sanctions monitoring agent ready.' AS STATUS;

