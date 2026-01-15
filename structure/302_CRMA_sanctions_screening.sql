-- ============================================================
-- Sanctions Screening Views for Customer 360
-- File: 302_CRMA_sanctions_screening.sql
-- Schema: CRM_AGG_001
-- Dependencies: 
--   - AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY.PUBLIC.SANCTIONS_TB_DATA_STAGING
--   - 010_CRMI_customer_master.sql (CRMI_RAW_TB_CUSTOMER)
-- ============================================================
--
-- BUSINESS PURPOSE:
-- This file creates views for sanctions screening that are used by the
-- Customer 360 view (410_CRMA_customer_360.sql). It provides:
-- 1. Enriched sanctions data with risk scores and active status
-- 2. Customer sanctions screening results (exact + fuzzy matches)
-- 3. Reusable screening logic for consistency across all compliance notebooks
--
-- SHOWCASE ENHANCEMENTS:
-- - Risk scoring for prioritization (OFAC SDN = 10, Individuals = 8)
-- - Active/expired sanctions filtering
-- - Fuzzy matching with confidence levels (exact, high, medium, low)
-- - Multi-signal matching (name, DOB, nationality)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA CRM_AGG_001;

-- ============================================================
-- VIEW 1: Enriched Sanctions Data (Base Layer)
-- ============================================================
-- Purpose: Add calculated fields for risk scoring and filtering
-- Usage: Base view for all sanctions screening queries

CREATE OR REPLACE VIEW CRMA_AGG_VW_SANCTIONS_ENRICHED AS
SELECT 
    -- Original sanctions data fields
    "Sr No.",
    ENTITY_ID,
    ENTITY_NAME,
    ENTITY_ALIASES,
    ENTITY_TYPE,
    TRY_CAST(DOB AS VARCHAR) AS DOB,  -- Convert to VARCHAR (data contains arrays like ['1948', '1949'])
    POB,
    NATIONALITY_COUNTRY,
    CITIZENSHIP_COUNTRY,
    ADDRESS,
    AUTHORITY,
    LIST_NAME,
    EFFECTIVE_DATE,
    EXPIRY_DATE,
    ENTITY_NOTES,
    CITATION_LINK,
    COUNTRY,
    LISTING_COUNTRY,
    CALL_SIGN,
    VESSEL_TYPE,
    VESSEL_FLAG,
    VESSEL_OWNER,
    GROSS_TONNAGE,
    GROSS_REGISTERED_TONNAGE,
    CREATED_DATE,
    
    -- Enhancement 1: Risk Score (for prioritization)
    CASE 
        WHEN AUTHORITY = 'DOT - Department of Treasury' AND LIST_NAME LIKE '%SDN%' THEN 10  -- OFAC SDN = Critical
        WHEN AUTHORITY LIKE '%UK%' OR AUTHORITY LIKE '%Canada%' THEN 7                      -- UK/Canada = High
        WHEN ENTITY_TYPE = 'Individual' THEN 8                                               -- Individuals = Higher risk
        WHEN ENTITY_TYPE = 'Vessel' THEN 5                                                  -- Vessels = Medium risk
        ELSE 6                                                                               -- Default = Medium
    END AS RISK_SCORE,
    
    -- Enhancement 2: Active Status (for filtering expired sanctions)
    CASE 
        WHEN EXPIRY_DATE IS NULL THEN TRUE                     -- No expiry = Active
        WHEN EXPIRY_DATE > CURRENT_DATE() THEN TRUE            -- Future expiry = Active
        ELSE FALSE                                             -- Past expiry = Delisted
    END AS IS_ACTIVE,
    
    -- Enhancement 3: Sanctions Program (friendly name for storytelling)
    CASE 
        WHEN LIST_NAME LIKE '%SDN%' THEN 'OFAC Specially Designated Nationals (SDN)'
        WHEN LIST_NAME LIKE '%UK Sanctions%' THEN 'UK Russia Sanctions'
        WHEN LIST_NAME LIKE '%Canada%' THEN 'Canada Port State Control'
        ELSE LIST_NAME
    END AS SANCTIONS_PROGRAM,
    
    -- Enhancement 4: Authority Category (for multi-jurisdiction demos)
    CASE 
        WHEN AUTHORITY LIKE '%DOT%' OR AUTHORITY LIKE '%Treasury%' THEN 'US_OFAC'
        WHEN AUTHORITY LIKE '%UK%' OR AUTHORITY LIKE '%FCDO%' THEN 'UK_OFSI'
        WHEN AUTHORITY LIKE '%Canada%' THEN 'CANADA_PSC'
        WHEN AUTHORITY LIKE '%EU%' THEN 'EU_SANCTIONS'
        WHEN AUTHORITY LIKE '%SECO%' THEN 'SWISS_SECO'
        ELSE 'OTHER'
    END AS AUTHORITY_CATEGORY,
    
    -- Enhancement 5: Days Since Listing (for temporal analysis)
    DATEDIFF(day, EFFECTIVE_DATE, CURRENT_DATE()) AS DAYS_SINCE_LISTING,
    
    -- Enhancement 6: Days Until Expiry (for delisting monitoring)
    CASE 
        WHEN EXPIRY_DATE IS NOT NULL 
        THEN DATEDIFF(day, CURRENT_DATE(), EXPIRY_DATE)
        ELSE NULL
    END AS DAYS_UNTIL_EXPIRY,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS VIEW_CREATED_AT

