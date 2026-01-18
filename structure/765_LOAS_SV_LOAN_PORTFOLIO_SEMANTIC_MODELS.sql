-- ============================================================================
-- 765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql
-- Loan Portfolio Semantic Models for Cortex Analyst AI Agent
-- ============================================================================
-- Purpose: Semantic views for AI agent with NLQ metadata, synonyms, and comments
-- Used by: 865_LOAN_PORTFOLIO_AGENT.sql (Cortex Analyst AI Agent)
-- Related: 565_LOAR_loans_portfolio_reporting.sql (regular views for dashboards)
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================================
-- SEMANTIC VIEW 1: Portfolio Current Status
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LOAS_SV_PORTFOLIO_CURRENT
tables (
  portfolio_data AS LOAR_AGG_DT_PORTFOLIO_SUMMARY
    COMMENT = 'Loan portfolio summary by product, country, and status'
)

facts (
  -- Date
  portfolio_data.AS_OF_DATE as AS_OF_DATE 
    WITH SYNONYMS = ('reporting date', 'calculation date', 'snapshot date', 'data date', 'as of date')
    comment='Date of portfolio snapshot | reporting date',
  
  -- Portfolio Dimensions
  portfolio_data.PRODUCT_TYPE as PRODUCT_TYPE
    WITH SYNONYMS = ('product', 'loan type', 'loan product', 'product category')
    comment='Product type: MORTGAGE, PERSONAL_LOAN, HOME_EQUITY',
  
  portfolio_data.COUNTRY as COUNTRY
    WITH SYNONYMS = ('country code', 'jurisdiction', 'regime', 'market')
    comment='Country code: CHE (Switzerland), GBR (UK), DEU (Germany), PRT (Portugal)',
  
  portfolio_data.APPLICATION_STATUS as APPLICATION_STATUS
    WITH SYNONYMS = ('status', 'loan status', 'application state', 'approval status')
    comment='Application status: APPROVED, DECLINED, UNDER_REVIEW, DISBURSED',
  
  -- Portfolio Metrics
  portfolio_data.LOAN_COUNT as LOAN_COUNT
    WITH SYNONYMS = ('count', 'number of loans', 'loan volume', 'applications count', 'total loans')
    comment='Number of loan applications in this category',
  
  portfolio_data.TOTAL_REQUESTED_AMOUNT as TOTAL_REQUESTED_AMOUNT
    WITH SYNONYMS = ('total amount', 'total exposure', 'total loan amount', 'exposure', 'portfolio value')
    comment='Total requested loan amount in CHF',
  
  portfolio_data.AVG_REQUESTED_AMOUNT as AVG_REQUESTED_AMOUNT
    WITH SYNONYMS = ('average amount', 'average loan', 'mean amount', 'average loan size')
    comment='Average requested loan amount in CHF',
  
  portfolio_data.MIN_REQUESTED_AMOUNT as MIN_REQUESTED_AMOUNT
    WITH SYNONYMS = ('minimum amount', 'smallest loan', 'min loan')
    comment='Minimum requested loan amount in CHF',
  
  portfolio_data.MAX_REQUESTED_AMOUNT as MAX_REQUESTED_AMOUNT
    WITH SYNONYMS = ('maximum amount', 'largest loan', 'max loan', 'biggest loan')
    comment='Maximum requested loan amount in CHF',
  
  portfolio_data.AVG_TERM_MONTHS as AVG_TERM_MONTHS
    WITH SYNONYMS = ('average term', 'average loan term', 'mean term', 'term length', 'average maturity')
    comment='Average loan term in months',
  
  -- Data Quality
  portfolio_data.CALCULATION_TIMESTAMP as CALCULATION_TIMESTAMP
    WITH SYNONYMS = ('calculation time', 'data timestamp', 'calculated at', 'last updated')
    comment='When this portfolio aggregation was last calculated'
);

-- Note: Semantic views inherit permissions from underlying tables, no explicit GRANT needed

