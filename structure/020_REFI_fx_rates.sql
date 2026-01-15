-- ============================================================
-- REF_RAW_001 Schema - Reference Data (FX Rates)
-- Generated on: 2025-09-22 15:50:17
-- ============================================================
--
-- OVERVIEW:
-- This schema contains reference data including foreign exchange rates
-- for the synthetic EMEA retail bank data generator.
--
-- BUSINESS PURPOSE:
-- - Daily FX rate management for multi-currency operations
-- - Bid/ask spread calculations for realistic trading scenarios
-- - Currency conversion support for all EMEA countries
-- - Automated rate updates with stream-based processing
--
-- SUPPORTED CURRENCIES:
-- EUR (Euro), GBP (British Pound), USD (US Dollar), CHF (Swiss Franc),
-- NOK (Norwegian Krone), SEK (Swedish Krona), DKK (Danish Krone)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (1):
-- │  └─ REFI_RAW_TB_FX_RATES      - FX rates files
-- │
-- ├─ FILE FORMATS (1):
-- │  └─ REFI_FF_FX_RATES_CSV - FX rates CSV format
-- │
-- ├─ TABLES (1):
-- │  └─ REFI_RAW_TB_FX_RATES - Daily FX rates with bid/ask spreads
-- │
-- ├─ STREAMS (1):
-- │  └─ REFI_RAW_STREAM_FX_RATE_FILES - Detects new FX rate files
-- │
-- ├─ STORED PROCEDURES (1):
-- │  └─ REFI_CLEANUP_STAGE_KEEP_LAST_N - Generic stage cleanup utility
-- │
-- └─ TASKS (2 - All Serverless: 1 load + 1 cleanup):
--    ├─ REFI_RAW_TASK_LOAD_FX_RATES - Automated FX rate loading
--    └─ REFI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_FX_RATES - Stage cleanup
--
-- DATA ARCHITECTURE:
-- File Upload → Stage → Stream Detection → Task Processing → Table
--
-- REFRESH STRATEGY:
-- - Tasks: 1-hour schedule with stream-based triggering
-- - Error Handling: ON_ERROR = CONTINUE for resilient processing
-- - Pattern Matching: *fx_rates*.csv for flexible file naming
--
-- RELATED SCHEMAS:
-- - PAY_RAW_001: Payment transactions (currency conversion)
-- - EQT_RAW_001: Equity trades (currency conversion)
-- - FII_RAW_001: Fixed income trades (currency conversion)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REF_RAW_001;

-- ============================================================
-- INTERNAL STAGES - File Landing Areas
-- ============================================================
-- Internal stages for CSV file ingestion with directory listing enabled
-- for automated file detection via streams. All stages support PUT/GET
-- operations for manual file uploads and downloads.

-- FX rates data stage
CREATE STAGE IF NOT EXISTS REFI_RAW_STAGE_FX_RATES
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for FX rates CSV files. Expected pattern: *fx_rates*.csv with fields: date, from_currency, to_currency, mid_rate, bid_rate, ask_rate';

-- ============================================================
-- FILE FORMATS - CSV Parsing Configurations
-- ============================================================
-- Standardized CSV file formats for consistent data ingestion across
-- all FX rate data sources. All formats handle quoted fields,
-- trim whitespace, and use flexible column count matching.

-- FX rates CSV format
CREATE OR REPLACE FILE FORMAT REFI_FF_FX_RATES_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"'
    COMMENT = 'CSV format for FX rates data with bid/ask spreads and currency conversion support';

-- ============================================================
-- MASTER DATA TABLES - FX Rate Information
-- ============================================================

-- ============================================================
-- REFI_RAW_TB_FX_RATES - Daily FX Rates with Bid/Ask Spreads
-- ============================================================
-- Daily foreign exchange rates with realistic bid/ask spreads
-- for multi-currency operations and currency conversion

