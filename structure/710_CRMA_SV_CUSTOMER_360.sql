-- ============================================================================
-- 710_CRMA_SV_CUSTOMER_360.sql
-- Comprehensive Customer 360° Semantic View
-- ============================================================================
-- Purpose: Unified customer intelligence including profile, compliance, risk,
--          lifecycle, and address data
-- Used by: All notebooks, Streamlit CRM App, AI Agents (MD_2, MD3)
-- Business Value: Foundation for all CRM operations
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================================
-- Main Semantic View: CRMA_SV_CUSTOMER_360
-- ============================================================================
-- 
-- QUERY INTERPRETATION GUIDE:
-- - "Top clients" / "largest clients" / "biggest clients" → Rank by TOTAL_BALANCE (primary wealth indicator)
-- - "Most active clients" / "clients with most transactions" → Rank by TOTAL_TRANSACTIONS
-- - "Clients with most accounts" / "product holdings" → Rank by TOTAL_ACCOUNTS
-- - "By country" / "grouped by country" / "per country" → Use COUNTRY for GROUP BY
-- - "In [country]" / "from [country]" → Use COUNTRY for WHERE clause
-- - When ambiguous, DEFAULT to ranking by TOTAL_BALANCE for "top" queries
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW CRMA_SV_CUSTOMER_360
tables (
  customers AS CRMA_AGG_DT_CUSTOMER_360
    PRIMARY KEY (CUSTOMER_ID)
    COMMENT = 'Customer 360 view with profile, compliance, risk, lifecycle, and address data',
  advisors AS EMPA_AGG_VW_ADVISORS
    PRIMARY KEY (EMPLOYEE_ID)
    COMMENT = 'Advisor performance and client portfolio metrics'
)

relationships (
  customer_to_advisor AS
    customers (CURRENT_ADVISOR_EMPLOYEE_ID) REFERENCES advisors
)

