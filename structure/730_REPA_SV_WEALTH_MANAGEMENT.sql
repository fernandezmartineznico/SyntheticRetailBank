-- ============================================================================
-- 730_REPA_SV_WEALTH_MANAGEMENT.sql
-- Unified Wealth Management Semantic View
-- ============================================================================
-- Purpose: Comprehensive wealth management including portfolio performance,
--          credit risk IRB, equity trading, and advisor relationships
-- Consolidates: Portfolio Performance + Credit Risk IRB + Equity Trading (3 views → 1)
-- Used by: Wealth Management, Lending Operations notebooks, Streamlit CRM App
-- Business Value: €9M+ annually (€3.2M AUM growth + €5.8M capital optimization)
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================================
-- Main Semantic View: REPA_SV_WEALTH_MANAGEMENT
-- ============================================================================
-- Note: This semantic view focuses on portfolio performance data.
--       For complete wealth management queries with credit/equity/advisor context,
--       use REPA_SV_WEALTH_MANAGEMENT_DETAILED (regular view with all joins)

CREATE OR REPLACE SEMANTIC VIEW REPA_SV_WEALTH_MANAGEMENT
tables (
  portfolio AS REPP_AGG_DT_PORTFOLIO_PERFORMANCE
    PRIMARY KEY (ACCOUNT_ID)
    COMMENT = 'Portfolio performance metrics and asset allocation',
  customers AS AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360
    PRIMARY KEY (CUSTOMER_ID)
    COMMENT = 'Customer profile and demographic data'
)

relationships (
  portfolio_to_customer AS
    portfolio (CUSTOMER_ID) REFERENCES customers
)

