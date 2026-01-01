-- ============================================================
-- CRM_RAW_001 Schema - Customer Relationship Management & Lifecycle Events
-- Generated on: 2025-10-11 (Reorganized - Objects grouped by type)
-- ============================================================
--
-- OVERVIEW:
-- This schema contains customer master data, lifecycle events, and compliance data 
-- for the synthetic EMEA retail bank data generator. Supports 12 EMEA countries with 
-- localized customer data, SCD Type 2 address history, lifecycle event tracking, 
-- and Politically Exposed Persons (PEP) compliance.
--
-- SUPPORTED COUNTRIES:
-- Norway, Netherlands, Sweden, Germany, France, Italy, United Kingdom, 
-- Denmark, Belgium, Austria, Switzerland
--
-- DATA ARCHITECTURE:
-- - Customer data separated from address data for normalization
-- - Address history tracked with SCD Type 2 via dynamic tables
-- - Lifecycle events for churn prediction and behavioral analytics
-- - Customer status history with SCD Type 2 for regulatory reporting
-- - PEP data for regulatory compliance and risk management
-- - Automated loading via streams and serverless tasks
--
-- OBJECTS CREATED:
-- ┌─ STAGES (4):
-- │  ├─ CRMI_RAW_STAGE_CUSTOMERS        - Customer master data files
-- │  ├─ CRMI_RAW_TB_ADDRESSES        - Customer address files (SCD Type 2)
-- │  ├─ CRMI_RAW_TB_EXPOSED_PERSON   - Politically Exposed Persons files
-- │  └─ CRMI_RAW_STAGE_CUSTOMER_EVENTS  - Lifecycle events and status files
-- │
-- ┌─ FILE FORMATS (5):
-- │  ├─ CRMI_FF_CUSTOMER_CSV         - Customer CSV format
-- │  ├─ CRMI_FF_ADDRESS_CSV          - Address CSV format
-- │  ├─ CRMI_FF_EXPOSED_PERSON_CSV   - PEP CSV format
-- │  ├─ CRMI_FF_CUSTOMER_EVENT_CSV   - Lifecycle event CSV format
-- │  └─ CRMI_FF_CUSTOMER_STATUS_CSV  - Status history CSV format
-- │
-- ┌─ TABLES (5):
-- │  ├─ CRMI_RAW_TB_CUSTOMER         - Customer master data (normalized)
-- │  ├─ CRMI_RAW_TB_ADDRESSES        - Address base table (append-only)
-- │  ├─ CRMI_RAW_TB_EXPOSED_PERSON   - PEP compliance data
-- │  ├─ CRMI_RAW_TB_CUSTOMER_EVENT   - Lifecycle event log (8 event types)
-- │  └─ CRMI_RAW_TB_CUSTOMER_STATUS  - Status history (SCD Type 2)
-- │
-- ┌─ STREAMS (5):
-- │  ├─ CRMI_RAW_STREAM_CUSTOMER_FILES        - Detects new customer files
-- │  ├─ CRMI_RAW_STREAM_ADDRESS_FILES         - Detects new address files
-- │  ├─ CRMI_RAW_STREAM_EXPOSED_PERSON_FILES  - Detects new PEP files
-- │  ├─ CRMI_RAW_STREAM_CUSTOMER_EVENT_FILES  - Detects new event files
-- │  └─ CRMI_RAW_STREAM_CUSTOMER_STATUS_FILES - Detects new status files
-- │
-- └─ TASKS (5 - All Serverless):
--    ├─ CRMI_RAW_TASK_LOAD_CUSTOMERS        - Automated customer loading
--    ├─ CRMI_RAW_TASK_LOAD_ADDRESSES        - Automated address loading
--    ├─ CRMI_RAW_TASK_LOAD_EXPOSED_PERSON   - Automated PEP loading
--    ├─ CRMI_RAW_TASK_LOAD_CUSTOMER_EVENTS  - Automated event loading
--    └─ CRMI_RAW_TASK_LOAD_CUSTOMER_STATUS  - Automated status loading
--
-- RELATED SCHEMAS:
-- - CRM_AGG_001 - Customer aggregations and SCD Type 2 views
-- - PAY_RAW_001 - Payment transaction data
-- - REP_AGG_001 - Cross-domain reporting and analytics
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_RAW_001;