facts (
  -- ===== CUSTOMER IDENTITY & DEMOGRAPHICS =====
  customers.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier | client ID | CIF | customer number | account holder ID | customer code | customer reference',
  customers.FIRST_NAME as FIRST_NAME comment='First name | given name | forename | personal name | Christian name',
  customers.FAMILY_NAME as FAMILY_NAME comment='Family name | last name | surname | family surname | last surname',
  customers.FULL_NAME as FULL_NAME comment='Full name | complete name | customer name | client name | full customer name | PRIMARY identifier for displaying clients in reports and rankings | use for showing "top clients" or "client lists" | human-readable client identifier',
  customers.DATE_OF_BIRTH as DATE_OF_BIRTH comment='Date of birth | DOB | birth date | birthday | birthdate',
  customers.ONBOARDING_DATE as ONBOARDING_DATE comment='Onboarding date | customer since | join date | account opening date | relationship start | joined on',
  customers.REPORTING_CURRENCY as REPORTING_CURRENCY comment='Reporting currency | base currency | home currency | preferred currency | default currency',
  
  -- ===== FRAUD & ANOMALY DETECTION =====
  customers.HAS_ANOMALY as HAS_ANOMALY comment='Anomaly flag | suspicious activity | fraud indicator | unusual pattern | red flag | suspicious flag',
  
  -- ===== EMPLOYMENT & FINANCIAL PROFILE =====
  customers.EMPLOYER as EMPLOYER comment='Employer | company | organization | workplace | employer name | company name',
  customers.POSITION as POSITION comment='Job position | job title | role | occupation | professional title | job role',
  
  -- ===== CONTACT INFORMATION =====
  customers.EMAIL as EMAIL comment='Email address | email | contact email | email ID | electronic mail | e-mail',
  customers.PHONE as PHONE comment='Phone number | telephone | mobile | contact number | phone | cell phone | mobile number',
  customers.PREFERRED_CONTACT_METHOD as PREFERRED_CONTACT_METHOD comment='Preferred contact method | contact preference | communication preference | contact channel | preferred channel',
  
  -- ===== ADDRESS INFORMATION =====
  customers.STREET_ADDRESS as STREET_ADDRESS comment='Street address | residential address | mailing address | physical address | home address | address line',
  customers.ZIPCODE as ZIPCODE comment='Postal code | ZIP code | postcode | area code | zip | post code',
  customers.ADDRESS_EFFECTIVE_DATE as ADDRESS_EFFECTIVE_DATE comment='Address effective date | address since | moved on | relocation date | address start date',
  
  -- ===== CUSTOMER STATUS =====
  customers.STATUS_EFFECTIVE_DATE as STATUS_EFFECTIVE_DATE comment='Status effective date | status since | status change date | status start date',
  
  -- ===== ACCOUNT PORTFOLIO SUMMARY =====
  customers.TOTAL_ACCOUNTS as TOTAL_ACCOUNTS 
    WITH SYNONYMS = ('count', 'number', 'total', 'quantity', 'how many', 'number of accounts')
    comment='Count of accounts. Use for aggregation and "how many accounts" queries',
  customers.ACCOUNT_TYPES as ACCOUNT_TYPES comment='Account types | product types | account categories | product mix | account products',
  customers.CURRENCIES as CURRENCIES comment='Currencies used | currency portfolio | multi-currency | currency mix | currencies held',
  customers.CHECKING_ACCOUNTS as CHECKING_ACCOUNTS comment='Checking accounts | current accounts | transaction accounts | checking products | transactional accounts',
  customers.SAVINGS_ACCOUNTS as SAVINGS_ACCOUNTS comment='Savings accounts | deposit accounts | savings products | term deposits | savings plans',
  customers.BUSINESS_ACCOUNTS as BUSINESS_ACCOUNTS comment='Business accounts | commercial accounts | corporate accounts | business banking | SME accounts',
  customers.INVESTMENT_ACCOUNTS as INVESTMENT_ACCOUNTS comment='Investment accounts | brokerage accounts | trading accounts | securities accounts | investment products',
  
  -- ===== ACCOUNT BALANCES =====
  customers.TOTAL_BALANCE as TOTAL_BALANCE 
    WITH SYNONYMS = ('AUM', 'assets under management', 'total assets', 'managed assets', 'portfolio value', 'balance', 'wealth')
    comment='Total Assets Under Management. Primary metric for advisor performance and client portfolio size ranking',
  customers.CHECKING_BALANCE as CHECKING_BALANCE comment='Checking balance | current account balance | transaction account balance | liquid funds',
  customers.SAVINGS_BALANCE as SAVINGS_BALANCE comment='Savings balance | deposit balance | savings account balance | deposit funds',
  customers.BUSINESS_BALANCE as BUSINESS_BALANCE comment='Business balance | commercial balance | corporate balance | SME balance',
  customers.INVESTMENT_BALANCE as INVESTMENT_BALANCE comment='Investment balance | brokerage balance | securities balance | portfolio balance | invested assets',
  customers.MAX_ACCOUNT_BALANCE as MAX_ACCOUNT_BALANCE comment='Maximum balance | highest balance | peak balance | max portfolio value',
  customers.MIN_ACCOUNT_BALANCE as MIN_ACCOUNT_BALANCE comment='Minimum balance | lowest balance | min portfolio value',
  customers.AVG_ACCOUNT_BALANCE as AVG_ACCOUNT_BALANCE comment='Average balance | mean balance | typical balance',
  customers.BALANCE_AS_OF_DATE as BALANCE_AS_OF_DATE comment='Balance as of date | balance date | valuation date | snapshot date',
  
  -- ===== TRANSACTION PATTERNS =====
  customers.TOTAL_TRANSACTIONS as TOTAL_TRANSACTIONS comment='Total transactions | transaction count | number of transactions | transaction volume | use for ranking by activity level or transaction frequency | use when specifically asked about most active clients or transaction volume | NOT the default for "top clients" (use TOTAL_BALANCE instead)',
  customers.TOTAL_TRANSACTIONS_ALL_TIME as TOTAL_TRANSACTIONS_ALL_TIME comment='Total transactions all time | lifetime transactions | historical transaction count',
  customers.LAST_TRANSACTION_DATE as LAST_TRANSACTION_DATE comment='Last transaction date | most recent transaction | latest transaction | last activity date',
  customers.DAYS_SINCE_LAST_TRANSACTION as DAYS_SINCE_LAST_TRANSACTION comment='Days since last transaction | days inactive | inactivity days | dormancy days',
  customers.DEBIT_TRANSACTIONS as DEBIT_TRANSACTIONS comment='Debit transactions | withdrawals | outgoing transactions | debit count',
  customers.CREDIT_TRANSACTIONS as CREDIT_TRANSACTIONS comment='Credit transactions | deposits | incoming transactions | credit count',
  customers.AVG_MONTHLY_TRANSACTIONS as AVG_MONTHLY_TRANSACTIONS comment='Average monthly transactions | typical monthly activity | avg monthly volume',
  customers.IS_DORMANT_TRANSACTIONALLY as IS_DORMANT_TRANSACTIONALLY comment='Dormant flag | inactive customer | dormant account | no activity | inactive flag',
  customers.IS_HIGHLY_ACTIVE as IS_HIGHLY_ACTIVE comment='Highly active flag | active customer | frequent user | high activity',
  
  -- ===== PEP (POLITICALLY EXPOSED PERSONS) SCREENING =====
  customers.EXPOSED_PERSON_MATCH_TYPE as EXPOSED_PERSON_MATCH_TYPE comment='PEP match type | politically exposed person match | PEP screening result | PEP status | exposed person status',
  customers.EXPOSED_PERSON_MATCH_ACCURACY_PERCENT as EXPOSED_PERSON_MATCH_ACCURACY_PERCENT comment='PEP match accuracy | match confidence | screening accuracy | match percentage | PEP match score',
  customers.EXPOSED_PERSON_EXACT_MATCH_NAME as EXPOSED_PERSON_EXACT_MATCH_NAME comment='PEP exact match name | PEP name match | exact PEP hit',
  customers.EXPOSED_PERSON_FUZZY_MATCH_NAME as EXPOSED_PERSON_FUZZY_MATCH_NAME comment='PEP fuzzy match name | similar PEP name | probable PEP match',
  customers.EXPOSED_PERSON_EXACT_CATEGORY as EXPOSED_PERSON_EXACT_CATEGORY comment='PEP category | PEP type | exposed person category | PEP classification',
  customers.EXPOSED_PERSON_EXACT_RISK_LEVEL as EXPOSED_PERSON_EXACT_RISK_LEVEL comment='PEP risk level | exposed person risk | PEP risk category',
  
  -- ===== SANCTIONS SCREENING =====
  customers.SANCTIONS_MATCH_TYPE as SANCTIONS_MATCH_TYPE comment='Sanctions match type | watchlist match | sanctions screening result | sanctions status | watchlist status',
  customers.SANCTIONS_MATCH_ACCURACY_PERCENT as SANCTIONS_MATCH_ACCURACY_PERCENT comment='Sanctions match accuracy | match confidence | screening accuracy | match percentage | sanctions match score',
  customers.SANCTIONS_EXACT_MATCH_NAME as SANCTIONS_EXACT_MATCH_NAME comment='Sanctions exact match name | watchlist name match | exact sanctions hit',
  customers.SANCTIONS_FUZZY_MATCH_NAME as SANCTIONS_FUZZY_MATCH_NAME comment='Sanctions fuzzy match name | similar sanctions name | probable sanctions match',
  customers.SANCTIONS_EXACT_MATCH_COUNTRY as SANCTIONS_EXACT_MATCH_COUNTRY comment='Sanctions country | sanctioned country | watchlist country',
  
  -- ===== COMPLIANCE & RISK SCORING =====
  customers.OVERALL_EXPOSED_PERSON_RISK as OVERALL_EXPOSED_PERSON_RISK comment='Overall PEP risk | politically exposed person risk | PEP risk level | PEP risk rating | exposed person risk score',
  customers.OVERALL_SANCTIONS_RISK as OVERALL_SANCTIONS_RISK comment='Overall sanctions risk | watchlist risk | sanctions risk level | sanctions risk rating | sanctions risk score',
  customers.OVERALL_RISK_RATING as OVERALL_RISK_RATING comment='Overall risk rating | comprehensive risk | total risk | risk assessment | combined risk | aggregate risk',
  customers.OVERALL_RISK_SCORE as OVERALL_RISK_SCORE comment='Overall risk score | risk number | numerical risk | risk points | risk value | total risk score',
  customers.REQUIRES_EXPOSED_PERSON_REVIEW as REQUIRES_EXPOSED_PERSON_REVIEW comment='Requires PEP review | needs PEP check | PEP review flag | exposed person review required | PEP review needed',
  customers.REQUIRES_SANCTIONS_REVIEW as REQUIRES_SANCTIONS_REVIEW comment='Requires sanctions review | needs sanctions check | sanctions review flag | watchlist review required | sanctions review needed',
  customers.HIGH_RISK_CUSTOMER as HIGH_RISK_CUSTOMER comment='High risk customer | high risk flag | risky customer | elevated risk | risk alert | high-risk indicator',
  
  -- ===== ADVISOR ASSIGNMENT =====
  customers.CURRENT_ADVISOR_EMPLOYEE_ID as CURRENT_ADVISOR_EMPLOYEE_ID comment='Current advisor | assigned advisor | relationship manager | advisor ID | employee ID | advisor assignment',
  customers.ADVISOR_ASSIGNMENT_START_DATE as ADVISOR_ASSIGNMENT_START_DATE comment='Advisor assignment date | assignment start | relationship start | advisor since | assigned since',
  
  -- ===== DATA FRESHNESS =====
  customers.LAST_UPDATED as LAST_UPDATED comment='Last updated timestamp | refresh timestamp | data freshness | update time | last refresh'
)

