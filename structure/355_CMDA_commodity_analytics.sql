-- ============================================================
-- CMD_AGG_001 Schema - Commodity Aggregation & Analytics
-- Generated on: 2025-10-05
-- ============================================================
--
-- OVERVIEW:
-- This schema provides aggregated views and analytics for commodity trading data.
-- It transforms raw commodity trades from CMD_RAW_001.CMDI_RAW_TB_TRADES into 
-- business-ready analytical views for commodity risk management, physical delivery
-- tracking, and FRTB capital calculations.
--
-- BUSINESS PURPOSE:
-- - Commodity price risk management (delta exposure analytics)
-- - Volatility monitoring and VaR calculations
-- - Portfolio position tracking (current holdings per customer)
-- - Physical delivery obligation tracking and logistics
-- - FRTB Standardized Approach capital calculations
-- - Regulatory reporting and compliance
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (5):
-- │  ├─ CMDA_AGG_DT_TRADE_SUMMARY - Enriched trade-level analytics
-- │  ├─ CMDA_AGG_DT_PORTFOLIO_POSITIONS - Current holdings by commodity type
-- │  ├─ CMDA_AGG_DT_DELTA_EXPOSURE - Price risk by commodity class
-- │  ├─ CMDA_AGG_DT_VOLATILITY_ANALYSIS - Volatility metrics and trends
-- │  └─ CMDA_AGG_DT_DELIVERY_SCHEDULE - Physical delivery tracking
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 60 minutes (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- DATA FLOW:
-- CMD_RAW_001.CMDI_RAW_TB_TRADES (raw trades)
--     ↓
-- CMDA_AGG_DT_TRADE_SUMMARY (enriched analytics)
--     ↓
-- CMDA_AGG_DT_PORTFOLIO_POSITIONS (current holdings)
--     ↓
-- CMDA_AGG_DT_DELTA_EXPOSURE (price risk)
-- CMDA_AGG_DT_VOLATILITY_ANALYSIS (volatility)
-- CMDA_AGG_DT_DELIVERY_SCHEDULE (delivery tracking)
--
-- RELATED SCHEMAS:
-- - CMD_RAW_001: Source commodity trading data
-- - CRM_RAW_001: Customer and account master data
-- - REF_RAW_001: FX rates for currency conversion
-- - REP_AGG_001: FRTB reporting and capital calculations
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CMD_AGG_001;

-- ============================================================
-- CMDA_AGG_DT_TRADE_SUMMARY - Enriched Trade Analytics
-- ============================================================
-- Trade-level view with enriched metadata, risk metrics, and classifications

CREATE OR REPLACE DYNAMIC TABLE CMDA_AGG_DT_TRADE_SUMMARY(
    TRADE_ID VARCHAR(50) COMMENT 'Unique trade identifier',
    TRADE_DATE TIMESTAMP_NTZ COMMENT 'Trade execution timestamp',
    SETTLEMENT_DATE DATE COMMENT 'Settlement/delivery date',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier',
    ACCOUNT_ID VARCHAR(30) COMMENT 'Investment account',
    COMMODITY_TYPE VARCHAR(20) COMMENT 'ENERGY, PRECIOUS_METAL, BASE_METAL, AGRICULTURAL',
    COMMODITY_NAME VARCHAR(100) COMMENT 'Specific commodity name',
    COMMODITY_CODE VARCHAR(20) COMMENT 'Commodity code',
    CONTRACT_TYPE VARCHAR(20) COMMENT 'SPOT, FUTURE, FORWARD, SWAP',
    SIDE VARCHAR(1) COMMENT '1=Buy, 2=Sell',
    SIDE_DESCRIPTION VARCHAR(10) COMMENT 'BUY or SELL',
    QUANTITY DECIMAL(28,4) COMMENT 'Quantity in commodity units',
    UNIT VARCHAR(20) COMMENT 'Unit of measure',
    PRICE DECIMAL(28,4) COMMENT 'Price per unit',
    CURRENCY VARCHAR(3) COMMENT 'Trading currency',
    GROSS_AMOUNT DECIMAL(28,2) COMMENT 'Gross amount in trade currency',
    NET_AMOUNT DECIMAL(28,2) COMMENT 'Net amount after commission',
    BASE_GROSS_AMOUNT DECIMAL(28,2) COMMENT 'Gross amount in CHF',
    BASE_NET_AMOUNT DECIMAL(28,2) COMMENT 'Net amount in CHF',
    FX_RATE DECIMAL(28,6) COMMENT 'Exchange rate to CHF',
    DELTA DECIMAL(28,2) COMMENT 'Price sensitivity in CHF',
    SPOT_PRICE DECIMAL(28,4) COMMENT 'Current spot price',
    FORWARD_PRICE DECIMAL(28,4) COMMENT 'Forward/futures price',
    VOLATILITY DECIMAL(5,2) COMMENT 'Price volatility (%)',
    LIQUIDITY_SCORE NUMBER(2,0) COMMENT 'Liquidity score (1-10)',
    EXCHANGE VARCHAR(50) COMMENT 'Trading exchange',
    DELIVERY_MONTH VARCHAR(7) COMMENT 'Delivery month',
    DELIVERY_LOCATION VARCHAR(100) COMMENT 'Delivery location',
    TRADE_VALUE_CATEGORY VARCHAR(15) COMMENT 'SMALL/MEDIUM/LARGE/VERY_LARGE',
    VOLATILITY_REGIME VARCHAR(10) COMMENT 'LOW/NORMAL/HIGH/EXTREME',
    CREATED_AT TIMESTAMP_NTZ COMMENT 'Record creation timestamp'
) COMMENT = 'Enriched commodity trade analytics with risk metrics and classifications'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.TRADE_ID,
    t.TRADE_DATE,
    t.SETTLEMENT_DATE,
    t.CUSTOMER_ID,
    t.ACCOUNT_ID,
    t.COMMODITY_TYPE,
    t.COMMODITY_NAME,
    t.COMMODITY_CODE,
    t.CONTRACT_TYPE,
    t.SIDE,
    CASE t.SIDE 
        WHEN '1' THEN 'BUY'
        WHEN '2' THEN 'SELL'
        ELSE 'UNKNOWN'
    END AS SIDE_DESCRIPTION,
    t.QUANTITY,
    t.UNIT,
    t.PRICE,
    t.CURRENCY,
    t.GROSS_AMOUNT,
    t.NET_AMOUNT,
    t.BASE_GROSS_AMOUNT,
    t.BASE_NET_AMOUNT,
    t.FX_RATE,
    t.DELTA,
    t.SPOT_PRICE,
    t.FORWARD_PRICE,
    t.VOLATILITY,
    t.LIQUIDITY_SCORE,
    t.EXCHANGE,
    t.DELIVERY_MONTH,
    t.DELIVERY_LOCATION,
    
    -- Trade value categorization
    CASE 
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 1000000 THEN 'VERY_LARGE'
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 100000 THEN 'LARGE'
        WHEN ABS(t.BASE_GROSS_AMOUNT) >= 10000 THEN 'MEDIUM'
        ELSE 'SMALL'
    END AS TRADE_VALUE_CATEGORY,
    
    -- Volatility regime classification
    CASE 
        WHEN t.VOLATILITY >= 50 THEN 'EXTREME'
        WHEN t.VOLATILITY >= 30 THEN 'HIGH'
        WHEN t.VOLATILITY >= 15 THEN 'NORMAL'
        ELSE 'LOW'
    END AS VOLATILITY_REGIME,
    
    t.CREATED_AT

FROM CMD_RAW_001.CMDI_RAW_TB_TRADES t
ORDER BY t.TRADE_DATE DESC;

-- ============================================================
-- CMDA_AGG_DT_PORTFOLIO_POSITIONS - Current Holdings
-- ============================================================
-- Current portfolio positions by commodity type showing holdings and P&L

CREATE OR REPLACE DYNAMIC TABLE CMDA_AGG_DT_PORTFOLIO_POSITIONS(
    ACCOUNT_ID VARCHAR(30) COMMENT 'Investment account',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier',
    COMMODITY_TYPE VARCHAR(20) COMMENT 'ENERGY, PRECIOUS_METAL, BASE_METAL, AGRICULTURAL',
    COMMODITY_NAME VARCHAR(100) COMMENT 'Specific commodity name',
    COMMODITY_CODE VARCHAR(20) COMMENT 'Commodity code',
    UNIT VARCHAR(20) COMMENT 'Unit of measure',
    TOTAL_QUANTITY DECIMAL(28,4) COMMENT 'Net position quantity',
    TOTAL_BUY_QUANTITY DECIMAL(28,4) COMMENT 'Total quantity bought',
    TOTAL_SELL_QUANTITY DECIMAL(28,4) COMMENT 'Total quantity sold',
    TOTAL_TRADES NUMBER(10,0) COMMENT 'Number of trades',
    TOTAL_INVESTMENT_CHF DECIMAL(28,2) COMMENT 'Total investment in CHF',
    NET_INVESTMENT_CHF DECIMAL(28,2) COMMENT 'Net investment (buys - sells) in CHF',
    REALIZED_PL_CHF DECIMAL(28,2) COMMENT 'Realized profit/loss in CHF',
    AVERAGE_PRICE DECIMAL(28,4) COMMENT 'Volume-weighted average price',
    TOTAL_DELTA_CHF DECIMAL(28,2) COMMENT 'Total delta in CHF',
    AVERAGE_VOLATILITY DECIMAL(5,2) COMMENT 'Average volatility',
    POSITION_STATUS VARCHAR(10) COMMENT 'LONG/SHORT/CLOSED',
    FIRST_TRADE_DATE TIMESTAMP_NTZ COMMENT 'Date of first trade',
    LAST_TRADE_DATE TIMESTAMP_NTZ COMMENT 'Date of most recent trade',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when calculated'
) COMMENT = 'Current commodity portfolio positions by customer and commodity type'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.ACCOUNT_ID,
    t.CUSTOMER_ID,
    t.COMMODITY_TYPE,
    t.COMMODITY_NAME,
    t.COMMODITY_CODE,
    t.UNIT,
    
    -- Net position calculation
    SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE -t.QUANTITY END) AS TOTAL_QUANTITY,
    SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) AS TOTAL_BUY_QUANTITY,
    SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END) AS TOTAL_SELL_QUANTITY,
    
    -- Trade counts
    COUNT(*) AS TOTAL_TRADES,
    
    -- Investment amounts
    SUM(ABS(t.BASE_GROSS_AMOUNT)) AS TOTAL_INVESTMENT_CHF,
    
    -- Net investment (signed amounts: buys are negative, sells are positive)
    ROUND(SUM(t.BASE_NET_AMOUNT), 2) AS NET_INVESTMENT_CHF,
    
    -- Realized P&L calculation (simplified: sell proceeds minus proportional buy cost)
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
    
    -- Average price (volume-weighted)
    ROUND(
        SUM(t.PRICE * t.QUANTITY) / NULLIF(SUM(t.QUANTITY), 0), 2
    ) AS AVERAGE_PRICE,
    
    -- Risk metrics
    SUM(t.DELTA) AS TOTAL_DELTA_CHF,
    ROUND(AVG(t.VOLATILITY), 2) AS AVERAGE_VOLATILITY,
    
    -- Position status
    CASE 
        WHEN SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE -t.QUANTITY END) > 0 THEN 'LONG'
        WHEN SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE -t.QUANTITY END) < 0 THEN 'SHORT'
        ELSE 'CLOSED'
    END AS POSITION_STATUS,
    
    -- Time dimensions
    MIN(t.TRADE_DATE) AS FIRST_TRADE_DATE,
    MAX(t.TRADE_DATE) AS LAST_TRADE_DATE,
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM CMD_RAW_001.CMDI_RAW_TB_TRADES t
GROUP BY t.ACCOUNT_ID, t.CUSTOMER_ID, t.COMMODITY_TYPE, t.COMMODITY_NAME, t.COMMODITY_CODE, t.UNIT
ORDER BY TOTAL_INVESTMENT_CHF DESC;

