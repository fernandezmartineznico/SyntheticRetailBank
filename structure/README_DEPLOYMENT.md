# Snowflake DDL Deployment Guide

This directory holds the complete DDL (in Snowflake syntax) for the **Synthetic Retail Bank** data model.

> **Purpose**: Technical deployment instructions, file order, and configuration details.  
> **For architecture**: See [../SYSTEM_ARCHITECTURE.md](../SYSTEM_ARCHITECTURE.md)  
> **For semantic views**: See [../SEMANTIC_VIEWS_QUICK_REFERENCE.md](../SEMANTIC_VIEWS_QUICK_REFERENCE.md)

---

## Quick Deployment

### Automated Deployment (Recommended)

```bash
# From project root
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>
```

**What it does**:
1. Executes all SQL files in numerical order
2. Deploys 8 Snowflake notebooks
3. Uploads generated data to stages
4. Activates automated processing (tasks + dynamic tables)

**Prerequisites**:
- Snowflake CLI installed (`snow` command available)
- Data generated (run `./data_generator.sh` first)
- Valid Snowflake connection configured

---

## File Structure

```
structure/
├─ 000_database_setup.sql           # Database and warehouse creation
├─ 001_get_listings.sql             # Snowflake Data Exchange: Sanctions Data
├─ 002_SANC_sanction_data.sql       # Sanctions data integration
├─ 010_CRMI_customer_master.sql     # CRM Raw: Customer, Address, PEP, Events
├─ 011_ACCI_accounts.sql            # CRM Raw: Account Master Data
├─ 015_EMPI_employees.sql           # CRM Raw: Employee & Client Assignments
├─ 020_REFI_fx_rates.sql            # REF Raw: FX Rates
├─ 030_PAYI_transactions.sql        # PAY Raw: Payment Transactions
├─ 035_ICGI_swift_messages.sql      # PAY Raw: SWIFT ISO20022 Messages
├─ 040_EQTI_equity_trades.sql       # EQT Raw: Equity Trading
├─ 050_FIII_fixed_income.sql        # FII Raw: Fixed Income Trading
├─ 055_CMDI_commodities.sql         # CMD Raw: Commodity Trading
├─ 060_LOAI_loans_documents.sql     # LOA Raw: Loan & Document Processing
├─ 311_ACCA_accounts_agg.sql        # CRM Agg: Account Aggregation
├─ 312_CRMA_LIFECYCLE.sql           # CRM Agg: Lifecycle & Churn Prediction
├─ 320_REFA_fx_analytics.sql        # REF Agg: FX Analytics & Volatility
├─ 330_PAYA_anomaly_detection.sql   # PAY Agg: Anomaly Detection & Balances
├─ 335_ICGA_swift_lifecycle.sql     # PAY Agg: SWIFT Message Aggregation
├─ 340_EQTA_equity_analytics.sql    # EQT Agg: Equity Trading Analytics
├─ 350_FIIA_fixed_income_analytics.sql # FII Agg: FI Analytics & Risk Metrics
├─ 355_CMDA_commodity_analytics.sql # CMD Agg: Commodity Analytics & Delta Risk
├─ 410_CRMA_customer_360.sql        # CRM Agg: Customer 360° with Balances/Txns
├─ 415_EMPA_employee_analytics.sql  # CRM Agg: Employee Analytics & Hierarchy
├─ 500_REPP_core_reporting.sql      # REP Agg: Core Reporting & Analytics
├─ 510_REPP_equity_reporting.sql    # REP Agg: Equity Trading Reporting
├─ 520_REPP_credit_risk.sql         # REP Agg: Credit Risk & IRB Reporting
├─ 525_REPP_frtb_market_risk.sql    # REP Agg: FRTB Market Risk Capital
├─ 540_REPP_bcbs239_compliance.sql  # REP Agg: BCBS 239 Risk Data Aggregation
├─ 600_REPP_portfolio_performance.sql # REP Agg: Portfolio Performance & TWR
├─ 710_CRMA_SV_CUSTOMER_360.sql     # Semantic: Customer 360° View
├─ 715_EMPA_SV_EMPLOYEE_ADVISOR.sql # Semantic: Employee/Advisor View
├─ 720_PAYA_SV_COMPLIANCE_MONITORING.sql # Semantic: AML Monitoring View
├─ 730_REPA_SV_WEALTH_MANAGEMENT.sql # Semantic: Wealth Management View
├─ 740_REPA_SV_RISK_REPORTING.sql   # Semantic: Risk Reporting View
├─ 810_CRM_INTELLIGENCE_AGENT.sql   # AI Agent: CRM Customer 360
├─ 811_COMPLIANCE_MONITORING_AGENT.sql # AI Agent: Compliance Monitoring
├─ 830_WEALTH_ADVISOR_AGENT.sql     # AI Agent: Wealth Advisor
└─ 850_RISK_REGULATORY_AGENT.sql    # AI Agent: Risk & Regulatory
```