dimensions (
  -- ===== PRIMARY GROUPING DIMENSIONS =====
  customers.COUNTRY AS COUNTRY 
    WITH SYNONYMS = ('country', 'nation', 'geography', 'location', 'region')
    COMMENT = 'Country code or name. Primary dimension for geographic grouping. Use with "by country" or "per country" queries',
  customers.ACCOUNT_TIER AS ACCOUNT_TIER 
    WITH SYNONYMS = ('tier', 'service level', 'customer segment', 'membership level')
    COMMENT = 'Account tier (PLATINUM, GOLD, SILVER, BRONZE). Primary dimension for customer segmentation',
  customers.CURRENT_STATUS AS CURRENT_STATUS 
    WITH SYNONYMS = ('status', 'active', 'inactive', 'customer status')
    COMMENT = 'Customer status (ACTIVE, INACTIVE, CLOSED). Use for filtering active customers',
  customers.RISK_CLASSIFICATION AS RISK_CLASSIFICATION 
    WITH SYNONYMS = ('risk level', 'risk category', 'risk rating')
    COMMENT = 'Risk classification (LOW_RISK, MEDIUM_RISK, HIGH_RISK). Use for risk-based grouping',
  
  -- ===== SECONDARY DIMENSIONS =====
  customers.CITY AS CITY COMMENT = 'City for geographic analysis',
  customers.STATE AS STATE COMMENT = 'State/province for regional grouping',
  customers.EMPLOYMENT_TYPE AS EMPLOYMENT_TYPE COMMENT = 'Employment type for demographic analysis',
  customers.INCOME_RANGE AS INCOME_RANGE COMMENT = 'Income range for customer segmentation',
  customers.CREDIT_SCORE_BAND AS CREDIT_SCORE_BAND COMMENT = 'Credit score band for risk grouping'
)