-- ============================================================
-- SECTION 1: INTERNAL STAGES
-- ============================================================
-- Internal stages for CSV file ingestion with directory listing enabled
-- for automated file detection via streams. All stages support PUT/GET
-- operations for manual file uploads and downloads.

-- Customer master data stage
CREATE OR REPLACE STAGE CRMI_RAW_STAGE_CUSTOMERS
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for customer master data CSV files. Expected pattern: *customers*.csv';

-- Customer address data stage (SCD Type 2)
CREATE OR REPLACE STAGE CRMI_RAW_STAGE_ADDRESSES
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for customer address CSV files with SCD Type 2 support. Expected pattern: *customer_addresses*.csv';

-- Politically Exposed Person compliance data stage
CREATE OR REPLACE STAGE CRMI_RAW_STAGE_EXPOSED_PERSON
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for PEP (Politically Exposed Persons) compliance CSV files. Expected pattern: *pep*.csv';

-- Customer lifecycle events stage
CREATE OR REPLACE STAGE CRMI_RAW_STAGE_CUSTOMER_EVENTS
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for customer lifecycle event and status CSV files. Expected patterns: *customer_events*.csv, *customer_status*.csv';

-- ============================================================
-- SECTION 2: FILE FORMATS
-- ============================================================
-- Standardized CSV file formats for consistent data ingestion across
-- all customer-related data sources. All formats handle quoted fields,
-- trim whitespace, and use flexible column count matching.

-- Customer master data CSV format
CREATE OR REPLACE FILE FORMAT CRMI_FF_CUSTOMER_CSV
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
    COMMENT = 'CSV format for customer master data with EMEA localization support';

-- Customer address CSV format (SCD Type 2)
CREATE OR REPLACE FILE FORMAT CRMI_FF_ADDRESS_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    COMMENT = 'CSV format for customer address data with SCD Type 2 support via INSERT_TIMESTAMP_UTC';

-- Politically Exposed Person compliance CSV format
CREATE OR REPLACE FILE FORMAT CRMI_FF_EXPOSED_PERSON_CSV
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
    COMMENT = 'CSV format for PEP (Politically Exposed Persons) compliance data';

-- Customer lifecycle event CSV format
CREATE OR REPLACE FILE FORMAT CRMI_FF_CUSTOMER_EVENT_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    COMMENT = 'CSV format for customer lifecycle event files with JSON event details (using single quotes in JSON for CSV compatibility)';

-- Customer status history CSV format
CREATE OR REPLACE FILE FORMAT CRMI_FF_CUSTOMER_STATUS_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    COMMENT = 'CSV format for customer status history files (SCD Type 2)';

-- ============================================================
-- SECTION 3: TABLES
-- ============================================================
-- Master data tables for customer information, addresses, lifecycle events,
-- and compliance. Tables use data sensitivity tags for PII protection.

-- ------------------------------------------------------------
-- CRMI_RAW_TB_CUSTOMER - Customer Master Data (SCD Type 2)
-- ------------------------------------------------------------
-- Comprehensive customer information with SCD Type 2 tracking for attribute changes.
-- Each update to mutable attributes (employer, account_tier, etc.) creates a new record
-- with INSERT_TIMESTAMP_UTC. Immutable attributes (name, DOB) remain constant across versions.
--
-- Supports 12 EMEA countries with localized data generation and anomaly detection.
-- Address data stored separately in CRMI_RAW_TB_ADDRESSES with its own SCD Type 2 tracking.
--
-- Use CRMA_AGG_DT_CUSTOMER_CURRENT (in CRM_AGG_001 schema) for current state view.