---

## Deployment Order

**⚠️ CRITICAL: Execute files in the EXACT order listed below.**

### Phase 1: Database Setup (0xx)

| File | Objects Created | Purpose |
|------|-----------------|---------|
| **000_database_setup.sql** | Database, Warehouse, Schemas | Foundation |
| **001_get_listings.sql** | External sanctions database (optional) | Compliance data |
| **002_SANC_sanction_data.sql** | Sanctions integration (optional) | PEP screening |

### Phase 2: Raw Layer - Data Ingestion (01x-06x)

| File | Schema | Objects | Purpose |
|------|--------|---------|---------|
| **010_CRMI_customer_master.sql** | CRM_RAW_001 | 5 tables, 4 stages, 5 tasks | Customer, Address, PEP, Events |
| **011_ACCI_accounts.sql** | CRM_RAW_001 | 1 table, 1 stage, 1 task | Account master data |
| **015_EMPI_employees.sql** | CRM_RAW_001 | 2 tables, 2 stages, 2 tasks | Employee hierarchy, assignments |
| **020_REFI_fx_rates.sql** | REF_RAW_001 | 1 table, 1 stage, 1 task | FX rates |
| **030_PAYI_transactions.sql** | PAY_RAW_001 | 1 table, 1 stage, 1 task | Payment transactions |
| **035_ICGI_swift_messages.sql** | PAY_RAW_001 | 1 table, 1 stage, 1 task | SWIFT messages |
| **040_EQTI_equity_trades.sql** | EQT_RAW_001 | 1 table, 1 stage, 1 task | Equity trades |
| **050_FIII_fixed_income.sql** | FII_RAW_001 | 1 table, 1 stage, 1 task | Bonds, swaps |
| **055_CMDI_commodities.sql** | CMD_RAW_001 | 1 table, 1 stage, 1 task | Commodity trades |
| **060_LOAI_loans_documents.sql** | LOA_RAW_001 | 2 tables, 2 stages, 2 tasks | Loans, documents |

**Total Raw Layer**: 16 tables, 16 stages, 16 serverless tasks

### Phase 3: Aggregation Layer - Business Logic (3xx-4xx)

**⚠️ CRITICAL SEQUENCE FOR CUSTOMER 360:**

