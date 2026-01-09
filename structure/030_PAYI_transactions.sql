-- ============================================================
-- PAY_RAW_001 Schema - Payment Transaction Data
-- Generated on: 2025-09-22 15:50:17
-- ============================================================
--
-- OVERVIEW:
-- This schema contains payment transaction data with multi-currency support
-- for the synthetic EMEA retail bank data generator.
--
-- BUSINESS PURPOSE:
-- - Payment transaction processing for retail banking operations
-- - Multi-currency support (EUR, GBP, USD, CHF, NOK, SEK, DKK)
-- - Anomaly detection for compliance and risk management
-- - Automated data ingestion and processing
--
-- SUPPORTED CURRENCIES:
-- EUR (Euro), GBP (British Pound), USD (US Dollar), CHF (Swiss Franc),
-- NOK (Norwegian Krone), SEK (Swedish Krona), DKK (Danish Krone)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (1):
-- │  └─ PAYI_RAW_TB_TRANSACTIONS      - Payment transaction files
-- │
-- ├─ FILE FORMATS (1):
-- │  └─ PAYI_FF_TRANSACTION_CSV - Payment transaction CSV format
-- │
-- ├─ TABLES (1):
-- │  └─ PAYI_RAW_TB_TRANSACTIONS - Payment transactions with multi-currency support
-- │
-- ├─ STREAMS (1):
-- │  └─ PAYI_RAW_STREAM_TRANSACTION_FILES - Detects new transaction files
-- │
-- └─ TASKS (1):
--    └─ PAYI_RAW_TASK_LOAD_TRANSACTIONS - Automated transaction loading
--
-- DATA ARCHITECTURE:
-- File Upload → Stage → Stream Detection → Task Processing → Table
--
-- REFRESH STRATEGY:
-- - Tasks: 1-hour schedule with stream-based triggering
-- - Error Handling: ON_ERROR = CONTINUE for resilient processing
-- - Pattern Matching: *pay_transactions*.csv for flexible file naming
--
-- RELATED SCHEMAS:
-- - CRM_RAW_001: Customer and account master data (foreign key relationships)
-- - REF_RAW_001: FX rates for currency conversion
-- - EQT_RAW_001: Equity trades (account references)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA PAY_RAW_001;

-- ============================================================
-- INTERNAL STAGES - File Landing Areas
-- ============================================================
-- Internal stages for CSV file ingestion with directory listing enabled
-- for automated file detection via streams. All stages support PUT/GET
-- operations for manual file uploads and downloads.

-- Payment transaction data stage
CREATE STAGE IF NOT EXISTS PAYI_RAW_STAGE_TRANSACTIONS
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for payment transaction CSV files. Expected pattern: *pay_transactions*.csv with fields: booking_date, value_date, transaction_id, account_id, amount, currency, etc.';

-- ============================================================
-- FILE FORMATS - CSV Parsing Configurations
-- ============================================================
-- Standardized CSV file formats for consistent data ingestion across
-- all payment transaction data sources. All formats handle quoted fields,
-- trim whitespace, and use flexible column count matching.

-- Payment transaction CSV format
CREATE OR REPLACE FILE FORMAT PAYI_FF_TRANSACTION_CSV
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
    COMMENT = 'CSV format for payment transaction data with multi-currency support and anomaly detection';

-- ============================================================
-- MASTER DATA TABLES - Payment Transaction Information
-- ============================================================

-- ============================================================
-- PAYI_RAW_TB_TRANSACTIONS - Payment Transactions with Multi-Currency Support
-- ============================================================
-- Payment transaction data with FX conversions and settlement dates
-- for retail banking operations and compliance monitoring

