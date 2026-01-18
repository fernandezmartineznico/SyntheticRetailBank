-- ============================================================
-- Synthetic Banking - Database Setup
-- Generated on: 2025-09-22 15:50:17
-- Updated: 2025-10-04 (Schema consolidation and serverless tasks)
-- Updated: 2025-01-22 (Added MD_TEST_WH warehouse for development)
-- ============================================================
--
-- This script creates the database, warehouse, and schemas for the
-- synthetic EMEA retail bank data generator.
--
-- INFRASTRUCTURE CREATED:
--   • Database: AAA_DEV_SYNTHETIC_BANK - Main development database
--   • Warehouse: MD_TEST_WH - X-SMALL warehouse for development and testing
--
-- SCHEMAS CREATED:
-- RAW Layer (Data Ingestion):
--   • CMD_RAW_001 - Commodity trades (energy, metals, agricultural)
--   • CRM_RAW_001 - Customer master data, addresses, accounts, PEP data
--   • EQT_RAW_001 - Equity trading data (FIX protocol)
--   • FII_RAW_001 - Fixed income trades (bonds and interest rate swaps)
--   • LOA_RAW_001 - Loan information and mortgage data
--   • PAY_RAW_001 - Payment transactions + SWIFT ISO20022 messages
--   • REF_RAW_001 - Reference data (FX rates, lookup tables)
--   • REP_RAW_001 - Regulatory reporting raw data (HQLA holdings, deposit balances)
--
-- AGGREGATION Layer (Business Logic):
--   • CMD_AGG_001 - Commodity analytics (delta risk, volatility, delivery tracking)
--   • CRM_AGG_001 - Customer 360° views, SCD Type 2 addresses
--   • EQT_AGG_001 - Equity trade analytics and portfolio positions
--   • FII_AGG_001 - Fixed income analytics (duration, DV01, credit risk)
--   • LOA_AGG_v001 - Loan analytics and reporting
--   • PAY_AGG_001 - Transaction anomalies, account balances, SWIFT message processing
--   • REF_AGG_001 - Enhanced FX rates with spreads
--
-- REPORTING Layer (Analytics & Regulatory):
--   • REP_AGG_001 - Regulatory reporting aggregations (FINMA LCR, BCBS239, FRTB market risk)

-- ============================================================

-- Create database
CREATE DATABASE IF NOT EXISTS AAA_DEV_SYNTHETIC_BANK
    COMMENT = 'Bank Development Database';

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

-- ============================================================
-- RAW LAYER SCHEMAS - Data Ingestion
-- ============================================================

CREATE SCHEMA IF NOT EXISTS CMD_RAW_001
    COMMENT = 'Commodity raw data schema for energy, metals, and agricultural trades';

CREATE SCHEMA IF NOT EXISTS CRM_RAW_001
    COMMENT = 'CRM raw data schema for customer/party information and accounts';

CREATE SCHEMA IF NOT EXISTS EQT_RAW_001
    COMMENT = 'Equity trading raw data schema for FIX protocol trades';

CREATE SCHEMA IF NOT EXISTS FII_RAW_001
    COMMENT = 'Fixed Income raw data schema for bonds and interest rate swaps';

CREATE SCHEMA IF NOT EXISTS LOA_RAW_001
    COMMENT = 'Loan raw data schema for loan information';

CREATE SCHEMA IF NOT EXISTS PAY_RAW_001
    COMMENT = 'Payment raw data schema for transaction information and SWIFT ISO20022 message storage';

CREATE SCHEMA IF NOT EXISTS REF_RAW_001
    COMMENT = 'Reference data schema for FX rates and other lookup tables';

CREATE SCHEMA IF NOT EXISTS REP_RAW_001
    COMMENT = 'Reporting raw data schema for regulatory submissions (FINMA LCR, BCBS239, HQLA holdings, deposit balances)';

-- ============================================================
-- AGGREGATION LAYER SCHEMAS - Business Logic
-- ============================================================

CREATE SCHEMA IF NOT EXISTS CMD_AGG_001
    COMMENT = 'Commodity aggregation schema for delta risk and volatility analytics';

