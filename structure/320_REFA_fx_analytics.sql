-- ============================================================
-- REF_AGG_001 Schema - Reference Data Aggregation Layer
-- Generated on: 2025-09-29 (FX Rates Aggregation)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides the aggregation layer for reference data, creating
-- enhanced dynamic tables on top of raw reference data from REF_RAW_001.
-- Focuses on foreign exchange rates with business logic and analytics.
--
-- BUSINESS PURPOSE:
-- - Provide enhanced FX rate data with analytics and trends
-- - Enable currency exposure analysis and risk management
-- - Support real-time FX rate lookups for multi-currency operations
-- - Maintain historical FX rate performance and volatility metrics
--
-- AGGREGATION STRATEGY:
-- - Enhanced FX rates with calculated spreads and volatility
-- - Current rates lookup optimized for real-time operations
-- - Historical trend analysis for risk management
-- - Currency pair analytics and market insights
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (1):
-- │  └─ REFA_AGG_DT_FX_RATES_ENHANCED - Enhanced FX rates with analytics
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (aligned with operational requirements)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes from REF_RAW_001.REFI_RAW_TB_FX_RATES
--
-- DATA ARCHITECTURE:
-- Raw FX Rates (REF_RAW_001.REFI_RAW_TB_FX_RATES) → Aggregation (REF_AGG_001.REFA_AGG_DT_FX_RATES_ENHANCED) → Analytics
--
-- SUPPORTED CURRENCIES:
-- - CHF (Swiss Franc) - Bank's base currency
-- - EUR (Euro), USD (US Dollar), GBP (British Pound)
-- - Additional currencies as per business requirements
--
-- RELATED SCHEMAS:
-- - REF_RAW_001: Source FX rates data (REFI_RAW_TB_FX_RATES)
-- - PAY_AGG_001: Payment analytics using FX rates for currency conversion
-- - CRM_AGG_001: Customer analytics with multi-currency support
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REF_AGG_001;

-- ============================================================
-- DYNAMIC TABLES - FX RATES AGGREGATION
-- ============================================================
-- Enhanced FX rates with business logic, volatility metrics, and analytics
-- optimized for real-time currency operations and risk management.

-- ============================================================
-- REFA_AGG_DT_FX_RATES_ENHANCED - Enhanced FX Rates with Analytics
-- ============================================================
-- Comprehensive FX rates aggregation providing current rates, historical trends,
-- volatility metrics, and business intelligence for currency operations.
-- Optimized for real-time lookups and risk management analytics.

