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
-- - CRM_AGG_001: Account aggregation (ACCA_AGG_DT_ACCOUNTS - for account counts and types), Sanctions screening (CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING)
-- - PAY_RAW_001: Payment transactions (PAYI_RAW_TB_TRANSACTIONS - direct join for transaction metrics)
-- - PAY_AGG_001: Account balances (PAYA_AGG_DT_ACCOUNT_BALANCES)
-- - External: Global Sanctions Data from Snowflake Data Exchange
-- - EQT_RAW_001: Equity trades (for tax reporting)
--
-- DEPLOYMENT ORDER:
-- 1. 030_PAYI_transactions.sql (raw transaction data)
-- 2. 302_CRMA_sanctions_screening.sql (creates CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING)
-- 3. 311_ACCA_accounts_agg.sql (creates ACCA_AGG_DT_ACCOUNTS - account aggregation layer)
-- 4. 330_PAYA_anomaly_detection.sql (creates PAYA_AGG_DT_ACCOUNT_BALANCES)
-- 5. 410_CRMA_customer_360.sql (this file - depends on sanctions screening, account aggregation, balances, and transactions)
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
) 
TARGET_LAG = '60 MINUTE' 
WAREHOUSE = MD_TEST_WH
COMMENT = 'Current/latest address for each customer. Operational view with one record per customer showing the most recent address based on INSERT_TIMESTAMP_UTC. Used for real-time customer lookups and front-end applications.'
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
) 
TARGET_LAG = '60 MINUTE' 
WAREHOUSE = MD_TEST_WH
COMMENT = 'SCD Type 2 address history with VALID_FROM/VALID_TO effective date ranges. Converts append-only base table into proper slowly changing dimension for compliance reporting, historical analysis, and point-in-time customer address queries.'
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
) 
TARGET_LAG = '60 MINUTE' 
WAREHOUSE = MD_TEST_WH
COMMENT = 'Current/latest customer attributes for each customer. Operational view with one record per customer showing the most recent state based on INSERT_TIMESTAMP_UTC. Used for real-time customer lookups and front-end applications.'
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
) 
TARGET_LAG = '60 MINUTE' 
WAREHOUSE = MD_TEST_WH
COMMENT = 'SCD Type 2 customer attribute history with VALID_FROM/VALID_TO effective date ranges. Tracks changes to mutable attributes (employment, account tier, contact info) over time. Used for compliance reporting, historical analysis, and point-in-time customer attribute queries.'
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
-- CRMA_AGG_DT_CUSTOMER_LIFECYCLE - Customer Lifecycle Analysis (Analytical)
-- ============================================================
-- Comprehensive customer lifecycle view combining master data with lifecycle events
-- for customer journey analysis, retention tracking, and engagement measurement.

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_CUSTOMER_LIFECYCLE(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for lifecycle tracking',
    FIRST_NAME VARCHAR(100) COMMENT 'Customer first name',
    FAMILY_NAME VARCHAR(100) COMMENT 'Customer family/last name',
    FULL_NAME VARCHAR(201) COMMENT 'Customer full name',
    ONBOARDING_DATE DATE COMMENT 'Date when customer relationship was established',
    CUSTOMER_AGE_DAYS NUMBER(10,0) COMMENT 'Number of days since customer onboarding',
    CUSTOMER_AGE_MONTHS NUMBER(10,2) COMMENT 'Number of months since customer onboarding',
    TOTAL_LIFECYCLE_EVENTS NUMBER(10,0) COMMENT 'Total count of all lifecycle events for customer',
    FIRST_EVENT_DATE DATE COMMENT 'Date of first lifecycle event',
    LAST_EVENT_DATE DATE COMMENT 'Date of most recent lifecycle event',
    DAYS_SINCE_LAST_EVENT NUMBER(10,0) COMMENT 'Days since last lifecycle activity',
    ACCOUNT_OPENED_COUNT NUMBER(10,0) COMMENT 'Number of ACCOUNT_OPENED events',
    ACCOUNT_CLOSED_COUNT NUMBER(10,0) COMMENT 'Number of ACCOUNT_CLOSED events',
    TIER_UPGRADE_COUNT NUMBER(10,0) COMMENT 'Number of TIER_UPGRADE events',
    TIER_DOWNGRADE_COUNT NUMBER(10,0) COMMENT 'Number of TIER_DOWNGRADE events',
    ADDRESS_CHANGE_COUNT NUMBER(10,0) COMMENT 'Number of ADDRESS_CHANGE events',
    CONTACT_UPDATE_COUNT NUMBER(10,0) COMMENT 'Number of CONTACT_UPDATE events',
    EMPLOYMENT_CHANGE_COUNT NUMBER(10,0) COMMENT 'Number of EMPLOYMENT_CHANGE events',
    RISK_RECLASS_COUNT NUMBER(10,0) COMMENT 'Number of RISK_RECLASSIFICATION events',
    COMPLIANCE_REVIEW_COUNT NUMBER(10,0) COMMENT 'Number of COMPLIANCE_REVIEW events',
    KYC_REFRESH_COUNT NUMBER(10,0) COMMENT 'Number of KYC_REFRESH events',
    HAS_RECENT_ACTIVITY BOOLEAN COMMENT 'TRUE if activity in last 90 days',
    IS_DORMANT_LIFECYCLE BOOLEAN COMMENT 'TRUE if no activity in 180+ days',
    ENGAGEMENT_SCORE NUMBER(5,2) COMMENT 'Lifecycle engagement score (0-100 based on event frequency)',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when lifecycle record was last updated'
) 
TARGET_LAG = '60 MINUTE' 
WAREHOUSE = MD_TEST_WH
COMMENT = 'Customer lifecycle analysis combining master data with lifecycle events for journey tracking, retention analysis, and engagement measurement. Used for churn prediction, customer health scoring, and lifecycle stage identification.'
AS
SELECT 
    c.CUSTOMER_ID,
    c.FIRST_NAME,
    c.FAMILY_NAME,
    c.FULL_NAME,
    c.ONBOARDING_DATE,
    DATEDIFF(day, c.ONBOARDING_DATE, CURRENT_DATE()) AS CUSTOMER_AGE_DAYS,
    ROUND(DATEDIFF(day, c.ONBOARDING_DATE, CURRENT_DATE()) / 30.44, 2) AS CUSTOMER_AGE_MONTHS,
    COUNT(evt.EVENT_ID) AS TOTAL_LIFECYCLE_EVENTS,
    MIN(evt.EVENT_DATE) AS FIRST_EVENT_DATE,
    MAX(evt.EVENT_DATE) AS LAST_EVENT_DATE,
    COALESCE(DATEDIFF(day, MAX(evt.EVENT_DATE), CURRENT_DATE()), 9999) AS DAYS_SINCE_LAST_EVENT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'ACCOUNT_OPENED' THEN 1 END) AS ACCOUNT_OPENED_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'ACCOUNT_CLOSED' THEN 1 END) AS ACCOUNT_CLOSED_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'TIER_UPGRADE' THEN 1 END) AS TIER_UPGRADE_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'TIER_DOWNGRADE' THEN 1 END) AS TIER_DOWNGRADE_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'ADDRESS_CHANGE' THEN 1 END) AS ADDRESS_CHANGE_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'CONTACT_UPDATE' THEN 1 END) AS CONTACT_UPDATE_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'EMPLOYMENT_CHANGE' THEN 1 END) AS EMPLOYMENT_CHANGE_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'RISK_RECLASSIFICATION' THEN 1 END) AS RISK_RECLASS_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'COMPLIANCE_REVIEW' THEN 1 END) AS COMPLIANCE_REVIEW_COUNT,
    COUNT(CASE WHEN evt.EVENT_TYPE = 'KYC_REFRESH' THEN 1 END) AS KYC_REFRESH_COUNT,
    CASE 
        WHEN COALESCE(DATEDIFF(day, MAX(evt.EVENT_DATE), CURRENT_DATE()), 9999) <= 90 
        THEN TRUE 
        ELSE FALSE 
    END AS HAS_RECENT_ACTIVITY,
    CASE 
        WHEN COALESCE(DATEDIFF(day, MAX(evt.EVENT_DATE), CURRENT_DATE()), 9999) >= 180 
        THEN TRUE 
        ELSE FALSE 
    END AS IS_DORMANT_LIFECYCLE,
    CASE 
        WHEN COUNT(evt.EVENT_ID) = 0 THEN 0
        ELSE LEAST(100, 
            (COUNT(evt.EVENT_ID) * 10.0) + 
            (COUNT(CASE WHEN evt.EVENT_DATE >= DATEADD(month, -3, CURRENT_DATE()) THEN 1 END) * 5.0)
        )
    END AS ENGAGEMENT_SCORE,
    CURRENT_TIMESTAMP() AS LAST_UPDATED
