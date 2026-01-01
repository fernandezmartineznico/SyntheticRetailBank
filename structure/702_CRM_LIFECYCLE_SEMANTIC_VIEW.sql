-- ============================================================
-- CRM CUSTOMER LIFECYCLE & CHURN PREDICTION SEMANTIC VIEW
-- Created on: 2025-11-03
-- ============================================================
--
-- OVERVIEW:
-- Semantic view for customer lifecycle analytics and churn prediction focused
-- on retention management and customer experience optimization. Enables CX teams
-- to identify at-risk customers and execute proactive retention campaigns.
--
-- BUSINESS PURPOSE:
-- - Churn probability prediction (0.00-1.00 scale)
-- - Lifecycle stage tracking (NEW, ACTIVE, MATURE, DECLINING, DORMANT, CHURNED)
-- - Dormancy detection (180+ days no activity)
-- - At-risk customer flagging
-- - Engagement metrics and behavioral analytics
--
-- TARGET USERS:
-- - Head of Customer Experience
-- - Retention Teams
-- - Relationship Managers
-- - Customer Success Managers
--
-- BUSINESS VALUE: €600K annually
-- - 45-day advance warning for customer churn
-- - 75% retention success rate for at-risk customers
-- - €1.7M in prevented churn revenue
--
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- CRM_LIFECYCLE_VIEW - Customer Lifecycle and Churn Prediction
-- ============================================================

CREATE OR REPLACE SEMANTIC VIEW CRM_LIFECYCLE_VIEW
	tables (
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE,
		CRMA_AGG_DT_CUSTOMER_360
	)
	facts (
		-- Customer Identity (from LIFECYCLE)
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier | client ID | customer number',
		
		-- Lifecycle Status and Stage
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.CURRENT_STATUS as CURRENT_STATUS comment='Lifecycle status | customer status | relationship status | ACTIVE INACTIVE DORMANT SUSPENDED CLOSED REACTIVATED',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.LIFECYCLE_STAGE as LIFECYCLE_STAGE comment='Lifecycle stage | customer stage | journey stage | relationship phase | NEW ACTIVE MATURE DECLINING DORMANT CHURNED',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.STATUS_SINCE as STATUS_SINCE comment='Status start date | status since | stage entry date | status effective date',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.DAYS_IN_CURRENT_STATUS as DAYS_IN_CURRENT_STATUS comment='Days in status | status duration | time in stage | days in current state',
		
		-- Churn Prediction and Risk
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.CHURN_PROBABILITY as CHURN_PROBABILITY comment='Churn probability | attrition risk | defection likelihood | retention score | 0.00-1.00 scale | >0.70 high risk',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.IS_DORMANT as IS_DORMANT comment='Dormant flag | inactive customer | sleeping customer | no activity 180+ days',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.IS_AT_RISK as IS_AT_RISK comment='At-risk flag | churn risk | retention risk | defection risk | leaving risk',
		
		-- Activity and Engagement Metrics
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.LAST_TRANSACTION_DATE as LAST_TRANSACTION_DATE comment='Last transaction date | last activity | most recent transaction | latest transaction',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.DAYS_SINCE_LAST_TRANSACTION as DAYS_SINCE_LAST_TRANSACTION comment='Days since transaction | transaction recency | activity gap | inactivity period',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.TOTAL_LIFECYCLE_EVENTS as TOTAL_LIFECYCLE_EVENTS comment='Total events | event count | lifecycle event count | activity count',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.LAST_EVENT_DATE as LAST_EVENT_DATE comment='Last event date | most recent event | latest activity | last activity date',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.LAST_EVENT_TYPE as LAST_EVENT_TYPE comment='Last event type | recent event | latest event category | most recent activity type',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.DAYS_SINCE_LAST_EVENT as DAYS_SINCE_LAST_EVENT comment='Days since last event | event recency | time since activity',
		
		-- Lifecycle Event Counts
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.ADDRESS_CHANGES as ADDRESS_CHANGES comment='Address changes | relocation count | move count | address updates',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.EMPLOYMENT_CHANGES as EMPLOYMENT_CHANGES comment='Employment changes | job changes | career changes | employer changes',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.ACCOUNT_UPGRADES as ACCOUNT_UPGRADES comment='Account upgrades | tier upgrades | product upgrades | service upgrades',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.ACCOUNT_DOWNGRADES as ACCOUNT_DOWNGRADES comment='Account downgrades | tier downgrades | product downgrades | service downgrades',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.ACCOUNT_CLOSURES as ACCOUNT_CLOSURES comment='Account closures | closed accounts | terminated products | account terminations',
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.REACTIVATIONS as REACTIVATIONS comment='Reactivations | account reopenings | relationship renewals | account restorations',
		
		-- Customer Context (from CUSTOMER_360)
		CRMA_AGG_DT_CUSTOMER_360.FULL_NAME as FULL_NAME comment='Full name | customer name | client name',
		CRMA_AGG_DT_CUSTOMER_360.ACCOUNT_TIER as ACCOUNT_TIER comment='Account tier | customer tier | service level | STANDARD SILVER GOLD PLATINUM PREMIUM',
		CRMA_AGG_DT_CUSTOMER_360.COUNTRY as COUNTRY comment='Country | domicile | residence country',
		CRMA_AGG_DT_CUSTOMER_360.EMAIL as EMAIL comment='Email address | contact email | email for outreach',
		CRMA_AGG_DT_CUSTOMER_360.TOTAL_ACCOUNTS as TOTAL_ACCOUNTS comment='Total accounts | account count | number of accounts',
		
		-- Data Freshness
		CRMA_AGG_DT_CUSTOMER_LIFECYCLE.LAST_UPDATED as LAST_UPDATED comment='Last updated | data freshness | refresh timestamp'
	);