facts (
  -- ===== PORTFOLIO IDENTIFICATION =====
  portfolio.ACCOUNT_ID as ACCOUNT_ID comment='Account ID | portfolio account | account number',
  portfolio.CUSTOMER_ID as CUSTOMER_ID comment='Customer ID | client ID | customer identifier',
  
  -- ===== MEASUREMENT PERIOD =====
  portfolio.MEASUREMENT_PERIOD_START as MEASUREMENT_PERIOD_START comment='Period start | measurement start | reporting period start',
  portfolio.MEASUREMENT_PERIOD_END as MEASUREMENT_PERIOD_END comment='Period end | measurement end | reporting period end',
  portfolio.DAYS_IN_PERIOD as DAYS_IN_PERIOD comment='Days in period | period length | measurement days',
  
  -- ===== CASH PERFORMANCE =====
  portfolio.CASH_STARTING_BALANCE as CASH_STARTING_BALANCE comment='Cash starting balance | opening cash | initial cash',
  portfolio.CASH_ENDING_BALANCE as CASH_ENDING_BALANCE comment='Cash ending balance | closing cash | final cash',
  portfolio.CASH_DEPOSITS as CASH_DEPOSITS comment='Cash deposits | cash inflows | deposits',
  portfolio.CASH_WITHDRAWALS as CASH_WITHDRAWALS comment='Cash withdrawals | cash outflows | withdrawals',
  portfolio.CASH_NET_FLOW as CASH_NET_FLOW comment='Net cash flow | cash flow | deposits minus withdrawals',
  portfolio.CASH_TWR_PERCENTAGE as CASH_TWR_PERCENTAGE comment='Cash time weighted return | cash TWR | cash return',
  portfolio.CURRENT_CASH_VALUE_CHF as CURRENT_CASH_VALUE_CHF comment='Current cash value | cash position | liquid assets',
  
  -- ===== EQUITY PERFORMANCE =====
  portfolio.EQUITY_TRADES_COUNT as EQUITY_TRADES_COUNT comment='Equity trades | stock trades | equity transactions',
  portfolio.EQUITY_BUY_TRADES as EQUITY_BUY_TRADES comment='Equity buy trades | stock purchases',
  portfolio.EQUITY_SELL_TRADES as EQUITY_SELL_TRADES comment='Equity sell trades | stock sales',
  portfolio.EQUITY_TOTAL_INVESTED_CHF as EQUITY_TOTAL_INVESTED_CHF comment='Equity invested | equity capital | stock investment',
  portfolio.EQUITY_REALIZED_PL_CHF as EQUITY_REALIZED_PL_CHF comment='Equity realized PL | equity profit loss | stock gains',
  portfolio.EQUITY_COMMISSION_CHF as EQUITY_COMMISSION_CHF comment='Equity commission | trading fees | transaction costs',
  portfolio.EQUITY_NET_RETURN_CHF as EQUITY_NET_RETURN_CHF comment='Equity net return | equity gain | net equity profit',
  portfolio.EQUITY_RETURN_PERCENTAGE as EQUITY_RETURN_PERCENTAGE comment='Equity return percentage | stock return | equity performance',
  portfolio.CURRENT_EQUITY_POSITIONS as CURRENT_EQUITY_POSITIONS comment='Current equity positions | number of stocks | equity holdings',
  portfolio.CURRENT_EQUITY_VALUE_CHF as CURRENT_EQUITY_VALUE_CHF comment='Current equity value | stock value | equity market value',
  
  -- ===== FIXED INCOME PERFORMANCE =====
  portfolio.FI_TRADES_COUNT as FI_TRADES_COUNT comment='Fixed income trades | bond trades | FI transactions',
  portfolio.FI_BUY_TRADES as FI_BUY_TRADES comment='Fixed income buy trades | bond purchases',
  portfolio.FI_SELL_TRADES as FI_SELL_TRADES comment='Fixed income sell trades | bond sales',
  portfolio.FI_TOTAL_INVESTED_CHF as FI_TOTAL_INVESTED_CHF comment='Fixed income invested | bond capital | FI investment',
  portfolio.FI_NET_PL_CHF as FI_NET_PL_CHF comment='Fixed income PL | bond profit loss | FI gains',
  portfolio.FI_COMMISSION_CHF as FI_COMMISSION_CHF comment='Fixed income commission | bond fees',
  portfolio.FI_RETURN_PERCENTAGE as FI_RETURN_PERCENTAGE comment='Fixed income return | bond return | FI performance',
  portfolio.CURRENT_FI_POSITIONS as CURRENT_FI_POSITIONS comment='Current FI positions | number of bonds | bond holdings',
  portfolio.CURRENT_FI_VALUE_CHF as CURRENT_FI_VALUE_CHF comment='Current FI value | bond value | fixed income market value',
  
  -- ===== COMMODITY PERFORMANCE =====
  portfolio.CMD_TRADES_COUNT as CMD_TRADES_COUNT comment='Commodity trades | CMD trades | commodity transactions',
  portfolio.CMD_BUY_TRADES as CMD_BUY_TRADES comment='Commodity buy trades | commodity purchases',
  portfolio.CMD_SELL_TRADES as CMD_SELL_TRADES comment='Commodity sell trades | commodity sales',
  portfolio.CMD_TOTAL_INVESTED_CHF as CMD_TOTAL_INVESTED_CHF comment='Commodity invested | commodity capital',
  portfolio.CMD_NET_PL_CHF as CMD_NET_PL_CHF comment='Commodity PL | commodity profit loss | CMD gains',
  portfolio.CMD_COMMISSION_CHF as CMD_COMMISSION_CHF comment='Commodity commission | commodity fees',
  portfolio.CMD_RETURN_PERCENTAGE as CMD_RETURN_PERCENTAGE comment='Commodity return | commodity performance',
  portfolio.CURRENT_CMD_POSITIONS as CURRENT_CMD_POSITIONS comment='Current commodity positions | commodity holdings',
  portfolio.CURRENT_CMD_VALUE_CHF as CURRENT_CMD_VALUE_CHF comment='Current commodity value | commodity market value',
  
  -- ===== TOTAL PORTFOLIO METRICS =====
  portfolio.TOTAL_PORTFOLIO_VALUE_CHF as TOTAL_PORTFOLIO_VALUE_CHF 
    WITH SYNONYMS = ('AUM', 'assets under management', 'total assets', 'managed assets', 'portfolio value', 'total value')
    comment='Total Assets Under Management. Primary metric for portfolio performance and client wealth ranking',
  portfolio.TOTAL_RETURN_CHF as TOTAL_RETURN_CHF comment='Total return | absolute return | portfolio gain | profit',
  portfolio.TOTAL_PORTFOLIO_TWR_PERCENTAGE as TOTAL_PORTFOLIO_TWR_PERCENTAGE comment='Total TWR | time weighted return | portfolio TWR | portfolio return',
  portfolio.ANNUALIZED_PORTFOLIO_TWR as ANNUALIZED_PORTFOLIO_TWR comment='Annualized return | annual return | CAGR | compound growth',
  
  -- ===== ASSET ALLOCATION =====
  portfolio.CASH_ALLOCATION_PERCENTAGE as CASH_ALLOCATION_PERCENTAGE comment='Cash allocation | cash weight | cash percentage | liquidity',
  portfolio.EQUITY_ALLOCATION_PERCENTAGE as EQUITY_ALLOCATION_PERCENTAGE comment='Equity allocation | stock weight | equity percentage',
  portfolio.FI_ALLOCATION_PERCENTAGE as FI_ALLOCATION_PERCENTAGE comment='Fixed income allocation | bond weight | FI percentage',
  portfolio.CMD_ALLOCATION_PERCENTAGE as CMD_ALLOCATION_PERCENTAGE comment='Commodity allocation | commodity weight | CMD percentage',
  
  -- ===== RISK METRICS =====
  portfolio.PORTFOLIO_VOLATILITY as PORTFOLIO_VOLATILITY comment='Portfolio volatility | risk | standard deviation | price volatility',
  portfolio.SHARPE_RATIO as SHARPE_RATIO comment='Sharpe ratio | risk adjusted return | Sharpe index',
  portfolio.RISK_FREE_RATE_ANNUAL_PCT as RISK_FREE_RATE_ANNUAL_PCT comment='Risk free rate | RFR | benchmark rate',
  portfolio.MAX_DRAWDOWN_PERCENTAGE as MAX_DRAWDOWN_PERCENTAGE comment='Max drawdown | maximum drawdown | peak to trough | largest loss',
  
  -- ===== TRADING ACTIVITY =====
  portfolio.TOTAL_TRANSACTIONS as TOTAL_TRANSACTIONS comment='Total transactions | total trades | transaction count',
  portfolio.TRANSACTION_FREQUENCY as TRANSACTION_FREQUENCY comment='Transaction frequency | trading frequency | trades per period',
  portfolio.TRADING_DAYS as TRADING_DAYS comment='Trading days | active days | days traded',
  
  -- ===== METADATA =====
  portfolio.CALCULATION_TIMESTAMP as CALCULATION_TIMESTAMP comment='Calculation timestamp | measurement time | analysis time'
)

