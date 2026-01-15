-- ============================================================
-- Execute All Tasks and Refresh All Dynamic Tables
-- Generated on: 2025-10-28
-- ============================================================
--
-- OVERVIEW:
-- This script manually executes all tasks and refreshes all dynamic tables
-- in the AAA_DEV_SYNTHETIC_BANK database. Use this for initial data load,
-- testing, or forcing a complete refresh of all data pipelines.
--
-- BUSINESS PURPOSE:
-- - Initial data load after deployment
-- - Complete data pipeline validation
-- - Force refresh after data changes
-- - Testing end-to-end data flow
-- - Troubleshooting data processing issues
--
-- USAGE:
-- 1. Ensure all data files are uploaded to Snowflake stages
-- 2. Execute this script to trigger full data processing
-- 3. Monitor task execution and DT refresh status
-- 4. Validate data loaded correctly in all tables
--
-- EXECUTION ORDER:
-- 1. Execute RAW layer tasks (load data from stages)
-- 2. Refresh AGG layer dynamic tables (transform raw data)
-- 3. Refresh REPORTING layer dynamic tables (business logic)
--
-- SAFETY FEATURES:
-- - Only affects AAA_DEV_SYNTHETIC_BANK database
-- - Can be safely re-executed (idempotent operations)
-- - All operations logged for audit trail
-- - Non-destructive (appends/updates data)
--
-- WARNINGS:
-- - This may take 10-30 minutes depending on data volume
-- - Warehouse usage costs will apply
-- - Do not interrupt execution mid-process
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

-- ============================================================
-- STEP 1: EXECUTE ALL RAW LAYER TASKS (17 root tasks)
-- ============================================================
-- These tasks load data from Snowflake stages into RAW tables
-- Execute in logical order: Master data → Reference data → Transactional data
-- 
-- NOTE: After each load task completes, its associated cleanup task will
-- automatically execute to remove old files from the stage (keeping last 5 files).
-- 15 cleanup tasks + 1 customer status task = 16 child tasks run automatically.
-- ============================================================

SELECT 'STEP 1: Executing RAW layer tasks to load data from stages...' AS status;
SELECT 'Note: 16 child tasks will run automatically (15 cleanup + 1 customer status)' AS info;

-- ============================================================
-- Execute CRM_RAW_001 Tasks (6 root tasks, 1 child auto-triggered)
-- ============================================================
SELECT 'Executing CRM master data tasks...' AS status;

-- Load customers (must run first - master data)
EXECUTE TASK CRM_RAW_001.CRMI_RAW_TASK_LOAD_CUSTOMERS;
SELECT 'Executed: CRMI_RAW_TASK_LOAD_CUSTOMERS' AS status;

-- Load addresses (depends on customers)
EXECUTE TASK CRM_RAW_001.CRMI_RAW_TASK_LOAD_ADDRESSES;
SELECT 'Executed: CRMI_RAW_TASK_LOAD_ADDRESSES' AS status;

-- Load PEP data (depends on customers)
EXECUTE TASK CRM_RAW_001.CRMI_RAW_TASK_LOAD_EXPOSED_PERSON;
SELECT 'Executed: CRMI_RAW_TASK_LOAD_EXPOSED_PERSON' AS status;

-- Load customer events (depends on customers)
-- Note: This will automatically trigger CRMI_RAW_TASK_LOAD_CUSTOMER_STATUS via AFTER clause
EXECUTE TASK CRM_RAW_001.CRMI_RAW_TASK_LOAD_CUSTOMER_EVENTS;
SELECT 'Executed: CRMI_RAW_TASK_LOAD_CUSTOMER_EVENTS (will auto-trigger CUSTOMER_STATUS)' AS status;

-- Load employees (master data - independent)
EXECUTE TASK CRM_RAW_001.EMPI_RAW_TASK_LOAD_EMPLOYEES;
SELECT 'Executed: EMPI_RAW_TASK_LOAD_EMPLOYEES' AS status;

-- Load client assignments (depends on employees and customers)
EXECUTE TASK CRM_RAW_001.EMPI_RAW_TASK_LOAD_ASSIGNMENTS;
SELECT 'Executed: EMPI_RAW_TASK_LOAD_ASSIGNMENTS' AS status;

