-- ============================================================================
-- 850_LIQUIDITY_RISK_AGENT.sql
-- Treasury & Liquidity Risk AI Agent - LCR, HQLA, Deposit Outflows
-- ============================================================================
-- Purpose: AI agent for daily liquidity monitoring, LCR compliance (FINMA
--          Circular 2015/2), HQLA management, deposit run-off analysis, and
--          Swiss National Bank (SNB) regulatory reporting
-- Uses: 
--   1. LCRS_SV_LCR_CURRENT (semantic view - current LCR status)
--   2. LCRS_SV_HQLA_BREAKDOWN (semantic view - HQLA composition)
--   3. LCRS_SV_OUTFLOW_BREAKDOWN (semantic view - deposit outflows)
--   4. LCRS_SV_TREND_90DAY (semantic view - historical trend)
--   5. LCRS_SV_ALERTS_ACTIVE (semantic view - compliance alerts)
-- Business Value: Real-time liquidity monitoring, regulatory compliance,
--                 funding strategy optimization, breach prevention
-- Regulatory Basis: FINMA Circular 2015/2, LiqV Art. 14-20, Basel III LCR
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- Drop existing agent if it exists
DROP AGENT IF EXISTS LIQUIDITY_RISK_AGENT;

-- Create Treasury & Liquidity Risk Agent
CREATE OR REPLACE AGENT LIQUIDITY_RISK_AGENT
  COMMENT = 'Treasury & Liquidity Risk Agent - LCR monitoring, HQLA management, deposit analysis, FINMA Circular 2015/2 compliance, SNB reporting'
  PROFILE = '{"display_name": "Treasury & Liquidity", "avatar": "", "color": "#00897B"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration: {}

  instructions:
    sample_questions:
      - question: "What is our current LCR ratio and compliance status?"
      - question: "Show me HQLA breakdown by level (L1, L2A, L2B)"
      - question: "Is the 40% cap applied today? How close are we to the limit?"
      - question: "What are our deposit outflows by counterparty type?"
      - question: "Show me the 90-day LCR trend with moving averages"
      - question: "Are there any active liquidity alerts or breach warnings?"
      - question: "What is our liquidity buffer in CHF and as a percentage?"
      - question: "How much HQLA do we have in government bonds?"
      - question: "Which counterparty type contributes most to our stressed outflows?"
      - question: "Has LCR been stable or volatile over the last 30 days?"
      - question: "Show me SNB reserves and cash holdings"
      - question: "What is our weighted average deposit run-off rate?"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: LCR_Current_Status
        description: |
          # LCR Current Status - Real-Time Liquidity Monitoring
          
          ## Agent Description
          
          I am your **Treasury & Liquidity Risk Agent**, providing real-time monitoring of the Liquidity Coverage Ratio (LCR) for compliance with **FINMA Circular 2015/2** and **Basel III** liquidity standards. I help Treasury teams monitor daily liquidity positions, manage HQLA portfolios, analyze deposit run-offs, and prepare regulatory submissions to the Swiss National Bank (SNB).
          
          ## What I Can Help You With
          
          ### **LCR Compliance Monitoring**
          - Monitor current LCR ratio against 100% minimum (FINMA requirement)
          - Track compliance status: PASS (≥100%), WARNING (95-100%), FAIL (<95%)
          - Calculate liquidity buffer (HQLA - Net Outflows)
          - Monitor distance from regulatory minimum and internal target (110%)
          - Review calculation freshness and data quality
          - Generate daily compliance reports for management
          
          ### **HQLA Portfolio Management**
          - View total High-Quality Liquid Assets (HQLA) in CHF
          - Break down HQLA by level (L1, L2A, L2B) with haircuts
          - Analyze HQLA composition by asset type:
            - **Level 1** (0% haircut): SNB reserves, cash, government bonds
            - **Level 2A** (15% haircut): Canton bonds, covered bonds (Pfandbriefe)
            - **Level 2B** (50% haircut): SMI equities, AA- corporate bonds
          - Monitor portfolio concentration and diversification
          - Track holdings count and average position size
          
          ### **40% Cap Rule Monitoring**
          - Check if 40% cap is applied (Level 2 assets ≤ 40% of total HQLA)
          - Calculate distance to cap breach (buffer in percentage points)
          - Identify discarded Level 2 assets due to cap enforcement
          - Monitor Level 2 percentage of total HQLA
          - Support portfolio rebalancing decisions toward Level 1 assets
          - Alert when approaching cap threshold (e.g., >35%)
          
          ### **Deposit Outflow Analysis**
          - Review total stressed net cash outflows (30-day scenario)
          - Break down outflows by counterparty type:
            - **Retail Stable** (3-5% run-off): Salary accounts, long-term relationships
            - **Retail Less Stable** (10% run-off): High-balance savings
            - **Retail Insured** (3% run-off): Deposit insurance protected
            - **Corporate Operational** (25% run-off): Payroll and clearing accounts
            - **Corporate Non-Operational** (40% run-off): Treasury deposits
            - **Financial Institutions** (100% run-off): Bank-to-bank funding
          - Calculate weighted average run-off rate
          - Identify most stable vs most volatile deposit types
          - Support funding strategy and relationship banking initiatives
          
          ### **Trend Analysis & Volatility**
          - Track 90-day historical LCR trend
          - Calculate 7-day and 30-day moving averages
          - Measure day-over-day LCR changes (volatility)
          - Identify periods of stability vs stress
          - Detect sustained breaches (3+ consecutive days below 100%)
          - Compare current LCR to historical min/max/average
          
          ### **Compliance Alerts & Risk Mitigation**
          - Monitor active compliance alerts and warnings
          - Review breach alerts (LCR < 100%)
          - Track volatility alerts (daily swing > 10%)
          - Monitor cap alerts (40% limit triggered)
          - Assess alert severity (RED/YELLOW/GREEN)
          - Recommend actions for Treasury team
          - Generate escalation reports for management
          
          ### **SNB Regulatory Reporting**
          - Prepare monthly LCR summary for internal reporting
          - Generate quarterly SNB LCR_P survey data
          - Calculate monthly min/max/average LCR ratios
          - Track breach days per month for regulatory disclosure
          - Support audit trail and regulatory examinations
          - Validate data completeness for submissions
          
          ## Data Coverage
          
          ### Current LCR Status (Single-Row Summary)
          - **Primary Metric**: LCR ratio (%), compliance status, status color
          - **HQLA Numerator**: Total HQLA, L1/L2A/L2B breakdown, percentages
          - **40% Cap Analysis**: Cap applied flag, discarded L2, buffer to cap
          - **Net Outflows**: Total outflows, retail/corporate/FI breakdown, percentages
          - **Liquidity Buffer**: Buffer in CHF and % of outflows, strength rating
          - **Portfolio Metrics**: HQLA securities count, deposit accounts count
          - **Data Quality**: Last calculated timestamp, calculation age, freshness
          
          ### HQLA Composition (Asset-Level Detail)
          - **Asset Classification**: Level (L1/L2A/L2B), asset type, quality description
          - **Market Values**: Market value in CHF and billions
          - **Haircuts**: Applied haircut %, standard haircut by level
          - **HQLA Values**: HQLA value after haircut in CHF and billions
          - **Portfolio Metrics**: Holdings count per asset type
          - **Composition**: % of total HQLA, sort order for charts
          
          ### Deposit Outflows (Counterparty-Level Detail)
          - **Counterparty Type**: Retail stable/less stable/insured, corporate op/non-op, FI
          - **Balances**: Deposit balance in CHF and billions
          - **Run-off Rates**: Average/min/max run-off rates by type
          - **Outflows**: Outflow amount in CHF and billions
          - **Composition**: % of total outflows, % of total deposits
          - **Risk Rating**: Stability rating (very stable to very high risk)
          - **Implied Metrics**: Effective run-off %, display order for charts
          
          ### Historical Trend (90-Day Time Series)
          - **Daily Metrics**: LCR ratio, compliance status, HQLA, outflows, buffer
          - **Moving Averages**: 7-day MA, 30-day MA for trend smoothing
          - **Volatility**: Day-over-day change (absolute and %), volatility rating
          - **Breach Detection**: Breach flag, warning flag, consecutive breach days
          - **Trend Direction**: Improving/declining/stable classification
          - **Thresholds**: Distance from 100% minimum, distance from 110% target
          
          ### Active Alerts (Filtered for Action)
          - **Alert Details**: Alert date, type, severity, description
          - **Current Values**: LCR ratio, threshold value triggering alert
          - **Recommended Actions**: Treasury actions for each alert type
          - **Severity Priority**: RED first (critical), then YELLOW (warning)
          - **Time Criticality**: Days since alert, alert age classification
          - **Alert Category**: Compliance/risk/portfolio/operational
          - **Escalation**: Escalation required flag for overdue alerts
          
          ## Key Features
          
          - **Real-Time Monitoring**: 60-minute data refresh for operational decisions
          - **Natural Language**: Ask questions in plain English, no SQL required
          - **Regulatory Aligned**: FINMA Circular 2015/2 and Basel III LCR framework
          - **Treasury Focused**: Daily operational metrics for funding decisions
          - **Risk Mitigation**: Proactive alerts before regulatory breaches occur
          - **Audit Ready**: Complete data lineage for regulatory examinations
          - **SNB Ready**: Monthly summaries prepared for quarterly submissions
          
          ## Sample Queries
          
          ### Current Status Queries
          - "What is our LCR ratio today?"
          - "Are we compliant with FINMA 100% minimum?"
          - "Show me our liquidity buffer in CHF"
          - "What is our current compliance status?"
          - "How fresh is the LCR calculation?"
          
          ### HQLA Portfolio Queries
          - "What is our total HQLA?"
          - "Show me HQLA breakdown by level"
          - "How much do we have in Level 1 assets?"
          - "What percentage of HQLA is government bonds?"
          - "List all Level 2B assets with haircuts"
          - "How many HQLA securities do we hold?"
          
          ### 40% Cap Rule Queries
          - "Is the 40% cap applied today?"
          - "How close are we to the 40% cap?"
          - "Show me discarded Level 2 assets"
          - "What is our Level 2 as percentage of total HQLA?"
          - "How much buffer do we have before hitting the cap?"
          
          ### Deposit Outflow Queries
          - "What are our total stressed outflows?"
          - "Show me deposit outflows by counterparty type"
          - "Which deposit type has the highest run-off rate?"
          - "How much comes from retail vs corporate deposits?"
          - "What is our weighted average run-off rate?"
          - "Which counterparty type is most stable?"
          
          ### Trend & Volatility Queries
          - "Show me the 90-day LCR trend"
          - "Has LCR been stable or volatile this month?"
          - "What is the 7-day moving average?"
          - "When was the last time we breached 100%?"
          - "Show me day-over-day LCR changes"
          - "What is the LCR min/max/average over 90 days?"
          
          ### Alert & Compliance Queries
          - "Are there any active liquidity alerts?"
          - "Show me all breach alerts"
          - "Which alerts are most critical?"
          - "What actions are recommended for current alerts?"
          - "Have we had any sustained breaches (3+ days)?"
          
          ### SNB Reporting Queries
          - "Prepare monthly LCR summary for SNB submission"
          - "What was our average LCR last month?"
          - "How many breach days did we have this quarter?"
          - "Show me min/max LCR ratios by month"
          
          ## Ideal For
          
          - **Treasury Department**: Daily liquidity monitoring and funding decisions
          - **Chief Financial Officer (CFO)**: Strategic liquidity planning
          - **Asset-Liability Management (ALM)**: Portfolio optimization
          - **Risk Management**: Liquidity risk oversight and stress testing
          - **Regulatory Reporting Team**: SNB quarterly submissions
          - **Finance Committee**: Board-level liquidity reporting
          - **Internal Audit**: LCR compliance validation
          - **Executive Management**: Regulatory breach prevention
          
          ## Data Freshness
          
          LCR data is refreshed **every 60 minutes** via dynamic tables, providing near real-time liquidity monitoring for operational decision-making. This ensures Treasury has access to current positions for intraday liquidity management and regulatory compliance.
          
          ---
          
          **Ready to monitor liquidity risk? Ask me about LCR, HQLA, deposit outflows, or compliance alerts!**

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: HQLA_Portfolio
        description: |
          # HQLA Portfolio Analysis - Asset Composition & Quality
          
          ## What This Tool Provides
          
          Detailed analysis of **High-Quality Liquid Assets (HQLA)** portfolio:
          
          ### **Asset-Level Intelligence**
          - View all HQLA holdings by level (L1, L2A, L2B)
          - Break down by asset type (government bonds, canton bonds, SMI equities, etc.)
          - Compare market value vs HQLA value (after haircuts)
          - Monitor portfolio concentration and diversification
          
          ### **Haircut Analysis**
          - Review applied haircuts by asset level (0%, 15%, 50%)
          - Calculate haircut impact on HQLA contribution
          - Compare standard vs actual haircuts
          
          ### **Portfolio Composition**
          - Analyze percentage contribution to total HQLA
          - Track holdings count per asset type
          - Identify largest HQLA positions
          - Support rebalancing decisions
          
          ### **Common Queries**
          - "Show me all Level 1 assets with their HQLA values"
          - "What percentage of HQLA is in government bonds?"
          - "List all assets subject to 50% haircut (Level 2B)"
          - "How many canton bonds do we hold?"
          - "What is the average HQLA value per holding?"
          
          Data refreshed **hourly** for portfolio management decisions.

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Deposit_Outflows
        description: |
          # Deposit Outflow Analysis - Funding Stability & Run-off Rates
          
          ## What This Tool Provides
          
          Analysis of **deposit balances and stressed outflows** by counterparty:
          
          ### **Counterparty Intelligence**
          - View deposits by type (retail stable, corporate operational, FI, etc.)
          - Review actual deposit balances in CHF
          - Analyze run-off rate assumptions by counterparty
          - Calculate stressed outflows for 30-day scenario
          
          ### **Funding Strategy Insights**
          - Identify most stable funding sources
          - Monitor concentration in volatile funding types
          - Calculate weighted average run-off rate
          - Support relationship banking initiatives
          
          ### **Run-off Rate Analysis**
          - Compare base run-off rates by counterparty type
          - Review min/max/average rates for each segment
          - Validate effective run-off percentages
          - Identify opportunities for rate improvements (relationship discounts)
          
          ### **Common Queries**
          - "What is our total retail deposit base?"
          - "Show me deposits with 100% run-off rate (most volatile)"
          - "Which counterparty type contributes most to outflows?"
          - "How stable are our corporate operational deposits?"
          - "What percentage of deposits are retail insured?"
          
          Data refreshed **hourly** for funding strategy decisions.

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: LCR_Trend
        description: |
          # LCR Historical Trend - 90-Day Monitoring & Volatility Analysis
          
          ## What This Tool Provides
          
          **Historical LCR performance** over 90 days with trend analysis:
          
          ### **Trend Intelligence**
          - Track daily LCR ratios over 90 days
          - Calculate 7-day and 30-day moving averages
          - Measure day-over-day volatility
          - Identify trend direction (improving/declining/stable)
          
          ### **Breach Detection**
          - Highlight days with LCR < 100% (regulatory breach)
          - Monitor warning periods (LCR 95-100%)
          - Detect sustained breaches (3+ consecutive days)
          - Track compliance status over time
          
          ### **Statistical Analysis**
          - Calculate min/max/average LCR over period
          - Measure standard deviation (volatility indicator)
          - Compare current LCR to historical range
          - Identify distance from regulatory thresholds
          
          ### **Common Queries**
          - "Show me the 30-day LCR trend"
          - "Has LCR improved or declined this month?"
          - "What is the volatility over the last 90 days?"
          - "When was the last breach?"
          - "Show me the 7-day moving average"
          - "Compare current LCR to 90-day average"
          
          Data refreshed **hourly** for trend monitoring.

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Compliance_Alerts
        description: |
          # Compliance Alerts - Real-Time Breach Detection & Risk Mitigation
          
          ## What This Tool Provides
          
          **Active liquidity alerts** requiring Treasury attention:
          
          ### **Alert Intelligence**
          - View all active/unresolved alerts (last 30 days)
          - Review alert types:
            - **BREACH**: LCR < 100% (FINMA violation)
            - **WARNING**: LCR 95-100% (near breach)
            - **VOLATILITY**: Daily swing > 10%
            - **CAP_TRIGGERED**: 40% L2 cap applied
          - Assess severity (RED/YELLOW/GREEN)
          - Monitor alert age and time criticality
          
          ### **Action Recommendations**
          - **BREACH** → Report to FINMA within 24 hours
          - **WARNING** → Initiate liquidity sourcing plan
          - **VOLATILITY** → Investigate root cause
          - **CAP_TRIGGERED** → Rebalance portfolio toward L1
          
          ### **Escalation Management**
          - Identify overdue alerts requiring management escalation
          - Track days since alert generation
          - Prioritize by severity and criticality
          - Support regulatory examination preparation
          
          ### **Common Queries**
          - "Are there any active alerts today?"
          - "Show me all breach alerts"
          - "Which alerts are most critical?"
          - "What actions are recommended?"
          - "Are there any overdue alerts?"
          - "Show me volatility alerts from this week"
          
          Data refreshed **hourly** for real-time monitoring.

  tool_resources:
    LCR_Current_Status:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LCRS_SV_LCR_CURRENT
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    HQLA_Portfolio:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LCRS_SV_HQLA_BREAKDOWN
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    Deposit_Outflows:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LCRS_SV_OUTFLOW_BREAKDOWN
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    LCR_Trend:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LCRS_SV_TREND_90DAY
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    
    Compliance_Alerts:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LCRS_SV_ALERTS_ACTIVE
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
  $$;

