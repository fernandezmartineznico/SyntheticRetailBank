# Synthetic Retail Bank

A comprehensive synthetic banking environment demonstrating modern risk management, governance, and compliance challenges faced by EMEA financial institutions. Features end-to-end data generation, regulatory reporting, and interactive analytics for AML, credit risk, market risk, and wealth management.

---

## What This Platform Delivers

| Domain | Purpose | Key Value |
|--------|---------|-----------|
| **Financial Crime Prevention** | AML/CTF compliance, PEP screening, sanctions monitoring | Prevent financial crime, avoid regulatory fines, demonstrate control effectiveness |
| **Credit & Capital Management** | Basel III/IV IRB approach, RWA calculation, portfolio risk | Ensure regulatory capital adequacy and financial stability |
| **Market Risk (FRTB)** | Multi-asset trading book risk, sensitivities, capital charges | Meet FRTB Standardized Approach requirements |
| **Operational Risk** | Transaction monitoring, data governance, audit trails | Maintain operational resilience and service quality |
| **Wealth Management** | Portfolio performance (TWR), risk analytics, advisor management | Optimize client outcomes and revenue per advisor |

---

## Interactive Analytics Notebooks

**8 Interactive Notebooks** providing instant-access analytics for compliance, risk management, and wealth operations. Built on Snowflake Notebooks with Streamlit.

### Compliance & Risk (5 Notebooks)

| Notebook | Audience | Key Analytics |
|----------|----------|---------------|
| **[Customer Screening & KYC](notebooks/customer_screening_kyc.ipynb)** | CCO, Compliance | Risk segmentation, PEP/sanctions evidence, KYC completeness, alert aging |
| **[AML & Transaction Monitoring](notebooks/aml_transaction_monitoring.ipynb)** | AML Teams, FIU | Alert metrics, SAR/STR filing, backlog management, risk heatmaps |
| **[Sanctions & Embargo](notebooks/sanctions_embargo_control.ipynb)** | Sanctions Officer, Legal | Control effectiveness, list updates, breach detection |
| **[Compliance Risk Mgmt](notebooks/compliance_risk_management.ipynb)** | CCO, Board, Audit | Enterprise risk register, regulatory breaches, top risks |
| **[Controls & Data Quality](notebooks/controls_data_quality.ipynb)** | Internal Audit, Data Gov | Control testing, BCBS 239 validation, audit evidence |

### Wealth & Operations (3 Notebooks)

| Notebook | Audience | Key Analytics |
|----------|----------|---------------|
| **[Employee Relationship Mgmt](notebooks/employee_relationship_management.ipynb)** | Wealth Mgmt, COO, HR | Advisor performance, AUM tracking, capacity planning |
| **[Wealth Management](notebooks/wealth_management.ipynb)** | Wealth Advisors, Private Banking | TWR analysis, Sharpe ratio, asset allocation, fee tracking |
| **[Lending Operations](notebooks/lending_operations.ipynb)** | Lending, Credit, Collections | NPL monitoring, Basel capital requirements |

**Access**: Deployed automatically via `deploy_structure.sh` → Snowsight → Projects → Notebooks

---

## Quick Start

### Prerequisites

```bash
# 1. Clone repository
git clone https://github.com/zBrainiac/SyntheticRetailBank.git
cd SyntheticRetailBank

# 2. Setup Snowflake CLI (https://docs.snowflake.com/cli)
snow connection add <my-sf-connection>

# 3. Setup Python environment
python -m venv venv
source venv/bin/activate  # macOS/Linux
pip install -r requirements.txt
```

### One-Command Deployment

```bash
# Generate data (1000 customers, 19 months of history)
./data_generator.sh 1000 --clean

# Deploy everything (SQL + notebooks + data + tasks)
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>
```

**Result**: Fully operational synthetic bank in ~15 minutes!

**What's Deployed**:
- All SQL objects (databases, schemas, tables, views, dynamic tables, streams, tasks)
- 8 interactive notebooks
- All generated data files uploaded to stages
- Automated processing activated

**What's Generated**:
- 1000 customers with employment, risk profiles, account tiers
- ~15 employees (dynamic hierarchy with advisor assignments)
- ~200K payment transactions (19 months)
- ~6K equity trades + fixed income + commodities
- SWIFT messages, PEP data, lifecycle events

**Important**: Always generate data **before** deploying structure!

---

## Architecture Overview

**Two-Layer System**: Data Generators → Snowflake Platform

### Data Generators (13 Python Modules)

| Type | Generators |
|------|------------|
| **Master Data** | `customer_generator` • `employee_generator` • `pep_generator` |
| **Transactions** | `pay_transaction_generator` • `equity_generator` • `fixed_income_generator` • `commodity_generator` |
| **Supporting** | `fx_generator` • `swift_generator` • `mortgage_email_generator` |
| **Lifecycle** | `customer_lifecycle_generator` • `address_update_generator` |
| **Compliance** | `anomaly_patterns` (AML testing) |

### Snowflake Platform (3-Layer Architecture)

**Layers**:
- **Raw Layer (0xx files)**: Immutable source data → Customer (`CRMI`), Accounts (`ACCI`), Payments (`PAYI`), Trades (`EQTI`), SWIFT (`ICGI`)
- **Aggregation Layer (3xx files)**: Business logic → Customer 360° (`CRMA`), Balances (`ACCA`), Anomalies (`PAYA`), Performance (`REPP`)
- **Reporting Layer (5xx files)**: Analytics & compliance → Risk reporting, regulatory dashboards, investment reports
- **Semantic Layer (7xx files)**: AI-ready views → 5 consolidated views for AI agents and notebooks

**Features**: Dynamic tables for auto-refresh • Streams & tasks for CDC • Semantic views for AI • SCD Type 2 tracking

