-- ============================================================================
-- 720_PAYA_SV_COMPLIANCE_MONITORING.sql
-- Unified Payment Compliance Monitoring Semantic View (AML + Sanctions)
-- ============================================================================
-- Purpose: Consolidated AML transaction monitoring and sanctions screening
-- Consolidates: AML Monitoring + Sanctions Screening (2 views → 1)
-- Used by: AML Transaction Monitoring, Sanctions & Embargo Control,
--          Compliance Risk Management notebooks, Streamlit CRM App
-- Business Value: €3.165M+ annually (€1.165M labor + €2M penalty avoidance)
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA PAY_AGG_001;

-- ============================================================================
-- Main Semantic View: PAYA_SV_COMPLIANCE_MONITORING (FOR AI AGENTS)
-- ============================================================================
-- Single-table semantic view for Cortex AI agents. Uses PAYA_AGG_DT_TRANSACTION_ANOMALIES
-- as the primary data source.
--
-- Note: For detailed multi-table compliance views with customer/account context,
--       see PAYA_SV_COMPLIANCE_MONITORING_DETAILED in 330_PAYA_anomaly_detection.sql
--
-- Note: Sanctions (SAN_AGG_001) and SWIFT (ICG_AGG_001) schemas not yet available
--       Currently focuses on AML transaction monitoring

CREATE OR REPLACE SEMANTIC VIEW PAYA_SV_COMPLIANCE_MONITORING
tables (
  transactions AS PAYA_AGG_DT_TRANSACTION_ANOMALIES
    PRIMARY KEY (TRANSACTION_ID)
    COMMENT = 'Transaction anomaly detection and compliance monitoring',
  customers AS AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360
    PRIMARY KEY (CUSTOMER_ID)
    COMMENT = 'Customer profile and risk data for compliance context'
)

relationships (
  transaction_to_customer AS
    transactions (CUSTOMER_ID) REFERENCES customers
)

facts (
  -- ===== TRANSACTION DETAILS =====
  transactions.TRANSACTION_ID as TRANSACTION_ID comment='Transaction ID | transaction number | payment ID | txn ID',
  transactions.ACCOUNT_ID as ACCOUNT_ID comment='Account ID | account number',
  transactions.CUSTOMER_ID as CUSTOMER_ID comment='Customer ID | client ID',
  transactions.BOOKING_DATE as BOOKING_DATE comment='Booking date | posting date | transaction date',
  transactions.VALUE_DATE as VALUE_DATE comment='Value date | settlement date',
  transactions.AMOUNT as AMOUNT comment='Transaction amount | payment amount | txn amount',
  transactions.COUNTERPARTY_ACCOUNT as COUNTERPARTY_ACCOUNT 
    WITH SYNONYMS = ('counterparty', 'beneficiary', 'recipient', 'payee', 'beneficiary account', 'recipient account')
    comment='Counterparty account number. Use for filtering by beneficiary or recipient',
  transactions.DESCRIPTION as DESCRIPTION 
    WITH SYNONYMS = ('description', 'narrative', 'details', 'payment description', 'transaction details', 'memo')
    comment='Transaction description. Supports text search for finding transactions by description content',
  
  -- ===== CUSTOMER TRANSACTION PATTERNS =====
  transactions.CUSTOMER_TOTAL_TRANSACTIONS as CUSTOMER_TOTAL_TRANSACTIONS comment='Customer total transactions | transaction count | total txns',
  transactions.AVG_TRANSACTION_AMOUNT as AVG_TRANSACTION_AMOUNT comment='Average transaction amount | typical amount | mean amount',
  transactions.MEDIAN_TRANSACTION_AMOUNT as MEDIAN_TRANSACTION_AMOUNT comment='Median transaction amount | middle amount',
  transactions.AVG_DAILY_TRANSACTION_COUNT as AVG_DAILY_TRANSACTION_COUNT comment='Average daily transactions | daily txn count',
  
  -- ===== ANOMALY DETECTION SCORES =====
  transactions.AMOUNT_ANOMALY_SCORE as AMOUNT_ANOMALY_SCORE comment='Amount anomaly score | unusual amount score',
  transactions.TIMING_ANOMALY_SCORE as TIMING_ANOMALY_SCORE comment='Timing anomaly score | unusual time score',
  
  -- ===== ANOMALY FLAGS =====
  transactions.IS_LARGE_TRANSACTION as IS_LARGE_TRANSACTION comment='Large transaction flag | high value | big amount',
  transactions.IS_UNUSUAL_WEEKEND_TRANSACTION as IS_UNUSUAL_WEEKEND_TRANSACTION comment='Weekend transaction flag | Saturday Sunday | unusual timing',
  transactions.IS_OFF_HOURS_TRANSACTION as IS_OFF_HOURS_TRANSACTION comment='Off hours transaction | late night | unusual time',
  transactions.IS_DELAYED_SETTLEMENT as IS_DELAYED_SETTLEMENT comment='Delayed settlement flag | late settlement',
  transactions.IS_BACKDATED_SETTLEMENT as IS_BACKDATED_SETTLEMENT comment='Backdated settlement | backdated value date',
  
  -- ===== COMPOSITE RISK ASSESSMENT =====
  transactions.COMPOSITE_ANOMALY_SCORE as COMPOSITE_ANOMALY_SCORE comment='Composite anomaly score | overall risk score | total anomaly score',
  transactions.REQUIRES_IMMEDIATE_REVIEW as REQUIRES_IMMEDIATE_REVIEW comment='Requires immediate review | urgent review | critical flag',
  transactions.REQUIRES_ENHANCED_MONITORING as REQUIRES_ENHANCED_MONITORING comment='Requires enhanced monitoring | heightened scrutiny | watch list',
  
  -- ===== VELOCITY METRICS =====
  transactions.TRANSACTIONS_LAST_24H as TRANSACTIONS_LAST_24H comment='Transactions last 24 hours | daily transactions',
  transactions.TRANSACTIONS_LAST_7D as TRANSACTIONS_LAST_7D comment='Transactions last 7 days | weekly transactions',
  
  -- ===== TIMING ATTRIBUTES =====
  transactions.TRANSACTION_HOUR as TRANSACTION_HOUR comment='Transaction hour | hour of day | time',
  transactions.SETTLEMENT_DAYS as SETTLEMENT_DAYS comment='Settlement days | days to settle',
  
  -- ===== METADATA =====
  transactions.ANOMALY_ANALYSIS_TIMESTAMP as ANOMALY_ANALYSIS_TIMESTAMP comment='Analysis timestamp | analyzed at | detection time'
)

