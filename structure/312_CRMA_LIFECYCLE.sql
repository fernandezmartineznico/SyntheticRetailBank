-- ============================================================
-- CRM_AGG_001 Schema - Customer Lifecycle Analytics & Churn Prediction
-- Created on: 2025-10-11
-- ============================================================
--
-- OVERVIEW:
-- This schema provides customer lifecycle analytics combining event history,
-- status transitions, and behavioral patterns for churn prediction and
-- lifecycle management.
--
-- BUSINESS PURPOSE:
-- - Customer lifecycle stage classification (NEW/ACTIVE/MATURE/DECLINING/DORMANT/CHURNED)
-- - Churn probability scoring based on transaction activity patterns
-- - Lifecycle event tracking and analysis
-- - At-risk customer identification for retention campaigns
-- - Dormancy detection and monitoring
--
-- DATA SOURCES:
-- - CRM_RAW_001.CRMI_RAW_TB_CUSTOMER: Customer master data
-- - CRM_RAW_001.CRMI_RAW_TB_CUSTOMER_STATUS: Status history (SCD Type 2)
-- - CRM_RAW_001.CRMI_RAW_TB_CUSTOMER_EVENT: Lifecycle events log
-- - PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS: Transaction activity for dormancy analysis
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (1):
-- │  └─ CRMA_AGG_DT_CUSTOMER_LIFECYCLE  - Customer lifecycle metrics and churn prediction
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (consistent with system schedule)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes
--
-- LIFECYCLE STAGES:
-- - NEW: < 90 days since onboarding
-- - ACTIVE: Recent transactions, normal activity
-- - MATURE: > 365 days since onboarding, steady activity
-- - DECLINING: > 90 days since last transaction, at-risk
-- - DORMANT: > 180 days since last transaction
-- - CHURNED: Status = CLOSED
--
-- CHURN PROBABILITY MODEL:
-- Based on transaction inactivity (NOT lifecycle events):
-- - CLOSED status: 100%
-- - No transactions > 1 year: 95%
-- - No transactions > 180 days (DORMANT): 75%
-- - No transactions > 90 days (AT RISK): 45%
-- - Account closure events: 60%
-- - Default: 10%
--
-- IMPORTANT NOTES:
-- - Dormant customers have NO lifecycle events by definition
-- - Churn prediction uses transaction patterns, not event frequency
-- - ADDRESS_CHANGE events are derived from address_update_generator.py
-- - Lifecycle events are for active engagement tracking only
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- CRMA_AGG_DT_CUSTOMER_LIFECYCLE - Customer Lifecycle Analytics
-- ============================================================
-- Comprehensive lifecycle view combining event history, status transitions,
-- and behavioral patterns for churn prediction and lifecycle management.
-- Integrates customer status, lifecycle events, and transaction activity
-- to classify customers by lifecycle stage and calculate churn probability.

