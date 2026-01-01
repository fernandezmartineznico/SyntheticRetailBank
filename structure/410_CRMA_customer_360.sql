-- ============================================================
-- CRM_AGG_001 Schema - Customer & Address Aggregation with SCD Type 2 Views
-- Generated on: 2025-09-27 (Updated: 2025-10-26)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides aggregated views and Slowly Changing Dimension (SCD) Type 2
-- processing for customer master data and address data. It transforms the append-only 
-- base tables from CRM_RAW_001 into business-ready dimensional views with current
-- and historical tracking capabilities.
--
-- BUSINESS PURPOSE:
-- - Current customer attribute lookup for operational systems (account tier, employment, etc.)
-- - Current address lookup for correspondence and compliance
-- - Historical tracking of customer attribute changes (SCD Type 2)
-- - Historical address tracking for compliance and analytics
-- - Point-in-time queries for regulatory reporting
-- - Audit trails for customer service and compliance reviews
--
-- SCD TYPE 2 IMPLEMENTATION:
-- Both CRMI_RAW_TB_CUSTOMER and CRMI_RAW_TB_ADDRESSES use append-only structures where each
-- change creates a new record with INSERT_TIMESTAMP_UTC. Dynamic tables automatically
-- convert these into proper SCD Type 2 with VALID_FROM/VALID_TO ranges.
-- - CRMI_RAW_TB_CUSTOMER: Tracks changes to employment, account tier, contact info, risk profile
-- - CRMI_RAW_TB_ADDRESSES: Tracks address changes for compliance and correspondence
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (5):
-- │  ├─ CRMA_AGG_DT_ADDRESSES_CURRENT  - Latest address per customer (operational)
-- │  ├─ CRMA_AGG_DT_ADDRESSES_HISTORY  - Full SCD Type 2 address history (analytical)
-- │  ├─ CRMA_AGG_DT_CUSTOMER_CURRENT   - Latest customer attributes per customer (operational)
-- │  ├─ CRMA_AGG_DT_CUSTOMER_HISTORY   - Full SCD Type 2 customer attribute history (analytical)
-- │  └─ CRMA_AGG_DT_CUSTOMER_360       - Comprehensive 360° customer view with PEP/Sanctions matching
-- │
-- ├─ SHARED ANALYTICAL VIEWS (3):
-- │  ├─ CRMA_AGG_VW_CUSTOMER_RISK_PROFILE  - Consolidated risk segmentation metrics (used by 6 notebooks)
-- │  ├─ CRMA_AGG_VW_SCREENING_STATUS       - Combined PEP & sanctions screening status (used by 4 notebooks)
-- │  └─ CRMA_AGG_VW_SCREENING_ALERTS       - Pre-filtered alerts requiring investigation (alert dashboards)
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- DATA FLOW:
-- CRM_RAW_001.CRMI_RAW_TB_ADDRESSES (append-only base)
--     ↓
-- CRMA_AGG_DT_ADDRESSES_CURRENT (latest addresses)
--     ↓
-- CRMA_AGG_DT_ADDRESSES_HISTORY (full SCD Type 2)
--
-- CRM_RAW_001.CRMI_RAW_TB_CUSTOMER (append-only base with SCD Type 2)
--     ↓
-- CRMA_AGG_DT_CUSTOMER_CURRENT (latest customer attributes)
--     ↓
-- CRMA_AGG_DT_CUSTOMER_HISTORY (full SCD Type 2)
--
-- PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS (transaction data - direct join for transaction metrics)
--     ↓
-- PAY_AGG_001.PAYA_AGG_DT_ACCOUNT_BALANCES (account balances)
--     ↓
-- CRMA_AGG_DT_CUSTOMER_360 (comprehensive 360° view with balances, transaction metrics, PEP/Sanctions matching)
--
-- SUPPORTED COUNTRIES:
-- Norway, Netherlands, Sweden, Germany, France, Italy, United Kingdom,
-- Denmark, Belgium, Austria, Switzerland (12 EMEA countries)
--
-- RELATED SCHEMAS & DEPENDENCIES:
-- - CRM_RAW_001: Source customer and address master data (CRMI_RAW_TB_CUSTOMER, CRMI_RAW_TB_ADDRESSES, CRMI_RAW_TB_CUSTOMER_STATUS, CRMI_RAW_TB_EXPOSED_PERSON)
-- - CRM_AGG_001: Account aggregation (ACCA_AGG_DT_ACCOUNTS - for account counts and types)
-- - PAY_RAW_001: Payment transactions (PAYI_RAW_TB_TRANSACTIONS - direct join for transaction metrics)
-- - PAY_AGG_001: Account balances (PAYA_AGG_DT_ACCOUNT_BALANCES)
-- - External: Global Sanctions Data from Snowflake Data Exchange
-- - EQT_RAW_001: Equity trades (for tax reporting)
--
-- DEPLOYMENT ORDER:
-- 1. 030_PAYI_transactions.sql (raw transaction data)
-- 2. 311_ACCA_accounts_agg.sql (creates ACCA_AGG_DT_ACCOUNTS - account aggregation layer)
-- 3. 330_PAYA_anomaly_detection.sql (creates PAYA_AGG_DT_ACCOUNT_BALANCES)
-- 4. 410_CRMA_customer_360.sql (this file - depends on account aggregation, balances, and transactions)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- DYNAMIC TABLES - SCD Type 2 Address Processing
-- ============================================================
-- Dynamic tables that automatically maintain current and historical address views
-- from the append-only base table. These tables refresh every 5 minutes based on
-- source data changes, providing near real-time dimensional processing.


-- ============================================================
-- CRMA_AGG_DT_ADDRESSES_CURRENT - Current Address Lookup (Operational)
-- ============================================================
-- Operational view providing the most recent address for each customer.
-- Used by front-end applications, customer service, and real-time processing.
-- Optimized for fast lookups with one record per customer.


CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_ADDRESSES_CURRENT(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for address lookup (CUST_XXXXX format)',
    STREET_ADDRESS VARCHAR(200) COMMENT 'Current street address for customer correspondence',
    CITY VARCHAR(100) COMMENT 'Current city for customer location and compliance',
    STATE VARCHAR(100) COMMENT 'Current state/region for regulatory jurisdiction',
    ZIPCODE VARCHAR(20) COMMENT 'Current postal code for address validation',
    COUNTRY VARCHAR(50) COMMENT 'Current country for regulatory and tax purposes',
    CURRENT_FROM TIMESTAMP_NTZ COMMENT 'Date when this address became current/effective',
    IS_CURRENT BOOLEAN COMMENT 'Boolean flag indicating this is the current address (always TRUE)'
) COMMENT = 'Current/latest address for each customer. Operational view with one record per customer showing the most recent address based on INSERT_TIMESTAMP_UTC. Used for real-time customer lookups and front-end applications.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    CUSTOMER_ID,
    STREET_ADDRESS,
    CITY,
    STATE,
    ZIPCODE,
    COUNTRY,
    INSERT_TIMESTAMP_UTC AS CURRENT_FROM,
    TRUE AS IS_CURRENT
FROM (
    SELECT 
        CUSTOMER_ID,
        STREET_ADDRESS,
        CITY,
        STATE,
        ZIPCODE,
        COUNTRY,
        INSERT_TIMESTAMP_UTC,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC DESC) as rn
    FROM CRM_RAW_001.CRMI_RAW_TB_ADDRESSES
) ranked
WHERE rn = 1;

-- ============================================================
-- CRMA_AGG_DT_ADDRESSES_HISTORY - Address History SCD Type 2 (Analytical)
-- ============================================================
-- Analytical view providing complete SCD Type 2 address history with effective date ranges.
-- Used for compliance reporting, historical analysis, and point-in-time queries.
-- Includes VALID_FROM/VALID_TO ranges and IS_CURRENT flags for each address period.

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_ADDRESSES_HISTORY(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for address history tracking',
    STREET_ADDRESS VARCHAR(200) COMMENT 'Historical street address for compliance audit trail',
    CITY VARCHAR(100) COMMENT 'Historical city for location tracking and analysis',
    STATE VARCHAR(100) COMMENT 'Historical state/region for regulatory compliance',
    ZIPCODE VARCHAR(20) COMMENT 'Historical postal code for address validation',
    COUNTRY VARCHAR(50) COMMENT 'Historical country for regulatory and tax compliance',
    VALID_FROM DATE COMMENT 'Start date when this address was effective (SCD Type 2)',
    VALID_TO DATE COMMENT 'End date when this address was superseded (NULL if current)',
    IS_CURRENT BOOLEAN COMMENT 'Boolean flag indicating if this is the current address',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ COMMENT 'Original timestamp when address was recorded in system'
) COMMENT = 'SCD Type 2 address history with VALID_FROM/VALID_TO effective date ranges. Converts append-only base table into proper slowly changing dimension for compliance reporting, historical analysis, and point-in-time customer address queries.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    CUSTOMER_ID,
    STREET_ADDRESS,
    CITY,
    STATE,
    ZIPCODE,
    COUNTRY,
    INSERT_TIMESTAMP_UTC::DATE AS VALID_FROM,
    CASE 
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NOT NULL 
        THEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC)::DATE - 1
        ELSE NULL 
    END AS VALID_TO,
    CASE 
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NULL 
        THEN TRUE 
        ELSE FALSE 
    END AS IS_CURRENT,
    INSERT_TIMESTAMP_UTC
