# Database Objects Inventory

**Database:** `AAA_DEV_SYNTHETIC_BANK`  
**Generated:** 2025-12-31  
**Total Objects:** 120

## Summary by Schema

| Schema | Tables | Views | Dynamic Tables | Stages | Streams | Semantic Views | Total |
|--------|--------|-------|----------------|--------|---------|----------------|-------|
| CRM_RAW_001 | 8 | 0 | 0 | 7 | 8 | 0 | 23 |
| CRM_AGG_001 | 0 | 8 | 10 | 0 | 0 | 0 | 18 |
| PAY_RAW_001 | 2 | 0 | 0 | 2 | 2 | 0 | 6 |
| PAY_AGG_001 | 0 | 0 | 6 | 0 | 0 | 0 | 6 |
| REF_RAW_001 | 1 | 0 | 0 | 1 | 1 | 0 | 3 |
| REF_AGG_001 | 0 | 0 | 1 | 0 | 0 | 0 | 1 |
| EQT_RAW_001 | 1 | 0 | 0 | 1 | 1 | 0 | 3 |
| EQT_AGG_001 | 0 | 0 | 3 | 0 | 0 | 0 | 3 |
| FII_RAW_001 | 1 | 0 | 0 | 1 | 1 | 0 | 3 |
| FII_AGG_001 | 0 | 0 | 5 | 0 | 0 | 0 | 5 |
| CMD_RAW_001 | 1 | 0 | 0 | 1 | 1 | 0 | 3 |
| CMD_AGG_001 | 0 | 0 | 5 | 0 | 0 | 0 | 5 |
| LOA_RAW_v001 | 2 | 0 | 0 | 2 | 2 | 0 | 6 |
| REP_AGG_001 | 0 | 0 | 28 | 0 | 0 | 2 | 30 |
| PUBLIC | 1 | 0 | 0 | 0 | 0 | 4 | 5 |
| **TOTAL** | **17** | **8** | **58** | **15** | **16** | **6** | **120** |

---

## 1. CRM_RAW_001 (Customer Relationship Management - Raw Layer)

> **✅ Naming Convention:** All RAW layer objects now follow complete naming pattern:
> - Tables: `*_RAW_TB_*` (e.g., `CRMI_RAW_TB_CUSTOMER`)
> - Stages: `*_RAW_STAGE_*` (e.g., `CRMI_RAW_STAGE_CUSTOMERS`)
> - Streams: `*_RAW_STREAM_*` (e.g., `CRMI_RAW_STREAM_CUSTOMER_FILES`)
> - Tasks: `*_RAW_TASK_*` (e.g., `CRMI_RAW_TASK_LOAD_CUSTOMERS`)

### Tables (8)
1. `CRMI_RAW_TB_CUSTOMER` - Customer master data
2. `CRMI_RAW_TB_ADDRESSES` - Customer addresses (SCD Type 2)
3. `CRMI_RAW_TB_CUSTOMER_EVENT` - Customer lifecycle events
4. `CRMI_RAW_TB_CUSTOMER_STATUS` - Customer status history
5. `CRMI_RAW_TB_EXPOSED_PERSON` - PEP (Politically Exposed Persons) data
6. `ACCI_RAW_TB_ACCOUNTS` - Account master data
7. `EMPI_RAW_TB_EMPLOYEE` - Employee master data
8. `EMPI_RAW_TB_CLIENT_ASSIGNMENT` - Client-advisor assignments (SCD Type 2)

### Stages (7)
1. `CRMI_RAW_STAGE_CUSTOMERS` - Customer CSV files
2. `CRMI_RAW_STAGE_ADDRESSES` - Address CSV files
3. `CRMI_RAW_STAGE_CUSTOMER_EVENTS` - Event CSV files
4. `CRMI_RAW_STAGE_EXPOSED_PERSON` - PEP CSV files
5. `ACCI_RAW_STAGE_ACCOUNTS` - Account CSV files
6. `EMPI_RAW_STAGE_EMPLOYEES` - Employee CSV files
7. `EMPI_RAW_STAGE_CLIENT_ASSIGNMENTS` - Assignment CSV files

