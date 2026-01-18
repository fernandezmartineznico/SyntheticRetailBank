-- ============================================================
-- LOA_AGG_001 Schema - Loan Applications & Core Entities
-- Updated: 2026-01-18
-- ============================================================
--
-- OVERVIEW:
-- Core loan origination business entities populated from DocAI-extracted data.
-- These are the transformed, business-ready tables for loan applications,
-- collateral, affordability assessments, and loan-collateral links.
--
-- BUSINESS PURPOSE:
-- - Store structured loan application data extracted from mortgage emails
-- - Track property collateral and valuation data
-- - Record affordability assessments with DTI/DSTI calculations
-- - Maintain loan-to-collateral relationships (1:1 for showcase, M:M capable)
--
-- DATA FLOW:
-- 1. RAW: Emails → AI_EXTRACT → LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT
-- 2. AGG: Flattened data → Business entities in this schema (via populate script)
--
-- OBJECTS CREATED:
-- ┌─ TABLES (4 - Core Loan Entities):
-- │  ├─ LOAA_AGG_TB_APPLICATIONS              - Loan application master (120 records)
-- │  ├─ LOAA_AGG_TB_COLLATERAL                - Property/collateral master (80 properties)
-- │  ├─ LOAA_AGG_TB_LOAN_COLLATERAL_LINK      - Loan-to-collateral M:M mapping
-- │  └─ LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS - Affordability calculations with DTI/DSTI
-- │
-- └─ POPULATION:
--    └─ Run populate_loan_tables_from_docai.sql to populate from DocAI extraction
--
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA LOA_AGG_001;

-- ============================================================
-- CORE LOAN BUSINESS ENTITIES
-- ============================================================

-- Table: Loan Applications Master
CREATE OR REPLACE TABLE LOAA_AGG_TB_APPLICATIONS (
    APPLICATION_ID VARCHAR(50) PRIMARY KEY COMMENT 'Unique application identifier (APP_*)',
    CUSTOMER_ID VARCHAR(30) COMMENT 'FK to CRMA_AGG_DT_CUSTOMER_360',
    APPLICATION_DATE_TIME TIMESTAMP_NTZ NOT NULL COMMENT 'Application submission timestamp',
    CHANNEL VARCHAR(50) COMMENT 'Application channel: EMAIL, PORTAL, BRANCH, BROKER',
    COUNTRY VARCHAR(50) COMMENT 'Country code (CHE, GBR, DEU) for regulatory parameterization',
    PRODUCT_ID VARCHAR(50) COMMENT 'FK to LOAI_REF_TB_PRODUCT_CATALOGUE',
    REQUESTED_AMOUNT NUMBER(18,2) COMMENT 'Requested loan amount in local currency',
    REQUESTED_TERM_MONTHS INT COMMENT 'Requested loan term in months',
    REQUESTED_CURRENCY VARCHAR(3) COMMENT 'Currency code (CHF, GBP, EUR)',
    PURPOSE VARCHAR(100) COMMENT 'Loan purpose: PURCHASE, REFINANCE, HOME_IMPROVEMENT',
    ADVICE_VS_EXECUTION_ONLY VARCHAR(50) COMMENT 'Advised sale vs execution-only (MCD requirement)',
    BROKER_ID VARCHAR(50) COMMENT 'Broker ID if application via intermediary',
    STATUS VARCHAR(50) COMMENT 'Application status: SUBMITTED, APPROVED, DECLINED, WITHDRAWN, DISBURSED',
    CREATED_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp',
    UPDATED_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Last update timestamp'
)
COMMENT = 'Loan applications master table. Populated from DocAI-extracted email data. Contains all mortgage and unsecured loan applications with status tracking and regulatory compliance attributes.';