CREATE OR REPLACE DYNAMIC TABLE REFA_AGG_DT_FX_RATES_ENHANCED(
    DATE DATE COMMENT 'Date of the FX rate observation for time series analysis',
    FROM_CURRENCY VARCHAR(3) COMMENT 'Source currency code (ISO 4217) for currency conversion',
    TO_CURRENCY VARCHAR(3) COMMENT 'Target currency code (ISO 4217) for currency conversion',
    CURRENCY_PAIR VARCHAR(7) COMMENT 'Currency pair identifier (FROM/TO format) for market analysis',
    MID_RATE NUMBER(15,6) COMMENT 'Mid-market exchange rate (average of bid and ask)',
    BID_RATE NUMBER(15,6) COMMENT 'Bid exchange rate (rate at which bank buys the base currency)',
    ASK_RATE NUMBER(15,6) COMMENT 'Ask exchange rate (rate at which bank sells the base currency)',
    SPREAD_ABSOLUTE NUMBER(15,6) COMMENT 'Absolute spread between bid and ask rates',
    SPREAD_PERCENTAGE NUMBER(8,4) COMMENT 'Percentage spread relative to mid rate for cost analysis',
    DAILY_CHANGE_ABSOLUTE NUMBER(15,6) COMMENT 'Absolute change in mid rate from previous day',
    DAILY_CHANGE_PERCENTAGE NUMBER(8,4) COMMENT 'Percentage change in mid rate from previous day',
    TREND_DIRECTION VARCHAR(15) COMMENT 'Daily trend classification (APPRECIATING/DEPRECIATING/STABLE/NO_PREV_DATA)',
    VOLATILITY_30D NUMBER(15,6) COMMENT '30-day rolling standard deviation of mid rates for risk assessment',
    MOVING_AVG_7D NUMBER(15,6) COMMENT '7-day rolling average of mid rates for trend analysis',
    MIN_RATE_30D NUMBER(15,6) COMMENT 'Minimum mid rate in last 30 days for range analysis',
    MAX_RATE_30D NUMBER(15,6) COMMENT 'Maximum mid rate in last 30 days for range analysis',
    RATE_POSITION_PERCENTAGE NUMBER(5,2) COMMENT 'Current rate position within 30-day range (0%=low, 100%=high)',
    CURRENCY_PAIR_TYPE VARCHAR(15) COMMENT 'Currency pair classification (CHF_BASE/CHF_TARGET/CROSS_CURRENCY)',
    PAIR_CLASSIFICATION VARCHAR(15) COMMENT 'Market classification (MAJOR_PAIR/MINOR_PAIR)',
    SPREAD_RISK_LEVEL VARCHAR(20) COMMENT 'Spread-based risk classification (LOW/MEDIUM/HIGH/UNKNOWN_SPREAD)',
    VOLATILITY_RISK_LEVEL VARCHAR(20) COMMENT 'Volatility-based risk classification (LOW/MEDIUM/HIGH/UNKNOWN_VOLATILITY)',
    IS_CURRENT_RATE BOOLEAN COMMENT 'Boolean flag indicating if this is the most current rate available',
    CREATED_AT TIMESTAMP_NTZ COMMENT 'Original timestamp when rate was created in source system',
    AGGREGATION_TIMESTAMP TIMESTAMP_NTZ COMMENT 'Timestamp when aggregation processing was performed',
    AGGREGATION_TYPE VARCHAR(25) COMMENT 'Type of aggregation processing applied (ENHANCED_FX_ANALYTICS)'
) COMMENT = 'Enhanced FX rates aggregation with analytics, volatility metrics, and business intelligence. Provides current rates, historical trends, bid/ask spreads, and currency pair analytics for real-time operations, risk management, and regulatory reporting.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
WITH fx_rates_base AS (
    -- Base FX rates with enhanced metadata
    SELECT 
        DATE,
        FROM_CURRENCY,
        TO_CURRENCY,
        MID_RATE,
        BID_RATE,
        ASK_RATE,
        
        -- Spread Calculations
        (ASK_RATE - BID_RATE) AS SPREAD_ABSOLUTE,
        CASE 
            WHEN MID_RATE > 0 THEN ROUND(((ASK_RATE - BID_RATE) / MID_RATE) * 100, 4)
            ELSE NULL
        END AS SPREAD_PERCENTAGE,
        
        -- Currency Pair Classification
        CASE 
            WHEN FROM_CURRENCY = 'CHF' THEN 'CHF_BASE'
            WHEN TO_CURRENCY = 'CHF' THEN 'CHF_TARGET'
            ELSE 'CROSS_CURRENCY'
        END AS CURRENCY_PAIR_TYPE,
        
        -- Major Currency Classification
        CASE 
            WHEN (FROM_CURRENCY IN ('CHF', 'USD', 'EUR', 'GBP') AND TO_CURRENCY IN ('CHF', 'USD', 'EUR', 'GBP'))
            THEN 'MAJOR_PAIR'
            ELSE 'MINOR_PAIR'
        END AS PAIR_CLASSIFICATION,
        
        -- Rate Direction (for trend analysis)
        LAG(MID_RATE) OVER (PARTITION BY FROM_CURRENCY, TO_CURRENCY ORDER BY DATE) AS PREV_MID_RATE,
        
        CREATED_AT
        
    FROM REF_RAW_001.REFI_RAW_TB_FX_RATES
),

