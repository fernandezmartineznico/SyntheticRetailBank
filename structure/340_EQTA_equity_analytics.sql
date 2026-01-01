-- ============================================================
-- EQT_AGG_001 Schema - Equity Trading Aggregation & Analytics
-- Generated on: 2025-10-05
-- ============================================================
--
-- OVERVIEW:
-- This schema provides aggregated views and analytics for equity trading data.
-- It transforms raw FIX protocol trades from EQT_RAW_001.EQTI_RAW_TB_TRADES into 
-- business-ready analytical views for portfolio management, performance tracking,
-- and risk management.
--
-- BUSINESS PURPOSE:
-- - Portfolio position tracking (current holdings per customer/account)
-- - Trade analytics and execution quality monitoring
-- - Profit and Loss (P&L) calculation per position
-- - Trading activity analysis and pattern detection
-- - Market exposure and concentration risk monitoring
-- - Customer investment behavior analytics
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (3):
-- │  ├─ EQTA_AGG_DT_TRADE_SUMMARY       - Trade-level analytics with enriched metadata
-- │  ├─ EQTA_AGG_DT_PORTFOLIO_POSITIONS - Current holdings and positions per account
-- │  └─ EQTA_AGG_DT_CUSTOMER_ACTIVITY   - Customer trading activity and behavior metrics
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- DATA FLOW:
-- EQT_RAW_001.EQTI_RAW_TB_TRADES (raw FIX protocol trades)
--     ↓
-- EQTA_AGG_DT_TRADE_SUMMARY (enriched trade analytics)
--     ↓
-- EQTA_AGG_DT_PORTFOLIO_POSITIONS (current holdings)
--     ↓
-- EQTA_AGG_DT_CUSTOMER_ACTIVITY (customer behavior)
--
-- RELATED SCHEMAS:
-- - EQT_RAW_001: Source equity trading data (FIX protocol)
-- - CRM_RAW_001: Customer and account master data
-- - REF_RAW_001: FX rates for currency conversion
-- - PAY_AGG_001: Account balances for cash settlement
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA EQT_AGG_001;

-- ============================================================
-- EQTA_AGG_DT_TRADE_SUMMARY - Enriched Trade Analytics
-- ============================================================
-- Trade-level view with enriched metadata, performance metrics, and classifications.
-- Provides comprehensive trade analytics for execution quality monitoring and reporting.