FROM CRM_RAW_001.CRMI_RAW_TB_ADDRESSES
ORDER BY CUSTOMER_ID, INSERT_TIMESTAMP_UTC;

-- ============================================================
-- CRMA_AGG_DT_CUSTOMER_CURRENT - Current Customer Attributes (Operational)
-- ============================================================
-- Operational view providing the most recent customer record with all attributes.
-- Used by front-end applications, customer service, and real-time processing.
-- Optimized for fast lookups with one record per customer.

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_CUSTOMER_CURRENT(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for lookup (CUST_XXXXX format)',
    FIRST_NAME VARCHAR(100) COMMENT 'Customer first name',
    FAMILY_NAME VARCHAR(100) COMMENT 'Customer family/last name',
    FULL_NAME VARCHAR(201) COMMENT 'Customer full name (First + Last)',
    DATE_OF_BIRTH DATE COMMENT 'Customer date of birth',
    ONBOARDING_DATE DATE COMMENT 'Date when customer relationship was established',
    REPORTING_CURRENCY VARCHAR(3) COMMENT 'Customer reporting currency',
    HAS_ANOMALY BOOLEAN COMMENT 'Flag for anomalous transaction patterns',
    EMPLOYER VARCHAR(200) COMMENT 'Current employer',
    POSITION VARCHAR(100) COMMENT 'Current job position/title',
    EMPLOYMENT_TYPE VARCHAR(30) COMMENT 'Current employment type',
    INCOME_RANGE VARCHAR(30) COMMENT 'Current income range bracket',
    ACCOUNT_TIER VARCHAR(30) COMMENT 'Current account tier',
    EMAIL VARCHAR(255) COMMENT 'Customer email address',
    PHONE VARCHAR(50) COMMENT 'Customer phone number',
    PREFERRED_CONTACT_METHOD VARCHAR(20) COMMENT 'Preferred contact method',
    RISK_CLASSIFICATION VARCHAR(20) COMMENT 'Risk classification',
    CREDIT_SCORE_BAND VARCHAR(20) COMMENT 'Credit score band',
    CURRENT_FROM TIMESTAMP_NTZ COMMENT 'Date when these attributes became current/effective',
    IS_CURRENT BOOLEAN COMMENT 'Boolean flag indicating this is the current record (always TRUE)'
) COMMENT = 'Current/latest customer attributes for each customer. Operational view with one record per customer showing the most recent state based on INSERT_TIMESTAMP_UTC. Used for real-time customer lookups and front-end applications.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    CONCAT(FIRST_NAME, ' ', FAMILY_NAME) AS FULL_NAME,
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
    INSERT_TIMESTAMP_UTC AS CURRENT_FROM,
    TRUE AS IS_CURRENT
FROM (
    SELECT 
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
        INSERT_TIMESTAMP_UTC,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC DESC) as rn
    FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER
) ranked
WHERE rn = 1;

-- ============================================================
-- CRMA_AGG_DT_CUSTOMER_HISTORY - Customer Attribute History SCD Type 2 (Analytical)
-- ============================================================
-- Analytical view providing complete SCD Type 2 customer attribute history with effective date ranges.
-- Used for compliance reporting, historical analysis, and point-in-time queries.
-- Includes VALID_FROM/VALID_TO ranges and IS_CURRENT flags for each attribute version.

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_CUSTOMER_HISTORY(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for history tracking',
    FIRST_NAME VARCHAR(100) COMMENT 'Customer first name (immutable)',
    FAMILY_NAME VARCHAR(100) COMMENT 'Customer family/last name (immutable)',
    FULL_NAME VARCHAR(201) COMMENT 'Customer full name',
    DATE_OF_BIRTH DATE COMMENT 'Customer date of birth (immutable)',
    ONBOARDING_DATE DATE COMMENT 'Customer onboarding date (immutable)',
    REPORTING_CURRENCY VARCHAR(3) COMMENT 'Customer reporting currency',
    HAS_ANOMALY BOOLEAN COMMENT 'Anomaly flag',
    EMPLOYER VARCHAR(200) COMMENT 'Historical employer',
    POSITION VARCHAR(100) COMMENT 'Historical job position',
    EMPLOYMENT_TYPE VARCHAR(30) COMMENT 'Historical employment type',
    INCOME_RANGE VARCHAR(30) COMMENT 'Historical income range',
    ACCOUNT_TIER VARCHAR(30) COMMENT 'Historical account tier',
    EMAIL VARCHAR(255) COMMENT 'Historical email address',
    PHONE VARCHAR(50) COMMENT 'Historical phone number',
    PREFERRED_CONTACT_METHOD VARCHAR(20) COMMENT 'Historical contact method',
    RISK_CLASSIFICATION VARCHAR(20) COMMENT 'Historical risk classification',
    CREDIT_SCORE_BAND VARCHAR(20) COMMENT 'Historical credit score band',
    VALID_FROM DATE COMMENT 'Start date when these attributes were effective (SCD Type 2)',
    VALID_TO DATE COMMENT 'End date when these attributes were superseded (NULL if current)',
    IS_CURRENT BOOLEAN COMMENT 'Boolean flag indicating if this is the current record',
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ COMMENT 'Original timestamp when this version was recorded in system'
) COMMENT = 'SCD Type 2 customer attribute history with VALID_FROM/VALID_TO effective date ranges. Tracks changes to mutable attributes (employment, account tier, contact info) over time. Used for compliance reporting, historical analysis, and point-in-time customer attribute queries.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    CONCAT(FIRST_NAME, ' ', FAMILY_NAME) AS FULL_NAME,
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
    INSERT_TIMESTAMP_UTC::DATE AS VALID_FROM,
    CASE 
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NOT NULL 
        THEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC)::DATE - 1
        ELSE NULL 
    END AS VALID_TO,
    CASE 
        WHEN LEAD(INSERT_TIMESTAMP_UTC) OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC) IS NULL 
        THEN TRUE 
        ELSE FALSE 
    END AS IS_CURRENT,
    INSERT_TIMESTAMP_UTC
FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER
ORDER BY CUSTOMER_ID, INSERT_TIMESTAMP_UTC;

-- ============================================================
-- CRMA_AGG_DT_CUSTOMER_360 - Comprehensive Customer View with PEP Matching & Accuracy Scoring
-- ============================================================
-- 360-degree customer view combining master data, current address, current status,
-- accounts, Exposed Person compliance fuzzy matching, and Global Sanctions Data 
-- fuzzy matching with accuracy percentage scoring. Used for comprehensive customer 
-- analysis, compliance screening, and risk assessment across all customer touchpoints 
-- with quantified match confidence levels for both PEP and sanctions screening.

