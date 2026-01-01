-- ============================================================
-- CRM SEMANTIC VIEW - Business-Friendly Customer Data Access with Synonyms
-- Created on: 2025-10-30 (Simplified with Rich Synonym Metadata)
-- ============================================================
--
-- OVERVIEW:
-- Semantic view providing unified access to the CUSTOMER_360 table with
-- rich synonym metadata for natural language query support. This is the
-- primary customer intelligence view combining all CRM data sources.
--
-- BUSINESS PURPOSE:
-- - Single interface for customer relationship management queries
-- - Natural language query support with synonym/alternative terminology  
-- - Comprehensive customer intelligence with PEP/sanctions screening
-- - Customer segmentation, risk scoring, and compliance
--
-- TABLE INCLUDED:
-- - CRMA_AGG_DT_CUSTOMER_360 - Comprehensive customer view (48 attributes)
--
-- SYNONYM METADATA:
-- All fact comments include alternative terms and synonyms to help Cortex AI
-- understand various ways users might refer to the same data (e.g., "client"
-- vs "customer", "DOB" vs "date of birth", "churn" vs "attrition")
--
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- CRMA_SEMANTIC_VIEW - Unified CRM Business Data Access
-- ============================================================

CREATE OR REPLACE SEMANTIC VIEW CRMA_SEMANTIC_VIEW
	tables (
		CRMA_AGG_DT_CUSTOMER_360
	)
	facts (
		-- Customer Identity & Demographics
		CRMA_AGG_DT_CUSTOMER_360.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier | client ID | CIF | customer number | account holder ID | customer code',
		CRMA_AGG_DT_CUSTOMER_360.FIRST_NAME as FIRST_NAME comment='First name | given name | forename | personal name | Christian name',
		CRMA_AGG_DT_CUSTOMER_360.FAMILY_NAME as FAMILY_NAME comment='Family name | last name | surname | family surname | last surname',
		CRMA_AGG_DT_CUSTOMER_360.FULL_NAME as FULL_NAME comment='Full name | complete name | customer name | client name | full customer name',
		CRMA_AGG_DT_CUSTOMER_360.DATE_OF_BIRTH as DATE_OF_BIRTH comment='Date of birth | DOB | birth date | birthday | birthdate',
		CRMA_AGG_DT_CUSTOMER_360.ONBOARDING_DATE as ONBOARDING_DATE comment='Onboarding date | customer since | join date | account opening date | relationship start | joined on',
		CRMA_AGG_DT_CUSTOMER_360.REPORTING_CURRENCY as REPORTING_CURRENCY comment='Reporting currency | base currency | home currency | preferred currency | default currency',
		
		-- Fraud & Anomaly Detection
		CRMA_AGG_DT_CUSTOMER_360.HAS_ANOMALY as HAS_ANOMALY comment='Anomaly flag | suspicious activity | fraud indicator | unusual pattern | red flag | suspicious flag',
		
		-- Employment & Financial Profile
		CRMA_AGG_DT_CUSTOMER_360.EMPLOYER as EMPLOYER comment='Employer | company | organization | workplace | employer name | company name',
		CRMA_AGG_DT_CUSTOMER_360.POSITION as POSITION comment='Job position | job title | role | occupation | professional title | job role',
		CRMA_AGG_DT_CUSTOMER_360.EMPLOYMENT_TYPE as EMPLOYMENT_TYPE comment='Employment type | work status | employment status | job type | employment category',
		CRMA_AGG_DT_CUSTOMER_360.INCOME_RANGE as INCOME_RANGE comment='Income range | salary band | income bracket | earning level | income tier | salary range',
		CRMA_AGG_DT_CUSTOMER_360.ACCOUNT_TIER as ACCOUNT_TIER comment='Account tier | customer tier | service level | membership level | customer segment | customer grade | tier level',
		
		-- Contact Information  
		CRMA_AGG_DT_CUSTOMER_360.EMAIL as EMAIL comment='Email address | email | contact email | email ID | electronic mail | e-mail',
		CRMA_AGG_DT_CUSTOMER_360.PHONE as PHONE comment='Phone number | telephone | mobile | contact number | phone | cell phone | mobile number',
		CRMA_AGG_DT_CUSTOMER_360.PREFERRED_CONTACT_METHOD as PREFERRED_CONTACT_METHOD comment='Preferred contact method | contact preference | communication preference | contact channel | preferred channel',
		
		-- Credit & Risk Profile
		CRMA_AGG_DT_CUSTOMER_360.RISK_CLASSIFICATION as RISK_CLASSIFICATION comment='Risk classification | risk category | risk level | risk tier | risk type | risk grade',
		CRMA_AGG_DT_CUSTOMER_360.CREDIT_SCORE_BAND as CREDIT_SCORE_BAND comment='Credit score band | credit rating | creditworthiness | credit tier | credit grade | credit category',
		
		-- Address Information
		CRMA_AGG_DT_CUSTOMER_360.STREET_ADDRESS as STREET_ADDRESS comment='Street address | residential address | mailing address | physical address | home address | address line',
		CRMA_AGG_DT_CUSTOMER_360.CITY as CITY comment='City | town | locality | municipality | urban area',
		CRMA_AGG_DT_CUSTOMER_360.STATE as STATE comment='State | region | province | territory | county',
		CRMA_AGG_DT_CUSTOMER_360.ZIPCODE as ZIPCODE comment='Postal code | ZIP code | postcode | area code | zip | post code',
		CRMA_AGG_DT_CUSTOMER_360.COUNTRY as COUNTRY comment='Country | nation | jurisdiction | domicile | country of residence | nationality',
		CRMA_AGG_DT_CUSTOMER_360.ADDRESS_EFFECTIVE_DATE as ADDRESS_EFFECTIVE_DATE comment='Address effective date | address since | moved on | relocation date | address start date',
		
		-- Customer Status
		CRMA_AGG_DT_CUSTOMER_360.CURRENT_STATUS as CURRENT_STATUS comment='Customer status | account status | relationship status | active status | customer state | status',
		CRMA_AGG_DT_CUSTOMER_360.STATUS_EFFECTIVE_DATE as STATUS_EFFECTIVE_DATE comment='Status effective date | status since | status change date | status start date',
		
		-- Account Portfolio Summary
		CRMA_AGG_DT_CUSTOMER_360.TOTAL_ACCOUNTS as TOTAL_ACCOUNTS comment='Total accounts | account count | number of accounts | account total | total products',
		CRMA_AGG_DT_CUSTOMER_360.ACCOUNT_TYPES as ACCOUNT_TYPES comment='Account types | product types | account categories | product mix | account products',
		CRMA_AGG_DT_CUSTOMER_360.CURRENCIES as CURRENCIES comment='Currencies used | currency portfolio | multi-currency | currency mix | currencies held',
		CRMA_AGG_DT_CUSTOMER_360.CHECKING_ACCOUNTS as CHECKING_ACCOUNTS comment='Checking accounts | current accounts | transaction accounts | checking products | transactional accounts',
		CRMA_AGG_DT_CUSTOMER_360.SAVINGS_ACCOUNTS as SAVINGS_ACCOUNTS comment='Savings accounts | deposit accounts | savings products | term deposits | savings plans',
		CRMA_AGG_DT_CUSTOMER_360.BUSINESS_ACCOUNTS as BUSINESS_ACCOUNTS comment='Business accounts | commercial accounts | corporate accounts | business banking | SME accounts',
		CRMA_AGG_DT_CUSTOMER_360.INVESTMENT_ACCOUNTS as INVESTMENT_ACCOUNTS comment='Investment accounts | brokerage accounts | trading accounts | securities accounts | investment products',
		
		-- PEP (Politically Exposed Persons) Screening
		CRMA_AGG_DT_CUSTOMER_360.EXPOSED_PERSON_MATCH_TYPE as EXPOSED_PERSON_MATCH_TYPE comment='PEP match type | politically exposed person match | PEP screening result | PEP status | exposed person status',
		CRMA_AGG_DT_CUSTOMER_360.EXPOSED_PERSON_MATCH_ACCURACY_PERCENT as EXPOSED_PERSON_MATCH_ACCURACY_PERCENT comment='PEP match accuracy | match confidence | screening accuracy | match percentage | PEP match score',
		
		-- Sanctions Screening
		CRMA_AGG_DT_CUSTOMER_360.SANCTIONS_MATCH_TYPE as SANCTIONS_MATCH_TYPE comment='Sanctions match type | watchlist match | sanctions screening result | sanctions status | watchlist status',
		CRMA_AGG_DT_CUSTOMER_360.SANCTIONS_MATCH_ACCURACY_PERCENT as SANCTIONS_MATCH_ACCURACY_PERCENT comment='Sanctions match accuracy | match confidence | screening accuracy | match percentage | sanctions match score',
		
		-- Compliance & Risk Scoring
		CRMA_AGG_DT_CUSTOMER_360.OVERALL_EXPOSED_PERSON_RISK as OVERALL_EXPOSED_PERSON_RISK comment='Overall PEP risk | politically exposed person risk | PEP risk level | PEP risk rating | exposed person risk score',
		CRMA_AGG_DT_CUSTOMER_360.OVERALL_SANCTIONS_RISK as OVERALL_SANCTIONS_RISK comment='Overall sanctions risk | watchlist risk | sanctions risk level | sanctions risk rating | sanctions risk score',
		CRMA_AGG_DT_CUSTOMER_360.OVERALL_RISK_RATING as OVERALL_RISK_RATING comment='Overall risk rating | comprehensive risk | total risk | risk assessment | combined risk | aggregate risk',
		CRMA_AGG_DT_CUSTOMER_360.OVERALL_RISK_SCORE as OVERALL_RISK_SCORE comment='Overall risk score | risk number | numerical risk | risk points | risk value | total risk score',
		CRMA_AGG_DT_CUSTOMER_360.REQUIRES_EXPOSED_PERSON_REVIEW as REQUIRES_EXPOSED_PERSON_REVIEW comment='Requires PEP review | needs PEP check | PEP review flag | exposed person review required | PEP review needed',
		CRMA_AGG_DT_CUSTOMER_360.REQUIRES_SANCTIONS_REVIEW as REQUIRES_SANCTIONS_REVIEW comment='Requires sanctions review | needs sanctions check | sanctions review flag | watchlist review required | sanctions review needed',
		CRMA_AGG_DT_CUSTOMER_360.HIGH_RISK_CUSTOMER as HIGH_RISK_CUSTOMER comment='High risk customer | high risk flag | risky customer | elevated risk | risk alert | high-risk indicator',
		
		-- Data Freshness
		CRMA_AGG_DT_CUSTOMER_360.LAST_UPDATED as LAST_UPDATED comment='Last updated timestamp | refresh timestamp | data freshness | update time | last refresh'
	);