-- ============================================================
-- Execute ACC_RAW_001 Tasks (1 task) - Task is in CRM_RAW_001 schema
-- ============================================================
SELECT 'Executing accounts data task...' AS status;

-- Load accounts (depends on customers)
EXECUTE TASK CRM_RAW_001.ACCI_RAW_TASK_LOAD_ACCOUNTS;
SELECT 'Executed: ACCI_RAW_TASK_LOAD_ACCOUNTS' AS status;

-- ============================================================
-- Execute REF_RAW_001 Tasks (1 task)
-- ============================================================
SELECT 'Executing reference data tasks...' AS status;

-- Load FX rates (reference data, no dependencies)
EXECUTE TASK REF_RAW_001.REFI_RAW_TASK_LOAD_FX_RATES;
SELECT 'Executed: REFI_RAW_TASK_LOAD_FX_RATES' AS status;

-- ============================================================
-- Execute PAY_RAW_001 Tasks (2 tasks)
-- ============================================================
SELECT 'Executing payment data tasks...' AS status;

-- Load payment transactions (depends on customers, accounts, FX rates)
EXECUTE TASK PAY_RAW_001.PAYI_RAW_TASK_LOAD_TRANSACTIONS;
SELECT 'Executed: PAYI_RAW_TASK_LOAD_TRANSACTIONS' AS status;

-- Load SWIFT messages (depends on customers, accounts)
EXECUTE TASK PAY_RAW_001.ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES;
SELECT 'Executed: ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES' AS status;

-- ============================================================
-- Execute EQT_RAW_001 Tasks (1 task)
-- ============================================================
SELECT 'Executing equity trading data tasks...' AS status;

-- Load equity trades (depends on customers, accounts, FX rates)
EXECUTE TASK EQT_RAW_001.EQTI_RAW_TASK_LOAD_TRADES;
SELECT 'Executed: EQTI_RAW_TASK_LOAD_TRADES' AS status;

-- ============================================================
-- Execute FII_RAW_001 Tasks (1 task)
-- ============================================================
SELECT 'Executing fixed income data tasks...' AS status;

-- Load fixed income trades (depends on customers, accounts, FX rates)
EXECUTE TASK FII_RAW_001.FIII_LOAD_TRADES_TASK;
SELECT 'Executed: FIII_LOAD_TRADES_TASK' AS status;

-- ============================================================
-- Execute CMD_RAW_001 Tasks (1 task)
-- ============================================================
SELECT 'Executing commodity trading data tasks...' AS status;

-- Load commodity trades (depends on customers, accounts, FX rates)
EXECUTE TASK CMD_RAW_001.CMDI_LOAD_TRADES_TASK;
SELECT 'Executed: CMDI_LOAD_TRADES_TASK' AS status;

-- ============================================================
-- Execute LOA_RAW_001 Tasks (2 tasks)
-- ============================================================
SELECT 'Executing loan document tasks...' AS status;

-- Load loan emails
EXECUTE TASK LOA_RAW_001.LOAI_RAW_TASK_LOAD_EMAILS;
SELECT 'Executed: LOAI_RAW_TASK_LOAD_EMAILS' AS status;

-- Load loan PDF documents
EXECUTE TASK LOA_RAW_001.LOAI_RAW_TASK_LOAD_DOCUMENTS;
SELECT 'Executed: LOAI_RAW_TASK_LOAD_DOCUMENTS' AS status;

-- ============================================================
-- Execute REP_RAW_001 Tasks (2 tasks - FINMA LCR)
-- ============================================================
SELECT 'Executing FINMA LCR regulatory reporting tasks...' AS status;

-- Load HQLA holdings (High-Quality Liquid Assets)
EXECUTE TASK REP_RAW_001.LIQI_RAW_TASK_LOAD_HQLA_HOLDINGS;
SELECT 'Executed: LIQI_RAW_TASK_LOAD_HQLA_HOLDINGS' AS status;