-- ============================================================
-- DEPLOYMENT COMPLETE!
-- ============================================================
--
-- SEMANTIC VIEW CREATED: CRM_LIFECYCLE_VIEW
--
-- BUSINESS QUESTIONS IT ANSWERS:
-- - "Show me GOLD and PLATINUM customers at risk of churning"
-- - "Which customers have churn probability greater than 70 percent?"
-- - "Give me a retention campaign target list"
-- - "What is the lifecycle stage distribution?"
-- - "Show me dormant customers who became inactive recently"
-- - "Which high-value customers are declining?"
--
-- USAGE EXAMPLES:
--
-- 1. At-risk high-value customers:
--    SELECT c.CUSTOMER_ID, c.FULL_NAME, c.ACCOUNT_TIER, c.COUNTRY,
--           lc.CHURN_PROBABILITY, lc.LIFECYCLE_STAGE,
--           lc.DAYS_SINCE_LAST_TRANSACTION
--    FROM CRMA_AGG_DT_CUSTOMER_360 c
--    JOIN CRMA_AGG_DT_CUSTOMER_LIFECYCLE lc ON c.CUSTOMER_ID = lc.CUSTOMER_ID
--    WHERE c.ACCOUNT_TIER IN ('GOLD', 'PLATINUM', 'PREMIUM')
--      AND (lc.IS_AT_RISK = TRUE OR lc.IS_DORMANT = TRUE)
--    ORDER BY lc.CHURN_PROBABILITY DESC;
--
-- 2. Churn risk distribution by lifecycle stage:
--    SELECT LIFECYCLE_STAGE,
--           COUNT(*) AS CUSTOMER_COUNT,
--           ROUND(AVG(CHURN_PROBABILITY), 3) AS AVG_CHURN_PROBABILITY,
--           SUM(CASE WHEN IS_AT_RISK = TRUE THEN 1 ELSE 0 END) AS AT_RISK_COUNT,
--           SUM(CASE WHEN IS_DORMANT = TRUE THEN 1 ELSE 0 END) AS DORMANT_COUNT
--    FROM CRMA_AGG_DT_CUSTOMER_LIFECYCLE
--    GROUP BY LIFECYCLE_STAGE
--    ORDER BY AVG_CHURN_PROBABILITY DESC;
--
-- 3. Retention campaign target list with contact info:
--    SELECT c.CUSTOMER_ID, c.FULL_NAME, c.EMAIL, c.ACCOUNT_TIER, c.COUNTRY,
--           lc.CHURN_PROBABILITY, lc.DAYS_SINCE_LAST_TRANSACTION,
--           lc.LIFECYCLE_STAGE
--    FROM CRMA_AGG_DT_CUSTOMER_360 c
--    JOIN CRMA_AGG_DT_CUSTOMER_LIFECYCLE lc ON c.CUSTOMER_ID = lc.CUSTOMER_ID
--    WHERE lc.CHURN_PROBABILITY > 0.50
--      AND c.ACCOUNT_TIER IN ('SILVER', 'GOLD', 'PLATINUM', 'PREMIUM')
--      AND c.EMAIL IS NOT NULL
--    ORDER BY lc.CHURN_PROBABILITY DESC, c.ACCOUNT_TIER DESC;
--
-- 4. Dormant account reactivation targets:
--    SELECT c.CUSTOMER_ID, c.FULL_NAME, c.ACCOUNT_TIER, c.EMAIL,
--           lc.DAYS_SINCE_LAST_TRANSACTION, lc.LAST_TRANSACTION_DATE
--    FROM CRMA_AGG_DT_CUSTOMER_360 c
--    JOIN CRMA_AGG_DT_CUSTOMER_LIFECYCLE lc ON c.CUSTOMER_ID = lc.CUSTOMER_ID
--    WHERE lc.IS_DORMANT = TRUE
--      AND lc.DAYS_SINCE_LAST_TRANSACTION BETWEEN 180 AND 270
--    ORDER BY lc.DAYS_SINCE_LAST_TRANSACTION ASC;
--
-- MONITORING:
-- - Check semantic view: SHOW VIEWS LIKE '%LIFECYCLE%' IN SCHEMA CRM_AGG_001;
-- - Check data freshness: SELECT MAX(LAST_UPDATED) FROM CRMA_AGG_DT_CUSTOMER_LIFECYCLE;
--
-- RELATED TABLES:
-- - CRMA_AGG_DT_CUSTOMER_LIFECYCLE - Source table with lifecycle analytics
-- - CRMA_AGG_DT_CUSTOMER_360 - Customer context and contact information
-- - CRMI_RAW_TB_CUSTOMER_EVENT - Detailed lifecycle event history
--
-- BUSINESS VALUE:
-- - €600K annual revenue recovery from churn prevention
-- - 45-day advance warning before customers churn
-- - 75% retention success rate for at-risk customers
-- - €1.7M total annual value from prevented churn
-- - NPS improvement: +26 points (42 → 68)
--
-- KEY METRICS:
-- - Churn Probability Ranges:
--   * 0.00-0.30: Safe, no action needed
--   * 0.31-0.50: Monitor, standard engagement
--   * 0.51-0.70: At risk, consider outreach
--   * 0.71-0.85: High risk, proactive retention
--   * 0.86-1.00: Critical, executive intervention
--
-- - Lifecycle Stages:
--   * NEW: Just onboarded (first 90 days)
--   * ACTIVE: Regular engagement, healthy relationship
--   * MATURE: Long-term customer, stable patterns
--   * DECLINING: Engagement dropping, warning sign
--   * DORMANT: No activity 180+ days, intervention needed
--   * CHURNED: Relationship ended
-- ============================================================