CREATE OR REPLACE TABLE PAYI_RAW_TB_TRANSACTIONS (
    BOOKING_DATE TIMESTAMP_NTZ NOT NULL COMMENT 'Transaction timestamp when recorded (ISO 8601 UTC format: YYYY-MM-DDTHH:MM:SS.fffffZ)',
    VALUE_DATE DATE NOT NULL COMMENT 'Date when funds are settled/available (YYYY-MM-DD)',
    TRANSACTION_ID VARCHAR(50) NOT NULL COMMENT 'Unique transaction identifier',
    ACCOUNT_ID VARCHAR(30) NOT NULL COMMENT 'Reference to account ID in ACCI_RAW_TB_ACCOUNTS',
    AMOUNT DECIMAL(15,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Signed transaction amount in original currency (positive = incoming, negative = outgoing)',
    CURRENCY VARCHAR(3) NOT NULL COMMENT 'Transaction currency (USD, EUR, GBP, JPY, CAD, CHF)',
    BASE_AMOUNT DECIMAL(15,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Signed transaction amount converted to base currency USD (positive = incoming, negative = outgoing)',
    BASE_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Currency of Account - ISO 4217 currency code',
    FX_RATE DECIMAL(15,6) NOT NULL COMMENT 'Exchange rate used for conversion (from transaction currency to base currency)',
    COUNTERPARTY_ACCOUNT VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Counterparty account identifier',
    DESCRIPTION VARCHAR(500) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Transaction description (may contain anomaly indicators in [brackets])',

    -- GENERATED ALWAYS AS virtual columns not supported - replaced with comments for documentation
    -- BOOKING_DATE_LOCAL: Use DATE(BOOKING_DATE) in queries
    -- AMOUNT_CATEGORY: Use CASE WHEN BASE_AMOUNT < 1000 THEN 'SMALL' WHEN BASE_AMOUNT < 10000 THEN 'MEDIUM' ELSE 'LARGE' END
    -- IS_ANOMALOUS: Use DESCRIPTION LIKE '%[%]%' in queries

    -- Metadata
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    -- Constraints
    CONSTRAINT PK_PAYI_RAW_TB_TRANSACTIONS PRIMARY KEY (TRANSACTION_ID),
    CONSTRAINT FK_PAYI_RAW_TB_TRANSACTIONS_ACCOUNT FOREIGN KEY (ACCOUNT_ID) REFERENCES AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS (ACCOUNT_ID)
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_CURRENCY_TXN: CURRENCY should be in ('USD', 'EUR', 'GBP', 'JPY', 'CAD', 'CHF')
    -- CHK_BASE_CURRENCY_TXN: BASE_CURRENCY should be 'USD'
    -- CHK_AMOUNT_SIGNED: AMOUNT and BASE_AMOUNT can be positive (incoming) or negative (outgoing)
    -- CHK_FX_RATE_POSITIVE: FX_RATE should be > 0
    -- CHK_VALUE_DATE_LOGIC: VALUE_DATE should be >= BOOKING_DATE
)
COMMENT = 'Payment transactions with multi-currency support and anomaly detection';

-- ============================================================
-- CHANGE DETECTION STREAMS - File Monitoring
-- ============================================================
-- Streams monitor stages for new files and trigger automated processing
-- tasks. Each stream detects specific file patterns and maintains change
-- tracking for reliable data pipeline processing.

-- Payment transaction file detection stream
CREATE OR REPLACE STREAM PAYI_RAW_STREAM_TRANSACTION_FILES
    ON STAGE PAYI_RAW_STAGE_TRANSACTIONS
    COMMENT = 'Monitors PAYI_RAW_STAGE_TRANSACTIONS stage for new payment transaction CSV files. Triggers PAYI_RAW_TASK_LOAD_TRANSACTIONS when files matching *pay_transactions*.csv pattern are detected';

-- ============================================================
-- AUTOMATED PROCESSING TASKS - Data Pipeline Orchestration
-- ============================================================
-- Automated tasks triggered by stream data availability. All tasks run
-- on 1-hour schedule with stream-based triggering for efficient resource
-- usage. Error handling continues processing despite individual record failures.

-- Payment transaction loading task
CREATE OR REPLACE TASK PAYI_RAW_TASK_LOAD_TRANSACTIONS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('PAYI_RAW_STREAM_TRANSACTION_FILES')
AS
    COPY INTO PAYI_RAW_TB_TRANSACTIONS (BOOKING_DATE, VALUE_DATE, TRANSACTION_ID, ACCOUNT_ID, AMOUNT, CURRENCY, BASE_AMOUNT, BASE_CURRENCY, FX_RATE, COUNTERPARTY_ACCOUNT, DESCRIPTION)
    FROM @PAYI_RAW_STAGE_TRANSACTIONS
    PATTERN = '.*pay_transactions.*\.csv'
    FILE_FORMAT = PAYI_FF_TRANSACTION_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- TASK ACTIVATION - Enable Automated Processing
-- ============================================================
-- Tasks must be explicitly resumed to begin processing. This allows for
-- controlled deployment and testing before enabling automated data flows.

-- Enable payment transaction data loading
ALTER TASK PAYI_RAW_TASK_LOAD_TRANSACTIONS RESUME;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ PAY_RAW_001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 1 Stage: PAYI_RAW_TB_TRANSACTIONS
-- • 1 File Format: PAYI_FF_TRANSACTION_CSV
-- • 1 Table: PAYI_RAW_TB_TRANSACTIONS
-- • 1 Stream: PAYI_RAW_STREAM_TRANSACTION_FILES
-- • 1 Task: PAYI_RAW_TASK_LOAD_TRANSACTIONS (ACTIVE)
--
-- NEXT STEPS:
-- 1. ✅ PAY_RAW_001 schema deployed successfully
-- 2. Upload payment transaction CSV files to PAYI_RAW_TB_TRANSACTIONS stage
-- 3. Monitor task execution: SHOW TASKS IN SCHEMA PAY_RAW_001;
-- 4. Verify data loading: SELECT COUNT(*) FROM PAYI_RAW_TB_TRANSACTIONS;
-- 5. Check for processing errors in task history
-- 6. Proceed to deploy dependent schemas (EQTI, FIII, CMDI)
--
-- USAGE EXAMPLES:
-- -- Upload files
-- PUT file://pay_transactions.csv @PAYI_RAW_TB_TRANSACTIONS;
-- 
-- -- Check transaction distribution
-- SELECT CURRENCY, COUNT(*) as transaction_count,
--        SUM(BASE_AMOUNT) as total_amount_chf
-- FROM PAYI_RAW_TB_TRANSACTIONS 
-- GROUP BY CURRENCY;
--
-- -- Monitor stream for new data
-- SELECT * FROM PAYI_RAW_STREAM_TRANSACTION_FILES;
--
-- -- Check task execution history
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
-- WHERE NAME = 'PAYI_RAW_TASK_LOAD_TRANSACTIONS'
-- ORDER BY SCHEDULED_TIME DESC;
-- ============================================================
-- PAY_RAW_001 Schema Setup Complete!
-- ============================================================