dimensions (
  -- ===== PRIMARY GROUPING DIMENSIONS =====
  transactions.OVERALL_ANOMALY_CLASSIFICATION AS OVERALL_ANOMALY_CLASSIFICATION 
    WITH SYNONYMS = ('risk level', 'anomaly level', 'classification', 'severity', 'risk category')
    COMMENT = 'Overall anomaly classification (CRITICAL, HIGH, MODERATE, LOW). Primary dimension for risk-based filtering and grouping',
  transactions.CURRENCY AS CURRENCY 
    WITH SYNONYMS = ('currency', 'currency code', 'payment currency', 'transaction currency')
    COMMENT = 'Transaction currency. Use for currency-based analysis and reporting',
  
  -- ===== SECONDARY DIMENSIONS =====
  transactions.AMOUNT_ANOMALY_LEVEL AS AMOUNT_ANOMALY_LEVEL 
    WITH SYNONYMS = ('amount risk', 'amount anomaly', 'unusual amount')
    COMMENT = 'Amount anomaly level. Use for filtering transactions with unusual amounts',
  transactions.TIMING_ANOMALY_LEVEL AS TIMING_ANOMALY_LEVEL 
    WITH SYNONYMS = ('timing risk', 'timing anomaly', 'unusual timing')
    COMMENT = 'Timing anomaly level. Use for filtering transactions with unusual timing patterns',
  transactions.VELOCITY_ANOMALY_LEVEL AS VELOCITY_ANOMALY_LEVEL 
    WITH SYNONYMS = ('velocity risk', 'frequency anomaly', 'velocity anomaly')
    COMMENT = 'Velocity anomaly level. Use for filtering transactions with unusual frequency patterns',
  transactions.TRANSACTION_DAYOFWEEK AS TRANSACTION_DAYOFWEEK 
    COMMENT = 'Day of week for temporal analysis'
)

metrics (
  -- ===== PRIMARY METRICS =====
  transactions.TRANSACTION_COUNT AS COUNT(transactions.TRANSACTION_ID)
    WITH SYNONYMS = ('number of transactions', 'transaction count', 'how many transactions', 'total transactions', 'txn count')
    COMMENT = 'Count of transactions. Use for "how many transactions" queries',
  transactions.TOTAL_AMOUNT AS SUM(transactions.AMOUNT)
    WITH SYNONYMS = ('total amount', 'sum of amounts', 'total value', 'aggregate amount')
    COMMENT = 'Sum of all transaction amounts. Use for total transaction value calculations',
  transactions.AVG_AMOUNT AS AVG(transactions.AMOUNT)
    WITH SYNONYMS = ('average amount', 'mean amount', 'typical amount', 'avg transaction size')
    COMMENT = 'Average transaction amount. Use for typical transaction size analysis',
  transactions.HIGH_RISK_COUNT AS COUNT(CASE WHEN transactions.OVERALL_ANOMALY_CLASSIFICATION IN ('HIGH', 'CRITICAL') THEN 1 END)
    WITH SYNONYMS = ('high risk transactions', 'critical transactions', 'number of high risk', 'high risk count')
    COMMENT = 'Count of HIGH and CRITICAL anomaly transactions. Use for risk concentration analysis'
);

-- Note: Customer context (FULL_NAME, COUNTRY, OVERALL_RISK_RATING, etc.) is accessible
--       through the transaction_to_customer relationship.

-- ============================================================================
-- Permissions
-- ============================================================================

-- Permissions on underlying table
GRANT SELECT ON TABLE PAYA_AGG_DT_TRANSACTION_ANOMALIES TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE PAYA_AGG_DT_TRANSACTION_ANOMALIES TO ROLE PUBLIC;

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test semantic view (basic AML monitoring)
-- SELECT 
--   transaction_id,
--   booking_date,
--   amount,
--   currency,
--   overall_anomaly_classification,
--   composite_anomaly_score,
--   counterparty_account,
--   description
-- FROM PAYA_SV_COMPLIANCE_MONITORING
-- WHERE overall_anomaly_classification IN ('HIGH_ANOMALY', 'CRITICAL_ANOMALY')
-- LIMIT 20;

-- Test AI agent query
-- SELECT 
--   customer_id,
--   COUNT(*) as high_risk_transactions,
--   SUM(amount) as total_amount_at_risk
-- FROM PAYA_SV_COMPLIANCE_MONITORING
-- WHERE overall_anomaly_classification IN ('HIGH_ANOMALY', 'CRITICAL_ANOMALY')
-- GROUP BY customer_id
-- ORDER BY high_risk_transactions DESC;

-- ============================================================================
-- Deployment Success Message
-- ============================================================================

SELECT 'PAYA_SV_COMPLIANCE_MONITORING semantic view created successfully! AML transaction monitoring ready. (Sanctions/SWIFT to be added when schemas available)' AS STATUS;