FROM AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET_COPY.PUBLIC.SANCTIONS_TB_DATA_STAGING;


-- ============================================================
-- VIEW 2: Customer Sanctions Screening (Exact + Fuzzy Matches)
-- ============================================================
-- Purpose: Combine exact and fuzzy matching logic from Customer 360
-- Usage: Reusable screening logic for notebooks and dashboards

CREATE OR REPLACE VIEW CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING AS
WITH customer_base AS (
    -- Get current customer data with country from addresses
    SELECT 
        c.CUSTOMER_ID,
        c.FIRST_NAME,
        c.FAMILY_NAME,
        CONCAT(c.FIRST_NAME, ' ', c.FAMILY_NAME) AS FULL_NAME,
        c.DATE_OF_BIRTH,
        COALESCE(a.COUNTRY, 'UNKNOWN') AS CUSTOMER_COUNTRY,
        NULL AS CUSTOMER_NATIONALITY,  -- Not available in customer table
        NULL AS CUSTOMER_TYPE,  -- Not available in customer table
        c.RISK_CLASSIFICATION,
        c.INSERT_TIMESTAMP_UTC AS CUSTOMER_CREATED_DATE
    FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER c
    LEFT JOIN (
        SELECT CUSTOMER_ID, COUNTRY, 
               ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY INSERT_TIMESTAMP_UTC DESC) as rn
        FROM CRM_RAW_001.CRMI_RAW_TB_ADDRESSES
    ) a ON c.CUSTOMER_ID = a.CUSTOMER_ID AND a.rn = 1
),
exact_matches AS (
    -- Exact name matches (from line 762-763 of Customer 360)
    SELECT 
        c.CUSTOMER_ID,
        c.FULL_NAME AS CUSTOMER_NAME,
        c.DATE_OF_BIRTH AS CUSTOMER_DOB,
        c.CUSTOMER_COUNTRY,
        c.CUSTOMER_NATIONALITY,
        c.CUSTOMER_TYPE,
        c.RISK_CLASSIFICATION,
        s.ENTITY_ID,
        s.ENTITY_NAME,
        s.ENTITY_ALIASES,
        s.DOB AS SANCTIONS_DOB,
        s.NATIONALITY_COUNTRY AS SANCTIONS_NATIONALITY,
        s.AUTHORITY,
        s.LIST_NAME,
        s.SANCTIONS_PROGRAM,
        s.RISK_SCORE AS SANCTIONS_RISK_SCORE,
        s.IS_ACTIVE AS SANCTIONS_IS_ACTIVE,
        s.EFFECTIVE_DATE,
        s.EXPIRY_DATE,
        s.CITATION_LINK,
        'EXACT_MATCH' AS MATCH_TYPE,
        100.0 AS MATCH_SCORE,
        0 AS EDIT_DISTANCE
    FROM customer_base c
    INNER JOIN CRMA_AGG_VW_SANCTIONS_ENRICHED s
        ON UPPER(c.FULL_NAME) = UPPER(s.ENTITY_NAME)
    WHERE s.IS_ACTIVE = TRUE  -- Only active sanctions
),
fuzzy_matches AS (
    -- Fuzzy name matches using EDITDISTANCE (from line 765-767 of Customer 360)
    SELECT 
        c.CUSTOMER_ID,
        c.FULL_NAME AS CUSTOMER_NAME,
        c.DATE_OF_BIRTH AS CUSTOMER_DOB,
        c.CUSTOMER_COUNTRY,
        c.CUSTOMER_NATIONALITY,
        c.CUSTOMER_TYPE,
        c.RISK_CLASSIFICATION,
        s.ENTITY_ID,
        s.ENTITY_NAME,
        s.ENTITY_ALIASES,
        s.DOB AS SANCTIONS_DOB,
        s.NATIONALITY_COUNTRY AS SANCTIONS_NATIONALITY,
        s.AUTHORITY,
        s.LIST_NAME,
        s.SANCTIONS_PROGRAM,
        s.RISK_SCORE AS SANCTIONS_RISK_SCORE,
        s.IS_ACTIVE AS SANCTIONS_IS_ACTIVE,
        s.EFFECTIVE_DATE,
        s.EXPIRY_DATE,
        s.CITATION_LINK,
        'FUZZY_MATCH' AS MATCH_TYPE,
        -- Calculate match score based on edit distance
        CASE 
            WHEN EDITDISTANCE(UPPER(c.FULL_NAME), UPPER(s.ENTITY_NAME)) <= 1 THEN 95.0  -- 1 character difference
            WHEN EDITDISTANCE(UPPER(c.FULL_NAME), UPPER(s.ENTITY_NAME)) <= 2 THEN 90.0  -- 2 characters difference
            WHEN EDITDISTANCE(UPPER(c.FULL_NAME), UPPER(s.ENTITY_NAME)) <= 3 THEN 85.0  -- 3 characters difference
            WHEN EDITDISTANCE(UPPER(c.FULL_NAME), UPPER(s.ENTITY_NAME)) <= 4 THEN 80.0  -- 4 characters difference
            WHEN EDITDISTANCE(UPPER(c.FULL_NAME), UPPER(s.ENTITY_NAME)) <= 5 THEN 75.0  -- 5 characters difference
            ELSE 70.0
        END AS MATCH_SCORE,
        EDITDISTANCE(UPPER(c.FULL_NAME), UPPER(s.ENTITY_NAME)) AS EDIT_DISTANCE
    FROM customer_base c
    INNER JOIN CRMA_AGG_VW_SANCTIONS_ENRICHED s
        ON s.ENTITY_ID NOT IN (
            -- Exclude customers who already have exact matches
            SELECT ENTITY_ID FROM exact_matches WHERE CUSTOMER_ID = c.CUSTOMER_ID
        )
        AND EDITDISTANCE(UPPER(c.FULL_NAME), UPPER(s.ENTITY_NAME)) <= 5
    WHERE s.IS_ACTIVE = TRUE  -- Only active sanctions
),
alias_matches AS (
    -- Check aliases for additional matches
    SELECT 
        c.CUSTOMER_ID,
        c.FULL_NAME AS CUSTOMER_NAME,
        c.DATE_OF_BIRTH AS CUSTOMER_DOB,
        c.CUSTOMER_COUNTRY,
        c.CUSTOMER_NATIONALITY,
        c.CUSTOMER_TYPE,
        c.RISK_CLASSIFICATION,
        s.ENTITY_ID,
        s.ENTITY_NAME,
        s.ENTITY_ALIASES,
        s.DOB AS SANCTIONS_DOB,
        s.NATIONALITY_COUNTRY AS SANCTIONS_NATIONALITY,
        s.AUTHORITY,
        s.LIST_NAME,
        s.SANCTIONS_PROGRAM,
        s.RISK_SCORE AS SANCTIONS_RISK_SCORE,
        s.IS_ACTIVE AS SANCTIONS_IS_ACTIVE,
        s.EFFECTIVE_DATE,
        s.EXPIRY_DATE,
        s.CITATION_LINK,
        'ALIAS_MATCH' AS MATCH_TYPE,
        95.0 AS MATCH_SCORE,  -- Alias matches are high confidence
        0 AS EDIT_DISTANCE
    FROM customer_base c
    INNER JOIN CRMA_AGG_VW_SANCTIONS_ENRICHED s
        ON UPPER(s.ENTITY_ALIASES) LIKE '%' || UPPER(c.FULL_NAME) || '%'
        AND s.ENTITY_ID NOT IN (
            -- Exclude customers who already have exact matches
            SELECT ENTITY_ID FROM exact_matches WHERE CUSTOMER_ID = c.CUSTOMER_ID
        )
    WHERE s.IS_ACTIVE = TRUE
      AND s.ENTITY_ALIASES IS NOT NULL
),
all_matches AS (
    -- Combine all match types
    SELECT * FROM exact_matches
    UNION ALL
    SELECT * FROM fuzzy_matches
    UNION ALL
    SELECT * FROM alias_matches
)
SELECT 
    -- Customer Information
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CUSTOMER_DOB,
    CUSTOMER_COUNTRY,
    CUSTOMER_NATIONALITY,
    CUSTOMER_TYPE,
    RISK_CLASSIFICATION,
    
    -- Sanctions Entity Information
    ENTITY_ID,
    ENTITY_NAME,
    ENTITY_ALIASES,
    SANCTIONS_DOB,
    SANCTIONS_NATIONALITY,
    AUTHORITY,
    LIST_NAME,
    SANCTIONS_PROGRAM,
    SANCTIONS_RISK_SCORE,
    SANCTIONS_IS_ACTIVE,
    EFFECTIVE_DATE,
    EXPIRY_DATE,
    CITATION_LINK,
    
    -- Match Information
    MATCH_TYPE,
    MATCH_SCORE,
    EDIT_DISTANCE,
    
    -- Multi-Signal Matching Flags
    -- Note: SANCTIONS_DOB contains unreliable data (arrays like ['1948', '1949']), 
    -- so DOB matching is disabled for showcase. In production, use clean reference data.
    CASE 
        WHEN CUSTOMER_DOB IS NOT NULL 
             AND SANCTIONS_DOB IS NOT NULL 
             AND SANCTIONS_DOB NOT LIKE '%[%' 
             AND TO_VARCHAR(CUSTOMER_DOB, 'YYYY-MM-DD') = SANCTIONS_DOB 
        THEN TRUE 
        ELSE FALSE 
    END AS DOB_MATCH,
    CASE WHEN CUSTOMER_NATIONALITY = SANCTIONS_NATIONALITY THEN TRUE ELSE FALSE END AS NATIONALITY_MATCH,
    CASE WHEN CUSTOMER_COUNTRY = SANCTIONS_NATIONALITY THEN TRUE ELSE FALSE END AS COUNTRY_MATCH,
    
    -- Match Confidence Classification
    CASE 
        WHEN MATCH_TYPE = 'EXACT_MATCH' THEN 'EXACT'
        WHEN MATCH_TYPE = 'ALIAS_MATCH' THEN 'HIGH_CONFIDENCE'
        WHEN MATCH_SCORE >= 90 THEN 'HIGH_CONFIDENCE'
        WHEN MATCH_SCORE >= 80 THEN 'MEDIUM_CONFIDENCE'
        WHEN MATCH_SCORE >= 70 THEN 'LOW_CONFIDENCE'
        ELSE 'VERY_LOW_CONFIDENCE'
    END AS MATCH_CONFIDENCE,
    
    -- Disposition Recommendation
    CASE 
        WHEN MATCH_TYPE = 'EXACT_MATCH' AND DOB_MATCH THEN 'HARD_BLOCK'
        WHEN MATCH_TYPE = 'EXACT_MATCH' THEN 'IMMEDIATE_INVESTIGATION'
        WHEN MATCH_TYPE = 'ALIAS_MATCH' THEN 'IMMEDIATE_INVESTIGATION'
        WHEN MATCH_SCORE >= 90 AND (DOB_MATCH OR NATIONALITY_MATCH) THEN 'IMMEDIATE_INVESTIGATION'
        WHEN MATCH_SCORE >= 85 THEN 'ENHANCED_DUE_DILIGENCE'
        WHEN MATCH_SCORE >= 75 THEN 'MANUAL_REVIEW'
        ELSE 'LIKELY_FALSE_POSITIVE'
    END AS DISPOSITION_RECOMMENDATION,
    
    -- Combined Risk Score (Customer Risk + Sanctions Risk)
    CASE 
        WHEN RISK_CLASSIFICATION = 'CRITICAL' THEN 10
        WHEN RISK_CLASSIFICATION = 'HIGH' THEN 8
        WHEN RISK_CLASSIFICATION = 'MEDIUM' THEN 5
        WHEN RISK_CLASSIFICATION = 'LOW' THEN 3
        ELSE 5
    END + SANCTIONS_RISK_SCORE AS COMBINED_RISK_SCORE,
    
    -- Alert Priority
    CASE 
        WHEN MATCH_TYPE = 'EXACT_MATCH' AND DOB_MATCH THEN 'CRITICAL'
        WHEN MATCH_TYPE = 'EXACT_MATCH' OR MATCH_TYPE = 'ALIAS_MATCH' THEN 'HIGH'
        WHEN MATCH_SCORE >= 85 THEN 'HIGH'
        WHEN MATCH_SCORE >= 75 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS ALERT_PRIORITY,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS SCREENING_TIMESTAMP