-- Table: Property Collateral Master
CREATE OR REPLACE TABLE LOAA_AGG_TB_COLLATERAL (
    COLLATERAL_ID VARCHAR(50) PRIMARY KEY COMMENT 'Unique collateral identifier (COLL_*)',
    PROPERTY_IDENTIFIER VARCHAR(100) COMMENT 'External property reference (land registry, tax ID)',
    PROPERTY_ADDRESS VARCHAR(500) COMMENT 'Full property address including postal code',
    PROPERTY_TYPE VARCHAR(50) COMMENT 'Property type: SINGLE_FAMILY, MULTI_FAMILY, APARTMENT, CONDO, TOWNHOUSE',
    OCCUPANCY_TYPE VARCHAR(50) COMMENT 'Occupancy type: OWNER_OCCUPIED, BUY_TO_LET, INVESTMENT',
    CONSTRUCTION_YEAR INT COMMENT 'Year property was built',
    ENERGY_PERFORMANCE_RATING VARCHAR(10) COMMENT 'EPC rating (A-G for UK, similar for EU)',
    VALUATION_VALUE NUMBER(18,2) NOT NULL COMMENT 'Current property valuation in local currency',
    VALUATION_DATE DATE NOT NULL COMMENT 'Date of valuation',
    VALUATION_METHOD VARCHAR(50) COMMENT 'Valuation method: AVM, FULL_APPRAISAL, DRIVE_BY, DESKTOP',
    VALUATION_PROVIDER VARCHAR(200) COMMENT 'Valuation provider name (for audit trail)',
    CREATED_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp'
)
COMMENT = 'Property collateral master table. Contains valuation, property characteristics, and ESG attributes (energy ratings) for mortgage lending.';

-- Table: Loan-to-Collateral Link (M:M Relationship)
CREATE OR REPLACE TABLE LOAA_AGG_TB_LOAN_COLLATERAL_LINK (
    LINK_ID VARCHAR(50) PRIMARY KEY COMMENT 'Unique link identifier (LINK_*)',
    ACCOUNT_ID VARCHAR(50) NOT NULL COMMENT 'FK to loan account (using APPLICATION_ID for showcase)',
    COLLATERAL_ID VARCHAR(50) NOT NULL COMMENT 'FK to LOAA_AGG_TB_COLLATERAL',
    EFFECTIVE_FROM_DATE DATE NOT NULL COMMENT 'Date when collateral link became effective',
    EFFECTIVE_TO_DATE DATE COMMENT 'Date when collateral link ended (NULL = active)',
    CHARGE_RANK VARCHAR(10) COMMENT 'Charge rank: 1ST, 2ND, 3RD (legal priority)',
    CHARGE_AMOUNT NUMBER(18,2) COMMENT 'Amount of charge secured against this collateral',
    COLLATERAL_ALLOCATION_PCT NUMBER(5,2) COMMENT 'Percentage of collateral allocated to this loan (for M:M scenarios)',
    REGISTRATION_STATUS VARCHAR(50) COMMENT 'Legal registration status: REGISTERED, PENDING, CANCELLED',
    CREATED_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'Record creation timestamp'
)
COMMENT = 'Loan-to-collateral M:M mapping table. Supports cross-collateralization and second charges. Showcase uses simple 1:1 relationships (all 1ST charge, 100% allocation).';

