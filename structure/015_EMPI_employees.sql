-- ============================================================
-- CRM_RAW_001 Schema - Employee Hierarchy & Client Assignments
-- Generated on: 2025-12-19
-- ============================================================
--
-- OVERVIEW:
-- This schema contains employee master data and client-advisor assignment tracking
-- for the synthetic EMEA retail bank. Implements a dynamic 3-tier hierarchy that
-- scales automatically based on customer distribution across 12 EMEA countries.
--
-- HIERARCHY STRUCTURE:
-- - Super Team Leaders (top level, typically 1 for up to 100 team leaders)
-- - Team Leaders (middle level, managing up to 10 client advisors each)
-- - Client Advisors (front-line, handling up to 200 clients each per country)
--
-- DATA ARCHITECTURE:
-- - Employee data with hierarchical manager relationships
-- - Client assignment tracking with SCD Type 2 support (assignment history)
-- - Country-based advisor assignments for localized customer service
-- - Performance tracking with ratings, languages, and certifications
-- - Automated loading via streams and serverless tasks
-- - Customer relationship validated via joins (no FK due to CRMI_RAW_TB_CUSTOMER SCD Type 2 structure)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (2):
-- │  ├─ EMPI_RAW_STAGE_EMPLOYEES           - Employee master data files
-- │  └─ EMPI_RAW_STAGE_CLIENT_ASSIGNMENTS  - Client-advisor assignment files
-- │
-- ┌─ FILE FORMATS (2):
-- │  ├─ EMPI_FF_EMPLOYEE_CSV     - Employee CSV format
-- │  └─ EMPI_FF_ASSIGNMENT_CSV   - Assignment CSV format
-- │
-- ┌─ TABLES (2):
-- │  ├─ EMPI_RAW_TB_EMPLOYEE            - Employee master data with hierarchy
-- │  └─ EMPI_RAW_TB_CLIENT_ASSIGNMENT   - Client-advisor relationships (SCD Type 2 ready)
-- │
-- ┌─ STREAMS (2):
-- │  ├─ EMPI_RAW_STREAM_EMPLOYEE_FILES     - Detects new employee files
-- │  └─ EMPI_RAW_STREAM_ASSIGNMENT_FILES   - Detects new assignment files
-- │
-- └─ TASKS (2 - All Serverless):
--    ├─ EMPI_RAW_TASK_LOAD_EMPLOYEES       - Automated employee loading
--    └─ EMPI_RAW_TASK_LOAD_ASSIGNMENTS     - Automated assignment loading
--
-- RELATED SCHEMAS:
-- - CRM_AGG_001 - Employee analytics views and hierarchy aggregations
-- - CRM_RAW_001 - Customer master data for assignment relationships
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_RAW_001;

-- ============================================================
-- SECTION 1: INTERNAL STAGES
-- ============================================================
-- Internal stages for CSV file ingestion with directory listing enabled
-- for automated file detection via streams.

-- Employee master data stage
CREATE OR REPLACE STAGE EMPI_RAW_STAGE_EMPLOYEES
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for employee master data CSV files. Expected pattern: *employees*.csv';

-- Client-advisor assignment stage
CREATE OR REPLACE STAGE EMPI_RAW_STAGE_CLIENT_ASSIGNMENTS
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for client-advisor assignment CSV files. Expected pattern: *client_assignments*.csv';

-- ============================================================
-- SECTION 2: FILE FORMATS
-- ============================================================
-- Standardized CSV file formats for consistent data ingestion.

-- Employee master data CSV format
CREATE OR REPLACE FILE FORMAT EMPI_FF_EMPLOYEE_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"'
    COMMENT = 'CSV format for employee master data with EMEA localization - PARSE_HEADER handles header row';

-- Client-advisor assignment CSV format
CREATE OR REPLACE FILE FORMAT EMPI_FF_ASSIGNMENT_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    PARSE_HEADER = TRUE
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    REPLACE_INVALID_CHARACTERS = TRUE
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD"T"HH24:MI:SS.FF"Z"'
    COMMENT = 'CSV format for client-advisor assignments with SCD Type 2 support - PARSE_HEADER handles header row';

-- ============================================================
-- SECTION 3: BASE TABLES
-- ============================================================

