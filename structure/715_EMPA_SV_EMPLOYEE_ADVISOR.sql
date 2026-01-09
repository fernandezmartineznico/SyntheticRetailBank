-- ============================================================================
-- 715_EMPA_SV_EMPLOYEE_ADVISOR.sql
-- Employee/Advisor Relationship Management Semantic View
-- ============================================================================
-- Purpose: Advisor-customer relationship management and capacity planning
-- Used by: Employee Relationship Management notebook, Streamlit CRM App
-- Business Value: €450K annually (capacity optimization, revenue per advisor)
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================================
-- Main Semantic View: EMPA_SV_EMPLOYEE_ADVISOR
-- ============================================================================
-- Note: References EMPA_AGG_VW_ADVISORS (created in 415_EMPA_employee_analytics.sql)
--       Provides advisor-level metrics aggregated from customer 360 data

CREATE OR REPLACE SEMANTIC VIEW EMPA_SV_EMPLOYEE_ADVISOR
tables (
  advisors AS EMPA_AGG_VW_ADVISORS
    PRIMARY KEY (EMPLOYEE_ID)
    COMMENT = 'Advisor performance and client portfolio metrics',
  customers AS CRMA_AGG_DT_CUSTOMER_360
    PRIMARY KEY (CUSTOMER_ID)
    COMMENT = 'Customer 360 data for advisor-customer relationships'
)

relationships (
  advisor_to_customers AS
    customers (CURRENT_ADVISOR_EMPLOYEE_ID) REFERENCES advisors
)

facts (
  -- ===== EMPLOYEE/ADVISOR IDENTITY =====
  advisors.EMPLOYEE_ID as EMPLOYEE_ID comment='Employee ID | advisor ID | employee number | staff ID | advisor code | employee identifier',
  advisors.FULL_NAME as FULL_NAME comment='Full name | advisor name | employee name | complete name',
  advisors.FIRST_NAME as FIRST_NAME comment='First name | given name | forename | personal name',
  advisors.FAMILY_NAME as FAMILY_NAME comment='Family name | last name | surname | family surname | last surname',
  advisors.EMAIL as EMAIL comment='Email address | email | advisor email | contact email | work email | business email',
  advisors.PHONE as PHONE comment='Phone number | telephone | mobile | contact number | phone | cell phone | mobile number',
  advisors.DATE_OF_BIRTH as DATE_OF_BIRTH comment='Date of birth | DOB | birth date | birthday | birthdate',
  
  -- ===== EMPLOYMENT DETAILS =====
  advisors.HIRE_DATE as HIRE_DATE comment='Hire date | start date | employment start | join date | onboarding date | employment date',
  
  -- ===== REPORTING STRUCTURE =====
  advisors.MANAGER_EMPLOYEE_ID as MANAGER_EMPLOYEE_ID comment='Manager ID | supervisor ID | manager identifier | reports to ID | manager employee ID',
  
  -- ===== QUALIFICATIONS =====
  advisors.LANGUAGES_SPOKEN as LANGUAGES_SPOKEN comment='Languages spoken | language skills | multilingual | languages | language proficiency',
  advisors.CERTIFICATIONS as CERTIFICATIONS comment='Certifications | professional certifications | qualifications | credentials | licenses',
  
  -- ===== ADVISOR PERFORMANCE METRICS (from customer 360 data) =====
  advisors.TOTAL_CLIENTS as TOTAL_CLIENTS comment='Total clients | number of clients | client count | assigned clients | customer portfolio',
  advisors.TOTAL_AUM as TOTAL_AUM 
    WITH SYNONYMS = ('AUM', 'assets under management', 'managed assets', 'portfolio value')
    comment='Total AUM managed by advisor. Primary metric for advisor performance ranking',
  advisors.AVG_CLIENT_BALANCE as AVG_CLIENT_BALANCE comment='Average client balance | mean client balance | typical client value | avg portfolio size',
  advisors.ACTIVE_CLIENTS as ACTIVE_CLIENTS comment='Active clients | current clients | active portfolio | active customer count',
  advisors.CLOSED_CLIENTS as CLOSED_CLIENTS comment='Closed clients | churned clients | lost clients | departed customers',
  advisors.CLIENT_RETENTION_RATE as CLIENT_RETENTION_RATE comment='Client retention rate | retention percentage | client loyalty | retention ratio',
  advisors.TOTAL_ACCOUNTS_MANAGED as TOTAL_ACCOUNTS_MANAGED comment='Total accounts managed | account count | managed accounts | accounts under management',
  advisors.TOTAL_CHECKING_BALANCE as TOTAL_CHECKING_BALANCE comment='Total checking balance | checking AUM | checking portfolio | checking assets',
  advisors.TOTAL_SAVINGS_BALANCE as TOTAL_SAVINGS_BALANCE comment='Total savings balance | savings AUM | savings portfolio | savings assets',
  advisors.TOTAL_INVESTMENT_BALANCE as TOTAL_INVESTMENT_BALANCE comment='Total investment balance | investment AUM | investment portfolio | investment assets',
  advisors.HIGH_RISK_CLIENTS as HIGH_RISK_CLIENTS comment='High risk clients | risky customers | high risk portfolio | elevated risk clients',
  advisors.PREMIUM_CLIENTS as PREMIUM_CLIENTS comment='Premium clients | platinum clients | VIP clients | high value clients | premium tier customers'
)