CREATE OR REPLACE DYNAMIC TABLE EQTA_AGG_DT_TRADE_SUMMARY(
    TRADE_ID VARCHAR(50) COMMENT 'Unique trade identifier',
    TRADE_DATE TIMESTAMP_NTZ COMMENT 'Trade execution timestamp',
    SETTLEMENT_DATE DATE COMMENT 'Settlement date for cash/securities transfer',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer who executed the trade',
    ACCOUNT_ID VARCHAR(30) COMMENT 'Investment account used for settlement',
    ORDER_ID VARCHAR(50) COMMENT 'Order reference for trade grouping',
    EXEC_ID VARCHAR(50) COMMENT 'Execution reference',
    SYMBOL VARCHAR(20) COMMENT 'Stock symbol/ticker',
    ISIN VARCHAR(12) COMMENT 'International Securities Identification Number',
    SIDE CHAR(1) COMMENT 'Trade side (1=Buy, 2=Sell)',
    SIDE_DESCRIPTION VARCHAR(4) COMMENT 'Trade side description (BUY/SELL)',
    QUANTITY NUMBER(15,4) COMMENT 'Number of shares/units traded',
    PRICE NUMBER(18,4) COMMENT 'Execution price per share',
    CURRENCY VARCHAR(3) COMMENT 'Trade currency',
    GROSS_AMOUNT NUMBER(18,2) COMMENT 'Gross trade amount in trade currency',
    COMMISSION NUMBER(12,4) COMMENT 'Trading commission charged',
    NET_AMOUNT NUMBER(18,2) COMMENT 'Net amount after commission',
    BASE_CURRENCY VARCHAR(3) COMMENT 'Base reporting currency (CHF)',
    BASE_GROSS_AMOUNT NUMBER(18,2) COMMENT 'Gross amount in CHF',
    BASE_NET_AMOUNT NUMBER(18,2) COMMENT 'Net amount in CHF',
    FX_RATE NUMBER(15,6) COMMENT 'Exchange rate used for conversion to CHF',
    MARKET VARCHAR(20) COMMENT 'Exchange/market where trade was executed',
    ORDER_TYPE VARCHAR(10) COMMENT 'Order type (MARKET/LIMIT/STOP)',
    EXEC_TYPE VARCHAR(15) COMMENT 'Execution type (NEW/FILL/PARTIAL_FILL)',
    TIME_IN_FORCE VARCHAR(3) COMMENT 'Time in force instruction (DAY/GTC/IOC)',
    BROKER_ID VARCHAR(20) COMMENT 'Executing broker identifier',
    VENUE VARCHAR(20) COMMENT 'Trading venue',
    COMMISSION_RATE_BPS NUMBER(8,2) COMMENT 'Commission rate in basis points (bps)',
    TRADE_VALUE_CATEGORY VARCHAR(10) COMMENT 'Trade size category (SMALL/MEDIUM/LARGE/VERY_LARGE)',
    SETTLEMENT_DAYS NUMBER(3,0) COMMENT 'Days between trade and settlement',
    TRADE_YEAR NUMBER(4,0) COMMENT 'Year of trade execution',
    TRADE_MONTH NUMBER(2,0) COMMENT 'Month of trade execution',
    TRADE_DAY_OF_WEEK NUMBER(1,0) COMMENT 'Day of week (1=Monday, 7=Sunday)',
    CREATED_AT TIMESTAMP_NTZ COMMENT 'Timestamp when trade was recorded in system'
) COMMENT = 'Enriched trade-level analytics with metadata, classifications, and performance metrics. Provides comprehensive view of all equity trades for execution quality monitoring, reporting, and compliance.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Trade Identification
    t.TRADE_ID,
    t.TRADE_DATE,
    t.SETTLEMENT_DATE,
    t.CUSTOMER_ID,
    t.ACCOUNT_ID,
    t.ORDER_ID,
    t.EXEC_ID,
    
    -- Security Information
    t.SYMBOL,
    t.ISIN,
    t.SIDE,
    CASE t.SIDE 
        WHEN '1' THEN 'BUY'
        WHEN '2' THEN 'SELL'
        ELSE 'UNKNOWN'
    END AS SIDE_DESCRIPTION,
    
    -- Trade Details
    t.QUANTITY,
    t.PRICE,
    t.CURRENCY,
    t.GROSS_AMOUNT,
    t.COMMISSION,
    t.NET_AMOUNT,
    
    -- Base Currency (CHF)
    t.BASE_CURRENCY,
    t.BASE_GROSS_AMOUNT,
    t.BASE_NET_AMOUNT,
    t.FX_RATE,
    
    -- Execution Details
    t.MARKET,
    t.ORDER_TYPE,
    t.EXEC_TYPE,
    t.TIME_IN_FORCE,
    t.BROKER_ID,
    t.VENUE,
    
    -- Calculated Metrics
    -- Commission rate in basis points (1 bp = 0.01%)
    ROUND(
        CASE 
            WHEN ABS(t.GROSS_AMOUNT) > 0 THEN
                (t.COMMISSION / ABS(t.GROSS_AMOUNT)) * 10000
            ELSE 0
        END, 2
    ) AS COMMISSION_RATE_BPS,
    
    -- Trade value categorization
    CASE 
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 1000000 THEN 'VERY_LARGE'
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 100000 THEN 'LARGE'
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 10000 THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS TRADE_VALUE_CATEGORY,
    
    -- Settlement period
    DATEDIFF(DAY, t.TRADE_DATE, t.SETTLEMENT_DATE) AS SETTLEMENT_DAYS,
    
    -- Time dimensions for analytics
    YEAR(t.TRADE_DATE) AS TRADE_YEAR,
    MONTH(t.TRADE_DATE) AS TRADE_MONTH,
    DAYOFWEEK(t.TRADE_DATE) AS TRADE_DAY_OF_WEEK,
    
    -- Metadata
    t.CREATED_AT

FROM EQT_RAW_001.EQTI_RAW_TB_TRADES t
ORDER BY t.TRADE_DATE DESC;

-- ============================================================
-- EQTA_AGG_DT_PORTFOLIO_POSITIONS - Current Holdings & Positions
-- ============================================================
-- Current portfolio positions per account/symbol showing holdings, average cost,
-- and P and L. Aggregates all buy/sell trades to calculate net positions.

