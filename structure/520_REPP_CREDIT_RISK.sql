-- ============================================================
-- REP_AGG_001 Schema - Credit Risk & IRB Reporting
-- Created on: 2025-10-05 (Split from 500_REPP_core_reporting.sql)
-- ============================================================
--
-- OVERVIEW:
-- This schema contains dynamic tables for credit risk management and Internal
-- Ratings Based (IRB) approach reporting. Provides Basel III/IV compliant risk
-- metrics for regulatory capital calculation and credit portfolio management.
--
-- BUSINESS PURPOSE:
-- - Customer credit rating and risk parameter tracking
-- - Portfolio-level risk aggregation and RWA calculation
-- - Historical rating tracking (SCD Type 2) for trend analysis
-- - Regulatory capital requirement calculation
-- - Model validation and backtesting
-- - Default tracking and rating migration analysis
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (5):
-- │  ├─ REPP_AGG_DT_IRB_CUSTOMER_RATINGS       - Customer-level credit ratings & risk parameters
-- │  ├─ REPP_AGG_DT_IRB_PORTFOLIO_METRICS      - Portfolio-level risk aggregation
-- │  ├─ REPP_AGG_DT_CUSTOMER_RATING_HISTORY    - Historical rating tracking (SCD Type 2)
-- │  ├─ REPP_AGG_DT_IRB_RWA_SUMMARY            - Risk Weighted Assets summary
-- │  └─ REPP_AGG_DT_IRB_RISK_TRENDS            - Risk parameter trends & model validation
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- DATA FLOW:
-- CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 (customer master)
--     +
-- REP_AGG_001.REPP_AGG_DT_ANOMALY_ANALYSIS (behavioral analysis)
--     +
-- PAY_AGG_001.PAYA_AGG_DT_ACCOUNT_BALANCES (exposure data)
--     ↓
-- REP_AGG_001.REPP_AGG_DT_IRB_* (credit risk reporting)
--
-- RELATED SCHEMAS:
-- - CRM_AGG_001: Customer master data
-- - PAY_AGG_001: Account balances and exposure
-- - 500_REPP_core_reporting.sql: Core reporting tables (anomaly analysis)
-- - 510_REPP_EQUITY.sql: Equity trading reporting
-- - 530_REPP_PORTFOLIO.sql: Portfolio performance reporting
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================
-- IRB (INTERNAL RATINGS BASED) APPROACH DYNAMIC TABLES
-- ============================================================
-- Basel III/IV compliant IRB risk metrics for credit risk management
-- and regulatory capital calculation

