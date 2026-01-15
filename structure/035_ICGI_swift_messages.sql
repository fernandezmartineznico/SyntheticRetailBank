-- ============================================================
-- PAY_RAW_001 Schema - SWIFT ISO20022 Message Processing (Raw Data Layer)
-- Generated on: 2025-09-28 (Updated with comprehensive documentation)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides the foundational raw data layer for SWIFT ISO20022 message
-- processing within the Interbank Credit Gateway (ICG) clearing and settlement
-- operations. It handles the ingestion, parsing, and initial storage of XML-based
-- SWIFT messages for downstream processing and business intelligence.
--
-- BUSINESS PURPOSE:
-- - Real-time ingestion of SWIFT ISO20022 XML messages (PACS.008, PACS.002)
-- - Automated file processing with stream-based triggering for operational efficiency
-- - Raw message preservation for compliance, audit trails, and regulatory reporting
-- - Foundation for downstream payment processing, status tracking, and analytics
-- - Support for high-volume interbank clearing and settlement operations
--
-- SUPPORTED MESSAGE TYPES:
-- - PACS.008: FIToFICstmrCdtTrf (Customer Credit Transfer Instructions)
-- - PACS.002: FIToFIPmtStsRpt (Payment Status Reports and Acknowledgments)
-- - Future extensibility for additional ISO20022 message types (PACS.004, PACS.007, etc.)
--
-- OBJECTS CREATED:
-- ┌─ STAGES (1):
-- │  └─ ICGI_RAW_STAGE_SWIFT_INBOUND     - XML message landing area with directory listing
-- │
-- ├─ FILE FORMATS (1):
-- │  └─ ICGI_XML_FILE_FORMAT       - ISO20022 XML parsing configuration
-- │
-- ├─ TABLES (1):
-- │  └─ ICGI_RAW_TB_SWIFT_MESSAGES    - Raw XML message storage with metadata
-- │
-- ├─ STREAMS (1):
-- │  └─ ICGI_RAW_STREAM_SWIFT_FILES    - File arrival detection for automation
-- │
-- ├─ STORED PROCEDURES (1):
-- │  └─ PAYI_CLEANUP_STAGE_KEEP_LAST_N  - Generic stage cleanup utility (shared from 030_PAYI)
-- │
-- └─ TASKS (2 - All Serverless: 1 load + 1 cleanup):
--    ├─ ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES - Automated XML ingestion (60-minute schedule)
--    └─ ICGI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_SWIFT_MESSAGES - Stage cleanup
--
-- DATA ARCHITECTURE:
-- Raw XML files → ICGI_RAW_STAGE_SWIFT_INBOUND → Stream Detection → Automated Task → Raw Table → Downstream Processing
--
-- PROCESSING PATTERNS:
-- - SWIFT XML: *pacs008*.xml, *pacs002*.xml for message type identification
-- - Automatic XML parsing with PARSE_XML() for VARIANT storage
-- - Metadata capture (filename, load timestamp) for data lineage and audit
-- - Error handling with ON_ERROR = CONTINUE for resilient processing
-- - Stream-based triggering for near real-time processing efficiency
--
-- SUPPORTED COUNTRIES & CURRENCIES:
-- - All EMEA countries with SWIFT connectivity
-- - Multi-currency support (EUR, GBP, USD, CHF, NOK, SEK, DKK)
-- - TARGET2 and correspondent banking network compatibility
--
-- RELATED SCHEMAS:
-- - PAY_AGG_001: Message parsing and business logic transformation
-- - REP_AGG_001: Analytics and reporting data products
-- - CRM_RAW_001: Customer data for payment participant identification
-- - PAY_RAW_001: Domestic payment correlation and reconciliation
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;

USE SCHEMA PAY_RAW_001;

-- ============================================================
-- INTERNAL STAGES - File Landing Areas
-- ============================================================
-- Internal stages for XML file ingestion with directory listing enabled
-- for automated file detection via streams. All stages support PUT/GET
-- operations for manual file uploads and downloads.

-- SWIFT XML message data stage
CREATE STAGE IF NOT EXISTS ICGI_RAW_STAGE_SWIFT_INBOUND
    DIRECTORY = (
        ENABLE = TRUE
        AUTO_REFRESH = TRUE
    )
    COMMENT = 'Internal stage for SWIFT ISO20022 XML message files. Expected pattern: *.xml with PACS.008 and PACS.002 message types for interbank clearing operations';

-- ============================================================
-- FILE FORMATS - XML Processing Configuration
-- ============================================================
-- Specialized file format for SWIFT ISO20022 XML message parsing with
-- optimized settings for financial message processing and compliance requirements.