CREATE SCHEMA IF NOT EXISTS CRM_AGG_001
    COMMENT = 'CRM aggregation data schema for customer/party information';

CREATE SCHEMA IF NOT EXISTS EQT_AGG_001
    COMMENT = 'Equity trading aggregation schema for trade analytics and portfolio positions';

CREATE SCHEMA IF NOT EXISTS FII_AGG_001
    COMMENT = 'Fixed Income aggregation schema for duration, DV01, and credit risk analytics';

CREATE SCHEMA IF NOT EXISTS LOA_AGG_001
    COMMENT = 'Loan aggregation schema for loan analytics and reporting';

CREATE SCHEMA IF NOT EXISTS PAY_AGG_001
    COMMENT = 'Payment aggregation schema for transaction analytics, anomaly detection, and SWIFT message processing';

CREATE SCHEMA IF NOT EXISTS REF_AGG_001
    COMMENT = 'Reference data aggregation schema for enhanced FX rates and analytics';

-- ============================================================
-- REPORTING LAYER SCHEMAS - Analytics & Regulatory
-- ============================================================

CREATE SCHEMA IF NOT EXISTS REP_AGG_001
    COMMENT = 'Reporting schema for raw data, aggregations, and analytics (FINMA LCR, BCBS239, FRTB)';


-- ============================================================
-- WAREHOUSE CREATION - Compute Resources for Development
-- ============================================================
-- Create X-SMALL warehouse optimized for development and testing
-- Features: Auto-suspend after 5 minutes, auto-resume on demand
-- Resource constraint: STANDARD_GEN_2 for optimal performance/cost balance

CREATE WAREHOUSE IF NOT EXISTS MD_TEST_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    WAREHOUSE_TYPE = 'STANDARD'
    RESOURCE_CONSTRAINT = 'STANDARD_GEN_2'
    AUTO_SUSPEND = 5
    AUTO_RESUME = true
    COMMENT = 'Development and testing warehouse - X-SMALL size with auto-suspend for cost optimization';

-- ============================================================
-- SENSITIVITY TAGS - Data Classification and Privacy Controls
-- ============================================================
-- Create sensitivity tags for column-level data protection and masking policies
-- These tags enable role-based access control and automated data masking

-- Create sensitivity tag in the PUBLIC schema for database-wide access
USE SCHEMA PUBLIC;
CREATE TAG IF NOT EXISTS SENSITIVITY_LEVEL
    COMMENT = 'Data sensitivity classification for privacy and compliance controls. Valid values: "restricted" (highly sensitive financial/PII data requiring strict access controls) | "top_secret" (maximum protection for personal identifiers and addresses). Used for automated masking policies and role-based access control.';

-- ============================================================
-- PERMISSION GRANTS - Database and Schema Access
-- ============================================================
-- Grant USAGE permissions to PUBLIC role for development and testing access
-- This enables all users to query data and run analytics

-- Grant database-level access
GRANT USAGE ON DATABASE AAA_DEV_SYNTHETIC_BANK TO ROLE PUBLIC;

-- Grant schema-level access for all RAW layer schemas
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.CMD_RAW_001 TO ROLE PUBLIC;
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.CRM_RAW_001 TO ROLE PUBLIC;
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.EQT_RAW_001 TO ROLE PUBLIC;
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.FII_RAW_001 TO ROLE PUBLIC;
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.LOA_RAW_001 TO ROLE PUBLIC;
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.PAY_RAW_001 TO ROLE PUBLIC;
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.REF_RAW_001 TO ROLE PUBLIC;
--GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_RAW_001 TO ROLE PUBLIC;

-- Grant schema-level access for all AGGREGATION layer schemas
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.CMD_AGG_001 TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001 TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.EQT_AGG_001 TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.FII_AGG_001 TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.LOA_AGG_001 TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001 TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.REF_AGG_001 TO ROLE PUBLIC;

-- Grant schema-level access for REPORTING layer schemas
GRANT USAGE ON SCHEMA AAA_DEV_SYNTHETIC_BANK.REP_AGG_001 TO ROLE PUBLIC;

-- ============================================================