-- IRB Customer Credit Ratings and Risk Parameters
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_IRB_CUSTOMER_RATINGS(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for credit risk assessment',
    FULL_NAME VARCHAR(201) COMMENT 'Customer name for credit reporting',
    ONBOARDING_DATE DATE COMMENT 'Customer relationship start date for vintage analysis',
    CREDIT_RATING VARCHAR(3) COMMENT 'Internal credit rating (AAA to D scale)',
    PD_1_YEAR DECIMAL(8,2) COMMENT 'Probability of Default over 1 year horizon (%)',
    PD_LIFETIME DECIMAL(8,2) COMMENT 'Lifetime Probability of Default (%)',
    LGD_RATE DECIMAL(8,2) COMMENT 'Loss Given Default rate (%) - expected loss severity',
    EAD_AMOUNT DECIMAL(28,2) COMMENT 'Exposure at Default amount in CHF - total exposure',
    RISK_WEIGHT DECIMAL(8,2) COMMENT 'Risk weight (%) for RWA calculation under IRB approach',
    RATING_DATE DATE COMMENT 'Date when credit rating was assigned/updated',
    RATING_METHODOLOGY VARCHAR(20) COMMENT 'Rating methodology used (FOUNDATION_IRB/ADVANCED_IRB)',
    PORTFOLIO_SEGMENT VARCHAR(20) COMMENT 'Portfolio segment (RETAIL/CORPORATE/SME/SOVEREIGN)',
    DAYS_PAST_DUE NUMBER(10,0) COMMENT 'Current days past due for default identification',
    DEFAULT_FLAG BOOLEAN COMMENT 'Boolean flag indicating if customer is in default (90+ DPD)',
    WATCH_LIST_FLAG BOOLEAN COMMENT 'Boolean flag for customers on credit watch list',
    TOTAL_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total credit exposure across all facilities in CHF',
    SECURED_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Secured portion of exposure with collateral',
    UNSECURED_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Unsecured exposure without collateral'
) COMMENT = 'Basel III/IV Individual Credit Risk Parameters: To assign and store the key Internal Ratings Based (IRB) metrics—PD (Probability of Default), LGD (Loss Given Default), EAD (Exposure at Default)—at the customer level.
Credit Risk/Regulatory Capital: The foundational table for Basel III/IV compliance. These parameters are used directly to calculate Risk Weighted Assets (RWA) and Expected Loss (EL) for regulatory capital requirement reporting.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    c.CUSTOMER_ID,
    CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME) AS FULL_NAME,
    c.ONBOARDING_DATE,
    -- Synthetic credit rating based on customer behavior
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 'CCC'
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 'B'
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 'BB'
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 'BBB'
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 'A'
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 'AA'
        ELSE 'AAA'
    END AS CREDIT_RATING,
    -- Synthetic PD calculation based on rating
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 15.0
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 8.0
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 4.0
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 2.0
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 1.0
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 0.5
        ELSE 0.1
    END AS PD_1_YEAR,
    -- Lifetime PD (typically higher)
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 25.0
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 15.0
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 8.0
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 4.0
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 2.0
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 1.0
        ELSE 0.3
    END AS PD_LIFETIME,
    -- LGD based on portfolio type (retail typically lower)
    45.0 AS LGD_RATE,  -- Standard retail LGD assumption
    -- EAD approximated from account balances
    COALESCE(b.CURRENT_BALANCE_BASE, 0) AS EAD_AMOUNT,
    -- Risk weight calculation under IRB
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 150.0
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 120.0
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 100.0
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN 75.0
        WHEN t.ANOMALY_PERCENTAGE > 2 THEN 50.0
        WHEN t.ANOMALY_PERCENTAGE > 0 THEN 35.0
        ELSE 20.0
    END AS RISK_WEIGHT,
    CURRENT_DATE AS RATING_DATE,
    'FOUNDATION_IRB' AS RATING_METHODOLOGY,
    'RETAIL' AS PORTFOLIO_SEGMENT,
    -- Synthetic days past due
    CASE 
        WHEN c.HAS_ANOMALY = TRUE THEN 120
        WHEN t.ANOMALY_PERCENTAGE > 20 THEN 60
        WHEN t.ANOMALY_PERCENTAGE > 10 THEN 30
        ELSE 0
    END AS DAYS_PAST_DUE,
    -- Default flag (90+ days past due)
    CASE 
        WHEN c.HAS_ANOMALY = TRUE OR t.ANOMALY_PERCENTAGE > 20 THEN TRUE
        ELSE FALSE
    END AS DEFAULT_FLAG,
    -- Watch list flag
    CASE 
        WHEN t.ANOMALY_PERCENTAGE > 5 THEN TRUE
        ELSE FALSE
    END AS WATCH_LIST_FLAG,
    COALESCE(b.CURRENT_BALANCE_BASE, 0) AS TOTAL_EXPOSURE_CHF,
    COALESCE(b.CURRENT_BALANCE_BASE * 0.6, 0) AS SECURED_EXPOSURE_CHF,  -- Assume 60% secured
    COALESCE(b.CURRENT_BALANCE_BASE * 0.4, 0) AS UNSECURED_EXPOSURE_CHF -- Assume 40% unsecured
FROM CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 c
LEFT JOIN REPP_AGG_DT_ANOMALY_ANALYSIS t ON c.CUSTOMER_ID = t.CUSTOMER_ID
LEFT JOIN PAY_AGG_001.PAYA_AGG_DT_ACCOUNT_BALANCES b ON c.CUSTOMER_ID = b.CUSTOMER_ID;