fx_rates_with_trends AS (
    -- Calculate trends and volatility metrics
    SELECT 
        *,
        
        -- Daily Rate Changes
        CASE 
            WHEN PREV_MID_RATE IS NOT NULL AND PREV_MID_RATE > 0
            THEN ROUND(((MID_RATE - PREV_MID_RATE) / PREV_MID_RATE) * 100, 4)
            ELSE NULL
        END AS DAILY_CHANGE_PERCENTAGE,
        
        CASE 
            WHEN PREV_MID_RATE IS NOT NULL 
            THEN (MID_RATE - PREV_MID_RATE)
            ELSE NULL
        END AS DAILY_CHANGE_ABSOLUTE,
        
        -- Trend Classification
        CASE 
            WHEN PREV_MID_RATE IS NULL THEN 'NO_PREV_DATA'
            WHEN MID_RATE > PREV_MID_RATE THEN 'APPRECIATING'
            WHEN MID_RATE < PREV_MID_RATE THEN 'DEPRECIATING'
            ELSE 'STABLE'
        END AS TREND_DIRECTION,
        
        -- Rolling Volatility (30-day window)
        STDDEV(MID_RATE) OVER (
            PARTITION BY FROM_CURRENCY, TO_CURRENCY 
            ORDER BY DATE 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS VOLATILITY_30D,
        
        -- Rolling Average (7-day window)
        AVG(MID_RATE) OVER (
            PARTITION BY FROM_CURRENCY, TO_CURRENCY 
            ORDER BY DATE 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS MOVING_AVG_7D,
        
        -- Min/Max in last 30 days
        MIN(MID_RATE) OVER (
            PARTITION BY FROM_CURRENCY, TO_CURRENCY 
            ORDER BY DATE 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS MIN_RATE_30D,
        
        MAX(MID_RATE) OVER (
            PARTITION BY FROM_CURRENCY, TO_CURRENCY 
            ORDER BY DATE 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS MAX_RATE_30D
        
    FROM fx_rates_base
)

SELECT 
    -- Basic Rate Information
    DATE,
    FROM_CURRENCY,
    TO_CURRENCY,
    CONCAT(FROM_CURRENCY, '/', TO_CURRENCY) AS CURRENCY_PAIR,
    MID_RATE,
    BID_RATE,
    ASK_RATE,
    
    -- Spread Analytics
    SPREAD_ABSOLUTE,
    SPREAD_PERCENTAGE,
    
    -- Trend Analytics
    DAILY_CHANGE_ABSOLUTE,
    DAILY_CHANGE_PERCENTAGE,
    TREND_DIRECTION,
    
    -- Volatility and Moving Averages
    ROUND(VOLATILITY_30D, 6) AS VOLATILITY_30D,
    ROUND(MOVING_AVG_7D, 6) AS MOVING_AVG_7D,
    MIN_RATE_30D,
    MAX_RATE_30D,
    
    -- Rate Position Analysis
    CASE 
        WHEN MIN_RATE_30D IS NOT NULL AND MAX_RATE_30D IS NOT NULL AND MAX_RATE_30D > MIN_RATE_30D
        THEN ROUND(((MID_RATE - MIN_RATE_30D) / (MAX_RATE_30D - MIN_RATE_30D)) * 100, 2)
        ELSE NULL
    END AS RATE_POSITION_PERCENTAGE, -- 0% = at 30-day low, 100% = at 30-day high
    
    -- Business Classifications
    CURRENCY_PAIR_TYPE,
    PAIR_CLASSIFICATION,
    
    -- Risk Classifications
    CASE 
        WHEN SPREAD_PERCENTAGE IS NULL THEN 'UNKNOWN_SPREAD'
        WHEN SPREAD_PERCENTAGE > 1.0 THEN 'HIGH_SPREAD'
        WHEN SPREAD_PERCENTAGE > 0.5 THEN 'MEDIUM_SPREAD'
        ELSE 'LOW_SPREAD'
    END AS SPREAD_RISK_LEVEL,
    
    CASE 
        WHEN VOLATILITY_30D IS NULL THEN 'UNKNOWN_VOLATILITY'
        WHEN VOLATILITY_30D > 0.05 THEN 'HIGH_VOLATILITY'
        WHEN VOLATILITY_30D > 0.02 THEN 'MEDIUM_VOLATILITY'
        ELSE 'LOW_VOLATILITY'
    END AS VOLATILITY_RISK_LEVEL,
    
    -- Current Rate Status
    CASE 
        WHEN DATE = CURRENT_DATE() THEN TRUE
        WHEN DATE = (SELECT MAX(DATE) FROM REF_RAW_001.REFI_RAW_TB_FX_RATES) THEN TRUE
        ELSE FALSE
    END AS IS_CURRENT_RATE,
    
    -- Metadata
    CREATED_AT,
    CURRENT_TIMESTAMP() AS AGGREGATION_TIMESTAMP,
    'ENHANCED_FX_ANALYTICS' AS AGGREGATION_TYPE
    
FROM fx_rates_with_trends

ORDER BY FROM_CURRENCY, TO_CURRENCY, DATE DESC;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ REF_AGG_001 FX Rates Aggregation Layer Complete
--
-- OBJECTS CREATED:
-- • 1 Dynamic Table: REFA_AGG_DT_FX_RATES_ENHANCED (comprehensive FX analytics)
-- • Enhanced analytics: Spreads, volatility, trends, risk classifications
-- • Real-time metrics: Current rates, moving averages, position analysis
-- • Automated refresh: 1-hour TARGET_LAG for timely FX data
--
-- NEXT STEPS:
-- 1. ✅ REF_AGG_001 FX rates aggregation layer deployed successfully
-- 2. Verify dynamic table refresh: SHOW DYNAMIC TABLES IN SCHEMA REF_AGG_001;
-- 3. Update downstream consumers to use REF_AGG_001.REFA_AGG_DT_FX_RATES_ENHANCED
-- 4. Test FX analytics: SELECT * FROM REFA_AGG_DT_FX_RATES_ENHANCED WHERE IS_CURRENT_RATE = TRUE;
-- 5. Validate volatility and trend calculations
-- 6. Monitor refresh performance and data quality
--
-- USAGE EXAMPLES:
--
-- -- Get current FX rates for all currency pairs
-- SELECT CURRENCY_PAIR, MID_RATE, SPREAD_PERCENTAGE, TREND_DIRECTION,
--        VOLATILITY_RISK_LEVEL, RATE_POSITION_PERCENTAGE
-- FROM REFA_AGG_DT_FX_RATES_ENHANCED 
-- WHERE IS_CURRENT_RATE = TRUE
-- ORDER BY PAIR_CLASSIFICATION, CURRENCY_PAIR;
--
-- -- Analyze CHF-based currency pairs (bank's base currency)
-- SELECT CURRENCY_PAIR, DATE, MID_RATE, DAILY_CHANGE_PERCENTAGE,
--        MOVING_AVG_7D, VOLATILITY_30D
-- FROM REFA_AGG_DT_FX_RATES_ENHANCED 
-- WHERE CURRENCY_PAIR_TYPE = 'CHF_BASE'
--   AND DATE >= CURRENT_DATE - INTERVAL '30 days'
-- ORDER BY DATE DESC, CURRENCY_PAIR;
--
-- -- High volatility currency pairs for risk management
-- SELECT CURRENCY_PAIR, AVG(VOLATILITY_30D) as avg_volatility,
--        MAX(SPREAD_PERCENTAGE) as max_spread,
--        COUNT(*) as rate_observations
-- FROM REFA_AGG_DT_FX_RATES_ENHANCED 
-- WHERE VOLATILITY_RISK_LEVEL = 'HIGH_VOLATILITY'
--   AND DATE >= CURRENT_DATE - INTERVAL '90 days'
-- GROUP BY CURRENCY_PAIR
-- ORDER BY avg_volatility DESC;
--
-- -- Currency pair performance over time
-- SELECT DATE, CURRENCY_PAIR, MID_RATE, DAILY_CHANGE_PERCENTAGE,
--        RATE_POSITION_PERCENTAGE, TREND_DIRECTION
-- FROM REFA_AGG_DT_FX_RATES_ENHANCED 
-- WHERE CURRENCY_PAIR IN ('CHF/USD', 'CHF/EUR', 'CHF/GBP')
--   AND DATE >= CURRENT_DATE - INTERVAL '30 days'
-- ORDER BY CURRENCY_PAIR, DATE DESC;
--
-- -- Best and worst performing currencies vs CHF
-- SELECT FROM_CURRENCY, TO_CURRENCY,
--        AVG(DAILY_CHANGE_PERCENTAGE) as avg_daily_change,
--        STDDEV(DAILY_CHANGE_PERCENTAGE) as change_volatility,
--        COUNT(*) as observations
-- FROM REFA_AGG_DT_FX_RATES_ENHANCED 
-- WHERE (FROM_CURRENCY = 'CHF' OR TO_CURRENCY = 'CHF')
--   AND DAILY_CHANGE_PERCENTAGE IS NOT NULL
--   AND DATE >= CURRENT_DATE - INTERVAL '90 days'
-- GROUP BY FROM_CURRENCY, TO_CURRENCY
-- ORDER BY avg_daily_change DESC;
--
-- MANUAL REFRESH COMMAND:
-- ALTER DYNAMIC TABLE REFA_AGG_DT_FX_RATES_ENHANCED REFRESH;
--
-- DATA REQUIREMENTS:
-- - Source table REF_RAW_001.REFI_RAW_TB_FX_RATES must contain FX rate data
-- - FX rate CSV files must be uploaded to stage and loaded
-- - Raw layer must be populated before aggregation layer can function
--
-- MONITORING:
-- - Dynamic table refresh status: SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY()) WHERE NAME = 'REFA_AGG_DT_FX_RATES_ENHANCED';
-- - FX data coverage: SELECT COUNT(*) as total_rates, COUNT(DISTINCT CURRENCY_PAIR) as unique_pairs FROM REFA_AGG_DT_FX_RATES_ENHANCED;
-- - Data consistency check: Compare counts with raw layer SELECT COUNT(*) FROM REF_RAW_001.REFI_RAW_TB_FX_RATES;
--
-- PERFORMANCE OPTIMIZATION:
-- - Monitor warehouse usage during refresh periods
-- - Consider clustering on CURRENCY_PAIR and DATE for query optimization
-- - Archive old FX rates based on business retention requirements
-- ============================================================