### Streams (8)
1. `CRMI_RAW_STREAM_CUSTOMER_FILES` - Monitor customer uploads
2. `CRMI_RAW_STREAM_ADDRESS_FILES` - Monitor address uploads
3. `CRMI_RAW_STREAM_CUSTOMER_EVENT_FILES` - Monitor event uploads
4. `CRMI_RAW_STREAM_CUSTOMER_STATUS_FILES` - Monitor status uploads
5. `CRMI_RAW_STREAM_EXPOSED_PERSON_FILES` - Monitor PEP uploads
6. `ACCI_RAW_STREAM_ACCOUNT_FILES` - Monitor account uploads
7. `EMPI_RAW_STREAM_EMPLOYEE_FILES` - Monitor employee uploads
8. `EMPI_RAW_STREAM_ASSIGNMENT_FILES` - Monitor assignment uploads

---

## 2. CRM_AGG_001 (Customer Relationship Management - Aggregation Layer)

### Dynamic Tables (10)
1. `CRMA_AGG_DT_CUSTOMER_CURRENT` - Current customer records (SCD Type 2)
2. `CRMA_AGG_DT_CUSTOMER_HISTORY` - Historical customer changes
3. `CRMA_AGG_DT_ADDRESSES_CURRENT` - Current addresses (SCD Type 2)
4. `CRMA_AGG_DT_ADDRESSES_HISTORY` - Historical addresses
5. `CRMA_AGG_DT_CUSTOMER_LIFECYCLE` - Customer event aggregations
6. `CRMA_AGG_DT_CUSTOMER_360` - Comprehensive customer view with risk, transactions, balances
7. `ACCA_AGG_DT_ACCOUNTS` - Account aggregations
8. `EMPA_AGG_DT_ADVISOR_PERFORMANCE` - Advisor KPIs and performance metrics
9. `EMPA_AGG_DT_TEAM_LEADER_DASHBOARD` - Team leader rollup metrics
10. `EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR` - Portfolio aggregations by advisor

### Views (8)
1. `EMPA_AGG_VW_EMPLOYEE_HIERARCHY` - Recursive employee hierarchy (3 levels)
2. `EMPA_AGG_VW_ORGANIZATIONAL_CHART` - Org chart with manager details
3. `EMPA_AGG_VW_CURRENT_ASSIGNMENTS` - Current client-advisor assignments with customer context
4. `EMPA_AGG_VW_ASSIGNMENT_HISTORY` - Assignment history with SCD Type 2 support
5. `EMPA_AGG_VW_WORKLOAD_DISTRIBUTION` - Workload by country/region
6. `CRMA_AGG_VW_CUSTOMER_RISK_PROFILE` - Shared view: Customer risk segmentation
7. `CRMA_AGG_VW_SCREENING_STATUS` - Shared view: PEP/sanctions screening status
8. `CRMA_AGG_VW_SCREENING_ALERTS` - Shared view: Active screening alerts

---

## 3. PAY_RAW_001 (Payment Operations - Raw Layer)

### Tables (2)
1. `PAYI_RAW_TB_TRANSACTIONS` - Payment transactions
2. `ICGI_RAW_TB_SWIFT_MESSAGES` - SWIFT ISO20022 messages (XML)

### Stages (2)
1. `PAYI_RAW_STAGE_TRANSACTIONS` - Transaction CSV files
2. `ICGI_RAW_STAGE_SWIFT_INBOUND` - SWIFT XML files

### Streams (2)
1. `PAYI_RAW_STREAM_TRANSACTION_FILES` - Monitor transaction uploads
2. `ICGI_RAW_STREAM_SWIFT_FILES` - Monitor SWIFT uploads

---

## 4. PAY_AGG_001 (Payment Operations - Aggregation Layer)

### Dynamic Tables (6)
1. `PAYA_AGG_DT_TRANSACTION_ANOMALIES` - Anomaly detection (velocity, amount, time-of-day)
2. `PAYA_AGG_DT_ACCOUNT_BALANCES` - Account balance calculations
3. `PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY` - Customer-level transaction metrics
4. `ICGA_AGG_DT_SWIFT_PACS008` - SWIFT payment initiation messages
5. `ICGA_AGG_DT_SWIFT_PACS002` - SWIFT payment status messages
6. `ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE` - End-to-end payment tracking

---

## 5. REF_RAW_001 (Reference Data - Raw Layer)

### Tables (1)
1. `REFI_RAW_TB_FX_RATES` - FX rate reference data

### Stages (1)
1. `REFI_RAW_STAGE_FX_RATES` - FX rate CSV files

### Streams (1)
1. `REFI_RAW_STREAM_FX_RATE_FILES` - Monitor FX rate uploads

---

## 6. REF_AGG_001 (Reference Data - Aggregation Layer)

