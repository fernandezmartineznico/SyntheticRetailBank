-- ============================================================================
-- 740_REPA_SV_RISK_REPORTING.sql
-- Cross-Domain Risk Aggregation & Regulatory Reporting Semantic View
-- ============================================================================
-- Purpose: Executive-level risk aggregation, regulatory compliance (BCBS 239,
--          FRTB), and data quality monitoring across all domains
-- Used by: RISK_REGULATORY_AGENT, CRO, Risk Management, Board committees
-- Business Value: Regulatory compliance efficiency, faster risk decisions,
--                 penalty avoidance, board confidence
-- ============================================================================
-- NOTE: Multi-table semantic view using star schema relationships
--       Primary fact table: REPP_AGG_DT_BCBS239_RISK_AGGREGATION
--       Related tables: REGULATORY_REPORTING, DATA_QUALITY, ANOMALY_ANALYSIS,
--                      HIGH_RISK_PATTERNS, CURRENCY_EXPOSURE, FRTB_CAPITAL_CHARGES
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================================
-- Main Semantic View: REPA_SV_RISK_REPORTING (Multi-Table)
-- ============================================================================
-- Note: This comprehensive semantic view combines 7 tables for AI agent consumption.
--       Relationships are defined to enable natural language queries across all
--       BCBS 239 risk dimensions, regulatory reporting, data quality, anomalies,
--       high-risk patterns, currency exposure, and FRTB capital charges.


CREATE OR REPLACE SEMANTIC VIEW REPA_SV_RISK_REPORTING
tables (
  risk AS REPP_AGG_DT_BCBS239_RISK_AGGREGATION
    PRIMARY KEY (CUSTOMER_ID, REPORTING_DATE, RISK_TYPE, GEOGRAPHY)
    COMMENT = 'BCBS 239 risk aggregation and capital requirements',
  customers AS CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360
    PRIMARY KEY (CUSTOMER_ID)
    COMMENT = 'Customer profile for risk attribution'
)

relationships (
  risk_to_customer AS
    risk (CUSTOMER_ID) REFERENCES customers
)

facts (
  -- ===== PRIMARY IDENTIFIERS =====
  risk.CUSTOMER_ID as CUSTOMER_ID comment='Customer ID | client ID | customer identifier for individual risk tracking',
  risk.REPORTING_DATE as REPORTING_DATE comment='Reporting date | report date | as of date | business date for regulatory reporting',
  
  -- ===== RISK CLASSIFICATION (reduced section - main grouping fields moved to DIMENSIONS) =====

  -- ===== RISK EXPOSURE METRICS =====
  risk.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF 
    WITH SYNONYMS = ('exposure', 'risk exposure', 'at-risk amount', 'exposed capital', 'risk amount')
    comment='Total risk exposure in CHF. Primary metric for risk aggregation and regulatory reporting',
  risk.TOTAL_CAPITAL_REQUIREMENT_CHF as TOTAL_CAPITAL_REQUIREMENT_CHF 
    WITH SYNONYMS = ('capital', 'capital amount', 'capital requirement', 'required capital')
    comment='Capital requirement or amount. Primary metric for capital adequacy analysis and FRTB reporting',
  risk.AVG_RISK_WEIGHT as AVG_RISK_WEIGHT comment='Average risk weight | risk weight | risk weight percentage',
  risk.CUSTOMER_COUNT as CUSTOMER_COUNT comment='Customer count | number of customers | client count in risk segment',
  risk.MAX_SINGLE_EXPOSURE_CHF as MAX_SINGLE_EXPOSURE_CHF comment='Maximum single exposure | largest exposure | max concentration',
  risk.EXPOSURE_VOLATILITY_CHF as EXPOSURE_VOLATILITY_CHF comment='Exposure volatility | volatility | standard deviation of exposures',
  risk.MAX_CONCENTRATION_PERCENT as MAX_CONCENTRATION_PERCENT comment='Maximum concentration | concentration percentage | max single customer concentration',
  risk.CAPITAL_RATIO_PERCENT as CAPITAL_RATIO_PERCENT comment='Capital ratio | capital adequacy ratio | CAR percentage',
  risk.AVG_EXPOSURE_PER_CUSTOMER_CHF as AVG_EXPOSURE_PER_CUSTOMER_CHF comment='Average exposure per customer | average exposure | mean customer exposure',
  risk.AGGREGATION_TIMESTAMP as AGGREGATION_TIMESTAMP comment='Aggregation timestamp | calculation timestamp | when aggregation was performed'
)