-- Table: Affordability Assessments
CREATE OR REPLACE TABLE LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS (
    AFFORDABILITY_ID VARCHAR(50) PRIMARY KEY COMMENT 'Unique affordability assessment ID (AFF_*)',
    APPLICATION_ID VARCHAR(50) NOT NULL COMMENT 'FK to LOAA_AGG_TB_APPLICATIONS',
    CUSTOMER_ID VARCHAR(30) COMMENT 'FK to CRMA_AGG_DT_CUSTOMER_360',
    GROSS_INCOME_MONTHLY NUMBER(18,2) COMMENT 'Gross monthly income before taxes',
    NET_INCOME_MONTHLY NUMBER(18,2) COMMENT 'Net monthly income after taxes',
    FIXED_INCOME_MONTHLY NUMBER(18,2) COMMENT 'Fixed income component (salary, pension)',
    VARIABLE_INCOME_MONTHLY NUMBER(18,2) COMMENT 'Variable income component (bonus, commission, rental)',
    RENTAL_INCOME_MONTHLY NUMBER(18,2) COMMENT 'Rental income from other properties (if applicable)',
    LIVING_EXPENSES_MONTHLY NUMBER(18,2) COMMENT 'Committed living expenses',
    TOTAL_DEBT_OBLIGATIONS_MONTHLY NUMBER(18,2) COMMENT 'Total existing monthly debt obligations',
    DTI_RATIO NUMBER(5,3) COMMENT 'Debt-to-Income ratio: Existing debts / Gross income',
    DSTI_RATIO NUMBER(5,3) COMMENT 'Debt Service-to-Income ratio: (Loan payment + Existing debts) / Gross income',
    AFFORDABILITY_RESULT VARCHAR(20) NOT NULL COMMENT 'Affordability result: PASS, FAIL, MARGINAL',
    AFFORDABILITY_REASON_CODES VARCHAR(500) COMMENT 'Comma-separated reason codes for FAIL results',
    INTEREST_RATE_STRESS_APPLIED_PCT NUMBER(5,4) COMMENT 'Stress test interest rate applied (e.g., 5% for CHE, 7% for UK)',
    STRESSED_PAYMENT_MONTHLY NUMBER(18,2) COMMENT 'Monthly payment calculated at stressed interest rate',
    MODEL_EXPLAINABILITY_TOP_FACTORS VARCHAR(1000) COMMENT 'Top 3-5 factors contributing to decision (SHAP/LIME concept)',
    CALCULATION_TIMESTAMP_UTC TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP() COMMENT 'When affordability was calculated'
)
COMMENT = 'Affordability assessment snapshots for loan applications. Contains DTI/DSTI calculations with country-specific thresholds (CHE: 33%, UK: 45%, DE: 40%) and stress testing per regulatory requirements.';

-- ============================================================
-- QUERY OPTIMIZATION NOTES
-- ============================================================
-- 
-- Snowflake uses automatic micro-partitioning and does not support traditional indexes.
-- Instead, Snowflake automatically clusters data based on query patterns.
--
-- For large-scale production deployments, consider:
-- 
-- 1. CLUSTER BY on frequently filtered columns:
--    ALTER TABLE LOAA_AGG_TB_APPLICATIONS CLUSTER BY (CUSTOMER_ID, APPLICATION_DATE_TIME);
--    ALTER TABLE LOAA_AGG_TB_COLLATERAL CLUSTER BY (PROPERTY_TYPE);
--
-- 2. Search Optimization Service for point lookups:
--    ALTER TABLE LOAA_AGG_TB_APPLICATIONS ADD SEARCH OPTIMIZATION ON EQUALITY(APPLICATION_ID, CUSTOMER_ID);
--
-- 3. Materialized Views for complex joins (if needed):
--    CREATE MATERIALIZED VIEW for frequently joined application + collateral + affordability queries
--
-- For this showcase (< 200 records per table), automatic micro-partitioning is sufficient.
--
-- ============================================================

-- ============================================================
-- DATA POPULATION FROM DOCAI EXTRACTION
-- ============================================================
--
-- This section populates the core loan tables from DocAI-extracted
-- and flattened email data in LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT
--
-- Data Flow:
-- 1. RAW: Emails → AI_EXTRACT → LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT
-- 2. AGG: Flattened data → Business entities (this section)
--
-- Prerequisites:
-- - structure/065_LOAI_loans_documents.sql deployed
-- - Emails uploaded and extracted successfully
-- - LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT populated
--
-- ============================================================

-- STEP 1: Populate APPLICATIONS table
-- ============================================================

