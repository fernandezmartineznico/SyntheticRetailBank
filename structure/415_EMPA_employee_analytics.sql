-- ============================================================
-- CRM_AGG_001 Schema - Employee Analytics & Hierarchy (Dynamic Tables + Views)
-- Generated on: 2025-12-19 | Updated: 2025-12-19 (Dynamic Table Conversion)
-- ============================================================
--
-- OVERVIEW:
-- This schema provides analytics for employee hierarchy, advisor performance,
-- and team management. Enables relationship management, portfolio analytics, and
-- workforce optimization through comprehensive employee and assignment metrics.
--
-- HYBRID ARCHITECTURE:
-- 🔷 DYNAMIC TABLES (Auto-refreshing aggregations for performance):
--    - EMPA_AGG_DT_ADVISOR_PERFORMANCE   - Client advisor KPIs and metrics
--    - EMPA_AGG_DT_TEAM_LEADER_DASHBOARD - Team leader aggregated metrics
--    - EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR  - Advisor portfolio valuations
--
-- 🔹 VIEWS (Real-time lookups and recursive queries):
--    - EMPA_AGG_VW_EMPLOYEE_HIERARCHY        - Recursive hierarchy with full path
--    - EMPA_AGG_VW_ORGANIZATIONAL_CHART      - Flat organizational structure
--    - EMPA_AGG_VW_CURRENT_ASSIGNMENTS       - Active client-advisor relationships
--    - EMPA_AGG_VW_ASSIGNMENT_HISTORY        - Full assignment audit trail
--    - EMPA_AGG_VW_WORKLOAD_DISTRIBUTION     - Client distribution analysis
--
-- BUSINESS VALUE:
-- - Relationship Management: Track customer-advisor assignments and history
-- - Performance Analytics: Monitor advisor productivity and client portfolios
-- - Workforce Optimization: Balance workloads and identify capacity constraints
-- - Team Management: Aggregate metrics for team leaders and super team leaders
-- - Compliance: Audit trails for client assignment changes and advisor transitions
--
-- RELATED TABLES:
-- - CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE           - Employee master data
-- - CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT  - Assignment relationships
-- - CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT - Current customer attributes (aggregation layer)
-- - CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 - Customer 360 with balance + transaction metrics (direct transaction aggregation)
-- - PAY_AGG_001.PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY - Alternative pre-aggregated transaction data (optional)
--
-- ENHANCEMENTS COMPLETED:
-- ✅ 2025-12-19: Phase 1 - AUM (Assets Under Management) with TOTAL_BALANCE
-- ✅ 2025-12-19: Phase 2 - Transaction activity metrics (TOTAL_TRANSACTIONS, dormancy flags)
-- ✅ 2025-12-19: Dynamic Table Conversion - Converted 3 heavy views to DTs for performance
--
-- REFRESH SCHEDULE:
-- - Dynamic Tables: TARGET_LAG = 60 minutes (matches CRMA_AGG_DT_CUSTOMER_360)
-- - Views: Real-time (no refresh needed)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- SECTION 1: HIERARCHY VIEWS
-- ============================================================

-- Recursive employee hierarchy view with full organizational path
CREATE OR REPLACE VIEW EMPA_AGG_VW_EMPLOYEE_HIERARCHY
COMMENT = 'Recursive employee hierarchy showing full organizational structure with paths and levels'
AS
WITH RECURSIVE hierarchy AS (
    -- Anchor: Super Team Leaders (top level)
    SELECT 
        EMPLOYEE_ID,                                                    -- Unique employee identifier for drill-down and cross-referencing
        FIRST_NAME,                                                     -- Employee given name for reporting and personalization
        FAMILY_NAME,                                                    -- Employee surname for formal identification
        FIRST_NAME || ' ' || FAMILY_NAME as FULL_NAME,                -- Complete name for display in org charts and dashboards
        POSITION_LEVEL,                                                 -- Role tier for filtering by responsibility level
        MANAGER_EMPLOYEE_ID,                                            -- Direct manager for escalation path visualization
        COUNTRY,                                                        -- Geographic location for regional analysis
        REGION,                                                         -- Broader geographic grouping for strategic planning
        EMPLOYMENT_STATUS,                                              -- Active/inactive flag for workforce planning and capacity
        HIRE_DATE,                                                      -- Start date for tenure analysis and retention metrics
        PERFORMANCE_RATING,                                             -- Performance score for succession planning and promotions
        1 as HIERARCHY_LEVEL,                                          -- Organizational depth for span-of-control analysis
        EMPLOYEE_ID as ROOT_SUPER_LEADER_ID,                           -- Top-level leader ID for organizational grouping
        NULL as ROOT_SUPER_LEADER_NAME,                                -- Top-level leader name (NULL for top level themselves)
        NULL as TEAM_LEADER_ID,                                        -- Direct team lead (NULL for super leaders)
        NULL as TEAM_LEADER_NAME,                                      -- Direct team lead name (NULL for super leaders)
        CAST(EMPLOYEE_ID AS VARCHAR(1000)) as HIERARCHY_PATH,         -- Full ID path for technical drill-up/down navigation
        CAST(FIRST_NAME || ' ' || FAMILY_NAME AS VARCHAR(1000)) as HIERARCHY_PATH_NAMES  -- Full name path for visual org chart display
    FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE
    WHERE POSITION_LEVEL = 'SUPER_TEAM_LEADER'
    
    UNION ALL
    
    -- Recursive: Get all subordinates
    SELECT 
        e.EMPLOYEE_ID,                                                 -- Employee identifier propagated through hierarchy
        e.FIRST_NAME,                                                  -- Given name for reporting
        e.FAMILY_NAME,                                                 -- Surname for identification
        e.FIRST_NAME || ' ' || e.FAMILY_NAME,                         -- Full name for displays
        e.POSITION_LEVEL,                                              -- Role level in 3-tier structure
        e.MANAGER_EMPLOYEE_ID,                                         -- Immediate supervisor for escalation
        e.COUNTRY,                                                     -- Location for geographic analysis
        e.REGION,                                                      -- Regional grouping for strategy
        e.EMPLOYMENT_STATUS,                                           -- Status for capacity planning
        e.HIRE_DATE,                                                   -- Tenure tracking
        e.PERFORMANCE_RATING,                                          -- Performance for talent management
        h.HIERARCHY_LEVEL + 1,                                        -- Incremented depth for organizational structure analysis
        h.ROOT_SUPER_LEADER_ID,                                       -- Inherited top leader ID for portfolio grouping
        h.ROOT_SUPER_LEADER_NAME,                                     -- Inherited top leader name for reporting
        CASE 
            WHEN e.POSITION_LEVEL = 'CLIENT_ADVISOR' THEN e.MANAGER_EMPLOYEE_ID
            ELSE h.TEAM_LEADER_ID
        END,                                                          -- Team leader ID for advisor performance roll-ups
        CASE 
            WHEN e.POSITION_LEVEL = 'CLIENT_ADVISOR' THEN 
                (SELECT FIRST_NAME || ' ' || FAMILY_NAME 
                 FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE 
                 WHERE EMPLOYEE_ID = e.MANAGER_EMPLOYEE_ID)
            ELSE h.TEAM_LEADER_NAME
        END,                                                          -- Team leader name for dashboard filtering
        h.HIERARCHY_PATH || ' > ' || e.EMPLOYEE_ID,                  -- Accumulated ID path for hierarchy navigation
        h.HIERARCHY_PATH_NAMES || ' > ' || e.FIRST_NAME || ' ' || e.FAMILY_NAME  -- Accumulated name path for visual org chart
    FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE e
    INNER JOIN hierarchy h ON e.MANAGER_EMPLOYEE_ID = h.EMPLOYEE_ID
)
SELECT * FROM hierarchy;