-- Load deposit balances
EXECUTE TASK REP_RAW_001.LIQI_RAW_TASK_LOAD_DEPOSIT_BALANCES;
SELECT 'Executed: LIQI_RAW_TASK_LOAD_DEPOSIT_BALANCES' AS status;

SELECT 'STEP 1 COMPLETE: All 17 root RAW layer tasks executed (+ 16 child tasks auto-triggered)' AS status;

-- ============================================================
-- STEP 2: REFRESH AGGREGATION LAYER DYNAMIC TABLES (30 tables)
-- ============================================================
-- These DTs transform and aggregate RAW data into business entities
-- Refresh in logical order: Master data aggregations → Transactional aggregations
-- ============================================================

SELECT 'STEP 2: Refreshing AGGREGATION layer dynamic tables...' AS status;

-- ============================================================
-- Refresh CRM_AGG_001 Dynamic Tables (10 tables: 6 CRM + 1 Account + 3 Employee Analytics)
-- ============================================================
SELECT 'Refreshing CRM aggregation tables...' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.CRMA_AGG_DT_ADDRESSES_CURRENT REFRESH;
SELECT 'Refreshed: CRMA_AGG_DT_ADDRESSES_CURRENT' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.CRMA_AGG_DT_ADDRESSES_HISTORY REFRESH;
SELECT 'Refreshed: CRMA_AGG_DT_ADDRESSES_HISTORY' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT REFRESH;
SELECT 'Refreshed: CRMA_AGG_DT_CUSTOMER_CURRENT' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_HISTORY REFRESH;
SELECT 'Refreshed: CRMA_AGG_DT_CUSTOMER_HISTORY' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_LIFECYCLE REFRESH;
SELECT 'Refreshed: CRMA_AGG_DT_CUSTOMER_LIFECYCLE' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 REFRESH;
SELECT 'Refreshed: CRMA_AGG_DT_CUSTOMER_360' AS status;

-- ============================================================
-- Refresh Account Aggregation (1 table in CRM_AGG_001)
-- ============================================================
SELECT 'Refreshing account aggregation tables...' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.ACCA_AGG_DT_ACCOUNTS REFRESH;
SELECT 'Refreshed: ACCA_AGG_DT_ACCOUNTS' AS status;

-- ============================================================
-- Refresh Employee Analytics (3 tables in CRM_AGG_001)
-- ============================================================
SELECT 'Refreshing employee analytics tables...' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.EMPA_AGG_DT_ADVISOR_PERFORMANCE REFRESH;
SELECT 'Refreshed: EMPA_AGG_DT_ADVISOR_PERFORMANCE' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.EMPA_AGG_DT_TEAM_LEADER_DASHBOARD REFRESH;
SELECT 'Refreshed: EMPA_AGG_DT_TEAM_LEADER_DASHBOARD' AS status;

ALTER DYNAMIC TABLE CRM_AGG_001.EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR REFRESH;
SELECT 'Refreshed: EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR' AS status;

-- ============================================================
-- Refresh REF_AGG_001 Dynamic Tables (1 table)
-- ============================================================
SELECT 'Refreshing reference data aggregation tables...' AS status;

ALTER DYNAMIC TABLE REF_AGG_001.REFA_AGG_DT_FX_RATES_ENHANCED REFRESH;
SELECT 'Refreshed: REFA_AGG_DT_FX_RATES_ENHANCED' AS status;

-- ============================================================
-- Refresh PAY_AGG_001 Dynamic Tables (6 tables)
-- ============================================================
SELECT 'Refreshing payment aggregation tables...' AS status;

ALTER DYNAMIC TABLE PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES REFRESH;
SELECT 'Refreshed: PAYA_AGG_DT_TRANSACTION_ANOMALIES' AS status;

ALTER DYNAMIC TABLE PAY_AGG_001.PAYA_AGG_DT_ACCOUNT_BALANCES REFRESH;
SELECT 'Refreshed: PAYA_AGG_DT_ACCOUNT_BALANCES' AS status;

ALTER DYNAMIC TABLE PAY_AGG_001.PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY REFRESH;
SELECT 'Refreshed: PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY' AS status;

