-- ============================================================
-- REP_AGG_001 Schema - Equity Trading Reporting & Analytics
-- Created on: 2025-10-05 (Split from 500_REPP_core_reporting.sql)
-- ============================================================
--
-- OVERVIEW:
-- This schema contains dynamic tables for equity trading reporting and analytics.
-- Provides comprehensive views of customer trading activity, position management,
-- and compliance monitoring for equity securities.
--
-- BUSINESS PURPOSE:
-- - Customer equity trading activity analysis
-- - Portfolio position tracking and concentration risk
-- - Currency exposure monitoring for equity trades
-- - Large trade compliance monitoring
-- - Market risk analysis and reporting
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (4):
-- │  ├─ REPP_AGG_DT_EQUITY_SUMMARY              - Customer trading activity summary
-- │  ├─ REPP_AGG_DT_EQUITY_POSITIONS            - Position summary by security
-- │  ├─ REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE    - FX exposure from equity trades
-- │  └─ REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES    - Large trade compliance monitoring
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- DATA FLOW:
-- EQT_RAW_001.EQTI_RAW_TB_TRADES (raw equity trades)
--     ↓
-- REP_AGG_001.REPP_AGG_DT_EQUITY_* (reporting tables)
--
-- RELATED SCHEMAS:
-- - EQT_RAW_001: Source equity trading data
-- - EQT_AGG_001: Equity aggregation layer (positions, analytics)
-- - CRM_AGG_001: Customer and account master data
-- - 500_REPP_core_reporting.sql: Core reporting tables
-- - 520_REPP_CREDIT_RISK.sql: Credit risk reporting
-- - 530_REPP_PORTFOLIO.sql: Portfolio performance reporting
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================
-- EQUITY TRADING DYNAMIC TABLES
-- ============================================================

-- Equity trading summary by customer
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_EQUITY_SUMMARY(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for portfolio analysis',
    ACCOUNT_ID VARCHAR(30) COMMENT 'Account identifier for position tracking',
    BASE_CURRENCY VARCHAR(3) COMMENT 'Account base currency for reporting',
    TOTAL_TRADES NUMBER(10,0) COMMENT 'Total number of equity transactions',
    BUY_TRADES NUMBER(10,0) COMMENT 'Number of buy transactions',
    SELL_TRADES NUMBER(10,0) COMMENT 'Number of sell transactions',
    UNIQUE_SYMBOLS NUMBER(10,0) COMMENT 'Number of different securities traded',
    TOTAL_CHF_VOLUME DECIMAL(28,2) COMMENT 'Total trading volume in CHF',
    NET_CHF_POSITION DECIMAL(28,2) COMMENT 'Net position (positive = net buyer, negative = net seller)',
    TOTAL_COMMISSION_CHF DECIMAL(28,2) COMMENT 'Total commission fees paid',
    AVG_TRADE_SIZE_CHF DECIMAL(28,2) COMMENT 'Average trade size for customer profiling',
    FIRST_TRADE_DATE DATE COMMENT 'First trading activity date',
    LAST_TRADE_DATE DATE COMMENT 'Most recent trading activity date'
) COMMENT = 'Customer Equity Trading Performance: To summarize the trading activity and profitability (via net position and commissions) for each customer and account.	
Brokerage/CRM: Measures customer engagement and revenue generation (commissions). 
Risk: Monitors net market position (buyer/seller) for risk exposure at the client level.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    t.CUSTOMER_ID,                                               -- Customer identifier for portfolio analysis
    t.ACCOUNT_ID,                                                -- Account identifier for position tracking
    a.BASE_CURRENCY,                                             -- Account base currency for reporting
    COUNT(*) AS TOTAL_TRADES,                                    -- Total number of equity transactions
    SUM(CASE WHEN t.SIDE = '1' THEN 1 ELSE 0 END) AS BUY_TRADES,  -- Number of buy transactions
    SUM(CASE WHEN t.SIDE = '2' THEN 1 ELSE 0 END) AS SELL_TRADES, -- Number of sell transactions
    COUNT(DISTINCT t.SYMBOL) AS UNIQUE_SYMBOLS,                  -- Number of different securities traded
    SUM(ABS(t.BASE_GROSS_AMOUNT)) AS TOTAL_CHF_VOLUME,          -- Total trading volume in CHF
    SUM(t.BASE_GROSS_AMOUNT) AS NET_CHF_POSITION,               -- Net position (positive = net buyer, negative = net seller)
    SUM(t.COMMISSION) AS TOTAL_COMMISSION_CHF,                   -- Total commission fees paid
    AVG(ABS(t.BASE_GROSS_AMOUNT)) AS AVG_TRADE_SIZE_CHF,        -- Average trade size for customer profiling
    MIN(t.TRADE_DATE) AS FIRST_TRADE_DATE,                       -- First trading activity date
    MAX(t.TRADE_DATE) AS LAST_TRADE_DATE                         -- Most recent trading activity date
