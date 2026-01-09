-- ============================================================================
-- 753_WEALTH_ADVISOR_AGENT.sql
-- Unified Wealth Management AI Agent
-- ============================================================================
-- Purpose: AI agent for wealth management, portfolio performance, credit risk,
--          and equity trading intelligence
-- Uses: REPA_SV_WEALTH_MANAGEMENT (primary), CRMA_SV_CUSTOMER_360 (context),
--       EMPA_SV_EMPLOYEE_ADVISOR (advisor relationships)
-- Business Value: €9M+ annually (€3.2M AUM growth + €5.8M capital optimization)
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- Drop existing agent if it exists
DROP AGENT IF EXISTS WEALTH_ADVISOR_AGENT;

-- Create Wealth Advisor Agent
CREATE OR REPLACE AGENT WEALTH_ADVISOR_AGENT
  COMMENT = 'Unified Wealth Management and Advisory Agent - Portfolio performance, credit risk IRB, and equity trading intelligence'
  PROFILE = '{"display_name": "Wealth Advisor", "avatar": "", "color": "#388E3C"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration: {}

  instructions:
    sample_questions:
      - question: "Show me PLATINUM clients with EXCELLENT_PERFORMANCE portfolios"
      - question: "Which clients have HIGH risk category but GOOD_PERFORMANCE returns?"
      - question: "Find portfolios with POOR_PERFORMANCE or NEGATIVE_PERFORMANCE requiring rebalancing"
      - question: "Show me clients with total portfolio value over CHF 5 million"
      - question: "Which PREMIUM account type clients have the highest returns?"
      - question: "Analyze equity positions for my top 10 clients by total AUM"
      - question: "Show me INVESTMENT accounts with EXCELLENT_PERFORMANCE in the last measurement period"
      - question: "Find clients with high Sharpe ratio and low volatility"

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Wealth_Management
        description: |
          # Wealth Advisor Agent - Portfolio, Credit and Equity Intelligence
          
          ## Agent Description
          
          I am your **Wealth Advisor Agent**, providing comprehensive wealth management intelligence across portfolio performance, credit risk, equity trading, and advisor relationships. I help you make informed investment decisions, assess client risk, optimize portfolios, and manage advisor capacity.
          
          ## What I Can Help You With
          
          ### **Portfolio Performance Analytics**
          - View portfolio values, returns, and performance metrics
          - Analyze time-weighted returns (TWR), annualized returns, YTD/MTD/QTD performance
          - Review Sharpe ratio, Sortino ratio, max drawdown, volatility
          - Track beta, alpha, tracking error, information ratio
          - Monitor asset allocation (equity, fixed income, commodities, cash, alternatives)
          - Identify portfolios requiring rebalancing
          - Categorize performance (EXCELLENT_PERFORMANCE, GOOD_PERFORMANCE, NEUTRAL_PERFORMANCE, POOR_PERFORMANCE, NEGATIVE_PERFORMANCE)
          
          ### **Credit Risk and Lending Exposure**
          - Review IRB (Internal Ratings-Based) credit ratings and scores
          - Analyze probability of default (PD), loss given default (LGD), exposure at default (EAD)
          - Monitor risk-weighted assets (RWA) and capital requirements
          - Track expected loss and unexpected loss metrics
          - Review secured vs unsecured lending exposure
          - Identify impaired loans and provisioning requirements
          - Monitor loan-to-value (LTV) ratios and collateral values
          - Track credit utilization and days past due
          
          ### **Equity Positions and Trading**
          - View equity holdings by symbol, ISIN, and security name
          - Monitor net positions, unrealized and realized P and L
          - Track buy/sell activity, average prices, current valuations
          - Analyze trading volumes, commissions, and trading frequency
          - Review equity concentration and diversification
          - Identify stale positions requiring review
          
          ### **Client Segmentation and Prioritization**
          - Analyze clients by tier (STANDARD, GOLD, PLATINUM, PREMIUM)
          - Calculate total client value (portfolio + lending)
          - Prioritize clients (VIP, HIGH, MEDIUM, STANDARD) by total exposure
          - Review client risk profiles and compliance status
          - Track customer tenure and relationship history
          
          ### **Advisor Relationship Management**
          - View advisor assignments and client portfolios
          - Monitor advisor capacity and client load
          - Track last contact dates and review schedules
          - Identify clients requiring advisor attention
          - Optimize advisor workload and capacity planning
          
          ### **Risk Aggregation and Alerts**
          - Identify clients with HIGH or MODERATE risk category
          - Flag portfolios with NEGATIVE_PERFORMANCE or POOR_PERFORMANCE
          - Monitor clients with EXCELLENT_PERFORMANCE but HIGH risk category
          - Track portfolio concentration and asset allocation
          - Review clients with poor performance requiring rebalancing
          
          ## Data Coverage
          
          I have access to **100+ wealth management attributes** including:
          - **Portfolio Metrics**: Value, returns, Sharpe, max drawdown, asset allocation
          - **Credit Risk IRB**: PD, LGD, EAD, RWA, credit rating, expected loss
          - **Lending**: Total exposure, secured/unsecured, loan balance, utilization
          - **Equity Positions**: Holdings, P and L, trading activity, commissions
          - **Customer Context**: Name, tier, risk rating, PEP status, income
          - **Account Details**: Type, status, balance, currency
          - **Advisor Info**: Primary advisor, team, region, contact frequency
          - **Consolidated Metrics**: Total client value, overall risk category, client priority
          
          ## Key Features
          
          - **Unified View**: Portfolio + Credit + Equity in one query (complete client picture)  
          - **Multi-Asset Coverage**: Equities, fixed income, commodities, cash, alternatives  
          - **IRB Compliant**: Full Basel III credit risk metrics  
          - **Natural Language**: Ask questions in plain English  
          - **Real-Time Data**: Hourly refreshed portfolio and position data  
          - **Advisor-Friendly**: Designed for relationship managers and wealth advisors  
          
          ## Sample Queries
          
          - "Show me my top 10 clients by total portfolio value"
          - "Which INVESTMENT accounts have EXCELLENT_PERFORMANCE but HIGH risk category?"
          - "Find portfolios with max drawdown exceeding -20%"
          - "Show me all portfolios with NEGATIVE_PERFORMANCE"
          - "Which clients have GOOD_PERFORMANCE with Sharpe ratio above 1.5?"
          - "Find CHECKING accounts with POOR_PERFORMANCE"
          - "Show me all INVESTMENT accounts with total value over CHF 1 million"
          - "Which portfolios have the highest annualized returns?"
          - "Find accounts with high equity allocation (over 80%)"
          
          ## Ideal For
          
          - **Wealth Advisors**: Client portfolio reviews and investment recommendations
          - **Relationship Managers**: Complete client relationship oversight
          - **Credit Risk Officers**: Lending exposure and IRB monitoring
          - **Portfolio Managers**: Multi-asset portfolio optimization
          - **Private Bankers**: High-net-worth client management
          - **Executive Leadership**: Wealth management KPIs and AUM tracking
          
          ## Data Freshness
          
          Portfolio performance is refreshed **daily** (end-of-day valuations). Equity positions and credit risk metrics are updated **hourly** via dynamic tables.
          
          ---
          
          **Ready to optimize your client portfolios? Ask me about performance, risk, or client prioritization!**

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Customer_Profile
        description: |
          # Customer Profile and Demographics
          
          Provides additional customer context for wealth advisory:
          - Customer demographics and contact information
          - Account tier and risk profile
          - PEP status and compliance flags
          - Customer tenure and relationship history
          - Employment, occupation, and income details

    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: Advisor_Relationships
        description: |
          # Advisor Assignments and Capacity
          
          Provides advisor relationship and capacity management:
          - Advisor-customer assignments and primary advisors
          - Advisor capacity utilization and client load
          - Advisor performance metrics and revenue
          - Team structure and regional organization
          - Contact frequency and relationship tenure

  tool_resources:
    Wealth_Management:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.REPA_SV_WEALTH_MANAGEMENT
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    Customer_Profile:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_SV_CUSTOMER_360
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
    Advisor_Relationships:
      semantic_view: AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.EMPA_SV_EMPLOYEE_ADVISOR
      execution_environment:
        type: warehouse
        warehouse: MD_TEST_WH
        query_timeout: 30
  $$;

-- Grant permissions on the agent
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.WEALTH_ADVISOR_AGENT TO ROLE ACCOUNTADMIN;
GRANT USAGE ON AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.WEALTH_ADVISOR_AGENT TO ROLE PUBLIC;

-- Create Snowflake Intelligence object if it doesn't exist
CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;

-- Grant usage on Snowflake Intelligence object to users
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Add agent to Snowflake Intelligence (makes it visible in the UI)
ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT ADD AGENT AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.WEALTH_ADVISOR_AGENT;

-- Verify creation
SHOW AGENTS IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001;
SHOW SNOWFLAKE INTELLIGENCES;

SELECT 'WEALTH_ADVISOR_AGENT created successfully! Unified wealth management (portfolio + credit + equity) agent ready.' AS STATUS;