SELECT 'Created LOAS_SV_PORTFOLIO_CURRENT semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 2: LTV Distribution & Risk Analysis
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LOAS_SV_LTV_DISTRIBUTION
tables (
  ltv_data AS LOAR_AGG_DT_LTV_DISTRIBUTION
    COMMENT = 'LTV distribution by buckets for risk concentration analysis'
)

facts (
  ltv_data.AS_OF_DATE as AS_OF_DATE
    WITH SYNONYMS = ('reporting date', 'date', 'snapshot date')
    comment='Date of LTV distribution snapshot',
  
  ltv_data.LTV_BUCKET as LTV_BUCKET
    WITH SYNONYMS = ('LTV band', 'LTV range', 'LTV category', 'risk bucket')
    comment='LTV bucket: 0-50%, 50-60%, 60-70%, 70-80%, 80-90%, >90%',
  
  ltv_data.LTV_BUCKET_SORT_ORDER as LTV_BUCKET_SORT_ORDER
    WITH SYNONYMS = ('sort order', 'bucket order')
    comment='Sort order for LTV buckets (1-6)',
  
  ltv_data.LOAN_COUNT as LOAN_COUNT
    WITH SYNONYMS = ('count', 'number of loans', 'loan volume', 'loans in bucket')
    comment='Number of loans in this LTV bucket',
  
  ltv_data.TOTAL_LOAN_AMOUNT as TOTAL_LOAN_AMOUNT
    WITH SYNONYMS = ('total amount', 'total exposure', 'loan amount', 'exposure in bucket')
    comment='Total loan amount in this LTV bucket (CHF)',
  
  ltv_data.AVG_LTV_PCT as AVG_LTV_PCT
    WITH SYNONYMS = ('average LTV', 'mean LTV', 'LTV percentage', 'average loan to value')
    comment='Average LTV percentage in this bucket',
  
  ltv_data.TOTAL_COLLATERAL_VALUE as TOTAL_COLLATERAL_VALUE
    WITH SYNONYMS = ('collateral value', 'property value', 'total collateral', 'asset value')
    comment='Total collateral value in this bucket (CHF)',
  
  ltv_data.PCT_OF_TOTAL_LOANS as PCT_OF_TOTAL_LOANS
    WITH SYNONYMS = ('percentage of loans', 'loan concentration', 'portfolio percentage', 'share of portfolio')
    comment='Percentage of total loan count in this bucket',
  
  ltv_data.CALCULATION_TIMESTAMP as CALCULATION_TIMESTAMP
    WITH SYNONYMS = ('calculation time', 'calculated at', 'last updated')
    comment='When this LTV distribution was last calculated'
);

SELECT 'Created LOAS_SV_LTV_DISTRIBUTION semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 3: Application Funnel & Conversion Metrics
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LOAS_SV_APPLICATION_FUNNEL
tables (
  funnel_data AS LOAR_AGG_DT_APPLICATION_FUNNEL
    COMMENT = 'Application volumes and conversion rates by product, country, and channel'
)

