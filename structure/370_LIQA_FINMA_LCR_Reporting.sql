-- ============================================================
-- REP_AGG_001 Schema - FINMA LCR Reporting & Analytics
-- Generated on: 2026-01-07
-- ============================================================
--
-- OVERVIEW:
-- This schema contains final LCR ratio calculation, trend analysis, monthly
-- summaries, and automated compliance alerts for FINMA regulatory reporting.
-- Semantic view layer is in 750_LCRS_SemanticView.sql for dashboard/API consumption.
--
-- BUSINESS PURPOSE:
-- - Calculate final LCR ratio: (HQLA Stock / Net Cash Outflows) × 100
-- - Monitor regulatory compliance (minimum 100% per FINMA Circular 2015/2)
-- - Track 7/30/90-day LCR trends and volatility
-- - Generate automated alerts for breaches and high volatility
-- - Enable natural language queries via Cortex AI agent
-- - Support SNB (Swiss National Bank) monthly submission
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (2):
-- │  ├─ REPP_AGG_DT_LCR_DAILY  - Daily LCR calculation with compliance status
-- │  └─ REPP_AGG_DT_LCR_TREND  - 90-day rolling trend analysis
-- │
-- └─ VIEWS (3):
--    ├─ REPP_VW_LCR_MONITORING        - Consolidated LCR monitoring dashboard view
--    ├─ REPP_AGG_VW_LCR_MONTHLY_SUMMARY - Monthly aggregates for SNB submission
--    └─ REPP_AGG_VW_LCR_ALERTS          - Real-time compliance alerts
--
-- DATA FLOW:
-- REPP_AGG_DT_LCR_HQLA → ┐
--                        ├→ REPP_AGG_DT_LCR_DAILY → REPP_AGG_DT_LCR_TREND → REPP_VW_LCR_MONITORING
-- REPP_AGG_DT_LCR_OUTFLOW→┘                ↓                                     (Dashboard)
--                                   REPP_AGG_VW_LCR_MONTHLY_SUMMARY (SNB)
--                                   REPP_AGG_VW_LCR_ALERTS (Compliance)
--
-- COMPLIANCE THRESHOLDS:
-- - LCR ≥ 100%: PASS (GREEN)   - Regulatory compliant
-- - LCR 95-100%: WARNING (YELLOW) - Close monitoring required
-- - LCR < 95%: FAIL (RED)      - Critical breach, FINMA notification
--
-- ALERT TYPES:
-- - Compliance Alerts: Regulatory breaches and warnings
-- - Volatility Alerts: Day-over-day LCR changes > 5%
-- - Cap Alerts: Level 2 assets exceeding 40% cap
-- - Sustained Breach: 3+ consecutive days below 100%
--
-- RELATED SCHEMAS:
-- - REP_AGG_001: (Same schema) Hosts HQLA and outflow calculation DTs
-- - REP_RAW_001: Source data for drill-down analysis
-- ============================================================


USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================================
-- DYNAMIC TABLE: LCR DAILY CALCULATION
-- ============================================================================
-- Final daily LCR ratio calculation combining HQLA stock and net cash outflows.
-- This is the primary regulatory metric monitored by FINMA and reported to SNB.
-- Formula: LCR = (HQLA Stock / Net Cash Outflows over 30 days) × 100
-- Regulatory minimum: 100% per FINMA Circular 2015/2
--
-- BUSINESS LOGIC:
-- 1. Join HQLA and outflow calculations
-- 2. Calculate LCR ratio: (HQLA / Outflows) × 100
-- 3. Determine compliance status: PASS (≥100%), WARNING (95-100%), FAIL (<95%)
-- 4. Calculate liquidity buffer (HQLA - Outflows)
--
-- REFRESH: TARGET_LAG = 60 MINUTES (hourly refresh for regulatory monitoring)
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_LCR_DAILY(
    AS_OF_DATE DATE COMMENT 'Reporting date for LCR calculation (daily COB snapshot). Primary time dimension for regulatory reporting to SNB and intraday liquidity monitoring. Used for time-series compliance tracking and historical breach analysis.',
    BANK_ID VARCHAR(20) COMMENT 'Bank identifier for regulatory reporting (SYNTH-CH-999). Used for multi-entity consolidation in group structures and SNB submission identification. Static identifier for this synthetic bank.',
    L1_TOTAL NUMBER(18,2) COMMENT 'Total Level 1 HQLA value in CHF (0% haircut). Highest quality liquid assets including SNB reserves, cash, and government bonds rated AA- or higher. Core component of liquidity buffer providing maximum regulatory benefit.',
    L2A_TOTAL NUMBER(18,2) COMMENT 'Total Level 2A HQLA value in CHF (15% haircut). Swiss canton bonds and covered bonds. High-quality assets with minor liquidity discount. Used for yield optimization while maintaining strong LCR contribution.',
    L2B_TOTAL NUMBER(18,2) COMMENT 'Total Level 2B HQLA value in CHF (50% haircut). SMI equities and AA- corporate bonds. Lower-quality liquid assets with significant haircut. Subject to 40% cap rule and rebalancing constraints.',
    L2_UNCAPPED NUMBER(18,2) COMMENT 'Total Level 2 assets before 40% cap enforcement (L2A + L2B). Used for cap proximity monitoring and pre-emptive portfolio rebalancing decisions. Gap between uncapped and capped indicates regulatory constraint.',
    L2_CAPPED NUMBER(18,2) COMMENT 'Total Level 2 assets after 40% cap rule (max 2/3 of L1). Final L2 value included in HQLA numerator. When cap applied, excess L2 is discarded and provides no LCR benefit.',
    HQLA_TOTAL NUMBER(18,2) COMMENT 'Final total HQLA stock in CHF (L1 + L2_capped). The numerator in LCR formula: LCR = (HQLA / Outflows) × 100. Must maintain minimum CHF 2B for systemic banks. Board-level metric for liquidity risk appetite.',
    CAP_APPLIED BOOLEAN COMMENT 'Flag indicating 40% Basel III cap was triggered (TRUE = L2 exceeded 2/3 of L1). When TRUE, triggers Treasury alert to rebalance portfolio toward Level 1 assets. Monitored daily by ALM.',
    DISCARDED_L2 NUMBER(18,2) COMMENT 'CHF amount of Level 2 assets excluded due to cap breach. Represents opportunity cost - unutilized liquidity buffer. High values trigger strategic review to optimize portfolio composition.',
    TOTAL_HOLDINGS NUMBER(10,0) COMMENT 'Total number of HQLA securities across all levels. Portfolio complexity metric for operational management and custody arrangements. Used for diversification analysis and concentration risk assessment.',
    OUTFLOW_RETAIL NUMBER(18,2) COMMENT 'Total expected 30-day retail deposit outflows in CHF (3-10% base rates with discounts). Most stable funding source due to deposit insurance and relationship banking. Critical for retail funding strategy.',
    OUTFLOW_CORP NUMBER(18,2) COMMENT 'Total expected 30-day corporate deposit outflows in CHF (25-40% rates). Operational vs non-operational designation drives run-off assumptions. Used for commercial banking funding strategy.',
    OUTFLOW_FI NUMBER(18,2) COMMENT 'Total expected 30-day financial institution deposit outflows in CHF (100% assumption). Most volatile wholesale funding requiring immediate liquidity coverage. Monitored for counterparty concentration limits.',
    OUTFLOW_TOTAL NUMBER(18,2) COMMENT 'Total expected 30-day stressed net cash outflows in CHF (denominator in LCR formula). Must maintain sufficient HQLA to cover this amount for 100% LCR. Critical metric for daily liquidity planning and SNB reporting.',
    TOTAL_DEPOSIT_ACCOUNTS NUMBER(10,0) COMMENT 'Total number of active deposit accounts across all counterparty types. Deposit base breadth metric for diversification assessment and operational complexity monitoring.',
    LCR_RATIO NUMBER(8,2) COMMENT 'Liquidity Coverage Ratio: (HQLA_Total / Outflow_Total) × 100. Primary Basel III liquidity metric. Regulatory minimum 100% per FINMA Circular 2015/2. Values over 9000% indicate no stressed outflows (exceptional case).',
    LCR_STATUS VARCHAR(10) COMMENT 'Regulatory compliance status: PASS (≥100%), WARNING (95-100%), FAIL (<95%), N/A (no outflows). Used for automated alert generation, management escalation, and FINMA breach reporting.',
    SEVERITY VARCHAR(10) COMMENT 'Color-coded severity level for dashboards: GREEN (≥100%), YELLOW (95-100%), RED (<95%), GRAY (N/A). Visual indicator for Treasury operations and executive dashboards.',
    LCR_BUFFER_CHF NUMBER(18,2) COMMENT 'Absolute liquidity buffer in CHF (HQLA_Total - Outflow_Total). Excess HQLA beyond minimum regulatory requirement. Positive buffer provides cushion for market stress; negative indicates breach requiring immediate action.',
    LCR_BUFFER_PCT NUMBER(8,2) COMMENT 'Liquidity buffer as percentage of required outflows ((HQLA - Outflows) / Outflows × 100). Indicates buffer size relative to stressed outflows. Target typically 20-50% buffer for operational flexibility and stress resilience.',
    CALCULATION_TIMESTAMP TIMESTAMP_NTZ COMMENT 'UTC timestamp when LCR calculation was executed. Used for data lineage, audit trail, and SLA monitoring. Critical for validating calculation freshness (must be within 60 minutes for intraday reporting).'
) COMMENT = 'Daily Liquidity Coverage Ratio (LCR) calculation per FINMA Circular 2015/2. Combines HQLA stock and 30-day net cash outflows to calculate the primary Basel III liquidity metric. Determines regulatory compliance status (PASS/WARNING/FAIL) and calculates liquidity buffer. Critical metric monitored daily by Treasury, reported monthly to Swiss National Bank (SNB), and used for strategic liquidity planning. Regulatory minimum 100% must be maintained at all times. Updated hourly for real-time compliance monitoring and management escalation.'
TARGET_LAG = '60 MINUTES' WAREHOUSE = MD_TEST_WH
AS
WITH lcr_calc AS (
    SELECT 
        COALESCE(h.AS_OF_DATE, o.AS_OF_DATE) AS AS_OF_DATE,
        'SYNTH-CH-999' AS BANK_ID,
        -- HQLA Components
        COALESCE(h.L1_TOTAL, 0) AS L1_TOTAL,
        COALESCE(h.L2A_TOTAL, 0) AS L2A_TOTAL,
        COALESCE(h.L2B_TOTAL, 0) AS L2B_TOTAL,
        COALESCE(h.L2_UNCAPPED, 0) AS L2_UNCAPPED,
        COALESCE(h.L2_CAPPED, 0) AS L2_CAPPED,
        COALESCE(h.HQLA_TOTAL, 0) AS HQLA_TOTAL,
        COALESCE(h.CAP_APPLIED, FALSE) AS CAP_APPLIED,
        COALESCE(h.DISCARDED_L2, 0) AS DISCARDED_L2,
        COALESCE(h.TOTAL_HOLDINGS, 0) AS TOTAL_HOLDINGS,
        -- Outflow Components
        COALESCE(o.OUTFLOW_RETAIL, 0) AS OUTFLOW_RETAIL,
        COALESCE(o.OUTFLOW_CORP, 0) AS OUTFLOW_CORP,
        COALESCE(o.OUTFLOW_FI, 0) AS OUTFLOW_FI,
        COALESCE(o.OUTFLOW_TOTAL, 0) AS OUTFLOW_TOTAL,
        COALESCE(o.TOTAL_ACCOUNTS, 0) AS TOTAL_DEPOSIT_ACCOUNTS,
        -- Calculate LCR Ratio
        CASE 
            WHEN COALESCE(o.OUTFLOW_TOTAL, 0) > 0 
            THEN ROUND((COALESCE(h.HQLA_TOTAL, 0) / o.OUTFLOW_TOTAL) * 100, 2)
            ELSE 9999.99  -- Infinite LCR (no outflows)
        END AS LCR_RATIO,
        -- Determine Compliance Status
        CASE 
            WHEN COALESCE(o.OUTFLOW_TOTAL, 0) = 0 THEN 'N/A'
            WHEN (COALESCE(h.HQLA_TOTAL, 0) / NULLIF(o.OUTFLOW_TOTAL, 0)) * 100 >= 100 THEN 'PASS'
            WHEN (COALESCE(h.HQLA_TOTAL, 0) / NULLIF(o.OUTFLOW_TOTAL, 0)) * 100 >= 95 THEN 'WARNING'
            ELSE 'FAIL'
        END AS LCR_STATUS,
        -- Severity for alerting
        CASE 
            WHEN COALESCE(o.OUTFLOW_TOTAL, 0) = 0 THEN 'GRAY'
            WHEN (COALESCE(h.HQLA_TOTAL, 0) / NULLIF(o.OUTFLOW_TOTAL, 0)) * 100 >= 100 THEN 'GREEN'
            WHEN (COALESCE(h.HQLA_TOTAL, 0) / NULLIF(o.OUTFLOW_TOTAL, 0)) * 100 >= 95 THEN 'YELLOW'
            ELSE 'RED'
        END AS SEVERITY,
        -- Buffer Metrics
        COALESCE(h.HQLA_TOTAL, 0) - COALESCE(o.OUTFLOW_TOTAL, 0) AS LCR_BUFFER_CHF,
        ROUND((COALESCE(h.HQLA_TOTAL, 0) - COALESCE(o.OUTFLOW_TOTAL, 0)) / NULLIF(o.OUTFLOW_TOTAL, 0) * 100, 2) AS LCR_BUFFER_PCT,
        CURRENT_TIMESTAMP() AS CALCULATION_TIMESTAMP
    FROM REPP_AGG_DT_LCR_HQLA_CALCULATION h
    FULL OUTER JOIN REPP_AGG_DT_LCR_OUTFLOW_CALCULATION o
        ON h.AS_OF_DATE = o.AS_OF_DATE
)
SELECT * FROM lcr_calc
ORDER BY AS_OF_DATE DESC;