CREATE OR REPLACE DYNAMIC TABLE EQTA_AGG_DT_PORTFOLIO_POSITIONS(
    ACCOUNT_ID VARCHAR(30) COMMENT 'Investment account identifier',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier',
    SYMBOL VARCHAR(20) COMMENT 'Stock symbol/ticker',
    ISIN VARCHAR(12) COMMENT 'International Securities Identification Number',
    CURRENCY VARCHAR(3) COMMENT 'Trading currency for this position',
    TOTAL_QUANTITY NUMBER(15,4) COMMENT 'Net position quantity (positive=long, negative=short, zero=closed)',
    TOTAL_BUYS NUMBER(15,4) COMMENT 'Total shares purchased',
    TOTAL_SELLS NUMBER(15,4) COMMENT 'Total shares sold',
    AVERAGE_BUY_PRICE NUMBER(18,4) COMMENT 'Volume-weighted average buy price',
    AVERAGE_SELL_PRICE NUMBER(18,4) COMMENT 'Volume-weighted average sell price',
    TOTAL_BUY_AMOUNT NUMBER(18,2) COMMENT 'Total amount spent on purchases (in trade currency)',
    TOTAL_SELL_AMOUNT NUMBER(18,2) COMMENT 'Total amount received from sales (in trade currency)',
    TOTAL_COMMISSION NUMBER(12,4) COMMENT 'Total commission paid on all trades',
    NET_INVESTMENT NUMBER(18,2) COMMENT 'Net investment amount (buys - sells + commission)',
    TOTAL_BUY_AMOUNT_CHF NUMBER(18,2) COMMENT 'Total purchase amount in CHF',
    TOTAL_SELL_AMOUNT_CHF NUMBER(18,2) COMMENT 'Total sales amount in CHF',
    NET_INVESTMENT_CHF NUMBER(18,2) COMMENT 'Net investment in CHF',
    REALIZED_PL_CHF NUMBER(18,2) COMMENT 'Realized profit/loss in CHF (for closed/partial positions)',
    POSITION_STATUS VARCHAR(10) COMMENT 'Position status (LONG/SHORT/CLOSED)',
    FIRST_TRADE_DATE DATE COMMENT 'Date of first trade for this position',
    LAST_TRADE_DATE DATE COMMENT 'Date of most recent trade',
    TRADE_COUNT NUMBER(10,0) COMMENT 'Total number of trades for this position',
    HOLDING_DAYS NUMBER(10,0) COMMENT 'Days since first trade',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when position was last calculated'
) COMMENT = 'Current portfolio positions per account and symbol. Aggregates all trades to show net holdings, average costs, and realized P and L. Used for portfolio management, risk monitoring, and performance reporting.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.ACCOUNT_ID,
    t.CUSTOMER_ID,
    t.SYMBOL,
    t.ISIN,
    t.CURRENCY,
    
    -- Net Position Calculation
    -- Buy trades (SIDE='1') add to position, Sell trades (SIDE='2') reduce position
    SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) - 
    SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END) AS TOTAL_QUANTITY,
    
    SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) AS TOTAL_BUYS,
    SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END) AS TOTAL_SELLS,
    
    -- Average Prices (volume-weighted)
    ROUND(
        CASE 
            WHEN SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) > 0 THEN
                SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY * t.PRICE ELSE 0 END) / 
                SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END)
            ELSE 0
        END, 6
    ) AS AVERAGE_BUY_PRICE,
    
    ROUND(
        CASE 
            WHEN SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END) > 0 THEN
                SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY * t.PRICE ELSE 0 END) / 
                SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END)
            ELSE 0
        END, 6
    ) AS AVERAGE_SELL_PRICE,
    
    -- Trade Currency Amounts
    ROUND(SUM(CASE WHEN t.SIDE = '1' THEN ABS(t.GROSS_AMOUNT) ELSE 0 END), 2) AS TOTAL_BUY_AMOUNT,
    ROUND(SUM(CASE WHEN t.SIDE = '2' THEN ABS(t.GROSS_AMOUNT) ELSE 0 END), 2) AS TOTAL_SELL_AMOUNT,
    ROUND(SUM(t.COMMISSION), 2) AS TOTAL_COMMISSION,
    ROUND(
        SUM(CASE WHEN t.SIDE = '1' THEN ABS(t.GROSS_AMOUNT) ELSE 0 END) - 
        SUM(CASE WHEN t.SIDE = '2' THEN ABS(t.GROSS_AMOUNT) ELSE 0 END) + 
        SUM(t.COMMISSION), 2
    ) AS NET_INVESTMENT,
    
    -- CHF Amounts
    ROUND(SUM(CASE WHEN t.SIDE = '1' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END), 2) AS TOTAL_BUY_AMOUNT_CHF,
    ROUND(SUM(CASE WHEN t.SIDE = '2' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END), 2) AS TOTAL_SELL_AMOUNT_CHF,
    ROUND(
        SUM(CASE WHEN t.SIDE = '1' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END) - 
        SUM(CASE WHEN t.SIDE = '2' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END), 2
    ) AS NET_INVESTMENT_CHF,
    
    -- Realized P and L (only for shares that have been sold)
    ROUND(
        SUM(CASE WHEN t.SIDE = '2' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END) - 
        (
            CASE 
                WHEN SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END) > 0 
                 AND SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) > 0 THEN
                    (SUM(CASE WHEN t.SIDE = '1' THEN ABS(t.BASE_GROSS_AMOUNT) ELSE 0 END) / 
                     SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END)) * 
                    SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END)
                ELSE 0
            END
        ), 2
    ) AS REALIZED_PL_CHF,
    
    -- Position Status
    CASE 
        WHEN (SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) - 
              SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END)) > 0 THEN 'LONG'
        WHEN (SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) - 
              SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END)) < 0 THEN 'SHORT'
        ELSE 'CLOSED'
    END AS POSITION_STATUS,
    
    -- Time Dimensions
    MIN(t.TRADE_DATE) AS FIRST_TRADE_DATE,
    MAX(t.TRADE_DATE) AS LAST_TRADE_DATE,
    COUNT(*) AS TRADE_COUNT,
    DATEDIFF(DAY, MIN(t.TRADE_DATE), CURRENT_DATE) AS HOLDING_DAYS,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM EQT_RAW_001.EQTI_RAW_TB_TRADES t