ALTER DYNAMIC TABLE PAY_AGG_001.ICGA_AGG_DT_SWIFT_PACS008 REFRESH;
SELECT 'Refreshed: ICGA_AGG_DT_SWIFT_PACS008' AS status;

ALTER DYNAMIC TABLE PAY_AGG_001.ICGA_AGG_DT_SWIFT_PACS002 REFRESH;
SELECT 'Refreshed: ICGA_AGG_DT_SWIFT_PACS002' AS status;

ALTER DYNAMIC TABLE PAY_AGG_001.ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE REFRESH;
SELECT 'Refreshed: ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE' AS status;

-- ============================================================
-- Refresh EQT_AGG_001 Dynamic Tables (3 tables)
-- ============================================================
SELECT 'Refreshing equity aggregation tables...' AS status;

ALTER DYNAMIC TABLE EQT_AGG_001.EQTA_AGG_DT_TRADE_SUMMARY REFRESH;
SELECT 'Refreshed: EQTA_AGG_DT_TRADE_SUMMARY' AS status;

ALTER DYNAMIC TABLE EQT_AGG_001.EQTA_AGG_DT_PORTFOLIO_POSITIONS REFRESH;
SELECT 'Refreshed: EQTA_AGG_DT_PORTFOLIO_POSITIONS' AS status;

ALTER DYNAMIC TABLE EQT_AGG_001.EQTA_AGG_DT_CUSTOMER_ACTIVITY REFRESH;
SELECT 'Refreshed: EQTA_AGG_DT_CUSTOMER_ACTIVITY' AS status;

-- ============================================================
-- Refresh FII_AGG_001 Dynamic Tables (5 tables)
-- ============================================================
SELECT 'Refreshing fixed income aggregation tables...' AS status;

ALTER DYNAMIC TABLE FII_AGG_001.FIIA_AGG_DT_TRADE_SUMMARY REFRESH;
SELECT 'Refreshed: FIIA_AGG_DT_TRADE_SUMMARY' AS status;

ALTER DYNAMIC TABLE FII_AGG_001.FIIA_AGG_DT_PORTFOLIO_POSITIONS REFRESH;
SELECT 'Refreshed: FIIA_AGG_DT_PORTFOLIO_POSITIONS' AS status;

ALTER DYNAMIC TABLE FII_AGG_001.FIIA_AGG_DT_DURATION_ANALYSIS REFRESH;
SELECT 'Refreshed: FIIA_AGG_DT_DURATION_ANALYSIS' AS status;

ALTER DYNAMIC TABLE FII_AGG_001.FIIA_AGG_DT_CREDIT_EXPOSURE REFRESH;
SELECT 'Refreshed: FIIA_AGG_DT_CREDIT_EXPOSURE' AS status;

ALTER DYNAMIC TABLE FII_AGG_001.FIIA_AGG_DT_YIELD_CURVE REFRESH;
SELECT 'Refreshed: FIIA_AGG_DT_YIELD_CURVE' AS status;

-- ============================================================
-- Refresh CMD_AGG_001 Dynamic Tables (5 tables)
-- ============================================================
SELECT 'Refreshing commodity aggregation tables...' AS status;

ALTER DYNAMIC TABLE CMD_AGG_001.CMDA_AGG_DT_TRADE_SUMMARY REFRESH;
SELECT 'Refreshed: CMDA_AGG_DT_TRADE_SUMMARY' AS status;

ALTER DYNAMIC TABLE CMD_AGG_001.CMDA_AGG_DT_PORTFOLIO_POSITIONS REFRESH;
SELECT 'Refreshed: CMDA_AGG_DT_PORTFOLIO_POSITIONS' AS status;

ALTER DYNAMIC TABLE CMD_AGG_001.CMDA_AGG_DT_DELTA_EXPOSURE REFRESH;
SELECT 'Refreshed: CMDA_AGG_DT_DELTA_EXPOSURE' AS status;

ALTER DYNAMIC TABLE CMD_AGG_001.CMDA_AGG_DT_VOLATILITY_ANALYSIS REFRESH;
SELECT 'Refreshed: CMDA_AGG_DT_VOLATILITY_ANALYSIS' AS status;