-- XML file format for SWIFT ISO20022 messages
CREATE OR REPLACE FILE FORMAT ICGI_XML_FILE_FORMAT
    TYPE = XML
    STRIP_OUTER_ELEMENT = TRUE
    COMMENT = 'Optimized XML file format for SWIFT ISO20022 message processing. Strips outer XML envelope for efficient VARIANT parsing of PACS.008 credit transfers and PACS.002 status reports. Supports multi-message files and preserves all ISO20022 schema elements for compliance and downstream analytics.';

-- ============================================================
-- MASTER DATA TABLES - SWIFT Message Information
-- ============================================================

-- ============================================================
-- ICGI_RAW_TB_SWIFT_MESSAGES - Raw XML Message Repository
-- ============================================================
-- Central repository for all inbound SWIFT ISO20022 XML messages with
-- comprehensive metadata capture for operational monitoring and compliance

CREATE OR REPLACE TABLE ICGI_RAW_TB_SWIFT_MESSAGES (
    FILE_NAME   STRING COMMENT 'Original source file name for audit trail, correlation with external systems, and operational troubleshooting. Enables traceability back to source systems and message routing verification.',
    LOAD_TS     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP COMMENT 'System ingestion timestamp for data lineage tracking, SLA monitoring, and processing performance analysis. Critical for operational dashboards and regulatory reporting timelines.',
    RAW_XML     VARIANT COMMENT 'Complete SWIFT ISO20022 XML message content preserved as VARIANT for flexible schema evolution, compliance archival, and comprehensive downstream parsing. Supports all current and future ISO20022 message types with full fidelity preservation.'
)
COMMENT = 'Master repository for raw SWIFT ISO20022 XML messages supporting interbank clearing and settlement operations. Stores PACS.008 customer credit transfer instructions, PACS.002 payment status reports, and future message types in native XML format. Provides foundation for downstream business logic processing, regulatory compliance analysis, operational monitoring, and audit trail maintenance. Optimized for high-volume message ingestion with comprehensive metadata capture.';

-- ============================================================
-- CHANGE DETECTION STREAMS - File Monitoring
-- ============================================================
-- Streams monitor stages for new files and trigger automated processing
-- tasks. Each stream detects specific file patterns and maintains change
-- tracking for reliable data pipeline processing.

-- SWIFT XML file detection stream
CREATE OR REPLACE STREAM ICGI_RAW_STREAM_SWIFT_FILES
    ON STAGE ICGI_RAW_STAGE_SWIFT_INBOUND
    COMMENT = 'Monitors ICGI_RAW_STAGE_SWIFT_INBOUND stage for new SWIFT ISO20022 XML files. Triggers ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES when files matching *.xml pattern are detected';

-- ============================================================
-- AUTOMATED PROCESSING TASKS - Data Pipeline Orchestration
-- ============================================================
-- Automated tasks triggered by stream data availability. All tasks run
-- on 1-hour schedule with stream-based triggering for efficient resource
-- usage. Error handling continues processing despite individual record failures.

-- SWIFT XML message loading task
CREATE OR REPLACE TASK ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    SCHEDULE = '60 MINUTE'
    WHEN SYSTEM$STREAM_HAS_DATA('ICGI_RAW_STREAM_SWIFT_FILES')
AS
    COPY INTO ICGI_RAW_TB_SWIFT_MESSAGES (FILE_NAME, RAW_XML)
    FROM (
        SELECT 
            METADATA$FILENAME AS FILE_NAME,          -- Capture original filename for audit trail
            PARSE_XML($1) AS RAW_XML                 -- Parse XML content into VARIANT for flexible processing
        FROM @ICGI_RAW_STAGE_SWIFT_INBOUND
    )
    PATTERN = '.*\.xml'                              -- Process all XML files regardless of naming convention
    FILE_FORMAT = ICGI_XML_FILE_FORMAT               -- Use optimized XML format for ISO20022 messages
    ON_ERROR = CONTINUE;                             -- Continue processing on individual file errors for resilience

-- ============================================================
-- TASK ACTIVATION - Enable Automated Processing
-- ============================================================
-- Tasks must be explicitly resumed to begin processing. This allows for
-- controlled deployment and testing before enabling automated data flows.

-- ============================================================
-- AUTOMATED STAGE CLEANUP TASKS
-- ============================================================
-- Cleanup tasks that run after data loading completes to manage
-- stage storage. Uses PAYI_CLEANUP_STAGE_KEEP_LAST_N procedure
-- defined in 030_PAYI_transactions.sql (same schema).

-- Cleanup task for SWIFT messages stage
CREATE OR REPLACE TASK ICGI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_SWIFT_MESSAGES
    USER_TASK_MANAGED_INITIAL_WAREHOUSE_SIZE = 'XSMALL'
    COMMENT = 'Automated stage cleanup after SWIFT message data load. Keeps last 5 files to manage storage costs.'
    AFTER ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES
AS
    CALL PAYI_CLEANUP_STAGE_KEEP_LAST_N('ICGI_RAW_STAGE_SWIFT_INBOUND', 5);

-- ============================================================
-- TASK ACTIVATION
-- ============================================================
-- Resume all tasks (load tasks must be resumed first, then cleanup tasks)

-- Resume child task before parent task
ALTER TASK ICGI_RAW_TASK_CLEANUP_STAGE_AFTER_LOAD_SWIFT_MESSAGES RESUME;
ALTER TASK ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES RESUME;

-- ============================================================
-- MANUAL LOADING EXAMPLES
-- ============================================================

-- Manual COPY INTO command for immediate loading of SWIFT XML files
-- Use this for one-time bulk loading or testing
/*
COPY INTO ICGI_RAW_TB_SWIFT_MESSAGES (FILE_NAME, RAW_XML)
FROM (
    SELECT 
        METADATA$FILENAME AS FILE_NAME,
        PARSE_XML($1) AS RAW_XML
    FROM @ICGI_RAW_STAGE_SWIFT_INBOUND_DEV
)
PATTERN = '.*\.(xml|XML)'
FILE_FORMAT = ICGI_XML_FILE_FORMAT
ON_ERROR = CONTINUE;

-- Check loaded data
SELECT 
    FILE_NAME,
    LOAD_TS,
    RAW_XML:"@xmlns"::STRING AS XML_NAMESPACE,
    RAW_XML:"Document":"*"[0] AS MESSAGE_TYPE
FROM ICGI_RAW_TB_SWIFT_MESSAGES 
ORDER BY LOAD_TS DESC
LIMIT 10;
*/

-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ PAY_RAW_001 Schema Deployment Complete
--
-- OBJECTS CREATED:
-- • 1 Stage: ICGI_RAW_STAGE_SWIFT_INBOUND (XML messages)
-- • 1 File Format: ICGI_XML_FILE_FORMAT (optimized ISO20022 XML parsing)
-- • 1 Table: ICGI_RAW_TB_SWIFT_MESSAGES (raw message repository with metadata)
-- • 1 Stream: ICGI_RAW_STREAM_SWIFT_FILES (file arrival detection for automation)
-- • 1 Task: ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES (automated ingestion - ACTIVE)
--
-- NEXT STEPS:
-- 1. ✅ PAY_RAW_001 schema deployed successfully
-- 2. Upload SWIFT ISO20022 XML files to stage: PUT file://*.xml @ICGI_RAW_STAGE_SWIFT_INBOUND;
-- 3. Monitor task execution: SHOW TASKS IN SCHEMA PAY_RAW_001;
-- 4. Verify message loading: SELECT COUNT(*) FROM ICGI_RAW_TB_SWIFT_MESSAGES;
-- 5. Check processing errors in task history and stream status
-- 6. Deploy PAY_AGG_001 schema for message parsing and business logic
--
-- USAGE EXAMPLES:
-- -- Upload SWIFT XML files
-- PUT file://pacs008_20250928_001.xml @ICGI_RAW_STAGE_SWIFT_INBOUND;
-- PUT file://pacs002_20250928_001.xml @ICGI_RAW_STAGE_SWIFT_INBOUND;
--
-- -- Monitor ingestion
-- SELECT FILE_NAME, LOAD_TS, LENGTH(RAW_XML::STRING) AS xml_size 
-- FROM ICGI_RAW_TB_SWIFT_MESSAGES 
-- ORDER BY LOAD_TS DESC LIMIT 10;
--
-- -- Check message types
-- SELECT 
--     FILE_NAME,
--     CASE 
--         WHEN RAW_XML::STRING ILIKE '%FIToFICstmrCdtTrf%' THEN 'PACS.008'
--         WHEN RAW_XML::STRING ILIKE '%FIToFIPmtStsRpt%' THEN 'PACS.002'
--         ELSE 'UNKNOWN'
--     END AS message_type,
--     COUNT(*) AS message_count
-- FROM ICGI_RAW_TB_SWIFT_MESSAGES 
-- GROUP BY FILE_NAME, message_type;
--
-- MONITORING:
-- - Task status: SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) WHERE NAME = 'ICGI_RAW_TASK_LOAD_SWIFT_MESSAGES';
-- - Stream status: SHOW STREAMS IN SCHEMA PAY_RAW_001;
-- - Stage contents: LIST @ICGI_RAW_STAGE_SWIFT_INBOUND;
--
-- PERFORMANCE OPTIMIZATION:
-- - Monitor warehouse usage during peak message processing periods
-- - Consider clustering on LOAD_TS for time-based queries
-- - Archive old messages based on regulatory retention requirements
-- ============================================================