CREATE OR REPLACE DYNAMIC TABLE CRMA_AGG_DT_CUSTOMER_LIFECYCLE(
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier',
    FIRST_NAME VARCHAR(100) COMMENT 'Customer first name',
    FAMILY_NAME VARCHAR(100) COMMENT 'Customer family name',
    ONBOARDING_DATE DATE COMMENT 'Original onboarding date',
    CURRENT_STATUS VARCHAR(30) COMMENT 'Current customer status',
    STATUS_SINCE DATE COMMENT 'Date when current status started',
    DAYS_IN_CURRENT_STATUS NUMBER(10,0) COMMENT 'Number of days in current status',
    TOTAL_LIFECYCLE_EVENTS NUMBER(10,0) COMMENT 'Total number of lifecycle events',
    LAST_EVENT_DATE DATE COMMENT 'Date of most recent lifecycle event',
    LAST_EVENT_TYPE VARCHAR(30) COMMENT 'Type of most recent lifecycle event',
    DAYS_SINCE_LAST_EVENT NUMBER(10,0) COMMENT 'Days since last lifecycle event',
    ADDRESS_CHANGES NUMBER(10,0) COMMENT 'Number of address changes',
    EMPLOYMENT_CHANGES NUMBER(10,0) COMMENT 'Number of employment changes',
    ACCOUNT_UPGRADES NUMBER(10,0) COMMENT 'Number of account upgrades',
    ACCOUNT_DOWNGRADES NUMBER(10,0) COMMENT 'Number of account downgrades',
    ACCOUNT_CLOSURES NUMBER(10,0) COMMENT 'Number of account closures',
    REACTIVATIONS NUMBER(10,0) COMMENT 'Number of reactivations',
    IS_DORMANT BOOLEAN COMMENT 'Flag indicating dormant customer (no activity > 180 days)',
    IS_AT_RISK BOOLEAN COMMENT 'Flag indicating at-risk customer (reduced activity, early churn indicators)',
    CHURN_PROBABILITY NUMBER(5,2) COMMENT 'Calculated churn probability percentage (0-100)',
    LIFECYCLE_STAGE VARCHAR(30) COMMENT 'Lifecycle stage (NEW/ACTIVE/MATURE/DECLINING/DORMANT/CHURNED)',
    LAST_TRANSACTION_DATE DATE COMMENT 'Date of most recent transaction (from PAY_RAW_001)',
    DAYS_SINCE_LAST_TRANSACTION NUMBER(10,0) COMMENT 'Days since last transaction',
    LAST_UPDATED TIMESTAMP_NTZ COMMENT 'Timestamp when record was last refreshed'
) COMMENT = 'Customer lifecycle analytics view combining event history, status transitions, and behavioral patterns for churn prediction and lifecycle management. Provides lifecycle stage classification, churn probability scoring, and at-risk customer identification for retention campaigns.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    c.CUSTOMER_ID,
    c.FIRST_NAME,
    c.FAMILY_NAME,
    c.ONBOARDING_DATE,
    
    -- Current Status
    s.STATUS AS CURRENT_STATUS,
    s.STATUS_START_DATE AS STATUS_SINCE,
    DATEDIFF(DAY, s.STATUS_START_DATE, CURRENT_DATE()) AS DAYS_IN_CURRENT_STATUS,
    
    -- Event Statistics
    COUNT(DISTINCT e.EVENT_ID) AS TOTAL_LIFECYCLE_EVENTS,
    MAX(e.EVENT_DATE) AS LAST_EVENT_DATE,
    MAX(e.EVENT_TYPE) AS LAST_EVENT_TYPE,
    DATEDIFF(DAY, MAX(e.EVENT_DATE), CURRENT_DATE()) AS DAYS_SINCE_LAST_EVENT,
    
    -- Event Type Counts
    COUNT(DISTINCT CASE WHEN e.EVENT_TYPE = 'ADDRESS_CHANGE' THEN e.EVENT_ID END) AS ADDRESS_CHANGES,
    COUNT(DISTINCT CASE WHEN e.EVENT_TYPE = 'EMPLOYMENT_CHANGE' THEN e.EVENT_ID END) AS EMPLOYMENT_CHANGES,
    COUNT(DISTINCT CASE WHEN e.EVENT_TYPE = 'ACCOUNT_UPGRADE' THEN e.EVENT_ID END) AS ACCOUNT_UPGRADES,
    COUNT(DISTINCT CASE WHEN e.EVENT_TYPE = 'ACCOUNT_DOWNGRADE' THEN e.EVENT_ID END) AS ACCOUNT_DOWNGRADES,
    COUNT(DISTINCT CASE WHEN e.EVENT_TYPE = 'ACCOUNT_CLOSE' THEN e.EVENT_ID END) AS ACCOUNT_CLOSURES,
    COUNT(DISTINCT CASE WHEN e.EVENT_TYPE = 'REACTIVATION' THEN e.EVENT_ID END) AS REACTIVATIONS,
    
    -- Risk Flags
    CASE WHEN DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) > 180 THEN TRUE ELSE FALSE END AS IS_DORMANT,
    CASE WHEN DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) > 90 AND s.STATUS = 'ACTIVE' THEN TRUE ELSE FALSE END AS IS_AT_RISK,
    
    -- Churn Probability (simplified model based on transaction activity, NOT lifecycle events)
    -- Note: Dormant customers have NO lifecycle events by definition, so we use transaction patterns
    CASE 
        WHEN s.STATUS = 'CLOSED' THEN 100.0
        WHEN DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) > 365 THEN 95.0  -- No transactions > 1 year
        WHEN DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) > 180 THEN 75.0  -- No transactions > 6 months (DORMANT)
        WHEN DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) > 90 THEN 45.0   -- No transactions > 3 months (AT RISK)
        WHEN COUNT(DISTINCT CASE WHEN e.EVENT_TYPE = 'ACCOUNT_CLOSE' THEN e.EVENT_ID END) > 0 THEN 60.0
        ELSE 10.0
    END AS CHURN_PROBABILITY,
    
    -- Lifecycle Stage
    CASE 
        WHEN s.STATUS = 'CLOSED' THEN 'CHURNED'
        WHEN DATEDIFF(DAY, c.ONBOARDING_DATE, CURRENT_DATE()) < 90 THEN 'NEW'
        WHEN DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) > 180 THEN 'DORMANT'
        WHEN DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) > 90 THEN 'DECLINING'
        WHEN DATEDIFF(DAY, c.ONBOARDING_DATE, CURRENT_DATE()) >= 365 THEN 'MATURE'
        ELSE 'ACTIVE'
    END AS LIFECYCLE_STAGE,
    
    -- Transaction Activity
    MAX(t.BOOKING_DATE) AS LAST_TRANSACTION_DATE,
    DATEDIFF(DAY, MAX(t.BOOKING_DATE), CURRENT_DATE()) AS DAYS_SINCE_LAST_TRANSACTION,
    
    CURRENT_TIMESTAMP() AS LAST_UPDATED

FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER c

-- Join current status
LEFT JOIN CRM_RAW_001.CRMI_RAW_TB_CUSTOMER_STATUS s
    ON c.CUSTOMER_ID = s.CUSTOMER_ID
    AND s.IS_CURRENT = TRUE

-- Join lifecycle events
LEFT JOIN CRM_RAW_001.CRMI_RAW_TB_CUSTOMER_EVENT e
    ON c.CUSTOMER_ID = e.CUSTOMER_ID

-- Join accounts to connect customer to transactions
LEFT JOIN CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS a
    ON c.CUSTOMER_ID = a.CUSTOMER_ID

-- Join transaction data for activity analysis
LEFT JOIN PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS t
    ON a.ACCOUNT_ID = t.ACCOUNT_ID

GROUP BY 
    c.CUSTOMER_ID, c.FIRST_NAME, c.FAMILY_NAME, c.ONBOARDING_DATE,
    s.STATUS, s.STATUS_START_DATE

ORDER BY c.CUSTOMER_ID;

-- ============================================================
-- CRM_AGG_001 Lifecycle Schema Setup Complete!
-- ============================================================
--
-- DYNAMIC TABLE REFRESH STATUS:
-- The lifecycle dynamic table will automatically refresh based on changes to
-- source tables (CRMI_RAW_TB_CUSTOMER, CRMI_RAW_TB_CUSTOMER_STATUS, CRMI_RAW_TB_CUSTOMER_EVENT,
-- PAYI_RAW_TB_TRANSACTIONS) with a 1-hour target lag.
--
-- USAGE EXAMPLES:
--
-- 1. Find at-risk customers for retention campaigns:
--    SELECT CUSTOMER_ID, FULL_NAME, CHURN_PROBABILITY, LIFECYCLE_STAGE
--    FROM CRMA_AGG_DT_CUSTOMER_LIFECYCLE
--    WHERE IS_AT_RISK = TRUE
--    ORDER BY CHURN_PROBABILITY DESC;
--
-- 2. Identify dormant customers:
--    SELECT CUSTOMER_ID, FULL_NAME, DAYS_SINCE_LAST_TRANSACTION, LAST_EVENT_TYPE
--    FROM CRMA_AGG_DT_CUSTOMER_LIFECYCLE
--    WHERE IS_DORMANT = TRUE
--    ORDER BY DAYS_SINCE_LAST_TRANSACTION DESC;
--
-- 3. Lifecycle stage distribution:
--    SELECT LIFECYCLE_STAGE, COUNT(*) AS CUSTOMER_COUNT,
--           ROUND(AVG(CHURN_PROBABILITY), 2) AS AVG_CHURN_PROB
--    FROM CRMA_AGG_DT_CUSTOMER_LIFECYCLE
--    GROUP BY LIFECYCLE_STAGE
--    ORDER BY AVG_CHURN_PROB DESC;
--
-- 4. Event activity analysis:
--    SELECT CUSTOMER_ID, FULL_NAME, TOTAL_LIFECYCLE_EVENTS,
--           ADDRESS_CHANGES, EMPLOYMENT_CHANGES, ACCOUNT_UPGRADES, ACCOUNT_DOWNGRADES
--    FROM CRMA_AGG_DT_CUSTOMER_LIFECYCLE
--    WHERE TOTAL_LIFECYCLE_EVENTS > 3
--    ORDER BY TOTAL_LIFECYCLE_EVENTS DESC;
--
-- 5. Churn prediction for closed customers:
--    SELECT CUSTOMER_ID, FULL_NAME, CURRENT_STATUS, STATUS_SINCE,
--           DAYS_IN_CURRENT_STATUS, LAST_EVENT_TYPE
--    FROM CRMA_AGG_DT_CUSTOMER_LIFECYCLE
--    WHERE LIFECYCLE_STAGE = 'CHURNED'
--    ORDER BY STATUS_SINCE DESC;
--
-- To check dynamic table refresh status:
-- SHOW DYNAMIC TABLES IN SCHEMA AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001;
--
-- To manually refresh the dynamic table:
-- ALTER DYNAMIC TABLE CRMA_AGG_DT_CUSTOMER_LIFECYCLE REFRESH;
--
-- ============================================================
-- 312_CRMA_LIFECYCLE.sql - Customer Lifecycle Analytics completed!
-- ============================================================