facts (
  funnel_data.AS_OF_DATE as AS_OF_DATE
    WITH SYNONYMS = ('reporting date', 'date', 'snapshot date')
    comment='Date of application funnel snapshot',
  
  funnel_data.PRODUCT_TYPE as PRODUCT_TYPE
    WITH SYNONYMS = ('product', 'loan type', 'loan product')
    comment='Product type: MORTGAGE, PERSONAL_LOAN',
  
  funnel_data.COUNTRY as COUNTRY
    WITH SYNONYMS = ('country code', 'jurisdiction', 'market')
    comment='Country code: CHE, GBR, DEU, PRT',
  
  funnel_data.CHANNEL as CHANNEL
    WITH SYNONYMS = ('application channel', 'source channel', 'origination channel', 'source')
    comment='Application channel: EMAIL, PORTAL, BRANCH, BROKER',
  
  funnel_data.TOTAL_APPLICATIONS as TOTAL_APPLICATIONS
    WITH SYNONYMS = ('total apps', 'application count', 'total volume', 'applications received')
    comment='Total number of applications received',
  
  funnel_data.APPROVED_COUNT as APPROVED_COUNT
    WITH SYNONYMS = ('approved', 'approved apps', 'approvals', 'approved applications')
    comment='Number of approved applications',
  
  funnel_data.DECLINED_COUNT as DECLINED_COUNT
    WITH SYNONYMS = ('declined', 'declined apps', 'declines', 'rejected', 'declined applications')
    comment='Number of declined applications',
  
  funnel_data.UNDER_REVIEW_COUNT as UNDER_REVIEW_COUNT
    WITH SYNONYMS = ('under review', 'in review', 'pending', 'pending review', 'in progress')
    comment='Number of applications currently under review',
  
  funnel_data.APPROVAL_RATE_PCT as APPROVAL_RATE_PCT
    WITH SYNONYMS = ('approval rate', 'approval percentage', 'conversion rate', 'success rate')
    comment='Approval rate percentage (approved / total applications)',
  
  funnel_data.DECLINE_RATE_PCT as DECLINE_RATE_PCT
    WITH SYNONYMS = ('decline rate', 'decline percentage', 'rejection rate', 'failure rate')
    comment='Decline rate percentage (declined / total applications)',
  
  funnel_data.AVG_REQUESTED_AMOUNT as AVG_REQUESTED_AMOUNT
    WITH SYNONYMS = ('average amount', 'average loan', 'mean amount', 'average loan size')
    comment='Average requested loan amount in CHF',
  
  funnel_data.CALCULATION_TIMESTAMP as CALCULATION_TIMESTAMP
    WITH SYNONYMS = ('calculation time', 'calculated at', 'last updated')
    comment='When this funnel data was last calculated'
);

SELECT 'Created LOAS_SV_APPLICATION_FUNNEL semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 4: Affordability Analysis
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LOAS_SV_AFFORDABILITY_ANALYSIS
tables (
  affordability_data AS LOAR_AGG_DT_AFFORDABILITY_SUMMARY
    COMMENT = 'Affordability assessment pass/fail rates by country'
)

facts (
  affordability_data.AS_OF_DATE as AS_OF_DATE
    WITH SYNONYMS = ('reporting date', 'date', 'snapshot date')
    comment='Date of affordability analysis snapshot',
  
  affordability_data.COUNTRY as COUNTRY
    WITH SYNONYMS = ('country code', 'jurisdiction', 'market', 'regime')
    comment='Country code: CHE, GBR, DEU',
  
  affordability_data.AFFORDABILITY_RESULT as AFFORDABILITY_RESULT
    WITH SYNONYMS = ('result', 'outcome', 'assessment result', 'pass or fail', 'affordability outcome')
    comment='Affordability assessment result: PASS, FAIL',
  
  affordability_data.ASSESSMENT_COUNT as ASSESSMENT_COUNT
    WITH SYNONYMS = ('count', 'number of assessments', 'assessments', 'volume')
    comment='Number of affordability assessments performed',
  
  affordability_data.AVG_DTI_RATIO_PCT as AVG_DTI_RATIO_PCT
    WITH SYNONYMS = ('DTI', 'debt to income', 'DTI ratio', 'average DTI', 'debt to income ratio')
    comment='Average Debt-to-Income ratio percentage',
  
  affordability_data.AVG_DSTI_RATIO_PCT as AVG_DSTI_RATIO_PCT
    WITH SYNONYMS = ('DSTI', 'debt service to income', 'DSTI ratio', 'average DSTI')
    comment='Average Debt Service-to-Income ratio percentage',
  
  affordability_data.AVG_GROSS_INCOME as AVG_GROSS_INCOME
    WITH SYNONYMS = ('average income', 'mean income', 'gross income', 'monthly income')
    comment='Average gross monthly income in CHF',
  
  affordability_data.AVG_DEBT_OBLIGATIONS as AVG_DEBT_OBLIGATIONS
    WITH SYNONYMS = ('average debt', 'monthly debt', 'debt obligations', 'existing debts')
    comment='Average monthly debt obligations in CHF',
  
  affordability_data.PASS_RATE_PCT as PASS_RATE_PCT
    WITH SYNONYMS = ('pass rate', 'pass percentage', 'success rate', 'affordability pass rate')
    comment='Percentage of affordability assessments that passed',
  
  affordability_data.CALCULATION_TIMESTAMP as CALCULATION_TIMESTAMP
    WITH SYNONYMS = ('calculation time', 'calculated at', 'last updated')
    comment='When this affordability analysis was last calculated'
);