INSERT INTO LOAA_AGG_TB_APPLICATIONS (
    APPLICATION_ID,
    CUSTOMER_ID,
    APPLICATION_DATE_TIME,
    CHANNEL,
    COUNTRY,
    PRODUCT_ID,
    REQUESTED_AMOUNT,
    REQUESTED_TERM_MONTHS,
    REQUESTED_CURRENCY,
    PURPOSE,
    STATUS,
    CREATED_TIMESTAMP_UTC
)
SELECT 
    'APP_' || REPLACE(e.FILE_NAME, '_internal.txt', '') as APPLICATION_ID,
    
    -- FK lookup to Customer 360 by fuzzy name matching
    c.CUSTOMER_ID,
    
    e.FILE_TIMESTAMP as APPLICATION_DATE_TIME,
    'EMAIL' as CHANNEL,
    
    -- Map country name to country code
    CASE 
        WHEN e.COUNTRY IN ('Switzerland', 'Swiss', 'CHE') THEN 'CHE'
        WHEN e.COUNTRY IN ('UK', 'United Kingdom', 'GBR', 'Britain') THEN 'GBR'
        WHEN e.COUNTRY IN ('Germany', 'DEU', 'Deutschland') THEN 'DEU'
        WHEN e.COUNTRY IN ('France', 'FRA') THEN 'FRA'
        WHEN e.COUNTRY IN ('Portugal', 'PRT') THEN 'PRT'
        WHEN e.COUNTRY IN ('Italy', 'ITA') THEN 'ITA'
        WHEN e.COUNTRY IN ('Spain', 'ESP') THEN 'ESP'
        ELSE 'CHE'  -- Default to Switzerland
    END as COUNTRY,
    
    -- FK lookup to Product Catalogue (from LEFT JOIN)
    p.PRODUCT_ID,
    
    e.LOAN_AMOUNT as REQUESTED_AMOUNT,
    e.LOAN_TERM_YEARS * 12 as REQUESTED_TERM_MONTHS,
    
    -- Map country to currency
    CASE 
        WHEN e.COUNTRY IN ('Switzerland', 'Swiss', 'CHE') THEN 'CHF'
        WHEN e.COUNTRY IN ('UK', 'United Kingdom', 'GBR', 'Britain') THEN 'GBP'
        WHEN e.COUNTRY IN ('Germany', 'DEU', 'France', 'FRA', 'Italy', 'ITA', 'Spain', 'ESP', 'Portugal', 'PRT') THEN 'EUR'
        ELSE 'CHF'
    END as REQUESTED_CURRENCY,
    
    'PURCHASE_PRIMARY_RESIDENCE' as PURPOSE,
    
    -- Set status based on LTV and credit score
    CASE 
        WHEN e.LTV_RATIO_PCT > 90 OR e.CREDIT_SCORE < 600 THEN 'DECLINED'
        WHEN e.LTV_RATIO_PCT > 85 OR e.CREDIT_SCORE < 650 THEN 'UNDER_REVIEW'
        WHEN e.DTI_RATIO_PCT > 45 THEN 'UNDER_REVIEW'
        ELSE 'APPROVED'
    END as STATUS,
    
    CURRENT_TIMESTAMP() as CREATED_TIMESTAMP_UTC

FROM LOA_RAW_001.LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT e

-- Fuzzy match to Customer 360 by name
LEFT JOIN CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 c 
    ON UPPER(TRIM(c.FULL_NAME)) = UPPER(TRIM(e.CUSTOMER_NAME))
    OR UPPER(TRIM(c.FIRST_NAME || ' ' || c.FAMILY_NAME)) = UPPER(TRIM(e.CUSTOMER_NAME))

-- Join to Product Catalogue by country and product type
LEFT JOIN LOA_RAW_001.LOAI_REF_TB_PRODUCT_CATALOGUE p
    ON p.PRODUCT_TYPE = 'MORTGAGE'
    AND p.COUNTRY = CASE 
        WHEN e.COUNTRY IN ('Switzerland', 'Swiss', 'CHE') THEN 'CHE'
        WHEN e.COUNTRY IN ('UK', 'United Kingdom', 'GBR') THEN 'GBR'
        WHEN e.COUNTRY IN ('Germany', 'DEU') THEN 'DEU'
        ELSE 'CHE'
    END
    AND p.IS_ACTIVE = TRUE

WHERE e.EXTRACTION_SUCCESS = TRUE
  AND e.LOAN_AMOUNT IS NOT NULL
  AND e.LOAN_AMOUNT > 0
  -- Idempotency: skip already inserted
  AND NOT EXISTS (
      SELECT 1 FROM LOAA_AGG_TB_APPLICATIONS a 
      WHERE a.APPLICATION_ID = 'APP_' || REPLACE(e.FILE_NAME, '_internal.txt', '')
  )
