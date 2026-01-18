-- ============================================================================
-- 865_LOAN_PORTFOLIO_AGENT.sql
-- Retail Loans & Mortgages Portfolio AI Agent
-- ============================================================================
-- Purpose: AI agent for loan portfolio monitoring, LTV analysis, application
--          funnel tracking, affordability assessment, and compliance screening
-- Uses: 
--   1. LOAS_SV_PORTFOLIO_CURRENT (semantic view - portfolio summary)
--   2. LOAS_SV_LTV_DISTRIBUTION (semantic view - LTV risk analysis)
--   3. LOAS_SV_APPLICATION_FUNNEL (semantic view - conversion metrics)
--   4. LOAS_SV_AFFORDABILITY_ANALYSIS (semantic view - DTI/DSTI analysis)
--   5. LOAS_SV_COMPLIANCE_SCREENING (semantic view - sanctions/PEP integration)
-- Business Value: Real-time portfolio monitoring, credit risk management,
--                 regulatory compliance (FINMA, FCA, BaFin), lending strategy
-- Regulatory Basis: MCD (Mortgages Credit Directive), CCD (Consumer Credit),
--                   FINMA Mortgage Lending Guidelines, EBA Loan Origination
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- Drop existing agent if it exists
DROP AGENT IF EXISTS LOAN_PORTFOLIO_AGENT;