-- IRB Portfolio Risk Metrics and RWA Calculation
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_IRB_PORTFOLIO_METRICS(
    PORTFOLIO_SEGMENT VARCHAR(20) COMMENT 'Portfolio segment for risk aggregation (RETAIL/CORPORATE/SME)',
    CREDIT_RATING VARCHAR(3) COMMENT 'Credit rating bucket for portfolio analysis',
    CUSTOMER_COUNT NUMBER(10,0) COMMENT 'Number of customers in this rating/segment combination',
    TOTAL_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total credit exposure in CHF for this portfolio segment',
    AVERAGE_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Average exposure per customer in CHF',
    WEIGHTED_AVG_PD DECIMAL(8,2) COMMENT 'Exposure-weighted average Probability of Default (%)',
    WEIGHTED_AVG_LGD DECIMAL(8,2) COMMENT 'Exposure-weighted average Loss Given Default (%)',
    EXPECTED_LOSS_CHF DECIMAL(28,2) COMMENT 'Expected Loss = EAD × PD × LGD in CHF',
    RISK_WEIGHTED_ASSETS_CHF DECIMAL(28,2) COMMENT 'Risk Weighted Assets under IRB approach in CHF',
    CAPITAL_REQUIREMENT_CHF DECIMAL(28,2) COMMENT 'Minimum capital requirement (8% of RWA) in CHF',
    DEFAULT_COUNT NUMBER(10,0) COMMENT 'Number of customers currently in default',
    DEFAULT_RATE DECIMAL(8,2) COMMENT 'Default rate (%) within this portfolio segment',
    WATCH_LIST_COUNT NUMBER(10,0) COMMENT 'Number of customers on credit watch list',
    WATCH_LIST_RATE DECIMAL(8,2) COMMENT 'Watch list rate (%) within this portfolio segment',
    SECURED_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total secured exposure with collateral in CHF',
    UNSECURED_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total unsecured exposure without collateral in CHF',
    COLLATERAL_COVERAGE_RATIO DECIMAL(8,2) COMMENT 'Secured exposure as % of total exposure',
    VINTAGE_MONTHS DECIMAL(8,2) COMMENT 'Average customer vintage in months for maturity analysis',
    CONCENTRATION_RISK_SCORE NUMBER(10,0) COMMENT 'Portfolio concentration risk score (1-10 scale)'
) COMMENT = 'Basel III/IV Portfolio RWA and EL Calculation: To aggregate the customer IRB parameters by portfolio segment and rating bucket, directly calculating the portfolios RWA, Expected Loss (EL), and Capital Requirement.
Credit Risk/Regulatory Capital: Provides the aggregated figures necessary for official Basel III/IV capital reporting. Tracks default rates, watch list rates, and collateral coverage for portfolio-level risk oversight.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    r.PORTFOLIO_SEGMENT,
    r.CREDIT_RATING,
    COUNT(*) AS CUSTOMER_COUNT,
    SUM(r.TOTAL_EXPOSURE_CHF) AS TOTAL_EXPOSURE_CHF,
    AVG(r.TOTAL_EXPOSURE_CHF) AS AVERAGE_EXPOSURE_CHF,
    -- Exposure-weighted averages
    SUM(r.TOTAL_EXPOSURE_CHF * r.PD_1_YEAR) / NULLIF(SUM(r.TOTAL_EXPOSURE_CHF), 0) AS WEIGHTED_AVG_PD,
    SUM(r.TOTAL_EXPOSURE_CHF * r.LGD_RATE) / NULLIF(SUM(r.TOTAL_EXPOSURE_CHF), 0) AS WEIGHTED_AVG_LGD,
    -- Expected Loss calculation: EL = EAD × PD × LGD
    SUM(r.TOTAL_EXPOSURE_CHF * (r.PD_1_YEAR / 100) * (r.LGD_RATE / 100)) AS EXPECTED_LOSS_CHF,
    -- Risk Weighted Assets: RWA = EAD × Risk Weight
    SUM(r.TOTAL_EXPOSURE_CHF * (r.RISK_WEIGHT / 100)) AS RISK_WEIGHTED_ASSETS_CHF,
    -- Capital Requirement: 8% of RWA
    SUM(r.TOTAL_EXPOSURE_CHF * (r.RISK_WEIGHT / 100)) * 0.08 AS CAPITAL_REQUIREMENT_CHF,
    SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) AS DEFAULT_COUNT,
    (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DEFAULT_RATE,
    SUM(CASE WHEN r.WATCH_LIST_FLAG = TRUE THEN 1 ELSE 0 END) AS WATCH_LIST_COUNT,
    (SUM(CASE WHEN r.WATCH_LIST_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS WATCH_LIST_RATE,
    SUM(r.SECURED_EXPOSURE_CHF) AS SECURED_EXPOSURE_CHF,
    SUM(r.UNSECURED_EXPOSURE_CHF) AS UNSECURED_EXPOSURE_CHF,
    (SUM(r.SECURED_EXPOSURE_CHF) * 100.0 / NULLIF(SUM(r.TOTAL_EXPOSURE_CHF), 0)) AS COLLATERAL_COVERAGE_RATIO,
    AVG(DATEDIFF(MONTH, r.ONBOARDING_DATE, CURRENT_DATE)) AS VINTAGE_MONTHS,
    -- Concentration risk score based on exposure distribution
    CASE 
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.3 THEN 9  -- High concentration
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.2 THEN 7  -- Medium-high
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.1 THEN 5  -- Medium
        WHEN MAX(r.TOTAL_EXPOSURE_CHF) > SUM(r.TOTAL_EXPOSURE_CHF) * 0.05 THEN 3 -- Low-medium
        ELSE 1  -- Low concentration
    END AS CONCENTRATION_RISK_SCORE
FROM REPP_AGG_DT_IRB_CUSTOMER_RATINGS r
GROUP BY r.PORTFOLIO_SEGMENT, r.CREDIT_RATING
ORDER BY r.PORTFOLIO_SEGMENT, r.CREDIT_RATING;

-- ============================================================
-- REPP_AGG_DT_CUSTOMER_RATING_HISTORY - Historical Credit Rating Tracking (SCD Type 2)
-- ============================================================
-- Historical tracking of customer credit ratings over time using SCD Type 2 methodology.
-- Captures daily snapshots from the IRB customer ratings for trend analysis, default
-- rate calculation, and model validation. Used by REPP_AGG_DT_IRB_RISK_TRENDS to calculate
-- real rating migrations and default changes.

CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_CUSTOMER_RATING_HISTORY(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for historical tracking',
    EFFECTIVE_DATE DATE COMMENT 'Date when this rating became effective',
    CREDIT_RATING VARCHAR(3) COMMENT 'Credit rating at this point in time',
    PD_1_YEAR DECIMAL(8,2) COMMENT 'Probability of Default (1-year) at this point in time',
    PD_LIFETIME DECIMAL(8,2) COMMENT 'Lifetime Probability of Default at this point in time',
    LGD_RATE DECIMAL(8,2) COMMENT 'Loss Given Default rate at this point in time',
    RISK_WEIGHT DECIMAL(8,2) COMMENT 'Risk weight percentage at this point in time',
    DEFAULT_FLAG BOOLEAN COMMENT 'Whether customer was in default at this point in time',
    WATCH_LIST_FLAG BOOLEAN COMMENT 'Whether customer was on watch list at this point in time',
    TOTAL_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total exposure amount at this point in time',
    DAYS_PAST_DUE NUMBER(10,0) COMMENT 'Days past due at this point in time',
    RATING_DATE DATE COMMENT 'Date when rating was calculated'
) COMMENT = 'Historical tracking of customer credit ratings over time (SCD Type 2). Captures daily snapshots for trend analysis, model validation, and regulatory reporting. Enables calculation of rating migrations, default rates, and model performance metrics.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    CUSTOMER_ID,
    RATING_DATE AS EFFECTIVE_DATE,
    CREDIT_RATING,
    PD_1_YEAR,
    PD_LIFETIME,
    LGD_RATE,
    RISK_WEIGHT,
    DEFAULT_FLAG,
    WATCH_LIST_FLAG,
    TOTAL_EXPOSURE_CHF,
    DAYS_PAST_DUE,
    RATING_DATE
FROM REPP_AGG_DT_IRB_CUSTOMER_RATINGS
ORDER BY CUSTOMER_ID, RATING_DATE DESC;

-- ============================================================
-- REPP_AGG_DT_IRB_RWA_SUMMARY - IRB Risk Weighted Assets Summary
-- ============================================================
-- IRB Risk Weighted Assets Summary
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_IRB_RWA_SUMMARY(
    CALCULATION_DATE DATE COMMENT 'Date of RWA calculation for regulatory reporting',
    TOTAL_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total credit exposure across all portfolios in CHF',
    TOTAL_RWA_CHF DECIMAL(28,2) COMMENT 'Total Risk Weighted Assets under IRB approach in CHF',
    TOTAL_CAPITAL_REQUIREMENT_CHF DECIMAL(28,2) COMMENT 'Total minimum capital requirement (8% of RWA) in CHF',
    TOTAL_EXPECTED_LOSS_CHF DECIMAL(28,2) COMMENT 'Total Expected Loss across all portfolios in CHF',
    AVERAGE_RISK_WEIGHT DECIMAL(8,2) COMMENT 'Portfolio-weighted average risk weight (%)',
    TIER1_CAPITAL_RATIO DECIMAL(8,2) COMMENT 'Simulated Tier 1 capital ratio (%) - regulatory minimum 6%',
    TOTAL_CAPITAL_RATIO DECIMAL(8,2) COMMENT 'Simulated total capital ratio (%) - regulatory minimum 8%',
    LEVERAGE_RATIO DECIMAL(8,2) COMMENT 'Simulated leverage ratio (%) - regulatory minimum 3%',
    DEFAULT_CUSTOMERS NUMBER(10,0) COMMENT 'Total number of customers in default across all portfolios',
    TOTAL_CUSTOMERS NUMBER(10,0) COMMENT 'Total number of customers across all portfolios',
    PORTFOLIO_DEFAULT_RATE DECIMAL(8,2) COMMENT 'Overall portfolio default rate (%)',
    RETAIL_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total retail portfolio exposure in CHF',
    CORPORATE_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total corporate portfolio exposure in CHF',
    SME_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total SME portfolio exposure in CHF',
    RETAIL_RWA_CHF DECIMAL(28,2) COMMENT 'Retail portfolio Risk Weighted Assets in CHF',
    CORPORATE_RWA_CHF DECIMAL(28,2) COMMENT 'Corporate portfolio Risk Weighted Assets in CHF',
    SME_RWA_CHF DECIMAL(28,2) COMMENT 'SME portfolio Risk Weighted Assets in CHF'
) COMMENT = 'Basel III/IV Top-Level Capital Reporting: To provide the highest-level summary of the banks credit risk profile, including total RWA, total capital requirement, and simulated regulatory ratios (e.g., Tier 1, Total Capital, Leverage Ratio).
Regulatory Reporting/Executive Management: The executive dashboard for Basel III/IV compliance, offering an immediate view of capital adequacy against minimum regulatory thresholds.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    CURRENT_DATE AS CALCULATION_DATE,
    SUM(TOTAL_EXPOSURE_CHF) AS TOTAL_EXPOSURE_CHF,
    SUM(RISK_WEIGHTED_ASSETS_CHF) AS TOTAL_RWA_CHF,
    SUM(CAPITAL_REQUIREMENT_CHF) AS TOTAL_CAPITAL_REQUIREMENT_CHF,
    SUM(EXPECTED_LOSS_CHF) AS TOTAL_EXPECTED_LOSS_CHF,
    (SUM(RISK_WEIGHTED_ASSETS_CHF) * 100.0 / NULLIF(SUM(TOTAL_EXPOSURE_CHF), 0)) AS AVERAGE_RISK_WEIGHT,
    -- Simulated capital ratios (would normally come from capital management system)
    15.2 AS TIER1_CAPITAL_RATIO,  -- Above regulatory minimum of 6%
    18.5 AS TOTAL_CAPITAL_RATIO,  -- Above regulatory minimum of 8%
    5.8 AS LEVERAGE_RATIO,        -- Above regulatory minimum of 3%
    SUM(DEFAULT_COUNT) AS DEFAULT_CUSTOMERS,
    SUM(CUSTOMER_COUNT) AS TOTAL_CUSTOMERS,
    (SUM(DEFAULT_COUNT) * 100.0 / NULLIF(SUM(CUSTOMER_COUNT), 0)) AS PORTFOLIO_DEFAULT_RATE,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'RETAIL' THEN TOTAL_EXPOSURE_CHF ELSE 0 END) AS RETAIL_EXPOSURE_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'CORPORATE' THEN TOTAL_EXPOSURE_CHF ELSE 0 END) AS CORPORATE_EXPOSURE_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'SME' THEN TOTAL_EXPOSURE_CHF ELSE 0 END) AS SME_EXPOSURE_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'RETAIL' THEN RISK_WEIGHTED_ASSETS_CHF ELSE 0 END) AS RETAIL_RWA_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'CORPORATE' THEN RISK_WEIGHTED_ASSETS_CHF ELSE 0 END) AS CORPORATE_RWA_CHF,
    SUM(CASE WHEN PORTFOLIO_SEGMENT = 'SME' THEN RISK_WEIGHTED_ASSETS_CHF ELSE 0 END) AS SME_RWA_CHF
