-- ============================================================
-- LOA_RAW_v001 Schema - Loan & Document Processing (Raw Data Layer)
-- Generated on: 2025-10-04
-- ============================================================
--
-- OVERVIEW:
-- This schema provides the foundational raw data layer for loan applications,
-- mortgage documentation, and related document processing. It handles the ingestion
-- and storage of email communications and PDF documents for downstream processing
-- and business intelligence using DocAI capabilities.
--
-- BUSINESS PURPOSE:
-- - Document ingestion for loan applications and mortgage processing
-- - Email communication tracking and analysis
-- - PDF document storage for contract analysis and compliance
-- - Foundation for downstream loan processing, risk assessment, and analytics
-- - Support for document intelligence and automated content extraction
--
-- SUPPORTED DOCUMENT TYPES:
-- - Email Files: Customer inquiries, loan applications, internal communications
-- - PDF Documents: Loan agreements, mortgage contracts, financial statements
-- - Future extensibility for additional document types and formats
--
-- OBJECTS CREATED:
-- ┌─ STAGES (2):
-- │  ├─ LOAI_RAW_STAGE_EMAIL_INBOUND     - Email files for DocAI processing
-- │  └─ LOAI_RAW_STAGE_PDF_INBOUND       - PDF documents for DocAI processing
-- │
-- ├─ TABLES (2):
-- │  ├─ LOAI_RAW_TB_EMAILS            - Raw email storage with metadata
-- │  └─ LOAI_RAW_TB_DOCUMENTS         - Raw PDF document storage with metadata
-- │
-- ├─ STREAMS (2):
-- │  ├─ LOAI_RAW_STREAM_EMAIL_FILES    - Email file arrival detection
-- │  └─ LOAI_RAW_STREAM_PDF_FILES      - PDF file arrival detection
-- │
-- └─ TASKS (2):
--    ├─ LOAI_RAW_TASK_LOAD_EMAILS      - Automated email ingestion
--    └─ LOAI_TASK_LOAD_DOCUMENTS   - Automated PDF ingestion
--
-- DATA ARCHITECTURE:
-- Email files → LOAI_RAW_STAGE_EMAIL_INBOUND → Stream Detection → Automated Task → Raw Table → DocAI Processing
-- PDF documents → LOAI_RAW_STAGE_PDF_INBOUND → Stream Detection → Automated Task → Raw Table → DocAI Processing
--
-- PROCESSING PATTERNS:
-- - Email Files: *.eml, *.msg, *.mbox for DocAI content extraction
-- - PDF Documents: *.pdf for DocAI intelligent document analysis
-- - Metadata capture (filename, load timestamp) for data lineage and audit
-- - Error handling with ON_ERROR = CONTINUE for resilient processing
-- - Stream-based triggering for near real-time processing efficiency
-- - DocAI integration for automated document intelligence and content extraction
--
-- RELATED SCHEMAS:
-- - LOA_AGG_v001: Loan analytics and business logic transformation
-- - REP_AGG_001: Analytics and reporting data products
-- - CRM_RAW_001: Customer data for loan applicant identification
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

-- ============================================================
-- LOA_RAW_v001 SCHEMA - Raw Loan Documents
-- ============================================================

USE SCHEMA LOA_RAW_v001;

-- ============================================================
-- INTERNAL STAGES - Document Landing Areas
-- ============================================================
-- Secure internal stages for loan-related document ingestion with
-- directory listing enabled for automated file discovery and DocAI integration.

-- Stage for inbound email files (DocAI processing)
CREATE OR REPLACE STAGE LOAI_RAW_STAGE_EMAIL_INBOUND
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Staging area for loan-related email files awaiting DocAI processing and analysis. Supports various email formats (.eml, .msg, .mbox) for document intelligence extraction, content analysis, and automated loan application processing workflows. Directory listing enabled for batch processing and monitoring of email document ingestion.';

-- Stage for inbound PDF documents (DocAI processing)
CREATE OR REPLACE STAGE LOAI_RAW_STAGE_PDF_INBOUND
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Staging area for loan-related PDF documents awaiting DocAI processing and intelligent document analysis. Handles mortgage applications, loan agreements, contracts, financial statements, and regulatory filings for automated content extraction, classification, and data mining. Directory listing enabled for batch processing and document workflow management.';

-- ============================================================
-- TABLES - Raw Document Storage
-- ============================================================
-- Persistent storage for raw loan-related documents with metadata
-- for audit trails, compliance, and downstream processing requirements.

-- ============================================================
-- LOAI_RAW_TB_EMAILS TABLE - Raw Email Repository
-- ============================================================
-- Central repository for all inbound loan-related email communications with
-- comprehensive metadata capture for operational monitoring and compliance.