dimensions (
  -- ===== PRIMARY GROUPING DIMENSIONS =====
  risk.RISK_TYPE AS RISK_TYPE 
    WITH SYNONYMS = ('risk type', 'risk category', 'type of risk', 'credit risk', 'market risk', 'operational risk', 'liquidity risk')
    COMMENT = 'Risk type (CREDIT, MARKET, OPERATIONAL, LIQUIDITY). Primary dimension for risk category analysis',
  risk.GEOGRAPHY AS GEOGRAPHY 
    WITH SYNONYMS = ('geography', 'region', 'country', 'location', 'area', 'territory', 'geographic region')
    COMMENT = 'Geographic region. Primary dimension for regional risk analysis and "by region" queries',
  risk.CURRENCY AS CURRENCY 
    WITH SYNONYMS = ('currency', 'currency code', 'reporting currency', 'FX', 'foreign exchange')
    COMMENT = 'Reporting currency (CHF, USD, EUR, GBP). Use for currency-based risk analysis',
  risk.CUSTOMER_SEGMENT AS CUSTOMER_SEGMENT 
    WITH SYNONYMS = ('customer segment', 'client segment', 'risk segment', 'low risk', 'medium risk', 'high risk')
    COMMENT = 'Customer risk segment (LOW_RISK, MEDIUM_RISK, HIGH_RISK). Use for risk appetite segmentation',
  
  -- ===== SECONDARY DIMENSIONS =====
  risk.BUSINESS_LINE AS BUSINESS_LINE 
    WITH SYNONYMS = ('business line', 'LOB', 'line of business', 'business unit')
    COMMENT = 'Business line or line of business. Use for risk allocation by business unit'
)

metrics (
  -- ===== PRIMARY METRICS =====
  risk.CUSTOMER_RISK_COUNT AS COUNT(risk.CUSTOMER_ID)
    WITH SYNONYMS = ('number of customers', 'customer count', 'how many customers', 'at-risk customers', 'exposed customers')
    COMMENT = 'Count of customers with risk exposure. Use for "how many customers" queries',
  risk.TOTAL_EXPOSURE_SUM AS SUM(risk.TOTAL_EXPOSURE_CHF)
    WITH SYNONYMS = ('total exposure', 'aggregate exposure', 'sum of exposures', 'total risk exposure', 'RWA', 'risk-weighted assets')
    COMMENT = 'Sum of all risk exposures. Use for total RWA and aggregate risk calculations',
  risk.TOTAL_CAPITAL_SUM AS SUM(risk.TOTAL_CAPITAL_REQUIREMENT_CHF)
    WITH SYNONYMS = ('total capital', 'aggregate capital', 'sum of capital requirements', 'capital requirement', 'required capital')
    COMMENT = 'Sum of all capital requirements. Use for total capital adequacy analysis',
  risk.AVG_EXPOSURE AS AVG(risk.TOTAL_EXPOSURE_CHF)
    WITH SYNONYMS = ('average exposure', 'mean exposure', 'typical exposure', 'avg risk')
    COMMENT = 'Average risk exposure. Use for typical risk level analysis',
  risk.MAX_CONCENTRATION AS MAX(risk.MAX_SINGLE_EXPOSURE_CHF)
    WITH SYNONYMS = ('maximum concentration', 'largest exposure', 'peak concentration', 'max exposure')
    COMMENT = 'Maximum single exposure. Use for concentration risk analysis'
);

-- Note: Customer context (FULL_NAME, COUNTRY, ACCOUNT_TIER) is accessible through
--       the risk_to_customer relationship.

-- ============================================================================
-- Permissions
-- ============================================================================
-- Note: Semantic views inherit permissions from their underlying tables.
--       Ensure base tables have appropriate grants for all roles that need access.

-- Grant access to underlying tables (semantic view inherits these)
GRANT SELECT ON TABLE REPP_AGG_DT_BCBS239_RISK_AGGREGATION TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_BCBS239_RISK_AGGREGATION TO ROLE PUBLIC;
GRANT SELECT ON TABLE REPP_AGG_DT_BCBS239_REGULATORY_REPORTING TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_BCBS239_REGULATORY_REPORTING TO ROLE PUBLIC;
GRANT SELECT ON TABLE REPP_AGG_DT_BCBS239_DATA_QUALITY TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_BCBS239_DATA_QUALITY TO ROLE PUBLIC;
GRANT SELECT ON TABLE REPP_AGG_DT_ANOMALY_ANALYSIS TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_ANOMALY_ANALYSIS TO ROLE PUBLIC;
GRANT SELECT ON TABLE REPP_AGG_DT_HIGH_RISK_PATTERNS TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_HIGH_RISK_PATTERNS TO ROLE PUBLIC;
GRANT SELECT ON TABLE REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT TO ROLE PUBLIC;
GRANT SELECT ON TABLE REPP_AGG_DT_FRTB_CAPITAL_CHARGES TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE REPP_AGG_DT_FRTB_CAPITAL_CHARGES TO ROLE PUBLIC;

-- Note: Detailed view has been removed. Will be recreated when comprehensive
--       REPP_AGG_DT_RISK_AGGREGATION_COMPLETE dynamic table is available.

-- ============================================================================
-- Deployment Success Message
-- ============================================================================

SELECT 'REPA_SV_RISK_REPORTING semantic view created successfully! Currently includes 17 risk aggregation attributes from risk. This is a foundational deployment - comprehensive multi-table version (130+ attributes) will be available once REPP_AGG_DT_RISK_AGGREGATION_COMPLETE dynamic table is created.' AS STATUS;