-- Flat organizational chart view
CREATE OR REPLACE VIEW EMPA_AGG_VW_ORGANIZATIONAL_CHART
COMMENT = 'Flat organizational chart with manager relationships and direct report counts'
AS
SELECT 
    e.EMPLOYEE_ID,                                                     -- Employee identifier for lookups and joins
    e.FIRST_NAME || ' ' || e.FAMILY_NAME as EMPLOYEE_NAME,            -- Full name for org chart displays and employee directories
    e.POSITION_LEVEL,                                                  -- Job level for compensation bands and authority levels
    e.COUNTRY,                                                         -- Work location for compliance and local HR policies
    e.REGION,                                                          -- Regional grouping for budget allocation and strategy
    e.EMPLOYMENT_STATUS,                                               -- Status for headcount reporting and resource availability
    e.HIRE_DATE,                                                       -- Start date for service awards and benefit vesting
    DATEDIFF(day, e.HIRE_DATE, CURRENT_DATE()) as TENURE_DAYS,       -- Days of service for detailed retention analysis
    ROUND(DATEDIFF(day, e.HIRE_DATE, CURRENT_DATE()) / 365.25, 1) as TENURE_YEARS,  -- Years of service for seniority-based decisions
    e.PERFORMANCE_RATING,                                              -- Latest performance score for promotion and compensation reviews
    e.LANGUAGES_SPOKEN,                                                -- Language capabilities for international client matching
    e.MANAGER_EMPLOYEE_ID,                                             -- Manager ID for reporting line validation
    m.FIRST_NAME || ' ' || m.FAMILY_NAME as MANAGER_NAME,             -- Manager name for escalation paths and approval workflows
    m.POSITION_LEVEL as MANAGER_POSITION,                             -- Manager's level for authority verification
    -- Count direct reports
    (SELECT COUNT(*) 
     FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE 
     WHERE MANAGER_EMPLOYEE_ID = e.EMPLOYEE_ID) as DIRECT_REPORTS,   -- Number of direct reports for span-of-control analysis and workload assessment
    -- Count clients (for advisors)
    (SELECT COUNT(DISTINCT CUSTOMER_ID) 
     FROM CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT 
     WHERE ADVISOR_EMPLOYEE_ID = e.EMPLOYEE_ID 
     AND IS_CURRENT = TRUE) as CLIENT_COUNT                           -- Active client portfolio size for capacity planning and performance evaluation
FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE e
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE m ON e.MANAGER_EMPLOYEE_ID = m.EMPLOYEE_ID;

-- ============================================================
-- SECTION 2: ADVISOR PERFORMANCE DYNAMIC TABLES
-- ============================================================