CREATE OR REPLACE TABLE LOAI_RAW_TB_EMAILS (
    FILE_NAME   STRING COMMENT 'Original source file name for audit trail, correlation with loan applications, and operational troubleshooting. Enables traceability back to customer communications and case management systems.',
    LOAD_TS     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'System ingestion timestamp for data lineage tracking, SLA monitoring, and processing performance analysis. Critical for operational dashboards and customer service response time tracking.',
    RAW_CONTENT VARIANT COMMENT 'Complete email content preserved as VARIANT for flexible schema evolution, compliance archival, and comprehensive downstream parsing. Supports all email formats with full fidelity preservation for DocAI processing.'
)
COMMENT = 'Master repository for raw loan-related email communications supporting mortgage and loan application processing. Stores customer inquiries, application submissions, internal communications, and loan officer correspondence. Provides foundation for downstream DocAI processing, customer service analytics, compliance analysis, and audit trail maintenance. Optimized for document intelligence workflows with comprehensive metadata capture.';

-- ============================================================
-- LOAI_RAW_TB_DOCUMENTS TABLE - Raw PDF Document Repository
-- ============================================================
-- Central repository for all inbound loan-related PDF documents with
-- comprehensive metadata capture for operational monitoring and compliance.

CREATE OR REPLACE TABLE LOAI_RAW_TB_DOCUMENTS (
    FILE_NAME   STRING COMMENT 'Original source file name for audit trail, correlation with loan applications, and document management. Enables traceability back to source systems and document version control.',
    LOAD_TS     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'System ingestion timestamp for data lineage tracking, SLA monitoring, and processing performance analysis. Critical for operational dashboards and regulatory reporting timelines.',
    RAW_CONTENT VARIANT COMMENT 'Complete PDF document content preserved as VARIANT for flexible schema evolution, compliance archival, and comprehensive downstream parsing. Supports DocAI intelligent document processing with full content preservation.'
)
COMMENT = 'Master repository for raw loan-related PDF documents supporting mortgage and loan application processing. Stores loan agreements, mortgage contracts, financial statements, credit reports, and regulatory filings. Provides foundation for downstream DocAI processing, automated data extraction, compliance analysis, and audit trail maintenance. Optimized for intelligent document analysis workflows with comprehensive metadata capture.';

-- ============================================================
-- STREAMS - File Arrival Detection
-- ============================================================
-- Change data capture streams for automated detection of new document
-- arrivals, enabling near real-time processing and operational efficiency.

-- Stream to detect new email files arriving on the stage
CREATE OR REPLACE STREAM LOAI_RAW_STREAM_EMAIL_FILES
ON STAGE LOAI_RAW_STAGE_EMAIL_INBOUND
COMMENT = 'Change data capture stream for automated detection of new email files arriving on the inbound stage. Triggers downstream processing tasks for near real-time document ingestion and DocAI analysis. Essential for operational SLA compliance and timely loan application processing.';

-- Stream to detect new PDF files arriving on the stage
CREATE OR REPLACE STREAM LOAI_RAW_STREAM_PDF_FILES
ON STAGE LOAI_RAW_STAGE_PDF_INBOUND
COMMENT = 'Change data capture stream for automated detection of new PDF documents arriving on the inbound stage. Triggers downstream processing tasks for near real-time document ingestion and DocAI intelligent analysis. Essential for operational SLA compliance and timely loan document processing.';

-- ============================================================
-- TASKS - Automated Document Processing
-- ============================================================
-- Scheduled tasks for automated document ingestion with stream-based
-- triggering for efficient resource utilization and near real-time processing.

-- Task to automatically load new email files
CREATE OR REPLACE TASK LOAI_RAW_TASK_LOAD_EMAILS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('LOAI_RAW_STREAM_EMAIL_FILES')
    -- Automated email ingestion task with stream-based triggering for efficient
    -- processing of loan-related communications. Executes every 60 minutes with
    -- serverless compute and conditional execution based on file arrival detection.
AS
    COPY INTO LOAI_RAW_TB_EMAILS (FILE_NAME, RAW_CONTENT)
    FROM (
        SELECT 
            METADATA$FILENAME AS FILE_NAME,          -- Capture original filename for audit trail
            TO_VARIANT($1) AS RAW_CONTENT            -- Store content as VARIANT for flexible processing
        FROM @LOAI_RAW_STAGE_EMAIL_INBOUND
    )
    PATTERN = '.*\.(eml|msg|mbox)'                   -- Process common email file formats
    ON_ERROR = CONTINUE;                             -- Continue processing on individual file errors for resilience

