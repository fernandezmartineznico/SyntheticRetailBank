-- ============================================================
-- CRM_RAW_001 Schema - Account Master Data Management
-- Generated on: 2025-09-27 (Separated from CRMI)
-- ============================================================
--
-- OVERVIEW:
-- This schema manages account master data for the synthetic EMEA retail bank.
-- Supports multi-currency accounts across 12 EMEA countries with automated
-- loading and comprehensive account type management.
--
-- BUSINESS PURPOSE:
-- - Account master data management for retail banking operations
-- - Multi-currency support (EUR, GBP, USD, CHF, NOK, SEK, DKK)
-- - Account type categorization (CHECKING, SAVINGS, BUSINESS, INVESTMENT)
-- - Customer-account relationship management
-- - Automated data ingestion and processing
--
-- SUPPORTED ACCOUNT TYPES:
-- - CHECKING: Primary transaction accounts
-- - SAVINGS: Interest-bearing savings accounts  
-- - BUSINESS: Commercial banking accounts
-- - INVESTMENT: Securities and investment accounts
--
-- SUPPORTED CURRENCIES:
-- EUR (Euro), GBP (British Pound), USD (US Dollar), CHF (Swiss Franc),
-- NOK (Norwegian Krone), SEK (Swedish Krona), DKK (Danish Krone)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (1):
-- │  └─ ACCI_RAW_STAGE_ACCOUNTS   - Account master data files
-- │
-- ┌─ FILE FORMATS (1):
-- │  └─ ACCI_FF_ACCOUNT_CSV - Account CSV format with currency support
-- │
-- ┌─ TABLES (1):
-- │  └─ ACCI_RAW_TB_ACCOUNTS      - Account master data with currencies
-- │
-- ┌─ STREAMS (1):
-- │  └─ ACCI_RAW_STREAM_ACCOUNT_FILES - Detects new account files
-- │
-- ┌─ STORED PROCEDURES (1):
-- │  └─ CRMI_CLEANUP_STAGE_KEEP_LAST_N  - Generic stage cleanup utility (shared from 010_CRMI)
-- │
-- └─ TASKS (2 - All Serverless: 1 load + 1 cleanup):
--    ├─ ACCI_RAW_TASK_LOAD_ACCOUNTS  - Automated account loading
--    └─ ACCI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_ACCOUNTS  - Stage cleanup
--
-- DATA ARCHITECTURE:
-- File Upload → Stage → Stream Detection → Task Processing → Table
--
-- REFRESH STRATEGY:
-- - Tasks: 1-hour schedule with stream-based triggering
-- - Error Handling: ON_ERROR = CONTINUE for resilient processing
-- - Pattern Matching: *accounts*.csv for flexible file naming
--
-- RELATED SCHEMAS:
-- - CRM_RAW_001: Customer master data (foreign key relationship)
-- - PAY_RAW_001: Payment transactions (account references)
-- - EQT_RAW_001: Equity trades (investment account references)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_RAW_001;

-- ============================================================
-- INTERNAL STAGES - Account Data Landing Areas
-- ============================================================
-- Internal stage for account master data CSV file ingestion with directory
-- listing enabled for automated file detection via streams.

-- Account master data stage
CREATE STAGE IF NOT EXISTS ACCI_RAW_STAGE_ACCOUNTS
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for account master data CSV files. Expected pattern: *accounts*.csv with multi-currency support (EUR, GBP, USD, CHF, etc.)';

-- ============================================================
-- FILE FORMATS - CSV Processing Specifications
-- ============================================================
-- Standardized CSV file formats for consistent data processing across
-- all account data files with proper encoding and delimiter handling.

-- Account master data CSV format
CREATE OR REPLACE FILE FORMAT ACCI_FF_ACCOUNT_CSV
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
    COMMENT = 'CSV format for account master data files with multi-currency support. Expected columns: account_id, account_type, base_currency, customer_id, status';

-- ============================================================
-- MASTER DATA TABLES - Account Information
-- ============================================================

-- ============================================================
-- ACCI_RAW_TB_ACCOUNTS - Account Master Data (Multi-Currency)
-- ============================================================
-- Account master data supporting multiple currencies and account types.
-- Links to customer master data via CUSTOMER_ID foreign key relationship.
-- Base currencies include EUR, GBP, USD, CHF, NOK, SEK, DKK.

CREATE OR REPLACE TABLE ACCI_RAW_TB_ACCOUNTS (
    ACCOUNT_ID VARCHAR(30) NOT NULL COMMENT 'Unique account identifier (CUSTOMER_ID_ACCOUNT_TYPE_XX format)',
    ACCOUNT_TYPE VARCHAR(20) NOT NULL COMMENT 'Type of account (CHECKING, SAVINGS, BUSINESS, INVESTMENT)',
    BASE_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Account base currency (EUR, GBP, USD, CHF, NOK, SEK, DKK)',
    CUSTOMER_ID VARCHAR(30) NOT NULL COMMENT 'Reference to customer (foreign key to CRMI_RAW_001.CRMI_RAW_TB_CUSTOMER)',
    STATUS VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT 'Account status (ACTIVE, INACTIVE, CLOSED, SUSPENDED)',

    -- Constraints
    CONSTRAINT PK_ACCI_RAW_TB_ACCOUNTS PRIMARY KEY (ACCOUNT_ID)
    -- FK to CRMI_RAW_TB_CUSTOMER removed due to SCD Type 2 composite PK
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_ACCOUNT_TYPE: ACCOUNT_TYPE should be in ('CHECKING', 'SAVINGS', 'BUSINESS', 'INVESTMENT')
    -- CHK_BASE_CURRENCY: BASE_CURRENCY should be in ('EUR', 'GBP', 'USD', 'CHF', 'NOK', 'SEK', 'DKK')
    -- CHK_STATUS: STATUS should be in ('ACTIVE', 'INACTIVE', 'CLOSED', 'SUSPENDED')
)
COMMENT = 'Account master data table supporting multi-currency retail banking operations. Each customer can have multiple accounts of different types. Investment accounts are used for equity trading settlement. FK to CRMI_RAW_TB_CUSTOMER removed due to SCD Type 2 composite PK.';