-- Create Retail Loans & Mortgages Portfolio Agent
CREATE OR REPLACE AGENT LOAN_PORTFOLIO_AGENT
  COMMENT = 'Retail Loans & Mortgages Portfolio Agent - Portfolio monitoring, LTV analysis, application funnel, affordability assessment, compliance screening'
  PROFILE = '{"display_name": "Loan Portfolio", "avatar": "", "color": "#1565C0"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration: {}

  instructions:
    sample_questions:
      - question: "What is our total loan exposure and average loan amount?"
      - question: "Show me the LTV distribution across our portfolio"
      - question: "How many loans are in the high LTV bucket (>80%)?"
      - question: "What is our application approval rate by country?"
      - question: "Show me the application funnel by product type"
      - question: "What is the average DTI ratio for approved loans?"
      - question: "How many applications are on compliance hold?"
      - question: "Show me all loans with vulnerable customer flags"
      - question: "Which country has the highest approval rate?"
      - question: "What is the affordability pass rate for UK mortgages?"
      - question: "Are there any applications with sanctions or PEP hits?"
      - question: "Show me portfolio breakdown by country and product"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Portfolio_Summary
        description: |
          # Loan Portfolio Summary - Real-Time Portfolio Monitoring
          
          ## Agent Description
          
          I am your **Retail Loans & Mortgages Portfolio Agent**, providing real-time monitoring of loan origination and portfolio performance across Switzerland, UK, and Germany. I help Retail Banking teams monitor application volumes, manage credit risk, track LTV concentration, assess affordability compliance, and integrate with sanctions/PEP screening for regulatory compliance.
          
          ## What I Can Help You With
          
          ### **Portfolio Monitoring**
          - Monitor total loan exposure by product type (mortgages, personal loans)
          - Track loan counts and average loan amounts
          - Analyze portfolio composition by country and product
          - Review application status distribution (approved, declined, under review)
          - Monitor portfolio growth and origination trends
          - Identify largest and smallest loan exposures
          
          ### **Product Analysis**
          - Compare mortgage vs personal loan volumes
          - Analyze average loan terms by product type
          - Review product mix across different markets
          - Track product-specific approval rates
          - Monitor product concentration risk
          
          ### **Country/Market Analysis**
          - Compare portfolio across Switzerland (CHE), UK (GBR), Germany (DEU), Portugal (PRT)
          - Analyze market-specific lending patterns
          - Review country-specific approval rates
          - Monitor regulatory exposure by jurisdiction
          - Track cross-border portfolio diversification
          
          ### **Application Status Tracking**
          - Monitor approved, declined, and under-review applications
          - Track application volumes over time
          - Analyze status distribution by product and country
          - Identify bottlenecks in application processing
          - Support operational capacity planning
          
          ## Data Coverage
          
          ### Portfolio Metrics (Aggregated by Product/Country/Status)
          - **Volume Metrics**: Loan count, total exposure, average/min/max loan amounts
          - **Product Dimensions**: Product type (MORTGAGE, PERSONAL_LOAN)
          - **Geographic Dimensions**: Country codes (CHE, GBR, DEU, PRT)
          - **Status Dimensions**: Application status (APPROVED, DECLINED, UNDER_REVIEW)
          - **Term Metrics**: Average loan term in months
          - **Data Quality**: Calculation timestamp (60-minute refresh)
          
          ## Sample Queries
          
          ### Portfolio Overview
          - "What is our total loan exposure?"
          - "How many loans do we have in the portfolio?"
          - "Show me portfolio breakdown by product type"
          - "What is the average loan amount?"
          - "Show me the largest loan in the portfolio"
          
          ### Country Analysis
          - "Show me portfolio by country"
          - "How many loans do we have in Switzerland?"
          - "Compare loan volumes between UK and Germany"
          - "What is the average loan amount in CHE?"
          
          ### Product Analysis
          - "Show me mortgage vs personal loan volumes"
          - "What is the average term for mortgages?"
          - "How much exposure do we have in mortgages?"
          
          ### Status Analysis
          - "How many approved applications do we have?"
          - "Show me declined applications by country"
          - "What percentage of applications are under review?"
          
          ## Ideal For
          
          - **Retail Banking Leadership**: Portfolio performance and strategic planning
          - **Credit Risk Management**: Exposure monitoring and risk assessment
          - **Loan Operations**: Application pipeline management
          - **Product Management**: Product mix analysis and optimization
          - **Country Managers**: Market-specific performance tracking
          - **Finance/Treasury**: Balance sheet planning and forecasting
          
          ## Data Freshness
          
          Portfolio data is refreshed **every 60 minutes** via dynamic tables, providing near real-time monitoring for operational decision-making and risk management.
          
          ---
          
          **Ready to monitor loan portfolio? Ask me about exposures, product mix, or country performance!**

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: LTV_Risk_Analysis
        description: |
          # LTV Distribution & Risk Concentration - Credit Risk Monitoring
          
          ## What This Tool Provides
          
          Detailed **Loan-to-Value (LTV) distribution** analysis for credit risk management:
          
          ### **LTV Risk Intelligence**
          - View LTV distribution across 6 risk buckets (0-50%, 50-60%, 60-70%, 70-80%, 80-90%, >90%)
          - Monitor high LTV concentration (>80% LTV = higher credit risk)
          - Analyze average LTV by bucket
          - Track collateral values supporting loan portfolio
          - Calculate portfolio concentration in each LTV band
          
          ### **Credit Risk Assessment**
          - **0-50% LTV**: Very low risk - strong equity cushion
          - **50-60% LTV**: Low risk - adequate collateral coverage
          - **60-70% LTV**: Moderate risk - standard lending
          - **70-80% LTV**: Elevated risk - requires monitoring
          - **80-90% LTV**: High risk - regulatory thresholds (FINMA 80% owner-occupied)
          - **>90% LTV**: Very high risk - may breach regulatory limits
          
          ### **Regulatory Compliance**
          - **Switzerland (FINMA)**: Max 80% LTV for owner-occupied, 75% for buy-to-let
          - **UK (FCA)**: Max 90% LTV for owner-occupied (Consumer Duty)
          - **Germany (BaFin)**: Max 85% LTV typical for residential mortgages
          - Monitor portfolio concentration above regulatory thresholds
          - Support stress testing and scenario analysis
          
          ### **Portfolio Risk Metrics**
          - Total loan amount in each LTV bucket
          - Total collateral value by bucket
          - Average LTV within each band
          - Percentage of loans in each bucket (concentration risk)
          - Number of loans requiring additional monitoring (high LTV)
          
          ### **Common Queries**
          - "Show me LTV distribution across the portfolio"
          - "How many loans are in the high LTV bucket (>80%)?"
          - "What is our average LTV?"
          - "How much exposure do we have above 80% LTV?"
          - "Show me collateral values by LTV bucket"
          - "What percentage of loans are in the 70-80% LTV range?"
          - "Which LTV bucket has the most concentration?"
          
          Data refreshed **hourly** for credit risk monitoring.

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Application_Funnel
        description: |
          # Application Funnel & Conversion Metrics - Origination Performance
          
          ## What This Tool Provides
          
          **Application pipeline and conversion analysis** by product, country, and channel:
          
          ### **Funnel Intelligence**
          - Track total applications received
          - Monitor approved, declined, and under-review volumes
          - Calculate approval and decline rates
          - Analyze conversion by product type
          - Compare performance across countries
          - Evaluate channel effectiveness (email, portal, branch, broker)
          
          ### **Conversion Metrics**
          - **Approval Rate**: Approved applications / Total applications
          - **Decline Rate**: Declined applications / Total applications
          - **Pending Rate**: Under review / Total applications
          - Average requested loan amount by status
          - Identify bottlenecks in application processing
          
          ### **Channel Performance**
          - Compare EMAIL vs PORTAL vs BRANCH vs BROKER channels
          - Analyze channel-specific approval rates
          - Monitor average loan size by channel
          - Support channel strategy and marketing decisions
          - Optimize broker partnerships based on conversion
          
          ### **Market Performance**
          - Compare approval rates across Switzerland, UK, Germany, Portugal
          - Identify market-specific credit quality patterns
          - Monitor country-specific decline reasons
          - Support country-level credit policy adjustments
          
          ### **Product Performance**
          - Compare mortgage vs personal loan conversion rates
          - Analyze product-specific application volumes
          - Monitor average loan amounts by product
          - Support product strategy and risk appetite decisions
          
          ### **Common Queries**
          - "What is our overall approval rate?"
          - "Show me the application funnel by country"
          - "Which channel has the highest approval rate?"
          - "How many applications are currently under review?"
          - "Compare approval rates for mortgages vs personal loans"
          - "Show me declined applications by country"
          - "What is the approval rate for UK mortgages?"
          - "Which country has the most applications?"
          
          Data refreshed **hourly** for operational monitoring.

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Affordability_Assessment
        description: |
          # Affordability Analysis - DTI/DSTI Compliance Monitoring
          
          ## What This Tool Provides
          
          **Affordability assessment outcomes** and DTI/DSTI analysis by country:
          
          ### **Affordability Intelligence**
          - Monitor affordability pass/fail rates by country
          - Analyze average Debt-to-Income (DTI) ratios
          - Track Debt Service-to-Income (DSTI) metrics
          - Review average gross monthly income
          - Monitor average monthly debt obligations
          - Support responsible lending compliance
          
          ### **Regulatory Thresholds**
          - **Switzerland (FINMA)**: Max 33% DSTI with 5% imputed rate stress test
          - **UK (FCA)**: Max 45% DTI for affordability (Consumer Duty)
          - **Germany (BaFin)**: Max 40% DSTI typical for residential mortgages
          - Monitor portfolio compliance with country-specific rules
          - Support stress testing and scenario analysis
          
          ### **DTI vs DSTI**
          - **DTI (Debt-to-Income)**: Total debt obligations / Gross income
          - **DSTI (Debt Service-to-Income)**: Loan payment + existing debts / Gross income
          - DSTI includes hypothetical loan payment for affordability test
          - Used for responsible lending and consumer protection
          
          ### **Assessment Metrics**
          - Number of affordability assessments performed
          - Pass vs fail counts by country
          - Average DTI and DSTI ratios
          - Average income levels by country
          - Average existing debt obligations
          - Affordability pass rate percentage
          
          ### **Responsible Lending**
          - Monitor adherence to affordability rules
          - Identify customers with high debt burdens
          - Support vulnerable customer identification
          - Demonstrate compliance with Consumer Duty (UK FCA)
          - Prepare for regulatory examinations
          
          ### **Common Queries**
          - "What is our affordability pass rate?"
          - "Show me average DTI ratio by country"
          - "How many affordability assessments have we performed?"
          - "What is the average DSTI for UK applications?"
          - "Show me affordability pass/fail breakdown by country"
          - "What is the average monthly income for approved loans?"
          - "How many assessments failed affordability?"
          - "Compare affordability pass rates across countries"
          
          Data refreshed **hourly** for compliance monitoring.

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Compliance_Screening
        description: |
          # Compliance & Screening Integration - Sanctions/PEP Monitoring
          
          ## What This Tool Provides
          
          **Loan applications linked to sanctions and PEP screening** for compliance:
          
          ### **Compliance Intelligence**
          - View all loan applications with customer compliance status
          - Monitor sanctions screening hits (OFAC, EU, UN)
          - Track Politically Exposed Persons (PEP) flags
          - Review overall risk ratings (CRITICAL, HIGH, MEDIUM, LOW)
          - Identify vulnerable customer flags
          - Monitor applications on compliance hold
          - Support KYC/CDD requirements
          
          ### **Sanctions Screening**
          - Identify customers with sanctions matches
          - Review sanctioning authorities (OFAC, EU, UN)
          - Monitor sanctions risk scores
          - Track sanctioned entity names
          - Support sanctions compliance and regulatory reporting
          - Prevent prohibited lending to sanctioned individuals
          
          ### **PEP Screening**
          - Identify Politically Exposed Persons in loan portfolio
          - Review PEP categories (DOMESTIC, FOREIGN, INTERNATIONAL)
          - Monitor PEP risk levels (CRITICAL, HIGH, MEDIUM, LOW)
          - Track exact vs fuzzy PEP matches
          - Support enhanced due diligence (EDD) requirements
          - Demonstrate compliance with AML regulations
          
          ### **Vulnerable Customers**
          - Identify customers with vulnerability flags
          - Support UK FCA Consumer Duty requirements
          - Monitor vulnerable customer treatment
          - Ensure appropriate lending decisions
          - Demonstrate fair treatment of vulnerable borrowers
          
          ### **Compliance Hold Management**
          - View applications blocked for compliance review
          - Monitor hold reasons (sanctions, PEP, high risk)
          - Track compliance status (SANCTIONS_REVIEW, PEP_REVIEW, CLEAR)
          - Support escalation to compliance team
          - Maintain audit trail for regulatory examinations
          
          ### **Integration with Customer 360**
          - Loan applications automatically linked to Customer 360
          - Real-time sanctions/PEP status from screening views
          - Overall customer risk rating incorporated
          - Comprehensive customer profile for credit decisions
          - Demonstrate holistic risk assessment
          
          ### **Common Queries**
          - "Are there any applications with sanctions hits?"
          - "Show me loans with PEP flags"
          - "How many applications are on compliance hold?"
          - "Show me all high risk applications"
          - "Which applications have vulnerable customer flags?"
          - "Are there any OFAC sanctions matches?"
          - "Show me applications with CRITICAL risk rating"
          - "How many applications have CLEAR compliance status?"
          - "Show me all PEP matches by risk level"
          - "Which customers require enhanced due diligence?"
          
          Data refreshed **hourly** for compliance monitoring.

  tool_resources:
    Portfolio_Summary:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAS_SV_PORTFOLIO_CURRENT
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    LTV_Risk_Analysis:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAS_SV_LTV_DISTRIBUTION
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    Application_Funnel:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAS_SV_APPLICATION_FUNNEL
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    Affordability_Assessment:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAS_SV_AFFORDABILITY_ANALYSIS
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    Compliance_Screening:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAS_SV_COMPLIANCE_SCREENING
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
  $$;