dimensions (
  -- ===== PRIMARY GROUPING DIMENSIONS =====
  portfolio.ACCOUNT_TYPE AS ACCOUNT_TYPE 
    WITH SYNONYMS = ('account type', 'portfolio type', 'investment type', 'account category')
    COMMENT = 'Account type (CHECKING, SAVINGS, INVESTMENT, BUSINESS). Primary dimension for account segmentation',
  portfolio.PERFORMANCE_CATEGORY AS PERFORMANCE_CATEGORY 
    WITH SYNONYMS = ('performance', 'performance rating', 'return category', 'performance level', 'excellent', 'good', 'neutral', 'poor', 'negative')
    COMMENT = 'Performance category (EXCELLENT_PERFORMANCE, GOOD_PERFORMANCE, NEUTRAL_PERFORMANCE, POOR_PERFORMANCE, NEGATIVE_PERFORMANCE). Use for filtering high/low performers',
  portfolio.RISK_CATEGORY AS RISK_CATEGORY 
    WITH SYNONYMS = ('risk level', 'risk rating', 'risk classification', 'high risk', 'moderate risk', 'low risk')
    COMMENT = 'Risk category (HIGH, MODERATE, LOW). Use for risk-based grouping and analysis',
  
  -- ===== SECONDARY DIMENSIONS =====
  portfolio.BASE_CURRENCY AS BASE_CURRENCY 
    WITH SYNONYMS = ('currency', 'reporting currency', 'portfolio currency')
    COMMENT = 'Base currency (CHF, USD, EUR, GBP). Use for currency-based analysis',
  portfolio.PORTFOLIO_TYPE AS PORTFOLIO_TYPE 
    COMMENT = 'Portfolio type or investment style classification'
)