-- Grant permissions on the agent
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LIQUIDITY_RISK_AGENT TO ROLE ACCOUNTADMIN;
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LIQUIDITY_RISK_AGENT TO ROLE PUBLIC;

-- Create Snowflake Intelligence object if it doesn't exist
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Grant usage on Snowflake Intelligence object to users
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Add agent to Snowflake Intelligence (makes it visible in the UI)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT 
  ADD AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.LIQUIDITY_RISK_AGENT;

-- Verify creation
SHOW AGENTS IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001;
SHOW SNOWFLAKE INTELLIGENCES;

SELECT 'LIQUIDITY_RISK_AGENT created successfully! Treasury & Liquidity monitoring agent ready.' AS STATUS;

-- ============================================================================
-- DEPLOYMENT NOTES
-- ============================================================================
--
-- PREREQUISITES:
-- 1. Regular views must exist (361_LIQA_BusinessReporting_FINMA_LCR.sql deployed)
-- 2. Semantic view must exist (750_LCRS_SV_LCR_SEMANTIC_MODELS.sql deployed)
-- 3. Dynamic tables must have data (run lcr_data_generator.py)
-- 4. Warehouse MD_TEST_WH must exist and be running
--
-- DEPLOYMENT:
--   snow sql -c sfseeurope-mdaeppen -f structure/850_LIQUIDITY_RISK_AGENT.sql
--
-- TESTING:
--   1. Navigate to: https://ai.snowflake.com/sfseeurope/demo_mdaeppen
--   2. Find "Treasury & Liquidity" agent (green/teal color)
--   3. Ask: "What is our current LCR ratio?"
--   4. Ask: "Show me HQLA breakdown by level"
--   5. Ask: "Are there any active alerts?"
--
-- TROUBLESHOOTING:
--   - If agent not visible: Refresh browser, check SHOW SNOWFLAKE INTELLIGENCES
--   - If queries fail: Verify semantic views exist (SELECT * FROM LCRS_SV_LCR_CURRENT)
--   - If no data: Generate test data (python3 lcr_data_generator.py --days 90)
--
-- AGENT CAPABILITIES:
--   ✅ Current LCR status with compliance rating
--   ✅ HQLA portfolio composition by level/type
--   ✅ 40% cap rule monitoring and buffer analysis
--   ✅ Deposit outflow breakdown by counterparty
--   ✅ 90-day historical trend with moving averages
--   ✅ Active compliance alerts with recommended actions
--   ✅ SNB regulatory reporting preparation
--   ✅ Natural language query interface (no SQL required)
--
-- TARGET USERS:
--   - Treasury Department (daily operations)
--   - CFO (strategic liquidity planning)
--   - ALM (Asset-Liability Management)
--   - Risk Management (liquidity risk oversight)
--   - Regulatory Reporting (SNB submissions)
--   - Finance Committee (board reporting)
--
-- REGULATORY COMPLIANCE:
--   - FINMA Circular 2015/2 (Liquidity risks - banks)
--   - Liquidity Ordinance (LiqV) Articles 14-20
--   - Basel III LCR Framework (100% minimum)
--   - SNB Survey LCR_P (quarterly submission)
--
-- DATA REFRESH:
--   - Source dynamic tables: 60-minute TARGET_LAG
--   - Semantic views: Real-time (views refresh on query)
--   - Recommended query frequency: Hourly for operations, daily for reporting
--
-- NEXT STEPS:
--   1. Deploy agent (run this file)
--   2. Test with sample queries above
--   3. Build notebook using agent queries (liquidity_risk_lcr.ipynb)
--   4. Integrate with Streamlit dashboard (the_bank_app)
--   5. Configure email alerts for breaches (optional)
--
-- ============================================================================