FROM all_matches;


-- ============================================================
-- VIEW 3: Sanctions Screening Summary (Aggregate Metrics)
-- ============================================================
-- Purpose: Provide high-level metrics for dashboards
-- Usage: Quick metrics for notebooks and Streamlit dashboards

CREATE OR REPLACE VIEW CRMA_AGG_VW_SANCTIONS_SCREENING_SUMMARY AS
SELECT 
    -- Overall Screening Metrics
    COUNT(DISTINCT CUSTOMER_ID) AS total_customers_with_matches,
    COUNT(DISTINCT ENTITY_ID) AS total_sanctions_entities_matched,
    COUNT(*) AS total_matches,
    
    -- Match Type Distribution
    COUNT(DISTINCT CASE WHEN MATCH_TYPE = 'EXACT_MATCH' THEN CUSTOMER_ID END) AS exact_match_customers,
    COUNT(DISTINCT CASE WHEN MATCH_TYPE = 'FUZZY_MATCH' THEN CUSTOMER_ID END) AS fuzzy_match_customers,
    COUNT(DISTINCT CASE WHEN MATCH_TYPE = 'ALIAS_MATCH' THEN CUSTOMER_ID END) AS alias_match_customers,
    
    -- Match Confidence Distribution
    COUNT(DISTINCT CASE WHEN MATCH_CONFIDENCE = 'EXACT' THEN CUSTOMER_ID END) AS exact_confidence_customers,
    COUNT(DISTINCT CASE WHEN MATCH_CONFIDENCE = 'HIGH_CONFIDENCE' THEN CUSTOMER_ID END) AS high_confidence_customers,
    COUNT(DISTINCT CASE WHEN MATCH_CONFIDENCE = 'MEDIUM_CONFIDENCE' THEN CUSTOMER_ID END) AS medium_confidence_customers,
    COUNT(DISTINCT CASE WHEN MATCH_CONFIDENCE = 'LOW_CONFIDENCE' THEN CUSTOMER_ID END) AS low_confidence_customers,
    
    -- Disposition Distribution
    COUNT(DISTINCT CASE WHEN DISPOSITION_RECOMMENDATION = 'HARD_BLOCK' THEN CUSTOMER_ID END) AS hard_block_required,
    COUNT(DISTINCT CASE WHEN DISPOSITION_RECOMMENDATION = 'IMMEDIATE_INVESTIGATION' THEN CUSTOMER_ID END) AS immediate_investigation_required,
    COUNT(DISTINCT CASE WHEN DISPOSITION_RECOMMENDATION = 'ENHANCED_DUE_DILIGENCE' THEN CUSTOMER_ID END) AS edd_required,
    COUNT(DISTINCT CASE WHEN DISPOSITION_RECOMMENDATION = 'MANUAL_REVIEW' THEN CUSTOMER_ID END) AS manual_review_required,
    COUNT(DISTINCT CASE WHEN DISPOSITION_RECOMMENDATION = 'LIKELY_FALSE_POSITIVE' THEN CUSTOMER_ID END) AS likely_false_positives,
    
    -- Alert Priority Distribution
    COUNT(DISTINCT CASE WHEN ALERT_PRIORITY = 'CRITICAL' THEN CUSTOMER_ID END) AS critical_alerts,
    COUNT(DISTINCT CASE WHEN ALERT_PRIORITY = 'HIGH' THEN CUSTOMER_ID END) AS high_alerts,
    COUNT(DISTINCT CASE WHEN ALERT_PRIORITY = 'MEDIUM' THEN CUSTOMER_ID END) AS medium_alerts,
    COUNT(DISTINCT CASE WHEN ALERT_PRIORITY = 'LOW' THEN CUSTOMER_ID END) AS low_alerts,
    
    -- Authority Distribution
    COUNT(DISTINCT CASE WHEN AUTHORITY LIKE '%DOT%' OR AUTHORITY LIKE '%Treasury%' THEN CUSTOMER_ID END) AS ofac_matches,
    COUNT(DISTINCT CASE WHEN AUTHORITY LIKE '%UK%' THEN CUSTOMER_ID END) AS uk_matches,
    COUNT(DISTINCT CASE WHEN AUTHORITY LIKE '%Canada%' THEN CUSTOMER_ID END) AS canada_matches,
    
    -- Average Match Scores
    ROUND(AVG(MATCH_SCORE), 2) AS avg_match_score,
    ROUND(AVG(CASE WHEN MATCH_TYPE = 'FUZZY_MATCH' THEN MATCH_SCORE END), 2) AS avg_fuzzy_match_score,
    
    -- Metadata
    CURRENT_TIMESTAMP() AS SUMMARY_GENERATED_AT

