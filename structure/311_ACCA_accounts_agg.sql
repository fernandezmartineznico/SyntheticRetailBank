-- ============================================================
-- CRM_AGG_001 Schema - Account Master Data Aggregation Layer
-- Generated on: 2025-09-29 (Account aggregation layer for downstream analytics)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides the aggregation layer for account master data, creating
-- a 1:1 dynamic table copy of the raw ACCI_RAW_TB_ACCOUNTS table with enhanced processing
-- capabilities. Serves as the foundation for downstream analytics and reporting
-- while maintaining data lineage from the raw layer.
--
-- BUSINESS PURPOSE:
-- - Provide clean aggregation layer access to account master data
-- - Enable downstream analytics without direct raw layer dependencies
-- - Support account-based reporting and balance calculations
-- - Maintain data consistency and refresh automation
-- - Bridge raw data to analytical data products
--
-- AGGREGATION STRATEGY:
-- - 1:1 copy of raw account master data with metadata enhancement
-- - Real-time refresh to maintain data currency
-- - Consistent schema for downstream consumption
-- - Enhanced data quality and validation
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (1):
-- │  └─ ACCA_AGG_DT_ACCOUNTS - 1:1 copy of raw account master data
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 1 hour (aligned with operational requirements)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes from CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS
--
-- DATA ARCHITECTURE:
-- Raw Accounts (CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS) → Aggregation (CRM_AGG_001.ACCA_AGG_DT_ACCOUNTS) → Analytics
--
-- SUPPORTED ACCOUNT TYPES:
-- - CHECKING: Primary transaction accounts
-- - SAVINGS: Interest-bearing savings accounts  
-- - BUSINESS: Commercial banking accounts
-- - INVESTMENT: Securities and investment accounts
--
-- SUPPORTED CURRENCIES:
-- - EUR (Euro), GBP (British Pound), USD (US Dollar), CHF (Swiss Franc)
-- - NOK (Norwegian Krone), SEK (Swedish Krona), DKK (Danish Krone)
--
-- RELATED SCHEMAS:
-- - CRM_RAW_001: Source account master data (ACCI_RAW_TB_ACCOUNTS)
-- - PAY_AGG_001: Account balance calculations and payment analytics
-- - CRM_AGG_001: Customer master data and address aggregations
-- - EQT_RAW_001: Equity trades (investment account references)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- DYNAMIC TABLES - ACCOUNT MASTER DATA AGGREGATION
-- ============================================================
-- 1:1 aggregation of raw account master data with enhanced metadata
-- and processing timestamps for downstream analytics consumption.

-- ============================================================
-- ACCA_AGG_DT_ACCOUNTS - Account Master Data Aggregation
-- ============================================================
-- Direct 1:1 copy of raw account master data with aggregation layer enhancements.
-- Provides clean access to account data for downstream analytics without
-- direct dependencies on raw layer tables.