dimensions (
  -- ===== PRIMARY GROUPING DIMENSIONS =====
  advisors.COUNTRY AS COUNTRY 
    WITH SYNONYMS = ('country', 'nation', 'location', 'geography')
    COMMENT = 'Country where advisor is located. Use for geographic analysis and regional grouping',
  advisors.REGION AS REGION 
    WITH SYNONYMS = ('region', 'territory', 'area', 'geographic region')
    COMMENT = 'Geographic region for regional performance analysis',
  advisors.EMPLOYMENT_STATUS AS EMPLOYMENT_STATUS 
    WITH SYNONYMS = ('status', 'active', 'employment status', 'work status')
    COMMENT = 'Employment status (ACTIVE, INACTIVE). Use for filtering active advisors',
  advisors.POSITION_LEVEL AS POSITION_LEVEL 
    WITH SYNONYMS = ('tier', 'level', 'advisor tier', 'position level', 'seniority')
    COMMENT = 'Position level or advisor tier. Use for performance comparison by seniority',
  advisors.PERFORMANCE_RATING AS PERFORMANCE_RATING 
    WITH SYNONYMS = ('rating', 'performance', 'performance rating', 'advisor rating')
    COMMENT = 'Performance rating. Use for identifying top performers',
  
  -- ===== SECONDARY DIMENSIONS =====
  advisors.OFFICE_LOCATION AS OFFICE_LOCATION 
    COMMENT = 'Office location for branch-level analysis'
)

metrics (
  -- ===== PRIMARY METRICS =====
  advisors.ADVISOR_COUNT AS COUNT(advisors.EMPLOYEE_ID)
    WITH SYNONYMS = ('number of advisors', 'advisor count', 'how many advisors', 'total advisors', 'headcount')
    COMMENT = 'Count of advisors.
               EXAMPLES: "How many advisors by region?" → COUNT(EMPLOYEE_ID) GROUP BY REGION',
  advisors.TOTAL_AUM_SUM AS SUM(advisors.TOTAL_AUM)
    WITH SYNONYMS = ('total AUM', 'total assets', 'total managed assets', 'sum of AUM')
    COMMENT = 'Sum of all AUM managed by advisors. DEFAULT for advisor rankings.
               EXAMPLES: "Show me top 10 advisors by total AUM" → ORDER BY TOTAL_AUM DESC LIMIT 10
                        "Total AUM by region" → SUM(TOTAL_AUM) GROUP BY REGION
                        "Which advisors manage most assets?" → ORDER BY TOTAL_AUM DESC',
  advisors.AVG_AUM AS AVG(advisors.TOTAL_AUM)
    WITH SYNONYMS = ('average AUM', 'mean AUM', 'typical AUM', 'avg assets per advisor')
    COMMENT = 'Average AUM per advisor. Use for productivity benchmarking.
               EXAMPLES: "Average AUM by position level" → AVG(TOTAL_AUM) GROUP BY POSITION_LEVEL',
  advisors.TOTAL_CLIENTS_SUM AS SUM(advisors.TOTAL_CLIENTS)
    WITH SYNONYMS = ('total clients', 'sum of clients', 'all clients', 'total customer count')
    COMMENT = 'Total number of clients managed by all advisors.
               EXAMPLES: "Total clients by advisor" → SUM(TOTAL_CLIENTS) or use TOTAL_CLIENTS directly',
  advisors.AVG_RETENTION AS AVG(advisors.CLIENT_RETENTION_RATE)
    WITH SYNONYMS = ('average retention', 'mean retention', 'typical retention', 'avg retention rate')
    COMMENT = 'Average client retention rate. Use for retention analysis.
               EXAMPLES: "Which advisors have highest retention?" → ORDER BY CLIENT_RETENTION_RATE DESC
                        "Average retention by region" → AVG(CLIENT_RETENTION_RATE) GROUP BY REGION'
);

-- ============================================================================
-- Permissions
-- ============================================================================
-- Note: Permissions are granted in 315_EMPA_employees.sql on the underlying dynamic table

-- ============================================================================
-- Validation Queries
-- ============================================================================

-- Test basic query
-- SELECT COUNT(DISTINCT employee_id) AS total_advisors 
-- FROM EMPA_SV_EMPLOYEE_ADVISOR;

-- Test capacity planning query
-- SELECT 
--   advisor_name,
--   region,
--   employee_tier,
--   total_clients,
--   total_aum_chf,
--   capacity_utilization_pct,
--   capacity_status,
--   can_accept_new_clients,
--   recommended_new_clients
-- FROM EMPA_SV_EMPLOYEE_ADVISOR
-- WHERE capacity_status IN ('BELOW_CAPACITY', 'AT_CAPACITY')
--   AND can_accept_new_clients = TRUE
-- GROUP BY 1,2,3,4,5,6,7,8,9
-- ORDER BY capacity_utilization_pct ASC
-- LIMIT 20;

-- Test advisor-customer relationship query
-- SELECT 
--   advisor_name,
--   customer_name,
--   client_tier,
--   relationship_tenure_years,
--   customer_aum_chf,
--   days_since_last_contact,
--   is_contact_overdue,
--   is_at_churn_risk
-- FROM EMPA_SV_EMPLOYEE_ADVISOR
-- WHERE is_at_churn_risk = TRUE
--   OR is_contact_overdue = TRUE
-- ORDER BY customer_aum_chf DESC
-- LIMIT 20;

-- ============================================================================
-- Deployment Success Message
-- ============================================================================

SELECT 'EMPA_SV_EMPLOYEE_ADVISOR created successfully! Advisor relationship management view ready.' AS STATUS;