GROUP BY t.ACCOUNT_ID, t.CUSTOMER_ID, t.SYMBOL, t.ISIN, t.CURRENCY
ORDER BY t.ACCOUNT_ID, t.SYMBOL;

-- ============================================================
-- EQTA_AGG_DT_CUSTOMER_ACTIVITY - Customer Trading Behavior
-- ============================================================
-- Customer-level trading activity metrics and behavior analysis.
-- Provides insights into trading patterns, preferences, and engagement levels.

CREATE OR REPLACE DYNAMIC TABLE EQTA_AGG_DT_CUSTOMER_ACTIVITY(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier',
    TOTAL_TRADES NUMBER(10,0) COMMENT 'Total number of trades executed',
    TOTAL_BUY_TRADES NUMBER(10,0) COMMENT 'Number of buy trades',
    TOTAL_SELL_TRADES NUMBER(10,0) COMMENT 'Number of sell trades',
    UNIQUE_SYMBOLS NUMBER(10,0) COMMENT 'Number of unique symbols traded',
    UNIQUE_ACCOUNTS NUMBER(10,0) COMMENT 'Number of investment accounts used',
    TOTAL_VOLUME_CHF NUMBER(18,2) COMMENT 'Total trading volume in CHF (sum of all trade values)',
    TOTAL_COMMISSION_CHF NUMBER(18,2) COMMENT 'Total commission paid in CHF',
    AVERAGE_TRADE_SIZE_CHF NUMBER(18,2) COMMENT 'Average trade size in CHF',
    LARGEST_TRADE_CHF NUMBER(18,2) COMMENT 'Largest single trade value in CHF',
    AVERAGE_COMMISSION_BPS NUMBER(8,2) COMMENT 'Average commission rate in basis points',
    FIRST_TRADE_DATE DATE COMMENT 'Date of first trade',
    LAST_TRADE_DATE DATE COMMENT 'Date of most recent trade',
    TRADING_DAYS NUMBER(10,0) COMMENT 'Number of distinct days with trading activity',
    CUSTOMER_TENURE_DAYS NUMBER(10,0) COMMENT 'Days since first trade',
    AVERAGE_TRADES_PER_MONTH NUMBER(8,2) COMMENT 'Average number of trades per month',
    MOST_TRADED_SYMBOL VARCHAR(20) COMMENT 'Symbol with highest trade count',
    MOST_TRADED_SYMBOL_COUNT NUMBER(10,0) COMMENT 'Number of trades for most traded symbol',
    PREFERRED_MARKET VARCHAR(20) COMMENT 'Market with highest trade count',
    PREFERRED_ORDER_TYPE VARCHAR(10) COMMENT 'Most frequently used order type',
    TRADER_CATEGORY VARCHAR(15) COMMENT 'Trading activity category (VERY_ACTIVE/ACTIVE/MODERATE/OCCASIONAL/INACTIVE)',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when metrics were calculated'
) COMMENT = 'Customer-level trading activity and behavior metrics. Aggregates all trades per customer to provide insights into trading patterns, preferences, and engagement levels for relationship management and analytics.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
WITH customer_trades AS (
    SELECT 
        t.CUSTOMER_ID,
        t.TRADE_ID,
        t.TRADE_DATE,
        t.SIDE,
        t.SYMBOL,
        t.ACCOUNT_ID,
        t.MARKET,
        t.ORDER_TYPE,
        ABS(t.BASE_GROSS_AMOUNT) as trade_value_chf,
        t.COMMISSION as commission_chf,
        CASE 
            WHEN ABS(t.GROSS_AMOUNT) > 0 THEN (t.COMMISSION / ABS(t.GROSS_AMOUNT)) * 10000
            ELSE 0
        END as commission_bps
    FROM EQT_RAW_001.EQTI_RAW_TB_TRADES t
),
symbol_counts AS (
    SELECT 
        CUSTOMER_ID,
        SYMBOL,
        COUNT(*) as trade_count,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(*) DESC) as rn
    FROM customer_trades
    GROUP BY CUSTOMER_ID, SYMBOL
),
market_counts AS (
    SELECT 
        CUSTOMER_ID,
        MARKET,
        COUNT(*) as trade_count,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(*) DESC) as rn
    FROM customer_trades
    GROUP BY CUSTOMER_ID, MARKET
),
order_type_counts AS (
    SELECT 
        CUSTOMER_ID,
        ORDER_TYPE,
        COUNT(*) as trade_count,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY COUNT(*) DESC) as rn
    FROM customer_trades
    GROUP BY CUSTOMER_ID, ORDER_TYPE
)
SELECT 
    ct.CUSTOMER_ID,
    
    -- Trade Counts
    COUNT(*) AS TOTAL_TRADES,
    COUNT(CASE WHEN ct.SIDE = '1' THEN 1 END) AS TOTAL_BUY_TRADES,
    COUNT(CASE WHEN ct.SIDE = '2' THEN 1 END) AS TOTAL_SELL_TRADES,
    COUNT(DISTINCT ct.SYMBOL) AS UNIQUE_SYMBOLS,
    COUNT(DISTINCT ct.ACCOUNT_ID) AS UNIQUE_ACCOUNTS,
    
    -- Financial Metrics
    ROUND(SUM(ct.trade_value_chf), 2) AS TOTAL_VOLUME_CHF,
    ROUND(SUM(ct.commission_chf), 2) AS TOTAL_COMMISSION_CHF,
    ROUND(AVG(ct.trade_value_chf), 2) AS AVERAGE_TRADE_SIZE_CHF,
    ROUND(MAX(ct.trade_value_chf), 2) AS LARGEST_TRADE_CHF,
    ROUND(AVG(ct.commission_bps), 2) AS AVERAGE_COMMISSION_BPS,
    
    -- Time Dimensions
    MIN(ct.TRADE_DATE) AS FIRST_TRADE_DATE,
    MAX(ct.TRADE_DATE) AS LAST_TRADE_DATE,
    COUNT(DISTINCT DATE(ct.TRADE_DATE)) AS TRADING_DAYS,
    DATEDIFF(DAY, MIN(ct.TRADE_DATE), CURRENT_DATE) AS CUSTOMER_TENURE_DAYS,
    
    -- Activity Frequency
    ROUND(
        CASE 
            WHEN DATEDIFF(MONTH, MIN(ct.TRADE_DATE), MAX(ct.TRADE_DATE)) > 0 THEN
                COUNT(*) * 1.0 / DATEDIFF(MONTH, MIN(ct.TRADE_DATE), MAX(ct.TRADE_DATE))
            ELSE COUNT(*) * 1.0
        END, 2
    ) AS AVERAGE_TRADES_PER_MONTH,
    
    -- Preferences
    MAX(CASE WHEN sc.rn = 1 THEN sc.SYMBOL END) AS MOST_TRADED_SYMBOL,
    MAX(CASE WHEN sc.rn = 1 THEN sc.trade_count END) AS MOST_TRADED_SYMBOL_COUNT,
    MAX(CASE WHEN mc.rn = 1 THEN mc.MARKET END) AS PREFERRED_MARKET,
    MAX(CASE WHEN otc.rn = 1 THEN otc.ORDER_TYPE END) AS PREFERRED_ORDER_TYPE,
    
    -- Customer Categorization
    CASE 
        WHEN COUNT(*) >= 100 THEN 'VERY_ACTIVE'
        WHEN COUNT(*) >= 50 THEN 'ACTIVE'
        WHEN COUNT(*) >= 20 THEN 'MODERATE'
        WHEN COUNT(*) >= 5 THEN 'OCCASIONAL'
        ELSE 'INACTIVE'
    END AS TRADER_CATEGORY,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM customer_trades ct