CREATE OR REPLACE TABLE CRMI_RAW_TB_CUSTOMER (
    CUSTOMER_ID VARCHAR(30) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Unique customer identifier (CUST_XXXXX format)',
    FIRST_NAME VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Customer first name (localized to country)',
    FAMILY_NAME VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Customer family/last name (localized to country)',
    DATE_OF_BIRTH DATE NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Date of birth (YYYY-MM-DD format)',
    ONBOARDING_DATE DATE NOT NULL COMMENT 'Customer onboarding date (YYYY-MM-DD)',
    REPORTING_CURRENCY VARCHAR(3) NOT NULL COMMENT 'Customer reporting currency based on country (EUR, GBP, USD, CHF, NOK, SEK, DKK, PLN)',
    HAS_ANOMALY BOOLEAN NOT NULL DEFAULT FALSE WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Flag indicating customer has anomalous transaction patterns for compliance testing',
    EMPLOYER VARCHAR(200) WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Employer name (nullable for unemployed/retired)',
    POSITION VARCHAR(100) COMMENT 'Job position/title',
    EMPLOYMENT_TYPE VARCHAR(30) COMMENT 'Employment type (FULL_TIME, PART_TIME, CONTRACT, SELF_EMPLOYED, RETIRED, UNEMPLOYED)',
    INCOME_RANGE VARCHAR(30) COMMENT 'Income range bracket (e.g., 50K-75K, 100K-150K)',
    ACCOUNT_TIER VARCHAR(30) COMMENT 'Account tier (STANDARD, SILVER, GOLD, PLATINUM, PREMIUM)',
    EMAIL VARCHAR(255) WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Customer email address',
    PHONE VARCHAR(50) WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Customer phone number',
    PREFERRED_CONTACT_METHOD VARCHAR(20) COMMENT 'Preferred contact method (EMAIL, SMS, POST, MOBILE_APP)',
    RISK_CLASSIFICATION VARCHAR(20) WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Risk classification (LOW, MEDIUM, HIGH)',
    CREDIT_SCORE_BAND VARCHAR(20) WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Credit score band (POOR, FAIR, GOOD, VERY_GOOD, EXCELLENT)',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when this customer record version was inserted (for SCD Type 2)',

    CONSTRAINT PK_CRMI_RAW_TB_CUSTOMER PRIMARY KEY (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)
)
COMMENT = 'Customer master data table with SCD Type 2 support for tracking attribute changes over time. Extended attributes include employment, account tier, contact preferences, and risk profile. Multiple records per customer allowed, uniquely identified by (CUSTOMER_ID, INSERT_TIMESTAMP_UTC). Address data stored separately in CRMI_RAW_TB_ADDRESSES with its own SCD Type 2 tracking.';

-- ------------------------------------------------------------
-- CRMI_RAW_TB_ADDRESSES - Customer Address Base Table (SCD Type 2)
-- ------------------------------------------------------------
-- Append-only address table supporting SCD Type 2 via INSERT_TIMESTAMP_UTC.
-- Dynamic tables in CRM_AGG_001 schema provide current and historical views.
-- Each address change creates a new record with timestamp for audit trail.

CREATE OR REPLACE TABLE CRMI_RAW_TB_ADDRESSES (
    CUSTOMER_ID VARCHAR(30) NOT NULL COMMENT 'Reference to customer (foreign key to CRMI_RAW_TB_CUSTOMER)',
    STREET_ADDRESS VARCHAR(200) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Street address (localized format)',
    CITY VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'City name (localized to country)',
    STATE VARCHAR(100) COMMENT 'State/Region (where applicable for the country)',
    ZIPCODE VARCHAR(20) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Postal code (country-specific format)',
    COUNTRY VARCHAR(50) NOT NULL COMMENT 'Customer country (12 EMEA countries supported)',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp when this address record was inserted (for SCD Type 2)',
    
    CONSTRAINT PK_CRMI_RAW_TB_ADDRESSES PRIMARY KEY (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)
)
COMMENT = 'Customer address base table with append-only structure (SCD Type 2). Multiple records per customer are allowed, uniquely identified by (CUSTOMER_ID, INSERT_TIMESTAMP_UTC). Dynamic tables in CRM_AGG_001 provide current and historical views.';

-- ------------------------------------------------------------
-- CRMI_RAW_TB_EXPOSED_PERSON - Politically Exposed Persons (Compliance)
-- ------------------------------------------------------------
-- PEP master data for regulatory compliance and risk management.
-- Tracks current and former political figures, family members, and associates
-- for automated compliance screening and regulatory reporting requirements.