### Dynamic Tables (1)
1. `REFA_AGG_DT_FX_RATES_ENHANCED` - FX rates with spreads and analytics

---

## 7. EQT_RAW_001 (Equity Trading - Raw Layer)

### Tables (1)
1. `EQTI_RAW_TB_TRADES` - Equity trade data

### Stages (1)
1. `EQTI_RAW_STAGE_TRADES` - Trade CSV files

### Streams (1)
1. `EQTI_RAW_STREAM_TRADES_FILES` - Monitor trade uploads

---

## 8. EQT_AGG_001 (Equity Trading - Aggregation Layer)

### Dynamic Tables (3)
1. `EQTA_AGG_DT_TRADE_SUMMARY` - Daily trade summaries
2. `EQTA_AGG_DT_PORTFOLIO_POSITIONS` - Current positions
3. `EQTA_AGG_DT_CUSTOMER_ACTIVITY` - Customer trading activity

---

## 9. FII_RAW_001 (Fixed Income - Raw Layer)

### Tables (1)
1. `FIII_RAW_TB_TRADES` - Fixed income trade data

### Stages (1)
1. `FIII_RAW_STAGE_TRADES` - Trade CSV files

### Streams (1)
1. `FIII_RAW_TB_TRADES_STREAM` - Monitor trade uploads

---

## 10. FII_AGG_001 (Fixed Income - Aggregation Layer)

### Dynamic Tables (5)
1. `FIIA_AGG_DT_TRADE_SUMMARY` - Daily trade summaries
2. `FIIA_AGG_DT_PORTFOLIO_POSITIONS` - Current bond positions
3. `FIIA_AGG_DT_DURATION_ANALYSIS` - Duration and convexity
4. `FIIA_AGG_DT_YIELD_CURVE` - Yield curve analytics
5. `FIIA_AGG_DT_CREDIT_EXPOSURE` - Credit risk exposure

---

## 11. CMD_RAW_001 (Commodities - Raw Layer)

### Tables (1)
1. `CMDI_RAW_TB_TRADES` - Commodity trade data

### Stages (1)
1. `CMDI_RAW_STAGE_TRADES` - Trade CSV files

### Streams (1)
1. `CMDI_RAW_TB_TRADES_STREAM` - Monitor trade uploads

---

## 12. CMD_AGG_001 (Commodities - Aggregation Layer)

### Dynamic Tables (5)
1. `CMDA_AGG_DT_TRADE_SUMMARY` - Daily trade summaries
2. `CMDA_AGG_DT_PORTFOLIO_POSITIONS` - Current commodity positions
3. `CMDA_AGG_DT_DELTA_EXPOSURE` - Delta exposure by commodity type
4. `CMDA_AGG_DT_DELIVERY_SCHEDULE` - Physical delivery schedule
5. `CMDA_AGG_DT_VOLATILITY_ANALYSIS` - Price volatility analytics

---

## 13. LOA_RAW_v001 (Loan Operations - Raw Layer)

### Tables (2)
1. `LOAI_RAW_TB_EMAILS` - Email documents (TXT)
2. `LOAI_RAW_TB_DOCUMENTS` - PDF documents

### Stages (2)
1. `LOAI_RAW_STAGE_EMAIL_INBOUND` - Email files
2. `LOAI_RAW_STAGE_PDF_INBOUND` - PDF files

### Streams (2)
1. `LOAI_RAW_STREAM_EMAIL_FILES` - Monitor email uploads
2. `LOAI_RAW_STREAM_PDF_FILES` - Monitor PDF uploads

---

## 14. REP_AGG_001 (Reporting - Aggregation Layer)

### Dynamic Tables (28)

#### Core Reporting (3)
1. `REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY` - Daily transaction metrics
2. `REPP_AGG_DT_ANOMALY_ANALYSIS` - Cross-domain anomaly detection
3. `REPP_AGG_DT_LIFECYCLE_ANOMALIES` - Payment lifecycle anomalies

#### Equity Reporting (4)
4. `REPP_AGG_DT_EQUITY_SUMMARY` - Equity position summaries
5. `REPP_AGG_DT_EQUITY_POSITIONS` - Detailed equity positions
6. `REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES` - High-value trade monitoring
7. `REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE` - Currency exposure from equity