-- Client advisor performance metrics and KPIs (CONVERTED TO DYNAMIC TABLE for better performance)
CREATE OR REPLACE DYNAMIC TABLE EMPA_AGG_DT_ADVISOR_PERFORMANCE(
    -- Advisor Identity
    EMPLOYEE_ID VARCHAR(20) COMMENT 'Advisor identifier for performance tracking and compensation',
    ADVISOR_NAME VARCHAR(201) COMMENT 'Full name for leaderboards and recognition programs',
    COUNTRY VARCHAR(50) COMMENT 'Location for regional performance benchmarking',
    REGION VARCHAR(50) COMMENT 'Broader region for cross-market comparison',
    HIRE_DATE DATE COMMENT 'Start date for experience-weighted metrics',
    TENURE_DAYS NUMBER(10,0) COMMENT 'Days of service for ramp-up performance expectations',
    EMPLOYMENT_STATUS VARCHAR(20) COMMENT 'Status for active advisor filtering',
    PERFORMANCE_RATING DECIMAL(3,2) COMMENT 'HR rating for correlation with client outcomes',
    LANGUAGES_SPOKEN VARCHAR(200) COMMENT 'Language skills for multicultural client service quality',
    
    -- Manager Hierarchy
    TEAM_LEADER_ID VARCHAR(20) COMMENT 'Team leader for escalation and support',
    TEAM_LEADER_NAME VARCHAR(201) COMMENT 'Team leader name for coaching accountability',
    
    -- Client Volume Metrics
    TOTAL_CLIENTS NUMBER(10,0) COMMENT 'Current client count for workload and revenue calculations',
    HIGH_RISK_CLIENTS NUMBER(10,0) COMMENT 'High-risk clients requiring enhanced monitoring',
    HIGH_RISK_PERCENTAGE NUMBER(10,2) COMMENT 'Risk concentration for compliance oversight',
    
    -- Portfolio Value Metrics (AUM - Assets Under Management)
    TOTAL_PORTFOLIO_VALUE NUMBER(18,2) COMMENT 'Total AUM for revenue forecasting and incentive compensation',
    AVG_CLIENT_BALANCE NUMBER(18,2) COMMENT 'Average client value for service tier optimization',
    MAX_CLIENT_BALANCE NUMBER(18,2) COMMENT 'Largest client for key account management',
    
    -- Account Relationship Depth
    TOTAL_CLIENT_ACCOUNTS NUMBER(10,0) COMMENT 'Total accounts for cross-sell success measurement',
    AVG_ACCOUNTS_PER_CLIENT NUMBER(10,2) COMMENT 'Products per client for relationship depth KPI',
    
    -- Transaction Activity Metrics
    TOTAL_TRANSACTIONS NUMBER(10,0) COMMENT 'Total transactions for activity-based portfolio quality',
    AVG_TRANSACTIONS_PER_CLIENT NUMBER(10,2) COMMENT 'Transaction frequency for engagement health score',
    
    -- Risk Exposure Metrics
    CRITICAL_RISK_CLIENTS NUMBER(10,0) COMMENT 'Critical risk clients requiring immediate attention',
    HIGH_RISK_CLIENTS_CLASSIFICATION NUMBER(10,0) COMMENT 'High risk classification for portfolio quality',
    
    -- Assignment Timeline
    MOST_RECENT_ASSIGNMENT DATE COMMENT 'Latest assignment date for onboarding activity tracking',
    FIRST_ASSIGNMENT DATE COMMENT 'First assignment for advisor seniority with book',
    
    -- Capacity Management
    CAPACITY_UTILIZATION_PCT NUMBER(10,2) COMMENT 'Utilization percentage for workload balancing decisions',
    AVAILABLE_CAPACITY NUMBER(10,0) COMMENT 'Remaining capacity for new client assignments',
    
    -- Workload Classification
    WORKLOAD_STATUS VARCHAR(20) COMMENT 'Status flag for hiring needs and rebalancing priorities'
)
COMMENT = 'Client advisor performance metrics including portfolio value, client counts, and workload status. Refreshed hourly for management dashboards.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Advisor Identity
    e.EMPLOYEE_ID,                                                     -- Advisor identifier for performance tracking and compensation
    e.FIRST_NAME || ' ' || e.FAMILY_NAME as ADVISOR_NAME,             -- Full name for leaderboards and recognition programs
    e.COUNTRY,                                                         -- Location for regional performance benchmarking
    e.REGION,                                                          -- Broader region for cross-market comparison
    e.HIRE_DATE,                                                       -- Start date for experience-weighted metrics
    DATEDIFF(day, e.HIRE_DATE, CURRENT_DATE()) as TENURE_DAYS,       -- Days of service for ramp-up performance expectations
    e.EMPLOYMENT_STATUS,                                               -- Status for active advisor filtering
    e.PERFORMANCE_RATING,                                              -- HR rating for correlation with client outcomes
    e.LANGUAGES_SPOKEN,                                                -- Language skills for multicultural client service quality
    
    -- Manager Hierarchy
    e.MANAGER_EMPLOYEE_ID as TEAM_LEADER_ID,                          -- Team leader for escalation and support
    m.FIRST_NAME || ' ' || m.FAMILY_NAME as TEAM_LEADER_NAME,         -- Team leader name for coaching accountability
    
    -- Client Volume Metrics
    COUNT(DISTINCT a.CUSTOMER_ID) as TOTAL_CLIENTS,                   -- Current client count for workload and revenue calculations
    COUNT(DISTINCT CASE WHEN c.HAS_ANOMALY THEN a.CUSTOMER_ID END) as HIGH_RISK_CLIENTS,  -- High-risk clients requiring enhanced monitoring
    ROUND(COUNT(DISTINCT CASE WHEN c.HAS_ANOMALY THEN a.CUSTOMER_ID END) * 100.0 / 
          NULLIF(COUNT(DISTINCT a.CUSTOMER_ID), 0), 2) as HIGH_RISK_PERCENTAGE,  -- Risk concentration for compliance oversight
    
    -- Portfolio Value Metrics (AUM - Assets Under Management)
    COALESCE(SUM(c360.TOTAL_BALANCE), 0) as TOTAL_PORTFOLIO_VALUE,   -- Total AUM for revenue forecasting and incentive compensation
    COALESCE(AVG(c360.TOTAL_BALANCE), 0) as AVG_CLIENT_BALANCE,      -- Average client value for service tier optimization
    COALESCE(MAX(c360.TOTAL_BALANCE), 0) as MAX_CLIENT_BALANCE,      -- Largest client for key account management
    
    -- Account Relationship Depth
    COALESCE(SUM(c360.TOTAL_ACCOUNTS), 0) as TOTAL_CLIENT_ACCOUNTS,  -- Total accounts for cross-sell success measurement
    COALESCE(AVG(c360.TOTAL_ACCOUNTS), 0) as AVG_ACCOUNTS_PER_CLIENT,  -- Products per client for relationship depth KPI
    
    -- Transaction Activity Metrics
    COALESCE(SUM(c360.TOTAL_TRANSACTIONS), 0) as TOTAL_TRANSACTIONS,  -- Total transactions for activity-based portfolio quality
    COALESCE(AVG(c360.TOTAL_TRANSACTIONS), 0) as AVG_TRANSACTIONS_PER_CLIENT,  -- Transaction frequency for engagement health score
    
    -- Risk Exposure Metrics
    COUNT(DISTINCT CASE WHEN c360.RISK_CLASSIFICATION = 'CRITICAL' THEN a.CUSTOMER_ID END) as CRITICAL_RISK_CLIENTS,  -- Critical risk clients requiring immediate attention
    COUNT(DISTINCT CASE WHEN c360.RISK_CLASSIFICATION = 'HIGH' THEN a.CUSTOMER_ID END) as HIGH_RISK_CLIENTS_CLASSIFICATION,  -- High risk classification for portfolio quality
    
    -- Assignment Timeline
    MAX(a.ASSIGNMENT_START_DATE) as MOST_RECENT_ASSIGNMENT,          -- Latest assignment date for onboarding activity tracking
    MIN(a.ASSIGNMENT_START_DATE) as FIRST_ASSIGNMENT,                -- First assignment for advisor seniority with book
    
    -- Capacity Management
    ROUND(COUNT(DISTINCT a.CUSTOMER_ID) / 200.0 * 100, 2) as CAPACITY_UTILIZATION_PCT,  -- Utilization percentage for workload balancing decisions
    200 - COUNT(DISTINCT a.CUSTOMER_ID) as AVAILABLE_CAPACITY,       -- Remaining capacity for new client assignments
    
    -- Workload Classification
    CASE 
        WHEN COUNT(DISTINCT a.CUSTOMER_ID) >= 180 THEN 'AT_CAPACITY'
        WHEN COUNT(DISTINCT a.CUSTOMER_ID) >= 150 THEN 'HIGH_LOAD'
        WHEN COUNT(DISTINCT a.CUSTOMER_ID) >= 100 THEN 'BALANCED'
        ELSE 'LOW_LOAD'
    END as WORKLOAD_STATUS                                            -- Status flag for hiring needs and rebalancing priorities
    
FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE e
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE m ON e.MANAGER_EMPLOYEE_ID = m.EMPLOYEE_ID
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT a 
    ON e.EMPLOYEE_ID = a.ADVISOR_EMPLOYEE_ID 
    AND a.IS_CURRENT = TRUE
LEFT JOIN CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT c 
    ON a.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN CRMA_AGG_DT_CUSTOMER_360 c360 
    ON a.CUSTOMER_ID = c360.CUSTOMER_ID
WHERE e.POSITION_LEVEL = 'CLIENT_ADVISOR'
GROUP BY 
    e.EMPLOYEE_ID, e.FIRST_NAME, e.FAMILY_NAME, e.COUNTRY, e.REGION, 
    e.HIRE_DATE, e.EMPLOYMENT_STATUS, e.PERFORMANCE_RATING, e.LANGUAGES_SPOKEN,
    e.MANAGER_EMPLOYEE_ID, m.FIRST_NAME, m.FAMILY_NAME;

-- Portfolio valuation by advisor (CONVERTED TO DYNAMIC TABLE for better performance)
CREATE OR REPLACE DYNAMIC TABLE EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR(
    -- Advisor Identity
    ADVISOR_EMPLOYEE_ID VARCHAR(20) COMMENT 'Advisor ID for portfolio performance attribution',
    ADVISOR_NAME VARCHAR(201) COMMENT 'Full name for wealth management reporting',
    COUNTRY VARCHAR(50) COMMENT 'Location for local market AUM tracking',
    REGION VARCHAR(50) COMMENT 'Region for divisional AUM aggregation',
    
    -- Portfolio Size Metrics
    TOTAL_CLIENTS NUMBER(10,0) COMMENT 'Client count for relationship-based compensation models',
    TOTAL_AUM NUMBER(18,2) COMMENT 'Total assets under management for advisor ranking',
    AVG_AUM_PER_CLIENT NUMBER(18,2) COMMENT 'Average client value for service model segmentation',
    
    -- Currency Exposure (Risk and Compliance)
    AUM_USD NUMBER(18,2) COMMENT 'USD exposure for FX risk management',
    AUM_EUR NUMBER(18,2) COMMENT 'EUR exposure for euro-zone strategy',
    AUM_GBP NUMBER(18,2) COMMENT 'GBP exposure for UK market tracking',
    AUM_CHF NUMBER(18,2) COMMENT 'CHF exposure for Swiss wealth management',
    
    -- Client Segmentation (Service Tier Distribution)
    PREMIUM_CLIENTS NUMBER(10,0) COMMENT 'Premium tier count for white-glove service allocation',
    PLATINUM_CLIENTS NUMBER(10,0) COMMENT 'Platinum tier for VIP relationship management',
    GOLD_CLIENTS NUMBER(10,0) COMMENT 'Gold tier for enhanced service level tracking',
    
    -- Revenue Projection
    ESTIMATED_ANNUAL_REVENUE NUMBER(18,2) COMMENT 'Annual fee estimate (1% AUM) for incentive compensation and budget planning'
)
COMMENT = 'Portfolio valuation aggregated by client advisor for AUM tracking and revenue estimation. Refreshed hourly for financial reporting.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Advisor Identity
    a.ADVISOR_EMPLOYEE_ID,                                             -- Advisor ID for portfolio performance attribution
    e.FIRST_NAME || ' ' || e.FAMILY_NAME as ADVISOR_NAME,             -- Full name for wealth management reporting
    e.COUNTRY,                                                         -- Location for local market AUM tracking
    e.REGION,                                                          -- Region for divisional AUM aggregation
    
    -- Portfolio Size Metrics
    COUNT(DISTINCT a.CUSTOMER_ID) as TOTAL_CLIENTS,                   -- Client count for relationship-based compensation models
    COALESCE(SUM(c360.TOTAL_BALANCE), 0) as TOTAL_AUM,               -- Total assets under management for advisor ranking
    COALESCE(AVG(c360.TOTAL_BALANCE), 0) as AVG_AUM_PER_CLIENT,      -- Average client value for service model segmentation
    
    -- Currency Exposure (Risk and Compliance)
    COALESCE(SUM(CASE WHEN c360.REPORTING_CURRENCY = 'USD' THEN c360.TOTAL_BALANCE ELSE 0 END), 0) as AUM_USD,  -- USD exposure for FX risk management
    COALESCE(SUM(CASE WHEN c360.REPORTING_CURRENCY = 'EUR' THEN c360.TOTAL_BALANCE ELSE 0 END), 0) as AUM_EUR,  -- EUR exposure for euro-zone strategy
    COALESCE(SUM(CASE WHEN c360.REPORTING_CURRENCY = 'GBP' THEN c360.TOTAL_BALANCE ELSE 0 END), 0) as AUM_GBP,  -- GBP exposure for UK market tracking
    COALESCE(SUM(CASE WHEN c360.REPORTING_CURRENCY = 'CHF' THEN c360.TOTAL_BALANCE ELSE 0 END), 0) as AUM_CHF,  -- CHF exposure for Swiss wealth management
    
    -- Client Segmentation (Service Tier Distribution)
    COUNT(DISTINCT CASE WHEN c360.ACCOUNT_TIER = 'PREMIUM' THEN a.CUSTOMER_ID END) as PREMIUM_CLIENTS,   -- Premium tier count for white-glove service allocation
    COUNT(DISTINCT CASE WHEN c360.ACCOUNT_TIER = 'PLATINUM' THEN a.CUSTOMER_ID END) as PLATINUM_CLIENTS, -- Platinum tier for VIP relationship management
    COUNT(DISTINCT CASE WHEN c360.ACCOUNT_TIER = 'GOLD' THEN a.CUSTOMER_ID END) as GOLD_CLIENTS,         -- Gold tier for enhanced service level tracking
    
    -- Revenue Projection
    COALESCE(SUM(c360.TOTAL_BALANCE), 0) * 0.01 as ESTIMATED_ANNUAL_REVENUE  -- Annual fee estimate (1% AUM) for incentive compensation and budget planning
    
