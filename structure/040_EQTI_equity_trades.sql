-- ============================================================
-- EQT_RAW_001 Schema - Equity Trading Data
-- Generated on: 2025-09-22 15:50:17
-- ============================================================
--
-- OVERVIEW:
-- This schema contains equity trading data following FIX protocol standards
-- for the synthetic EMEA retail bank data generator.
--
-- BUSINESS PURPOSE:
-- - Equity trading operations for retail banking customers
-- - FIX protocol compliance for institutional trading standards
-- - Multi-currency support with CHF as base currency
-- - Investment account integration for settlement
-- - Automated data ingestion and processing
--
-- SUPPORTED CURRENCIES:
-- EUR (Euro), GBP (British Pound), USD (US Dollar), CHF (Swiss Franc),
-- NOK (Norwegian Krone), SEK (Swedish Krona), DKK (Danish Krone)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (1):
-- │  └─ EQTI_RAW_TB_TRADES      - Equity trade files
-- │
-- ├─ FILE FORMATS (1):
-- │  └─ EQTI_FF_TRADES_CSV - Equity trade CSV format
-- │
-- ├─ TABLES (1):
-- │  └─ EQTI_RAW_TB_TRADES - Equity trades with FIX protocol compliance
-- │
-- ├─ STREAMS (1):
-- │  └─ EQTI_RAW_STREAM_TRADES_FILES - Detects new trade files
-- │
-- └─ TASKS (1):
--    └─ EQTI_RAW_TASK_LOAD_TRADES - Automated trade loading
--
-- DATA ARCHITECTURE:
-- File Upload → Stage → Stream Detection → Task Processing → Table
--
-- REFRESH STRATEGY:
-- - Tasks: 1-hour schedule with stream-based triggering
-- - Error Handling: ON_ERROR = CONTINUE for resilient processing
-- - Pattern Matching: *trades*.csv for flexible file naming
--
-- RELATED SCHEMAS:
-- - CRM_RAW_001: Customer and account master data (foreign key relationships)
-- - REF_RAW_001: FX rates for currency conversion
-- - PAY_RAW_001: Payment transactions (account references)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA EQT_RAW_001;

-- ============================================================
-- INTERNAL STAGES - File Landing Areas
-- ============================================================
-- Internal stages for CSV file ingestion with directory listing enabled
-- for automated file detection via streams. All stages support PUT/GET
-- operations for manual file uploads and downloads.

-- Equity trade data stage
CREATE OR REPLACE STAGE EQTI_RAW_STAGE_TRADES
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for equity trade CSV files. Expected pattern: *trades*.csv with fields: trade_date, trade_id, customer_id, account_id, symbol, side, quantity, price, etc.';

-- ============================================================
-- FILE FORMATS - CSV Parsing Configurations
-- ============================================================
-- Standardized CSV file formats for consistent data ingestion across
-- all equity trade data sources. All formats handle quoted fields,
-- trim whitespace, and use flexible column count matching.

-- Equity trade CSV format
CREATE OR REPLACE FILE FORMAT EQTI_FF_TRADES_CSV
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
    COMMENT = 'CSV format for equity trade data with FIX protocol compliance and currency conversion support';

-- ============================================================
-- MASTER DATA TABLES - Equity Trade Information
-- ============================================================

-- ============================================================
-- EQTI_RAW_TB_TRADES - Equity Trades with FIX Protocol Compliance
-- ============================================================
-- Equity trading data via FIX protocol with CHF as base currency
-- for retail banking investment operations