#### Credit Risk (IRB - Internal Ratings Based) (6)
8. `REPP_AGG_DT_CUSTOMER_SUMMARY` - Customer risk summary
9. `REPP_AGG_DT_CUSTOMER_RATING_HISTORY` - Rating migration history
10. `REPP_AGG_DT_IRB_CUSTOMER_RATINGS` - IRB customer ratings (PD, LGD, EAD)
11. `REPP_AGG_DT_IRB_PORTFOLIO_METRICS` - Portfolio-level IRB metrics
12. `REPP_AGG_DT_IRB_RWA_SUMMARY` - Risk-Weighted Assets calculation
13. `REPP_AGG_DT_IRB_RISK_TRENDS` - Risk trend analysis

#### FRTB (Fundamental Review of the Trading Book) (5)
14. `REPP_AGG_DT_FRTB_RISK_POSITIONS` - FRTB risk positions by bucket
15. `REPP_AGG_DT_FRTB_SENSITIVITIES` - Delta sensitivities
16. `REPP_AGG_DT_FRTB_CAPITAL_CHARGES` - SA-TB capital requirements
17. `REPP_AGG_DT_FRTB_NMRF_ANALYSIS` - Non-Modellable Risk Factors
18. `REPP_AGG_DT_SETTLEMENT_ANALYSIS` - Settlement risk

#### BCBS 239 (Risk Data Aggregation) (7)
19. `REPP_AGG_DT_BCBS239_RISK_AGGREGATION` - Cross-domain risk aggregation
20. `REPP_AGG_DT_BCBS239_RISK_CONCENTRATION` - Risk concentration by dimension
21. `REPP_AGG_DT_BCBS239_RISK_LIMITS` - Risk limit monitoring
22. `REPP_AGG_DT_BCBS239_DATA_QUALITY` - Data quality metrics
23. `REPP_AGG_DT_BCBS239_REGULATORY_REPORTING` - Regulatory reporting readiness
24. `REPP_AGG_DT_BCBS239_EXECUTIVE_DASHBOARD` - Executive summary
25. `REPP_AGG_DT_HIGH_RISK_PATTERNS` - High-risk pattern detection

#### Currency & Portfolio (3)
26. `REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT` - Current currency exposure
27. `REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY` - Historical currency exposure
28. `REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE` - Settlement currency risk
29. `REPP_AGG_DT_PORTFOLIO_PERFORMANCE` - Multi-asset portfolio performance

### Semantic Views (2)
1. `REPP_SEMANTIC_VIEW` - Cortex AI semantic view for reporting
2. `FRTB_MARKET_RISK_REPORTING` - FRTB semantic view for Cortex AI

---

## 15. PUBLIC (Shared/Reference Schema)

### Tables (1)
1. `SANCTIONS_TB_DATA_STAGING` - Sanctions reference data (from shared database)

### Semantic Views (4)
1. `CRMA_SEMANTIC_VIEW` - Customer 360 semantic view for Cortex AI
2. `CRM_COMPLIANCE_RISK_VIEW` - Compliance risk semantic view
3. `CRM_LIFECYCLE_VIEW` - Customer lifecycle semantic view
4. `CRM_ADDRESS_INTELLIGENCE_VIEW` - Address intelligence semantic view

---

## Object Type Summary

### Tables (17)
Raw data ingestion layer - populated via Snowflake COPY INTO commands from stages.

| Domain | Schema | Count |
|--------|--------|-------|
| Customer/Employee | CRM_RAW_001 | 8 |
| Payment | PAY_RAW_001 | 2 |
| Reference | REF_RAW_001 | 1 |
| Equity | EQT_RAW_001 | 1 |
| Fixed Income | FII_RAW_001 | 1 |
| Commodities | CMD_RAW_001 | 1 |
| Loans | LOA_RAW_v001 | 2 |
| Sanctions | PUBLIC | 1 |

### Views (8)
Real-time analytical views - used for complex queries, recursive hierarchies, and shared analytics.

| Domain | Schema | Count |
|--------|--------|-------|
| Employee Analytics | CRM_AGG_001 | 5 |
| Customer Risk | CRM_AGG_001 | 3 |

### Dynamic Tables (58)
Auto-refreshing aggregation layer - optimized for analytical queries and dashboards.

| Domain | Schema | Count |
|--------|--------|-------|
| Customer/Employee | CRM_AGG_001 | 10 |
| Payment | PAY_AGG_001 | 6 |
| Reference | REF_AGG_001 | 1 |
| Equity | EQT_AGG_001 | 3 |
| Fixed Income | FII_AGG_001 | 5 |
| Commodities | CMD_AGG_001 | 5 |
| Reporting | REP_AGG_001 | 28 |