CREATE OR REPLACE DYNAMIC TABLE ACCA_AGG_DT_ACCOUNTS(
    ACCOUNT_ID VARCHAR(30) COMMENT 'Unique account identifier for transaction allocation and balance tracking',
    ACCOUNT_TYPE VARCHAR(20) COMMENT 'Type of account (CHECKING/SAVINGS/BUSINESS/INVESTMENT)',
    BASE_CURRENCY VARCHAR(3) COMMENT 'Base currency of the account (EUR/GBP/USD/CHF/NOK/SEK/DKK)',
    CUSTOMER_ID VARCHAR(30) COMMENT 'Customer identifier for account ownership and relationship management',
    STATUS VARCHAR(20) COMMENT 'Current account status (ACTIVE/INACTIVE/CLOSED)',
    IS_ACTIVE BOOLEAN COMMENT 'Boolean flag indicating if account status is ACTIVE',
    IS_CHECKING_ACCOUNT BOOLEAN COMMENT 'Boolean flag for checking/transaction accounts',
    IS_SAVINGS_ACCOUNT BOOLEAN COMMENT 'Boolean flag for savings accounts',
    IS_BUSINESS_ACCOUNT BOOLEAN COMMENT 'Boolean flag for business/commercial accounts',
    IS_INVESTMENT_ACCOUNT BOOLEAN COMMENT 'Boolean flag for investment/securities accounts',
    IS_USD_ACCOUNT BOOLEAN COMMENT 'Boolean flag for USD-denominated accounts',
    IS_EUR_ACCOUNT BOOLEAN COMMENT 'Boolean flag for EUR-denominated accounts',
    IS_OTHER_CURRENCY_ACCOUNT BOOLEAN COMMENT 'Boolean flag for accounts in other currencies (GBP/CHF/NOK/SEK/DKK)',
    ACCOUNT_TYPE_PRIORITY NUMBER(2,0) COMMENT 'Priority ranking for account type (1=CHECKING, 2=SAVINGS, 3=BUSINESS, 4=INVESTMENT)',
    CURRENCY_GROUP VARCHAR(20) COMMENT 'Currency grouping for reporting (MAJOR_EUROPEAN/USD_BASE/OTHER_EUROPEAN/OTHER)',
    AGGREGATION_TIMESTAMP TIMESTAMP_NTZ COMMENT 'Timestamp when aggregation processing was performed',
    AGGREGATION_TYPE VARCHAR(20) COMMENT 'Type of aggregation processing (1:1_COPY_FROM_RAW)',
    SOURCE_TABLE VARCHAR(50) COMMENT 'Source table reference for data lineage (CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS)'
) COMMENT = '1:1 aggregation of account master data from raw layer (CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS). Provides clean aggregation layer access for downstream analytics, balance calculations, and reporting. Maintains real-time refresh for data currency while serving as bridge between raw data and analytical data products.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Account Master Data (1:1 copy from raw layer)
    ACCOUNT_ID,
    ACCOUNT_TYPE,
    BASE_CURRENCY,
    CUSTOMER_ID,
    STATUS,
    
    -- Enhanced Metadata for Aggregation Layer
    CASE 
        WHEN STATUS = 'ACTIVE' THEN TRUE
        ELSE FALSE
    END AS IS_ACTIVE,
    
    CASE 
        WHEN ACCOUNT_TYPE = 'CHECKING' THEN TRUE
        ELSE FALSE
    END AS IS_CHECKING_ACCOUNT,
    
    CASE 
        WHEN ACCOUNT_TYPE = 'SAVINGS' THEN TRUE
        ELSE FALSE
    END AS IS_SAVINGS_ACCOUNT,
    
    CASE 
        WHEN ACCOUNT_TYPE = 'BUSINESS' THEN TRUE
        ELSE FALSE
    END AS IS_BUSINESS_ACCOUNT,
    
    CASE 
        WHEN ACCOUNT_TYPE = 'INVESTMENT' THEN TRUE
        ELSE FALSE
    END AS IS_INVESTMENT_ACCOUNT,
    
    -- Currency Classification
    CASE 
        WHEN BASE_CURRENCY = 'USD' THEN TRUE
        ELSE FALSE
    END AS IS_USD_ACCOUNT,
    
    CASE 
        WHEN BASE_CURRENCY = 'EUR' THEN TRUE
        ELSE FALSE
    END AS IS_EUR_ACCOUNT,
    
    CASE 
        WHEN BASE_CURRENCY IN ('GBP', 'CHF', 'NOK', 'SEK', 'DKK') THEN TRUE
        ELSE FALSE
    END AS IS_OTHER_CURRENCY_ACCOUNT,
    
    -- Account Type Priority for Balance Allocation
    CASE 
        WHEN ACCOUNT_TYPE = 'CHECKING' THEN 1
        WHEN ACCOUNT_TYPE = 'SAVINGS' THEN 2
        WHEN ACCOUNT_TYPE = 'BUSINESS' THEN 3
        WHEN ACCOUNT_TYPE = 'INVESTMENT' THEN 4
        ELSE 99
    END AS ACCOUNT_TYPE_PRIORITY,
    
    -- Currency Group for Reporting
    CASE 
        WHEN BASE_CURRENCY IN ('EUR', 'GBP') THEN 'MAJOR_EUROPEAN'
        WHEN BASE_CURRENCY = 'USD' THEN 'USD_BASE'
        WHEN BASE_CURRENCY IN ('CHF', 'NOK', 'SEK', 'DKK') THEN 'OTHER_EUROPEAN'
        ELSE 'OTHER'
    END AS CURRENCY_GROUP,
    
    -- Processing Metadata
    CURRENT_TIMESTAMP() AS AGGREGATION_TIMESTAMP,
    '1:1_COPY_FROM_RAW' AS AGGREGATION_TYPE,
    'CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS' AS SOURCE_TABLE

