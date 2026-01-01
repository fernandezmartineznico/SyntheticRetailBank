-- ============================================================
-- PAY_AGG_001 Schema - SWIFT ISO20022 Message Aggregation & Business Logic
-- Generated on: 2025-09-28 (Updated with comprehensive documentation)
-- Updated: 2025-10-04 (Schema consolidation)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides the aggregation and business logic layer for SWIFT ISO20022
-- message processing, transforming raw XML messages into structured business data
-- for operational monitoring, compliance analysis, and regulatory reporting.
--
-- BUSINESS PURPOSE:
-- - Parse and structure SWIFT PACS.008 customer credit transfer instructions
-- - Process SWIFT PACS.002 payment status reports and acknowledgments
-- - Extract business-critical data elements for operational decision making
-- - Provide analytics-ready datasets for treasury management and risk assessment
-- - Enable real-time monitoring of payment flows and settlement status
-- - Support regulatory compliance and audit trail requirements
--
-- DATA TRANSFORMATION:
-- Raw XML (PAY_RAW_001) → Parsed Business Data → Analytics & Reporting (REP_AGG_001)
--
-- OBJECTS CREATED:
-- ┌─ DYNAMIC TABLES (3):
-- │  ├─ ICGA_AGG_DT_SWIFT_PACS008      - Parsed customer credit transfer instructions
-- │  ├─ ICGA_AGG_DT_SWIFT_PACS002      - Parsed payment status reports and acknowledgments
-- │  └─ ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE - Complete payment lifecycle (PACS008 + PACS002 joined)
-- │
-- └─ REFRESH STRATEGY:
--    ├─ TARGET_LAG: 60 minutes (aligned with operational SLA requirements)
--    ├─ WAREHOUSE: MD_TEST_WH
--    └─ AUTO-REFRESH: Based on source table changes from PAY_RAW_001
--
-- SUPPORTED MESSAGE TYPES:
-- - PACS.008.001.08: FIToFICstmrCdtTrf (Customer Credit Transfer)
-- - PACS.002.001.10: FIToFIPmtStsRpt (Payment Status Report)
-- - Future extensibility for additional ISO20022 payment message types
--
-- BUSINESS DATA ELEMENTS:
-- - Payment identification and routing information
-- - Debtor and creditor party details for compliance screening
-- - Settlement instructions and clearing system codes
-- - Amount, currency, and charges information
-- - Status codes and reason codes for operational monitoring
-- - Derived analytics fields for business intelligence
--
-- RELATED SCHEMAS:
-- - PAY_RAW_001: Source raw XML messages
-- - REP_AGG_001: Analytics and reporting data products
-- - CRM_RAW_001: Customer master data for party identification
-- - PAY_RAW_001: Domestic payment correlation and reconciliation
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA PAY_AGG_001;

-- ============================================================
-- DYNAMIC TABLES - SWIFT MESSAGE PARSING & BUSINESS LOGIC
-- ============================================================
-- Dynamic tables that automatically parse raw SWIFT ISO20022 XML messages
-- into structured business data with comprehensive field extraction and
-- derived analytics for operational monitoring and compliance reporting.

-- ============================================================
-- ICGA_AGG_DT_SWIFT_PACS008 - Customer Credit Transfer Instructions (pacs.008)
-- ============================================================
-- Processes SWIFT pacs.008 (FIToFICstmrCdtTrf) messages for customer credit
-- transfer instructions with comprehensive business data extraction and analytics.
-- Financial Institution to Financial Institution Customer Credit Transfer parsing
-- with derived fields for operational monitoring, compliance screening, and treasury management.

