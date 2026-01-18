-- ============================================================
-- LOA_RAW_001 Schema -  Loan DocAI Processing
-- Updated: 2026-01-18
-- ============================================================
--
-- OVERVIEW:
-- Simplified DocAI pipeline for extracting loan application data from mortgage emails.
-- Uses direct file-to-AI_EXTRACT approach with 2-stage processing.
--
-- BUSINESS PURPOSE:
-- - Extract structured loan data from mortgage emails using Snowflake Cortex AI
-- - Automated, event-driven processing with minimal latency
-- - Foundation for loan origination and underwriting workflows
--
-- SIMPLIFIED ARCHITECTURE (Event-Driven):
-- 1. Files arrive → LOAI_RAW_STAGE_EMAIL_INBOUND
-- 2. Stream detects files → LOAI_RAW_STREAM_EMAIL_FILES
-- 3. Task extracts data → LOAI_RAW_TASK_EXTRACT_MAIL_DATA (AI_EXTRACT)
-- 4. Stores raw JSON → LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT
-- 5. Task flattens data → LOAI_RAW_TASK_FLAT_MAIL_DATA (runs AFTER extraction task)
-- 6. Stores typed columns → LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT
--
-- OBJECTS CREATED:
-- ┌─ STAGES (2):
-- │  ├─ LOAI_RAW_STAGE_EMAIL_INBOUND     - Email files (.txt, .eml, .msg)
-- │  └─ LOAI_RAW_STAGE_PDF_INBOUND       - PDF documents
-- │
-- ├─ TABLES (6):
-- │  ├─ Schema Config (1):
-- │  │  └─ LOAI_RAW_TB_EMAIL_INBOUND_LOAN_SCHEMA_CONFIG - AI_EXTRACT schema definition (15 fields)
-- │  │
-- │  ├─ Reference Data (3):
-- │  │  ├─ LOAI_REF_TB_PRODUCT_CATALOGUE        - Loan products (8 products)
-- │  │  ├─ LOAI_REF_TB_COUNTRY_REGIME_CONFIG    - Regulatory parameters (CH/UK/DE)
-- │  │  └─ LOAI_REF_TB_APPLICATION_STATUS       - Application status codes (12 statuses)
-- │  │
-- │  └─ DocAI Extraction (2):
-- │     ├─ LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT       - Raw AI_EXTRACT output (JSON)
-- │     └─ LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT  - Flattened typed columns (15 fields)
-- │
-- ├─ STREAMS (1 - Event-Driven Trigger):
-- │  └─ LOAI_RAW_STREAM_EMAIL_FILES    - Detects new files on stage → triggers extraction
-- │
-- └─ TASKS (2 - All Serverless):
--    ├─ LOAI_RAW_TASK_EXTRACT_MAIL_DATA - Root task (60 min schedule + stream trigger)
--    └─ LOAI_RAW_TASK_FLAT_MAIL_DATA    - Child task (runs AFTER extraction task completes)
--
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA LOA_RAW_001;

-- ============================================================
-- INTERNAL STAGES
-- ============================================================

CREATE STAGE IF NOT EXISTS LOAI_RAW_STAGE_EMAIL_INBOUND
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Staging area for mortgage email files (.txt, .eml, .msg) for DocAI processing.';

CREATE STAGE IF NOT EXISTS LOAI_RAW_STAGE_PDF_INBOUND
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Staging area for loan-related PDF documents for DocAI processing.';

-- ============================================================
-- AI_EXTRACT SCHEMA CONFIGURATION
-- ============================================================
-- Defines the 15 fields to extract from mortgage emails:
-- - 1 document classification field
-- - 14 loan application data fields
-- ============================================================