metrics (
  -- ===== PRIMARY METRICS =====
  customers.CUSTOMER_COUNT AS COUNT(customers.CUSTOMER_ID)
    WITH SYNONYMS = ('number of customers', 'customer count', 'how many customers', 'total customers')
    COMMENT = 'Count of customers. DEFAULT metric for counting.
               EXAMPLES: "How many customers per country?" → COUNT(CUSTOMER_ID) GROUP BY COUNTRY
                        "Top 10 countries by customer count" → COUNT(CUSTOMER_ID) GROUP BY COUNTRY LIMIT 10
                        "How many PLATINUM customers?" → COUNT WHERE ACCOUNT_TIER = PLATINUM',
  customers.TOTAL_BALANCE_SUM AS SUM(customers.TOTAL_BALANCE)
    WITH SYNONYMS = ('total AUM', 'total assets', 'total balance', 'sum of balances')
    COMMENT = 'Sum of all customer balances. Use for wealth/AUM aggregation.
               EXAMPLES: "Top 10 clients by total AUM" → ORDER BY TOTAL_BALANCE DESC LIMIT 10
                        "Total AUM by country" → SUM(TOTAL_BALANCE) GROUP BY COUNTRY
                        "Which tier has highest total assets?" → SUM(TOTAL_BALANCE) GROUP BY ACCOUNT_TIER',
  customers.AVG_BALANCE AS AVG(customers.TOTAL_BALANCE)
    WITH SYNONYMS = ('average balance', 'mean balance', 'average AUM')
    COMMENT = 'Average customer balance. Use for typical customer value.
               EXAMPLES: "Average balance by country" → AVG(TOTAL_BALANCE) GROUP BY COUNTRY
                        "Which country has highest average wealth?" → AVG(TOTAL_BALANCE) GROUP BY COUNTRY'
);