CREATE OR REPLACE TABLE CRMI_RAW_TB_EXPOSED_PERSON (
    EXPOSED_PERSON_ID VARCHAR(50) NOT NULL COMMENT 'Unique PEP identifier',
    FULL_NAME VARCHAR(200) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Full name of the politically exposed person',
    FIRST_NAME VARCHAR(100) WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'First name',
    LAST_NAME VARCHAR(100) NOT NULL WITH TAG (SENSITIVITY_LEVEL='top_secret') COMMENT 'Last name/family name',
    DATE_OF_BIRTH DATE WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Date of birth (YYYY-MM-DD)',
    NATIONALITY VARCHAR(50) COMMENT 'Nationality/citizenship',
    POSITION_TITLE VARCHAR(200) NOT NULL COMMENT 'Political position or title held',
    ORGANIZATION VARCHAR(200) COMMENT 'Government organization or political party',
    COUNTRY VARCHAR(50) NOT NULL COMMENT 'Country where political position is/was held',
    EXPOSED_PERSON_CATEGORY VARCHAR(50) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'PEP category: DOMESTIC, FOREIGN, INTERNATIONAL_ORG, FAMILY_MEMBER, CLOSE_ASSOCIATE',
    RISK_LEVEL VARCHAR(20) NOT NULL WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Risk assessment level: LOW, MEDIUM, HIGH, CRITICAL',
    STATUS VARCHAR(20) NOT NULL COMMENT 'Current status: ACTIVE, INACTIVE, DECEASED',
    START_DATE DATE COMMENT 'Date when PEP status began (YYYY-MM-DD)',
    END_DATE DATE COMMENT 'Date when PEP status ended (YYYY-MM-DD), NULL if still active',
    REFERENCE_LINK VARCHAR(500) COMMENT 'URL reference to official source or documentation',
    SOURCE VARCHAR(100) COMMENT 'Data source (e.g., government website, sanctions list)',
    LAST_UPDATED DATE NOT NULL COMMENT 'Date when record was last updated (YYYY-MM-DD)',
    CREATED_DATE DATE NOT NULL COMMENT 'Date when record was created (YYYY-MM-DD)',
    
    CONSTRAINT PK_CRMI_RAW_TB_EXPOSED_PERSON PRIMARY KEY (EXPOSED_PERSON_ID)
)
COMMENT = 'Politically Exposed Persons (PEP) master data for compliance and risk management. Tracks current and former political figures, their family members, and close associates for regulatory compliance.';

-- ------------------------------------------------------------
-- CRMI_RAW_TB_CUSTOMER_EVENT - Customer Lifecycle Event Log
-- ------------------------------------------------------------
-- Comprehensive lifecycle event tracking for churn prediction and behavioral analytics.
-- Captures all significant customer status changes, account modifications, and milestones.
-- Supports 8 event types: ONBOARDING, ADDRESS_CHANGE, EMPLOYMENT_CHANGE, ACCOUNT_UPGRADE,
-- ACCOUNT_DOWNGRADE, ACCOUNT_CLOSE, REACTIVATION, CHURN.
--
-- PREVIOUS_VALUE and NEW_VALUE fields:
-- These fields provide a quick summary of what changed during the event:
--   • ADDRESS_CHANGE: "Old Street, Old City" → "New Street, New City"
--   • EMPLOYMENT_CHANGE: "Old Company" → "New Company"
--   • ACCOUNT_UPGRADE: "STANDARD" → "PREMIUM"
--   • ACCOUNT_DOWNGRADE: "GOLD" → "STANDARD"
--   • STATUS_CHANGE: "ACTIVE" → "CLOSED"
--   • ONBOARDING: "PROSPECT" → "ACTIVE"
--
-- Purpose: Enable quick filtering and reporting without parsing EVENT_DETAILS JSON.
-- The full details are stored in EVENT_DETAILS as structured JSON.