CREATE OR REPLACE TABLE LOAI_RAW_TB_EMAIL_INBOUND_LOAN_SCHEMA_CONFIG (
    schema_json VARIANT COMMENT 'AI_EXTRACT schema definition: {"field_name": "type: description"}'
) 
COMMENT = 'Configuration table storing the AI_EXTRACT schema for mortgage email processing. Defines 15 fields to extract using Snowflake Cortex AI.'
AS
SELECT PARSE_JSON('{
    "document_type": "string: classify this email as one of: MORTGAGE_APPLICATION, CUSTOMER_INQUIRY, INTERNAL_REVIEW, LOAN_OFFICER_NOTES, PRE_APPROVAL, OFFER_LETTER, GENERAL_CORRESPONDENCE. Required field.",
    "customer_name": "string: full name of the mortgage applicant or borrower. Return null if not mentioned.",
    "property_address": "string: complete property address including street, city, postal code. Return null if not mentioned.",
    "property_type": "string: type of property such as Single Family Home, Multi-family, Apartment, Condo, Townhouse, Detached House. Return null if not mentioned.",
    "purchase_price": "number: property purchase price or current market valuation in the local currency. Return only the numeric value without currency symbols. Return null if not mentioned.",
    "down_payment": "number: down payment amount or deposit being paid by the borrower in the local currency. Return only the numeric value without currency symbols. Return null if not mentioned.",
    "loan_amount": "number: requested mortgage loan amount in the local currency. Return only the numeric value without currency symbols. Return null if not mentioned.",
    "loan_term_years": "number: loan term duration in years (e.g., 15, 20, 25, 30). Return null if not mentioned.",
    "rate_type": "string: interest rate type, either Fixed or Variable (also known as Adjustable or Tracker). Return null if not mentioned.",
    "monthly_income": "number: applicant total monthly gross income before taxes in the local currency. Return only the numeric value without currency symbols. Return null if not mentioned.",
    "employment": "string: job title, occupation, or employment type (e.g., Software Engineer, Self-Employed, Government Employee, Teacher). Return null if not mentioned.",
    "employment_tenure_years": "number: number of years the applicant has been in their current employment or job. Return null if not mentioned.",
    "credit_score": "number: applicant credit score or credit rating (typically 300-850 range). Return null if not mentioned.",
    "existing_debts_monthly": "number: total monthly debt obligations including credit cards, car loans, other mortgages, in the local currency. Return only the numeric value without currency symbols. Return 0 if explicitly stated as none, return null if not mentioned.",
    "country": "string: country where the property is located (e.g., Switzerland, UK, Germany, Portugal, France). Return null if not mentioned."
}');

-- ============================================================
-- LOAN REFERENCE TABLES
-- ============================================================