-- Ensure only one product per application (in case multiple products match)
QUALIFY ROW_NUMBER() OVER (PARTITION BY e.FILE_NAME ORDER BY p.PRODUCT_ID) = 1;

-- Show results
SELECT COUNT(*) as APPLICATIONS_INSERTED FROM LOAA_AGG_TB_APPLICATIONS;

-- ============================================================
-- STEP 2: Populate COLLATERAL table (properties)
-- ============================================================

INSERT INTO LOAA_AGG_TB_COLLATERAL (
    COLLATERAL_ID,
    PROPERTY_ADDRESS,
    PROPERTY_TYPE,
    OCCUPANCY_TYPE,
    VALUATION_VALUE,
    VALUATION_DATE,
    VALUATION_METHOD,
    CREATED_TIMESTAMP_UTC
)
SELECT 
    'COLL_' || REPLACE(e.FILE_NAME, '_internal.txt', '') as COLLATERAL_ID,
    
    e.PROPERTY_ADDRESS,
    
    COALESCE(e.PROPERTY_TYPE, 'Unknown') as PROPERTY_TYPE,
    
    'OWNER_OCCUPIED' as OCCUPANCY_TYPE,  -- Assume owner-occupied for showcase
    
    e.PURCHASE_PRICE as VALUATION_VALUE,
    
    e.FILE_TIMESTAMP::DATE as VALUATION_DATE,
    
    'AVM' as VALUATION_METHOD,  -- Automated Valuation Model
    
    CURRENT_TIMESTAMP() as CREATED_TIMESTAMP_UTC

FROM LOA_RAW_001.LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT e

WHERE e.EXTRACTION_SUCCESS = TRUE
  AND e.PROPERTY_ADDRESS IS NOT NULL
  AND e.PURCHASE_PRICE IS NOT NULL
  AND e.PURCHASE_PRICE > 0
  -- Idempotency: skip already inserted
  AND NOT EXISTS (
      SELECT 1 FROM LOAA_AGG_TB_COLLATERAL col
      WHERE col.COLLATERAL_ID = 'COLL_' || REPLACE(e.FILE_NAME, '_internal.txt', '')
  );

-- Show results
SELECT COUNT(*) as COLLATERAL_INSERTED FROM LOAA_AGG_TB_COLLATERAL;

-- ============================================================
-- STEP 3: Populate AFFORDABILITY_ASSESSMENTS table
-- ============================================================