-- Task to automatically load new PDF documents
CREATE OR REPLACE TASK LOAI_TASK_LOAD_DOCUMENTS
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('LOAI_RAW_STREAM_PDF_FILES')
    -- Automated PDF document ingestion task with stream-based triggering for
    -- efficient processing of loan-related documents. Executes every 60 minutes
    -- with serverless compute and conditional execution based on file arrival detection.
AS
    COPY INTO LOAI_RAW_TB_DOCUMENTS (FILE_NAME, RAW_CONTENT)
    FROM (
        SELECT 
            METADATA$FILENAME AS FILE_NAME,          -- Capture original filename for audit trail
            TO_VARIANT($1) AS RAW_CONTENT            -- Store content as VARIANT for DocAI processing
        FROM @LOAI_RAW_STAGE_PDF_INBOUND
    )
    PATTERN = '.*\.pdf'                              -- Process PDF documents
    ON_ERROR = CONTINUE;                             -- Continue processing on individual file errors for resilience

-- Activate the tasks for production operations
ALTER TASK LOAI_RAW_TASK_LOAD_EMAILS RESUME;
ALTER TASK LOAI_TASK_LOAD_DOCUMENTS RESUME;

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ LOA_RAW_v001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 2 Stages: LOAI_RAW_STAGE_EMAIL_INBOUND (emails), LOAI_RAW_STAGE_PDF_INBOUND (PDFs)
-- • 2 Tables: LOAI_RAW_TB_EMAILS (email repository), LOAI_RAW_TB_DOCUMENTS (PDF repository)
-- • 2 Streams: LOAI_RAW_STREAM_EMAIL_FILES, LOAI_RAW_STREAM_PDF_FILES (file arrival detection)
-- • 2 Tasks: LOAI_RAW_TASK_LOAD_EMAILS, LOAI_TASK_LOAD_DOCUMENTS (automated ingestion - ACTIVE)
--
-- NEXT STEPS:
-- 1. ✅ LOA_RAW_v001 schema deployed successfully
-- 2. Upload email files to stage: PUT file://*.eml @LOAI_RAW_STAGE_EMAIL_INBOUND;
-- 3. Upload PDF documents to stage: PUT file://*.pdf @LOAI_RAW_STAGE_PDF_INBOUND;
-- 4. Monitor task execution: SHOW TASKS IN SCHEMA LOA_RAW_v001;
-- 5. Verify document loading: SELECT COUNT(*) FROM LOAI_RAW_TB_EMAILS; SELECT COUNT(*) FROM LOAI_RAW_TB_DOCUMENTS;
-- 6. Deploy LOA_AGG_v001 schema for loan analytics and business logic
--
-- USAGE EXAMPLES:
-- -- Upload email files for DocAI processing
-- PUT file://customer_inquiry_20250928.eml @LOAI_RAW_STAGE_EMAIL_INBOUND;
-- PUT file://loan_application_20250928.msg @LOAI_RAW_STAGE_EMAIL_INBOUND;
--
-- -- Upload PDF documents for DocAI processing
-- PUT file://mortgage_application_Q3_2025.pdf @LOAI_RAW_STAGE_PDF_INBOUND;
-- PUT file://loan_agreement_20250928.pdf @LOAI_RAW_STAGE_PDF_INBOUND;
--
-- -- Monitor email ingestion
-- SELECT FILE_NAME, LOAD_TS 
-- FROM LOAI_RAW_TB_EMAILS 
-- ORDER BY LOAD_TS DESC LIMIT 10;
--
-- -- Monitor document ingestion
-- SELECT FILE_NAME, LOAD_TS 
-- FROM LOAI_RAW_TB_DOCUMENTS 
-- ORDER BY LOAD_TS DESC LIMIT 10;
--
-- MONITORING:
-- - Task status: SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) WHERE NAME IN ('LOAI_RAW_TASK_LOAD_EMAILS', 'LOAI_TASK_LOAD_DOCUMENTS');
-- - Stream status: SHOW STREAMS IN SCHEMA LOA_RAW_v001;
-- - Stage contents: LIST @LOAI_RAW_STAGE_EMAIL_INBOUND; LIST @LOAI_RAW_STAGE_PDF_INBOUND;
-- - DocAI processing status: Monitor file counts and processing workflows for email and PDF stages
--
-- PERFORMANCE OPTIMIZATION:
-- - Monitor warehouse usage during peak document processing periods
-- - Consider clustering on LOAD_TS for time-based queries
-- - Archive old documents based on regulatory retention requirements
-- - Implement DocAI workflows for automated content extraction
-- ============================================================