-- Table: Loan Product Catalogue
CREATE OR REPLACE TABLE LOAI_REF_TB_PRODUCT_CATALOGUE (
    PRODUCT_ID VARCHAR(50) PRIMARY KEY,
    PRODUCT_NAME VARCHAR(200) NOT NULL,
    PRODUCT_TYPE VARCHAR(50) NOT NULL,
    COUNTRY VARCHAR(3) NOT NULL,
    IS_SECURED BOOLEAN NOT NULL,
    MIN_LOAN_AMOUNT NUMBER(18,2),
    MAX_LOAN_AMOUNT NUMBER(18,2),
    MIN_TERM_MONTHS INT,
    MAX_TERM_MONTHS INT,
    DEFAULT_INTEREST_RATE NUMBER(5,4),
    RATE_TYPE VARCHAR(20),
    MAX_LTV_PCT NUMBER(5,2),
    ELIGIBILITY_CRITERIA VARCHAR(1000),
    REGULATORY_CLASSIFICATION VARCHAR(100),
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    PRODUCT_LAUNCH_DATE DATE,
    PRODUCT_DISCONTINUATION_DATE DATE,
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Loan product catalogue for retail mortgages and loans across EMEA markets.';

-- Insert sample products
INSERT INTO LOAI_REF_TB_PRODUCT_CATALOGUE (
    PRODUCT_ID, PRODUCT_NAME, PRODUCT_TYPE, COUNTRY, IS_SECURED, 
    MIN_LOAN_AMOUNT, MAX_LOAN_AMOUNT, MIN_TERM_MONTHS, MAX_TERM_MONTHS, 
    DEFAULT_INTEREST_RATE, RATE_TYPE, MAX_LTV_PCT, REGULATORY_CLASSIFICATION, 
    IS_ACTIVE, PRODUCT_LAUNCH_DATE
) VALUES
    ('CH_FIXED_MORTGAGE_25Y', 'Swiss Fixed Rate Mortgage (25Y)', 'MORTGAGE', 'CHE', TRUE, 100000, 2000000, 120, 300, 0.0250, 'FIXED', 80.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2023-01-01'),
    ('CH_SARON_MORTGAGE', 'Swiss SARON Variable Mortgage', 'MORTGAGE', 'CHE', TRUE, 100000, 2000000, 120, 300, 0.0180, 'VARIABLE', 80.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2023-06-01'),
    ('CH_BUY_TO_LET_MORTGAGE', 'Swiss Buy-to-Let Mortgage', 'MORTGAGE', 'CHE', TRUE, 200000, 3000000, 120, 300, 0.0300, 'FIXED', 75.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2023-01-01'),
    ('UK_FIXED_MORTGAGE_30Y', 'UK Fixed Rate Mortgage (30Y)', 'MORTGAGE', 'GBR', TRUE, 80000, 1500000, 120, 360, 0.0450, 'FIXED', 90.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2023-01-01'),
    ('UK_TRACKER_MORTGAGE', 'UK Base Rate Tracker Mortgage', 'MORTGAGE', 'GBR', TRUE, 80000, 1500000, 120, 360, 0.0400, 'TRACKER', 90.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2023-01-01'),
    ('UK_GREEN_MORTGAGE', 'UK Green Mortgage (EPC A-C)', 'MORTGAGE', 'GBR', TRUE, 100000, 2000000, 120, 360, 0.0380, 'FIXED', 90.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2024-01-01'),
    ('DE_FIXED_MORTGAGE_20Y', 'German Fixed Rate Mortgage (20Y)', 'MORTGAGE', 'DEU', TRUE, 120000, 1800000, 60, 240, 0.0350, 'FIXED', 80.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2023-01-01'),
    ('DE_KFW_GREEN_MORTGAGE', 'German KfW Energy Efficient Mortgage', 'MORTGAGE', 'DEU', TRUE, 100000, 1500000, 60, 300, 0.0200, 'FIXED', 80.00, 'RESIDENTIAL_MORTGAGE', TRUE, '2023-06-01');

-- Table: Country-Regime Configuration
CREATE OR REPLACE TABLE LOAI_REF_TB_COUNTRY_REGIME_CONFIG (
    COUNTRY_CODE VARCHAR(3) PRIMARY KEY,
    COUNTRY_NAME VARCHAR(100) NOT NULL,
    CURRENCY_CODE VARCHAR(3) NOT NULL,
    MAX_LTV_OWNER_OCCUPIED NUMBER(5,2),
    MAX_LTV_BUY_TO_LET NUMBER(5,2),
    MIN_HARD_EQUITY_PCT NUMBER(5,2),
    AFFORDABILITY_IMPUTED_RATE NUMBER(5,4),
    AFFORDABILITY_DTI_THRESHOLD NUMBER(5,2),
    AFFORDABILITY_DSTI_THRESHOLD NUMBER(5,2),
    ANCILLARY_COSTS_PCT NUMBER(5,4),
    COOLING_OFF_PERIOD_DAYS INT,
    AMORTIZATION_REQUIRED_LTV NUMBER(5,2),
    AMORTIZATION_PERIOD_YEARS INT,
    REQUIRES_VALUATION_APPRAISAL BOOLEAN,
    ALLOWS_FOREIGN_CURRENCY_LOANS BOOLEAN,
    REGULATORY_BODY VARCHAR(200),
    CONSUMER_DUTY_APPLIES BOOLEAN DEFAULT FALSE,
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Country-specific regulatory parameters for mortgage lending (CH/UK/DE).';

INSERT INTO LOAI_REF_TB_COUNTRY_REGIME_CONFIG (
    COUNTRY_CODE, COUNTRY_NAME, CURRENCY_CODE, 
    MAX_LTV_OWNER_OCCUPIED, MAX_LTV_BUY_TO_LET, MIN_HARD_EQUITY_PCT,
    AFFORDABILITY_IMPUTED_RATE, AFFORDABILITY_DTI_THRESHOLD, AFFORDABILITY_DSTI_THRESHOLD, ANCILLARY_COSTS_PCT,
    COOLING_OFF_PERIOD_DAYS, AMORTIZATION_REQUIRED_LTV, AMORTIZATION_PERIOD_YEARS,
    REQUIRES_VALUATION_APPRAISAL, ALLOWS_FOREIGN_CURRENCY_LOANS,
    REGULATORY_BODY, CONSUMER_DUTY_APPLIES
) VALUES
    ('CHE', 'Switzerland', 'CHF', 80.00, 75.00, 10.00, 0.0500, 33.00, 33.00, 0.0100, 14, 66.67, 15, TRUE, FALSE, 'FINMA', FALSE),
    ('GBR', 'United Kingdom', 'GBP', 90.00, 80.00, 0.00, 0.0700, 45.00, 45.00, 0.0000, 0, NULL, NULL, TRUE, FALSE, 'FCA, PRA', TRUE),
    ('DEU', 'Germany', 'EUR', 80.00, 70.00, 0.00, 0.0450, 40.00, 40.00, 0.0000, 14, NULL, NULL, TRUE, FALSE, 'BaFin', FALSE);

-- Table: Application Status Codes
CREATE OR REPLACE TABLE LOAI_REF_TB_APPLICATION_STATUS (
    STATUS_CODE VARCHAR(50) PRIMARY KEY,
    STATUS_NAME VARCHAR(100) NOT NULL,
    STATUS_CATEGORY VARCHAR(50),
    DESCRIPTION VARCHAR(500),
    IS_FINAL BOOLEAN DEFAULT FALSE,
    REQUIRES_ACTION BOOLEAN DEFAULT FALSE,
    DISPLAY_ORDER INT,
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Loan application status codes for workflow management.';

INSERT INTO LOAI_REF_TB_APPLICATION_STATUS (STATUS_CODE, STATUS_NAME, STATUS_CATEGORY, DESCRIPTION, IS_FINAL, REQUIRES_ACTION, DISPLAY_ORDER) VALUES
    ('DRAFT', 'Draft', 'PENDING', 'Application started but not yet submitted', FALSE, TRUE, 1),
    ('SUBMITTED', 'Submitted', 'PENDING', 'Application submitted and awaiting review', FALSE, FALSE, 2),
    ('KYC_PENDING', 'KYC Pending', 'PENDING', 'Pending KYC verification', FALSE, TRUE, 3),
    ('UNDER_REVIEW', 'Under Review', 'PENDING', 'Under credit assessment', FALSE, FALSE, 4),
    ('APPROVED', 'Approved', 'APPROVED', 'Application approved', FALSE, FALSE, 5),
    ('OFFER_ISSUED', 'Offer Issued', 'APPROVED', 'Formal offer issued', FALSE, TRUE, 6),
    ('OFFER_ACCEPTED', 'Offer Accepted', 'APPROVED', 'Customer accepted offer', FALSE, FALSE, 7),
    ('COOLING_OFF', 'Cooling-Off Period', 'PENDING', 'Mandatory cooling-off period', FALSE, FALSE, 8),
    ('DISBURSED', 'Disbursed', 'DISBURSED', 'Loan disbursed', TRUE, FALSE, 9),
    ('DECLINED', 'Declined', 'DECLINED', 'Application declined', TRUE, FALSE, 10),
    ('WITHDRAWN', 'Withdrawn by Applicant', 'WITHDRAWN', 'Customer withdrew application', TRUE, FALSE, 11),
    ('CANCELLED', 'Cancelled by Bank', 'DECLINED', 'Application cancelled by bank', TRUE, FALSE, 12);

-- ============================================================
-- DOCAI EXTRACTION TABLES (SIMPLIFIED 2-STAGE PIPELINE)
-- ============================================================

-- STAGE 1: Raw AI_EXTRACT Output
CREATE OR REPLACE TABLE LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT (
    FILE_NAME STRING COMMENT 'Source filename from stage',
    FILE_TIMESTAMP TIMESTAMP_NTZ COMMENT 'File last modified timestamp',
    EXTRACTED_DATA VARIANT COMMENT 'Raw AI_EXTRACT JSON output: {error: null, response: {...}}',
    EXTRACTION_TIMESTAMP TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'When AI_EXTRACT was performed'
)
COMMENT = 'Raw AI_EXTRACT output from mortgage emails. Contains unflattened JSON with all 15 extracted fields.';

-- STAGE 2: Flattened Typed Columns
CREATE OR REPLACE TABLE LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT (
    FILE_NAME STRING COMMENT 'Source filename',
    FILE_TIMESTAMP TIMESTAMP_NTZ COMMENT 'File timestamp',
    EXTRACTION_TIMESTAMP TIMESTAMP_NTZ COMMENT 'Extraction timestamp',
    
    -- Document classification
    DOCUMENT_TYPE STRING COMMENT 'AI-classified document type',
    
    -- Applicant information
    CUSTOMER_NAME STRING COMMENT 'Applicant name',
    EMPLOYMENT STRING COMMENT 'Job title',
    EMPLOYMENT_TENURE_YEARS INT COMMENT 'Years in current employment',
    MONTHLY_INCOME NUMBER(18,2) COMMENT 'Monthly gross income',
    EXISTING_DEBTS_MONTHLY NUMBER(18,2) COMMENT 'Monthly debt obligations',
    CREDIT_SCORE INT COMMENT 'Credit score',
    
    -- Property information
    PROPERTY_ADDRESS STRING COMMENT 'Property address',
    PROPERTY_TYPE STRING COMMENT 'Property type',
    PURCHASE_PRICE NUMBER(18,2) COMMENT 'Property purchase price',
    
    -- Loan request
    LOAN_AMOUNT NUMBER(18,2) COMMENT 'Requested loan amount',
    DOWN_PAYMENT NUMBER(18,2) COMMENT 'Down payment',
    LOAN_TERM_YEARS INT COMMENT 'Loan term in years',
    RATE_TYPE STRING COMMENT 'Interest rate type (Fixed/Variable)',
    
    -- Geographic
    COUNTRY STRING COMMENT 'Country',
    
    -- Calculated metrics
    LTV_RATIO_PCT NUMBER(5,2) COMMENT 'Loan-to-Value ratio percentage',
    DTI_RATIO_PCT NUMBER(5,2) COMMENT 'Debt-to-Income ratio percentage',
    
    -- Metadata
    EXTRACTION_SUCCESS BOOLEAN COMMENT 'TRUE if extraction successful',
    RAW_EXTRACTED_DATA VARIANT COMMENT 'Complete raw JSON for debugging'
)
COMMENT = 'Flattened loan data with typed columns from AI_EXTRACT. Ready for business logic and reporting.';

-- ============================================================
-- NOTE: Core Loan Business Entities Moved to AGG Schema
-- ============================================================
-- 
-- The following tables have been moved to structure/465_LOAA_loans_applications.sql
-- in the LOA_AGG_001 schema (proper layering for business entities):
--
-- • LOAA_AGG_TB_APPLICATIONS              (Loan applications master)
-- • LOAA_AGG_TB_COLLATERAL                (Property collateral master)
-- • LOAA_AGG_TB_LOAN_COLLATERAL_LINK      (Loan-to-collateral M:M mapping)
-- • LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS (Affordability calculations)
--
-- These tables are populated by populate_loan_tables_from_docai.sql
-- from the flattened DocAI extraction data below.
--
-- ============================================================

-- ============================================================
-- STREAMS FOR CHANGE DETECTION
-- ============================================================

-- Stream to detect new files arriving on the stage
CREATE OR REPLACE STREAM LOAI_RAW_STREAM_EMAIL_FILES
ON STAGE LOAI_RAW_STAGE_EMAIL_INBOUND
COMMENT = 'Stream to detect new email files arriving on the stage. Triggers LOAI_RAW_TASK_EXTRACT_MAIL_DATA when new .txt files are uploaded.';

-- ============================================================
-- TASK 1: EXTRACT FROM STAGE FILES USING AI_EXTRACT
-- ============================================================
-- Event-driven task triggered when new files arrive on stage
-- Runs every 60 minutes ONLY when stream has data (new files uploaded)
-- Extracts 15 fields using Snowflake Cortex AI_EXTRACT
-- Stores raw JSON output in LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT
-- ============================================================

CREATE OR REPLACE TASK LOAI_RAW_TASK_EXTRACT_MAIL_DATA
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'SMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('LOAI_RAW_STREAM_EMAIL_FILES')
AS
INSERT INTO LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT (
    FILE_NAME,
    FILE_TIMESTAMP,
    EXTRACTED_DATA,
    EXTRACTION_TIMESTAMP
)
SELECT 
    RELATIVE_PATH AS FILE_NAME,
    LAST_MODIFIED::TIMESTAMP_NTZ AS FILE_TIMESTAMP,  -- Convert from TIMESTAMP_TZ to TIMESTAMP_NTZ
    SNOWFLAKE.CORTEX.AI_EXTRACT(
        TO_FILE('@LOAI_RAW_STAGE_EMAIL_INBOUND', RELATIVE_PATH),
        (SELECT schema_json FROM LOAI_RAW_TB_EMAIL_INBOUND_LOAN_SCHEMA_CONFIG)
    ) AS EXTRACTED_DATA,
    CURRENT_TIMESTAMP() AS EXTRACTION_TIMESTAMP
FROM DIRECTORY(@LOAI_RAW_STAGE_EMAIL_INBOUND)
WHERE RELATIVE_PATH LIKE '%mortgage%'
  AND RELATIVE_PATH LIKE '%_internal.txt'  -- Internal emails contain all required fields
  -- Idempotency: skip files already extracted
  AND NOT EXISTS (
      SELECT 1 FROM LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT e
      WHERE e.FILE_NAME = RELATIVE_PATH
  );

-- ============================================================
-- TASK 2: FLATTEN EXTRACTED DATA TO TYPED COLUMNS
-- ============================================================
-- Child task that runs automatically AFTER extraction task completes
-- Triggered ONLY when stream has data (new extractions available)
-- Flattens AI_EXTRACT JSON to typed columns with calculations
-- Handles currency formatting (removes EUR/CHF/GBP and commas)
-- ============================================================

CREATE OR REPLACE TASK LOAI_RAW_TASK_FLAT_MAIL_DATA
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    AFTER LOAI_RAW_TASK_EXTRACT_MAIL_DATA
AS
INSERT INTO LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT (
    FILE_NAME,
    FILE_TIMESTAMP,
    EXTRACTION_TIMESTAMP,
    DOCUMENT_TYPE,
    CUSTOMER_NAME,
    EMPLOYMENT,
    EMPLOYMENT_TENURE_YEARS,
    MONTHLY_INCOME,
    EXISTING_DEBTS_MONTHLY,
    CREDIT_SCORE,
    PROPERTY_ADDRESS,
    PROPERTY_TYPE,
    PURCHASE_PRICE,
    LOAN_AMOUNT,
    DOWN_PAYMENT,
    LOAN_TERM_YEARS,
    RATE_TYPE,
    COUNTRY,
    LTV_RATIO_PCT,
    DTI_RATIO_PCT,
    EXTRACTION_SUCCESS,
    RAW_EXTRACTED_DATA
)
SELECT 
    s.FILE_NAME,
    s.FILE_TIMESTAMP,
    s.EXTRACTION_TIMESTAMP,
    
    -- Document classification (nested under 'response')
    s.EXTRACTED_DATA:response:document_type::STRING AS DOCUMENT_TYPE,
    
    -- Applicant information (convert "None" strings to NULL)
    NULLIF(s.EXTRACTED_DATA:response:customer_name::STRING, 'None') AS CUSTOMER_NAME,
    NULLIF(s.EXTRACTED_DATA:response:employment::STRING, 'None') AS EMPLOYMENT,
    CASE 
        WHEN s.EXTRACTED_DATA:response:employment_tenure_years::STRING = 'None' THEN NULL
        ELSE TRY_TO_NUMBER(s.EXTRACTED_DATA:response:employment_tenure_years::STRING)
    END AS EMPLOYMENT_TENURE_YEARS,
    
    -- Financial fields - handle "None" strings and remove currency codes/commas before converting to NUMBER
    CASE 
        WHEN s.EXTRACTED_DATA:response:monthly_income::STRING IN ('None', 'null') THEN NULL
        ELSE TRY_TO_NUMBER(
            REGEXP_REPLACE(
                REGEXP_REPLACE(s.EXTRACTED_DATA:response:monthly_income::STRING, '[A-Z]{3}', ''),
                '[,\\s]', ''
            )
        )
    END AS MONTHLY_INCOME,
    
    CASE 
        WHEN s.EXTRACTED_DATA:response:existing_debts_monthly::STRING IN ('None', 'null') THEN NULL
        ELSE TRY_TO_NUMBER(
            REGEXP_REPLACE(
                REGEXP_REPLACE(s.EXTRACTED_DATA:response:existing_debts_monthly::STRING, '[A-Z]{3}', ''),
                '[,\\s]', ''
            )
        )
    END AS EXISTING_DEBTS_MONTHLY,
    
    CASE 
        WHEN s.EXTRACTED_DATA:response:credit_score::STRING IN ('None', 'null') THEN NULL
        ELSE TRY_TO_NUMBER(s.EXTRACTED_DATA:response:credit_score::STRING)
    END AS CREDIT_SCORE,
    
    -- Property information (convert "None" strings to NULL)
    NULLIF(s.EXTRACTED_DATA:response:property_address::STRING, 'None') AS PROPERTY_ADDRESS,
    NULLIF(s.EXTRACTED_DATA:response:property_type::STRING, 'None') AS PROPERTY_TYPE,
    
    CASE 
        WHEN s.EXTRACTED_DATA:response:purchase_price::STRING IN ('None', 'null') THEN NULL
        ELSE TRY_TO_NUMBER(
            REGEXP_REPLACE(
                REGEXP_REPLACE(s.EXTRACTED_DATA:response:purchase_price::STRING, '[A-Z]{3}', ''),
                '[,\\s]', ''
            )
        )
    END AS PURCHASE_PRICE,
    
    -- Loan request details
    CASE 
        WHEN s.EXTRACTED_DATA:response:loan_amount::STRING IN ('None', 'null') THEN NULL
        ELSE TRY_TO_NUMBER(
            REGEXP_REPLACE(
                REGEXP_REPLACE(s.EXTRACTED_DATA:response:loan_amount::STRING, '[A-Z]{3}', ''),
                '[,\\s]', ''
            )
        )
    END AS LOAN_AMOUNT,
    
    CASE 
        WHEN s.EXTRACTED_DATA:response:down_payment::STRING IN ('None', 'null') THEN NULL
        ELSE TRY_TO_NUMBER(
            REGEXP_REPLACE(
                REGEXP_REPLACE(s.EXTRACTED_DATA:response:down_payment::STRING, '[A-Z]{3}', ''),
                '[,\\s]', ''
            )
        )
    END AS DOWN_PAYMENT,
    
    CASE 
        WHEN s.EXTRACTED_DATA:response:loan_term_years::STRING = 'None' THEN NULL
        ELSE TRY_TO_NUMBER(s.EXTRACTED_DATA:response:loan_term_years::STRING)
    END AS LOAN_TERM_YEARS,
    NULLIF(s.EXTRACTED_DATA:response:rate_type::STRING, 'None') AS RATE_TYPE,
    
    -- Geographic information (convert "None" strings to NULL)
    NULLIF(s.EXTRACTED_DATA:response:country::STRING, 'None') AS COUNTRY,
    
    -- Calculated LTV ratio
    CASE 
        WHEN TRY_TO_NUMBER(REGEXP_REPLACE(REGEXP_REPLACE(s.EXTRACTED_DATA:response:purchase_price::STRING, '[A-Z]{3}', ''), '[,\\s]', '')) > 0 
        THEN ROUND(
            (TRY_TO_NUMBER(REGEXP_REPLACE(REGEXP_REPLACE(s.EXTRACTED_DATA:response:loan_amount::STRING, '[A-Z]{3}', ''), '[,\\s]', '')) 
             / TRY_TO_NUMBER(REGEXP_REPLACE(REGEXP_REPLACE(s.EXTRACTED_DATA:response:purchase_price::STRING, '[A-Z]{3}', ''), '[,\\s]', ''))) * 100, 
            2
        )
        ELSE NULL 
    END AS LTV_RATIO_PCT,
    
    -- Calculated DTI ratio
    CASE 
        WHEN TRY_TO_NUMBER(REGEXP_REPLACE(REGEXP_REPLACE(s.EXTRACTED_DATA:response:monthly_income::STRING, '[A-Z]{3}', ''), '[,\\s]', '')) > 0 
        THEN ROUND(
            (TRY_TO_NUMBER(REGEXP_REPLACE(REGEXP_REPLACE(s.EXTRACTED_DATA:response:existing_debts_monthly::STRING, '[A-Z]{3}', ''), '[,\\s]', '')) 
             / TRY_TO_NUMBER(REGEXP_REPLACE(REGEXP_REPLACE(s.EXTRACTED_DATA:response:monthly_income::STRING, '[A-Z]{3}', ''), '[,\\s]', ''))) * 100, 
            2
        )
        ELSE NULL 
    END AS DTI_RATIO_PCT,
    
    -- Extraction success indicator
    CASE WHEN s.EXTRACTED_DATA:response IS NOT NULL THEN TRUE ELSE FALSE END AS EXTRACTION_SUCCESS,
    
    -- Keep raw JSON for debugging
    s.EXTRACTED_DATA AS RAW_EXTRACTED_DATA
    
FROM LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT s
WHERE NOT EXISTS (
      SELECT 1 FROM LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT f
      WHERE f.FILE_NAME = s.FILE_NAME
        AND f.EXTRACTION_TIMESTAMP = s.EXTRACTION_TIMESTAMP
  );

-- ============================================================
-- TASK ACTIVATION
-- ============================================================

-- Resume child task first (flattening)
ALTER TASK LOAI_RAW_TASK_FLAT_MAIL_DATA RESUME;

-- Resume parent task (extraction)
ALTER TASK LOAI_RAW_TASK_EXTRACT_MAIL_DATA RESUME;

-- ============================================================
-- COMPLETION STATUS
-- ============================================================
--
-- OBJECTS CREATED:
-- • 2 Stages: EMAIL_INBOUND, PDF_INBOUND
-- • 6 Tables: 1 schema config, 3 reference, 2 DocAI extraction (business entities in LOA_AGG_001)
-- • 1 Stream: EMAIL_FILES (stage) - Event-driven trigger for extraction
-- • 2 Tasks: EXTRACT_MAIL_DATA (root, 60min + stream), FLAT_MAIL_DATA (child, runs AFTER parent)
--
-- EVENT-DRIVEN DATA FLOW:
-- 1. Files uploaded → LOAI_RAW_STAGE_EMAIL_INBOUND (.txt files)
-- 2. Stream detects → LOAI_RAW_STREAM_EMAIL_FILES (new files on stage)
-- 3. Task extracts → LOAI_RAW_TASK_EXTRACT_MAIL_DATA (AI_EXTRACT, within 60 min if stream has data)
-- 4. Store raw JSON → LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT
-- 5. Task flattens → LOAI_RAW_TASK_FLAT_MAIL_DATA (runs automatically AFTER extraction completes)
-- 6. Store typed data → LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT (business-ready)
--
-- USAGE:
-- Upload files:
--   PUT file://generated_data/emails/mortgage_*.txt 
--       @LOAI_RAW_STAGE_EMAIL_INBOUND AUTO_COMPRESS=FALSE;
--
-- Monitor extraction:
--   SELECT * FROM LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT 
--   ORDER BY EXTRACTION_TIMESTAMP DESC;
--
-- Query flattened data:
--   SELECT * FROM LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT
--   WHERE EXTRACTION_SUCCESS = TRUE
--   ORDER BY EXTRACTION_TIMESTAMP DESC;
--
-- Check task status:
--   SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
--   WHERE NAME LIKE 'LOAI_RAW_TASK_%'
--   ORDER BY SCHEDULED_TIME DESC LIMIT 20;
--
-- ============================================================