CREATE OR REPLACE TABLE CRMI_RAW_TB_CUSTOMER_EVENT (
    EVENT_ID VARCHAR(50) NOT NULL COMMENT 'Unique event identifier (EVT_XXXXX format)',
    CUSTOMER_ID VARCHAR(30) NOT NULL COMMENT 'Reference to customer (foreign key to CRMI_RAW_TB_CUSTOMER)',
    EVENT_TYPE VARCHAR(30) NOT NULL COMMENT 'Type of event (ONBOARDING, ADDRESS_CHANGE, EMPLOYMENT_CHANGE, ACCOUNT_UPGRADE, ACCOUNT_DOWNGRADE, ACCOUNT_CLOSE, REACTIVATION, CHURN)',
    EVENT_DATE DATE NOT NULL COMMENT 'Date when the event occurred (YYYY-MM-DD)',
    EVENT_TIMESTAMP_UTC TIMESTAMP_NTZ NOT NULL COMMENT 'UTC timestamp of the event for precise ordering',
    CHANNEL VARCHAR(50) COMMENT 'Channel through which the event occurred (ONLINE, BRANCH, MOBILE, PHONE, SYSTEM)',
    EVENT_DETAILS VARIANT COMMENT 'JSON object containing event-specific details (e.g., old/new address, job title, account type, income changes)',
    PREVIOUS_VALUE VARCHAR(500) COMMENT 'Previous state before event (e.g., "Old Company", "STANDARD tier", "123 Old St, City") - for quick filtering without JSON parsing',
    NEW_VALUE VARCHAR(500) COMMENT 'New state after event (e.g., "New Company", "PREMIUM tier", "456 New Ave, Town") - for quick filtering without JSON parsing',
    TRIGGERED_BY VARCHAR(100) COMMENT 'User/system that triggered event (e.g., CUSTOMER_SELF_SERVICE, BRANCH_OFFICER_123, SYSTEM_AUTO)',
    REQUIRES_REVIEW BOOLEAN DEFAULT FALSE COMMENT 'Flag indicating if event requires manual compliance review',
    REVIEW_STATUS VARCHAR(20) COMMENT 'Review status (PENDING/APPROVED/REJECTED/NOT_REQUIRED)',
    REVIEW_DATE DATE COMMENT 'Date when review was completed',
    NOTES VARCHAR(1000) WITH TAG (SENSITIVITY_LEVEL='restricted') COMMENT 'Free-text notes about the event for compliance or customer service',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT 'System timestamp when record was inserted',
    
    CONSTRAINT PK_CRMI_RAW_TB_CUSTOMER_EVENT PRIMARY KEY (EVENT_ID)
)
COMMENT = 'Customer lifecycle event log tracking all significant customer status changes, account modifications, and behavioral milestones. Used for lifecycle analytics, churn prediction, and AML correlation. PREVIOUS_VALUE and NEW_VALUE provide quick summaries; full details in EVENT_DETAILS JSON. FK constraint removed due to SCD Type 2 composite PK in CRMI_RAW_TB_CUSTOMER.';

-- ------------------------------------------------------------
-- CRMI_RAW_TB_CUSTOMER_STATUS - Customer Status History (SCD Type 2)
-- ------------------------------------------------------------
-- Maintains current and historical customer status for lifecycle analysis.
-- Implements SCD Type 2 with IS_CURRENT flag and effective date ranges.
-- Linked to triggering events in CRMI_RAW_TB_CUSTOMER_EVENT for audit trail.

CREATE OR REPLACE TABLE CRMI_RAW_TB_CUSTOMER_STATUS (
    STATUS_ID VARCHAR(50) NOT NULL COMMENT 'Unique status record identifier (STAT_XXXXX format)',
    CUSTOMER_ID VARCHAR(30) NOT NULL COMMENT 'Reference to customer (foreign key to CRMI_RAW_TB_CUSTOMER)',
    STATUS VARCHAR(30) NOT NULL COMMENT 'Customer status (ACTIVE/INACTIVE/DORMANT/SUSPENDED/CLOSED/REACTIVATED)',
    STATUS_REASON VARCHAR(100) COMMENT 'Reason for status change (e.g., VOLUNTARY_CLOSURE, INACTIVITY, REGULATORY_SUSPENSION)',
    STATUS_START_DATE DATE NOT NULL COMMENT 'Date when this status became effective',
    STATUS_END_DATE DATE COMMENT 'Date when this status ended (NULL if current)',
    IS_CURRENT BOOLEAN NOT NULL DEFAULT TRUE COMMENT 'Flag indicating if this is the current status',
    LINKED_EVENT_ID VARCHAR(50) COMMENT 'Reference to triggering event in CRMI_RAW_TB_CUSTOMER_EVENT',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ NOT NULL DEFAULT CURRENT_TIMESTAMP() COMMENT 'System timestamp when record was inserted',
    
    CONSTRAINT PK_CRMI_RAW_TB_CUSTOMER_STATUS PRIMARY KEY (STATUS_ID),
    CONSTRAINT FK_CRMI_STATUS_EVENT FOREIGN KEY (LINKED_EVENT_ID) REFERENCES CRMI_RAW_TB_CUSTOMER_EVENT (EVENT_ID)
)
COMMENT = 'Customer status history with SCD Type 2 tracking. Maintains current and historical customer status for lifecycle analysis, churn prediction, and regulatory reporting. Linked to CRMI_RAW_TB_CUSTOMER_EVENT for complete audit trail. FK to CRMI_RAW_TB_CUSTOMER removed due to SCD Type 2 composite PK.';