FROM EQT_RAW_001.EQTI_RAW_TB_TRADES t
LEFT JOIN CRM_AGG_001.ACCA_AGG_DT_ACCOUNTS a ON t.ACCOUNT_ID = a.ACCOUNT_ID
GROUP BY t.CUSTOMER_ID, t.ACCOUNT_ID, a.BASE_CURRENCY;

-- Equity position summary by symbol
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_EQUITY_POSITIONS(
    SYMBOL VARCHAR(20) COMMENT 'Security symbol for position tracking',
    ISIN VARCHAR(12) COMMENT 'International Securities Identification Number',
    UNIQUE_CUSTOMERS NUMBER(10,0) COMMENT 'Number of customers holding this security',
    NET_POSITION DECIMAL(28,2) COMMENT 'Net position across all customers (positive = long, negative = short)',
    TOTAL_BOUGHT DECIMAL(28,2) COMMENT 'Total quantity purchased',
    TOTAL_SOLD DECIMAL(28,2) COMMENT 'Total quantity sold',
    TOTAL_TRADES NUMBER(10,0) COMMENT 'Total number of trades in this security',
    TOTAL_CHF_VOLUME DECIMAL(28,2) COMMENT 'Total trading volume in CHF',
    AVG_PRICE DECIMAL(15,4) COMMENT 'Average trading price',
    MIN_PRICE DECIMAL(15,4) COMMENT 'Lowest trading price observed',
    MAX_PRICE DECIMAL(15,4) COMMENT 'Highest trading price observed',
    LAST_TRADE_DATE DATE COMMENT 'Most recent trading date for this security'
) COMMENT = 'Concentration Risk and Market Exposure by Security: To track the aggregate net position (long/short) for every traded security across all customers.
Market Risk: Identifies securities where the banks customers have high volume or concentrated positions, which could impact liquidity and require capital provisioning.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    SYMBOL,                                                      -- Security symbol for position tracking
    ISIN,                                                        -- International Securities Identification Number
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS,            -- Number of customers holding this security
    SUM(CASE WHEN SIDE = '1' THEN QUANTITY ELSE -QUANTITY END) AS NET_POSITION, -- Net position across all customers (positive = long, negative = short)
    SUM(CASE WHEN SIDE = '1' THEN QUANTITY ELSE 0 END) AS TOTAL_BOUGHT,         -- Total quantity purchased
    SUM(CASE WHEN SIDE = '2' THEN QUANTITY ELSE 0 END) AS TOTAL_SOLD,           -- Total quantity sold
    COUNT(*) AS TOTAL_TRADES,                                    -- Total number of trades in this security
    SUM(ABS(BASE_GROSS_AMOUNT)) AS TOTAL_CHF_VOLUME,            -- Total trading volume in CHF
    AVG(PRICE) AS AVG_PRICE,                                     -- Average trading price
    MIN(PRICE) AS MIN_PRICE,                                     -- Lowest trading price observed
    MAX(PRICE) AS MAX_PRICE,                                     -- Highest trading price observed
    MAX(TRADE_DATE) AS LAST_TRADE_DATE                           -- Most recent trading date for this security