FROM CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING;


-- ============================================================
-- VIEW 4: High-Risk Sanctions Alerts (Actionable Items)
-- ============================================================
-- Purpose: Filter to only actionable alerts requiring investigation
-- Usage: Alert management and investigation workflows

CREATE OR REPLACE VIEW CRMA_AGG_VW_SANCTIONS_HIGH_RISK_ALERTS AS
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    CUSTOMER_DOB,
    CUSTOMER_COUNTRY,
    CUSTOMER_NATIONALITY,
    CUSTOMER_TYPE,
    RISK_CLASSIFICATION,
    ENTITY_ID,
    ENTITY_NAME,
    ENTITY_ALIASES,
    SANCTIONS_DOB,
    SANCTIONS_NATIONALITY,
    AUTHORITY,
    LIST_NAME,
    SANCTIONS_PROGRAM,
    SANCTIONS_RISK_SCORE,
    EFFECTIVE_DATE,
    CITATION_LINK,
    MATCH_TYPE,
    MATCH_SCORE,
    EDIT_DISTANCE,
    DOB_MATCH,
    NATIONALITY_MATCH,
    MATCH_CONFIDENCE,
    DISPOSITION_RECOMMENDATION,
    COMBINED_RISK_SCORE,
    ALERT_PRIORITY,
    SCREENING_TIMESTAMP