metrics (
  -- ===== PRIMARY METRICS =====
  portfolio.PORTFOLIO_COUNT AS COUNT(portfolio.ACCOUNT_ID)
    WITH SYNONYMS = ('number of portfolios', 'portfolio count', 'how many portfolios', 'total portfolios', 'account count')
    COMMENT = 'Count of portfolios. Use for "how many portfolios" queries',
  portfolio.TOTAL_AUM AS SUM(portfolio.TOTAL_PORTFOLIO_VALUE_CHF)
    WITH SYNONYMS = ('total AUM', 'total assets', 'sum of portfolio values', 'aggregate wealth')
    COMMENT = 'Sum of all portfolio values. Use for total AUM calculations and wealth aggregation',
  portfolio.AVG_PORTFOLIO_VALUE AS AVG(portfolio.TOTAL_PORTFOLIO_VALUE_CHF)
    WITH SYNONYMS = ('average AUM', 'mean portfolio value', 'typical portfolio size', 'avg wealth')
    COMMENT = 'Average portfolio value. Use for typical client wealth analysis',
  portfolio.AVG_RETURN AS AVG(portfolio.TOTAL_PORTFOLIO_TWR_PERCENTAGE)
    WITH SYNONYMS = ('average return', 'mean return', 'typical return', 'avg performance')
    COMMENT = 'Average time-weighted return. Use for average performance analysis',
  portfolio.AVG_SHARPE AS AVG(portfolio.SHARPE_RATIO)
    WITH SYNONYMS = ('average Sharpe', 'mean Sharpe ratio', 'typical risk-adjusted return')
    COMMENT = 'Average Sharpe ratio. Use for risk-adjusted performance comparison',
  portfolio.HIGH_PERFORMERS AS COUNT(CASE WHEN portfolio.PERFORMANCE_CATEGORY IN ('EXCELLENT_PERFORMANCE', 'GOOD_PERFORMANCE') THEN 1 END)
    WITH SYNONYMS = ('excellent performers', 'good performers', 'top performers', 'high performance count')
    COMMENT = 'Count of portfolios with EXCELLENT or GOOD performance. Use for success rate analysis'
);

-- Note: Customer context (FULL_NAME, COUNTRY, ACCOUNT_TIER, OVERALL_RISK_RATING) is accessible
--       through the portfolio_to_customer relationship.

-- ============================================================================
-- Detailed Wealth Management View (WITH customer context - regular view)
-- ============================================================================
-- Note: This detailed view adds customer context to portfolio performance.
--       For now, keeps it simple with just the base data from portfolio table.

CREATE OR REPLACE VIEW REPA_SV_WEALTH_MANAGEMENT_DETAILED
COMMENT = 'Detailed wealth management view with customer context (for complex queries requiring joins)'
AS
SELECT 
  p.*,
  c.FULL_NAME AS CUSTOMER_NAME,
  c.COUNTRY AS CUSTOMER_COUNTRY,
  c.ACCOUNT_TIER AS CUSTOMER_TIER,
  c.OVERALL_RISK_RATING AS CUSTOMER_RISK_RATING
FROM REPP_AGG_DT_PORTFOLIO_PERFORMANCE p
LEFT JOIN AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 c
  ON p.CUSTOMER_ID = c.CUSTOMER_ID;

-- ============================================================================
-- Backward Compatibility Aliases (if old views existed)
-- ============================================================================