-- Note: Advisor details (FULL_NAME, TOTAL_CLIENTS, TOTAL_AUM) are accessible through
--       the customer_to_advisor relationship but are not directly exposed as facts
--       in this semantic view. Use EMPA_SV_EMPLOYEE_ADVISOR for advisor-centric queries.

-- ============================================================================
-- Permissions
-- ============================================================================

-- Semantic views don't need explicit grants in the same way as regular views
-- Access is controlled through the underlying table permissions
GRANT SELECT ON TABLE CRMA_AGG_DT_CUSTOMER_360 TO ROLE ACCOUNTADMIN;
GRANT SELECT ON TABLE CRMA_AGG_DT_CUSTOMER_360 TO ROLE PUBLIC;

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test basic query
-- SELECT COUNT(*) AS total_customers FROM CRMA_SV_CUSTOMER_360;

-- Test consolidated data (lifecycle + address)
-- SELECT 
--   full_name,
--   risk_rating,
--   lifecycle_stage,
--   churn_probability,
--   city,
--   country
-- FROM CRMA_SV_CUSTOMER_360
-- WHERE account_tier = 'PLATINUM'
--   AND country = 'Switzerland'
--   AND is_dormant = TRUE
-- LIMIT 10;

-- Test complex compliance query
-- SELECT 
--   customer_id,
--   full_name,
--   risk_rating,
--   pep_status,
--   sanctions_match_type,
--   lifecycle_stage,
--   churn_probability,
--   city,
--   address_country
-- FROM CRMA_SV_CUSTOMER_360
-- WHERE (requires_pep_review = TRUE OR requires_sanctions_review = TRUE)
--   AND account_tier IN ('PLATINUM', 'GOLD')
--   AND is_at_risk = TRUE
-- ORDER BY risk_score DESC
-- LIMIT 20;

-- ============================================================================
-- Deployment Success Message
-- ============================================================================

SELECT 'CRMA_SV_CUSTOMER_360 created successfully! Consolidated 4 CRM views into 1 unified customer 360° view.' AS STATUS;