INSERT INTO LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS (
    AFFORDABILITY_ID,
    APPLICATION_ID,
    CUSTOMER_ID,
    GROSS_INCOME_MONTHLY,
    TOTAL_DEBT_OBLIGATIONS_MONTHLY,
    DTI_RATIO,
    DSTI_RATIO,
    AFFORDABILITY_RESULT,
    AFFORDABILITY_REASON_CODES,
    INTEREST_RATE_STRESS_APPLIED_PCT,
    STRESSED_PAYMENT_MONTHLY,
    CALCULATION_TIMESTAMP_UTC
)
SELECT 
    'AFF_' || REPLACE(e.FILE_NAME, '_internal.txt', '') as AFFORDABILITY_ID,
    
    a.APPLICATION_ID,
    a.CUSTOMER_ID,
    
    e.MONTHLY_INCOME as GROSS_INCOME_MONTHLY,
    
    COALESCE(e.EXISTING_DEBTS_MONTHLY, 0) as TOTAL_DEBT_OBLIGATIONS_MONTHLY,
    
    -- DTI: Existing debts / Income
    ROUND(COALESCE(e.EXISTING_DEBTS_MONTHLY, 0) / NULLIF(e.MONTHLY_INCOME, 0), 3) as DTI_RATIO,
    
    -- DSTI: (Loan payment + Existing debts) / Income
    -- Simplified: (Loan / Term + Existing debts) / Income
    ROUND(
        ((e.LOAN_AMOUNT / NULLIF(e.LOAN_TERM_YEARS * 12, 0)) + COALESCE(e.EXISTING_DEBTS_MONTHLY, 0)) 
        / NULLIF(e.MONTHLY_INCOME, 0), 
        3
    ) as DSTI_RATIO,
    
    -- Affordability result based on DSTI thresholds per country
    CASE 
        WHEN ((e.LOAN_AMOUNT / NULLIF(e.LOAN_TERM_YEARS * 12, 0)) + COALESCE(e.EXISTING_DEBTS_MONTHLY, 0)) / NULLIF(e.MONTHLY_INCOME, 0) <= 
            CASE 
                WHEN a.COUNTRY = 'CHE' THEN 0.33  -- Swiss 33% threshold
                WHEN a.COUNTRY = 'GBR' THEN 0.45  -- UK 45% threshold
                WHEN a.COUNTRY = 'DEU' THEN 0.40  -- German 40% threshold
                ELSE 0.40
            END
        THEN 'PASS' 
        ELSE 'FAIL' 
    END as AFFORDABILITY_RESULT,
    
    -- Reason codes for failures
    CASE 
        WHEN ((e.LOAN_AMOUNT / NULLIF(e.LOAN_TERM_YEARS * 12, 0)) + COALESCE(e.EXISTING_DEBTS_MONTHLY, 0)) / NULLIF(e.MONTHLY_INCOME, 0) > 0.45
        THEN 'HIGH_DSTI_RATIO'
        WHEN e.CREDIT_SCORE < 650
        THEN 'LOW_CREDIT_SCORE'
        WHEN e.LTV_RATIO_PCT > 85
        THEN 'HIGH_LTV'
        ELSE NULL
    END as AFFORDABILITY_REASON_CODES,
    
    -- Stress test interest rate (5% for Switzerland, 7% for UK, 4.5% for Germany)
    CASE 
        WHEN a.COUNTRY = 'CHE' THEN 0.05
        WHEN a.COUNTRY = 'GBR' THEN 0.07
        WHEN a.COUNTRY = 'DEU' THEN 0.045
        ELSE 0.05
    END as INTEREST_RATE_STRESS_APPLIED_PCT,
    
    -- Stressed monthly payment using imputed rate
    ROUND(
        e.LOAN_AMOUNT * 
        (CASE WHEN a.COUNTRY = 'CHE' THEN 0.05 WHEN a.COUNTRY = 'GBR' THEN 0.07 ELSE 0.045 END / 12),
        2
    ) as STRESSED_PAYMENT_MONTHLY,
    
    CURRENT_TIMESTAMP() as CALCULATION_TIMESTAMP_UTC

FROM LOA_RAW_001.LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT e

-- Join to Applications to get APPLICATION_ID and CUSTOMER_ID
JOIN LOAA_AGG_TB_APPLICATIONS a 
    ON a.APPLICATION_ID = 'APP_' || REPLACE(e.FILE_NAME, '_internal.txt', '')

WHERE e.EXTRACTION_SUCCESS = TRUE
  AND e.MONTHLY_INCOME IS NOT NULL
  AND e.MONTHLY_INCOME > 0
  AND e.LOAN_AMOUNT IS NOT NULL
  -- Idempotency: skip already inserted
  AND NOT EXISTS (
      SELECT 1 FROM LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS aff
      WHERE aff.AFFORDABILITY_ID = 'AFF_' || REPLACE(e.FILE_NAME, '_internal.txt', '')
  );

-- Show results
SELECT COUNT(*) as AFFORDABILITY_ASSESSMENTS_INSERTED FROM LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS;

-- ============================================================
-- STEP 4: Populate LOAN_COLLATERAL_LINK table
-- ============================================================
-- Links applications to their collateral (1:1 for showcase)
-- In production, this would support M:M relationships