1. **311_ACCA_accounts_agg.sql** → Creates `ACCA_AGG_DT_ACCOUNTS`
2. **330_PAYA_anomaly_detection.sql** → Creates `PAYA_AGG_DT_ACCOUNT_BALANCES` + `PAYA_AGG_DT_TRANSACTION_ANOMALIES`
3. **410_CRMA_customer_360.sql** → Creates `CRMA_AGG_DT_CUSTOMER_360` (depends on #1 and #2)
4. **415_EMPA_employee_analytics.sql** → Creates `EMPA_AGG_DT_ADVISOR_PERFORMANCE` (depends on #3)

| File | Schema | Key Objects | Dependencies |
|------|--------|-------------|--------------|
| **311_ACCA_accounts_agg.sql** | CRM_AGG_001 | `ACCA_AGG_DT_ACCOUNTS` | Raw accounts |
| **312_CRMA_LIFECYCLE.sql** | CRM_AGG_001 | Lifecycle dynamic tables | Raw customer, events, status |
| **320_REFA_fx_analytics.sql** | REF_AGG_001 | `REFA_AGG_DT_FX_RATES_ENHANCED` | Raw FX rates |
| **330_PAYA_anomaly_detection.sql** | PAY_AGG_001 | `PAYA_AGG_DT_TRANSACTION_ANOMALIES`, `PAYA_AGG_DT_ACCOUNT_BALANCES` | Raw transactions, accounts |
| **335_ICGA_swift_lifecycle.sql** | PAY_AGG_001 | SWIFT aggregation | Raw SWIFT messages |
| **340_EQTA_equity_analytics.sql** | EQT_AGG_001 | Equity portfolio positions | Raw equity trades |
| **350_FIIA_fixed_income_analytics.sql** | FII_AGG_001 | Duration, yield curve | Raw FI trades |
| **355_CMDA_commodity_analytics.sql** | CMD_AGG_001 | Delta exposure, volatility | Raw commodity trades |
| **410_CRMA_customer_360.sql** | CRM_AGG_001 | `CRMA_AGG_DT_CUSTOMER_360` | **Requires 311 + 330** |
| **415_EMPA_employee_analytics.sql** | CRM_AGG_001 | `EMPA_AGG_DT_ADVISOR_PERFORMANCE` | **Requires 410** |

**Total Aggregation Layer**: ~40 dynamic tables

### Phase 4: Reporting Layer - Cross-Domain Analytics (5xx-6xx)

| File | Schema | Purpose | Key Tables |
|------|--------|---------|------------|
| **500_REPP_core_reporting.sql** | REP_AGG_001 | Core analytics | 10 dynamic tables (customer summary, FX exposure, anomalies) |
| **510_REPP_equity_reporting.sql** | REP_AGG_001 | Equity trading | 4 dynamic tables (equity summary, positions, currency exposure) |
| **520_REPP_credit_risk.sql** | REP_AGG_001 | Basel III/IV IRB | 5 dynamic tables (IRB ratings, RWA, rating history) |
| **525_REPP_frtb_market_risk.sql** | REP_AGG_001 | FRTB market risk | 4 dynamic tables (risk positions, sensitivities, capital charges) |
| **540_REPP_bcbs239_compliance.sql** | REP_AGG_001 | BCBS 239 | 6 dynamic tables (risk aggregation, data quality) |
| **600_REPP_portfolio_performance.sql** | REP_AGG_001 | Portfolio performance | 1 dynamic table (TWR, Sharpe ratio, asset allocation) |

**Total Reporting Layer**: ~30 dynamic tables

### Phase 5: Semantic Layer - AI Interface (7xx)

| File | Schema | Purpose | Views Created |
|------|--------|---------|---------------|
| **710_CRMA_SV_CUSTOMER_360.sql** | CRM_AGG_001 | Customer 360° semantic view | 1 view (48 attrs consolidated) |
| **715_EMPA_SV_EMPLOYEE_ADVISOR.sql** | CRM_AGG_001 | Advisor performance | 1 view |
| **720_PAYA_SV_COMPLIANCE_MONITORING.sql** | PAY_AGG_001 | AML monitoring | 3 views (1 semantic + 1 detailed + 1 alias) |
| **730_REPA_SV_WEALTH_MANAGEMENT.sql** | REP_AGG_001 | Wealth management | 1 view (61 attrs) |
| **740_REPA_SV_RISK_REPORTING.sql** | REP_AGG_001 | Risk reporting | 1 view (cross-domain) |

**Total Semantic Layer**: 5 consolidated views (AI-ready)

### Phase 6: AI Agents (8xx) - Optional

| File | Schema | Purpose | Agent Name |
|------|--------|---------|------------|
| **810_CRM_INTELLIGENCE_AGENT.sql** | CRM_AGG_001 | Customer 360 AI agent | CRM_Customer_360 |
| **811_COMPLIANCE_MONITORING_AGENT.sql** | PAY_AGG_001 | AML/compliance AI agent | COMPLIANCE_MONITORING_AGENT |
| **830_WEALTH_ADVISOR_AGENT.sql** | REP_AGG_001 | Wealth advisor AI agent | WEALTH_ADVISOR_AGENT |
| **850_RISK_REGULATORY_AGENT.sql** | REP_AGG_001 | Risk/regulatory AI agent | RISK_REGULATORY_AGENT |

---

## Configuration

### Warehouse Settings

**All tasks and dynamic tables use**: `MD_TEST_WH`

To change warehouse, search and replace across all files:
```bash
# From structure/ directory
sed -i '' 's/MD_TEST_WH/YOUR_WAREHOUSE_NAME/g' *.sql
```

### Refresh Strategy

| Layer | Refresh Method | Frequency | Purpose |
|-------|----------------|-----------|---------|
| **Raw Layer** | Stream-triggered tasks | On file arrival | Real-time ingestion |
| **Aggregation Layer** | Dynamic tables | 60-minute TARGET_LAG | Near-real-time |
| **Reporting Layer** | Dynamic tables | 60-minute TARGET_LAG | Consistent snapshots |
| **Semantic Layer** | Views | Instant (query-time) | Real-time access |

### Error Handling

- **Tasks**: `ON_ERROR = CONTINUE` for resilient processing
- **Pattern Matching**: Specific file patterns for each data type (e.g., `*pay_transactions*.csv`)
- **Logging**: Built-in Snowflake task logging

---

## Object Naming Standards

### Consistent Naming Convention

**Schema Pattern**: `{DOMAIN}_{LAYER}_{VERSION}`
- Example: `CRM_RAW_001`, `PAY_AGG_001`, `REP_AGG_001`

**Object Pattern**: `{DOMAIN}{LAYER}_[TYPE]_{NAME}`
- `CRMI_RAW_TB_CUSTOMER` = CRM **I**ngestion, **RAW** layer, **T**a**B**le, Customer
- `CRMA_AGG_DT_CUSTOMER_360` = CRM **A**ggregation, **AGG** layer, **D**ynamic **T**able, Customer 360
- `CRMI_RAW_STAGE_CUSTOMERS` = CRM Ingestion, Stage, Customers
- `CRMI_RAW_TASK_LOAD_CUSTOMERS` = CRM Ingestion, Task, Load Customers

**Layer Codes**:
- **I** = Ingestion (RAW layer)
- **A** = Aggregation (AGG layer)
- **P** = Processing/Reporting (REP layer)

**Object Type Codes**:
- **TB** = Table (raw tables)
- **DT** = Dynamic Table (aggregation/reporting)
- **VW** = View
- **SV** = Semantic View (AI layer)
- **STAGE** = Internal stage
- **TASK** = Serverless task
- **STREAM** = Change data capture stream
- **FF** = File Format

### Domain Prefixes

| Prefix | Domain | Layer | Example |
|--------|--------|-------|---------|
| **CRMI** | Customer Master | Ingestion (RAW) | `CRMI_RAW_TB_CUSTOMER` |
| **CRMA** | Customer Master | Aggregation (AGG) | `CRMA_AGG_DT_CUSTOMER_360` |
| **ACCI** | Accounts | Ingestion (RAW) | `ACCI_RAW_TB_ACCOUNTS` |
| **ACCA** | Accounts | Aggregation (AGG) | `ACCA_AGG_DT_ACCOUNTS` |
| **EMPI** | Employees | Ingestion (RAW) | `EMPI_RAW_TB_EMPLOYEE` |
| **EMPA** | Employees | Aggregation (AGG) | `EMPA_AGG_DT_ADVISOR_PERFORMANCE` |
| **PAYI** | Payments | Ingestion (RAW) | `PAYI_RAW_TB_TRANSACTIONS` |
| **PAYA** | Payments | Aggregation (AGG) | `PAYA_AGG_DT_TRANSACTION_ANOMALIES` |
| **EQTI** | Equity Trading | Ingestion (RAW) | `EQTI_RAW_TB_TRADES` |
| **EQTA** | Equity Trading | Aggregation (AGG) | `EQTA_AGG_DT_PORTFOLIO_POSITIONS` |
| **FIII** | Fixed Income | Ingestion (RAW) | `FIII_RAW_TB_TRADES` |
| **FIIA** | Fixed Income | Aggregation (AGG) | `FIIA_AGG_DT_YIELD_CURVE` |
| **CMDI** | Commodities | Ingestion (RAW) | `CMDI_RAW_TB_TRADES` |
| **CMDA** | Commodities | Aggregation (AGG) | `CMDA_AGG_DT_DELTA_EXPOSURE` |
| **REFI** | Reference Data | Ingestion (RAW) | `REFI_RAW_TB_FX_RATES` |
| **REFA** | Reference Data | Aggregation (AGG) | `REFA_AGG_DT_FX_RATES_ENHANCED` |
| **ICGI** | SWIFT Messages | Ingestion (RAW) | `ICGI_RAW_TB_SWIFT_MESSAGES` |
| **ICGA** | SWIFT Messages | Aggregation (AGG) | `ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE` |
| **REPP** | Reporting | Processing (REP) | `REPP_AGG_DT_PORTFOLIO_PERFORMANCE` |

---

## Data Loading

### Automated Upload Process

```bash
# From project root
./upload-data.sh --CONNECTION_NAME=<my-sf-connection>

# With options for large datasets
./upload-data.sh --CONNECTION_NAME=<my-sf-connection> \
  --BATCH_SIZE=100 \
  --MAX_RETRIES=5 \
  --PARALLEL_THREADS=4
```

**Features**:
- Uploads all generated data to appropriate stages
- Progress tracking and error handling
- Automatic stage detection
- Parallel upload support

### Manual Upload (per stage)

```sql
-- Example: Upload customer data
PUT file:///path/to/customers.csv @CRM_RAW_001.CRMI_RAW_STAGE_CUSTOMERS AUTO_COMPRESS=TRUE;

-- Example: Upload transactions
PUT file:///path/to/pay_transactions_*.csv @PAY_RAW_001.PAYI_RAW_STAGE_TRANSACTIONS AUTO_COMPRESS=TRUE;
```

### Automated Processing

1. **Streams detect** new files automatically
2. **Tasks process** files within 1 hour (or immediately if stream-triggered)
3. **Dynamic tables refresh** according to TARGET_LAG (60 minutes)
4. **Data flows** through the complete pipeline: RAW → AGG → REP → Semantic

---

## Schema Architecture

### RAW LAYER (Data Ingestion)

| Schema | Purpose | Key Objects | Refresh Strategy |
|--------|---------|-------------|------------------|
| `CRM_RAW_001` | Customer, Lifecycle, Employees | 8 tables, 8 stages, 8 tasks | Stream-triggered serverless tasks |
| `REF_RAW_001` | Reference Data | 1 table, 1 stage, 1 task | Stream-triggered tasks |
| `PAY_RAW_001` | Payments, SWIFT | 2 tables, 2 stages, 2 tasks | Stream-triggered tasks |
| `EQT_RAW_001` | Equity Trading | 1 table, 1 stage, 1 task | Stream-triggered tasks |
| `FII_RAW_001` | Fixed Income | 1 table, 1 stage, 1 task | Serverless tasks (60 min) |
| `CMD_RAW_001` | Commodities | 1 table, 1 stage, 1 task | Serverless tasks (60 min) |
| `LOA_RAW_001` | Loans, Documents | 2 tables, 2 stages, 2 tasks | Stream-triggered tasks |

### AGGREGATION LAYER (Business Logic)

| Schema | Purpose | Key Objects | Refresh Strategy |
|--------|---------|-------------|------------------|
| `CRM_AGG_001` | Customer Analytics, Lifecycle, Employee Performance | 12+ dynamic tables, 5 views | 60-min dynamic tables + real-time views |
| `REF_AGG_001` | Reference Analytics | 1 dynamic table | 1-hour dynamic tables |
| `PAY_AGG_001` | Payment Analytics | 3 dynamic tables | 1-hour dynamic tables |
| `EQT_AGG_001` | Equity Trading Analytics | 3 dynamic tables | 1-hour dynamic tables |
| `FII_AGG_001` | Fixed Income Analytics | 5 dynamic tables | 1-hour dynamic tables |
| `CMD_AGG_001` | Commodity Analytics | 5 dynamic tables | 1-hour dynamic tables |
| `REP_AGG_001` | Reporting & FRTB & BCBS239 | 30+ dynamic tables | 1-hour dynamic tables |

---

## Advanced Features

### Multi-Currency Support
- **Customer Reporting Currencies**: Country-based currency assignment (EUR, GBP, NOK, SEK, DKK, PLN)
- **FX Rate Integration**: Real-time currency conversion using `REF_RAW_001.REFI_RAW_TB_FX_RATES`
- **Dynamic Base Currency**: Automatic detection from transaction data
- **Account Balance Conversion**: Real-time FX conversion for account currency display

### SCD Type 2 Dimensional Management

**Customer Attributes** (employment, account tier, risk profile):
```
CRMI_RAW_TB_CUSTOMER (base - append-only)
  ↓
CRMA_AGG_DT_CUSTOMER_CURRENT (operational - latest only)
  ↓
CRMA_AGG_DT_CUSTOMER_HISTORY (analytical - full history)
```

**Customer Addresses**:
```
CRMI_RAW_TB_ADDRESSES (base - append-only)
  ↓
CRMA_AGG_DT_ADDRESSES_CURRENT (operational - latest only)
  ↓
CRMA_AGG_DT_ADDRESSES_HISTORY (analytical - full history)
```

### Payment Anomaly Detection
- **Behavioral Analysis**: Multi-dimensional customer behavior profiling
- **Statistical Scoring**: Z-scores for amount, timing, and velocity anomalies
- **Risk Classification**: CRITICAL, HIGH, MODERATE, NORMAL classifications
- **Operational Alerting**: Immediate review and enhanced monitoring flags

### Customer 360° View with Financial Metrics
- **Comprehensive Data**: Integrates all customer dimensions (attributes, address, lifecycle, accounts, balances, transactions, PEP/sanctions)
- **Balance Metrics**: Total balance (AUM), account type balances, min/max/avg balances
- **Transaction Metrics**: Transaction counts, activity levels, dormancy flags, engagement scores
- **Fuzzy Matching**: `EDITDISTANCE` functions for PEP and sanctions screening
- **Risk Assessment**: Combined PEP, sanctions, and anomaly risk scoring
- **Performance**: 60-minute refresh for consistent snapshots

---

## Troubleshooting

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| **Stream has no data** | Files not uploaded or stage is empty | Re-upload: `./upload-data.sh` |
| **Task not triggering** | Stream hasn't detected files yet | Wait 1 minute or manually refresh: `ALTER STREAM <name> REFRESH;` |
| **Dynamic table lag** | Warehouse suspended or under-resourced | Resume warehouse: `ALTER WAREHOUSE MD_TEST_WH RESUME;` |
| **Foreign key violation** | Deployment order incorrect | Drop and redeploy in correct order |
| **Object already exists** | Previous deployment not cleaned | Drop schema/database and redeploy |

### Validation Queries

```sql
-- Check raw data counts
SELECT 'CUSTOMERS' as TABLE_NAME, COUNT(*) as COUNT FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER
UNION ALL
SELECT 'ACCOUNTS', COUNT(*) FROM CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS
UNION ALL
SELECT 'TRANSACTIONS', COUNT(*) FROM PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS
UNION ALL
SELECT 'EQUITY_TRADES', COUNT(*) FROM EQT_RAW_001.EQTI_RAW_TB_TRADES;

-- Check dynamic table refresh status
SHOW DYNAMIC TABLES IN SCHEMA CRM_AGG_001;
SHOW DYNAMIC TABLES IN SCHEMA PAY_AGG_001;
SHOW DYNAMIC TABLES IN SCHEMA REP_AGG_001;

-- Check task execution history
SELECT 
    NAME,
    STATE,
    COMPLETED_TIME,
    ERROR_CODE,
    ERROR_MESSAGE
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE SCHEMA_NAME = 'CRM_RAW_001'
ORDER BY COMPLETED_TIME DESC
LIMIT 10;
```

---

**Document Version**: 2.0  
**Last Updated**: January 2026  
**Maintained By**: Data Engineering Team  
**Next Review**: Q2 2026