FROM CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT a
JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE e ON a.ADVISOR_EMPLOYEE_ID = e.EMPLOYEE_ID
JOIN CRMA_AGG_DT_CUSTOMER_360 c360 ON a.CUSTOMER_ID = c360.CUSTOMER_ID
WHERE a.IS_CURRENT = TRUE
GROUP BY a.ADVISOR_EMPLOYEE_ID, e.FIRST_NAME, e.FAMILY_NAME, e.COUNTRY, e.REGION;

-- ============================================================
-- SECTION 3: TEAM LEADER DASHBOARD DYNAMIC TABLES
-- ============================================================

-- Team leader aggregated metrics (CONVERTED TO DYNAMIC TABLE for better performance)
CREATE OR REPLACE DYNAMIC TABLE EMPA_AGG_DT_TEAM_LEADER_DASHBOARD(
    -- Team Leader Identity
    TEAM_LEADER_ID VARCHAR(20) COMMENT 'Team leader ID for management reporting',
    TEAM_LEADER_NAME VARCHAR(201) COMMENT 'Full name for leadership dashboards',
    REGION VARCHAR(50) COMMENT 'Geographic region for divisional P and L',
    HIRE_DATE DATE COMMENT 'Start date for leadership tenure tracking',
    TL_PERFORMANCE_RATING DECIMAL(3,2) COMMENT 'Leader own rating for correlation with team outcomes',
    
    -- Reporting Line
    SUPER_LEADER_ID VARCHAR(20) COMMENT 'Super leader for executive roll-ups',
    SUPER_LEADER_NAME VARCHAR(201) COMMENT 'Super leader name for organizational reporting',
    
    -- Team Size & Composition
    TOTAL_ADVISORS NUMBER(10,0) COMMENT 'Total advisors for span-of-control analysis',
    ACTIVE_ADVISORS NUMBER(10,0) COMMENT 'Active headcount for capacity planning',
    
    -- Team Performance Distribution
    AVG_ADVISOR_PERFORMANCE NUMBER(5,2) COMMENT 'Team average for leader effectiveness measurement',
    MIN_ADVISOR_PERFORMANCE DECIMAL(3,2) COMMENT 'Lowest performer for coaching focus',
    MAX_ADVISOR_PERFORMANCE DECIMAL(3,2) COMMENT 'Top performer for best practice sharing',
    
    -- Client Portfolio Aggregation
    TOTAL_CLIENTS NUMBER(10,0) COMMENT 'Total clients under team management',
    HIGH_RISK_CLIENTS NUMBER(10,0) COMMENT 'High-risk client concentration for oversight',
    
    -- Team AUM (Assets Under Management)
    TOTAL_TEAM_AUM NUMBER(18,2) COMMENT 'Total team portfolio for revenue attribution',
    AVG_CLIENT_BALANCE NUMBER(18,2) COMMENT 'Average client value for quality assessment',
    
    -- Workload Distribution
    AVG_CLIENTS_PER_ADVISOR NUMBER(10,1) COMMENT 'Average workload for balance assessment',
    
    -- Team Capacity Management
    TEAM_CAPACITY_UTILIZATION_PCT NUMBER(10,2) COMMENT 'Team utilization for hiring decisions',
    TEAM_AVAILABLE_CAPACITY NUMBER(10,0) COMMENT 'Remaining capacity for growth planning',
    
    -- Geographic Coverage
    COUNTRIES_COVERED NUMBER(10,0) COMMENT 'Number of countries for international reach',
    COUNTRY_LIST VARCHAR(2000) COMMENT 'Country list for market coverage validation'
)
COMMENT = 'Team leader dashboard with aggregated team performance, workload, and portfolio metrics. Refreshed hourly for management reporting.'
TARGET_LAG = '60 MINUTE' WAREHOUSE = MD_TEST_WH
AS
SELECT 
    -- Team Leader Identity
    tl.EMPLOYEE_ID as TEAM_LEADER_ID,                                  -- Team leader ID for management reporting
    tl.FIRST_NAME || ' ' || tl.FAMILY_NAME as TEAM_LEADER_NAME,       -- Full name for leadership dashboards
    tl.REGION,                                                         -- Geographic region for divisional P and L
    tl.HIRE_DATE,                                                      -- Start date for leadership tenure tracking
    tl.PERFORMANCE_RATING as TL_PERFORMANCE_RATING,                    -- Leader's own rating for correlation with team outcomes
    
    -- Reporting Line
    tl.MANAGER_EMPLOYEE_ID as SUPER_LEADER_ID,                        -- Super leader for executive roll-ups
    stl.FIRST_NAME || ' ' || stl.FAMILY_NAME as SUPER_LEADER_NAME,   -- Super leader name for organizational reporting
    
    -- Team Size & Composition
    COUNT(DISTINCT adv.EMPLOYEE_ID) as TOTAL_ADVISORS,                -- Total advisors for span-of-control analysis
    COUNT(DISTINCT CASE WHEN adv.EMPLOYMENT_STATUS = 'ACTIVE' THEN adv.EMPLOYEE_ID END) as ACTIVE_ADVISORS,  -- Active headcount for capacity planning
    
    -- Team Performance Distribution
    AVG(adv.PERFORMANCE_RATING) as AVG_ADVISOR_PERFORMANCE,           -- Team average for leader effectiveness measurement
    MIN(adv.PERFORMANCE_RATING) as MIN_ADVISOR_PERFORMANCE,           -- Lowest performer for coaching focus
    MAX(adv.PERFORMANCE_RATING) as MAX_ADVISOR_PERFORMANCE,           -- Top performer for best practice sharing
    
    -- Client Portfolio Aggregation
    COUNT(DISTINCT a.CUSTOMER_ID) as TOTAL_CLIENTS,                   -- Total clients under team management
    COUNT(DISTINCT CASE WHEN c.HAS_ANOMALY THEN a.CUSTOMER_ID END) as HIGH_RISK_CLIENTS,  -- High-risk client concentration for oversight
    
    -- Team AUM (Assets Under Management)
    COALESCE(SUM(c360.TOTAL_BALANCE), 0) as TOTAL_TEAM_AUM,          -- Total team portfolio for revenue attribution
    COALESCE(AVG(c360.TOTAL_BALANCE), 0) as AVG_CLIENT_BALANCE,      -- Average client value for quality assessment
    
    -- Workload Distribution
    ROUND(AVG(
        (SELECT COUNT(*) 
         FROM CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT 
         WHERE ADVISOR_EMPLOYEE_ID = adv.EMPLOYEE_ID AND IS_CURRENT = TRUE)
    ), 1) as AVG_CLIENTS_PER_ADVISOR,                                 -- Average workload for balance assessment
    
    -- Team Capacity Management
    ROUND(COUNT(DISTINCT a.CUSTOMER_ID) / (COUNT(DISTINCT adv.EMPLOYEE_ID) * 200.0) * 100, 2) as TEAM_CAPACITY_UTILIZATION_PCT,  -- Team utilization for hiring decisions
    (COUNT(DISTINCT adv.EMPLOYEE_ID) * 200) - COUNT(DISTINCT a.CUSTOMER_ID) as TEAM_AVAILABLE_CAPACITY,  -- Remaining capacity for growth planning
    
    -- Geographic Coverage
    COUNT(DISTINCT adv.COUNTRY) as COUNTRIES_COVERED,                 -- Number of countries for international reach
    LISTAGG(DISTINCT adv.COUNTRY, ', ') WITHIN GROUP (ORDER BY adv.COUNTRY) as COUNTRY_LIST  -- Country list for market coverage validation
    
FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE tl
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE stl ON tl.MANAGER_EMPLOYEE_ID = stl.EMPLOYEE_ID
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE adv ON tl.EMPLOYEE_ID = adv.MANAGER_EMPLOYEE_ID
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT a 
    ON adv.EMPLOYEE_ID = a.ADVISOR_EMPLOYEE_ID 
    AND a.IS_CURRENT = TRUE
LEFT JOIN CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT c ON a.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN CRMA_AGG_DT_CUSTOMER_360 c360 ON a.CUSTOMER_ID = c360.CUSTOMER_ID
WHERE tl.POSITION_LEVEL = 'TEAM_LEADER'
GROUP BY 
    tl.EMPLOYEE_ID, tl.FIRST_NAME, tl.FAMILY_NAME, tl.REGION, tl.HIRE_DATE, 
    tl.PERFORMANCE_RATING, tl.MANAGER_EMPLOYEE_ID, stl.FIRST_NAME, stl.FAMILY_NAME;

-- ============================================================
-- SECTION 4: ASSIGNMENT VIEWS
-- ============================================================

-- Current active client-advisor assignments
CREATE OR REPLACE VIEW EMPA_AGG_VW_CURRENT_ASSIGNMENTS
COMMENT = 'Current active client-advisor assignments with customer and advisor details'
AS
SELECT 
    -- Assignment Record Identity
    a.ASSIGNMENT_ID,                                                   -- Unique assignment record for audit trails
    
    -- Customer Information
    a.CUSTOMER_ID,                                                     -- Customer identifier for 360° lookup
    c.FIRST_NAME || ' ' || c.FAMILY_NAME as CUSTOMER_NAME,            -- Customer name for relationship tracking
    c360.COUNTRY as CUSTOMER_COUNTRY,                                  -- Customer location for local service validation
    c.HAS_ANOMALY as IS_HIGH_RISK_CUSTOMER,                           -- Risk flag for enhanced advisor monitoring
    
    -- Advisor Information
    a.ADVISOR_EMPLOYEE_ID,                                             -- Advisor ID for contact routing and escalation
    e.FIRST_NAME || ' ' || e.FAMILY_NAME as ADVISOR_NAME,             -- Advisor name for customer communications
    e.COUNTRY as ADVISOR_COUNTRY,                                      -- Advisor location for in-person meeting coordination
    e.REGION as ADVISOR_REGION,                                        -- Advisor region for regional support teams
    e.PERFORMANCE_RATING as ADVISOR_RATING,                            -- Advisor quality score for customer satisfaction correlation
    
    -- Management Hierarchy
    e.MANAGER_EMPLOYEE_ID as TEAM_LEADER_ID,                          -- Team leader for service escalation
    tl.FIRST_NAME || ' ' || tl.FAMILY_NAME as TEAM_LEADER_NAME,      -- Team leader name for complaint handling
    
    -- Relationship Timeline
    a.ASSIGNMENT_START_DATE,                                           -- Relationship start for tenure-based service milestones
    DATEDIFF(day, a.ASSIGNMENT_START_DATE, CURRENT_DATE()) as ASSIGNMENT_DURATION_DAYS,  -- Days with advisor for continuity measurement
    ROUND(DATEDIFF(day, a.ASSIGNMENT_START_DATE, CURRENT_DATE()) / 365.25, 1) as ASSIGNMENT_DURATION_YEARS,  -- Years for long-term relationship recognition
    a.ASSIGNMENT_REASON,                                               -- Assignment trigger for quality control analysis
    
    -- Customer Profile Metrics
    c360.TOTAL_BALANCE,                                                -- Customer portfolio value for prioritization
    c360.TOTAL_TRANSACTIONS,                                           -- Transaction activity for engagement scoring
    c360.TOTAL_ACCOUNTS,                                               -- Number of products for cross-sell opportunity
    c360.ACCOUNT_TIER,                                                 -- Customer tier for service level determination
    c360.RISK_CLASSIFICATION,                                          -- Risk tier for compliance oversight requirements
    c360.DAYS_SINCE_LAST_TRANSACTION                                   -- Days since last activity for dormancy tracking
    