-- Employee master data table with hierarchical structure
CREATE OR REPLACE TABLE EMPI_RAW_TB_EMPLOYEE (
    -- Identity & Contact Information
    EMPLOYEE_ID VARCHAR(20) NOT NULL,                    -- Unique employee identifier for HR systems and reporting
    FIRST_NAME VARCHAR(100),                             -- Employee's given name for personalization and communication
    FAMILY_NAME VARCHAR(100),                            -- Employee's surname for formal identification and reporting
    EMAIL VARCHAR(200),                                  -- Corporate email address for business communication and system access
    PHONE VARCHAR(50),                                   -- Direct contact number for client escalations and internal coordination
    
    -- Employment Details
    DATE_OF_BIRTH DATE,                                  -- Birth date for compliance, benefits eligibility, and retirement planning
    HIRE_DATE DATE,                                      -- Employment start date for tenure tracking and anniversary recognition
    EMPLOYMENT_STATUS VARCHAR(20),                       -- Current work status (ACTIVE, ON_LEAVE, TERMINATED) for resource planning and capacity management
    
    -- Geographic & Office Assignment
    COUNTRY VARCHAR(50),                                 -- Primary work country for regulatory compliance and local market expertise
    OFFICE_LOCATION VARCHAR(200),                        -- Physical office address for client meetings and team coordination
    REGION VARCHAR(50),                                  -- Geographic region (NORDIC, CENTRAL_EUROPE, WESTERN_EUROPE, SOUTHERN_EUROPE, EMEA) for regional reporting and strategy
    
    -- Organizational Hierarchy
    POSITION_LEVEL VARCHAR(30),                          -- Role in hierarchy (CLIENT_ADVISOR, TEAM_LEADER, SUPER_TEAM_LEADER) for reporting lines and responsibilities
    MANAGER_EMPLOYEE_ID VARCHAR(20),                     -- Direct manager's employee ID for escalation paths and performance reviews
    
    -- Performance & Capabilities
    PERFORMANCE_RATING DECIMAL(3,2),                     -- Annual performance score (0.00-5.00) for compensation, promotions, and client assignment decisions
    LANGUAGES_SPOKEN VARCHAR(200),                       -- Spoken languages for international client service and cross-border collaboration
    CERTIFICATIONS VARCHAR(500),                         -- Professional certifications (CFP, CFA, etc.) for compliance requirements and client confidence
    
    -- System Metadata
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ,                  -- Data ingestion timestamp for audit trails and data lineage tracking
    
    PRIMARY KEY (EMPLOYEE_ID),
    CONSTRAINT FK_EMPI_MANAGER FOREIGN KEY (MANAGER_EMPLOYEE_ID) REFERENCES EMPI_RAW_TB_EMPLOYEE(EMPLOYEE_ID)
)
COMMENT = 'Employee master data with 3-tier hierarchy (advisors, team leaders, super team leaders). Scales dynamically based on customer distribution.';

-- Client-advisor assignment table (SCD Type 2 ready)
CREATE OR REPLACE TABLE EMPI_RAW_TB_CLIENT_ASSIGNMENT (
    -- Assignment Identity & Relationships
    ASSIGNMENT_ID VARCHAR(30) NOT NULL,                  -- Unique assignment record identifier for tracking relationship history
    CUSTOMER_ID VARCHAR(30) NOT NULL,                    -- Customer being served - links to CRMI_RAW_TB_CUSTOMER for 360° view
    ADVISOR_EMPLOYEE_ID VARCHAR(20) NOT NULL,            -- Assigned client advisor - must be POSITION_LEVEL='CLIENT_ADVISOR'
    
    -- Assignment Timeline & History
    ASSIGNMENT_START_DATE DATE,                          -- Relationship start date for tenure tracking and service quality metrics
    ASSIGNMENT_END_DATE DATE,                            -- Relationship end date (NULL for active assignments) - enables historical analysis
    IS_CURRENT BOOLEAN DEFAULT TRUE,                     -- Active assignment flag for quick filtering of current relationships
    
    -- Assignment Context & Reasoning
    ASSIGNMENT_REASON VARCHAR(50),                       -- Assignment trigger (INITIAL_ONBOARDING, TRANSFER, ESCALATION, REBALANCING) for audit and pattern analysis
    
    -- System Metadata
    INSERT_TIMESTAMP_UTC TIMESTAMP_NTZ,                  -- Record creation timestamp for SCD Type 2 tracking and audit compliance
    
    PRIMARY KEY (ASSIGNMENT_ID),

    FOREIGN KEY (ADVISOR_EMPLOYEE_ID) REFERENCES EMPI_RAW_TB_EMPLOYEE(EMPLOYEE_ID)
)
COMMENT = 'Client-advisor assignment tracking with history support (SCD Type 2 ready). Tracks customer-advisor relationships over time. CUSTOMER_ID references CRMI_RAW_TB_CUSTOMER but FK not enforced due to SCD Type 2 composite key.';