INSERT INTO LOAA_AGG_TB_LOAN_COLLATERAL_LINK (
    LINK_ID,
    ACCOUNT_ID,
    COLLATERAL_ID,
    EFFECTIVE_FROM_DATE,
    CHARGE_RANK,
    CHARGE_AMOUNT,
    COLLATERAL_ALLOCATION_PCT,
    REGISTRATION_STATUS,
    CREATED_TIMESTAMP_UTC
)
SELECT 
    'LINK_' || REPLACE(e.FILE_NAME, '_internal.txt', '') as LINK_ID,
    
    -- For showcase, use APPLICATION_ID as ACCOUNT_ID 
    -- (in production, applications would create separate loan accounts)
    'APP_' || REPLACE(e.FILE_NAME, '_internal.txt', '') as ACCOUNT_ID,
    
    'COLL_' || REPLACE(e.FILE_NAME, '_internal.txt', '') as COLLATERAL_ID,
    
    e.FILE_TIMESTAMP::DATE as EFFECTIVE_FROM_DATE,
    
    '1ST' as CHARGE_RANK,  -- All are first charge for showcase
    
    e.LOAN_AMOUNT as CHARGE_AMOUNT,
    
    100.00 as COLLATERAL_ALLOCATION_PCT,  -- 100% allocation (1:1 relationship)
    
    'REGISTERED' as REGISTRATION_STATUS,
    
    CURRENT_TIMESTAMP() as CREATED_TIMESTAMP_UTC

FROM LOA_RAW_001.LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT e

WHERE e.EXTRACTION_SUCCESS = TRUE
  AND e.LOAN_AMOUNT IS NOT NULL
  AND e.PROPERTY_ADDRESS IS NOT NULL
  -- Ensure both application and collateral exist
  AND EXISTS (
      SELECT 1 FROM LOAA_AGG_TB_APPLICATIONS a 
      WHERE a.APPLICATION_ID = 'APP_' || REPLACE(e.FILE_NAME, '_internal.txt', '')
  )
  AND EXISTS (
      SELECT 1 FROM LOAA_AGG_TB_COLLATERAL col
      WHERE col.COLLATERAL_ID = 'COLL_' || REPLACE(e.FILE_NAME, '_internal.txt', '')
  )
  -- Idempotency: skip already inserted
  AND NOT EXISTS (
      SELECT 1 FROM LOAA_AGG_TB_LOAN_COLLATERAL_LINK lnk
      WHERE lnk.LINK_ID = 'LINK_' || REPLACE(e.FILE_NAME, '_internal.txt', '')
  );

-- Show results
SELECT COUNT(*) as COLLATERAL_LINKS_INSERTED FROM LOAA_AGG_TB_LOAN_COLLATERAL_LINK;

-- ============================================================
-- VALIDATION QUERIES
-- ============================================================

SELECT '===========================================' as SECTION;
SELECT 'PHASE 2 POPULATION COMPLETE' as STATUS;
SELECT '===========================================' as SECTION;

-- Summary counts
SELECT 
    (SELECT COUNT(*) FROM LOA_RAW_001.LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT WHERE EXTRACTION_SUCCESS = TRUE) as EXTRACTED_EMAILS,
    (SELECT COUNT(*) FROM LOAA_AGG_TB_APPLICATIONS) as APPLICATIONS,
    (SELECT COUNT(*) FROM LOAA_AGG_TB_COLLATERAL) as COLLATERAL_PROPERTIES,
    (SELECT COUNT(*) FROM LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS) as AFFORDABILITY_ASSESSMENTS,
    (SELECT COUNT(*) FROM LOAA_AGG_TB_LOAN_COLLATERAL_LINK) as COLLATERAL_LINKS;

-- Applications by status
SELECT 
    STATUS,
    COUNT(*) as COUNT,
    ROUND(AVG(REQUESTED_AMOUNT), 0) as AVG_LOAN_AMOUNT,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as PCT_OF_TOTAL
FROM LOAA_AGG_TB_APPLICATIONS
GROUP BY STATUS
ORDER BY COUNT DESC;

-- Applications by country
SELECT 
    COUNTRY,
    COUNT(*) as COUNT,
    ROUND(AVG(REQUESTED_AMOUNT), 0) as AVG_LOAN_AMOUNT
FROM LOAA_AGG_TB_APPLICATIONS
GROUP BY COUNTRY
ORDER BY COUNT DESC;

-- Affordability results
SELECT 
    AFFORDABILITY_RESULT,
    COUNT(*) as COUNT,
    ROUND(AVG(DTI_RATIO) * 100, 1) as AVG_DTI_PCT,
    ROUND(AVG(DSTI_RATIO) * 100, 1) as AVG_DSTI_PCT