CREATE OR REPLACE TABLE EQTI_RAW_TB_TRADES (
    TRADE_DATE TIMESTAMP_NTZ NOT NULL COMMENT 'Trade execution timestamp (ISO 8601 UTC format)',
    SETTLEMENT_DATE DATE NOT NULL COMMENT 'Settlement date (YYYY-MM-DD)',
    TRADE_ID VARCHAR(50) NOT NULL COMMENT 'Unique trade identifier',
    CUSTOMER_ID VARCHAR(30) NOT NULL COMMENT 'Reference to customer',
    ACCOUNT_ID VARCHAR(30) NOT NULL COMMENT 'Investment account used for settlement (References ACCI_RAW_TB_ACCOUNTS.ACCOUNT_ID where ACCOUNT_TYPE = ''INVESTMENT'')',
    ORDER_ID VARCHAR(50) NOT NULL COMMENT 'Order reference',
    EXEC_ID VARCHAR(50) NOT NULL COMMENT 'Execution reference',
    SYMBOL VARCHAR(20) NOT NULL COMMENT 'Stock symbol',
    ISIN VARCHAR(12) COMMENT 'International Securities Identification Number',
    SIDE CHAR(1) NOT NULL COMMENT 'FIX protocol side (1=Buy, 2=Sell)',
    QUANTITY NUMBER(15,4) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Number of shares/units',
    PRICE NUMBER(18,6) NOT NULL COMMENT 'Price per share/unit',
    CURRENCY VARCHAR(3) NOT NULL COMMENT 'Trade currency',
    GROSS_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Signed gross trade amount (positive for buys, negative for sells)',
    COMMISSION NUMBER(12,4) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Trading commission',
    NET_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Signed net amount after commission',
    BASE_CURRENCY VARCHAR(3) NOT NULL DEFAULT 'CHF' COMMENT 'Base currency for reporting (CHF)',
    BASE_GROSS_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Gross amount in CHF',
    BASE_NET_AMOUNT NUMBER(18,2) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Net amount in CHF',
    FX_RATE NUMBER(12,6) NOT NULL COMMENT 'Exchange rate to CHF',
    MARKET VARCHAR(10) NOT NULL COMMENT 'Exchange/market (NYSE, LSE, XETRA, etc.)',
    ORDER_TYPE VARCHAR(15) NOT NULL COMMENT 'Order type (MARKET, LIMIT, STOP, etc.)',
    EXEC_TYPE VARCHAR(15) NOT NULL COMMENT 'Execution type (NEW, PARTIAL_FILL, FILL, etc.)',
    TIME_IN_FORCE VARCHAR(10) COMMENT 'Time in force (DAY, GTC, IOC, etc.)',
    BROKER_ID VARCHAR(20) COMMENT 'Executing broker',
    VENUE VARCHAR(20) COMMENT 'Trading venue',

    -- Metadata
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),

    -- Constraints
    CONSTRAINT PK_EQTI_RAW_TB_TRADES PRIMARY KEY (TRADE_ID),
    CONSTRAINT FK_EQTI_RAW_TB_TRADES_ACCOUNT FOREIGN KEY (ACCOUNT_ID) REFERENCES AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS(ACCOUNT_ID)
    -- FK to CRMI_RAW_TB_CUSTOMER removed due to SCD Type 2 composite PK
    -- CHECK constraints not supported in Snowflake - replaced with comments for documentation
    -- CHK_EQ_SIDE: SIDE should be '1' (Buy) or '2' (Sell) per FIX protocol
    -- CHK_EQ_CURRENCY: CURRENCY should be in ('USD', 'EUR', 'GBP', 'JPY', 'CHF')
    -- CHK_EQ_BASE_CURRENCY: BASE_CURRENCY should be 'CHF'
    -- CHK_EQ_QUANTITY_POSITIVE: QUANTITY should be > 0
    -- CHK_EQ_PRICE_POSITIVE: PRICE should be > 0
    -- CHK_EQ_COMMISSION_POSITIVE: COMMISSION should be >= 0
    -- CHK_EQ_FX_RATE_POSITIVE: FX_RATE should be > 0
    -- CHK_EQ_SETTLEMENT_DATE: SETTLEMENT_DATE should be >= TRADE_DATE
    -- CHK_EQ_ACCOUNT_TYPE: Referenced ACCOUNT_ID should have ACCOUNT_TYPE = 'INVESTMENT'
)
COMMENT = 'Equity trades via FIX protocol with CHF as base currency. Uses INVESTMENT accounts from ACCI_RAW_TB_ACCOUNTS. Signed amounts: positive for purchases, negative for sales.';