FROM CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING
WHERE 
    -- Only include alerts requiring action
    DISPOSITION_RECOMMENDATION IN ('HARD_BLOCK', 'IMMEDIATE_INVESTIGATION', 'ENHANCED_DUE_DILIGENCE')
    AND ALERT_PRIORITY IN ('CRITICAL', 'HIGH')
ORDER BY 
    -- Prioritize by alert priority, then combined risk score, then match score
    CASE ALERT_PRIORITY 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        ELSE 3 
    END,
    COMBINED_RISK_SCORE DESC,
    MATCH_SCORE DESC;


-- ============================================================
-- VALIDATION QUERIES
-- ============================================================

-- Test View 1: Enriched Sanctions Data
SELECT 
    'CRMA_AGG_VW_SANCTIONS_ENRICHED' AS view_name,
    COUNT(*) AS total_records,
    COUNT(DISTINCT ENTITY_ID) AS unique_entities,
    COUNT(DISTINCT AUTHORITY) AS unique_authorities,
    SUM(CASE WHEN IS_ACTIVE = TRUE THEN 1 ELSE 0 END) AS active_sanctions,
    SUM(CASE WHEN IS_ACTIVE = FALSE THEN 1 ELSE 0 END) AS expired_sanctions,
    ROUND(AVG(RISK_SCORE), 2) AS avg_risk_score