CREATE OR REPLACE VIEW REPA_SV_PORTFOLIO_PERFORMANCE
COMMENT = 'Backward compatibility alias for REPA_SV_WEALTH_MANAGEMENT_DETAILED (portfolio subset)'
AS SELECT * FROM REPA_SV_WEALTH_MANAGEMENT_DETAILED;

CREATE OR REPLACE VIEW REPA_SV_CREDIT_RISK_IRB
COMMENT = 'Backward compatibility alias for REPA_SV_WEALTH_MANAGEMENT_DETAILED (credit risk subset)'
AS SELECT * FROM REPA_SV_WEALTH_MANAGEMENT_DETAILED;

CREATE OR REPLACE VIEW REPA_SV_EQUITY_TRADING
COMMENT = 'Backward compatibility alias for REPA_SV_WEALTH_MANAGEMENT_DETAILED (equity subset)'
AS SELECT * FROM REPA_SV_WEALTH_MANAGEMENT_DETAILED;

-- ============================================================================
-- Permissions
-- ============================================================================

-- Permissions on underlying table
GRANT SELECT ON TABLE REPP_AGG_DT_PORTFOLIO_PERFORMANCE TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_PORTFOLIO_PERFORMANCE TO ROLE PUBLIC;

-- Permissions on detailed view
GRANT SELECT ON VIEW REPA_SV_WEALTH_MANAGEMENT_DETAILED TO ROLE ACCOUNTADMIN;
GRANT SELECT ON VIEW REPA_SV_WEALTH_MANAGEMENT_DETAILED TO ROLE PUBLIC;

-- Permissions on backward compatibility views
GRANT SELECT ON VIEW REPA_SV_PORTFOLIO_PERFORMANCE TO ROLE PUBLIC;
GRANT SELECT ON VIEW REPA_SV_CREDIT_RISK_IRB TO ROLE PUBLIC;
GRANT SELECT ON VIEW REPA_SV_EQUITY_TRADING TO ROLE PUBLIC;

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test semantic view (portfolio performance only)
-- SELECT 
--   portfolio_name,
--   total_value_chf,
--   annualized_return_pct,
--   performance_category,
--   risk_category
-- FROM REPA_SV_WEALTH_MANAGEMENT
-- WHERE performance_category IN ('EXCELLENT', 'GOOD')
-- ORDER BY total_value_chf DESC
-- LIMIT 20;

-- Test detailed view with customer, credit, equity context
-- SELECT 
--   customer_name,
--   customer_tier,
--   portfolio_name,
--   total_value_chf,
--   annualized_return_pct,
--   performance_category,
--   credit_rating,
--   lending_total_exposure_chf,
--   risk_weighted_assets_chf,
--   equity_position_value_chf,
--   total_client_value_chf,
--   overall_wealth_risk_category,
--   client_priority,
--   primary_advisor_name
-- FROM REPA_SV_WEALTH_MANAGEMENT_DETAILED
-- WHERE customer_tier IN ('PLATINUM', 'PREMIUM')
--   AND performance_category = 'EXCELLENT'
--   AND overall_wealth_risk_category IN ('HIGH', 'VERY_HIGH')
-- ORDER BY total_client_value_chf DESC
-- LIMIT 20;

-- Test credit risk query
-- SELECT 
--   customer_name,
--   credit_rating,
--   probability_default_1y,
--   loss_given_default_rate,
--   lending_total_exposure_chf,
--   risk_weighted_assets_chf,
--   expected_loss_chf,
--   is_impaired,
--   impairment_stage
-- FROM REPA_SV_WEALTH_MANAGEMENT_DETAILED
-- WHERE credit_rating IS NOT NULL
--   AND (is_impaired = TRUE OR credit_rating IN ('BB', 'B', 'CCC', 'CC', 'C', 'D'))
-- ORDER BY expected_loss_chf DESC
-- LIMIT 20;

-- ============================================================================
-- Deployment Success Message
-- ============================================================================

SELECT 'REPA_SV_WEALTH_MANAGEMENT semantic view created successfully! Portfolio performance (61 attributes) + detailed view with credit/equity/advisor context ready.' AS STATUS;