-- ============================================================
-- SECTION 4: STREAMS FOR CHANGE DATA CAPTURE
-- ============================================================
-- Streams monitor stage directories for new files and trigger automated loading.

-- Stream to detect new employee files
CREATE OR REPLACE STREAM EMPI_RAW_STREAM_EMPLOYEE_FILES
    ON STAGE EMPI_RAW_STAGE_EMPLOYEES
    COMMENT = 'Monitors EMPI_RAW_STAGE_EMPLOYEES stage for new employee data files';

-- Stream to detect new assignment files
CREATE OR REPLACE STREAM EMPI_RAW_STREAM_ASSIGNMENT_FILES
    ON STAGE EMPI_RAW_STAGE_CLIENT_ASSIGNMENTS
    COMMENT = 'Monitors EMPI_RAW_STAGE_CLIENT_ASSIGNMENTS stage for new assignment files';

-- ============================================================
-- SECTION 5: SERVERLESS TASKS FOR AUTOMATED LOADING
-- ============================================================
-- Tasks automatically load data when streams detect new files.

-- Task: Load employee data
CREATE OR REPLACE TASK EMPI_RAW_TASK_LOAD_EMPLOYEES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
WHEN
    SYSTEM$STREAM_HAS_DATA('EMPI_RAW_STREAM_EMPLOYEE_FILES')
AS
    COPY INTO EMPI_RAW_TB_EMPLOYEE
    FROM @EMPI_RAW_STAGE_EMPLOYEES
    FILE_FORMAT = (FORMAT_NAME = 'EMPI_FF_EMPLOYEE_CSV')
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
    ON_ERROR = 'CONTINUE';

-- Resume task to enable automatic execution
ALTER TASK EMPI_RAW_TASK_LOAD_EMPLOYEES RESUME;

-- Task: Load client-advisor assignments
CREATE OR REPLACE TASK EMPI_RAW_TASK_LOAD_ASSIGNMENTS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
WHEN
    SYSTEM$STREAM_HAS_DATA('EMPI_RAW_STREAM_ASSIGNMENT_FILES')
AS
    COPY INTO EMPI_RAW_TB_CLIENT_ASSIGNMENT
    FROM @EMPI_RAW_STAGE_CLIENT_ASSIGNMENTS
    FILE_FORMAT = (FORMAT_NAME = 'EMPI_FF_ASSIGNMENT_CSV')
    MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE
    ON_ERROR = 'CONTINUE';

-- Resume task to enable automatic execution
ALTER TASK EMPI_RAW_TASK_LOAD_ASSIGNMENTS RESUME;

-- ============================================================
-- SECTION 6: DATA SENSITIVITY TAGGING
-- ============================================================
-- Apply sensitivity tags for data protection and access control.

-- Tag employee PII columns as RESTRICTED
ALTER TABLE EMPI_RAW_TB_EMPLOYEE MODIFY COLUMN FIRST_NAME 
    SET TAG SENSITIVITY_LEVEL = 'restricted';
    
ALTER TABLE EMPI_RAW_TB_EMPLOYEE MODIFY COLUMN FAMILY_NAME 
    SET TAG SENSITIVITY_LEVEL = 'restricted';

ALTER TABLE EMPI_RAW_TB_EMPLOYEE MODIFY COLUMN EMAIL 
    SET TAG SENSITIVITY_LEVEL = 'restricted';

ALTER TABLE EMPI_RAW_TB_EMPLOYEE MODIFY COLUMN PHONE 
    SET TAG SENSITIVITY_LEVEL = 'restricted';

ALTER TABLE EMPI_RAW_TB_EMPLOYEE MODIFY COLUMN DATE_OF_BIRTH 
    SET TAG SENSITIVITY_LEVEL = 'restricted';

-- Tag full employee identity as TOP_SECRET (for masking policies)
ALTER TABLE EMPI_RAW_TB_EMPLOYEE MODIFY COLUMN OFFICE_LOCATION 
    SET TAG SENSITIVITY_LEVEL = 'top_secret';

-- ============================================================
-- TASK ACTIVATION
-- ============================================================
-- Tasks are created in SUSPENDED state. Resume them to enable automated loading.