FROM CRMA_AGG_DT_CUSTOMER_CURRENT c
LEFT JOIN CRM_RAW_001.CRMI_RAW_TB_CUSTOMER_EVENTS evt
    ON c.CUSTOMER_ID = evt.CUSTOMER_ID
GROUP BY 
    c.CUSTOMER_ID, c.FIRST_NAME, c.FAMILY_NAME, c.FULL_NAME, c.ONBOARDING_DATE
ORDER BY c.CUSTOMER_ID;

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
    
    -- Advisor Assignment (for relationship management and semantic views)
    CURRENT_ADVISOR_EMPLOYEE_ID VARCHAR(50) COMMENT 'Employee ID of currently assigned advisor/relationship manager for customer portfolio management and performance tracking',
    ADVISOR_ASSIGNMENT_START_DATE DATE COMMENT 'Date when current advisor was assigned to customer for relationship tenure analysis and advisor churn measurement',
    
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
    SANCTIONS_MATCH_ID VARCHAR(50) COMMENT 'Sanctions entity ID from enhanced screening view',
    SANCTIONS_MATCH_NAME VARCHAR(200) COMMENT 'Sanctions entity name from enhanced screening view',
    SANCTIONS_AUTHORITY VARCHAR(100) COMMENT 'Sanctioning authority (OFAC/EU/UN/etc.)',
    SANCTIONS_LIST VARCHAR(100) COMMENT 'Specific sanctions list name',
    SANCTIONS_PROGRAM VARCHAR(100) COMMENT 'Sanctions program (e.g., SDGT, UKRAINE-EO14024)',
    SANCTIONS_RISK_SCORE NUMBER(5,2) COMMENT 'Calculated risk score for sanctions match (0-100)',
    SANCTIONS_MATCH_TYPE_DETAIL VARCHAR(50) COMMENT 'Detailed match type (EXACT_MATCH/FUZZY_MATCH/ALIAS_MATCH)',
    SANCTIONS_MATCH_SCORE NUMBER(5,2) COMMENT 'Match quality score from screening algorithm (0-100)',
    SANCTIONS_MATCH_CONFIDENCE VARCHAR(20) COMMENT 'Match confidence classification (HIGH/MEDIUM/LOW)',
    SANCTIONS_DISPOSITION VARCHAR(50) COMMENT 'Recommended disposition for alert handling',
    SANCTIONS_ALERT_PRIORITY VARCHAR(20) COMMENT 'Alert priority level (CRITICAL/HIGH/MEDIUM/LOW)',
    SANCTIONS_DOB_MATCH BOOLEAN COMMENT 'TRUE if date of birth matches sanctions entity',
    SANCTIONS_NATIONALITY_MATCH BOOLEAN COMMENT 'TRUE if nationality matches sanctions entity',
    SANCTIONS_MATCH_ACCURACY_PERCENT NUMBER(5,2) COMMENT 'Sanctions match accuracy from screening view',
    SANCTIONS_MATCH_TYPE VARCHAR(15) COMMENT 'Type of sanctions match (EXACT_MATCH/FUZZY_MATCH/ALIAS_MATCH/NO_MATCH)',
    SANCTIONS_EXACT_MATCH_ID VARCHAR(50) COMMENT 'Exact match sanctions ID (backwards compatibility)',
    SANCTIONS_EXACT_MATCH_NAME VARCHAR(200) COMMENT 'Exact match sanctions name (backwards compatibility)',
    SANCTIONS_EXACT_MATCH_TYPE VARCHAR(20) COMMENT 'Exact match entity type (backwards compatibility)',
    SANCTIONS_EXACT_MATCH_COUNTRY VARCHAR(50) COMMENT 'Exact match country (backwards compatibility)',
    SANCTIONS_FUZZY_MATCH_ID VARCHAR(50) COMMENT 'Fuzzy match sanctions ID (backwards compatibility)',
    SANCTIONS_FUZZY_MATCH_NAME VARCHAR(200) COMMENT 'Fuzzy match sanctions name (backwards compatibility)',
    SANCTIONS_FUZZY_MATCH_TYPE VARCHAR(20) COMMENT 'Fuzzy match entity type (backwards compatibility)',
    SANCTIONS_FUZZY_MATCH_COUNTRY VARCHAR(50) COMMENT 'Fuzzy match country (backwards compatibility)',
    OVERALL_EXPOSED_PERSON_RISK VARCHAR(30) COMMENT 'Overall PEP risk assessment (CRITICAL/HIGH/MEDIUM/LOW/NO_EXPOSED_PERSON_RISK)',
    OVERALL_SANCTIONS_RISK VARCHAR(30) COMMENT 'Overall sanctions risk assessment (CRITICAL/NO_SANCTIONS_RISK)',
    OVERALL_RISK_RATING VARCHAR(20) COMMENT 'Comprehensive risk rating combining PEP, sanctions, and anomalies (CRITICAL/HIGH/MEDIUM/LOW/NO_RISK)',
    OVERALL_RISK_SCORE NUMBER(5,2) COMMENT 'Numerical risk score (0-100) combining all risk factors',
    REQUIRES_EXPOSED_PERSON_REVIEW BOOLEAN COMMENT 'Boolean flag indicating if customer requires PEP compliance review',
    REQUIRES_SANCTIONS_REVIEW BOOLEAN COMMENT 'Boolean flag indicating if customer requires sanctions compliance review',
    HIGH_RISK_CUSTOMER BOOLEAN COMMENT 'Boolean flag for customers with both anomalies and PEP/sanctions matches',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when customer record was last updated'
) 
TARGET_LAG = '60 MINUTE' 
WAREHOUSE = MD_TEST_WH
COMMENT = 'Comprehensive 360-degree customer view with master data, current address, current status, account summary with balances (Phase 1), transaction activity metrics via direct cross-schema join (Phase 2 - Option A), Exposed Person fuzzy matching, and Global Sanctions Data fuzzy matching with accuracy scoring from enhanced screening view (302_CRMA_sanctions_screening.sql). Enables AUM tracking, advisor performance measurement, engagement scoring, churn prediction, and comprehensive compliance screening for holistic customer risk assessment and relationship management.'
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
    
    -- Advisor Assignment
    adv_assign.ADVISOR_EMPLOYEE_ID AS CURRENT_ADVISOR_EMPLOYEE_ID,
    adv_assign.ASSIGNMENT_START_DATE AS ADVISOR_ASSIGNMENT_START_DATE,
    
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
    
    -- Sanctions Matching (Global Sanctions Data) - Fuzzy matching against external database
    -- Sanctions Screening Results (from enhanced screening view)
    sanctions.ENTITY_ID AS SANCTIONS_MATCH_ID,
    sanctions.ENTITY_NAME AS SANCTIONS_MATCH_NAME,
    sanctions.AUTHORITY AS SANCTIONS_AUTHORITY,
    sanctions.LIST_NAME AS SANCTIONS_LIST,
    sanctions.SANCTIONS_PROGRAM AS SANCTIONS_PROGRAM,
    sanctions.SANCTIONS_RISK_SCORE AS SANCTIONS_RISK_SCORE,
    sanctions.MATCH_TYPE AS SANCTIONS_MATCH_TYPE_DETAIL,
    sanctions.MATCH_SCORE AS SANCTIONS_MATCH_SCORE,
    sanctions.MATCH_CONFIDENCE AS SANCTIONS_MATCH_CONFIDENCE,
    sanctions.DISPOSITION_RECOMMENDATION AS SANCTIONS_DISPOSITION,
    sanctions.ALERT_PRIORITY AS SANCTIONS_ALERT_PRIORITY,
    sanctions.DOB_MATCH AS SANCTIONS_DOB_MATCH,
    sanctions.NATIONALITY_MATCH AS SANCTIONS_NATIONALITY_MATCH,
    
    -- Sanctions Match Accuracy Level
    -- Sanctions Match Accuracy (from enhanced screening view - already calculated)
    sanctions.MATCH_SCORE AS SANCTIONS_MATCH_ACCURACY_PERCENT,
    
    -- Sanctions Match Type (from enhanced screening view)
    COALESCE(sanctions.MATCH_TYPE, 'NO_MATCH') AS SANCTIONS_MATCH_TYPE,
    
    -- Old sanctions columns for backwards compatibility
    CASE WHEN sanctions.MATCH_TYPE = 'EXACT_MATCH' THEN sanctions.ENTITY_ID ELSE NULL END AS SANCTIONS_EXACT_MATCH_ID,
    CASE WHEN sanctions.MATCH_TYPE = 'EXACT_MATCH' THEN sanctions.ENTITY_NAME ELSE NULL END AS SANCTIONS_EXACT_MATCH_NAME,
    NULL AS SANCTIONS_EXACT_MATCH_TYPE,  -- Not available in new sanctions view
    NULL AS SANCTIONS_EXACT_MATCH_COUNTRY,  -- Not available in new sanctions view
    CASE WHEN sanctions.MATCH_TYPE IN ('FUZZY_MATCH', 'ALIAS_MATCH') THEN sanctions.ENTITY_ID ELSE NULL END AS SANCTIONS_FUZZY_MATCH_ID,
    CASE WHEN sanctions.MATCH_TYPE IN ('FUZZY_MATCH', 'ALIAS_MATCH') THEN sanctions.ENTITY_NAME ELSE NULL END AS SANCTIONS_FUZZY_MATCH_NAME,
    NULL AS SANCTIONS_FUZZY_MATCH_TYPE,  -- Not available in new sanctions view
    NULL AS SANCTIONS_FUZZY_MATCH_COUNTRY,  -- Not available in new sanctions view
    
    -- PEP and Sanctions Overall Risk
    CASE 
        WHEN pep_exact.RISK_LEVEL = 'CRITICAL' OR pep_fuzzy.RISK_LEVEL = 'CRITICAL' THEN 'CRITICAL'
        WHEN pep_exact.RISK_LEVEL = 'HIGH' OR pep_fuzzy.RISK_LEVEL = 'HIGH' THEN 'HIGH'
        WHEN pep_exact.RISK_LEVEL = 'MEDIUM' OR pep_fuzzy.RISK_LEVEL = 'MEDIUM' THEN 'MEDIUM'
        WHEN pep_exact.RISK_LEVEL = 'LOW' OR pep_fuzzy.RISK_LEVEL = 'LOW' THEN 'LOW'
        ELSE 'NO_EXPOSED_PERSON_RISK'
    END AS OVERALL_EXPOSED_PERSON_RISK,
    
    CASE 
        WHEN sanctions.ENTITY_ID IS NOT NULL THEN 'CRITICAL'
        ELSE 'NO_SANCTIONS_RISK'
    END AS OVERALL_SANCTIONS_RISK,
    
    -- Overall Risk Rating (combines PEP, sanctions, and anomalies)
    CASE 
        -- CRITICAL: Any sanctions match OR (PEP CRITICAL + anomaly)
        WHEN sanctions.ENTITY_ID IS NOT NULL THEN 'CRITICAL'
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
        WHEN sanctions.ENTITY_ID IS NOT NULL THEN 100
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
        WHEN sanctions.ENTITY_ID IS NOT NULL THEN TRUE 
        ELSE FALSE 
    END AS REQUIRES_SANCTIONS_REVIEW,
    
    CASE 
        WHEN c.HAS_ANOMALY = TRUE AND (pep_exact.EXPOSED_PERSON_ID IS NOT NULL OR pep_fuzzy.EXPOSED_PERSON_ID IS NOT NULL OR sanctions.ENTITY_ID IS NOT NULL) THEN TRUE
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
LEFT JOIN ACCA_AGG_DT_ACCOUNTS acc
    ON c.CUSTOMER_ID = acc.CUSTOMER_ID