-- ============================================================================
-- DYNAMIC TABLE: LCR TREND ANALYSIS (90-day rolling)
-- ============================================================================
-- Rolling trend analysis of LCR ratio with volatility metrics and alert detection.
-- Calculates 7/30/90-day moving averages, standard deviation, day-over-day changes,
-- and consecutive breach tracking for proactive liquidity risk management.
--
-- BUSINESS LOGIC:
-- 1. Calculate 7/30/90-day rolling averages
-- 2. Calculate 30-day volatility (standard deviation)
-- 3. Track day-over-day changes for volatility alerts
-- 4. Identify consecutive breach patterns (sustained stress)
-- 5. Generate alert flags for high volatility and sustained breaches
--
-- REFRESH: TARGET_LAG = 60 MINUTES (hourly refresh for trend monitoring)
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_LCR_TREND(
    AS_OF_DATE DATE COMMENT 'Reporting date for trend analysis (daily COB snapshot). Time dimension for historical trend visualization, volatility monitoring, and predictive analytics. Used for identifying adverse liquidity patterns before breaches occur.',
    LCR_RATIO NUMBER(8,2) COMMENT 'Daily LCR ratio snapshot from REPP_AGG_DT_LCR_DAILY. Point-in-time value used for calculating rolling averages, volatility measures, and trend analysis. Primary metric for time-series charting.',
    LCR_7D_AVG NUMBER(8,2) COMMENT '7-day rolling average LCR ratio. Short-term trend indicator for weekly liquidity patterns and intraweek volatility smoothing. Used for identifying immediate trend reversals and operational issues.',
    LCR_30D_AVG NUMBER(8,2) COMMENT '30-day rolling average LCR ratio. Medium-term trend indicator for monthly compliance averaging and business cycle patterns. Used for SNB monthly submissions and management reporting.',
    LCR_90D_AVG NUMBER(8,2) COMMENT '90-day rolling average LCR ratio. Long-term strategic trend indicator for quarterly performance assessment and seasonal pattern identification. Used for Board reporting and strategic liquidity planning.',
    LCR_30D_VOLATILITY NUMBER(8,2) COMMENT '30-day rolling standard deviation of LCR ratio. Statistical measure of LCR stability and predictability. High volatility (>5) indicates unstable liquidity position requiring investigation. Used for risk appetite monitoring.',
    LCR_30D_MIN NUMBER(8,2) COMMENT 'Minimum LCR ratio in past 30 days. Identifies worst-case liquidity stress point within monthly window. Used for stress testing validation and regulatory buffer adequacy assessment.',
    LCR_30D_MAX NUMBER(8,2) COMMENT 'Maximum LCR ratio in past 30 days. Identifies peak liquidity position within monthly window. Large min-max range indicates high volatility. Used for capacity planning and buffer optimization.',
    LCR_DOD_CHANGE NUMBER(8,2) COMMENT 'Day-over-day LCR ratio change in percentage points. Daily velocity metric for intraday monitoring and sudden movement detection. Absolute changes >10pp trigger high volatility alerts requiring immediate investigation.',
    LCR_STATUS VARCHAR(10) COMMENT 'Daily compliance status (PASS/WARNING/FAIL/N/A). Used for consecutive breach tracking and sustained stress identification. Drives automated escalation workflows and management notifications.',
    SEVERITY VARCHAR(10) COMMENT 'Color-coded severity level (GREEN/YELLOW/RED/GRAY). Visual indicator for dashboard alerts and operational monitoring. RED severity triggers immediate Treasury escalation and breach protocols.',
    CONSECUTIVE_BREACHES_3D NUMBER(3,0) COMMENT 'Count of days below 100% threshold in past 3 days (rolling window). Identifies sustained breach patterns requiring escalated regulatory action. Values ≥3 trigger FINMA notification and remediation plan requirement.',
    HIGH_VOLATILITY_ALERT BOOLEAN COMMENT 'Flag for excessive daily volatility (|LCR_DOD_Change| >10pp). Indicates significant intraday HQLA or deposit movements requiring investigation. Triggers Treasury alert to identify root cause (large withdrawals, asset sales, etc.).',
    SUSTAINED_BREACH_ALERT BOOLEAN COMMENT 'Flag for persistent compliance failure (3+ consecutive days below 100%). Indicates structural liquidity problem requiring immediate corrective action. Triggers executive escalation, FINMA notification, and remediation plan development.',
    CRITICAL_BREACH_ALERT BOOLEAN COMMENT 'Flag for severe regulatory breach (LCR <95%). Indicates critical liquidity crisis requiring emergency measures. Triggers Board notification, regulatory reporting, and potential public disclosure depending on severity and duration.',
    CALCULATION_TIMESTAMP TIMESTAMP_NTZ COMMENT 'UTC timestamp when trend analysis was calculated. Used for data lineage, audit trail, and calculation freshness validation. Ensures trend metrics reflect latest daily LCR calculations within 60-minute SLA.'
) COMMENT = 'Rolling trend analysis of LCR ratio with statistical metrics and automated alert detection. Calculates 7/30/90-day moving averages, volatility measures, day-over-day changes, and consecutive breach tracking. Enables proactive liquidity risk management by identifying adverse trends before regulatory breaches occur. Triggers Treasury alerts for high volatility (>10% daily change), sustained breaches (3+ consecutive days below 100%), and critical breaches (<95%). Used for Board reporting, management dashboards, and early warning system integration.'
TARGET_LAG = '60 MINUTES' WAREHOUSE = MD_TEST_WH
AS
WITH daily_lcr AS (
    SELECT 
        AS_OF_DATE,
        LCR_RATIO,
        HQLA_TOTAL,
        OUTFLOW_TOTAL,
        LCR_STATUS,
        SEVERITY
    FROM REPP_AGG_DT_LCR_DAILY
),
rolling_stats AS (
    SELECT 
        AS_OF_DATE,
        LCR_RATIO,
        HQLA_TOTAL,
        OUTFLOW_TOTAL,
        LCR_STATUS,
        SEVERITY,
        -- 7-day rolling average
        AVG(LCR_RATIO) OVER (
            ORDER BY AS_OF_DATE 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS LCR_7D_AVG,
        -- 30-day rolling average
        AVG(LCR_RATIO) OVER (
            ORDER BY AS_OF_DATE 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS LCR_30D_AVG,
        -- 90-day rolling average
        AVG(LCR_RATIO) OVER (
            ORDER BY AS_OF_DATE 
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS LCR_90D_AVG,
        -- Volatility (standard deviation)
        STDDEV(LCR_RATIO) OVER (
            ORDER BY AS_OF_DATE 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS LCR_30D_VOLATILITY,
        -- Min/Max
        MIN(LCR_RATIO) OVER (
            ORDER BY AS_OF_DATE 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS LCR_30D_MIN,
        MAX(LCR_RATIO) OVER (
            ORDER BY AS_OF_DATE 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS LCR_30D_MAX,
        -- Day-over-day change
        LAG(LCR_RATIO, 1) OVER (ORDER BY AS_OF_DATE) AS LCR_PREV_DAY,
        LCR_RATIO - LAG(LCR_RATIO, 1) OVER (ORDER BY AS_OF_DATE) AS LCR_DOD_CHANGE,
        -- Consecutive breach days
        SUM(CASE WHEN LCR_RATIO < 100 THEN 1 ELSE 0 END) OVER (
            ORDER BY AS_OF_DATE 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) AS CONSECUTIVE_BREACHES_3D
    FROM daily_lcr
)
SELECT 
    AS_OF_DATE,
    LCR_RATIO,
    ROUND(LCR_7D_AVG, 2) AS LCR_7D_AVG,
    ROUND(LCR_30D_AVG, 2) AS LCR_30D_AVG,
    ROUND(LCR_90D_AVG, 2) AS LCR_90D_AVG,
    ROUND(LCR_30D_VOLATILITY, 2) AS LCR_30D_VOLATILITY,
    ROUND(LCR_30D_MIN, 2) AS LCR_30D_MIN,
    ROUND(LCR_30D_MAX, 2) AS LCR_30D_MAX,
    ROUND(LCR_DOD_CHANGE, 2) AS LCR_DOD_CHANGE,
    LCR_STATUS,
    SEVERITY,
    CONSECUTIVE_BREACHES_3D,
    -- Alert flags
    CASE WHEN ABS(LCR_DOD_CHANGE) > 10 THEN TRUE ELSE FALSE END AS HIGH_VOLATILITY_ALERT,
    CASE WHEN CONSECUTIVE_BREACHES_3D >= 3 THEN TRUE ELSE FALSE END AS SUSTAINED_BREACH_ALERT,
    CASE WHEN LCR_RATIO < 95 THEN TRUE ELSE FALSE END AS CRITICAL_BREACH_ALERT,
    CURRENT_TIMESTAMP() AS CALCULATION_TIMESTAMP
FROM rolling_stats
ORDER BY AS_OF_DATE DESC;

-- ============================================================================
-- VIEW: LCR MONTHLY SUMMARY (for SNB submission)
-- ============================================================================
-- Monthly aggregation of daily LCR metrics for regulatory reporting to Swiss
-- National Bank (SNB). Provides summary statistics, breach counts, and compliance
-- rates required for FINMA Circular 2015/2 monthly submission.
--
-- BUSINESS PURPOSE:
-- - Monthly LCR statistics (average, min, max, volatility)
-- - Breach day counts and warning day counts
-- - Compliance rate calculation
-- - SNB regulatory submission preparation
-- ============================================================================

CREATE OR REPLACE VIEW REPP_AGG_VW_LCR_MONTHLY_SUMMARY 
    COMMENT = 'Monthly summary of LCR metrics for Swiss National Bank (SNB) regulatory reporting per FINMA Circular 2015/2. Aggregates daily LCR ratios by month with summary statistics (average, min, max, volatility), breach day counts (FAIL/WARNING/PASS), and compliance rates. Used by Compliance team for monthly regulatory submissions, by Treasury for performance reporting, and by Executive Management for Board reporting. Critical for demonstrating sustained compliance with Basel III liquidity requirements and trend analysis over time.'
    AS
SELECT 
    DATE_TRUNC('MONTH', AS_OF_DATE) AS REPORTING_MONTH,
    COUNT(*) AS TRADING_DAYS,
    ROUND(AVG(LCR_RATIO), 2) AS LCR_AVG,
    ROUND(MIN(LCR_RATIO), 2) AS LCR_MIN,
    ROUND(MAX(LCR_RATIO), 2) AS LCR_MAX,
    ROUND(STDDEV(LCR_RATIO), 2) AS LCR_VOLATILITY,
    ROUND(AVG(HQLA_TOTAL), 2) AS AVG_HQLA_TOTAL,
    ROUND(AVG(OUTFLOW_TOTAL), 2) AS AVG_OUTFLOW_TOTAL,
    SUM(CASE WHEN LCR_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS BREACH_DAYS,
    SUM(CASE WHEN LCR_STATUS = 'WARNING' THEN 1 ELSE 0 END) AS WARNING_DAYS,
    SUM(CASE WHEN LCR_STATUS = 'PASS' THEN 1 ELSE 0 END) AS COMPLIANT_DAYS,
    ROUND(SUM(CASE WHEN LCR_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS BREACH_RATE_PCT
FROM REPP_AGG_DT_LCR_DAILY
GROUP BY DATE_TRUNC('MONTH', AS_OF_DATE)
ORDER BY REPORTING_MONTH DESC;

-- ============================================================================
-- VIEW: LCR CONSOLIDATED MONITORING DASHBOARD
-- ============================================================================
-- Comprehensive single-row view consolidating all LCR metrics, trends, HQLA breakdown,
-- and outflow details for dashboards and executive reporting. This view serves as the
-- primary interface for Treasury operations, Streamlit dashboards, and API integrations.
--
-- BUSINESS PURPOSE:
-- - Single source of truth for current LCR status
-- - Real-time dashboard data source for Treasury operations
-- - Executive summary view for management reporting
-- - API endpoint for downstream applications
--
-- DATA CONSOLIDATION:
-- - Latest daily LCR calculation (ratio, status, buffer)
-- - Latest trend metrics (7/30/90-day averages, volatility)
-- - HQLA breakdown by regulatory level (L1, L2A, L2B)
-- - Outflow breakdown by counterparty type (Retail, Corporate, FI)
-- - Alert flags for compliance breaches and high volatility
-- ============================================================================

CREATE OR REPLACE VIEW REPP_VW_LCR_MONITORING 
    COMMENT = 'Consolidated LCR monitoring dashboard view combining all key liquidity metrics in a single row. Integrates latest daily LCR ratio, compliance status, HQLA breakdown (L1/L2A/L2B), deposit outflow analysis (Retail/Corporate/FI), trend metrics (7/30/90-day averages), volatility measures, and automated alert flags. Optimized for Treasury dashboards, executive reporting, and downstream application integration. Single source of truth for current liquidity position and regulatory compliance status. Updated in real-time via underlying dynamic tables for operational decision-making and management escalation.'
    AS
WITH latest_lcr AS (
    SELECT * 
    FROM REPP_AGG_DT_LCR_DAILY
    QUALIFY ROW_NUMBER() OVER (ORDER BY AS_OF_DATE DESC) = 1
),
latest_trend AS (
    SELECT * 
    FROM REPP_AGG_DT_LCR_TREND
    QUALIFY ROW_NUMBER() OVER (ORDER BY AS_OF_DATE DESC) = 1
),
hqla_breakdown AS (
    SELECT 
        h.AS_OF_DATE,
        h.REGULATORY_LEVEL,
        COUNT(*) AS HOLDING_COUNT,
        ROUND(SUM(h.MARKET_VALUE_CHF), 2) AS GROSS_VALUE_CHF,
        ROUND(SUM(h.WEIGHTED_VALUE_CHF), 2) AS WEIGHTED_VALUE_CHF,
        LISTAGG(DISTINCT h.CURRENCY, ', ') WITHIN GROUP (ORDER BY h.CURRENCY) AS CURRENCIES
    FROM REPP_AGG_VW_LCR_HQLA_HOLDINGS_DETAIL h
    WHERE h.AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM REPP_AGG_VW_LCR_HQLA_HOLDINGS_DETAIL)
    GROUP BY h.AS_OF_DATE, h.REGULATORY_LEVEL
),
outflow_breakdown AS (
    SELECT 
        o.AS_OF_DATE,
        o.COUNTERPARTY_TYPE,
        COUNT(*) AS ACCOUNT_COUNT,
        COUNT(DISTINCT o.CUSTOMER_ID) AS CUSTOMER_COUNT,
        ROUND(SUM(o.BALANCE_CHF), 2) AS TOTAL_BALANCE_CHF,
        ROUND(SUM(o.OUTFLOW_AMOUNT_CHF), 2) AS TOTAL_OUTFLOW_CHF,
        ROUND(AVG(o.FINAL_RUN_OFF_RATE) * 100, 2) AS AVG_RUN_OFF_PCT
    FROM REPP_AGG_VW_LCR_DEPOSIT_BALANCES_DETAIL o
    WHERE o.AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM REPP_AGG_VW_LCR_DEPOSIT_BALANCES_DETAIL)
    GROUP BY o.AS_OF_DATE, o.COUNTERPARTY_TYPE
)
SELECT 
    -- Core LCR Metrics
    l.AS_OF_DATE AS REPORTING_DATE,
    l.BANK_ID,
    l.LCR_RATIO,
    l.LCR_STATUS,
    l.SEVERITY,
    l.HQLA_TOTAL,
    l.L1_TOTAL,
    l.L2A_TOTAL,
    l.L2B_TOTAL,
    l.L2_CAPPED,
    l.CAP_APPLIED,
    l.DISCARDED_L2,
    l.OUTFLOW_TOTAL,
    l.OUTFLOW_RETAIL,
    l.OUTFLOW_CORP,
    l.OUTFLOW_FI,
    l.LCR_BUFFER_CHF,
    l.LCR_BUFFER_PCT,
    -- Trend Metrics
    t.LCR_7D_AVG,
    t.LCR_30D_AVG,
    t.LCR_90D_AVG,
    t.LCR_30D_VOLATILITY,
    t.LCR_30D_MIN,
    t.LCR_30D_MAX,
    t.LCR_DOD_CHANGE,
    t.CONSECUTIVE_BREACHES_3D,
    -- Alert Flags
    t.HIGH_VOLATILITY_ALERT,
    t.SUSTAINED_BREACH_ALERT,
    t.CRITICAL_BREACH_ALERT,
    -- HQLA Details (Level 1)
    (SELECT HOLDING_COUNT FROM hqla_breakdown WHERE REGULATORY_LEVEL = 'L1') AS L1_HOLDING_COUNT,
    (SELECT GROSS_VALUE_CHF FROM hqla_breakdown WHERE REGULATORY_LEVEL = 'L1') AS L1_GROSS_VALUE,
    (SELECT CURRENCIES FROM hqla_breakdown WHERE REGULATORY_LEVEL = 'L1') AS L1_CURRENCIES,
    -- HQLA Details (Level 2A)
    (SELECT HOLDING_COUNT FROM hqla_breakdown WHERE REGULATORY_LEVEL = 'L2A') AS L2A_HOLDING_COUNT,
    (SELECT GROSS_VALUE_CHF FROM hqla_breakdown WHERE REGULATORY_LEVEL = 'L2A') AS L2A_GROSS_VALUE,
    -- HQLA Details (Level 2B)
    (SELECT HOLDING_COUNT FROM hqla_breakdown WHERE REGULATORY_LEVEL = 'L2B') AS L2B_HOLDING_COUNT,
    (SELECT GROSS_VALUE_CHF FROM hqla_breakdown WHERE REGULATORY_LEVEL = 'L2B') AS L2B_GROSS_VALUE,
    -- Outflow Details (Retail)
    (SELECT ACCOUNT_COUNT FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'RETAIL') AS RETAIL_ACCOUNT_COUNT,
    (SELECT CUSTOMER_COUNT FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'RETAIL') AS RETAIL_CUSTOMER_COUNT,
    (SELECT TOTAL_BALANCE_CHF FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'RETAIL') AS RETAIL_BALANCE_CHF,
    (SELECT AVG_RUN_OFF_PCT FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'RETAIL') AS RETAIL_AVG_RUN_OFF_PCT,
    -- Outflow Details (Corporate)
    (SELECT ACCOUNT_COUNT FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'CORPORATE') AS CORP_ACCOUNT_COUNT,
    (SELECT CUSTOMER_COUNT FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'CORPORATE') AS CORP_CUSTOMER_COUNT,
    (SELECT TOTAL_BALANCE_CHF FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'CORPORATE') AS CORP_BALANCE_CHF,
    (SELECT AVG_RUN_OFF_PCT FROM outflow_breakdown WHERE COUNTERPARTY_TYPE = 'CORPORATE') AS CORP_AVG_RUN_OFF_PCT,
    -- Timestamps
    l.CALCULATION_TIMESTAMP AS LCR_CALCULATION_TIMESTAMP,
    CURRENT_TIMESTAMP() AS VIEW_QUERY_TIMESTAMP
FROM latest_lcr l
CROSS JOIN latest_trend t;


CREATE OR REPLACE VIEW REPP_AGG_VW_LCR_ALERTS 
    COMMENT = 'Automated alert generation view for LCR compliance monitoring with structured alert messages and severity classification. Generates real-time alerts for regulatory breaches (LCR <100%), critical breaches (LCR <95%), high volatility (>10% daily change), sustained breaches (3+ consecutive days), and 40% cap violations. Each alert includes severity level (CRITICAL/HIGH/MEDIUM/INFO), alert type, descriptive message, and recommended action. Used by Treasury operations for real-time monitoring, by Compliance for breach documentation, and integrated with notification systems for management escalation. Critical for FINMA reporting obligations and audit trail maintenance.'
    AS
WITH latest_lcr AS (
    SELECT * 
    FROM REPP_AGG_DT_LCR_DAILY
    QUALIFY ROW_NUMBER() OVER (ORDER BY AS_OF_DATE DESC) = 1
),
latest_trend AS (
    SELECT * 
    FROM REPP_AGG_DT_LCR_TREND
    QUALIFY ROW_NUMBER() OVER (ORDER BY AS_OF_DATE DESC) = 1
),
alerts AS (
    SELECT 
        l.AS_OF_DATE,
        l.LCR_RATIO,
        l.LCR_STATUS,
        l.SEVERITY,
        t.LCR_DOD_CHANGE,
        t.CONSECUTIVE_BREACHES_3D,
        -- Generate alert messages
        CASE 
            WHEN l.LCR_RATIO < 95 THEN ARRAY_CONSTRUCT(
                OBJECT_CONSTRUCT(
                    'severity', 'CRITICAL',
                    'type', 'LCR_BREACH_CRITICAL',
                    'message', 'LCR ratio ' || l.LCR_RATIO || '% is critically below 95% threshold',
                    'action', 'Immediate escalation to Treasury management required'
                )
            )
            WHEN l.LCR_RATIO < 100 THEN ARRAY_CONSTRUCT(
                OBJECT_CONSTRUCT(
                    'severity', 'HIGH',
                    'type', 'LCR_BREACH',
                    'message', 'LCR ratio ' || l.LCR_RATIO || '% is below 100% regulatory minimum',
                    'action', 'Notify FINMA within 24 hours, initiate remediation plan'
                )
            )
            WHEN l.LCR_RATIO < 105 AND t.CONSECUTIVE_BREACHES_3D >= 2 THEN ARRAY_CONSTRUCT(
                OBJECT_CONSTRUCT(
                    'severity', 'MEDIUM',
                    'type', 'LCR_WARNING',
                    'message', 'LCR ratio ' || l.LCR_RATIO || '% near threshold for ' || t.CONSECUTIVE_BREACHES_3D || ' days',
                    'action', 'Monitor closely, consider increasing HQLA buffer'
                )
            )
            ELSE ARRAY_CONSTRUCT()
        END AS compliance_alerts,
        CASE 
            WHEN ABS(t.LCR_DOD_CHANGE) > 10 THEN ARRAY_CONSTRUCT(
                OBJECT_CONSTRUCT(
                    'severity', 'HIGH',
                    'type', 'HIGH_VOLATILITY',
                    'message', 'LCR ratio changed by ' || t.LCR_DOD_CHANGE || '% in one day',
                    'action', 'Investigate large HQLA or deposit movements'
                )
            )
            WHEN ABS(t.LCR_DOD_CHANGE) > 5 THEN ARRAY_CONSTRUCT(
                OBJECT_CONSTRUCT(
                    'severity', 'MEDIUM',
                    'type', 'MODERATE_VOLATILITY',
                    'message', 'LCR ratio changed by ' || t.LCR_DOD_CHANGE || '% in one day',
                    'action', 'Review daily position changes'
                )
            )
            ELSE ARRAY_CONSTRUCT()
        END AS volatility_alerts,
        CASE 
            WHEN l.CAP_APPLIED THEN ARRAY_CONSTRUCT(
                OBJECT_CONSTRUCT(
                    'severity', 'INFO',
                    'type', 'L2_CAP_APPLIED',
                    'message', 'Level 2 assets exceeded 40% cap. Discarded: CHF ' || ROUND(l.DISCARDED_L2 / 1000000, 2) || 'M',
                    'action', 'Consider increasing Level 1 holdings or reducing Level 2'
                )
            )
            ELSE ARRAY_CONSTRUCT()
        END AS cap_alerts
    FROM latest_lcr l
    CROSS JOIN latest_trend t
)
SELECT 
    AS_OF_DATE,
    LCR_RATIO,
    LCR_STATUS,
    SEVERITY,
    ARRAY_CAT(ARRAY_CAT(compliance_alerts, volatility_alerts), cap_alerts) AS ALL_ALERTS,
    ARRAY_SIZE(ARRAY_CAT(ARRAY_CAT(compliance_alerts, volatility_alerts), cap_alerts)) AS TOTAL_ALERT_COUNT,
    CASE 
        WHEN ARRAY_SIZE(ARRAY_CAT(ARRAY_CAT(compliance_alerts, volatility_alerts), cap_alerts)) > 0 THEN 
            (SELECT MAX(VALUE:severity::STRING) FROM TABLE(FLATTEN(ARRAY_CAT(ARRAY_CAT(compliance_alerts, volatility_alerts), cap_alerts))))
        ELSE 'NONE'
    END AS HIGHEST_SEVERITY,
    CURRENT_TIMESTAMP() AS ALERT_TIMESTAMP
FROM alerts;

-- ============================================================================
-- PERMISSIONS
-- ============================================================================
-- Note: Permissions for REP_AGG_001 schema are managed centrally in 000_database_setup.sql
-- Grant specific permissions for LCR-related objects:

-- GRANT SELECT ON VIEW REPP_VW_LCR_MONITORING TO ROLE ANALYST;
-- GRANT SELECT ON VIEW REPP_AGG_VW_LCR_MONTHLY_SUMMARY TO ROLE ANALYST;
-- GRANT SELECT ON VIEW REPP_AGG_VW_LCR_ALERTS TO ROLE ANALYST;

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================