SELECT 'Created LOAS_SV_AFFORDABILITY_ANALYSIS semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 5: Compliance & Screening Integration
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LOAS_SV_COMPLIANCE_SCREENING
tables (
  compliance_data AS LOAR_AGG_VW_COMPLIANCE_SCREENING
    COMMENT = 'Loan applications linked to sanctions and PEP screening status'
)

facts (
  compliance_data.APPLICATION_ID as APPLICATION_ID
    WITH SYNONYMS = ('app id', 'application number', 'loan id', 'reference number')
    comment='Unique application identifier',
  
  compliance_data.CUSTOMER_ID as CUSTOMER_ID
    WITH SYNONYMS = ('customer number', 'client id', 'customer reference')
    comment='Customer identifier (FK to Customer 360)',
  
  compliance_data.FULL_NAME as FULL_NAME
    WITH SYNONYMS = ('name', 'customer name', 'applicant name', 'client name')
    comment='Customer full name',
  
  compliance_data.COUNTRY as COUNTRY
    WITH SYNONYMS = ('country code', 'jurisdiction', 'market')
    comment='Country code for application',
  
  compliance_data.REQUESTED_AMOUNT as REQUESTED_AMOUNT
    WITH SYNONYMS = ('loan amount', 'requested loan', 'amount', 'loan value')
    comment='Requested loan amount in CHF',
  
  compliance_data.APPLICATION_STATUS as APPLICATION_STATUS
    WITH SYNONYMS = ('status', 'application state', 'loan status')
    comment='Application status: APPROVED, DECLINED, UNDER_REVIEW',
  
  compliance_data.REQUIRES_SANCTIONS_REVIEW as REQUIRES_SANCTIONS_REVIEW
    WITH SYNONYMS = ('sanctions flag', 'sanctions review', 'sanctions hit', 'sanctions match')
    comment='Boolean flag: TRUE if customer requires sanctions compliance review',
  
  compliance_data.REQUIRES_EXPOSED_PERSON_REVIEW as REQUIRES_EXPOSED_PERSON_REVIEW
    WITH SYNONYMS = ('PEP flag', 'PEP review', 'PEP hit', 'politically exposed person', 'exposed person')
    comment='Boolean flag: TRUE if customer requires PEP compliance review',
  
  compliance_data.OVERALL_RISK_RATING as OVERALL_RISK_RATING
    WITH SYNONYMS = ('risk rating', 'risk level', 'risk classification', 'customer risk')
    comment='Overall risk rating: CRITICAL, HIGH, MEDIUM, LOW, NO_RISK',
  
  compliance_data.VULNERABLE_CUSTOMER_FLAG as VULNERABLE_CUSTOMER_FLAG
    WITH SYNONYMS = ('vulnerable flag', 'vulnerability', 'vulnerable customer', 'vulnerable')
    comment='Boolean flag: TRUE if customer has vulnerability characteristics',
  
  compliance_data.SANCTIONS_MATCH_NAME as SANCTIONS_MATCH_NAME
    WITH SYNONYMS = ('sanctions name', 'sanctioned entity', 'sanctions match')
    comment='Name of sanctions entity matched (if any)',
  
  compliance_data.SANCTIONS_AUTHORITY as SANCTIONS_AUTHORITY
    WITH SYNONYMS = ('sanctioning authority', 'sanctions issuer', 'authority')
    comment='Sanctioning authority: OFAC, EU, UN',
  
  compliance_data.SANCTIONS_RISK_SCORE as SANCTIONS_RISK_SCORE
    WITH SYNONYMS = ('sanctions score', 'risk score')
    comment='Sanctions risk score (0-100)',
  
  compliance_data.EXPOSED_PERSON_EXACT_MATCH_NAME as EXPOSED_PERSON_EXACT_MATCH_NAME
    WITH SYNONYMS = ('PEP name', 'PEP match', 'politically exposed person name')
    comment='Name of PEP matched (if exact match)',
  
  compliance_data.EXPOSED_PERSON_EXACT_CATEGORY as EXPOSED_PERSON_EXACT_CATEGORY
    WITH SYNONYMS = ('PEP category', 'PEP type', 'exposed person category')
    comment='PEP category: DOMESTIC, FOREIGN, INTERNATIONAL',
  
  compliance_data.EXPOSED_PERSON_EXACT_RISK_LEVEL as EXPOSED_PERSON_EXACT_RISK_LEVEL
    WITH SYNONYMS = ('PEP risk level', 'PEP risk', 'exposed person risk')
    comment='PEP risk level: CRITICAL, HIGH, MEDIUM, LOW',
  
  compliance_data.EXPOSED_PERSON_MATCH_TYPE as EXPOSED_PERSON_MATCH_TYPE
    WITH SYNONYMS = ('PEP match type', 'match type')
    comment='PEP match type: EXACT_MATCH, FUZZY_MATCH, NO_MATCH',
  
  compliance_data.APPLICATION_DATE_TIME as APPLICATION_DATE_TIME
    WITH SYNONYMS = ('application date', 'submitted date', 'application time', 'submission date')
    comment='Date and time when application was submitted',
  
  compliance_data.COMPLIANCE_HOLD_FLAG as COMPLIANCE_HOLD_FLAG
    WITH SYNONYMS = ('hold flag', 'compliance hold', 'blocked', 'on hold')
    comment='Boolean flag: TRUE if application is on compliance hold',
  
  compliance_data.COMPLIANCE_STATUS as COMPLIANCE_STATUS
    WITH SYNONYMS = ('compliance state', 'review status', 'compliance outcome')
    comment='Compliance status: SANCTIONS_REVIEW, PEP_REVIEW, HIGH_RISK_REVIEW, CLEAR'
);