-- Drop existing dynamic table first to ensure clean recreation after structural changes
DROP DYNAMIC TABLE IF EXISTS CRMA_AGG_DT_CUSTOMER_360;

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_CUSTOMER_360(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Unique customer identifier for relationship management',
    FIRST_NAME VARCHAR(100) COMMENT 'Customer first name for identification and compliance',
    FAMILY_NAME VARCHAR(100) COMMENT 'Customer family/last name for identification and compliance',
    FULL_NAME VARCHAR(201) COMMENT 'Customer full name (First + Last) for reporting',
    DATE_OF_BIRTH DATE COMMENT 'Customer date of birth for identity verification',
    ONBOARDING_DATE DATE COMMENT 'Date when customer relationship was established',
    REPORTING_CURRENCY VARCHAR(3) COMMENT 'Customer reporting currency based on country',
    HAS_ANOMALY BOOLEAN COMMENT 'Flag indicating if customer has anomalous transaction patterns',
    EMPLOYER VARCHAR(200) COMMENT 'Current employer name',
    POSITION VARCHAR(100) COMMENT 'Current job position/title',
    EMPLOYMENT_TYPE VARCHAR(30) COMMENT 'Current employment type',
    INCOME_RANGE VARCHAR(30) COMMENT 'Current income range bracket',
    ACCOUNT_TIER VARCHAR(30) COMMENT 'Current account tier',
    EMAIL VARCHAR(255) COMMENT 'Customer email address',
    PHONE VARCHAR(50) COMMENT 'Customer phone number',
    PREFERRED_CONTACT_METHOD VARCHAR(20) COMMENT 'Preferred contact method',
    RISK_CLASSIFICATION VARCHAR(20) COMMENT 'Risk classification',
    CREDIT_SCORE_BAND VARCHAR(20) COMMENT 'Credit score band',
    STREET_ADDRESS VARCHAR(200) COMMENT 'Current street address for correspondence',
    CITY VARCHAR(100) COMMENT 'Current city for location and regulatory purposes',
    STATE VARCHAR(100) COMMENT 'Current state/region for jurisdiction and compliance',
    ZIPCODE VARCHAR(20) COMMENT 'Current postal code for address validation',
    COUNTRY VARCHAR(50) COMMENT 'Current country for regulatory and tax purposes',
    ADDRESS_EFFECTIVE_DATE TIMESTAMP_NTZ COMMENT 'Date when current address became effective',
    CURRENT_STATUS VARCHAR(30) COMMENT 'Current customer status (ACTIVE/DORMANT/CLOSED/SUSPENDED/etc.)',
    STATUS_EFFECTIVE_DATE DATE COMMENT 'Date when current status became effective',
    TOTAL_ACCOUNTS NUMBER(10,0) COMMENT 'Total number of accounts held by customer',
    ACCOUNT_TYPES VARCHAR(200) COMMENT 'Comma-separated list of account types held',
    CURRENCIES VARCHAR(50) COMMENT 'Comma-separated list of currencies used by customer',
    CHECKING_ACCOUNTS NUMBER(10,0) COMMENT 'Number of checking accounts held',
    SAVINGS_ACCOUNTS NUMBER(10,0) COMMENT 'Number of savings accounts held',
    BUSINESS_ACCOUNTS NUMBER(10,0) COMMENT 'Number of business accounts held',
    INVESTMENT_ACCOUNTS NUMBER(10,0) COMMENT 'Number of investment accounts held',
    
    -- Balance Metrics (Phase 1 Enhancement - 2025-12-19)
    TOTAL_BALANCE NUMBER(18,2) COMMENT 'Sum of all account balances in reporting currency for AUM tracking and advisor performance',
    BALANCE_AS_OF_DATE DATE COMMENT 'Date when balance was calculated (most recent account update)',
    CHECKING_BALANCE NUMBER(18,2) COMMENT 'Total balance in checking accounts',
    SAVINGS_BALANCE NUMBER(18,2) COMMENT 'Total balance in savings accounts',
    BUSINESS_BALANCE NUMBER(18,2) COMMENT 'Total balance in business accounts',
    INVESTMENT_BALANCE NUMBER(18,2) COMMENT 'Total balance in investment accounts',
    MAX_ACCOUNT_BALANCE NUMBER(18,2) COMMENT 'Largest account balance for key account identification',
    MIN_ACCOUNT_BALANCE NUMBER(18,2) COMMENT 'Smallest account balance for minimum balance policy enforcement',
    AVG_ACCOUNT_BALANCE NUMBER(18,2) COMMENT 'Average balance per account for relationship depth measurement',
    
    -- Transaction Activity Metrics (Phase 2 Enhancement - 2025-12-19)
    TOTAL_TRANSACTIONS NUMBER(10,0) COMMENT 'Count of all transactions in last 12 months for engagement scoring and advisor performance',
    TOTAL_TRANSACTIONS_ALL_TIME NUMBER(10,0) COMMENT 'Lifetime transaction count since onboarding for relationship maturity',
    LAST_TRANSACTION_DATE DATE COMMENT 'Most recent transaction date for dormancy detection and churn prediction',
    DAYS_SINCE_LAST_TRANSACTION NUMBER(10,0) COMMENT 'Days since last activity (churn indicator for proactive retention)',
    DEBIT_TRANSACTIONS NUMBER(10,0) COMMENT 'Number of debit transactions for spending pattern analysis',
    CREDIT_TRANSACTIONS NUMBER(10,0) COMMENT 'Number of credit transactions for income deposit tracking',
    AVG_MONTHLY_TRANSACTIONS NUMBER(10,2) COMMENT 'Average transactions per month for engagement trend analysis',
    IS_DORMANT_TRANSACTIONALLY BOOLEAN COMMENT 'TRUE if no transactions in 180+ days (fraud risk + churn risk)',
    IS_HIGHLY_ACTIVE BOOLEAN COMMENT 'TRUE if >50 transactions in last month (high engagement)',
    
    EXPOSED_PERSON_EXACT_MATCH_ID VARCHAR(50) COMMENT 'PEP ID for exact name match (compliance)',
    EXPOSED_PERSON_EXACT_MATCH_NAME VARCHAR(200) COMMENT 'PEP name for exact match (compliance)',
    EXPOSED_PERSON_EXACT_CATEGORY VARCHAR(50) COMMENT 'PEP category for exact match (DOMESTIC/FOREIGN/etc.)',
    EXPOSED_PERSON_EXACT_RISK_LEVEL VARCHAR(20) COMMENT 'PEP risk level for exact match (CRITICAL/HIGH/MEDIUM/LOW)',
    EXPOSED_PERSON_EXACT_STATUS VARCHAR(20) COMMENT 'PEP status for exact match (ACTIVE/INACTIVE)',
    EXPOSED_PERSON_FUZZY_MATCH_ID VARCHAR(50) COMMENT 'PEP ID for fuzzy name match (compliance)',
    EXPOSED_PERSON_FUZZY_MATCH_NAME VARCHAR(200) COMMENT 'PEP name for fuzzy match (compliance)',
    EXPOSED_PERSON_FUZZY_CATEGORY VARCHAR(50) COMMENT 'PEP category for fuzzy match (DOMESTIC/FOREIGN/etc.)',
    EXPOSED_PERSON_FUZZY_RISK_LEVEL VARCHAR(20) COMMENT 'PEP risk level for fuzzy match (CRITICAL/HIGH/MEDIUM/LOW)',
    EXPOSED_PERSON_FUZZY_STATUS VARCHAR(20) COMMENT 'PEP status for fuzzy match (ACTIVE/INACTIVE)',
    EXPOSED_PERSON_MATCH_ACCURACY_PERCENT NUMBER(5,2) COMMENT 'PEP match accuracy percentage (70-100% for fuzzy, 100% for exact)',
    EXPOSED_PERSON_MATCH_TYPE VARCHAR(15) COMMENT 'Type of PEP match (EXACT_MATCH/FUZZY_MATCH/NO_MATCH)',
    SANCTIONS_EXACT_MATCH_ID VARCHAR(50) COMMENT 'Sanctions ID for exact name match against global sanctions data',
    SANCTIONS_EXACT_MATCH_NAME VARCHAR(200) COMMENT 'Sanctions name for exact match against global sanctions data',
    SANCTIONS_EXACT_MATCH_TYPE VARCHAR(20) COMMENT 'Sanctions match type (INDIVIDUAL/ENTITY) for exact match',
    SANCTIONS_EXACT_MATCH_COUNTRY VARCHAR(50) COMMENT 'Sanctions country for exact match',
    SANCTIONS_FUZZY_MATCH_ID VARCHAR(50) COMMENT 'Sanctions ID for fuzzy name match against global sanctions data',
    SANCTIONS_FUZZY_MATCH_NAME VARCHAR(200) COMMENT 'Sanctions name for fuzzy match against global sanctions data',
    SANCTIONS_FUZZY_MATCH_TYPE VARCHAR(20) COMMENT 'Sanctions match type (INDIVIDUAL/ENTITY) for fuzzy match',
    SANCTIONS_FUZZY_MATCH_COUNTRY VARCHAR(50) COMMENT 'Sanctions country for fuzzy match',
    SANCTIONS_MATCH_ACCURACY_PERCENT NUMBER(5,2) COMMENT 'Sanctions match accuracy percentage (70-100% for fuzzy, 100% for exact)',
    SANCTIONS_MATCH_TYPE VARCHAR(15) COMMENT 'Type of sanctions match (EXACT_MATCH/FUZZY_MATCH/NO_MATCH)',
    OVERALL_EXPOSED_PERSON_RISK VARCHAR(30) COMMENT 'Overall PEP risk assessment (CRITICAL/HIGH/MEDIUM/LOW/NO_EXPOSED_PERSON_RISK)',
    OVERALL_SANCTIONS_RISK VARCHAR(30) COMMENT 'Overall sanctions risk assessment (CRITICAL/HIGH/MEDIUM/LOW/NO_SANCTIONS_RISK)',
    OVERALL_RISK_RATING VARCHAR(20) COMMENT 'Comprehensive risk rating combining PEP, sanctions, and anomalies (CRITICAL/HIGH/MEDIUM/LOW/NO_RISK)',
    OVERALL_RISK_SCORE NUMBER(5,2) COMMENT 'Numerical risk score (0-100) combining all risk factors',
    REQUIRES_EXPOSED_PERSON_REVIEW BOOLEAN COMMENT 'Boolean flag indicating if customer requires PEP compliance review',
    REQUIRES_SANCTIONS_REVIEW BOOLEAN COMMENT 'Boolean flag indicating if customer requires sanctions compliance review',
    HIGH_RISK_CUSTOMER BOOLEAN COMMENT 'Boolean flag for customers with both anomalies and PEP/sanctions matches',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when customer record was last updated'
) COMMENT = 'Comprehensive 360-degree customer view with master data, current address, current status, account summary with balances (Phase 1), transaction activity metrics via direct cross-schema join (Phase 2 - Option A), Exposed Person fuzzy matching, and Global Sanctions Data fuzzy matching with accuracy scoring. Enables AUM tracking, advisor performance measurement, engagement scoring, churn prediction, and comprehensive compliance screening for holistic customer risk assessment and relationship management.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Customer Master Data
    c.CUSTOMER_ID,
    c.FIRST_NAME,
    c.FAMILY_NAME,
    c.FULL_NAME,
    c.DATE_OF_BIRTH,
    c.ONBOARDING_DATE,
    c.REPORTING_CURRENCY,
    c.HAS_ANOMALY,
    
    -- Customer Extended Attributes
    c.EMPLOYER,
    c.POSITION,
    c.EMPLOYMENT_TYPE,
    c.INCOME_RANGE,
    c.ACCOUNT_TIER,
    c.EMAIL,
    c.PHONE,
    c.PREFERRED_CONTACT_METHOD,
    c.RISK_CLASSIFICATION,
    c.CREDIT_SCORE_BAND,
    
    -- Current Address Information
    addr.STREET_ADDRESS,
    addr.CITY,
    addr.STATE,
    addr.ZIPCODE,
    addr.COUNTRY,
    addr.CURRENT_FROM AS ADDRESS_EFFECTIVE_DATE,
    
    -- Current Status Information
    status.STATUS AS CURRENT_STATUS,
    status.STATUS_START_DATE AS STATUS_EFFECTIVE_DATE,
    
    -- Account Summary
    COUNT(acc.ACCOUNT_ID) AS TOTAL_ACCOUNTS,
    LISTAGG(DISTINCT acc.ACCOUNT_TYPE, ', ') WITHIN GROUP (ORDER BY acc.ACCOUNT_TYPE) AS ACCOUNT_TYPES,
    LISTAGG(DISTINCT acc.BASE_CURRENCY, ', ') WITHIN GROUP (ORDER BY acc.BASE_CURRENCY) AS CURRENCIES,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'CHECKING' THEN 1 END) AS CHECKING_ACCOUNTS,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'SAVINGS' THEN 1 END) AS SAVINGS_ACCOUNTS,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'BUSINESS' THEN 1 END) AS BUSINESS_ACCOUNTS,
    COUNT(CASE WHEN acc.ACCOUNT_TYPE = 'INVESTMENT' THEN 1 END) AS INVESTMENT_ACCOUNTS,
    
    -- Balance Metrics (Phase 1 Enhancement)
    COALESCE(SUM(bal.CURRENT_BALANCE_BASE), 0) AS TOTAL_BALANCE,
    MAX(bal.LAST_TRANSACTION_DATE) AS BALANCE_AS_OF_DATE,
    COALESCE(SUM(CASE WHEN bal.ACCOUNT_TYPE = 'CHECKING' THEN bal.CURRENT_BALANCE_BASE ELSE 0 END), 0) AS CHECKING_BALANCE,
    COALESCE(SUM(CASE WHEN bal.ACCOUNT_TYPE = 'SAVINGS' THEN bal.CURRENT_BALANCE_BASE ELSE 0 END), 0) AS SAVINGS_BALANCE,
    COALESCE(SUM(CASE WHEN bal.ACCOUNT_TYPE = 'BUSINESS' THEN bal.CURRENT_BALANCE_BASE ELSE 0 END), 0) AS BUSINESS_BALANCE,
    COALESCE(SUM(CASE WHEN bal.ACCOUNT_TYPE = 'INVESTMENT' THEN bal.CURRENT_BALANCE_BASE ELSE 0 END), 0) AS INVESTMENT_BALANCE,
    COALESCE(MAX(bal.CURRENT_BALANCE_BASE), 0) AS MAX_ACCOUNT_BALANCE,
    COALESCE(MIN(bal.CURRENT_BALANCE_BASE), 0) AS MIN_ACCOUNT_BALANCE,
    COALESCE(AVG(bal.CURRENT_BALANCE_BASE), 0) AS AVG_ACCOUNT_BALANCE,
    
    -- Transaction Activity Metrics (Phase 2 Enhancement - Option A: Direct Cross-Schema Join)
    COUNT(CASE 
        WHEN txn.VALUE_DATE >= DATEADD(month, -12, CURRENT_DATE()) 
        THEN txn.TRANSACTION_ID 
    END) AS TOTAL_TRANSACTIONS,
    COUNT(txn.TRANSACTION_ID) AS TOTAL_TRANSACTIONS_ALL_TIME,
    MAX(txn.VALUE_DATE) AS LAST_TRANSACTION_DATE,
    COALESCE(DATEDIFF(day, MAX(txn.VALUE_DATE), CURRENT_DATE()), 9999) AS DAYS_SINCE_LAST_TRANSACTION,
    COUNT(CASE 
        WHEN txn.AMOUNT < 0 AND txn.VALUE_DATE >= DATEADD(month, -12, CURRENT_DATE())
        THEN txn.TRANSACTION_ID 
    END) AS DEBIT_TRANSACTIONS,
    COUNT(CASE 
        WHEN txn.AMOUNT > 0 AND txn.VALUE_DATE >= DATEADD(month, -12, CURRENT_DATE())
        THEN txn.TRANSACTION_ID 
    END) AS CREDIT_TRANSACTIONS,
    COUNT(CASE 
        WHEN txn.VALUE_DATE >= DATEADD(month, -12, CURRENT_DATE()) 
        THEN txn.TRANSACTION_ID 
    END) / 12.0 AS AVG_MONTHLY_TRANSACTIONS,
    CASE 
        WHEN COALESCE(DATEDIFF(day, MAX(txn.VALUE_DATE), CURRENT_DATE()), 9999) >= 180 
        THEN TRUE 
        ELSE FALSE 
    END AS IS_DORMANT_TRANSACTIONALLY,
    CASE 
        WHEN COUNT(CASE 
            WHEN txn.VALUE_DATE >= DATEADD(month, -1, CURRENT_DATE()) 
            THEN txn.TRANSACTION_ID 
        END) > 50 
        THEN TRUE 
        ELSE FALSE 
    END AS IS_HIGHLY_ACTIVE,
    
    -- PEP Compliance Fuzzy Matching
    -- Exact name match
    pep_exact.EXPOSED_PERSON_ID AS EXPOSED_PERSON_EXACT_MATCH_ID,
    pep_exact.FULL_NAME AS EXPOSED_PERSON_EXACT_MATCH_NAME,
    pep_exact.EXPOSED_PERSON_CATEGORY AS EXPOSED_PERSON_EXACT_CATEGORY,
    pep_exact.RISK_LEVEL AS EXPOSED_PERSON_EXACT_RISK_LEVEL,
    pep_exact.STATUS AS EXPOSED_PERSON_EXACT_STATUS,
    
    -- Fuzzy name matching (similar names)
    pep_fuzzy.EXPOSED_PERSON_ID AS EXPOSED_PERSON_FUZZY_MATCH_ID,
    pep_fuzzy.FULL_NAME AS EXPOSED_PERSON_FUZZY_MATCH_NAME,
    pep_fuzzy.EXPOSED_PERSON_CATEGORY AS EXPOSED_PERSON_FUZZY_CATEGORY,
    pep_fuzzy.RISK_LEVEL AS EXPOSED_PERSON_FUZZY_RISK_LEVEL,
    pep_fuzzy.STATUS AS EXPOSED_PERSON_FUZZY_STATUS,
    
    -- PEP Match Accuracy Level
    CASE 
        WHEN pep_exact.EXPOSED_PERSON_ID IS NOT NULL THEN 100.0  -- Exact match = 100% accuracy
        WHEN pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL THEN
            -- Calculate accuracy based on edit distance for fuzzy matches
            CASE 
                -- Both names have edit distance of 1 (highest fuzzy accuracy)
                WHEN EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 1
                     AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 1 
                THEN 95.0
                -- One exact name, other with edit distance 1
                WHEN (UPPER(c.FIRST_NAME) = UPPER(pep_fuzzy.FIRST_NAME) AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 1)
                     OR (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 1 AND UPPER(c.FAMILY_NAME) = UPPER(pep_fuzzy.LAST_NAME))
                THEN 90.0
                -- One exact name, other with edit distance 2
                WHEN (UPPER(c.FIRST_NAME) = UPPER(pep_fuzzy.FIRST_NAME) AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 2)
                     OR (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 2 AND UPPER(c.FAMILY_NAME) = UPPER(pep_fuzzy.LAST_NAME))
                THEN 85.0
                -- Full name similarity with edit distance <= 3
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(pep_fuzzy.FULL_NAME)) <= 3
                THEN GREATEST(70.0, 100.0 - (EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(pep_fuzzy.FULL_NAME)) * 10.0))
                -- Default fuzzy match accuracy
                ELSE 75.0
            END
        ELSE NULL  -- No match
    END AS EXPOSED_PERSON_MATCH_ACCURACY_PERCENT,
    
    -- PEP Risk Assessment
    CASE 
        WHEN pep_exact.EXPOSED_PERSON_ID IS NOT NULL THEN 'EXACT_MATCH'
        WHEN pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL THEN 'FUZZY_MATCH'
        ELSE 'NO_MATCH'
    END AS EXPOSED_PERSON_MATCH_TYPE,
    
    CASE 
        WHEN pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL' THEN 'CRITICAL'
        WHEN pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH' THEN 'HIGH'
        WHEN pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM' THEN 'MEDIUM'
        WHEN pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW' THEN 'LOW'
        ELSE 'NO_EXPOSED_PERSON_RISK'
    END AS OVERALL_EXPOSED_PERSON_RISK,
    
    -- Sanctions Matching (Global Sanctions Data) - Fuzzy matching against external database
    sanctions_exact.ENTITY_ID AS SANCTIONS_EXACT_MATCH_ID,
    sanctions_exact.ENTITY_NAME AS SANCTIONS_EXACT_MATCH_NAME,
    sanctions_exact.ENTITY_TYPE AS SANCTIONS_EXACT_MATCH_TYPE,
    sanctions_exact.COUNTRY AS SANCTIONS_EXACT_MATCH_COUNTRY,
    
    sanctions_fuzzy.ENTITY_ID AS SANCTIONS_FUZZY_MATCH_ID,
    sanctions_fuzzy.ENTITY_NAME AS SANCTIONS_FUZZY_MATCH_NAME,
    sanctions_fuzzy.ENTITY_TYPE AS SANCTIONS_FUZZY_MATCH_TYPE,
    sanctions_fuzzy.COUNTRY AS SANCTIONS_FUZZY_MATCH_COUNTRY,
    
    -- Sanctions Match Accuracy Level
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL THEN 100.0  -- Exact match = 100% accuracy
        WHEN sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN
            -- Calculate accuracy based on edit distance for fuzzy matches
            CASE 
                -- Edit distance of 1 (highest fuzzy accuracy)
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 1
                THEN 95.0
                -- Edit distance of 2
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 2
                THEN 90.0
                -- Edit distance of 3
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 3
                THEN 85.0
                -- Edit distance of 4
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 4
                THEN 80.0
                -- Edit distance of 5 (lowest acceptable fuzzy match)
                WHEN EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) = 5
                THEN 75.0
                -- Default fuzzy match accuracy
                ELSE 70.0
            END
        ELSE NULL  -- No match
    END AS SANCTIONS_MATCH_ACCURACY_PERCENT,
    
    -- Sanctions Risk Assessment
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL THEN 'EXACT_MATCH'
        WHEN sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 'FUZZY_MATCH'
        ELSE 'NO_MATCH'
    END AS SANCTIONS_MATCH_TYPE,
    
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 'CRITICAL'
        ELSE 'NO_SANCTIONS_RISK'
    END AS OVERALL_SANCTIONS_RISK,
    
    -- Overall Risk Rating (combines PEP, sanctions, and anomalies)
    CASE 
        -- CRITICAL: Any sanctions match OR (PEP CRITICAL + anomaly)
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 'CRITICAL'
        WHEN (pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL') AND c.HAS_ANOMALY = TRUE THEN 'CRITICAL'
        
        -- HIGH: PEP HIGH + anomaly OR PEP CRITICAL without anomaly
        WHEN (pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH') AND c.HAS_ANOMALY = TRUE THEN 'HIGH'
        WHEN pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL' THEN 'HIGH'
        
        -- MEDIUM: PEP MEDIUM + anomaly OR PEP HIGH without anomaly
        WHEN (pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM') AND c.HAS_ANOMALY = TRUE THEN 'MEDIUM'
        WHEN pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH' THEN 'MEDIUM'
        
        -- LOW: PEP LOW + anomaly OR PEP MEDIUM without anomaly OR anomaly only
        WHEN (pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW') AND c.HAS_ANOMALY = TRUE THEN 'LOW'
        WHEN pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM' THEN 'LOW'
        WHEN c.HAS_ANOMALY = TRUE THEN 'LOW'
        WHEN pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW' THEN 'LOW'
        
        -- NO_RISK: No matches and no anomalies
        ELSE 'NO_RISK'
    END AS OVERALL_RISK_RATING,
    
    -- Overall Risk Score (0-100 numerical score)
    CASE 
        -- CRITICAL: 90-100
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN 100
        WHEN (pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL') AND c.HAS_ANOMALY = TRUE THEN 95
        
        -- HIGH: 70-89
        WHEN (pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH') AND c.HAS_ANOMALY = TRUE THEN 85
        WHEN pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL' THEN 80
        
        -- MEDIUM: 50-69
        WHEN (pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM') AND c.HAS_ANOMALY = TRUE THEN 65
        WHEN pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH' THEN 60
        
        -- LOW: 20-49
        WHEN (pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW') AND c.HAS_ANOMALY = TRUE THEN 45
        WHEN pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM' THEN 40
        WHEN c.HAS_ANOMALY = TRUE THEN 35
        WHEN pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW' THEN 30
        
        -- NO_RISK: 0-19
        ELSE 10
    END AS OVERALL_RISK_SCORE,
    
    -- Compliance Flags
    CASE 
        WHEN pep_exact.EXPOSED_PERSON_ID IS NOT NULL OR pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS REQUIRES_EXPOSED_PERSON_REVIEW,
    
    CASE 
        WHEN sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS REQUIRES_SANCTIONS_REVIEW,
    
    CASE 
        WHEN c.HAS_ANOMALY = TRUE AND (pep_exact.EXPOSED_PERSON_ID IS NOT NULL OR pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL OR sanctions_exact.ENTITY_ID IS NOT NULL OR sanctions_fuzzy.ENTITY_ID IS NOT NULL) THEN TRUE
        ELSE FALSE
    END AS HIGH_RISK_CUSTOMER,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM CRMA_AGG_DT_CUSTOMER_CURRENT c

-- Join current address
LEFT JOIN CRMA_AGG_DT_ADDRESSES_CURRENT addr
    ON c.CUSTOMER_ID = addr.CUSTOMER_ID

-- Join current customer status (get latest status per customer)
LEFT JOIN (
    SELECT 
        CUSTOMER_ID,
        STATUS,
        STATUS_START_DATE,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY STATUS_START_DATE DESC) AS rn
    FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER_STATUS
    WHERE IS_CURRENT = TRUE
) status
    ON c.CUSTOMER_ID = status.CUSTOMER_ID
    AND status.rn = 1

-- Join accounts (aggregation layer) - for account type counts and metadata
LEFT JOIN CRM_AGG_001.ACCA_AGG_DT_ACCOUNTS acc
    ON c.CUSTOMER_ID = acc.CUSTOMER_ID

-- Join account balances (Phase 1 Enhancement) - for balance metrics
LEFT JOIN PAY_AGG_001.PAYA_AGG_DT_ACCOUNT_BALANCES bal
    ON c.CUSTOMER_ID = bal.CUSTOMER_ID

-- Join transactions (Phase 2 Enhancement - Option A: Direct Cross-Schema Join)
-- Note: PAYI_RAW_TB_TRANSACTIONS has ACCOUNT_ID, not CUSTOMER_ID, so we join through accounts
LEFT JOIN PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS txn
    ON acc.ACCOUNT_ID = txn.ACCOUNT_ID

-- Exact Exposed Person name matching
LEFT JOIN CRM_RAW_001.CRMI_RAW_TB_EXPOSED_PERSON pep_exact
    ON UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)) = UPPER(pep_exact.FULL_NAME)
    AND pep_exact.STATUS = 'ACTIVE'

-- Fuzzy Exposed Person name matching (similar names, different spellings)
LEFT JOIN CRM_RAW_001.CRMI_RAW_TB_EXPOSED_PERSON pep_fuzzy
    ON pep_fuzzy.EXPOSED_PERSON_ID != COALESCE(pep_exact.EXPOSED_PERSON_ID, 'NO_EXACT_MATCH')  -- Avoid duplicate matches
    AND pep_fuzzy.STATUS = 'ACTIVE'
    AND (
        -- Similar first name and exact last name
        (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) <= 2 
         AND UPPER(c.FAMILY_NAME) = UPPER(pep_fuzzy.LAST_NAME))
        OR
        -- Exact first name and similar last name  
        (UPPER(c.FIRST_NAME) = UPPER(pep_fuzzy.FIRST_NAME)
         AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) <= 2)
        OR
        -- Both names similar (stricter threshold)
        (EDITDISTANCE(UPPER(c.FIRST_NAME), UPPER(pep_fuzzy.FIRST_NAME)) = 1
         AND EDITDISTANCE(UPPER(c.FAMILY_NAME), UPPER(pep_fuzzy.LAST_NAME)) = 1)
        OR
        -- Full name similarity (for compound names)
        EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(pep_fuzzy.FULL_NAME)) <= 3
    )

-- Sanctions matching against Global Sanctions Data with fuzzy matching
-- Using copy database to avoid external database limitations
LEFT JOIN AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY.PUBLIC.SANCTIONS_TB_DATA_STAGING sanctions_exact
    ON UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)) = UPPER(sanctions_exact.ENTITY_NAME)