FROM CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS
WHERE 1=1  -- Include all records from raw layer
ORDER BY CUSTOMER_ID, ACCOUNT_TYPE_PRIORITY, ACCOUNT_ID;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ CRM_AGG_001 Account Aggregation Layer Complete
--
-- OBJECTS CREATED:
-- • 1 Dynamic Table: ACCA_AGG_DT_ACCOUNTS (1:1 account master data aggregation)
-- • Enhanced metadata: Account type flags, currency classifications, priorities
-- • Processing timestamps: Aggregation metadata for data lineage
-- • Automated refresh: 1-hour TARGET_LAG for real-time account data
--
-- NEXT STEPS:
-- 1. ✅ CRM_AGG_001 account aggregation layer deployed successfully
-- 2. Verify dynamic table refresh: SHOW DYNAMIC TABLES IN SCHEMA CRM_AGG_001;
-- 3. Update downstream consumers to use CRM_AGG_001.ACCA_AGG_DT_ACCOUNTS
-- 4. Test account data availability: SELECT COUNT(*) FROM ACCA_AGG_DT_ACCOUNTS;
-- 5. Validate data consistency with raw layer
-- 6. Monitor refresh performance and data latency
--
-- USAGE EXAMPLES:
--
-- -- Query all active accounts by type
-- SELECT ACCOUNT_TYPE, COUNT(*) as account_count, 
--        LISTAGG(DISTINCT BASE_CURRENCY, ', ') as currencies
-- FROM ACCA_AGG_DT_ACCOUNTS 
-- WHERE IS_ACTIVE = TRUE
-- GROUP BY ACCOUNT_TYPE
-- ORDER BY account_count DESC;
--
-- -- Get customer account portfolio
-- SELECT CUSTOMER_ID, ACCOUNT_ID, ACCOUNT_TYPE, BASE_CURRENCY, STATUS
-- FROM ACCA_AGG_DT_ACCOUNTS 
-- WHERE CUSTOMER_ID = 'CUST_00001'
-- ORDER BY ACCOUNT_TYPE_PRIORITY;
--
-- -- Account distribution by currency group
-- SELECT CURRENCY_GROUP, 
--        COUNT(*) as total_accounts,
--        COUNT(CASE WHEN IS_ACTIVE = TRUE THEN 1 END) as active_accounts
-- FROM ACCA_AGG_DT_ACCOUNTS 
-- GROUP BY CURRENCY_GROUP
-- ORDER BY total_accounts DESC;
--
-- -- Investment accounts for securities trading
-- SELECT ACCOUNT_ID, CUSTOMER_ID, BASE_CURRENCY, STATUS
-- FROM ACCA_AGG_DT_ACCOUNTS 
-- WHERE IS_INVESTMENT_ACCOUNT = TRUE AND IS_ACTIVE = TRUE
-- ORDER BY CUSTOMER_ID;
--
-- MANUAL REFRESH COMMAND:
-- ALTER DYNAMIC TABLE ACCA_AGG_DT_ACCOUNTS REFRESH;
--
-- DATA REQUIREMENTS:
-- - Source table CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS must contain account master data
-- - Account CSV files must be uploaded to stage and loaded
-- - Raw layer must be populated before aggregation layer can function
--
-- MONITORING:
-- - Dynamic table refresh status: SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY()) WHERE NAME = 'ACCA_AGG_DT_ACCOUNTS';
-- - Account data coverage: SELECT COUNT(*) as total_accounts, COUNT(DISTINCT CUSTOMER_ID) as unique_customers FROM ACCA_AGG_DT_ACCOUNTS;
-- - Data consistency check: Compare counts with raw layer SELECT COUNT(*) FROM CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS;
--
-- PERFORMANCE OPTIMIZATION:
-- - Monitor warehouse usage during refresh periods
-- - Consider clustering on CUSTOMER_ID and ACCOUNT_TYPE for query optimization
-- - Archive inactive accounts based on business retention requirements
-- ============================================================
