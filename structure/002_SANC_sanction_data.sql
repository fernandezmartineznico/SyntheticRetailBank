-- ============================================================
-- 002_sanction.sql - Sanctions Data Copy Database
-- Generated on: 2025-01-27
-- ============================================================
--
-- OVERVIEW:
-- This script creates a local copy database for Global Sanctions Data
-- to enable full ownership and control over sanctions data.
-- Combines database creation, table creation, and data population
-- into a single efficient operation.
--
-- BUSINESS PURPOSE:
-- - Create local copy of external sanctions data in one operation
-- - Enable staging table creation in owned database
-- - Provide full control over sanctions data management
-- - Support fuzzy matching and compliance screening
-- - Eliminate external database limitations
--
-- DATABASE STRUCTURE:
-- - Database: AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY
-- - Schema: PUBLIC
-- - Table: SANCTIONS_TB_DATA_STAGING (optimized for fuzzy matching)
-- ============================================================

-- ============================================================
-- CREATE COPY DATABASE AND POPULATE DATA
-- ============================================================
-- Create database with comment for documentation
CREATE OR REPLACE DATABASE AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY
COMMENT = 'HACK!!! Copy database for Global Sanctions Data becasue the is no data stream avaialable. table Contains local copy of external sanctions data for staging table creation and fuzzy matching capabilities.';

-- Switch to the new database and schema
USE DATABASE AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY;
USE SCHEMA PUBLIC;

-- Create and populate sanctions staging table in one efficient operation
-- This combines table creation and data population into a single statement
CREATE OR REPLACE TABLE PUBLIC.SANCTIONS_TB_DATA_STAGING AS
SELECT 
    ENTITY_ID,
    ENTITY_NAME,
    ENTITY_TYPE,
    COUNTRY,
    CURRENT_DATE as CREATED_DATE,
    CURRENT_TIMESTAMP as LAST_UPDATED
FROM AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET.GLOBAL_SANCTIONS_DATA.SANCTIONS_DATAFEED
WHERE ENTITY_TYPE = 'Individual';


-- ============================================================
-- SANCTIONS DATA COPY COMPLETE
-- ============================================================