LEFT JOIN symbol_counts sc ON ct.CUSTOMER_ID = sc.CUSTOMER_ID AND sc.rn = 1
LEFT JOIN market_counts mc ON ct.CUSTOMER_ID = mc.CUSTOMER_ID AND mc.rn = 1
LEFT JOIN order_type_counts otc ON ct.CUSTOMER_ID = otc.CUSTOMER_ID AND otc.rn = 1
GROUP BY ct.CUSTOMER_ID
ORDER BY TOTAL_TRADES DESC;

-- ============================================================
-- EQT_AGG_001 Schema Setup Complete!
-- ============================================================
--
-- DYNAMIC TABLE REFRESH STATUS:
-- All three dynamic tables will automatically refresh based on changes to the
-- source table (EQTI_RAW_TB_TRADES) with a 1-hour target lag.
--
-- USAGE EXAMPLES:
--
-- 1. View enriched trade details:
--    SELECT * FROM EQTA_AGG_DT_TRADE_SUMMARY 
--    WHERE TRADE_DATE >= CURRENT_DATE - 30
--    ORDER BY TRADE_DATE DESC;
--
-- 2. Check current portfolio positions:
--    SELECT * FROM EQTA_AGG_DT_PORTFOLIO_POSITIONS 
--    WHERE POSITION_STATUS = 'LONG'
--    ORDER BY NET_INVESTMENT_CHF DESC;
--
-- 3. Find positions with realized gains:
--    SELECT CUSTOMER_ID, SYMBOL, REALIZED_PL_CHF, TOTAL_SELLS
--    FROM EQTA_AGG_DT_PORTFOLIO_POSITIONS 
--    WHERE REALIZED_PL_CHF > 0
--    ORDER BY REALIZED_PL_CHF DESC;
--
-- 4. Analyze customer trading activity:
--    SELECT * FROM EQTA_AGG_DT_CUSTOMER_ACTIVITY 
--    WHERE TRADER_CATEGORY IN ('VERY_ACTIVE', 'ACTIVE')
--    ORDER BY TOTAL_VOLUME_CHF DESC;
--
-- 5. Find high-value trades:
--    SELECT CUSTOMER_ID, SYMBOL, SIDE_DESCRIPTION, BASE_GROSS_AMOUNT, TRADE_DATE
--    FROM EQTA_AGG_DT_TRADE_SUMMARY 
--    WHERE TRADE_VALUE_CATEGORY IN ('LARGE', 'VERY_LARGE')
--    ORDER BY BASE_GROSS_AMOUNT DESC;
--
-- 6. Customer portfolio summary:
--    SELECT 
--        p.CUSTOMER_ID,
--        COUNT(*) as open_positions,
--        SUM(p.NET_INVESTMENT_CHF) as total_invested,
--        SUM(p.REALIZED_PL_CHF) as total_realized_pl
--    FROM EQTA_AGG_DT_PORTFOLIO_POSITIONS p
--    WHERE p.POSITION_STATUS != 'CLOSED'
--    GROUP BY p.CUSTOMER_ID
--    ORDER BY total_invested DESC;
--
-- MONITORING:
-- - Monitor dynamic table refresh: SHOW DYNAMIC TABLES IN SCHEMA EQT_AGG_001;
-- - Check refresh history: SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY());
-- - Validate data quality: Compare trade counts between raw and aggregated tables
--
-- PERFORMANCE OPTIMIZATION:
-- - Dynamic tables automatically maintain incremental refresh
-- - Consider clustering on CUSTOMER_ID and TRADE_DATE for large datasets
-- - Monitor warehouse usage during refresh periods
--
-- RELATED SCHEMAS:
-- - EQT_RAW_001: Source equity trading data
-- - CRM_RAW_001: Customer and account master data (join on CUSTOMER_ID, ACCOUNT_ID)
-- - REF_RAW_001: FX rates for currency conversion
-- - PAY_AGG_001: Account balances for cash settlement verification
-- ============================================================