FROM CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT a
JOIN CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT c ON a.CUSTOMER_ID = c.CUSTOMER_ID
JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE e ON a.ADVISOR_EMPLOYEE_ID = e.EMPLOYEE_ID
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE tl ON e.MANAGER_EMPLOYEE_ID = tl.EMPLOYEE_ID
LEFT JOIN CRMA_AGG_DT_CUSTOMER_360 c360 ON a.CUSTOMER_ID = c360.CUSTOMER_ID
WHERE a.IS_CURRENT = TRUE;

-- Full assignment history (SCD Type 2)
CREATE OR REPLACE VIEW EMPA_AGG_VW_ASSIGNMENT_HISTORY
COMMENT = 'Complete assignment history with SCD Type 2 tracking for audit trails and compliance'
AS
SELECT 
    -- Assignment Identity
    a.ASSIGNMENT_ID,                                                   -- Assignment record for historical tracking
    
    -- Customer Information
    a.CUSTOMER_ID,                                                     -- Customer ID for lifetime relationship analysis
    c.FIRST_NAME || ' ' || c.FAMILY_NAME as CUSTOMER_NAME,            -- Customer name for audit reports
    
    -- Advisor Information
    a.ADVISOR_EMPLOYEE_ID,                                             -- Advisor ID for historical service quality analysis
    e.FIRST_NAME || ' ' || e.FAMILY_NAME as ADVISOR_NAME,             -- Advisor name for transition documentation
    e.COUNTRY as ADVISOR_COUNTRY,                                      -- Location for geographic continuity tracking
    
    -- Timeline (SCD Type 2)
    a.ASSIGNMENT_START_DATE,                                           -- Relationship start for time-in-service calculations
    a.ASSIGNMENT_END_DATE,                                             -- Relationship end (NULL if current) for transition analysis
    a.IS_CURRENT,                                                      -- Active flag for filtering current vs. historical
    COALESCE(
        DATEDIFF(day, a.ASSIGNMENT_START_DATE, a.ASSIGNMENT_END_DATE),
        DATEDIFF(day, a.ASSIGNMENT_START_DATE, CURRENT_DATE())
    ) as ASSIGNMENT_DURATION_DAYS,                                    -- Relationship duration for stability metrics
    
    -- Assignment Context
    a.ASSIGNMENT_REASON,                                               -- Reason code for churn and transfer pattern analysis
    
    -- Enriched Status Fields
    CASE WHEN a.ASSIGNMENT_END_DATE IS NULL THEN 'ACTIVE' ELSE 'ENDED' END as ASSIGNMENT_STATUS,  -- Simple status for reporting filters
    CASE 
        WHEN a.ASSIGNMENT_REASON = 'TRANSFER' THEN 'Advisor Change'
        WHEN a.ASSIGNMENT_REASON = 'ESCALATION' THEN 'Escalated to Senior'
        WHEN a.ASSIGNMENT_REASON = 'REBALANCING' THEN 'Workload Rebalancing'
        ELSE 'Initial Assignment'
    END as ASSIGNMENT_TYPE_DESCRIPTION                                 -- Human-readable reason for customer communication
    