-- ============================================================
-- SECTION 4: STREAMS
-- ============================================================
-- Streams monitor stages for new files and trigger automated processing
-- tasks. Each stream detects specific file patterns and maintains change
-- tracking for reliable data pipeline processing.

-- Customer file detection stream
CREATE OR REPLACE STREAM CRMI_RAW_STREAM_CUSTOMER_FILES
    ON STAGE CRMI_RAW_STAGE_CUSTOMERS
    COMMENT = 'Monitors CRMI_RAW_STAGE_CUSTOMERS stage for new customer CSV files. Triggers CRMI_RAW_TASK_LOAD_CUSTOMERS when files matching *customers*.csv pattern are detected';

-- Address file detection stream
CREATE OR REPLACE STREAM CRMI_RAW_STREAM_ADDRESS_FILES
    ON STAGE CRMI_RAW_STAGE_ADDRESSES
    COMMENT = 'Monitors CRMI_RAW_STAGE_ADDRESSES stage for new address CSV files. Triggers CRMI_RAW_TASK_LOAD_ADDRESSES for SCD Type 2 processing when files matching *customer_addresses*.csv pattern are detected';

-- PEP file detection stream
CREATE OR REPLACE STREAM CRMI_RAW_STREAM_EXPOSED_PERSON_FILES
    ON STAGE CRMI_RAW_STAGE_EXPOSED_PERSON
    COMMENT = 'Monitors CRMI_RAW_STAGE_EXPOSED_PERSON stage for new PEP compliance CSV files. Triggers CRMI_RAW_TASK_LOAD_EXPOSED_PERSON when files matching *pep*.csv pattern are detected';

-- Lifecycle event file detection stream
CREATE OR REPLACE STREAM CRMI_RAW_STREAM_CUSTOMER_EVENT_FILES 
    ON STAGE CRMI_RAW_STAGE_CUSTOMER_EVENTS
    COMMENT = 'Monitors CRMI_RAW_STAGE_CUSTOMER_EVENTS stage for new lifecycle event CSV files. Triggers CRMI_RAW_TASK_LOAD_CUSTOMER_EVENTS when files matching *customer_events*.csv pattern are detected';

-- Status history file detection stream
CREATE OR REPLACE STREAM CRMI_RAW_STREAM_CUSTOMER_STATUS_FILES 
    ON STAGE CRMI_RAW_STAGE_CUSTOMER_EVENTS
    COMMENT = 'Monitors CRMI_RAW_STAGE_CUSTOMER_EVENTS stage for new status history CSV files. Triggers CRMI_RAW_TASK_LOAD_CUSTOMER_STATUS when files matching *customer_status*.csv pattern are detected';

-- ============================================================
-- SECTION 5: TASKS (All Serverless)
-- ============================================================
-- Automated tasks triggered by stream data availability. All tasks use
-- USER_TASK_MANAGED (serverless) for cost efficiency and auto-scaling.
-- Error handling continues processing despite individual record failures.