-- To activate automated loading, run:
-- ALTER TASK EMPI_RAW_TASK_LOAD_EMPLOYEES RESUME;
-- ALTER TASK EMPI_RAW_TASK_LOAD_ASSIGNMENTS RESUME;

-- To suspend tasks:
-- ALTER TASK EMPI_RAW_TASK_LOAD_EMPLOYEES SUSPEND;
-- ALTER TASK EMPI_RAW_TASK_LOAD_ASSIGNMENTS SUSPEND;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================
-- Use these queries to verify data loading and hierarchy integrity.

-- Check employee counts by level
-- SELECT 
--     POSITION_LEVEL,
--     COUNT(*) as EMPLOYEE_COUNT
-- FROM EMPI_RAW_TB_EMPLOYEE
-- GROUP BY POSITION_LEVEL
-- ORDER BY 
--     CASE POSITION_LEVEL 
--         WHEN 'SUPER_TEAM_LEADER' THEN 1
--         WHEN 'TEAM_LEADER' THEN 2
--         WHEN 'CLIENT_ADVISOR' THEN 3
--     END;

-- Verify hierarchy relationships
-- SELECT 
--     e.EMPLOYEE_ID,
--     e.FIRST_NAME || ' ' || e.FAMILY_NAME as EMPLOYEE_NAME,
--     e.POSITION_LEVEL,
--     e.MANAGER_EMPLOYEE_ID,
--     m.FIRST_NAME || ' ' || m.FAMILY_NAME as MANAGER_NAME,
--     m.POSITION_LEVEL as MANAGER_LEVEL
-- FROM EMPI_RAW_TB_EMPLOYEE e
-- LEFT JOIN EMPI_RAW_TB_EMPLOYEE m ON e.MANAGER_EMPLOYEE_ID = m.EMPLOYEE_ID
-- ORDER BY e.EMPLOYEE_ID;

-- Check clients per advisor
-- SELECT 
--     a.ADVISOR_EMPLOYEE_ID,
--     e.FIRST_NAME || ' ' || e.FAMILY_NAME as ADVISOR_NAME,
--     e.COUNTRY,
--     COUNT(DISTINCT a.CUSTOMER_ID) as CLIENT_COUNT
-- FROM EMPI_RAW_TB_CLIENT_ASSIGNMENT a
-- JOIN EMPI_RAW_TB_EMPLOYEE e ON a.ADVISOR_EMPLOYEE_ID = e.EMPLOYEE_ID
-- WHERE a.IS_CURRENT = TRUE
-- GROUP BY a.ADVISOR_EMPLOYEE_ID, e.FIRST_NAME, e.FAMILY_NAME, e.COUNTRY
-- ORDER BY CLIENT_COUNT DESC;

-- Verify customer references are valid (join to current customer view)
-- SELECT 
--     a.ASSIGNMENT_ID,
--     a.CUSTOMER_ID,
--     c.FIRST_NAME || ' ' || c.FAMILY_NAME as CUSTOMER_NAME,
--     a.ADVISOR_EMPLOYEE_ID,
--     e.FIRST_NAME || ' ' || e.FAMILY_NAME as ADVISOR_NAME
-- FROM EMPI_RAW_TB_CLIENT_ASSIGNMENT a
-- LEFT JOIN CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT c 
--     ON a.CUSTOMER_ID = c.CUSTOMER_ID
-- LEFT JOIN EMPI_RAW_TB_EMPLOYEE e 
--     ON a.ADVISOR_EMPLOYEE_ID = e.EMPLOYEE_ID
-- WHERE a.IS_CURRENT = TRUE
--     AND (c.CUSTOMER_ID IS NULL OR e.EMPLOYEE_ID IS NULL)  -- Find orphaned records
-- LIMIT 10;

-- ============================================================
-- DEPLOYMENT COMPLETE
-- ============================================================
-- Employee master data and client assignment tables are ready.
-- 
-- IMPORTANT: Deploy 010_CRMI_customer_master.sql BEFORE this file
-- (EMPI_RAW_TB_CLIENT_ASSIGNMENT references CRMI_RAW_TB_CUSTOMER, validated via joins)
--
-- Next steps:
-- 1. Upload employee CSV files to @EMPI_RAW_STAGE_EMPLOYEES stage
-- 2. Upload assignment CSV files to @EMPI_RAW_STAGE_CLIENT_ASSIGNMENTS stage
-- 3. Resume tasks to enable automated loading
-- 4. Deploy aggregation views (415_EMPA_employee_analytics.sql)
-- 5. Validate customer references using verification queries above
-- ============================================================