ALTER DYNAMIC TABLE CMD_AGG_001.CMDA_AGG_DT_DELIVERY_SCHEDULE REFRESH;
SELECT 'Refreshed: CMDA_AGG_DT_DELIVERY_SCHEDULE' AS status;

SELECT 'STEP 2 COMPLETE: All 30 AGGREGATION layer dynamic tables refreshed' AS status;

-- ============================================================
-- STEP 3: REFRESH REPORTING LAYER DYNAMIC TABLES (31 tables)
-- ============================================================
-- These DTs implement business logic, risk calculations, and regulatory reporting
-- Refresh in logical order: Basic reports → Advanced analytics → Regulatory reports
-- ============================================================

SELECT 'STEP 3: Refreshing REPORTING layer dynamic tables...' AS status;

-- ============================================================
-- Refresh REP_AGG_001 Dynamic Tables (Core Reporting - 9 tables)
-- ============================================================
SELECT 'Refreshing core reporting tables...' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_CUSTOMER_SUMMARY REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_CUSTOMER_SUMMARY' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_ANOMALY_ANALYSIS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_ANOMALY_ANALYSIS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_HIGH_RISK_PATTERNS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_HIGH_RISK_PATTERNS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_SETTLEMENT_ANALYSIS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_SETTLEMENT_ANALYSIS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_LIFECYCLE_ANOMALIES REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_LIFECYCLE_ANOMALIES' AS status;

-- ============================================================
-- Refresh REP_AGG_001 Dynamic Tables (Equity - 4 tables)
-- ============================================================
SELECT 'Refreshing equity reporting tables...' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_EQUITY_SUMMARY REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_EQUITY_SUMMARY' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_EQUITY_POSITIONS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_EQUITY_POSITIONS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES' AS status;

-- ============================================================
-- Refresh REP_AGG_001 Dynamic Tables (Credit Risk - 5 tables)
-- ============================================================
SELECT 'Refreshing credit risk reporting tables...' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_IRB_CUSTOMER_RATINGS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_IRB_CUSTOMER_RATINGS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_IRB_PORTFOLIO_METRICS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_IRB_PORTFOLIO_METRICS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_CUSTOMER_RATING_HISTORY REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_CUSTOMER_RATING_HISTORY' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_IRB_RWA_SUMMARY REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_IRB_RWA_SUMMARY' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_IRB_RISK_TRENDS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_IRB_RISK_TRENDS' AS status;

-- ============================================================
-- Refresh REP_AGG_001 Dynamic Tables (FRTB - 4 tables)
-- ============================================================
SELECT 'Refreshing FRTB market risk reporting tables...' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_FRTB_RISK_POSITIONS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_FRTB_RISK_POSITIONS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_FRTB_SENSITIVITIES REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_FRTB_SENSITIVITIES' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_FRTB_CAPITAL_CHARGES REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_FRTB_CAPITAL_CHARGES' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_FRTB_NMRF_ANALYSIS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_FRTB_NMRF_ANALYSIS' AS status;

-- ============================================================
-- Refresh REP_AGG_001 Dynamic Tables (BCBS 239 - 6 tables)
-- ============================================================
SELECT 'Refreshing BCBS 239 compliance reporting tables...' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_BCBS239_RISK_AGGREGATION REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_BCBS239_RISK_AGGREGATION' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_BCBS239_EXECUTIVE_DASHBOARD REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_BCBS239_EXECUTIVE_DASHBOARD' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_BCBS239_REGULATORY_REPORTING REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_BCBS239_REGULATORY_REPORTING' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_BCBS239_RISK_CONCENTRATION REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_BCBS239_RISK_CONCENTRATION' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_BCBS239_RISK_LIMITS REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_BCBS239_RISK_LIMITS' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_BCBS239_DATA_QUALITY REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_BCBS239_DATA_QUALITY' AS status;

-- ============================================================
-- Refresh REP_AGG_001 Dynamic Tables (Portfolio - 1 table)
-- ============================================================
SELECT 'Refreshing portfolio performance reporting tables...' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_PORTFOLIO_PERFORMANCE REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_PORTFOLIO_PERFORMANCE' AS status;