-- Grant permissions on the agent
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAN_PORTFOLIO_AGENT TO ROLE ACCOUNTADMIN;
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAN_PORTFOLIO_AGENT TO ROLE PUBLIC;

-- Create Snowflake Intelligence object if it doesn't exist
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Grant usage on Snowflake Intelligence object to users
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Add agent to Snowflake Intelligence (makes it visible in the UI)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT 
  ADD AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LOAN_PORTFOLIO_AGENT;

-- Verify creation
SHOW AGENTS IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001;
SHOW SNOWFLAKE INTELLIGENCES;

SELECT 'LOAN_PORTFOLIO_AGENT created successfully! Retail Loans & Mortgages monitoring agent ready.' AS STATUS;

-- ============================================================================
-- DEPLOYMENT NOTES
-- ============================================================================
--
-- PREREQUISITES:
-- 1. Regular views must exist (565_LOAR_loans_portfolio_reporting.sql deployed)
-- 2. Semantic views must exist (765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql deployed)
-- 3. Dynamic tables must have data (Phase 1-3 deployed with DocAI extraction)
-- 4. Warehouse MD_TEST_WH must exist and be running
--
-- DEPLOYMENT:
--   snow sql -c sfseeurope-mdaeppen -f structure/865_LOAN_PORTFOLIO_AGENT.sql
--
-- TESTING:
--   1. Navigate to: https://ai.snowflake.com/sfseeurope/demo_mdaeppen
--   2. Find "Loan Portfolio" agent (blue color)
--   3. Ask: "What is our total loan exposure?"
--   4. Ask: "Show me LTV distribution"
--   5. Ask: "What is our approval rate?"
--   6. Ask: "Are there any compliance holds?"
--
-- TROUBLESHOOTING:
--   - If agent not visible: Refresh browser, check SHOW SNOWFLAKE INTELLIGENCES
--   - If queries fail: Verify semantic views exist (SELECT * FROM LOAS_SV_PORTFOLIO_CURRENT)
--   - If no data: Verify Phase 1-3 deployment (check LOAA_AGG_TB_APPLICATIONS)
--
-- AGENT CAPABILITIES:
--   ✅ Portfolio monitoring by product/country/status
--   ✅ LTV distribution and credit risk analysis
--   ✅ Application funnel and conversion metrics
--   ✅ Affordability (DTI/DSTI) compliance tracking
--   ✅ Sanctions/PEP screening integration
--   ✅ Vulnerable customer identification
--   ✅ Compliance hold management
--   ✅ Natural language query interface (no SQL required)
--
-- TARGET USERS:
--   - Retail Banking Leadership (portfolio strategy)
--   - Credit Risk Management (exposure monitoring)
--   - Loan Operations (pipeline management)
--   - Compliance Team (sanctions/PEP monitoring)
--   - Product Management (product mix analysis)
--   - Country Managers (market performance)
--   - Finance/Treasury (balance sheet planning)
--
-- REGULATORY COMPLIANCE:
--   - MCD (Mortgage Credit Directive) - EU mortgages
--   - CCD (Consumer Credit Directive) - EU unsecured lending
--   - FINMA Mortgage Lending Guidelines - Swiss mortgages
--   - UK FCA Consumer Duty - vulnerable customers
--   - EBA Guidelines on Loan Origination - credit risk
--   - AML Regulations - sanctions/PEP screening
--
-- DATA REFRESH:
--   - Source dynamic tables: 60-minute TARGET_LAG
--   - Semantic views: Real-time (views refresh on query)
--   - Recommended query frequency: Hourly for operations, daily for reporting
--
-- NEXT STEPS:
--   1. Deploy agent (run this file)
--   2. Test with sample queries above
--   3. Build notebook using agent queries (loan_portfolio_monitoring.ipynb)
--   4. Integrate with Streamlit dashboard (the_bank_app)
--   5. Configure alerts for high LTV concentration (optional)
--
-- ============================================================================