CREATE OR REPLACE DYNAMIC TABLE ICGA_AGG_DT_SWIFT_PACS008(
    SOURCE_FILENAME VARCHAR(200) COMMENT 'Original XML file name for audit trail and message correlation',
    SOURCE_LOAD_TIMESTAMP TIMESTAMP_NTZ COMMENT 'System ingestion timestamp for data lineage and processing tracking',
    MESSAGE_ID VARCHAR(50) COMMENT 'Unique SWIFT message identifier for deduplication and correlation',
    CREATION_DATETIME TIMESTAMP_NTZ COMMENT 'Message creation timestamp for SLA monitoring and processing analysis',
    NUMBER_OF_TRANSACTIONS NUMBER(10,0) COMMENT 'Number of transactions in message batch for volume analysis',
    GROUP_SETTLEMENT_CURRENCY VARCHAR(3) COMMENT 'Settlement currency for the entire message group',
    GROUP_SETTLEMENT_AMOUNT DECIMAL(28,2) COMMENT 'Total settlement amount for liquidity management',
    SETTLEMENT_METHOD VARCHAR(20) COMMENT 'Settlement method code for routing and clearing decisions',
    CLEARING_SYSTEM_CODE VARCHAR(20) COMMENT 'Clearing system identifier (TARGET2/SEPA/etc.) for operational routing',
    INSTRUCTION_ID VARCHAR(50) COMMENT 'Bank internal instruction identifier for operational tracking',
    END_TO_END_ID VARCHAR(50) COMMENT 'Customer end-to-end reference for reconciliation and customer service',
    TRANSACTION_ID VARCHAR(50) COMMENT 'SWIFT transaction identifier for inquiry and investigation',
    INSTRUCTION_PRIORITY VARCHAR(20) COMMENT 'Payment priority level for processing sequence and SLA',
    SERVICE_LEVEL_CODE VARCHAR(20) COMMENT 'Service level agreement code for processing rules',
    LOCAL_INSTRUMENT_CODE VARCHAR(20) COMMENT 'Local payment instrument code for domestic routing',
    TRANSACTION_CURRENCY VARCHAR(3) COMMENT 'Payment currency for FX and treasury management',
    TRANSACTION_AMOUNT DECIMAL(28,2) COMMENT 'Payment amount for limit monitoring and settlement',
    INTERBANK_SETTLEMENT_DATE DATE COMMENT 'Requested settlement date for liquidity planning',
    CHARGES_BEARER VARCHAR(10) COMMENT 'Charges allocation (OUR/BEN/SHA) for fee management',
    INSTRUCTING_AGENT_BIC VARCHAR(20) COMMENT 'BIC of instructing bank for routing and correspondence',
    INSTRUCTED_AGENT_BIC VARCHAR(20) COMMENT 'BIC of instructed bank for processing and settlement',
    DEBTOR_AGENT_BIC VARCHAR(20) COMMENT 'BIC of debtor bank for correspondent banking',
    CREDITOR_AGENT_BIC VARCHAR(20) COMMENT 'BIC of creditor bank for beneficiary settlement',
    DEBTOR_NAME VARCHAR(200) COMMENT 'Payer name for compliance screening and customer identification',
    DEBTOR_STREET VARCHAR(200) COMMENT 'Payer street address for compliance and verification',
    DEBTOR_POSTAL_CODE VARCHAR(20) COMMENT 'Payer postal code for geographic analysis',
    DEBTOR_CITY VARCHAR(100) COMMENT 'Payer city for compliance and risk assessment',
    DEBTOR_COUNTRY VARCHAR(50) COMMENT 'Payer country for sanctions screening and regulatory compliance',
    DEBTOR_IBAN VARCHAR(50) COMMENT 'Payer IBAN for account identification and validation',
    CREDITOR_NAME VARCHAR(200) COMMENT 'Beneficiary name for compliance screening and delivery confirmation',
    CREDITOR_STREET VARCHAR(200) COMMENT 'Beneficiary street address for compliance verification',
    CREDITOR_POSTAL_CODE VARCHAR(20) COMMENT 'Beneficiary postal code for geographic analysis',
    CREDITOR_CITY VARCHAR(100) COMMENT 'Beneficiary city for compliance and risk assessment',
    CREDITOR_COUNTRY VARCHAR(50) COMMENT 'Beneficiary country for sanctions screening and regulatory compliance',
    CREDITOR_IBAN VARCHAR(50) COMMENT 'Beneficiary IBAN for account identification and settlement',
    REMITTANCE_INFORMATION VARCHAR(500) COMMENT 'Payment purpose and reference information for compliance',
    IS_HIGH_VALUE_PAYMENT BOOLEAN COMMENT 'Boolean flag for payments >= 100k requiring enhanced monitoring',
    IS_TARGET2_PAYMENT BOOLEAN COMMENT 'Boolean flag for TARGET2 RTGS payments requiring special handling',
    PAYMENT_CORRIDOR VARCHAR(50) COMMENT 'Geographic payment flow (Country -> Country) for correspondent analysis',
    PAYMENT_TYPE_CLASSIFICATION VARCHAR(15) COMMENT 'Payment classification (DOMESTIC/CROSS_BORDER) for regulatory reporting',
    PARSED_AT TIMESTAMP_NTZ COMMENT 'Timestamp when XML parsing was completed for processing tracking',
    XML_SIZE_BYTES NUMBER(10,0) COMMENT 'Size of original XML message for performance analysis'
) COMMENT = 'SWIFT PACS.008 Customer Credit Transfer messages parsed and structured for business analysis. Includes payment instructions, routing information, compliance data, and derived analytics for operational monitoring, risk management, and regulatory reporting.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Source metadata - Technical tracking
    FILE_NAME as source_filename,
    LOAD_TS as source_load_timestamp,
    
    -- Group Header Information - Message-level controls
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[0]."$"')::STRING AS message_id,
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[1]."$"')::STRING AS TIMESTAMP_NTZ) AS creation_datetime,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[2]."$"')::INTEGER AS number_of_transactions,
    
    -- Group Header Settlement Information - Liquidity management
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[3]."@Ccy"')::STRING AS group_settlement_currency,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[3]."$"')::DECIMAL(28,2) AS group_settlement_amount,
    
    -- Settlement Information - Routing and clearing
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[4]."$"[0]."$"')::STRING AS settlement_method,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[4]."$"[1]."$"."$"')::STRING AS clearing_system_code,
    
    -- Payment Identification - Transaction tracking
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"[0]."$"')::STRING AS instruction_id,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"[1]."$"')::STRING AS end_to_end_id,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"[2]."$"')::STRING AS transaction_id,
    
    -- Payment Type Information - Processing rules
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"[0]."$"')::STRING AS instruction_priority,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"[1]."$"."$"')::STRING AS service_level_code,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"[2]."$"."$"')::STRING AS local_instrument_code,
    
    -- Transaction Amount - Financial data
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."@Ccy"')::STRING AS transaction_currency,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."$"')::DECIMAL(28,2) AS transaction_amount,
    
    -- Settlement Date and Charges - Operational controls
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::DATE AS interbank_settlement_date,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[4]."$"')::STRING AS charges_bearer,
    
    -- Agent Information - Routing and correspondent banking
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[5]."$"."$"."$"')::STRING AS instructing_agent_bic,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[6]."$"."$"."$"')::STRING AS instructed_agent_bic,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[7]."$"."$"."$"')::STRING AS debtor_agent_bic,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[8]."$"."$"."$"')::STRING AS creditor_agent_bic,
    
    -- Debtor Information - Payer details for compliance
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[0]."$"')::STRING AS debtor_name,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[0]."$"')::STRING AS debtor_street,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[1]."$"')::STRING AS debtor_postal_code,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[2]."$"')::STRING AS debtor_city,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[3]."$"')::STRING AS debtor_country,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[10]."$"."$"."$"')::STRING AS debtor_iban,
    
    -- Creditor Information - Beneficiary details for compliance
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[0]."$"')::STRING AS creditor_name,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[0]."$"')::STRING AS creditor_street,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[1]."$"')::STRING AS creditor_postal_code,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[2]."$"')::STRING AS creditor_city,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[3]."$"')::STRING AS creditor_country,
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[12]."$"."$"."$"')::STRING AS creditor_iban,
    
    -- Remittance Information - Payment purpose and compliance
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[13]."$"."$"')::STRING AS remittance_information,
    
    -- Analytics Fields - Business intelligence and monitoring
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."$"')::DECIMAL(28,2) >= 100000 THEN TRUE
        ELSE FALSE
    END AS is_high_value_payment,
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[4]."$"[1]."$"."$"')::STRING = 'TARGET2' THEN TRUE
        ELSE FALSE
    END AS is_target2_payment,
    
    CONCAT(
        COALESCE(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[3]."$"')::STRING, 'UNKNOWN'),
        ' -> ',
        COALESCE(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[3]."$"')::STRING, 'UNKNOWN')
    ) AS payment_corridor,
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[9]."$"[1]."$"[3]."$"')::STRING = 
             GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[11]."$"[1]."$"[3]."$"')::STRING THEN 'DOMESTIC'
        ELSE 'CROSS_BORDER'
    END AS payment_type_classification,
    
    -- Processing metadata - Technical operations
    CURRENT_TIMESTAMP() AS parsed_at,
    LENGTH(RAW_XML::STRING) AS xml_size_bytes

FROM PAY_RAW_001.ICGI_RAW_TB_SWIFT_MESSAGES
WHERE RAW_XML IS NOT NULL
  AND (FILE_NAME ILIKE '%pacs008%' OR RAW_XML::STRING ILIKE '%FIToFICstmrCdtTrf%');

-- ============================================================
-- ICGA_AGG_DT_SWIFT_PACS002 - Payment Status Reports & Acknowledgments (pacs.002)
-- ============================================================
-- Processes SWIFT pacs.002 (FIToFIPmtStsRpt) messages for payment status reports
-- and acknowledgments with comprehensive status tracking and operational analytics.
-- Financial Institution to Financial Institution Payment Status Report parsing
-- with derived fields for SLA monitoring, exception handling, and customer communication.

CREATE OR REPLACE DYNAMIC TABLE ICGA_AGG_DT_SWIFT_PACS002(
    SOURCE_FILENAME VARCHAR(200) COMMENT 'Original XML file name for audit trail and message correlation',
    SOURCE_LOAD_TIMESTAMP TIMESTAMP_NTZ COMMENT 'System ingestion timestamp for data lineage and processing tracking',
    MESSAGE_ID VARCHAR(50) COMMENT 'Unique status report message identifier for deduplication',
    CREATION_DATETIME TIMESTAMP_NTZ COMMENT 'Status report creation timestamp for SLA measurement and response time analysis',
    INSTRUCTING_AGENT_BIC VARCHAR(20) COMMENT 'BIC of bank sending status report for operational contact and routing',
    INSTRUCTED_AGENT_BIC VARCHAR(20) COMMENT 'BIC of bank receiving status report for message routing',
    ORIGINAL_MESSAGE_ID VARCHAR(50) COMMENT 'Reference to original PACS.008 message for correlation and reconciliation',
    ORIGINAL_MESSAGE_NAME_ID VARCHAR(50) COMMENT 'Confirmation of original message type being acknowledged',
    ORIGINAL_CREATION_DATETIME TIMESTAMP_NTZ COMMENT 'Original instruction timestamp for SLA tracking and processing time calculation',
    GROUP_STATUS VARCHAR(10) COMMENT 'Overall status of payment batch (ACCP/RJCT/PDNG) for bulk processing analysis',
    ORIGINAL_END_TO_END_ID VARCHAR(50) COMMENT 'Customer reference from original instruction for notification and reconciliation',
    TRANSACTION_STATUS VARCHAR(10) COMMENT 'Individual payment status code (ACCP/RJCT/PDNG/ACSC/ACSP) for operational decisions',
    STATUS_REASON VARCHAR(200) COMMENT 'Detailed reason code for rejection or delay for customer service and investigation',
    ORIGINAL_INSTRUCTION_ID VARCHAR(50) COMMENT 'Bank internal reference from original instruction for operational tracking',
    ORIGINAL_TRANSACTION_ID VARCHAR(50) COMMENT 'SWIFT tracking reference from original instruction for inquiry handling',
    ACCEPTANCE_DATETIME TIMESTAMP_NTZ COMMENT 'Timestamp when payment was actually processed for settlement timing analysis',
    TRANSACTION_STATUS_DESCRIPTION VARCHAR(50) COMMENT 'Human-readable transaction status for dashboards and customer notifications',
    GROUP_STATUS_DESCRIPTION VARCHAR(50) COMMENT 'Human-readable batch status for operational monitoring and reporting',
    IS_POSITIVE_RESPONSE BOOLEAN COMMENT 'Boolean flag for successful payment processing (SLA reporting and customer communication)',
    IS_REJECTION BOOLEAN COMMENT 'Boolean flag for failed payments requiring exception handling and customer service escalation',
    IS_PACS008_RESPONSE BOOLEAN COMMENT 'Boolean flag confirming this status relates to payment instruction (not other message types)',
    ORIGINAL_MESSAGE_DATE VARCHAR(10) COMMENT 'Business date extracted from original message for time-based analytics and archiving',
    PARSED_AT TIMESTAMP_NTZ COMMENT 'Timestamp when XML parsing was completed for processing tracking',
    XML_SIZE_BYTES NUMBER(10,0) COMMENT 'Size of original XML message for performance analysis'
) COMMENT = 'SWIFT PACS.002 Payment Status Reports parsed and structured for operational monitoring. Includes status confirmations, rejection reasons, processing timestamps, and derived analytics for SLA tracking, exception handling, and customer communication workflows.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Source metadata - Technical tracking
    FILE_NAME as source_filename,                                          -- Original XML file name for audit and correlation
    LOAD_TS as source_load_timestamp,                                     -- System ingestion timestamp for data lineage
    
    -- Group Header Information - Response message controls
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[0]."$"')::STRING AS message_id,                   -- Unique status report ID for deduplication
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[1]."$"')::STRING AS TIMESTAMP_NTZ) AS creation_datetime,  -- When status report was created (SLA measurement)
    
    -- Agent Information - Response routing
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[2]."$"."$"."$"')::STRING AS instructing_agent_bic,-- Bank sending status report (operational contact)
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[0]."$"[3]."$"."$"."$"')::STRING AS instructed_agent_bic, -- Bank receiving status report (for routing)
    
    -- Original Payment Reference - Links back to instruction
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"')::STRING AS original_message_id,          -- Links to original PACS.008 for reconciliation
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"')::STRING AS original_message_name_id,     -- Confirms message type being acknowledged
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[2]."$"')::STRING AS TIMESTAMP_NTZ) AS original_creation_datetime, -- Original instruction time for SLA tracking
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING AS group_status,                -- Overall status of payment batch
    
    -- Transaction-level Status - Individual payment outcome
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[0]."$"')::STRING AS original_end_to_end_id,       -- Customer reference for notification and reconciliation
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING AS transaction_status,           -- Payment status code (ACCP/RJCT/PDNG) for operational decisions
    
    -- Status Details - Reason and processing information
    GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[2]."$"."$"')::STRING AS status_reason,            -- Detailed reason for customer service and investigation
    
    -- Additional Processing Information - Extended tracking
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[3]."$"')::STRING AS STRING) AS original_instruction_id,  -- Bank internal reference for operations
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[4]."$"')::STRING AS STRING) AS original_transaction_id,  -- SWIFT tracking reference for inquiries
    TRY_CAST(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[5]."$"')::STRING AS TIMESTAMP_NTZ) AS acceptance_datetime,-- When payment was actually processed (settlement timing)
    
    -- Derived Analytics Fields - Business intelligence for status monitoring
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'ACCP' THEN 'ACCEPTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'RJCT' THEN 'REJECTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'PDNG' THEN 'PENDING'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'ACSC' THEN 'ACCEPTED_SETTLEMENT_COMPLETED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'ACSP' THEN 'ACCEPTED_SETTLEMENT_IN_PROCESS'
        ELSE GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING
    END AS transaction_status_description,                                  -- Human-readable status for dashboards and customer notifications
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING = 'ACCP' THEN 'ACCEPTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING = 'RJCT' THEN 'REJECTED'
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING = 'PDNG' THEN 'PENDING'
        ELSE GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[3]."$"')::STRING
    END AS group_status_description,                                        -- Batch-level status for operational monitoring
    
    -- Response Classification - Operational alerting and SLA monitoring
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING IN ('ACCP', 'ACSC', 'ACSP') THEN TRUE
        ELSE FALSE
    END AS is_positive_response,                                            -- Success indicator for SLA reporting and customer communication
    
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[2]."$"[1]."$"')::STRING = 'RJCT' THEN TRUE
        ELSE FALSE
    END AS is_rejection,                                                    -- Failure flag for exception handling and customer service escalation
    
    -- Message Type Validation - Processing integrity checks
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[1]."$"')::STRING = 'pacs.008.001.08' THEN TRUE
        ELSE FALSE
    END AS is_pacs008_response,                                             -- Confirms this status relates to payment instruction (not other message types)
    
    -- Temporal Correlation - Data organization and performance optimization
    CASE 
        WHEN GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"')::STRING LIKE '20%-%-%' THEN
            SUBSTR(GET_PATH(PARSE_XML(RAW_XML::STRING), '$[1]."$"[0]."$"')::STRING, 1, 8)
        ELSE NULL
    END AS original_message_date,                                           -- Business date extraction for time-based analytics and archiving
    
    -- Processing metadata - Technical operations and monitoring
    CURRENT_TIMESTAMP() AS parsed_at,                                       -- Processing timestamp for data quality monitoring
    LENGTH(RAW_XML::STRING) AS xml_size_bytes                              -- Message complexity indicator for performance analysis

FROM PAY_RAW_001.ICGI_RAW_TB_SWIFT_MESSAGES
WHERE RAW_XML IS NOT NULL
  AND (FILE_NAME ILIKE '%pacs002%' OR RAW_XML::STRING ILIKE '%FIToFIPmtStsRpt%');

-- ============================================================
-- FUTURE ENHANCEMENTS - SWIFT Payment Flow Analysis
-- ============================================================
-- Additional analytics can be built in REP_AGG_001 for:
-- - Joined pacs.008 credit transfers with pacs.002 status reports
-- - End-to-end view of payment processing lifecycle
-- - Payment success/failure analysis

CREATE OR REPLACE DYNAMIC TABLE ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE(
    PACS008_MESSAGE_ID VARCHAR(50) COMMENT 'Original payment instruction message ID for tracking and correlation',
    PACS002_ORIGINAL_MESSAGE_ID VARCHAR(50) COMMENT 'Status report reference back to original instruction for reconciliation',
    PACS008_END_TO_END_ID VARCHAR(50) COMMENT 'Customer payment reference from original instruction for reconciliation',
    PACS002_ORIGINAL_END_TO_END_ID VARCHAR(50) COMMENT 'Customer reference confirmed in status report for validation',
    TRANSACTION_STATUS VARCHAR(10) COMMENT 'Final payment status code (ACCP/RJCT/PDNG/ACSC/ACSP) for operational decisions',
    TRANSACTION_STATUS_DESCRIPTION VARCHAR(50) COMMENT 'Human-readable payment status for customer communication and dashboards',
    GROUP_STATUS VARCHAR(10) COMMENT 'Batch-level payment outcome for bulk processing analysis',
    GROUP_STATUS_DESCRIPTION VARCHAR(50) COMMENT 'Human-readable batch status for operational dashboards and monitoring',
    STATUS_REASON VARCHAR(200) COMMENT 'Detailed reason code for investigation, customer service, and process improvement',
    IS_REJECTION BOOLEAN COMMENT 'Boolean flag for failed payments requiring exception handling workflows',
    IS_POSITIVE_RESPONSE BOOLEAN COMMENT 'Boolean flag for successful payments (SLA and performance reporting)',
    TRANSACTION_CURRENCY VARCHAR(3) COMMENT 'Payment currency for FX exposure analysis and treasury management',
    TRANSACTION_AMOUNT DECIMAL(28,2) COMMENT 'Payment value for limit monitoring, settlement planning, and risk assessment',
    DEBTOR_NAME VARCHAR(200) COMMENT 'Payer identification for compliance screening and customer service',
    CREDITOR_NAME VARCHAR(200) COMMENT 'Beneficiary identification for delivery confirmation and compliance',
    PAYMENT_CORRIDOR VARCHAR(50) COMMENT 'Geographic payment flow (Country -> Country) for correspondent banking analysis',
    PAYMENT_TYPE_CLASSIFICATION VARCHAR(15) COMMENT 'Payment classification (DOMESTIC/CROSS_BORDER) for regulatory reporting',
    IS_HIGH_VALUE_PAYMENT BOOLEAN COMMENT 'Boolean flag for large payments requiring enhanced monitoring and approval processes',
    IS_TARGET2_PAYMENT BOOLEAN COMMENT 'Boolean flag for RTGS payments requiring special liquidity and settlement planning',
    PACS008_FILE VARCHAR(200) COMMENT 'Original instruction file name for audit trail and data lineage',
    PACS002_FILE VARCHAR(200) COMMENT 'Status report file name for correlation verification and audit trail',
    PACS008_LOAD_TIMESTAMP TIMESTAMP_NTZ COMMENT 'Instruction ingestion timestamp for timing analysis and data quality',
    PACS002_LOAD_TIMESTAMP TIMESTAMP_NTZ COMMENT 'Status report ingestion timestamp for response time measurement',
    ACK_TIME NUMBER(10,0) COMMENT 'Processing time in minutes from instruction to status for SLA monitoring and performance optimization',
    JOINED_AT TIMESTAMP_NTZ COMMENT 'Join processing timestamp for data quality tracking and refresh monitoring'
) COMMENT = 'Complete SWIFT payment lifecycle view joining PACS.008 instructions with PACS.002 status reports. Provides end-to-end payment tracking, SLA monitoring, settlement analysis, and comprehensive business intelligence for treasury management, compliance reporting, and operational excellence.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT
    -- Join keys - Message correlation identifiers
    p008.message_id                AS pacs008_message_id,               -- Original payment instruction ID for tracking
    p002.original_message_id       AS pacs002_original_message_id,     -- Status report reference back to instruction
    
    -- Transaction-level correlation - Customer and operational references
    p008.end_to_end_id             AS pacs008_end_to_end_id,           -- Customer's payment reference for reconciliation
    p002.original_end_to_end_id    AS pacs002_original_end_to_end_id,  -- Confirmed customer reference in status report
    
    -- Status Information - Payment outcome and processing results
    p002.transaction_status,                                           -- Final payment status (ACCP/RJCT/PDNG) for operational decisions
    p002.transaction_status_description,                               -- Human-readable status for customer communication
    p002.group_status,                                                 -- Batch-level outcome for bulk processing analysis
    p002.group_status_description,                                     -- Readable batch status for operational dashboards
    p002.status_reason,                                                -- Detailed reason code for investigation and customer service
    p002.is_rejection,                                                 -- Failed payment flag for exception handling workflows
    p002.is_positive_response,                                         -- Success indicator for SLA and performance reporting
    
    -- Payment Details - Financial and business information
    p008.transaction_currency,                                         -- Payment currency for FX and treasury management
    p008.transaction_amount,                                           -- Payment value for limit monitoring and settlement
    p008.debtor_name,                                                  -- Payer identification for compliance and customer service
    p008.creditor_name,                                                -- Beneficiary identification for delivery confirmation
    p008.payment_corridor,                                             -- Geographic flow for correspondent banking analysis
    p008.payment_type_classification,                                  -- Domestic vs cross-border for regulatory reporting
    p008.is_high_value_payment,                                        -- Large payment flag for enhanced monitoring and approval
    p008.is_target2_payment,                                           -- RTGS classification for liquidity and settlement planning
    
    -- Technical Metadata - Data lineage and processing information
    p008.source_filename   AS pacs008_file,                           -- Original instruction file for audit trail
    p002.source_filename   AS pacs002_file,                           -- Status report file for correlation verification
    p008.source_load_timestamp AS pacs008_load_timestamp,             -- When instruction was received for timing analysis
    p002.source_load_timestamp AS pacs002_load_timestamp,             -- When status was received for response time measurement
    DATEDIFF('minutes', p002.ORIGINAL_CREATION_DATETIME, p002.CREATION_DATETIME) AS ack_time, -- Processing time for SLA monitoring and performance optimization
    CURRENT_TIMESTAMP() AS joined_at                                  -- Join processing timestamp for data quality tracking
    
FROM ICGA_AGG_DT_SWIFT_PACS008 p008
LEFT JOIN ICGA_AGG_DT_SWIFT_PACS002 p002
    ON p002.original_message_id = p008.message_id
   AND (
        p002.original_end_to_end_id = p008.end_to_end_id
        OR p002.original_transaction_id = p008.transaction_id
   );


-- ============================================================
-- SCHEMA COMPLETION STATUS
-- ============================================================
-- ✅ PAY_AGG_001 Schema Deployment Complete (SWIFT Message Processing)
--
-- OBJECTS CREATED:
-- • 3 Dynamic Tables: 
--   - ICGA_AGG_DT_SWIFT_PACS008 (customer credit transfer instructions)
--   - ICGA_AGG_DT_SWIFT_PACS002 (payment status reports and acknowledgments)
--   - ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE (complete payment lifecycle with SLA analysis)
-- • Automated refresh: 60-minute TARGET_LAG for near real-time business intelligence
-- • Comprehensive field extraction: 50+ business data elements per message type
--
-- NEXT STEPS:
-- 1. ✅ PAY_AGG_001 schema deployed successfully (SWIFT processing objects)
-- 2. Verify dynamic table refresh: SHOW DYNAMIC TABLES IN SCHEMA PAY_AGG_001;
-- 3. Monitor processing performance and adjust TARGET_LAG if needed
-- 4. Build additional SWIFT analytics in REP_AGG_001 for cross-domain reporting
-- 5. Integrate with operational dashboards and monitoring systems
--
-- USAGE EXAMPLES:
--
-- -- Query all high-value payments (>= 100k EUR equivalent)
-- SELECT debtor_name, creditor_name, transaction_amount, transaction_currency, payment_corridor
-- FROM ICGA_AGG_DT_SWIFT_PACS008 
-- WHERE is_high_value_payment = TRUE
-- ORDER BY transaction_amount DESC;
--
-- -- Query rejected payments with reasons
-- SELECT original_end_to_end_id, transaction_status_description, status_reason, 
--        instructing_agent_bic, instructed_agent_bic
-- FROM ICGA_AGG_DT_SWIFT_PACS002 
-- WHERE is_rejection = TRUE
-- ORDER BY creation_datetime DESC;
--
-- -- Query complete payment lifecycle with SLA analysis
-- SELECT pacs008_end_to_end_id, transaction_amount, transaction_currency,
--        debtor_name, creditor_name, transaction_status_description, ack_time
-- FROM ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE 
-- WHERE ack_time > 60  -- Payments taking longer than 60 minutes
-- ORDER BY ack_time DESC;
--
-- -- Query cross-border payment flows by corridor
-- SELECT payment_corridor, COUNT(*) as payment_count, 
--        SUM(transaction_amount) as total_amount, transaction_currency
-- FROM ICGA_AGG_DT_SWIFT_PACS008 
-- WHERE payment_type_classification = 'CROSS_BORDER'
-- GROUP BY payment_corridor, transaction_currency
-- ORDER BY total_amount DESC;
--
-- -- Query TARGET2 payment volumes
-- SELECT DATE(creation_datetime) as business_date,
--        COUNT(*) as target2_payments,
--        SUM(transaction_amount) as total_eur_amount
-- FROM ICGA_AGG_DT_SWIFT_PACS008 
-- WHERE is_target2_payment = TRUE
-- GROUP BY business_date
-- ORDER BY business_date DESC;
--
-- MANUAL REFRESH COMMANDS:
-- ALTER DYNAMIC TABLE ICGA_AGG_DT_SWIFT_PACS008 REFRESH;
-- ALTER DYNAMIC TABLE ICGA_AGG_DT_SWIFT_PACS002 REFRESH;
-- ALTER DYNAMIC TABLE ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE REFRESH;
--
-- MONITORING:
-- - Dynamic table refresh status: SELECT * FROM TABLE(INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY()) WHERE NAME LIKE 'ICGA_AGG_DT_%';
-- - Processing performance: SELECT COUNT(*), AVG(xml_size_bytes) FROM ICGA_AGG_DT_SWIFT_PACS008;
-- - Message type distribution: SELECT message_type, COUNT(*) FROM (SELECT CASE WHEN FILE_NAME ILIKE '%pacs008%' THEN 'PACS.008' ELSE 'PACS.002' END as message_type FROM PAY_RAW_001.ICGI_RAW_TB_SWIFT_MESSAGES) GROUP BY message_type;
-- - Payment lifecycle SLA: SELECT AVG(ack_time) as avg_ack_minutes, MAX(ack_time) as max_ack_minutes FROM ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE;
--
-- PERFORMANCE OPTIMIZATION:
-- - Monitor warehouse usage during refresh periods
-- - Consider clustering on creation_datetime for time-based queries
-- - Adjust TARGET_LAG based on business SLA requirements
-- - Archive processed messages based on regulatory retention policies
-- ============================================================