-- Join account balances (Phase 1 Enhancement) - for balance metrics
LEFT JOIN PAY_AGG_001.PAYA_AGG_DT_ACCOUNT_BALANCES bal
    ON c.CUSTOMER_ID = bal.CUSTOMER_ID

-- Join transactions (Phase 2 Enhancement - Option A: Direct Cross-Schema Join)
-- Note: PAYI_RAW_TB_TRANSACTIONS has ACCOUNT_ID, not CUSTOMER_ID, so we join through accounts
LEFT JOIN PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS txn
    ON acc.ACCOUNT_ID = txn.ACCOUNT_ID

-- Join current advisor assignment (for relationship management)
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT adv_assign
    ON c.CUSTOMER_ID = adv_assign.CUSTOMER_ID
    AND adv_assign.IS_CURRENT = TRUE

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

-- Sanctions matching using enhanced screening view (302_CRMA_sanctions_screening.sql)
-- This view combines exact matches, fuzzy matches (EDITDISTANCE <= 5), and alias matches
-- with risk scoring, confidence classification, and disposition recommendations
LEFT JOIN CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING sanctions
    ON c.CUSTOMER_ID = sanctions.CUSTOMER_ID

GROUP BY 
    c.CUSTOMER_ID, c.FIRST_NAME, c.FAMILY_NAME, c.FULL_NAME, c.DATE_OF_BIRTH, c.ONBOARDING_DATE, c.REPORTING_CURRENCY, c.HAS_ANOMALY,
    c.EMPLOYER, c.POSITION, c.EMPLOYMENT_TYPE, c.INCOME_RANGE, c.ACCOUNT_TIER, c.EMAIL, c.PHONE, c.PREFERRED_CONTACT_METHOD, c.RISK_CLASSIFICATION, c.CREDIT_SCORE_BAND,
    addr.STREET_ADDRESS, addr.CITY, addr.STATE, addr.ZIPCODE, addr.COUNTRY, addr.CURRENT_FROM,
    status.STATUS, status.STATUS_START_DATE,
    adv_assign.ADVISOR_EMPLOYEE_ID, adv_assign.ASSIGNMENT_START_DATE,
    pep_exact.EXPOSED_PERSON_ID, pep_exact.FULL_NAME, pep_exact.EXPOSED_PERSON_CATEGORY, pep_exact.RISK_LEVEL, pep_exact.STATUS,
    pep_fuzzy.EXPOSED_PERSON_ID, pep_fuzzy.FULL_NAME, pep_fuzzy.FIRST_NAME, pep_fuzzy.LAST_NAME, pep_fuzzy.EXPOSED_PERSON_CATEGORY, pep_fuzzy.RISK_LEVEL, pep_fuzzy.STATUS,
    sanctions.ENTITY_ID, sanctions.ENTITY_NAME, sanctions.AUTHORITY, sanctions.LIST_NAME, sanctions.SANCTIONS_PROGRAM,
    sanctions.SANCTIONS_RISK_SCORE, sanctions.MATCH_TYPE, sanctions.MATCH_SCORE, sanctions.MATCH_CONFIDENCE,
    sanctions.DISPOSITION_RECOMMENDATION, sanctions.ALERT_PRIORITY, sanctions.DOB_MATCH, sanctions.NATIONALITY_MATCH

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