LEFT JOIN AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY.PUBLIC.SANCTIONS_TB_DATA_STAGING sanctions_fuzzy
    ON sanctions_fuzzy.ENTITY_ID != COALESCE(sanctions_exact.ENTITY_ID, 'NO_EXACT_MATCH')
    AND EDITDISTANCE(UPPER(CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME)), UPPER(sanctions_fuzzy.ENTITY_NAME)) <= 5

GROUP BY 
    c.CUSTOMER_ID, c.FIRST_NAME, c.FAMILY_NAME, c.FULL_NAME, c.DATE_OF_BIRTH, c.ONBOARDING_DATE, c.REPORTING_CURRENCY, c.HAS_ANOMALY,
    c.EMPLOYER, c.POSITION, c.EMPLOYMENT_TYPE, c.INCOME_RANGE, c.ACCOUNT_TIER, c.EMAIL, c.PHONE, c.PREFERRED_CONTACT_METHOD, c.RISK_CLASSIFICATION, c.CREDIT_SCORE_BAND,
    addr.STREET_ADDRESS, addr.CITY, addr.STATE, addr.ZIPCODE, addr.COUNTRY, addr.CURRENT_FROM,
    status.STATUS, status.STATUS_START_DATE,
    pep_exact.EXPOSED_PERSON_ID, pep_exact.FULL_NAME, pep_exact.EXPOSED_PERSON_CATEGORY, pep_exact.RISK_LEVEL, pep_exact.STATUS,
    pep_fuzzy.EXPOSED_PERSON_ID, pep_fuzzy.FULL_NAME, pep_fuzzy.FIRST_NAME, pep_fuzzy.LAST_NAME, pep_fuzzy.EXPOSED_PERSON_CATEGORY, pep_fuzzy.RISK_LEVEL, pep_fuzzy.STATUS,
    sanctions_exact.ENTITY_ID, sanctions_exact.ENTITY_NAME, sanctions_exact.ENTITY_TYPE, sanctions_exact.COUNTRY,
    sanctions_fuzzy.ENTITY_ID, sanctions_fuzzy.ENTITY_NAME, sanctions_fuzzy.ENTITY_TYPE, sanctions_fuzzy.COUNTRY