CREATE OR REPLACE TABLE REFI_RAW_TB_FX_RATES (
    DATE DATE NOT NULL COMMENT 'Rate date (YYYY-MM-DD)',
    FROM_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Source currency',
    TO_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Target currency',
    MID_RATE DECIMAL(15,6) NOT NULL COMMENT 'Mid-market exchange rate',
    BID_RATE DECIMAL(15,6) NOT NULL COMMENT 'Bid exchange rate (bank buys at this rate)',
    ASK_RATE DECIMAL(15,6) NOT NULL COMMENT 'Ask exchange rate (bank sells at this rate)',

    -- Metadata
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    -- Constraints
    CONSTRAINT PK_REFI_RAW_TB_FX_RATES PRIMARY KEY (DATE, FROM_CURRENCY, TO_CURRENCY)
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_FX_CURRENCIES: FROM_CURRENCY and TO_CURRENCY should be in ('USD', 'EUR', 'GBP', 'JPY', 'CAD') and different
    -- CHK_FX_RATES_POSITIVE: MID_RATE, BID_RATE, ASK_RATE should be > 0
    -- CHK_FX_SPREAD: BID_RATE <= MID_RATE <= ASK_RATE
)
COMMENT = 'Daily foreign exchange rates with realistic bid/ask spreads';

-- ============================================================
-- CHANGE DETECTION STREAMS - File Monitoring
-- ============================================================
-- Streams monitor stages for new files and trigger automated processing
-- tasks. Each stream detects specific file patterns and maintains change
-- tracking for reliable data pipeline processing.

-- FX rates file detection stream
CREATE OR REPLACE STREAM REFI_RAW_STREAM_FX_RATE_FILES
    ON STAGE REFI_RAW_STAGE_FX_RATES
    COMMENT = 'Monitors REFI_RAW_STAGE_FX_RATES stage for new FX rates CSV files. Triggers REFI_RAW_TASK_LOAD_FX_RATES when files matching *fx_rates*.csv pattern are detected';

-- ============================================================
-- AUTOMATED PROCESSING TASKS - Data Pipeline Orchestration
-- ============================================================
-- Automated tasks triggered by stream data availability. All tasks run
-- on 1-hour schedule with stream-based triggering for efficient resource
-- usage. Error handling continues processing despite individual record failures.

-- FX rates loading task
CREATE OR REPLACE TASK REFI_RAW_TASK_LOAD_FX_RATES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('REFI_RAW_STREAM_FX_RATE_FILES')
AS
    COPY INTO REFI_RAW_TB_FX_RATES (DATE, FROM_CURRENCY, TO_CURRENCY, MID_RATE, BID_RATE, ASK_RATE)
    FROM @REFI_RAW_STAGE_FX_RATES
    PATTERN = '.*fx_rates.*\.csv'
    FILE_FORMAT = REFI_FF_FX_RATES_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- MAINTENANCE PROCEDURES
-- ============================================================
-- Utility stored procedures for schema maintenance and operations.

-- ------------------------------------------------------------
-- REFI_CLEANUP_STAGE_KEEP_LAST_N - Generic Stage Cleanup Procedure
-- ------------------------------------------------------------
-- Removes oldest files from any stage in REF_RAW_001 schema, keeping only
-- the N most recently modified files. Useful for managing stage storage
-- costs and implementing data retention policies.
--
-- Parameters:
--   STAGE_NAME: Stage name without @ prefix (e.g., 'REFI_RAW_STAGE_FX_RATES')
--   KEEP_N: Number of most recent files to retain
--
-- Returns: Summary string with deletion statistics
--
-- Usage Example:
--   CALL REFI_CLEANUP_STAGE_KEEP_LAST_N('REFI_RAW_STAGE_FX_RATES', 5);