**For Details**: See [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md) for conceptual design and [structure/README_DEPLOYMENT.md](structure/README_DEPLOYMENT.md) for deployment instructions.

---

## Key Capabilities Summary

- **12 EMEA Countries**: Multi-jurisdictional operations with localized compliance
- **Dynamic Employee Hierarchy**: 3-tier structure with auto-scaling (200 clients/advisor)
- **PEP & Sanctions Screening**: Fuzzy name matching with continuous monitoring
- **Customer 360°**: Integrated profiles with master data, transactions, lifecycle, compliance
- **AML Detection**: Multi-dimensional behavioral analysis with statistical scoring
- **Portfolio Analytics**: Time-Weighted Return (TWR), Sharpe ratio, asset allocation
- **Basel III/IV IRB**: PD, LGD, EAD modeling with RWA calculation
- **FRTB Market Risk**: Multi-asset sensitivities (delta, vega, curvature) with capital charges
- **Audit Trails**: SCD Type 2 tracking for addresses, ratings, customer status
- **Data Governance**: End-to-end lineage with BCBS 239 validation

---

## Data Characteristics

### Realistic Transaction Patterns
- **Business Hours**: 9 AM - 5 PM concentration
- **Weekday Focus**: Business days with automatic weekend skipping
- **Amount Distribution**: Log-normal for natural spread
- **Settlement Timing**: Type/amount/currency-based (0-3 days)

### AML Anomaly Patterns (7 Types)
1. **Large Amounts** - Significantly above baselines
2. **High Frequency** - Unusual transaction volumes
3. **Suspicious Counterparties** - Shell companies, offshore
4. **Round Amounts** - 10K, 50K, 100K (structuring)
5. **Off-Hours** - Outside business hours/weekends
6. **Rapid Succession** - Multiple large in short periods
7. **New Beneficiary Large** - Large to new counterparties

### Data Volumes by Customer Count

| Customers | Employees | Transactions | Trades | Files | Runtime |
|-----------|-----------|--------------|--------|-------|---------|
| 100 | 15 | ~20K | ~600 | ~100 | 1-2 min |
| 1,000 | 15-18 | ~200K | ~6K | ~400 | 5-7 min |
| 10,000 | 66 | ~2M | ~60K | ~1000+ | 10-15 min |

---

## Advanced Options

**Maximum Coverage** (10K customers, all features):
```bash
python3 main.py --customers 10000 --period 24 --clean \
  --generate-swift --generate-pep --generate-mortgage-emails \
  --generate-address-updates --generate-customer-updates \
  --generate-fixed-income --generate-commodities --generate-lifecycle
```

**Custom Volumes**:
```bash
python3 main.py --customers 10000 --period 24 --clean \
  --swift-percentage 40 --pep-records 500 --mortgage-customers 20 \
  --fixed-income-trades 5000 --commodity-trades 2000
```

**Manual Control** (step-by-step):
```bash
# 1. Generate data
./data_generator.sh 1000 --clean

# 2. Deploy SQL + notebooks + data
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>

# 3. Re-upload data only (if needed)
./upload-data.sh --CONNECTION_NAME=<my-sf-connection>

# 4. Redeploy notebooks only (if needed)
./deploy_notebooks.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>
```

---

## Troubleshooting

### Quick Fixes

| Issue | Solution |
|-------|----------|
| `ModuleNotFoundError: 'faker'` | `python -m venv venv && source venv/bin/activate && pip install -r requirements.txt` |
| `Customer file not found` | Generate data first: `./data_generator.sh 100 --clean` |
| `Connection not found` | Add connection: `snow connection add <my-sf-connection>` |
| `Database does not exist` | Create it: `snow sql -c <connection> -q "CREATE DATABASE AAA_DEV_SYNTHETIC_BANK;"` |
| `Stream has no data` | Re-upload: `./upload-data.sh --CONNECTION_NAME=<connection>` |

### Data Quality Validation

```sql
-- Quick counts
SELECT COUNT(*) as customers FROM CRM_RAW_001.CRMI_RAW_TB_CUSTOMER;
SELECT COUNT(*) as accounts FROM CRM_RAW_001.ACCI_RAW_TB_ACCOUNTS;
SELECT COUNT(*) as transactions FROM PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS;

-- Anomaly distribution
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN OVERALL_ANOMALY_CLASSIFICATION != 'NORMAL' THEN 1 END) as anomalous,
    ROUND(100.0 * COUNT(CASE WHEN OVERALL_ANOMALY_CLASSIFICATION != 'NORMAL' THEN 1 END) / COUNT(*), 2) as anomaly_pct
FROM PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES;
```

---

## Documentation

| Document | Purpose | Audience |
|----------|---------|----------|
| **[SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)** | Conceptual architecture, data flows, integration points | Architects, Data Engineers |
| **[structure/README_DEPLOYMENT.md](structure/README_DEPLOYMENT.md)** | Deployment order, configuration, technical details | DevOps, DBAs |
| **[SEMANTIC_VIEWS_QUICK_REFERENCE.md](SEMANTIC_VIEWS_QUICK_REFERENCE.md)** | Semantic views, AI agents, notebook mappings | Data Analysts, AI Engineers |

---

## Data Protection & Governance

**Automated PII Protection** using Snowflake sensitivity tags:

| Classification | Coverage | Access Level |
|----------------|----------|--------------|
| **TOP_SECRET** | Customer names, addresses, PEP data | Compliance, Risk Manager only |
| **RESTRICTED** | Financial balances, risk ratings, transactions | Analysts+ |
| **Untagged** | Aggregated metrics, operational data | All business users |

**Benefits**: Automated masking • GDPR/CCPA compliant • Business-friendly • Audit-ready

---