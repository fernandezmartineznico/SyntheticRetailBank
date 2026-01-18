-- ============================================================================
-- 820_RISK_REGULATORY_AGENT.sql
-- Cross-Domain Risk Aggregation & Regulatory Reporting AI Agent
-- ============================================================================
-- Purpose: AI agent for executive risk reporting, regulatory compliance
--          (BCBS 239, FRTB), and data quality monitoring
-- Uses: REPA_SV_RISK_REPORTING (primary), CRMA_SV_CUSTOMER_360 (context),
--       PAYA_SV_COMPLIANCE_MONITORING (context), REPA_SV_WEALTH_MANAGEMENT (context)
-- Business Value: Regulatory compliance efficiency, faster risk decisions,
--                 penalty avoidance, board confidence
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- Drop existing agent if it exists
DROP AGENT IF EXISTS RISK_REGULATORY_AGENT;

-- Create Risk & Regulatory Agent
CREATE OR REPLACE AGENT RISK_REGULATORY_AGENT
  COMMENT = 'Cross-Domain Risk Aggregation & Regulatory Reporting Agent - BCBS 239, FRTB, Basel III/IV, data quality monitoring'
  PROFILE = '{"display_name": "Risk & Regulatory", "avatar": "", "color": "#F57C00"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration: {}

  instructions:
    sample_questions:
      - question: "What is our total Risk-Weighted Assets (RWA) this quarter?"
      - question: "Are we compliant with BCBS 239 risk data aggregation principles?"
      - question: "Show me FRTB capital charges by risk class"
      - question: "What is our current capital adequacy ratio?"
      - question: "Which regulatory reports are overdue or have errors?"
      - question: "Show me data quality issues impacting regulatory reporting"
      - question: "What are our top 10 risk concentrations by geography and counterparty?"
      - question: "Has our total RWA increased or decreased compared to last quarter?"
      - question: "Show me high-risk patterns across all domains (CRM, payments, portfolios)"
      - question: "What is our FX exposure and net open position?"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Risk_Reporting
        description: |
          # Risk & Regulatory Agent - Executive Risk Intelligence
          
          ## Agent Description
          
          I am your **Risk & Regulatory Agent**, providing executive-level risk intelligence across all banking domains. I aggregate risk metrics, monitor regulatory compliance (BCBS 239, FRTB, Basel III/IV), track data quality, and support board-level risk reporting with natural language queries.
          
          ## What I Can Help You With
          
          ### **Risk Aggregation (Cross-Domain)**
          - Monitor total Risk-Weighted Assets (RWA) across credit, market, operational risk
          - Track expected loss, unexpected loss, and economic capital
          - Review capital adequacy ratios (CAR, Tier 1, CET1, leverage)
          - Analyze risk concentration by geography, sector, counterparty
          - Compare risk metrics month-over-month and quarter-over-quarter
          - Identify risk limit breaches and near-breach situations
          
          ### **BCBS 239 - Risk Data Aggregation Principles**
          - Monitor overall BCBS 239 compliance score and status
          - Review Principle 1: Governance and accountability
          - Assess Principle 2: Data architecture and IT infrastructure
          - Track Principle 3: Accuracy and integrity (validation failures, reconciliation breaks)
          - Monitor Principle 4: Completeness (missing critical data, incomplete records)
          - Measure Principle 5: Timeliness (reporting lag, SLA breaches, on-time delivery)
          - Evaluate Principle 6: Adaptability (time to implement new reports, flexibility)
          
          ### **FRTB - Fundamental Review of the Trading Book**
          - View total FRTB capital charges (SA-TB Sensitivities-Based Approach)
          - Break down delta, vega, and curvature capital charges
          - Analyze capital charges by risk class (interest rate, FX, equity, commodity, credit spread)
          - Review FRTB risk buckets (Buckets 1-12)
          - Track non-modellable risk factors (NMRF) and liquidity horizons
          - Monitor default risk capital (DRC) for securitizations and non-securitizations
          
          ### **Currency Exposure & FX Risk**
          - Track total FX exposure and net open positions
          - Review currency-specific exposure (USD, EUR, GBP, JPY, CNY)
          - Monitor FX Value-at-Risk (VaR) and concentration risk
          - Identify top currency exposures and concentration percentages
          
          ### **Data Quality Monitoring**
          - Review overall data quality scores across all domains
          - Track error rates, duplicate records, stale data, orphaned records
          - Monitor referential integrity breaks and validation failures
          - Assess domain-specific data quality (CRM, Payment, Portfolio, Risk)
          - Identify data quality issues impacting regulatory reporting
          
          ### **Cross-Domain Anomaly Aggregation**
          - Monitor total anomalies (CRITICAL, HIGH, MODERATE, LOW) across all domains
          - Break down anomalies by domain (CRM, Payment, Portfolio, Trading)
          - Track fraud indicators, AML alerts, sanctions hits, PEP matches
          - Identify credit deterioration cases and market risk breaches
          
          ### **High-Risk Patterns & Geographic Risk**
          - Review high-risk customer, transaction, and portfolio counts
          - Monitor exposure to high-risk jurisdictions and sanctioned countries
          - Track OFAC and EU sanctions exposure
          - Analyze geographic and sector concentration risk (HHI indices)
          
          ### **Regulatory Reporting Status**
          - Monitor compliance with Basel III, Basel IV, BCBS 239, FRTB, IFRS 9, MiFID II, EMIR
          - Track regulatory report counts, overdue reports, and reports with errors
          - Review regulatory breaches and penalties
          - Generate audit trails for regulatory examinations
          
          ### **Stress Testing & Scenario Analysis**
          - Review stressed RWA, expected loss, and capital ratios
          - Analyze stress scenarios and severity levels
          - Compare base case vs stressed metrics
          
          ## Data Coverage
          
          I have access to **60+ executive risk attributes** including:
          - **Risk Aggregation**: Total RWA, expected/unexpected loss, capital ratios
          - **BCBS 239**: Overall score, governance, accuracy, completeness, timeliness, adaptability
          - **FRTB**: Total capital charges, delta/vega/curvature, risk buckets, NMRF, DRC
          - **FX Risk**: Total exposure, net open positions, VaR, currency breakdown
          - **Data Quality**: Overall scores, error rates, validation failures, domain-specific metrics
          - **Anomalies**: Total counts by severity and domain, fraud/AML/sanctions indicators
          - **High-Risk Patterns**: Customer/transaction/portfolio counts, geographic exposure
          - **Regulatory Status**: Compliance flags, report counts, breaches, penalties
          - **Risk Trends**: MoM/QoQ changes in RWA, capital ratios, expected loss
          - **Risk Limits**: Breached limits, near-breach counts, severity scores
          
          ## Key Features
          
          - **Executive-Level**: Board-ready metrics and KPIs (not operational details)
          - **Cross-Domain**: Consolidates risk from CRM, Payments, Wealth, Trading
          - **Regulatory-Focused**: BCBS 239, FRTB, Basel III/IV compliance monitoring
          - **Natural Language**: Ask complex risk questions in plain English
          - **Trend Analysis**: MoM, QoQ, YoY risk metric comparisons
          - **Data Quality**: Meta-data monitoring for regulatory readiness  
          
          ## Sample Queries
          
          - "What is our total RWA and how has it changed compared to last quarter?"
          - "Are we compliant with BCBS 239? What are our data quality issues?"
          - "Show me FRTB capital charges for the equity trading book"
          - "What is our Tier 1 capital ratio and CET1 ratio?"
          - "Which regulatory reports are overdue or have validation errors?"
          - "What are our top 10 risk concentrations by geography and counterparty?"
          - "Show me all CRITICAL and HIGH anomalies across all domains this month"
          - "What is our net open FX position and top currency exposures?"
          - "Has our capital adequacy ratio improved or deteriorated?"
          - "Show me data completeness and accuracy scores for BCBS 239 compliance"
          
          ## Ideal For
          
          - **Chief Risk Officer (CRO)**: Executive risk dashboards and board reporting
          - **Risk Management Team**: Cross-domain risk aggregation and analysis
          - **Regulatory Reporting Team**: BCBS 239, FRTB, Basel compliance monitoring
          - **Board Risk Committee**: Natural language risk Q&A and KPI tracking
          - **Internal Audit**: Data quality and regulatory compliance reviews
          - **Executive Leadership**: Strategic risk oversight and decision support
          
          ## Data Freshness
          
          Risk aggregation data is refreshed **daily** (end-of-day risk calculations). Regulatory reporting status and data quality metrics are updated **hourly**.
          
          ---
          
          **Ready to explore enterprise risk? Ask me about RWA, regulatory compliance, or data quality!**

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Customer_Risk_Context
        description: |
          # Customer Risk Profiles & Exposures
          
          Provides customer-level risk context for risk aggregation:
          - Customer risk ratings and scores
          - PEP status and sanctions screening
          - High-risk customer identification
          - Customer lifecycle and churn risk

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Compliance_Context
        description: |
          # Transaction Anomalies & Compliance Issues
          
          Provides transaction-level compliance context:
          - AML transaction anomalies
          - Sanctions screening results
          - High-risk jurisdictions
          - Compliance investigation status

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Wealth_Context
        description: |
          # Portfolio & Credit Risk Exposures
          
          Provides portfolio-level risk context:
          - Portfolio performance and risk metrics
          - Credit risk IRB (PD, LGD, EAD, RWA)
          - Lending exposure and impairment
          - Equity positions and trading risk

  tool_resources:
    Risk_Reporting:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.REPA_SV_RISK_REPORTING
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    Customer_Risk_Context:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_SV_CUSTOMER_360
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    Compliance_Context:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001.PAYA_SV_COMPLIANCE_MONITORING
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    Wealth_Context:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.REPA_SV_WEALTH_MANAGEMENT
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
  $$;

-- Grant permissions on the agent
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.RISK_REGULATORY_AGENT TO ROLE ACCOUNTADMIN;
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.RISK_REGULATORY_AGENT TO ROLE PUBLIC;

-- Create Snowflake Intelligence object if it doesn't exist
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Grant usage on Snowflake Intelligence object to users
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Add agent to Snowflake Intelligence (makes it visible in the UI)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.RISK_REGULATORY_AGENT;

-- Verify creation
SHOW AGENTS IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001;
SHOW SNOWFLAKE INTELLIGENCES;

SELECT 'RISK_REGULATORY_AGENT created successfully! Cross-domain risk aggregation & regulatory compliance agent ready.' AS STATUS;