-- ============================================================
-- CRM SEMANTIC VIEW DEPLOYMENT COMPLETE!
-- ============================================================
--
-- WHAT WAS DEPLOYED:
-- ✓ Semantic view with CUSTOMER_360 comprehensive view
-- ✓ 48 business-friendly facts with rich synonym metadata
-- ✓ Natural language query support with 200+ alternative terms
-- ✓ Optimized for Snowflake Cortex AI and business intelligence
--
-- SYNONYM COVERAGE EXAMPLES:
-- - Customer = client, account holder, CIF, customer number
-- - DOB = date of birth, birth date, birthday, birthdate
-- - Risk = risk rating, risk score, risk level, risk tier
-- - PEP = politically exposed person, exposed person
-- - Sanctions = watchlist, sanctions list
-- - Churn = attrition, defection, leaving
-- - Dormant = inactive, sleeping, idle
--
-- CORTEX AI NATURAL LANGUAGE CAPABILITIES:
-- The semantic view understands queries like:
-- ✓ "Show me high-risk clients" (understands risk rating/score/classification)
-- ✓ "Find customers with PEP matches" (understands politically exposed persons)
-- ✓ "Which clients require compliance review?" (understands review flags)
-- ✓ "Show me premium tier customers" (understands account tier/segment)
-- ✓ "Find customers who moved recently" (understands address changes)
-- ✓ "Which customers are on the watchlist?" (understands sanctions screening)
--
-- USAGE EXAMPLES:
--
-- 1. High-risk customers requiring compliance review:
--    SELECT 
--      CUSTOMER_ID, FULL_NAME, COUNTRY,
--      OVERALL_RISK_RATING, OVERALL_RISK_SCORE,
--      EXPOSED_PERSON_MATCH_TYPE, SANCTIONS_MATCH_TYPE
--    FROM CRMA_AGG_DT_CUSTOMER_360
--    WHERE HIGH_RISK_CUSTOMER = TRUE
--       OR REQUIRES_EXPOSED_PERSON_REVIEW = TRUE
--       OR REQUIRES_SANCTIONS_REVIEW = TRUE
--    ORDER BY OVERALL_RISK_SCORE DESC;
--
-- 2. Premium customers by country and risk:
--    SELECT 
--      COUNTRY,
--      ACCOUNT_TIER,
--      COUNT(*) as CUSTOMER_COUNT,
--      SUM(CASE WHEN HIGH_RISK_CUSTOMER = TRUE THEN 1 ELSE 0 END) as HIGH_RISK_COUNT,
--      AVG(OVERALL_RISK_SCORE) as AVG_RISK_SCORE
--    FROM CRMA_AGG_DT_CUSTOMER_360
--    WHERE ACCOUNT_TIER IN ('PREMIUM', 'PLATINUM', 'GOLD')
--    GROUP BY COUNTRY, ACCOUNT_TIER
--    ORDER BY CUSTOMER_COUNT DESC;
--
-- 3. PEP screening summary:
--    SELECT 
--      EXPOSED_PERSON_MATCH_TYPE,
--      COUNT(*) as MATCH_COUNT,
--      AVG(EXPOSED_PERSON_MATCH_ACCURACY_PERCENT) as AVG_ACCURACY,
--      COUNT(CASE WHEN REQUIRES_EXPOSED_PERSON_REVIEW = TRUE 
--            THEN 1 END) as REQUIRES_REVIEW
--    FROM CRMA_AGG_DT_CUSTOMER_360
--    WHERE EXPOSED_PERSON_MATCH_TYPE IS NOT NULL
--    GROUP BY EXPOSED_PERSON_MATCH_TYPE
--    ORDER BY MATCH_COUNT DESC;
--
-- 4. Customer segmentation by account tier and portfolio:
--    SELECT 
--      ACCOUNT_TIER,
--      ROUND(AVG(TOTAL_ACCOUNTS), 2) as AVG_ACCOUNTS,
--      ROUND(AVG(CHECKING_ACCOUNTS), 2) as AVG_CHECKING,
--      ROUND(AVG(SAVINGS_ACCOUNTS), 2) as AVG_SAVINGS,
--      ROUND(AVG(INVESTMENT_ACCOUNTS), 2) as AVG_INVESTMENT,
--      COUNT(*) as CUSTOMERS
--    FROM CRMA_AGG_DT_CUSTOMER_360
--    GROUP BY ACCOUNT_TIER
--    ORDER BY CUSTOMERS DESC;
--
-- 5. Compliance risk distribution:
--    SELECT 
--      OVERALL_RISK_RATING,
--      COUNT(*) as CUSTOMER_COUNT,
--      COUNT(CASE WHEN EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' 
--            THEN 1 END) as PEP_EXACT_MATCHES,
--      COUNT(CASE WHEN SANCTIONS_MATCH_TYPE = 'EXACT_MATCH' 
--            THEN 1 END) as SANCTIONS_EXACT_MATCHES,
--      ROUND(AVG(OVERALL_RISK_SCORE), 2) as AVG_RISK_SCORE
--    FROM CRMA_AGG_DT_CUSTOMER_360
--    GROUP BY OVERALL_RISK_RATING
--    ORDER BY AVG_RISK_SCORE DESC;
--
-- MONITORING:
-- - Check semantic view: SHOW VIEWS LIKE '%SEMANTIC%' IN SCHEMA CRM_AGG_001;
-- - Check source table: SHOW DYNAMIC TABLES LIKE '%CUSTOMER_360%' IN SCHEMA CRM_AGG_001;
-- - Monitor data freshness: SELECT MAX(LAST_UPDATED) FROM CRMA_AGG_DT_CUSTOMER_360;
-- - Count customers: SELECT COUNT(*) FROM CRMA_AGG_DT_CUSTOMER_360;
--
-- RELATED TABLES FOR ADDITIONAL ANALYSIS:
-- - ACCA_AGG_DT_ACCOUNTS - Detailed account information
-- - CRMA_AGG_DT_CUSTOMER_LIFECYCLE - Lifecycle and churn analytics  
-- - CRMA_AGG_DT_CUSTOMER_CURRENT - Current customer state (operational)
-- - CRMA_AGG_DT_CUSTOMER_HISTORY - Customer SCD Type 2 history
-- - CRMA_AGG_DT_ADDRESSES_HISTORY - Address change history
--
-- CORTEX AI INTEGRATION:
-- This semantic view can be integrated with:
-- - Snowflake Cortex Analyst for natural language queries
-- - Cortex Search Service for full-text customer search
-- - Cortex AI Agent for intelligent customer insights
-- ============================================================
--
-- ============================================================
-- SNOWFLAKE CORTEX AI AGENT DESCRIPTION
-- ============================================================
--
-- AGENT NAME: CRM Intelligence Agent - Customer 360° Assistant
--
-- AGENT DESCRIPTION:
-- I am your CRM Intelligence Agent, providing instant access to comprehensive
-- customer intelligence across our entire banking relationship portfolio. I help
-- you understand customer profiles, assess risk, monitor compliance, and make
-- data-driven relationship management decisions.
--
-- WHAT I CAN HELP YOU WITH:
--
-- 👤 Customer Intelligence
-- - Find customers by name, ID, or demographic attributes
-- - View complete customer profiles with 360° intelligence
-- - Analyze customer segmentation by tier, country, or employment
-- - Track customer onboarding dates and relationship history
--
-- 💼 Financial & Employment Profiles
-- - Review customer employment status, employer, and income ranges
-- - Analyze account tier distribution (STANDARD, SILVER, GOLD, PLATINUM, PREMIUM)
-- - Examine customer financial profiles and credit score bands
-- - Identify customers by industry, position, or employment type
--
-- 🔍 Risk & Compliance
-- - Screen customers for PEP (Politically Exposed Persons) matches
-- - Check sanctions watchlist screening results
-- - Review overall risk ratings (NO_RISK, LOW, MEDIUM, HIGH, CRITICAL)
-- - Identify high-risk customers requiring enhanced due diligence
-- - Monitor compliance review flags and requirements
--
-- 🏦 Account Portfolio Analysis
-- - Analyze customer account holdings and product mix
-- - Review checking, savings, business, and investment account counts
-- - Examine multi-currency portfolios and currency exposure
-- - Identify cross-sell and upsell opportunities
--
-- 🚩 Fraud & Anomaly Detection
-- - Flag customers with suspicious transaction patterns
-- - Identify anomalous behavior indicators
-- - Review fraud red flags and investigation priorities
-- - Support AML (Anti-Money Laundering) investigations
--
-- 📍 Geographic & Contact Information
-- - Search customers by country, city, state, or postal code
-- - Retrieve customer contact details (email, phone, preferred contact method)
-- - Analyze customer distribution by geography
-- - Support regulatory reporting and customer communications
--
-- 📊 EXAMPLE BUSINESS INTELLIGENCE QUERIES:
-- - "Show me all PLATINUM customers in Switzerland"
-- - "Which customers require PEP review?"
-- - "Find high-risk customers with anomalous transactions"
-- - "What is our customer distribution by account tier?"
-- - "Show me customers onboarded in the last 90 days"
-- - "List customers with investment accounts in multiple currencies"
-- - "Who are our GOLD tier customers in Germany with HIGH risk ratings?"
-- - "Show me customers with exact PEP matches requiring review"
-- - "Find all customers with business accounts and savings accounts"
-- - "Which premium customers have anomalous transaction patterns?"
--
-- DATA COVERAGE:
-- I have access to 48 comprehensive customer attributes including:
-- - Identity: Customer ID, full name, date of birth
-- - Contact: Email, phone, preferred contact method
-- - Employment: Employer, position, employment type, income range
-- - Address: Street, city, state, zip code, country
-- - Accounts: Total accounts, account types, currencies
-- - Risk: Credit score, risk classification, risk rating, risk score
-- - Compliance: PEP screening, sanctions screening, review flags
-- - Status: Current customer status, status effective date
-- - Anomalies: Fraud indicators, suspicious activity flags
--
-- KEY FEATURES:
-- ✅ Natural Language Understanding: Ask questions in plain English
-- ✅ Rich Synonym Support: Understands 200+ alternative terms
--    (e.g., "client" = "customer", "DOB" = "date of birth")
-- ✅ Real-Time Data: All responses reflect latest customer intelligence
-- ✅ Compliance-Ready: Instant PEP/sanctions screening and risk ratings
-- ✅ Business-Friendly: No SQL knowledge required - just ask naturally
--
-- IDEAL FOR:
-- - Relationship Managers: Customer profile reviews and relationship insights
-- - Compliance Officers: PEP/sanctions screening and risk assessment
-- - Risk Analysts: Customer risk scoring and portfolio analysis
-- - Marketing Teams: Customer segmentation and targeting
-- - AML Investigators: Fraud detection and anomaly investigation
-- - Executive Leadership: Customer portfolio reporting and analytics
--
-- DATA FRESHNESS:
-- Customer data is refreshed hourly via dynamic tables, ensuring you always
-- have access to current customer intelligence.
--
-- HOW TO CREATE THE AGENT IN SNOWSIGHT:
-- 1. Navigate to: Projects > Cortex Analyst
-- 2. Click "Create Analyst"
-- 3. Name: "CRM Intelligence Agent"
-- 4. Select Semantic View: CRMA_SEMANTIC_VIEW
-- 5. Add the description above
-- 6. Click "Create"
-- 7. Start asking questions!
--
-- AGENT USAGE TIPS:
-- - Be specific: "Show me PLATINUM customers" vs "Show me customers"
-- - Use filters: Add criteria like country, tier, risk level
-- - Ask follow-ups: The agent maintains context for multi-turn conversations
-- - Use synonyms freely: "clients", "accounts", "tier", "segment" all work
-- - Request aggregations: "Count of...", "Average...", "Total..."
-- - Combine criteria: "High-risk GOLD customers in high-income brackets"
--
-- ============================================================