### Stages (15)
Internal stages for CSV/XML file uploads.

### Streams (16)
Change data capture on stages - trigger Snowflake tasks for automated loading.

### Semantic Views (6)
Cortex AI integration - enable natural language querying via Cortex Analyst.

---

## Naming Conventions

> **⚠️ Current State vs. Target State**  
> **Current:** Raw tables use `*I_*` suffix only (e.g., `CRMI_RAW_TB_CUSTOMER`)  
> **Target:** Raw tables should include `_RAW_` (e.g., `CRMI_RAW_TB_CUSTOMER`)  
> **Status:** Migration planned - see `NAMING_CONVENTION_ANALYSIS.md`

### Current Prefixes by Layer
- **`*I_*`** - Ingest layer (raw tables, stages, streams)
  - Example: `CRMI_RAW_TB_CUSTOMER`, `PAYI_RAW_TB_TRANSACTIONS`
  - ⚠️ **Inconsistent:** Missing explicit `_RAW_` identifier
- **`*A_*`** - Aggregation layer (dynamic tables)
  - Example: `CRMA_AGG_DT_CUSTOMER_360`
  - ✅ **Consistent:** Always includes `_AGG_DT_` or `_AGG_VW_`
- **`*_VW_*`** - Views
- **`*_AGG_VW_*`** - Aggregation layer views
- **`*_AGG_DT_*`** - Aggregation layer dynamic tables

### Target Naming Pattern (Post-Migration)
- **`*I_RAW_*`** - Raw layer tables (e.g., `CRMI_RAW_TB_CUSTOMER`, `PAYI_RAW_TB_TRANSACTIONS`)
- **`*A_AGG_DT_*`** - Aggregation layer dynamic tables (e.g., `CRMA_AGG_DT_CUSTOMER_360`)
- **`*A_AGG_VW_*`** - Aggregation layer views (e.g., `CRMA_AGG_VW_CUSTOMER_RISK_PROFILE`)

### Domain Prefixes
- **`CRM*`** - Customer Relationship Management
- **`ACC*`** - Accounts
- **`EMP*`** - Employees
- **`PAY*`** - Payment Operations
- **`ICG*`** - Interbank Communication Gateway (SWIFT)
- **`REF*`** - Reference Data
- **`EQT*`** - Equity Trading
- **`FII*`** - Fixed Income
- **`CMD*`** - Commodities
- **`LOA*`** - Loan Operations
- **`REP*`** - Reporting
- **`SANC*`** - Sanctions

---

## Architecture Layers

### 1. RAW Layer (*_RAW_*)
- **Purpose:** Immutable source-of-truth data
- **Loading:** Automated via Snowflake tasks + streams
- **Object Types:** Tables, Stages, Streams
- **Schemas:** CRM_RAW_001, PAY_RAW_001, REF_RAW_001, EQT_RAW_001, FII_RAW_001, CMD_RAW_001, LOA_RAW_v001

### 2. AGG Layer (*_AGG_*)
- **Purpose:** Business logic, transformations, aggregations
- **Refresh:** Automatic via dynamic tables (lag: 5-60 minutes)
- **Object Types:** Dynamic Tables, Views
- **Schemas:** CRM_AGG_001, PAY_AGG_001, REF_AGG_001, EQT_AGG_001, FII_AGG_001, CMD_AGG_001, REP_AGG_001

### 3. Semantic Layer (PUBLIC)
- **Purpose:** Natural language querying via Cortex AI
- **Object Types:** Semantic Views
- **Integration:** Snowflake Cortex Analyst

---

## Deployment Order

Objects are deployed in the following order (controlled by filename prefix):

1. **000-009:** Database setup, reference data
2. **010-099:** RAW layer tables, stages, streams, tasks
3. **300-399:** AGG layer dynamic tables (single-domain)
4. **400-499:** AGG layer dynamic tables (cross-domain)
5. **500-699:** Reporting dynamic tables
6. **700-799:** Semantic views and AI agents

---

## Related Documentation

- **Deployment Guide:** `structure/README_DEPLOYMENT.md`
- **Upload Script:** `upload-data.sh` (with parallel upload support)
- **Task Execution:** `operation/execute_all_tasks_and_refresh_dts.sql`
- **Data Generation:** `README.md` (section: Data Generation)

---

**Last Updated:** 2025-12-31  
**Database:** AAA_DEV_SYNTHETIC_BANK  
**Environment:** Development