-- ============================================================
-- CMDA_AGG_DT_DELTA_EXPOSURE - Price Risk by Commodity Class
-- ============================================================
-- Delta exposure aggregated by commodity type for price risk management

CREATE OR REPLACE DYNAMIC TABLE CMDA_AGG_DT_DELTA_EXPOSURE(
    COMMODITY_TYPE VARCHAR(20) COMMENT 'ENERGY, PRECIOUS_METAL, BASE_METAL, AGRICULTURAL',
    TOTAL_POSITIONS NUMBER(10,0) COMMENT 'Number of positions',
    LONG_POSITIONS NUMBER(10,0) COMMENT 'Number of long positions',
    SHORT_POSITIONS NUMBER(10,0) COMMENT 'Number of short positions',
    TOTAL_DELTA_CHF DECIMAL(28,2) COMMENT 'Total delta in CHF',
    LONG_DELTA_CHF DECIMAL(28,2) COMMENT 'Long delta in CHF',
    SHORT_DELTA_CHF DECIMAL(28,2) COMMENT 'Short delta in CHF',
    NET_DELTA_CHF DECIMAL(28,2) COMMENT 'Net delta exposure in CHF',
    LARGEST_SINGLE_POSITION_CHF DECIMAL(28,2) COMMENT 'Largest single position value',
    CONCENTRATION_PERCENTAGE DECIMAL(5,2) COMMENT 'Percentage of total portfolio',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when calculated'
) COMMENT = 'Delta exposure by commodity class for price risk management'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
WITH total_portfolio AS (
    SELECT SUM(ABS(BASE_GROSS_AMOUNT)) AS total_value
    FROM CMD_RAW_001.CMDI_RAW_TB_TRADES
)
SELECT 
    t.COMMODITY_TYPE,
    COUNT(*) AS TOTAL_POSITIONS,
    COUNT(CASE WHEN t.SIDE = '1' THEN 1 END) AS LONG_POSITIONS,
    COUNT(CASE WHEN t.SIDE = '2' THEN 1 END) AS SHORT_POSITIONS,
    
    -- Delta calculations
    SUM(ABS(t.DELTA)) AS TOTAL_DELTA_CHF,
    SUM(CASE WHEN t.SIDE = '1' THEN ABS(t.DELTA) ELSE 0 END) AS LONG_DELTA_CHF,
    SUM(CASE WHEN t.SIDE = '2' THEN ABS(t.DELTA) ELSE 0 END) AS SHORT_DELTA_CHF,
    SUM(CASE WHEN t.SIDE = '1' THEN t.DELTA ELSE -t.DELTA END) AS NET_DELTA_CHF,
    
    MAX(ABS(t.BASE_GROSS_AMOUNT)) AS LARGEST_SINGLE_POSITION_CHF,
    
    ROUND(
        (SUM(ABS(t.BASE_GROSS_AMOUNT)) / tp.total_value) * 100, 2
    ) AS CONCENTRATION_PERCENTAGE,
    
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM CMD_RAW_001.CMDI_RAW_TB_TRADES t
CROSS JOIN total_portfolio tp
GROUP BY t.COMMODITY_TYPE, tp.total_value
ORDER BY TOTAL_DELTA_CHF DESC;