FROM CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT a
JOIN CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT c ON a.CUSTOMER_ID = c.CUSTOMER_ID
JOIN CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE e ON a.ADVISOR_EMPLOYEE_ID = e.EMPLOYEE_ID;

-- Workload distribution analysis
CREATE OR REPLACE VIEW EMPA_AGG_VW_WORKLOAD_DISTRIBUTION
COMMENT = 'Workload distribution analysis by country and region for capacity planning and rebalancing'
AS
SELECT 
    -- Geographic Grouping
    e.COUNTRY,                                                         -- Country for local workforce planning and hiring
    e.REGION,                                                          -- Region for divisional capacity strategy
    
    -- Workforce Metrics
    COUNT(DISTINCT e.EMPLOYEE_ID) as ADVISOR_COUNT,                   -- Number of advisors for market coverage density
    COUNT(DISTINCT a.CUSTOMER_ID) as TOTAL_CLIENTS,                   -- Total clients served in geography
    
    -- Workload Distribution Statistics
    ROUND(COUNT(DISTINCT a.CUSTOMER_ID) / NULLIF(COUNT(DISTINCT e.EMPLOYEE_ID), 0), 1) as AVG_CLIENTS_PER_ADVISOR,  -- Average load for staffing benchmarks
    MIN(client_counts.CLIENT_COUNT) as MIN_CLIENTS_PER_ADVISOR,       -- Lightest load for underutilization detection
    MAX(client_counts.CLIENT_COUNT) as MAX_CLIENTS_PER_ADVISOR,       -- Heaviest load for burnout risk identification
    ROUND(STDDEV(client_counts.CLIENT_COUNT), 1) as STDDEV_CLIENTS,  -- Load variance for fairness and balance assessment
    
    -- Capacity Analysis (Based on 200 clients/advisor standard)
    COUNT(DISTINCT e.EMPLOYEE_ID) * 200 as TOTAL_CAPACITY,           -- Maximum theoretical capacity for growth planning
    COUNT(DISTINCT a.CUSTOMER_ID) as USED_CAPACITY,                  -- Current utilization for demand tracking
    (COUNT(DISTINCT e.EMPLOYEE_ID) * 200) - COUNT(DISTINCT a.CUSTOMER_ID) as AVAILABLE_CAPACITY,  -- Headroom for new client onboarding
    ROUND(COUNT(DISTINCT a.CUSTOMER_ID) / (COUNT(DISTINCT e.EMPLOYEE_ID) * 200.0) * 100, 2) as CAPACITY_UTILIZATION_PCT,  -- Utilization rate for resource optimization
    
    -- Balance Health Indicator
    CASE 
        WHEN STDDEV(client_counts.CLIENT_COUNT) < 20 THEN 'WELL_BALANCED'
        WHEN STDDEV(client_counts.CLIENT_COUNT) < 40 THEN 'MODERATELY_BALANCED'
        ELSE 'IMBALANCED'
    END as BALANCE_STATUS                                             -- Balance flag for triggering reallocation or coaching initiatives
    
FROM CRM_RAW_001.EMPI_RAW_TB_EMPLOYEE e
LEFT JOIN CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT a 
    ON e.EMPLOYEE_ID = a.ADVISOR_EMPLOYEE_ID 
    AND a.IS_CURRENT = TRUE
LEFT JOIN (
    SELECT 
        ADVISOR_EMPLOYEE_ID,
        COUNT(DISTINCT CUSTOMER_ID) as CLIENT_COUNT
    FROM CRM_RAW_001.EMPI_RAW_TB_CLIENT_ASSIGNMENT
    WHERE IS_CURRENT = TRUE
    GROUP BY ADVISOR_EMPLOYEE_ID
) client_counts ON e.EMPLOYEE_ID = client_counts.ADVISOR_EMPLOYEE_ID
WHERE e.POSITION_LEVEL = 'CLIENT_ADVISOR'
GROUP BY e.COUNTRY, e.REGION;

-- ============================================================
-- DEPLOYMENT COMPLETE
-- ============================================================
-- Employee analytics views are ready for use.
-- 
-- KEY OBJECTS:
-- DYNAMIC TABLES:
-- - EMPA_AGG_DT_ADVISOR_PERFORMANCE: Advisor KPIs and portfolio metrics
-- - EMPA_AGG_DT_TEAM_LEADER_DASHBOARD: Team aggregations for management
-- - EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR: Portfolio valuation by advisor
--
-- VIEWS:
-- - EMPA_AGG_VW_EMPLOYEE_HIERARCHY: Recursive org chart with full paths
-- - EMPA_AGG_VW_ORGANIZATIONAL_CHART: Flat organizational structure
-- - EMPA_AGG_VW_CURRENT_ASSIGNMENTS: Active client-advisor relationships
-- - EMPA_AGG_VW_ASSIGNMENT_HISTORY: Full audit trail of assignments
-- - EMPA_AGG_VW_WORKLOAD_DISTRIBUTION: Capacity and balance analysis
--
-- SAMPLE QUERIES:
-- 
-- -- Top performing advisors by AUM
-- SELECT * FROM EMPA_AGG_DT_ADVISOR_PERFORMANCE 
-- ORDER BY TOTAL_PORTFOLIO_VALUE DESC LIMIT 10;
--
-- -- Team leader comparison
-- SELECT * FROM EMPA_AGG_DT_TEAM_LEADER_DASHBOARD
-- ORDER BY TOTAL_TEAM_AUM DESC;
--
-- -- Workload imbalances
-- SELECT * FROM EMPA_AGG_VW_WORKLOAD_DISTRIBUTION
-- WHERE BALANCE_STATUS = 'IMBALANCED';
--
-- -- Full organizational hierarchy
-- SELECT * FROM EMPA_AGG_VW_EMPLOYEE_HIERARCHY
-- ORDER BY HIERARCHY_LEVEL, EMPLOYEE_ID;
-- ============================================================