FROM LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS
GROUP BY AFFORDABILITY_RESULT;

-- LTV distribution
SELECT 
    CASE 
        WHEN e.LTV_RATIO_PCT <= 50 THEN '0-50%'
        WHEN e.LTV_RATIO_PCT <= 60 THEN '50-60%'
        WHEN e.LTV_RATIO_PCT <= 70 THEN '60-70%'
        WHEN e.LTV_RATIO_PCT <= 80 THEN '70-80%'
        WHEN e.LTV_RATIO_PCT <= 90 THEN '80-90%'
        ELSE '>90%'
    END as LTV_BUCKET,
    COUNT(*) as COUNT
FROM LOA_RAW_001.LOAI_RAW_TB_EMAIL_INBOUND_LOAN_EXTRACT_FLAT e
WHERE e.EXTRACTION_SUCCESS = TRUE
  AND e.LTV_RATIO_PCT IS NOT NULL
GROUP BY LTV_BUCKET
ORDER BY 
    CASE 
        WHEN LTV_BUCKET = '0-50%' THEN 1
        WHEN LTV_BUCKET = '50-60%' THEN 2
        WHEN LTV_BUCKET = '60-70%' THEN 3
        WHEN LTV_BUCKET = '70-80%' THEN 4
        WHEN LTV_BUCKET = '80-90%' THEN 5
        ELSE 6
    END;

-- Sample joined data (Applications → Collateral → Affordability)
SELECT 
    a.APPLICATION_ID,
    a.CUSTOMER_ID,
    a.REQUESTED_AMOUNT,
    a.STATUS,
    col.PROPERTY_TYPE,
    ROUND(col.VALUATION_VALUE, 0) as PROPERTY_VALUE,
    ROUND(a.REQUESTED_AMOUNT / col.VALUATION_VALUE * 100, 1) as LTV_PCT,
    aff.AFFORDABILITY_RESULT,
    ROUND(aff.DSTI_RATIO * 100, 1) as DSTI_PCT
FROM LOAA_AGG_TB_APPLICATIONS a
JOIN LOAA_AGG_TB_LOAN_COLLATERAL_LINK lnk ON a.APPLICATION_ID = lnk.ACCOUNT_ID
JOIN LOAA_AGG_TB_COLLATERAL col ON lnk.COLLATERAL_ID = col.COLLATERAL_ID
LEFT JOIN LOAA_AGG_TB_AFFORDABILITY_ASSESSMENTS aff ON a.APPLICATION_ID = aff.APPLICATION_ID
ORDER BY a.APPLICATION_DATE_TIME DESC
LIMIT 10;

SELECT '===========================================' as SECTION;
SELECT 'Ready for Phase 3: Aggregations & Dashboard' as NEXT_STEP;
SELECT '===========================================' as SECTION;

-- ============================================================
-- COMPLETION STATUS
-- ============================================================
-- ✅ Core Loan Business Entities Defined and Populated (LOA_AGG_001)
--
-- DEPLOYMENT:
-- • Deploy this file: snow sql -f structure/365_LOAA_loans_applications.sql
-- • This file creates tables AND populates them from DocAI extraction
-- • Run the entire file to complete Phase 2
--
-- OBJECTS CREATED:
-- • 4 Tables: Applications, Collateral, Link, Affordability
-- • Query optimization via Snowflake's automatic micro-partitioning
-- • Full population from DocAI-extracted email data
-- • Comprehensive validation queries
--
-- DATA RESULTS:
-- • ~120 applications (APPROVED, UNDER_REVIEW, DECLINED)
-- • ~80 collateral properties
-- • ~120 affordability assessments (DTI/DSTI calculations)
-- • ~80 collateral links (1:1 mapping for showcase)
--
-- NEXT PHASE:
-- • Phase 3: Create aggregation dynamic tables and dashboard
-- • File: structure/368_LOAA_loans_aggregations.sql
-- • Dashboard: notebooks/loan_portfolio_monitoring.ipynb
--
-- ============================================================