SELECT 'Created LOAS_SV_COMPLIANCE_SCREENING semantic view' AS status;

-- ============================================================================
-- COMPLETION STATUS
-- ============================================================================
-- ✅ Loan Portfolio Semantic Views Deployed (REP_AGG_001)
--
-- OBJECTS CREATED:
-- • 5 Semantic Views for Cortex Analyst AI Agent:
--   1. LOAS_SV_PORTFOLIO_CURRENT - Portfolio summary with counts and amounts
--   2. LOAS_SV_LTV_DISTRIBUTION - LTV risk concentration analysis
--   3. LOAS_SV_APPLICATION_FUNNEL - Application volumes and conversion rates
--   4. LOAS_SV_AFFORDABILITY_ANALYSIS - DTI/DSTI pass/fail analysis
--   5. LOAS_SV_COMPLIANCE_SCREENING - Sanctions/PEP screening integration
--
-- FEATURES:
-- • Rich synonyms for natural language queries
-- • Comprehensive comments for AI agent context
-- • Aligned with regular views in 565_LOAR_loans_portfolio_reporting.sql
-- • Ready for use by Cortex Analyst AI agent (865_LOAN_PORTFOLIO_AGENT.sql)
--
-- NEXT STEPS:
-- 1. Deploy this file: snow sql -f structure/765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql
-- 2. Create AI agent: structure/865_LOAN_PORTFOLIO_AGENT.sql
-- 3. Test natural language queries
--
-- ============================================================================