FROM EQT_RAW_001.EQTI_RAW_TB_TRADES
GROUP BY SYMBOL, ISIN;

-- Equity currency exposure (similar to FX exposure for trades)
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE(
    CURRENCY VARCHAR(3) COMMENT 'Trading currency for FX exposure analysis',
    TRADE_COUNT NUMBER(10,0) COMMENT 'Number of equity trades in this currency',
    TOTAL_ORIGINAL_VOLUME DECIMAL(28,2) COMMENT 'Total trading volume in original currency',
    TOTAL_CHF_VOLUME DECIMAL(28,2) COMMENT 'Total trading volume converted to CHF',
    AVG_FX_RATE DECIMAL(15,6) COMMENT 'Average FX rate used for currency conversion',
    MIN_FX_RATE DECIMAL(15,6) COMMENT 'Minimum FX rate observed',
    MAX_FX_RATE DECIMAL(15,6) COMMENT 'Maximum FX rate observed',
    UNIQUE_CUSTOMERS NUMBER(10,0) COMMENT 'Number of customers trading in this currency',
    UNIQUE_SYMBOLS NUMBER(10,0) COMMENT 'Number of different securities traded in this currency'
) COMMENT = 'FX Risk from Foreign Equity Trading: To measure the currency exposure generated specifically by trading securities denominated in non-base currencies.	
Market Risk/Treasury: Isolates the FX risk component of the trading book, ensuring accurate currency hedging and compliance with non-base currency exposure limits.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    CURRENCY,                                                    -- Trading currency for FX exposure analysis
    COUNT(*) AS TRADE_COUNT,                                     -- Number of equity trades in this currency
    SUM(ABS(GROSS_AMOUNT)) AS TOTAL_ORIGINAL_VOLUME,            -- Total trading volume in original currency
    SUM(ABS(BASE_GROSS_AMOUNT)) AS TOTAL_CHF_VOLUME,            -- Total trading volume converted to CHF
    AVG(FX_RATE) AS AVG_FX_RATE,                                 -- Average FX rate used for currency conversion
    MIN(FX_RATE) AS MIN_FX_RATE,                                 -- Minimum FX rate observed
    MAX(FX_RATE) AS MAX_FX_RATE,                                 -- Maximum FX rate observed
    COUNT(DISTINCT CUSTOMER_ID) AS UNIQUE_CUSTOMERS,            -- Number of customers trading in this currency
    COUNT(DISTINCT SYMBOL) AS UNIQUE_SYMBOLS                    -- Number of different securities traded in this currency
FROM EQT_RAW_001.EQTI_RAW_TB_TRADES
WHERE CURRENCY != 'CHF'
GROUP BY CURRENCY;