FROM CRMA_AGG_VW_SANCTIONS_ENRICHED;

-- Test View 2: Customer Sanctions Screening
SELECT 
    'CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING' AS view_name,
    COUNT(DISTINCT CUSTOMER_ID) AS customers_with_matches,
    COUNT(DISTINCT ENTITY_ID) AS unique_sanctions_matched,
    COUNT(*) AS total_matches,
    COUNT(DISTINCT CASE WHEN MATCH_TYPE = 'EXACT_MATCH' THEN CUSTOMER_ID END) AS exact_matches,
    COUNT(DISTINCT CASE WHEN MATCH_TYPE = 'FUZZY_MATCH' THEN CUSTOMER_ID END) AS fuzzy_matches,
    COUNT(DISTINCT CASE WHEN MATCH_TYPE = 'ALIAS_MATCH' THEN CUSTOMER_ID END) AS alias_matches
FROM CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING;

-- Test View 3: Screening Summary
SELECT * FROM CRMA_AGG_VW_SANCTIONS_SCREENING_SUMMARY;

-- Test View 4: High-Risk Alerts
SELECT 
    'CRMA_AGG_VW_SANCTIONS_HIGH_RISK_ALERTS' AS view_name,
    COUNT(DISTINCT CUSTOMER_ID) AS high_risk_customers,
    COUNT(*) AS high_risk_alerts,
    COUNT(DISTINCT CASE WHEN ALERT_PRIORITY = 'CRITICAL' THEN CUSTOMER_ID END) AS critical_priority,
    COUNT(DISTINCT CASE WHEN ALERT_PRIORITY = 'HIGH' THEN CUSTOMER_ID END) AS high_priority