-- ============================================================
-- CMDA_AGG_DT_VOLATILITY_ANALYSIS - Volatility Metrics
-- ============================================================
-- Volatility analysis by commodity for risk assessment

CREATE OR REPLACE DYNAMIC TABLE CMDA_AGG_DT_VOLATILITY_ANALYSIS(
    COMMODITY_NAME VARCHAR(100) COMMENT 'Specific commodity name',
    COMMODITY_TYPE VARCHAR(20) COMMENT 'ENERGY, PRECIOUS_METAL, BASE_METAL, AGRICULTURAL',
    CURRENT_VOLATILITY DECIMAL(5,2) COMMENT 'Current volatility (%)',
    MIN_VOLATILITY DECIMAL(5,2) COMMENT 'Minimum observed volatility',
    MAX_VOLATILITY DECIMAL(5,2) COMMENT 'Maximum observed volatility',
    VOLATILITY_REGIME VARCHAR(10) COMMENT 'LOW/NORMAL/HIGH/EXTREME',
    TRADE_COUNT NUMBER(10,0) COMMENT 'Number of trades',
    TOTAL_VALUE_CHF DECIMAL(28,2) COMMENT 'Total trade value in CHF',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when calculated'
) COMMENT = 'Volatility analysis by commodity for risk assessment'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.COMMODITY_NAME,
    t.COMMODITY_TYPE,
    ROUND(AVG(t.VOLATILITY), 2) AS CURRENT_VOLATILITY,
    ROUND(MIN(t.VOLATILITY), 2) AS MIN_VOLATILITY,
    ROUND(MAX(t.VOLATILITY), 2) AS MAX_VOLATILITY,
    
    -- Volatility regime
    CASE 
        WHEN AVG(t.VOLATILITY) >= 50 THEN 'EXTREME'
        WHEN AVG(t.VOLATILITY) >= 30 THEN 'HIGH'
        WHEN AVG(t.VOLATILITY) >= 15 THEN 'NORMAL'
        ELSE 'LOW'
    END AS VOLATILITY_REGIME,
    
    COUNT(*) AS TRADE_COUNT,
    SUM(ABS(t.BASE_GROSS_AMOUNT)) AS TOTAL_VALUE_CHF,
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM CMD_RAW_001.CMDI_RAW_TB_TRADES t
GROUP BY t.COMMODITY_NAME, t.COMMODITY_TYPE
ORDER BY CURRENT_VOLATILITY DESC;