-- High-value equity trades (potential compliance monitoring)
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES(
    TRADE_DATE DATE COMMENT 'Trade execution date for compliance tracking',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for large trade monitoring',
    ACCOUNT_ID VARCHAR(30) COMMENT 'Account identifier for position tracking',
    TRADE_ID VARCHAR(50) COMMENT 'Unique trade identifier for audit trail',
    SYMBOL VARCHAR(20) COMMENT 'Security symbol for concentration risk analysis',
    SIDE VARCHAR(1) COMMENT 'Trade direction (1=Buy, 2=Sell)',
    QUANTITY DECIMAL(28,2) COMMENT 'Number of shares/units traded',
    PRICE DECIMAL(15,4) COMMENT 'Execution price per unit',
    CHF_VALUE DECIMAL(28,2) COMMENT 'Trade value in CHF for threshold monitoring',
    MARKET VARCHAR(20) COMMENT 'Market/exchange where trade was executed',
    VENUE VARCHAR(20) COMMENT 'Trading venue for best execution analysis'
) COMMENT = 'Large Trade Compliance Monitoring: To filter and track all equity trades exceeding a significant value threshold (e.g., 100k CHF).	
Compliance/Audit: Essential for compliance monitoring to detect potential market manipulation, front-running, or unauthorized large trading activity that requires immediate review and audit trail maintenance.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    TRADE_DATE,                                                  -- Trade execution date for compliance tracking
    CUSTOMER_ID,                                                 -- Customer identifier for large trade monitoring
    ACCOUNT_ID,                                                  -- Account identifier for position tracking
    TRADE_ID,                                                    -- Unique trade identifier for audit trail
    SYMBOL,                                                      -- Security symbol for concentration risk analysis
    SIDE,                                                        -- Trade direction (1=Buy, 2=Sell)
    QUANTITY,                                                    -- Number of shares/units traded
    PRICE,                                                       -- Execution price per unit
    ABS(BASE_GROSS_AMOUNT) AS CHF_VALUE,                         -- Trade value in CHF for threshold monitoring
    MARKET,                                                      -- Market/exchange where trade was executed
    VENUE                                                        -- Trading venue for best execution analysis
FROM EQT_RAW_001.EQTI_RAW_TB_TRADES
WHERE ABS(BASE_GROSS_AMOUNT) > 100000 -- Trades over 100k CHF
ORDER BY ABS(BASE_GROSS_AMOUNT) DESC;

-- ============================================================
-- USAGE EXAMPLES
-- ============================================================
--
-- Equity Trading Analytics:
-- SELECT * FROM REPP_AGG_DT_EQUITY_SUMMARY LIMIT 10;
-- SELECT * FROM REPP_AGG_DT_EQUITY_POSITIONS WHERE NET_POSITION != 0 LIMIT 10;
-- SELECT * FROM REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES LIMIT 20;
--
-- Customer trading activity analysis:
-- SELECT CUSTOMER_ID, ACCOUNT_ID, TOTAL_TRADES, TOTAL_CHF_VOLUME, NET_CHF_POSITION
-- FROM REPP_AGG_DT_EQUITY_SUMMARY
-- WHERE TOTAL_TRADES > 10
-- ORDER BY TOTAL_CHF_VOLUME DESC;
--
-- Position concentration risk:
-- SELECT SYMBOL, UNIQUE_CUSTOMERS, NET_POSITION, TOTAL_CHF_VOLUME
-- FROM REPP_AGG_DT_EQUITY_POSITIONS
-- WHERE UNIQUE_CUSTOMERS > 5
-- ORDER BY TOTAL_CHF_VOLUME DESC;
--
-- Currency exposure analysis:
-- SELECT CURRENCY, TRADE_COUNT, TOTAL_CHF_VOLUME, UNIQUE_CUSTOMERS
-- FROM REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE
-- ORDER BY TOTAL_CHF_VOLUME DESC;
--
-- Large trade monitoring:
-- SELECT TRADE_DATE, CUSTOMER_ID, SYMBOL, SIDE, CHF_VALUE
-- FROM REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES
-- WHERE TRADE_DATE >= CURRENT_DATE - 30
-- ORDER BY CHF_VALUE DESC;
--
-- To check dynamic table refresh status:
-- SHOW DYNAMIC TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001;
--
-- To manually refresh a dynamic table:
-- ALTER DYNAMIC TABLE REPP_AGG_DT_EQUITY_SUMMARY REFRESH;
-- ALTER DYNAMIC TABLE REPP_AGG_DT_EQUITY_POSITIONS REFRESH;
-- ALTER DYNAMIC TABLE REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE REFRESH;
-- ALTER DYNAMIC TABLE REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES REFRESH;
--
-- ============================================================
-- 510_REPP_EQUITY.sql - Equity Trading Reporting completed!
-- ============================================================