FROM CRMA_AGG_VW_SANCTIONS_HIGH_RISK_ALERTS;

-- ============================================================
-- GRANTS (if needed for specific roles)
-- ============================================================

-- GRANT SELECT ON CRMA_AGG_VW_SANCTIONS_ENRICHED TO ROLE COMPLIANCE_OFFICER;
-- GRANT SELECT ON CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING TO ROLE COMPLIANCE_OFFICER;
-- GRANT SELECT ON CRMA_AGG_VW_SANCTIONS_SCREENING_SUMMARY TO ROLE COMPLIANCE_OFFICER;
-- GRANT SELECT ON CRMA_AGG_VW_SANCTIONS_HIGH_RISK_ALERTS TO ROLE COMPLIANCE_OFFICER;

-- ============================================================
-- DOCUMENTATION
-- ============================================================

/*
USAGE EXAMPLES:

1. Get all active sanctions with risk scores:
   SELECT * FROM CRMA_AGG_VW_SANCTIONS_ENRICHED WHERE IS_ACTIVE = TRUE;

2. Find customers with exact sanctions matches:
   SELECT * FROM CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING WHERE MATCH_TYPE = 'EXACT_MATCH';

3. Get high-risk alerts requiring immediate action:
   SELECT * FROM CRMA_AGG_VW_SANCTIONS_HIGH_RISK_ALERTS;

4. Get screening summary metrics for dashboard:
   SELECT * FROM CRMA_AGG_VW_SANCTIONS_SCREENING_SUMMARY;

5. Find customers with DOB matches (higher confidence):
   SELECT * FROM CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING WHERE DOB_MATCH = TRUE;

INTEGRATION WITH CUSTOMER 360:
This view replaces the inline JOIN logic in 410_CRMA_customer_360.sql (lines 762-767).
Instead of joining directly to SANCTIONS_TB_DATA_STAGING, Customer 360 can now:
  - LEFT JOIN CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING s ON c.CUSTOMER_ID = s.CUSTOMER_ID

NOTEBOOK UPDATES:
All compliance notebooks can now use these views for consistent sanctions screening:
  - customer_screening_kyc.ipynb: Use CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING
  - sanctions_embargo_control.ipynb: Use CRMA_AGG_VW_SANCTIONS_ENRICHED and CRMA_AGG_VW_SANCTIONS_SCREENING_SUMMARY
  - compliance_risk_management.ipynb: Use CRMA_AGG_VW_SANCTIONS_HIGH_RISK_ALERTS

*/