-- ============================================================
-- CHANGE DETECTION STREAMS - File Monitoring
-- ============================================================
-- Streams monitor stages for new files and trigger automated processing
-- tasks. Each stream detects specific file patterns and maintains change
-- tracking for reliable data pipeline processing.

-- Equity trade file detection stream
CREATE OR REPLACE STREAM EQTI_RAW_STREAM_TRADES_FILES
    ON STAGE EQTI_RAW_STAGE_TRADES
    COMMENT = 'Monitors EQTI_RAW_STAGE_TRADES stage for new equity trade CSV files. Triggers EQTI_RAW_TASK_LOAD_TRADES when files matching *trades*.csv pattern are detected';

-- ============================================================
-- AUTOMATED PROCESSING TASKS - Data Pipeline Orchestration
-- ============================================================
-- Automated tasks triggered by stream data availability. All tasks run
-- on 1-hour schedule with stream-based triggering for efficient resource
-- usage. Error handling continues processing despite individual record failures.

-- Equity trade loading task
CREATE OR REPLACE TASK EQTI_RAW_TASK_LOAD_TRADES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('EQTI_RAW_STREAM_TRADES_FILES')
AS
    COPY INTO EQTI_RAW_TB_TRADES (TRADE_DATE, SETTLEMENT_DATE, TRADE_ID, CUSTOMER_ID, ACCOUNT_ID, ORDER_ID, EXEC_ID, SYMBOL, ISIN, SIDE, QUANTITY, PRICE, CURRENCY, GROSS_AMOUNT, COMMISSION, NET_AMOUNT, BASE_CURRENCY, BASE_GROSS_AMOUNT, BASE_NET_AMOUNT, FX_RATE, MARKET, ORDER_TYPE, EXEC_TYPE, TIME_IN_FORCE, BROKER_ID, VENUE)
    FROM @EQTI_RAW_STAGE_TRADES
    PATTERN = '.*trades.*\.csv'
    FILE_FORMAT = EQTI_FF_TRADES_CSV
    ON_ERROR = CONTINUE;

-- ============================================================
-- TASK ACTIVATION - Enable Automated Processing
-- ============================================================
-- Tasks must be explicitly resumed to begin processing. This allows for
-- controlled deployment and testing before enabling automated data flows.

-- Enable equity trade data loading
ALTER TASK EQTI_RAW_TASK_LOAD_TRADES RESUME;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ EQT_RAW_001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 1 Stage: EQTI_RAW_TB_TRADES
-- • 1 File Format: EQTI_FF_TRADES_CSV
-- • 1 Table: EQTI_RAW_TB_TRADES
-- • 1 Stream: EQTI_RAW_STREAM_TRADES_FILES
-- • 1 Task: EQTI_RAW_TASK_LOAD_TRADES (ACTIVE)
--
-- NEXT STEPS:
-- 1. ✅ EQT_RAW_001 schema deployed successfully
-- 2. Upload equity trade CSV files to EQTI_RAW_TB_TRADES stage
-- 3. Monitor task execution: SHOW TASKS IN SCHEMA EQT_RAW_001;
-- 4. Verify data loading: SELECT COUNT(*) FROM EQTI_RAW_TB_TRADES;
-- 5. Check for processing errors in task history
-- 6. Proceed to deploy dependent schemas (FIII, CMDI)
--
-- USAGE EXAMPLES:
-- -- Upload files
-- PUT file://trades.csv @EQTI_RAW_TB_TRADES;
-- 
-- -- Check trade distribution
-- SELECT SYMBOL, COUNT(*) as trade_count,
--        SUM(BASE_GROSS_AMOUNT) as total_value_chf
-- FROM EQTI_RAW_TB_TRADES 
-- GROUP BY SYMBOL;
--
-- -- Monitor stream for new data
-- SELECT * FROM EQTI_RAW_STREAM_TRADES_FILES;
--
-- -- Check task execution history
-- SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
-- WHERE NAME = 'EQTI_RAW_TASK_LOAD_TRADES'
-- ORDER BY SCHEDULED_TIME DESC;
-- ============================================================
-- EQT_RAW_001 Schema Setup Complete!
-- ============================================================