-- ------------------------------------------------------------
-- Customer master data loading task
-- Serverless task: Automated loading of customer master data from CSV files.
-- Triggered by CRMI_RAW_STREAM_CUSTOMER_FILES when new files arrive.
-- Supports both file formats:
--   - customers.csv (17 cols): Initial load, uses CURRENT_TIMESTAMP()
--   - customer_updates/*.csv (18 cols): Updates with insert_timestamp_utc
-- ------------------------------------------------------------
CREATE OR REPLACE TASK CRMI_RAW_TASK_LOAD_CUSTOMERS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_RAW_STREAM_CUSTOMER_FILES')
AS
    COPY INTO CRMI_RAW_TB_CUSTOMER (
        CUSTOMER_ID, 
        FIRST_NAME, 
        FAMILY_NAME, 
        DATE_OF_BIRTH, 
        ONBOARDING_DATE, 
        REPORTING_CURRENCY, 
        HAS_ANOMALY,
        EMPLOYER,
        POSITION,
        EMPLOYMENT_TYPE,
        INCOME_RANGE,
        ACCOUNT_TIER,
        EMAIL,
        PHONE,
        PREFERRED_CONTACT_METHOD,
        RISK_CLASSIFICATION,
        CREDIT_SCORE_BAND,
        INSERT_TIMESTAMP_UTC
    )
    FROM (
        SELECT 
            $1::VARCHAR(30),
            $2::VARCHAR(100),
            $3::VARCHAR(100),
            $4::DATE,
            $5::DATE,
            $6::VARCHAR(3),
            $7::BOOLEAN,
            NULLIF($8, '')::VARCHAR(200),  -- Handle empty employer
            NULLIF($9, '')::VARCHAR(100),   -- Handle empty position
            NULLIF($10, '')::VARCHAR(30),   -- Handle empty employment_type
            NULLIF($11, '')::VARCHAR(30),   -- Handle empty income_range
            NULLIF($12, '')::VARCHAR(30),   -- Handle empty account_tier
            NULLIF($13, '')::VARCHAR(255),  -- Handle empty email
            NULLIF($14, '')::VARCHAR(50),   -- Handle empty phone
            NULLIF($15, '')::VARCHAR(20),   -- Handle empty preferred_contact_method
            NULLIF($16, '')::VARCHAR(20),   -- Handle empty risk_classification
            NULLIF($17, '')::VARCHAR(20),   -- Handle empty credit_score_band
            COALESCE(
                TRY_CAST($18 AS TIMESTAMP_NTZ),  -- Use timestamp from customer_updates/*.csv (18 cols)
                CURRENT_TIMESTAMP()               -- Fall back to current time for customers.csv (17 cols)
            ) AS INSERT_TIMESTAMP_UTC
        FROM @CRMI_RAW_STAGE_CUSTOMERS
    )
    PATTERN = '.*customers.*\.csv'
    FILE_FORMAT = CRMI_FF_CUSTOMER_CSV
    ON_ERROR = CONTINUE;

-- ------------------------------------------------------------
-- Customer address loading task (SCD Type 2)
-- Serverless task: Automated loading of customer address data with SCD Type 2 support.
-- Uses explicit column mapping and handles empty state values.
-- ------------------------------------------------------------
CREATE OR REPLACE TASK CRMI_RAW_TASK_LOAD_ADDRESSES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_RAW_STREAM_ADDRESS_FILES')
AS
    COPY INTO CRMI_RAW_TB_ADDRESSES (
        CUSTOMER_ID, 
        STREET_ADDRESS, 
        CITY, 
        STATE, 
        ZIPCODE, 
        COUNTRY, 
        INSERT_TIMESTAMP_UTC
    )
    FROM (
        SELECT 
            $1::VARCHAR(30) AS CUSTOMER_ID,
            $2::VARCHAR(200) AS STREET_ADDRESS,
            $3::VARCHAR(100) AS CITY,
            NULLIF($4, '')::VARCHAR(100) AS STATE,  -- Handle empty state values
            $5::VARCHAR(20) AS ZIPCODE,
            $6::VARCHAR(50) AS COUNTRY,
            $7::TIMESTAMP_NTZ AS INSERT_TIMESTAMP_UTC
        FROM @CRMI_RAW_STAGE_ADDRESSES
    )
    PATTERN = '.*customer_addresses.*\.csv'
    FILE_FORMAT = CRMI_FF_ADDRESS_CSV
    ON_ERROR = CONTINUE;

-- ------------------------------------------------------------
-- PEP compliance data loading task
-- Serverless task: Automated loading of PEP (Politically Exposed Persons) CSV files from stage.
-- ------------------------------------------------------------
CREATE OR REPLACE TASK CRMI_RAW_TASK_LOAD_EXPOSED_PERSON
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_RAW_STREAM_EXPOSED_PERSON_FILES')
AS
    COPY INTO CRMI_RAW_TB_EXPOSED_PERSON (
        EXPOSED_PERSON_ID, 
        FULL_NAME, 
        FIRST_NAME, 
        LAST_NAME, 
        DATE_OF_BIRTH, 
        NATIONALITY,
        POSITION_TITLE, 
        ORGANIZATION, 
        COUNTRY, 
        EXPOSED_PERSON_CATEGORY, 
        RISK_LEVEL, 
        STATUS,
        START_DATE, 
        END_DATE, 
        REFERENCE_LINK, 
        SOURCE, 
        LAST_UPDATED, 
        CREATED_DATE
    )
    FROM @CRMI_RAW_STAGE_EXPOSED_PERSON
    PATTERN = '.*pep.*\.csv'
    FILE_FORMAT = CRMI_FF_EXPOSED_PERSON_CSV
    ON_ERROR = CONTINUE;

-- ------------------------------------------------------------
-- Customer lifecycle event loading task
-- Serverless task: Automated loading of customer lifecycle event files from stage.
-- Processes events every 5 minutes for near-real-time lifecycle analytics.
-- ------------------------------------------------------------
CREATE OR REPLACE TASK CRMI_RAW_TASK_LOAD_CUSTOMER_EVENTS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_RAW_STREAM_CUSTOMER_EVENT_FILES')
AS
    COPY INTO CRMI_RAW_TB_CUSTOMER_EVENT (
        EVENT_ID,
        CUSTOMER_ID,
        EVENT_TYPE,
        EVENT_DATE,
        EVENT_TIMESTAMP_UTC,
        CHANNEL,
        EVENT_DETAILS,
        PREVIOUS_VALUE,
        NEW_VALUE,
        TRIGGERED_BY,
        REQUIRES_REVIEW,
        REVIEW_STATUS,
        REVIEW_DATE,
        NOTES
    )
    FROM (
        SELECT 
            $1::VARCHAR(50),
            $2::VARCHAR(30),
            $3::VARCHAR(30),
            $4::DATE,
            $5::TIMESTAMP_NTZ,
            $6::VARCHAR(50),
            PARSE_JSON(REPLACE($7, '''', '"')),  -- Convert single quotes back to double quotes for valid JSON
            $8::VARCHAR(500),
            $9::VARCHAR(500),
            $10::VARCHAR(100),
            $11::BOOLEAN,
            $12::VARCHAR(20),
            NULLIF($13, '')::DATE,  -- Handle empty review dates
            $14::VARCHAR(1000)
        FROM @CRMI_RAW_STAGE_CUSTOMER_EVENTS
    )
    FILE_FORMAT = CRMI_FF_CUSTOMER_EVENT_CSV
    PATTERN = '.*customer_events.*\.csv'
    ON_ERROR = CONTINUE;

-- ------------------------------------------------------------
-- Customer status history loading task
-- Serverless task: Automated loading of customer status history files from stage.
-- Processes status changes every 5 minutes for near-real-time status tracking.
-- ------------------------------------------------------------
CREATE OR REPLACE TASK CRMI_RAW_TASK_LOAD_CUSTOMER_STATUS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('CRMI_RAW_STREAM_CUSTOMER_STATUS_FILES')
AS
    COPY INTO CRMI_RAW_TB_CUSTOMER_STATUS (
        STATUS_ID,
        CUSTOMER_ID,
        STATUS,
        STATUS_REASON,
        STATUS_START_DATE,
        STATUS_END_DATE,
        IS_CURRENT,
        LINKED_EVENT_ID
    )
    FROM (
        SELECT 
            $1::VARCHAR(50),
            $2::VARCHAR(30),
            $3::VARCHAR(30),
            $4::VARCHAR(100),
            $5::DATE,
            $6::DATE,
            $7::BOOLEAN,
            $8::VARCHAR(50)
        FROM @CRMI_RAW_STAGE_CUSTOMER_EVENTS
    )
    FILE_FORMAT = CRMI_FF_CUSTOMER_STATUS_CSV
    PATTERN = '.*customer_status.*\.csv'
    ON_ERROR = CONTINUE;

-- ============================================================
-- SECTION 6: TASK ACTIVATION
-- ============================================================
-- Tasks must be explicitly resumed to begin processing. This allows for
-- controlled deployment and testing before enabling automated data flows.

-- Enable customer data loading
ALTER TASK CRMI_RAW_TASK_LOAD_CUSTOMERS RESUME;

-- Enable address data loading (SCD Type 2)
ALTER TASK CRMI_RAW_TASK_LOAD_ADDRESSES RESUME;

-- Enable PEP compliance data loading
ALTER TASK CRMI_RAW_TASK_LOAD_EXPOSED_PERSON RESUME;

-- Enable customer lifecycle event loading
ALTER TASK CRMI_RAW_TASK_LOAD_CUSTOMER_EVENTS RESUME;

-- Enable customer status history loading
ALTER TASK CRMI_RAW_TASK_LOAD_CUSTOMER_STATUS RESUME;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