CREATE OR REPLACE PROCEDURE REFI_CLEANUP_STAGE_KEEP_LAST_N (
    STAGE_NAME STRING,
    KEEP_N     NUMBER
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Generic stage cleanup utility for REF_RAW_001 schema. Removes oldest files from a stage, keeping only the N most recently modified files.'
EXECUTE AS CALLER
AS
$$
DECLARE
  V_DELETED NUMBER := 0;
  V_FAILED  NUMBER := 0;
  V_REL     STRING;
  V_CMD     STRING;
  V_QUERY   STRING;
  
  C1 CURSOR FOR
    SELECT RELATIVE_PATH
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    
BEGIN
  V_QUERY := 'SELECT RELATIVE_PATH FROM DIRECTORY(@' || STAGE_NAME || ') ' ||
             'QUALIFY ROW_NUMBER() OVER (ORDER BY LAST_MODIFIED DESC) > ' || KEEP_N;
  
  EXECUTE IMMEDIATE V_QUERY;

  OPEN C1;
  FOR RECORD IN C1 DO
    V_REL := RECORD.RELATIVE_PATH;
    V_CMD := 'REMOVE @' || STAGE_NAME || '/' || V_REL;
    
    BEGIN
      EXECUTE IMMEDIATE V_CMD;
      V_DELETED := V_DELETED + 1;
    EXCEPTION
      WHEN OTHER THEN
        V_FAILED := V_FAILED + 1;
    END;
  END FOR;
  CLOSE C1;

  RETURN 'Stage cleanup completed. Deleted: ' || V_DELETED || ' files, Failed: ' || V_FAILED || ' files, Kept: ' || KEEP_N || ' most recent files.';
END;
$$;

-- ============================================================
-- TASK ACTIVATION - Enable Automated Processing
-- ============================================================
-- Tasks must be explicitly resumed to begin processing. This allows for
-- controlled deployment and testing before enabling automated data flows.

-- ============================================================
-- AUTOMATED STAGE CLEANUP TASKS
-- ============================================================
-- Cleanup tasks that run after data loading completes to manage
-- stage storage by keeping only the N most recent files.

-- Cleanup task for FX rates stage
CREATE OR REPLACE TASK REFI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_FX_RATES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    COMMENT = 'Automated stage cleanup after FX rates data load. Keeps last 5 files to manage storage costs.'
    AFTER REFI_RAW_TASK_LOAD_FX_RATES
AS
    CALL REFI_CLEANUP_STAGE_KEEP_LAST_N('REFI_RAW_STAGE_FX_RATES', 5);

-- ============================================================
-- TASK ACTIVATION
-- ============================================================
-- Resume all tasks (load tasks must be resumed first, then cleanup tasks)

-- Resume child task before parent task
ALTER TASK REFI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_FX_RATES RESUME;
ALTER TASK REFI_RAW_TASK_LOAD_FX_RATES RESUME;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ REF_RAW_001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 1 Stage: REFI_RAW_TB_FX_RATES
-- • 1 File Format: REFI_FF_FX_RATES_CSV
-- • 1 Table: REFI_RAW_TB_FX_RATES
-- • 1 Stream: REFI_RAW_STREAM_FX_RATE_FILES
-- • 1 Task: REFI_RAW_TASK_LOAD_FX_RATES (ACTIVE)
--
-- NEXT STEPS:
-- 1. ✅ REF_RAW_001 schema deployed successfully
-- 2. Upload FX rates CSV files to REFI_RAW_TB_FX_RATES stage
-- 3. Monitor task execution: SHOW TASKS IN SCHEMA REF_RAW_001;
-- 4. Verify data loading: SELECT COUNT(*) FROM REFI_RAW_TB_FX_RATES;
-- 5. Check for processing errors in task history
-- 6. Proceed to deploy dependent schemas (PAYI, EQTI, FIII)
--
-- USAGE EXAMPLES:
-- -- Upload files
-- PUT file://fx_rates.csv @REFI_RAW_TB_FX_RATES;
-- 
-- -- Check rate distribution
-- SELECT FROM_CURRENCY, TO_CURRENCY, COUNT(*) as rate_count
-- FROM REFI_RAW_TB_FX_RATES 
-- GROUP BY FROM_CURRENCY, TO_CURRENCY;
--
-- -- Monitor stream for new data
-- SELECT * FROM REFI_RAW_STREAM_FX_RATE_FILES;
--
-- -- Check task execution history
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
-- WHERE NAME = 'REFI_RAW_TASK_LOAD_FX_RATES'
-- ORDER BY SCHEDULED_TIME DESC;
-- ============================================================
-- REF_RAW_001 Schema Setup Complete!
-- ============================================================
