-- ============================================================================
-- 750_CRM_INTELLIGENCE_AGENT.sql
-- CRM Customer 360° Intelligence AI Agent (Multi-View)
-- ============================================================================
-- Purpose: AI agent for comprehensive customer & advisor intelligence including
--          customer profiles, compliance/risk, lifecycle, address data, and
--          advisor performance metrics
-- Uses: 
--   1. CRMA_SV_CUSTOMER_360 (customer 360° view with advisor assignments)
--   2. EMPA_SV_EMPLOYEE_ADVISOR (advisor performance & client portfolio metrics)
-- Business Value: Foundation for all CRM operations + advisor capacity planning
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- Drop existing CRM_Customer_360 if it exists
DROP AGENT IF EXISTS CRM_Customer_360;

-- Create CRM Intelligence Agent
CREATE OR REPLACE AGENT CRM_Customer_360
  COMMENT = 'CRM Intelligence Agent - Customer 360° & Advisor Performance Assistant (Multi-View)'
  PROFILE = '{"display_name": "CRM Customer 360", "avatar": "", "color": "#1E88E5"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration: {}

  instructions:
    sample_questions:
      - question: "Show me all PLATINUM customers in Switzerland"
      - question: "Which customers require PEP review?"
      - question: "Analyze customer account holdings and product mix"
      - question: "How many customers per country?"
      - question: "Show me at-risk customers with high churn probability in Zurich"
      - question: "Which customers are dormant with addresses in high-risk jurisdictions?"
      - question: "Show me top 10 advisors by total AUM"
      - question: "Which advisors have the highest client retention rates?"
      - question: "List all customers assigned to advisor EMP_00055"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: CRM_Customer_360
        description: |
          # CRM Intelligence Agent - Customer 360° Assistant

          ## Agent Description

          I am your **CRM Intelligence Agent**, providing instant access to comprehensive customer AND advisor intelligence across our entire banking relationship portfolio. I help you understand customer profiles, assess risk, monitor compliance, analyze advisor performance, and make data-driven relationship management decisions.

          ## What I Can Help You With

          ### **Customer Intelligence**
          - Find customers by name, ID, or demographic attributes
          - View complete customer profiles with 360° intelligence
          - Analyze customer segmentation by tier, country, or employment
          - Track customer onboarding dates and relationship history

          ### **Financial & Employment Profiles**
          - Review customer employment status, employer, and income ranges
          - Analyze account tier distribution (STANDARD, SILVER, GOLD, PLATINUM, PREMIUM)
          - Examine customer financial profiles and credit score bands
          - Identify customers by industry, position, or employment type

          ### **Risk & Compliance**
          - Screen customers for PEP (Politically Exposed Persons) matches
          - Check sanctions watchlist screening results
          - Review overall risk ratings (NO_RISK, LOW, MEDIUM, HIGH, CRITICAL)
          - Identify high-risk customers requiring enhanced due diligence
          - Monitor compliance review flags and requirements

          ### **Account Portfolio Analysis**
          - Analyze customer account holdings and product mix
          - Review checking, savings, business, and investment account counts
          - Examine multi-currency portfolios and currency exposure
          - Identify cross-sell and upsell opportunities

          ### **Fraud & Anomaly Detection**
          - Flag customers with suspicious transaction patterns
          - Identify anomalous behavior indicators
          - Review fraud red flags and investigation priorities
          - Support AML (Anti-Money Laundering) investigations

          ### **Geographic & Address Intelligence**
          - Search customers by country, city, state, or postal code
          - View current address details with validation status
          - Track address changes and identify high-risk jurisdictions
          - Retrieve customer contact details (email, phone, preferred contact method)
          - Analyze customer distribution by geography
          - Support regulatory reporting and customer communications
          
          ### **Customer Lifecycle & Engagement**
          - Monitor customer lifecycle stages (ONBOARDING, ACTIVE, AT_RISK, DORMANT, CHURNED)
          - Track churn probability and identify at-risk customers
          - Analyze customer lifetime value and revenue metrics
          - Review engagement scores and contact frequency
          - Identify dormant accounts requiring reactivation
          - Monitor days since last transaction and contact
          
          ### **Advisor Performance & Capacity**
          - View advisor client portfolios and AUM (assets under management)
          - Analyze advisor performance metrics (retention rates, client counts)
          - Identify advisors by location, qualifications, and certifications
          - Track premium/platinum client distribution across advisors
          - Monitor high-risk client assignments
          - Review client-advisor relationships and assignments
          - Support advisor capacity planning and workload balancing

          ### **Business Intelligence Queries**
          
          **Customer Queries:**
          - "Show me all PLATINUM customers in Switzerland"
          - "Which customers require PEP review?"
          - "Find high-risk customers with anomalous transactions"
          - "What is our customer distribution by account tier?"
          - "Show me customers onboarded in the last 90 days"
          - "List customers with investment accounts in multiple currencies"
          - "Which customers are at high churn risk with addresses in high-risk jurisdictions?"
          - "Show me dormant PLATINUM customers in Zurich"
          - "Find customers with multiple address changes in the last year"
          
          **Advisor Queries:**
          - "Show me top 10 advisors by total AUM"
          - "Which advisors have the highest client retention rates?"
          - "List all customers assigned to advisor EMP_00055"
          - "Find advisors in Zurich managing more than 150 clients"
          - "Which advisors have the most premium clients?"
          - "Show me advisors with low capacity utilization"
          - "Compare AUM across advisors in Switzerland vs Germany"

          ## Data Coverage

          ### Customer Data (70+ attributes)
          - **Identity**: Customer ID, full name, date of birth, nationality
          - **Contact**: Email, phone, preferred contact method
          - **Employment**: Employer, position, employment type, income range
          - **Address**: Current street address, city, state, postal code, country, validation status, high-risk jurisdiction flag
          - **Accounts**: Total accounts, account types, currencies, balances
          - **Risk**: Credit score, risk classification, risk rating, risk score
          - **Compliance**: PEP screening, sanctions screening, review flags
          - **Lifecycle**: Lifecycle stage, churn probability, engagement score, days since last transaction
          - **Status**: Current customer status, dormancy flag, at-risk flag
          - **Anomalies**: Fraud indicators, suspicious activity flags, anomaly counts
          - **Advisor Assignment**: Current advisor ID, assignment start date
          
          ### Advisor Data (30+ attributes)
          - **Identity**: Employee ID, full name, email, phone
          - **Employment**: Hire date, position level, manager, performance rating
          - **Location**: Country, region, office location
          - **Qualifications**: Languages spoken, certifications
          - **Performance**: Total clients, AUM, retention rate, active/closed clients
          - **Portfolio**: Accounts managed, balances by type, premium clients, high-risk clients

          ## Key Features

           **Natural Language Understanding**: Ask questions in plain English (or your preferred language)  
           **Rich Synonym Support**: Understands 200+ alternative terms (e.g., "client" = "customer", "DOB" = "date of birth")  
           **Real-Time Data**: All responses reflect the latest customer intelligence  
           **Compliance-Ready**: Instant access to PEP/sanctions screening and risk ratings  
           **Business-Friendly**: No SQL knowledge required - just ask naturally  

          ## Ideal For

          - **Relationship Managers**: Customer profile reviews and relationship insights
          - **Compliance Officers**: PEP/sanctions screening and risk assessment
          - **Risk Analysts**: Customer risk scoring and portfolio analysis
          - **Marketing Teams**: Customer segmentation and targeting
          - **AML Investigators**: Fraud detection and anomaly investigation
          - **HR & Talent Management**: Advisor performance reviews and capacity planning
          - **Operations Managers**: Workload distribution and resource allocation
          - **Executive Leadership**: Customer & advisor portfolio reporting and analytics

          ## Data Freshness

          Both customer and advisor data are refreshed **hourly** via dynamic tables, ensuring you always have access to current customer and advisor intelligence.

          ---

          **Ready to explore your customer and advisor data? Just ask me anything!**

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Advisor_Performance
        description: |
          # Advisor Performance & Client Relationship Management
          
          ## What This Tool Provides
          
          Access to **advisor-level metrics** aggregated from customer data, including:
          
          ### **Advisor Intelligence**
          - Find advisors by name, ID, office location, or region
          - View advisor employment details (hire date, position level, manager)
          - Check advisor qualifications (certifications, languages spoken)
          - Review advisor performance ratings
          
          ### **Performance Metrics**
          - Total clients managed per advisor
          - Total AUM (assets under management) per advisor
          - Average client balance
          - Client retention rates
          - Active vs closed client counts
          
          ### **Portfolio Analysis**
          - Total accounts managed
          - Breakdown by account type (checking, savings, investment)
          - Premium/platinum client counts
          - High-risk client counts
          
          ### **Common Queries**
          - "Show me top advisors by AUM"
          - "Which advisors have the best retention rates?"
          - "List advisors in Zurich with capacity for new clients"
          - "How many premium clients does each advisor manage?"
          - "Show me advisors with the most high-risk clients"
          
          All advisor data is refreshed **hourly** via dynamic tables.

  tool_resources:
    CRM_Customer_360:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_SV_CUSTOMER_360
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    Advisor_Performance:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.EMPA_SV_EMPLOYEE_ADVISOR
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
  $$;

-- Grant permissions on the agent
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRM_Customer_360 TO ROLE ACCOUNTADMIN;
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRM_Customer_360 TO ROLE PUBLIC;

-- Create Snowflake Intelligence object if it doesn't exist
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Grant usage on Snowflake Intelligence object to users
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Add agent to Snowflake Intelligence (makes it visible in the UI)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRM_Customer_360;

-- Verify creation
--SHOW AGENTS IN SCHEMA AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001;
--SHOW SNOWFLAKE INTELLIGENCES;
--SELECT 'CRM_Customer_360 agent created successfully! Refresh your browser at https://ai.snowflake.com/sfseeurope/demo_mdaeppen' AS STATUS;