-- ============================================================
-- CHANGE DETECTION STREAMS - File Monitoring
-- ============================================================
-- Streams monitor stages for new files and trigger automated processing
-- tasks. Each stream detects specific file patterns and maintains change
-- tracking for reliable data pipeline processing.

-- Account file detection stream
CREATE OR REPLACE STREAM ACCI_RAW_STREAM_ACCOUNT_FILES
    ON STAGE ACCI_RAW_STAGE_ACCOUNTS
    COMMENT = 'Monitors ACCI_RAW_STAGE_ACCOUNTS stage for new account CSV files. Triggers ACCI_RAW_TASK_LOAD_ACCOUNTS when files matching *accounts*.csv pattern are detected';

-- ============================================================
-- AUTOMATED PROCESSING TASKS - Data Pipeline Orchestration
-- ============================================================
-- Automated tasks triggered by stream data availability. All tasks run
-- on 1-hour schedule with stream-based triggering for efficient resource
-- usage. Error handling continues processing despite individual record failures.

-- Account master data loading task
CREATE OR REPLACE TASK ACCI_RAW_TASK_LOAD_ACCOUNTS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('ACCI_RAW_STREAM_ACCOUNT_FILES')
 --   COMMENT = 'Automated loading of account master data with multi-currency support. Handles checking, savings, business, and investment accounts'
AS
    COPY INTO ACCI_RAW_TB_ACCOUNTS (ACCOUNT_ID, ACCOUNT_TYPE, BASE_CURRENCY, CUSTOMER_ID, STATUS)
    FROM @ACCI_RAW_STAGE_ACCOUNTS
    PATTERN = '.*accounts.*\.csv'
    FILE_FORMAT = ACCI_FF_ACCOUNT_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- TASK ACTIVATION - Enable Automated Processing
-- ============================================================
-- Tasks must be explicitly resumed to begin processing. This allows for
-- controlled deployment and testing before enabling automated data flows.

-- ============================================================
-- AUTOMATED STAGE CLEANUP TASKS
-- ============================================================
-- Cleanup tasks that run after data loading completes to manage
-- stage storage. Uses CRMI_CLEANUP_STAGE_KEEP_LAST_N procedure
-- defined in 010_CRMI_customer_master.sql (same schema).

-- Cleanup task for account data stage
CREATE OR REPLACE TASK ACCI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_ACCOUNTS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    COMMENT = 'Automated stage cleanup after account data load. Keeps last 5 files to manage storage costs.'
    AFTER ACCI_RAW_TASK_LOAD_ACCOUNTS
AS
    CALL CRMI_CLEANUP_STAGE_KEEP_LAST_N('ACCI_RAW_STAGE_ACCOUNTS', 5);

-- ============================================================
-- TASK ACTIVATION
-- ============================================================
-- Resume all tasks (load tasks must be resumed first, then cleanup tasks)

-- Resume child tasks before parent task
ALTER TASK ACCI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_ACCOUNTS RESUME;
ALTER TASK ACCI_RAW_TASK_LOAD_ACCOUNTS RESUME;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ CRM_RAW_001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 1 Stage: ACCI_RAW_STAGE_ACCOUNTS
-- • 1 File Format: ACCI_FF_ACCOUNT_CSV  
-- • 1 Table: ACCI_RAW_TB_ACCOUNTS
-- • 1 Stream: ACCI_RAW_STREAM_ACCOUNT_FILES
-- • 1 Task: ACCI_RAW_TASK_LOAD_ACCOUNTS (ACTIVE)
--
-- NEXT STEPS:
-- 1. Upload account CSV files to ACCI_RAW_STAGE_ACCOUNTS stage
-- 2. Monitor task execution: SHOW TASKS IN SCHEMA CRM_RAW_001;
-- 3. Verify data loading: SELECT COUNT(*) FROM ACCI_RAW_TB_ACCOUNTS;
-- 4. Check for processing errors in task history
-- 5. Proceed to deploy dependent schemas (PAYI, EQTI)
--
-- USAGE EXAMPLES:
-- -- Upload files
-- PUT file://accounts.csv @ACCI_RAW_STAGE_ACCOUNTS;
-- 
-- -- Check account distribution
-- SELECT ACCOUNT_TYPE, BASE_CURRENCY, COUNT(*) 
-- FROM ACCI_RAW_TB_ACCOUNTS 
-- GROUP BY ACCOUNT_TYPE, BASE_CURRENCY;
--
-- -- Customer account summary
-- SELECT CUSTOMER_ID, COUNT(*) as ACCOUNT_COUNT,
--        LISTAGG(DISTINCT ACCOUNT_TYPE, ', ') as ACCOUNT_TYPES
-- FROM ACCI_RAW_TB_ACCOUNTS 
-- GROUP BY CUSTOMER_ID;
-- ============================================================