-- ============================================================
-- CMDA_AGG_DT_DELIVERY_SCHEDULE - Physical Delivery Tracking
-- ============================================================
-- Physical delivery obligations and logistics tracking

CREATE OR REPLACE DYNAMIC TABLE CMDA_AGG_DT_DELIVERY_SCHEDULE(
    DELIVERY_MONTH VARCHAR(7) COMMENT 'Delivery month (YYYY-MM)',
    DELIVERY_LOCATION VARCHAR(100) COMMENT 'Delivery location/hub',
    COMMODITY_TYPE VARCHAR(20) COMMENT 'ENERGY, PRECIOUS_METAL, BASE_METAL, AGRICULTURAL',
    COMMODITY_NAME VARCHAR(100) COMMENT 'Specific commodity name',
    TOTAL_QUANTITY_TO_DELIVER DECIMAL(28,4) COMMENT 'Total quantity for delivery (sells)',
    TOTAL_QUANTITY_TO_RECEIVE DECIMAL(28,4) COMMENT 'Total quantity to receive (buys)',
    NET_DELIVERY_OBLIGATION DECIMAL(28,4) COMMENT 'Net delivery obligation',
    UNIT VARCHAR(20) COMMENT 'Unit of measure',
    CONTRACT_COUNT NUMBER(10,0) COMMENT 'Number of contracts',
    EARLIEST_TRADE_DATE TIMESTAMP_NTZ COMMENT 'Earliest trade date',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when calculated'
) COMMENT = 'Physical delivery schedule and logistics tracking'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    t.DELIVERY_MONTH,
    t.DELIVERY_LOCATION,
    t.COMMODITY_TYPE,
    t.COMMODITY_NAME,
    
    -- Delivery quantities
    SUM(CASE WHEN t.SIDE = '2' THEN t.QUANTITY ELSE 0 END) AS TOTAL_QUANTITY_TO_DELIVER,
    SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE 0 END) AS TOTAL_QUANTITY_TO_RECEIVE,
    SUM(CASE WHEN t.SIDE = '1' THEN t.QUANTITY ELSE -t.QUANTITY END) AS NET_DELIVERY_OBLIGATION,
    
    t.UNIT,
    COUNT(*) AS CONTRACT_COUNT,
    MIN(t.TRADE_DATE) AS EARLIEST_TRADE_DATE,
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM CMD_RAW_001.CMDI_RAW_TB_TRADES t
WHERE t.DELIVERY_MONTH IS NOT NULL
  AND t.CONTRACT_TYPE IN ('FUTURE', 'FORWARD')