ORDER BY c.CUSTOMER_ID;

-- ============================================================
-- SHARED ANALYTICAL VIEWS (For Notebook Consolidation)
-- ============================================================


CREATE OR REPLACE VIEW CRMA_AGG_VW_CUSTOMER_RISK_PROFILE
COMMENT = 'Consolidated customer risk segmentation - single source of truth for risk metrics across all notebooks. Provides population counts, risk breakdowns, PEP/sanctions metrics, and AUM distribution by risk level. Used by 6 notebooks.'
AS
SELECT 
    -- Overall Population Metrics
    COUNT(DISTINCT CUSTOMER_ID) as TOTAL_CUSTOMERS,
    CURRENT_DATE() as AS_OF_DATE,
    CURRENT_TIMESTAMP() as CALCULATION_TIMESTAMP,
    
    -- Risk Classification Breakdown (Counts)
    COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'CRITICAL' THEN CUSTOMER_ID END) as CRITICAL_RISK_COUNT,
    COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'HIGH' THEN CUSTOMER_ID END) as HIGH_RISK_COUNT,
    COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'MEDIUM' THEN CUSTOMER_ID END) as MEDIUM_RISK_COUNT,
    COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'LOW' THEN CUSTOMER_ID END) as LOW_RISK_COUNT,
    
    -- Risk Classification Percentages
    ROUND(COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'CRITICAL' THEN CUSTOMER_ID END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as CRITICAL_RISK_PCT,
    ROUND(COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'HIGH' THEN CUSTOMER_ID END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as HIGH_RISK_PCT,
    ROUND(COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'MEDIUM' THEN CUSTOMER_ID END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as MEDIUM_RISK_PCT,
    ROUND(COUNT(DISTINCT CASE WHEN RISK_CLASSIFICATION = 'LOW' THEN CUSTOMER_ID END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as LOW_RISK_PCT,
    
    -- PEP (Politically Exposed Person) Metrics
    COUNT(DISTINCT CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') 
        THEN CUSTOMER_ID 
    END) as PEP_COUNT,
    COUNT(DISTINCT CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' 
        THEN CUSTOMER_ID 
    END) as PEP_EXACT_MATCH_COUNT,
    COUNT(DISTINCT CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' 
        THEN CUSTOMER_ID 
    END) as PEP_FUZZY_MATCH_COUNT,
    ROUND(COUNT(DISTINCT CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') 
        THEN CUSTOMER_ID 
    END) * 100.0 / NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as PEP_PCT,
    
    -- Sanctions Screening Metrics
    COUNT(DISTINCT CASE 
        WHEN SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') 
        THEN CUSTOMER_ID 
    END) as SANCTIONS_COUNT,
    COUNT(DISTINCT CASE 
        WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' 
        THEN CUSTOMER_ID 
    END) as SANCTIONS_EXACT_MATCH_COUNT,
    COUNT(DISTINCT CASE 
        WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' 
        THEN CUSTOMER_ID 
    END) as SANCTIONS_FUZZY_MATCH_COUNT,
    ROUND(COUNT(DISTINCT CASE 
        WHEN SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') 
        THEN CUSTOMER_ID 
    END) * 100.0 / NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as SANCTIONS_PCT,
    
    -- Transaction Anomaly Metrics
    COUNT(DISTINCT CASE WHEN HAS_ANOMALY = TRUE THEN CUSTOMER_ID END) as ANOMALY_COUNT,
    ROUND(COUNT(DISTINCT CASE WHEN HAS_ANOMALY = TRUE THEN CUSTOMER_ID END) * 100.0 / 
          NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as ANOMALY_PCT,
    
    -- Combined High Risk (Any of: PEP, High/Critical Risk, Sanctions, Anomaly)
    COUNT(DISTINCT CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            OR RISK_CLASSIFICATION IN ('CRITICAL', 'HIGH')
            OR SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            OR HAS_ANOMALY = TRUE
        THEN CUSTOMER_ID 
    END) as COMBINED_HIGH_RISK_COUNT,
    ROUND(COUNT(DISTINCT CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            OR RISK_CLASSIFICATION IN ('CRITICAL', 'HIGH')
            OR SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            OR HAS_ANOMALY = TRUE
        THEN CUSTOMER_ID 
    END) * 100.0 / NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0), 2) as COMBINED_HIGH_RISK_PCT,
    
    -- Multiple Risk Factor Analysis
    COUNT(DISTINCT CASE 
        WHEN (CASE WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') THEN 1 ELSE 0 END +
              CASE WHEN RISK_CLASSIFICATION IN ('CRITICAL', 'HIGH') THEN 1 ELSE 0 END +
              CASE WHEN SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') THEN 1 ELSE 0 END +
              CASE WHEN HAS_ANOMALY = TRUE THEN 1 ELSE 0 END) >= 2
        THEN CUSTOMER_ID 
    END) as MULTIPLE_RISK_FACTORS_COUNT,
    
    -- Critical Combo: PEP + Sanctions
    COUNT(DISTINCT CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            AND SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
        THEN CUSTOMER_ID 
    END) as PEP_AND_SANCTIONS_COUNT,
    
    -- Dormant High Risk (High risk but no recent transactions)
    COUNT(DISTINCT CASE 
        WHEN (EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
              OR RISK_CLASSIFICATION IN ('CRITICAL', 'HIGH')
              OR SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH'))
            AND IS_DORMANT_TRANSACTIONALLY = TRUE
        THEN CUSTOMER_ID 
    END) as DORMANT_HIGH_RISK_COUNT,
    
    -- Active High Risk (High risk with recent transactions - heightened monitoring)
    COUNT(DISTINCT CASE 
        WHEN (EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
              OR RISK_CLASSIFICATION IN ('CRITICAL', 'HIGH')
              OR SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH'))
            AND IS_DORMANT_TRANSACTIONALLY = FALSE
        THEN CUSTOMER_ID 
    END) as ACTIVE_HIGH_RISK_COUNT,
    
    -- Risk Distribution by AUM (Balance-based segmentation)
    SUM(CASE WHEN RISK_CLASSIFICATION = 'CRITICAL' THEN COALESCE(TOTAL_BALANCE, 0) ELSE 0 END) as CRITICAL_RISK_AUM,
    SUM(CASE WHEN RISK_CLASSIFICATION = 'HIGH' THEN COALESCE(TOTAL_BALANCE, 0) ELSE 0 END) as HIGH_RISK_AUM,
    SUM(CASE WHEN RISK_CLASSIFICATION = 'MEDIUM' THEN COALESCE(TOTAL_BALANCE, 0) ELSE 0 END) as MEDIUM_RISK_AUM,
    SUM(CASE WHEN RISK_CLASSIFICATION = 'LOW' THEN COALESCE(TOTAL_BALANCE, 0) ELSE 0 END) as LOW_RISK_AUM,
    
    -- Total AUM at Risk
    SUM(CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            OR RISK_CLASSIFICATION IN ('CRITICAL', 'HIGH')
            OR SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
        THEN COALESCE(TOTAL_BALANCE, 0) 
        ELSE 0 
    END) as TOTAL_HIGH_RISK_AUM
    
FROM CRMA_AGG_DT_CUSTOMER_360;


CREATE OR REPLACE VIEW CRMA_AGG_VW_SCREENING_STATUS
COMMENT = 'Combined PEP and sanctions screening status for all customers. Provides detailed match information, risk tiers, SLA tracking, and investigation requirements. Single source of truth for compliance screening across all notebooks. Used by 4 notebooks.'
AS
SELECT 
    -- Customer Identity
    CUSTOMER_ID,
    FIRST_NAME,
    FAMILY_NAME,
    FIRST_NAME || ' ' || FAMILY_NAME as FULL_NAME,
    DATE_OF_BIRTH,
    COUNTRY,
    ONBOARDING_DATE,
    CURRENT_STATUS,
    
    -- PEP Screening Status
    EXPOSED_PERSON_MATCH_TYPE as PEP_MATCH_TYPE,
    CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') THEN TRUE
        ELSE FALSE
    END as IS_PEP,
    
    -- PEP Match Details
    COALESCE(EXPOSED_PERSON_EXACT_MATCH_NAME, EXPOSED_PERSON_FUZZY_MATCH_NAME) as PEP_MATCH_NAME,
    COALESCE(EXPOSED_PERSON_EXACT_CATEGORY, EXPOSED_PERSON_FUZZY_CATEGORY) as PEP_CATEGORY,
    COALESCE(EXPOSED_PERSON_EXACT_RISK_LEVEL, EXPOSED_PERSON_FUZZY_RISK_LEVEL) as PEP_RISK_LEVEL,
    EXPOSED_PERSON_MATCH_ACCURACY_PERCENT as PEP_MATCH_ACCURACY,
    
    -- PEP Match Confidence Level
    CASE 
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' THEN 'HIGH'
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' AND EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 90 THEN 'MEDIUM_HIGH'
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' AND EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 80 THEN 'MEDIUM'
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' THEN 'LOW_MEDIUM'
        ELSE 'NONE'
    END as PEP_MATCH_CONFIDENCE,
    
    -- Sanctions Screening Status
    SANCTIONS_MATCH_TYPE,
    CASE 
        WHEN SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') THEN TRUE
        ELSE FALSE
    END as HAS_SANCTIONS_HIT,
    
    -- Sanctions Match Details
    COALESCE(SANCTIONS_EXACT_MATCH_NAME, SANCTIONS_FUZZY_MATCH_NAME) as SANCTIONS_MATCH_NAME,
    COALESCE(SANCTIONS_EXACT_MATCH_TYPE, SANCTIONS_FUZZY_MATCH_TYPE) as SANCTIONS_ENTITY_TYPE,
    COALESCE(SANCTIONS_EXACT_MATCH_COUNTRY, SANCTIONS_FUZZY_MATCH_COUNTRY) as SANCTIONS_COUNTRY,
    SANCTIONS_MATCH_ACCURACY_PERCENT as SANCTIONS_MATCH_ACCURACY,
    
    -- Sanctions Match Confidence Level
    CASE 
        WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' THEN 'HIGH'
        WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' AND SANCTIONS_MATCH_ACCURACY_PERCENT >= 90 THEN 'MEDIUM_HIGH'
        WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' AND SANCTIONS_MATCH_ACCURACY_PERCENT >= 80 THEN 'MEDIUM'
        WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' THEN 'LOW_MEDIUM'
        ELSE 'NONE'
    END as SANCTIONS_MATCH_CONFIDENCE,
    
    -- Overall Screening Risk Assessment
    OVERALL_EXPOSED_PERSON_RISK,
    OVERALL_SANCTIONS_RISK,
    OVERALL_RISK_RATING,
    OVERALL_RISK_SCORE,
    
    -- Combined Screening Risk Tier
    CASE 
        WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' THEN 'SANCTIONS_EXACT_CRITICAL'
        WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' THEN 'SANCTIONS_FUZZY_HIGH'
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' AND COALESCE(EXPOSED_PERSON_EXACT_RISK_LEVEL, 'LOW') IN ('CRITICAL', 'HIGH') THEN 'PEP_EXACT_HIGH'
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' AND COALESCE(EXPOSED_PERSON_FUZZY_RISK_LEVEL, 'LOW') IN ('CRITICAL', 'HIGH') THEN 'PEP_FUZZY_HIGH'
        WHEN EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') THEN 'PEP_MEDIUM'
        WHEN RISK_CLASSIFICATION = 'CRITICAL' THEN 'HIGH_RISK_NO_MATCH'
        WHEN RISK_CLASSIFICATION = 'HIGH' THEN 'MEDIUM_RISK_NO_MATCH'
        ELSE 'LOW_RISK'
    END as SCREENING_RISK_TIER,
    
    -- Action Required Flags
    CASE 
        WHEN SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH') THEN 'IMMEDIATE_BLOCK'
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' THEN 'ENHANCED_DUE_DILIGENCE'
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' THEN 'VERIFY_AND_INVESTIGATE'
        WHEN RISK_CLASSIFICATION = 'CRITICAL' THEN 'ENHANCED_MONITORING'
        WHEN RISK_CLASSIFICATION = 'HIGH' THEN 'STANDARD_MONITORING'
        ELSE 'ROUTINE'
    END as REQUIRED_ACTION,
    
    REQUIRES_EXPOSED_PERSON_REVIEW as REQUIRES_PEP_REVIEW,
    REQUIRES_SANCTIONS_REVIEW,
    
    -- Investigation requires both PEP/Sanctions review
    CASE 
        WHEN REQUIRES_EXPOSED_PERSON_REVIEW = TRUE OR REQUIRES_SANCTIONS_REVIEW = TRUE 
        THEN TRUE 
        ELSE FALSE 
    END as REQUIRES_INVESTIGATION,
    
    -- SLA Policy for Investigation (days)
    CASE 
        WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' THEN 1  -- Immediate (same day)
        WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' THEN 3  -- 3 business days
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' THEN 7  -- 1 week
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' THEN 14  -- 2 weeks
        WHEN RISK_CLASSIFICATION = 'CRITICAL' THEN 7
        WHEN RISK_CLASSIFICATION = 'HIGH' THEN 30
        ELSE 90
    END as INVESTIGATION_SLA_DAYS,
    
    -- Alert Age (using onboarding_date as proxy for screening date)
    DATEDIFF(day, ONBOARDING_DATE, CURRENT_DATE()) as DAYS_SINCE_SCREENING,
    
    -- SLA Breach Flag
    CASE 
        WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' 
            AND DATEDIFF(day, ONBOARDING_DATE, CURRENT_DATE()) > 1 
        THEN TRUE
        WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' 
            AND DATEDIFF(day, ONBOARDING_DATE, CURRENT_DATE()) > 3 
        THEN TRUE
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' 
            AND DATEDIFF(day, ONBOARDING_DATE, CURRENT_DATE()) > 7 
        THEN TRUE
        WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' 
            AND DATEDIFF(day, ONBOARDING_DATE, CURRENT_DATE()) > 14 
        THEN TRUE
        ELSE FALSE
    END as IS_SLA_BREACH,
    
    -- Risk Context
    RISK_CLASSIFICATION,
    HAS_ANOMALY as HAS_TRANSACTION_ANOMALY,
    HIGH_RISK_CUSTOMER,
    
    -- Combined Risk Flags (for filtering)
    CASE 
        WHEN SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            OR EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            OR RISK_CLASSIFICATION IN ('CRITICAL', 'HIGH')
        THEN TRUE
        ELSE FALSE
    END as IS_HIGH_RISK,
    
    -- Multiple Screening Hits
    CASE 
        WHEN SANCTIONS_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
            AND EXPOSED_PERSON_MATCH_TYPE IN ('EXACT_MATCH', 'FUZZY_MATCH')
        THEN TRUE
        ELSE FALSE
    END as HAS_MULTIPLE_SCREENING_HITS,
    
    -- Financial Context
    TOTAL_BALANCE as ACCOUNT_BALANCE,
    TOTAL_ACCOUNTS,
    TOTAL_TRANSACTIONS,
    IS_DORMANT_TRANSACTIONALLY,
    
    -- Timestamp
    LAST_UPDATED as SCREENING_LAST_UPDATED,
    CURRENT_TIMESTAMP() as AS_OF_TIMESTAMP
    
FROM CRMA_AGG_DT_CUSTOMER_360;

CREATE OR REPLACE VIEW CRMA_AGG_VW_SCREENING_ALERTS
COMMENT = 'Filtered view showing only customers with PEP or sanctions hits requiring investigation. Pre-prioritized by action urgency and SLA breach status. Used for alert dashboards and case management.'
AS
SELECT * 
FROM CRMA_AGG_VW_SCREENING_STATUS
WHERE REQUIRES_INVESTIGATION = TRUE
ORDER BY 
    CASE REQUIRED_ACTION
        WHEN 'IMMEDIATE_BLOCK' THEN 1
        WHEN 'ENHANCED_DUE_DILIGENCE' THEN 2
        WHEN 'VERIFY_AND_INVESTIGATE' THEN 3
        WHEN 'ENHANCED_MONITORING' THEN 4
        ELSE 5
    END,
    IS_SLA_BREACH DESC,
    DAYS_SINCE_SCREENING DESC;

-- ============================================================
-- CRM_AGG_001 Schema Setup Complete!
-- ============================================================
--
-- DYNAMIC TABLE REFRESH STATUS:
-- All dynamic tables will automatically refresh based on changes to the
-- source tables with a 1-hour target lag. The 360° view depends on multiple
-- source tables: CRMI_RAW_TB_CUSTOMER, CRMI_RAW_TB_ADDRESSES, CRMI_RAW_TB_CUSTOMER_STATUS,
-- ACCA_AGG_DT_ACCOUNTS (for account type counts),
-- PAYA_AGG_DT_ACCOUNT_BALANCES (for balance metrics),
-- PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY (for transaction metrics - if used),
-- CRMI_RAW_TB_EXPOSED_PERSON, and Global Sanctions Data from Snowflake Data Exchange with 
-- comprehensive fuzzy matching.
--
-- USAGE EXAMPLES:
--
-- 1. Get current address for a customer:
--    SELECT * FROM CRMA_AGG_DT_ADDRESSES_CURRENT 
--    WHERE CUSTOMER_ID = 'CUST_00001';
--
-- 2. Get address history for compliance:
--    SELECT * FROM CRMA_AGG_DT_ADDRESSES_HISTORY 
--    WHERE CUSTOMER_ID = 'CUST_00001' 
--    ORDER BY VALID_FROM;
--
-- 3. Point-in-time address query:
--    SELECT * FROM CRMA_AGG_DT_ADDRESSES_HISTORY 
--    WHERE CUSTOMER_ID = 'CUST_00001' 
--    AND '2024-06-15' BETWEEN VALID_FROM AND COALESCE(VALID_TO, CURRENT_DATE());
--
-- 4. Address change audit trail:
--    SELECT CUSTOMER_ID, VALID_FROM, VALID_TO, STREET_ADDRESS, CITY, COUNTRY
--    FROM CRMA_AGG_DT_ADDRESSES_HISTORY 
--    WHERE CUSTOMER_ID = 'CUST_00001'
--    ORDER BY VALID_FROM;
--
-- 5. Comprehensive customer view with Exposed Person and Sanctions screening:
--    SELECT * FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE CUSTOMER_ID = 'CUST_00001';
--
-- 6. Find customers with sanctions matches:
--    SELECT CUSTOMER_ID, FULL_NAME, SANCTIONS_MATCH_TYPE, SANCTIONS_MATCH_ACCURACY_PERCENT,
--           SANCTIONS_EXACT_MATCH_NAME, SANCTIONS_FUZZY_MATCH_NAME
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE SANCTIONS_MATCH_TYPE != 'NO_MATCH';
--
-- 7. High-risk customers (anomalies + PEP + sanctions):
--    SELECT CUSTOMER_ID, FULL_NAME, HIGH_RISK_CUSTOMER, OVERALL_EXPOSED_PERSON_RISK, OVERALL_SANCTIONS_RISK
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE HIGH_RISK_CUSTOMER = TRUE;
--
-- 8. Compliance review queue:
--    SELECT CUSTOMER_ID, FULL_NAME, REQUIRES_EXPOSED_PERSON_REVIEW, REQUIRES_SANCTIONS_REVIEW
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE REQUIRES_EXPOSED_PERSON_REVIEW = TRUE OR REQUIRES_SANCTIONS_REVIEW = TRUE;
--
-- 6. Find customers with Exposed Person matches (with accuracy):
--    SELECT CUSTOMER_ID, FULL_NAME, EXPOSED_PERSON_MATCH_TYPE, OVERALL_EXPOSED_PERSON_RISK, EXPOSED_PERSON_MATCH_ACCURACY_PERCENT
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE EXPOSED_PERSON_MATCH_TYPE != 'NO_MATCH'
--    ORDER BY EXPOSED_PERSON_MATCH_ACCURACY_PERCENT DESC, OVERALL_EXPOSED_PERSON_RISK DESC;
--
-- 7. High-risk customers (anomaly + PEP) with match accuracy:
--    SELECT CUSTOMER_ID, FULL_NAME, COUNTRY, TOTAL_ACCOUNTS, 
--           EXPOSED_PERSON_EXACT_MATCH_NAME, EXPOSED_PERSON_FUZZY_MATCH_NAME, OVERALL_EXPOSED_PERSON_RISK, EXPOSED_PERSON_MATCH_ACCURACY_PERCENT
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE HIGH_RISK_CUSTOMER = TRUE;
--
-- 8. Exposed Person match accuracy analysis:
--    SELECT 
--        EXPOSED_PERSON_MATCH_TYPE,
--        CASE 
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT = 100 THEN 'EXACT (100%)'
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 90 THEN 'HIGH (90-99%)'
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 80 THEN 'MEDIUM (80-89%)'
--            WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT >= 70 THEN 'LOW (70-79%)'
--            ELSE 'NO_MATCH'
--        END AS ACCURACY_BAND,
--        COUNT(*) AS CUSTOMER_COUNT,
--        AVG(EXPOSED_PERSON_MATCH_ACCURACY_PERCENT) AS AVG_ACCURACY
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE EXPOSED_PERSON_MATCH_TYPE != 'NO_MATCH'
--    GROUP BY EXPOSED_PERSON_MATCH_TYPE, ACCURACY_BAND
--    ORDER BY AVG_ACCURACY DESC;
--
-- 9. Customer compliance summary:
--    SELECT 
--        COUNT(*) AS TOTAL_CUSTOMERS,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' THEN 1 END) AS EXACT_EXPOSED_PERSON_MATCHES,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' THEN 1 END) AS FUZZY_EXPOSED_PERSON_MATCHES,
--        COUNT(CASE WHEN REQUIRES_EXPOSED_PERSON_REVIEW = TRUE THEN 1 END) AS REQUIRES_REVIEW,
--        COUNT(CASE WHEN HIGH_RISK_CUSTOMER = TRUE THEN 1 END) AS HIGH_RISK_COUNT,
--        AVG(CASE WHEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT IS NOT NULL THEN EXPOSED_PERSON_MATCH_ACCURACY_PERCENT END) AS AVG_MATCH_ACCURACY
--    FROM CRMA_AGG_DT_CUSTOMER_360;
--
-- 10. Sanctions screening with Global Sanctions Data:
--    SELECT CUSTOMER_ID, FULL_NAME, COUNTRY,
--           SANCTIONS_EXACT_MATCH_NAME, SANCTIONS_FUZZY_MATCH_NAME, 
--           SANCTIONS_MATCH_TYPE, OVERALL_SANCTIONS_RISK, SANCTIONS_MATCH_ACCURACY_PERCENT
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE SANCTIONS_MATCH_TYPE != 'NO_MATCH'
--    ORDER BY SANCTIONS_MATCH_ACCURACY_PERCENT DESC, OVERALL_SANCTIONS_RISK DESC;
--
-- 11. High-risk customers with both PEP and Sanctions matches:
--    SELECT CUSTOMER_ID, FULL_NAME, COUNTRY, TOTAL_ACCOUNTS,
--           EXPOSED_PERSON_EXACT_MATCH_NAME, SANCTIONS_EXACT_MATCH_NAME,
--           OVERALL_EXPOSED_PERSON_RISK, OVERALL_SANCTIONS_RISK
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE HIGH_RISK_CUSTOMER = TRUE;
--
-- 12. Sanctions match accuracy analysis:
--    SELECT 
--        SANCTIONS_MATCH_TYPE,
--        CASE 
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT = 100 THEN 'EXACT (100%)'
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT >= 90 THEN 'HIGH (90-99%)'
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT >= 80 THEN 'MEDIUM (80-89%)'
--            WHEN SANCTIONS_MATCH_ACCURACY_PERCENT >= 70 THEN 'LOW (70-79%)'
--            ELSE 'NO_MATCH'
--        END AS ACCURACY_BAND,
--        COUNT(*) AS CUSTOMER_COUNT,
--        AVG(SANCTIONS_MATCH_ACCURACY_PERCENT) AS AVG_ACCURACY
--    FROM CRMA_AGG_DT_CUSTOMER_360 
--    WHERE SANCTIONS_MATCH_TYPE != 'NO_MATCH'
--    GROUP BY SANCTIONS_MATCH_TYPE, ACCURACY_BAND
--    ORDER BY AVG_ACCURACY DESC;
--
-- 13. Comprehensive compliance summary (PEP + Sanctions):
--    SELECT 
--        COUNT(*) AS TOTAL_CUSTOMERS,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' THEN 1 END) AS EXACT_PEP_MATCHES,
--        COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'FUZZY_MATCH' THEN 1 END) AS FUZZY_PEP_MATCHES,
--        COUNT(CASE WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' THEN 1 END) AS EXACT_SANCTIONS_MATCHES,
--        COUNT(CASE WHEN SANCTIONS_MATCH_TYPE = 'FUZZY_MATCH' THEN 1 END) AS FUZZY_SANCTIONS_MATCHES,
--        COUNT(CASE WHEN REQUIRES_EXPOSED_PERSON_REVIEW = TRUE THEN 1 END) AS REQUIRES_PEP_REVIEW,
--        COUNT(CASE WHEN REQUIRES_SANCTIONS_REVIEW = TRUE THEN 1 END) AS REQUIRES_SANCTIONS_REVIEW,
--        COUNT(CASE WHEN HIGH_RISK_CUSTOMER = TRUE THEN 1 END) AS HIGH_RISK_COUNT
--    FROM CRMA_AGG_DT_CUSTOMER_360;
--
-- MONITORING:
-- - Monitor dynamic table refresh: SHOW DYNAMIC TABLES IN SCHEMA CRMA_AGG_001;
-- - Check refresh history: SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY());
-- - Validate data quality: Compare record counts between base and dynamic tables
--
-- PERFORMANCE OPTIMIZATION:
-- - Dynamic tables automatically maintain incremental refresh
-- - Consider clustering on CUSTOMER_ID for large datasets
-- - Monitor warehouse usage during refresh periods
--
-- RELATED SCHEMAS:
-- - CRM_RAW_001: Source customer and address master data
-- - CRM_AGG_001: Account aggregation (ACCA_AGG_DT_ACCOUNTS for account metadata)
-- - PAY_RAW_001: Payment transactions (source for balances and activity - direct join for transaction metrics)
-- - PAY_AGG_001: Account balances (PAYA_AGG_DT_ACCOUNT_BALANCES) and transaction summary (PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY - alternative to direct join)
-- - EQT_RAW_001: Equity trades (join on CUSTOMER_ID)
-- ============================================================