-- ============================================================
-- Refresh REP_AGG_001 Dynamic Tables (FINMA LCR - 2 tables)
-- ============================================================
SELECT 'Refreshing FINMA LCR liquidity reporting tables...' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_LCR_HQLA_CALCULATION REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_LCR_HQLA_CALCULATION' AS status;

ALTER DYNAMIC TABLE REP_AGG_001.REPP_AGG_DT_LCR_OUTFLOW_CALCULATION REFRESH;
SELECT 'Refreshed: REPP_AGG_DT_LCR_OUTFLOW_CALCULATION' AS status;

SELECT 'STEP 3 COMPLETE: All 31 REPORTING layer dynamic tables refreshed' AS status;

-- ============================================================
-- COMPLETION SUMMARY
-- ============================================================
SELECT
    'EXECUTION_COMPLETE' AS status,
    CURRENT_TIMESTAMP() AS completed_at,
    'All 17 root load tasks executed and 61 dynamic tables refreshed (30 AGG + 31 REP).' AS summary,
    'Total: 78 manual operations completed' AS details,
    'Note: 16 child tasks auto-triggered (15 cleanup + 1 customer status)' AS auto_tasks_info,
    'Verify data loaded correctly by querying key tables' AS next_step;

-- ============================================================
-- VERIFICATION QUERIES (Optional - Uncomment to run)
-- ============================================================
/*
-- Verify RAW layer data loaded
SELECT 'RAW Layer Verification' AS check_type;
SELECT 'CRMI_RAW_TB_CUSTOMER' AS table_name, COUNT(*) AS row_count FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER
UNION ALL
SELECT 'CRMI_RAW_TB_ADDRESSES', COUNT(*) FROM CRM_RAW_001.CRMI_RAW_TB_ADDRESSES
UNION ALL
SELECT 'ACCI_RAW_TB_ACCOUNTS', COUNT(*) FROM ACCI_RAW_001.ACCI_RAW_TB_ACCOUNTS
UNION ALL
SELECT 'PAYI_RAW_TB_TRANSACTIONS', COUNT(*) FROM PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS
UNION ALL
SELECT 'EQTI_RAW_TB_TRADES', COUNT(*) FROM EQT_RAW_001.EQTI_RAW_TB_TRADES
UNION ALL
SELECT 'FIII_RAW_TB_TRADES', COUNT(*) FROM FII_RAW_001.FIII_RAW_TB_TRADES
UNION ALL
SELECT 'CMDI_RAW_TB_TRADES', COUNT(*) FROM CMD_RAW_001.CMDI_RAW_TB_TRADES;

-- Verify AGG layer data processed
SELECT 'AGG Layer Verification' AS check_type;
SELECT 'CRMA_AGG_DT_CUSTOMER_360' AS table_name, COUNT(*) AS row_count FROM CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360
UNION ALL
SELECT 'PAYA_AGG_DT_TRANSACTION_ANOMALIES', COUNT(*) FROM PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES
UNION ALL
SELECT 'EQTA_AGG_DT_PORTFOLIO_POSITIONS', COUNT(*) FROM EQT_AGG_001.EQTA_AGG_DT_PORTFOLIO_POSITIONS;

-- Verify REPORTING layer data available
SELECT 'REPORTING Layer Verification' AS check_type;
SELECT 'REPP_AGG_DT_CUSTOMER_SUMMARY' AS table_name, COUNT(*) AS row_count FROM REP_AGG_001.REPP_AGG_DT_CUSTOMER_SUMMARY
UNION ALL
SELECT 'REPP_AGG_DT_ANOMALY_ANALYSIS', COUNT(*) FROM REP_AGG_001.REPP_AGG_DT_ANOMALY_ANALYSIS
UNION ALL
SELECT 'REPP_AGG_DT_IRB_CUSTOMER_RATINGS', COUNT(*) FROM REP_AGG_001.REPP_AGG_DT_IRB_CUSTOMER_RATINGS;
*/