GROUP BY t.DELIVERY_MONTH, t.DELIVERY_LOCATION, t.COMMODITY_TYPE, t.COMMODITY_NAME, t.UNIT
ORDER BY t.DELIVERY_MONTH, t.COMMODITY_TYPE;

-- ============================================================
-- CMD_AGG_001 Schema Setup Complete!
-- ============================================================
--
-- USAGE EXAMPLES:
--
-- 1. View current portfolio positions:
--    SELECT * FROM CMDA_AGG_DT_PORTFOLIO_POSITIONS 
--    WHERE POSITION_STATUS != 'CLOSED'
--    ORDER BY TOTAL_INVESTMENT_CHF DESC;
--
-- 2. Analyze delta exposure:
--    SELECT COMMODITY_TYPE, NET_DELTA_CHF, CONCENTRATION_PERCENTAGE
--    FROM CMDA_AGG_DT_DELTA_EXPOSURE
--    ORDER BY ABS(NET_DELTA_CHF) DESC;
--
-- 3. Monitor volatility:
--    SELECT COMMODITY_NAME, CURRENT_VOLATILITY, VOLATILITY_REGIME
--    FROM CMDA_AGG_DT_VOLATILITY_ANALYSIS
--    WHERE VOLATILITY_REGIME IN ('HIGH', 'EXTREME')
--    ORDER BY CURRENT_VOLATILITY DESC;
--
-- 4. Check delivery schedule:
--    SELECT * FROM CMDA_AGG_DT_DELIVERY_SCHEDULE
--    WHERE DELIVERY_MONTH >= TO_CHAR(CURRENT_DATE, 'YYYY-MM')
--    ORDER BY DELIVERY_MONTH, COMMODITY_TYPE;
--
-- 5. Check dynamic table refresh status:
--    SHOW DYNAMIC TABLES IN SCHEMA CMD_AGG_001;
--
-- ============================================================