FROM REPP_AGG_DT_IRB_PORTFOLIO_METRICS;

-- IRB Risk Parameter Trends and Validation
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_IRB_RISK_TRENDS(
    TREND_DATE DATE COMMENT 'Date for time series analysis of risk parameters',
    PORTFOLIO_SEGMENT VARCHAR(20) COMMENT 'Portfolio segment for trend analysis',
    AVG_PD_1_YEAR DECIMAL(8,2) COMMENT 'Average 1-year PD across portfolio on this date (%)',
    AVG_PD_LIFETIME DECIMAL(8,2) COMMENT 'Average lifetime PD across portfolio on this date (%)',
    AVG_LGD_RATE DECIMAL(8,2) COMMENT 'Average LGD rate across portfolio on this date (%)',
    AVG_RISK_WEIGHT DECIMAL(8,2) COMMENT 'Average risk weight across portfolio on this date (%)',
    TOTAL_EXPOSURE_CHF DECIMAL(28,2) COMMENT 'Total portfolio exposure on this date in CHF',
    TOTAL_RWA_CHF DECIMAL(28,2) COMMENT 'Total Risk Weighted Assets on this date in CHF',
    EXPECTED_LOSS_CHF DECIMAL(28,2) COMMENT 'Total Expected Loss on this date in CHF',
    DEFAULT_RATE DECIMAL(8,2) COMMENT 'Observed default rate on this date (%)',
    NEW_DEFAULTS NUMBER(10,0) COMMENT 'Number of new defaults identified on this date',
    CURED_DEFAULTS NUMBER(10,0) COMMENT 'Number of defaults that cured on this date',
    NET_DEFAULT_CHANGE NUMBER(10,0) COMMENT 'Net change in default count (new - cured)',
    RATING_MIGRATIONS_UP NUMBER(10,0) COMMENT 'Number of customers with rating upgrades',
    RATING_MIGRATIONS_DOWN NUMBER(10,0) COMMENT 'Number of customers with rating downgrades',
    MODEL_PERFORMANCE_SCORE NUMBER(10,0) COMMENT 'PD model performance score (1-10, 10=best)',
    BACKTESTING_ACCURACY DECIMAL(8,2) COMMENT 'Model backtesting accuracy (%) against actual defaults',
    STRESS_TEST_MULTIPLIER DECIMAL(8,2) COMMENT 'Stress testing multiplier applied to base PD'
) COMMENT = 'Credit Model Validation and Performance Monitoring: To track the historical trends of key IRB risk parameters (Avg PD, Avg LGD, RWA) and critical model performance metrics (e.g., Backtesting Accuracy, Model Performance Score).
Model Risk Management: Crucial for ongoing IRB model validation, ensuring the PD/LGD/EAD models remain calibrated and accurate as required by Basel regulations, and tracking rating migrations.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    CURRENT_DATE AS TREND_DATE,
    r.PORTFOLIO_SEGMENT,
    AVG(r.PD_1_YEAR) AS AVG_PD_1_YEAR,
    AVG(r.PD_LIFETIME) AS AVG_PD_LIFETIME,
    AVG(r.LGD_RATE) AS AVG_LGD_RATE,
    AVG(r.RISK_WEIGHT) AS AVG_RISK_WEIGHT,
    SUM(r.TOTAL_EXPOSURE_CHF) AS TOTAL_EXPOSURE_CHF,
    SUM(r.TOTAL_EXPOSURE_CHF * (r.RISK_WEIGHT / 100)) AS TOTAL_RWA_CHF,
    SUM(r.TOTAL_EXPOSURE_CHF * (r.PD_1_YEAR / 100) * (r.LGD_RATE / 100)) AS EXPECTED_LOSS_CHF,
    (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS DEFAULT_RATE,
    
    -- Daily changes calculated from historical rating data
    COUNT(CASE 
        WHEN r.DEFAULT_FLAG = TRUE 
        AND COALESCE(h.DEFAULT_FLAG, FALSE) = FALSE 
        THEN 1 
    END) AS NEW_DEFAULTS,
    
    COUNT(CASE 
        WHEN r.DEFAULT_FLAG = FALSE 
        AND COALESCE(h.DEFAULT_FLAG, FALSE) = TRUE 
        THEN 1 
    END) AS CURED_DEFAULTS,
    
    COUNT(CASE 
        WHEN r.DEFAULT_FLAG = TRUE 
        AND COALESCE(h.DEFAULT_FLAG, FALSE) = FALSE 
        THEN 1 
    END) - COUNT(CASE 
        WHEN r.DEFAULT_FLAG = FALSE 
        AND COALESCE(h.DEFAULT_FLAG, FALSE) = TRUE 
        THEN 1 
    END) AS NET_DEFAULT_CHANGE,
    
    -- Rating migrations (using ordinal ranking: AAA=7, AA=6, A=5, BBB=4, BB=3, B=2, CCC=1)
    COUNT(CASE 
        WHEN (
            CASE r.CREDIT_RATING 
                WHEN 'AAA' THEN 7 WHEN 'AA' THEN 6 WHEN 'A' THEN 5 
                WHEN 'BBB' THEN 4 WHEN 'BB' THEN 3 WHEN 'B' THEN 2 WHEN 'CCC' THEN 1 
            END
        ) > (
            CASE h.CREDIT_RATING 
                WHEN 'AAA' THEN 7 WHEN 'AA' THEN 6 WHEN 'A' THEN 5 
                WHEN 'BBB' THEN 4 WHEN 'BB' THEN 3 WHEN 'B' THEN 2 WHEN 'CCC' THEN 1 
            END
        ) THEN 1 
    END) AS RATING_MIGRATIONS_UP,
    
    COUNT(CASE 
        WHEN (
            CASE r.CREDIT_RATING 
                WHEN 'AAA' THEN 7 WHEN 'AA' THEN 6 WHEN 'A' THEN 5 
                WHEN 'BBB' THEN 4 WHEN 'BB' THEN 3 WHEN 'B' THEN 2 WHEN 'CCC' THEN 1 
            END
        ) < (
            CASE h.CREDIT_RATING 
                WHEN 'AAA' THEN 7 WHEN 'AA' THEN 6 WHEN 'A' THEN 5 
                WHEN 'BBB' THEN 4 WHEN 'BB' THEN 3 WHEN 'B' THEN 2 WHEN 'CCC' THEN 1 
            END
        ) THEN 1 
    END) AS RATING_MIGRATIONS_DOWN,
    
    -- Model performance metrics (calculated from actual data)
    CASE 
        WHEN AVG(r.PD_1_YEAR) BETWEEN 0.5 AND 2.0 THEN 9  -- Good calibration
        WHEN AVG(r.PD_1_YEAR) BETWEEN 0.1 AND 5.0 THEN 7  -- Acceptable
        ELSE 5  -- Needs review
    END AS MODEL_PERFORMANCE_SCORE,
    -- Backtesting accuracy (simulated)
    CASE 
        WHEN (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) BETWEEN 0.5 AND 3.0 THEN 92.5
        WHEN (SUM(CASE WHEN r.DEFAULT_FLAG = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) BETWEEN 0.1 AND 5.0 THEN 87.2
        ELSE 78.5
    END AS BACKTESTING_ACCURACY,
    1.0 AS STRESS_TEST_MULTIPLIER  -- Base case, would be higher under stress
FROM REPP_AGG_DT_IRB_CUSTOMER_RATINGS r
LEFT JOIN REPP_AGG_DT_CUSTOMER_RATING_HISTORY h 
    ON r.CUSTOMER_ID = h.CUSTOMER_ID 
    AND h.EFFECTIVE_DATE = CURRENT_DATE - 1
GROUP BY r.PORTFOLIO_SEGMENT;

-- ============================================================
-- USAGE EXAMPLES
-- ============================================================
--
-- IRB Credit Risk Analytics:
-- SELECT * FROM REPP_AGG_DT_IRB_CUSTOMER_RATINGS WHERE DEFAULT_FLAG = TRUE;
-- SELECT * FROM REPP_AGG_DT_IRB_PORTFOLIO_METRICS ORDER BY TOTAL_EXPOSURE_CHF DESC;
-- SELECT * FROM REPP_AGG_DT_IRB_RWA_SUMMARY;
-- SELECT * FROM REPP_AGG_DT_IRB_RISK_TRENDS ORDER BY TREND_DATE DESC;
-- SELECT * FROM REPP_AGG_DT_CUSTOMER_RATING_HISTORY WHERE CUSTOMER_ID = 'CUST_00001' ORDER BY EFFECTIVE_DATE DESC;
--
-- Credit Risk Rating History:
-- SELECT CUSTOMER_ID, EFFECTIVE_DATE, CREDIT_RATING, PD_1_YEAR, DEFAULT_FLAG
-- FROM REPP_AGG_DT_CUSTOMER_RATING_HISTORY 
-- WHERE CUSTOMER_ID = 'CUST_00001'
-- ORDER BY EFFECTIVE_DATE DESC;
--
-- Rating Migration Analysis:
-- SELECT 
--     h1.CUSTOMER_ID,
--     h1.EFFECTIVE_DATE AS from_date,
--     h1.CREDIT_RATING AS from_rating,
--     h2.EFFECTIVE_DATE AS to_date,
--     h2.CREDIT_RATING AS to_rating
-- FROM REPP_AGG_DT_CUSTOMER_RATING_HISTORY h1
-- JOIN REPP_AGG_DT_CUSTOMER_RATING_HISTORY h2 
--     ON h1.CUSTOMER_ID = h2.CUSTOMER_ID 
--     AND h2.EFFECTIVE_DATE = h1.EFFECTIVE_DATE + 1
-- WHERE h1.CREDIT_RATING != h2.CREDIT_RATING;
--
-- Portfolio risk summary:
-- SELECT CREDIT_RATING, CUSTOMER_COUNT, TOTAL_EXPOSURE_CHF, 
--        WEIGHTED_AVG_PD, RISK_WEIGHTED_ASSETS_CHF, DEFAULT_RATE
-- FROM REPP_AGG_DT_IRB_PORTFOLIO_METRICS
-- ORDER BY TOTAL_EXPOSURE_CHF DESC;
--
-- Default tracking:
-- SELECT TREND_DATE, NEW_DEFAULTS, CURED_DEFAULTS, NET_DEFAULT_CHANGE,
--        RATING_MIGRATIONS_UP, RATING_MIGRATIONS_DOWN
-- FROM REPP_AGG_DT_IRB_RISK_TRENDS
-- ORDER BY TREND_DATE DESC;
--
-- To check dynamic table refresh status:
-- SHOW DYNAMIC TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001;
--
-- To manually refresh a dynamic table:
-- ALTER DYNAMIC TABLE REPP_AGG_DT_IRB_CUSTOMER_RATINGS REFRESH;
-- ALTER DYNAMIC TABLE REPP_AGG_DT_IRB_PORTFOLIO_METRICS REFRESH;
-- ALTER DYNAMIC TABLE REPP_AGG_DT_CUSTOMER_RATING_HISTORY REFRESH;
-- ALTER DYNAMIC TABLE REPP_AGG_DT_IRB_RWA_SUMMARY REFRESH;
-- ALTER DYNAMIC TABLE REPP_AGG_DT_IRB_RISK_TRENDS REFRESH;
--
-- ============================================================
-- 520_REPP_CREDIT_RISK.sql - Credit Risk & IRB Reporting completed!
-- ============================================================
