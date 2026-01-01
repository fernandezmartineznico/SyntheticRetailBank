# Synthetic Retail Bank

A comprehensive synthetic banking environment demonstrating modern risk management, governance, and compliance challenges faced by EMEA financial institutions. Features end-to-end data generation, regulatory reporting, and interactive analytics for AML, credit risk, market risk, and wealth management.

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
**8 Interactive Notebooks** providing instant-access analytics for compliance, risk management, and wealth operations. Built on Snowflake Notebooks with Streamlit - no authentication required.

### Compliance & Risk (5 Notebooks)

| Notebook | Audience | Key Analytics |
|----------|----------|---------------|
| **[Customer Screening & KYC](notebooks/customer_screening_kyc.ipynb)** | CCO, Compliance | Risk segmentation, PEP/sanctions evidence, KYC completeness, alert aging, audit trails |
| **[AML & Transaction Monitoring](notebooks/aml_transaction_monitoring.ipynb)** | AML Teams, FIU | Alert metrics, SAR/STR filing, backlog management, false positive analysis, risk heatmaps |
| **[Sanctions & Embargo](notebooks/sanctions_embargo_control.ipynb)** | Sanctions Officer, Legal | Control effectiveness, list updates, breach detection, exposure monitoring |
| **[Compliance Risk Mgmt](notebooks/compliance_risk_management.ipynb)** | CCO, Board, Audit | Enterprise risk register, regulatory breaches, top risks, incident remediation |
| **[Controls & Data Quality](notebooks/controls_data_quality.ipynb)** | Internal Audit, Data Gov | Control testing, data quality, BCBS 239 validation, audit evidence |

### Wealth & Operations (3 Notebooks)

| Notebook | Audience | Key Analytics |
|----------|----------|---------------|
| **[Employee Relationship Mgmt](notebooks/employee_relationship_management.ipynb)** | Wealth Mgmt, COO, HR | Advisor performance, AUM tracking, team dashboards, capacity planning, hiring needs |
| **[Wealth Management](notebooks/wealth_management.ipynb)** | Wealth Advisors, Private Banking | TWR analysis, Sharpe ratio, asset allocation, fee tracking, client segmentation |
| **[Lending Operations](notebooks/lending_operations.ipynb)** | Lending, Credit, Collections | Application tracking, auto-decisioning, NPL monitoring, Basel capital requirements |

**Features**: Interactive Streamlit dashboards • SQL queries • CSV export • Native Snowflake integration

**Access**: Deployed automatically via `deploy_structure.sh` → Snowsight → Projects → Notebooks

**Documentation**: See [Notebook Overlap Analysis](notebooks/OVERLAP_EXECUTIVE_SUMMARY.md) for analytics coverage and consolidation opportunities

---

## Key Capabilities

### Customer Risk & Compliance
- **Multi-Jurisdictional Operations**: 12 EMEA countries with localized compliance requirements
- **Dynamic Employee Hierarchy**: 3-tier structure (advisors → team leaders → super team leaders) with auto-scaling
- **Relationship Management**: Complete customer-advisor history with workload balancing (200 clients/advisor max)
- **Risk Classification**: Dynamic scoring (CRITICAL/HIGH/MODERATE/NORMAL) with behavioral profiling
- **PEP & Sanctions Screening**: Fuzzy name matching with continuous monitoring
- **Customer 360°**: Integrated profiles with master data, transactions, lifecycle events, compliance status
- **Lifecycle Analytics**: Event tracking (onboarding, changes, upgrades, closures, churn) with ML-ready churn prediction
- **Enhanced Due Diligence**: Automated triggers for high-risk segments and suspicious patterns

### AML & Transaction Monitoring
- **Anomaly Detection**: Multi-dimensional behavioral analysis with statistical scoring
- **Pattern Recognition**: Structuring, layering, integration techniques detection
- **Cross-Border Surveillance**: Multi-currency monitoring with enhanced controls
- **Trade-Based ML Detection**: Equity trading pattern analysis for unusual behaviors
- **Automated Alerts**: SAR/STR triggers with case management

### Investment Performance & Portfolio Analytics
- **Time-Weighted Return (TWR)**: Industry-standard performance measurement
- **Risk-Adjusted Returns**: Sharpe ratio, volatility analysis, maximum drawdown tracking
- **Portfolio Attribution**: Account-level and customer-level performance aggregation
- **Asset Allocation**: Multi-asset class analysis (cash, equity, FI, commodities)
- **Fee Analytics**: Commission tracking, cost ratios, net return calculations

### Credit Risk & Capital Management (Basel III/IV)
- **IRB Approach**: Internal Ratings Based regulatory capital calculation
- **Risk Parameters**: PD, LGD, EAD modeling with portfolio aggregation
- **RWA Calculation**: Automated risk-weighted assets and capital requirements
- **Rating Systems**: AAA-CCC scales with default tracking and watch lists
- **Model Validation**: Backtesting, performance monitoring, stress testing

### Market Risk (FRTB)
- **Multi-Asset Coverage**: Equity, FX, interest rates, commodities, credit spreads
- **Risk Sensitivities**: Delta, vega, curvature calculations for FRTB SA
- **Fixed Income**: Government/corporate bonds with duration, DV01, credit spreads
- **Commodities**: Energy, precious metals, base metals, agricultural with delta risk
- **Capital Charges**: FRTB SA calculations with correlation benefits

### Governance & Audit
- **Audit Trails**: SCD Type 2 tracking for addresses, ratings, customer status
- **Data Governance**: End-to-end lineage with BCBS 239 validation
- **Regulatory Reporting**: GDPR, MiFID II, Basel III/IV, PSD2 compliant structures
- **Data Protection**: Automated PII classification with Snowflake sensitivity tags
- **Quality Monitoring**: Completeness, accuracy, timeliness metrics

## Data Protection & Governance

**Automated PII Protection** using Snowflake sensitivity tags:

| Classification | Coverage | Access Level |
|----------------|----------|--------------|
| **TOP_SECRET** | Customer names, addresses, PEP data | Compliance, Risk Manager only |
| **RESTRICTED** | Financial balances, risk ratings, transactions | Analysts+ |
| **Untagged** | Aggregated metrics, operational data | All business users |

**Benefits**: Automated masking • GDPR/CCPA compliant • Business-friendly (focused protection) • Audit-ready

---

## Architecture

**Two-Layer System**: Data Generators → Snowflake DDL

### Data Generators (13 Python Modules)

| Type | Generators |
|------|------------|
| **Master Data** | `customer_generator` • `employee_generator` • `pep_generator` |
| **Transactions** | `pay_transaction_generator` • `equity_generator` • `fixed_income_generator` • `commodity_generator` |
| **Supporting** | `fx_generator` • `swift_generator` • `mortgage_email_generator` |
| **Lifecycle** | `customer_lifecycle_generator` • `address_update_generator` |
| **Compliance** | `anomaly_patterns` (AML testing) |

**External Integration**: Snowflake Data Exchange (Global Sanctions Data for real-time compliance screening)

### Snowflake DDL (`structure/` directory)

**3-Layer Architecture**:
- **Raw Layer (0xx)**: Customer (`CRMI`), Accounts (`ACCI`), Payments (`PAYI`), Trades (`EQTI`), SWIFT (`ICGI`)
- **Aggregation Layer (3xx)**: Customer 360° (`CRMA`), Balances (`ACCA`), Anomalies (`PAYA`), Performance (`REPP`)
- **Reporting Layer (5xx)**: Risk analytics, compliance dashboards, investment reports

**Features**: Dynamic tables for auto-refresh • Streams & tasks for CDC • Semantic views for AI • SCD Type 2 tracking

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
# OR: venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

### One-Command Deployment (Recommended)

```bash
# Generate data (1000 customers, 19 months of history)
./data_generator.sh 1000 --clean

# Deploy everything (SQL + notebooks + data + tasks)
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>
```

**Result**: Fully operational synthetic bank in ~15 minutes!

**What's Deployed**:
- All SQL objects (databases, schemas, tables, views, dynamic tables, streams, tasks)
- 8 interactive notebooks → Snowsight → Projects → Notebooks
- All generated data files uploaded to stages
- Automated processing activated (tasks + dynamic tables)

**What's Generated**:
- 1000 customers (employment, risk profiles, account tiers)
- ~15 employees (dynamic hierarchy with advisor assignments)
- ~200K payment transactions (19 months)
- ~6K equity trades + fixed income + commodities
- SWIFT messages, PEP data, lifecycle events, SCD Type 2 history

**Important**: Always generate data **before** deploying structure!

### Advanced Options

**Maximum Coverage** (10K customers, all features):
```bash
python3 main.py --customers 10000 --period 24 --clean \
  --generate-swift --generate-pep --generate-mortgage-emails \
  --generate-address-updates --generate-customer-updates \
  --generate-fixed-income --generate-commodities --generate-lifecycle
```
**Output**: ~2M transactions, ~66 employees, 1000+ files | **Runtime**: 10-15 minutes

**Custom Volumes**:
```bash
python3 main.py --customers 10000 --period 24 --clean \
  --swift-percentage 40 --pep-records 500 --mortgage-customers 20 \
  --fixed-income-trades 5000 --commodity-trades 2000
```

### Manual Control (Step-by-Step)

```bash
# 1. Generate data
./data_generator.sh 1000 --clean

# 2. Deploy SQL + notebooks + data
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>

# 3. Re-upload data only (if needed)
./upload-data.sh --CONNECTION_NAME=<my-sf-connection>

# For unstable networks or large file sets (1000+ files)
./upload-data.sh --CONNECTION_NAME=<my-sf-connection> --BATCH_SIZE=100 --MAX_RETRIES=5

# 4. Redeploy notebooks only (if needed)
./deploy_notebooks.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>
```

### Testing & Debugging

```bash
# Dry run (preview changes)
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection> --DRY_RUN

# Test single file
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection> --FILE=035_ICGI_swift_messages.sql
```

---

## Generated Data Files

### Master Data
| File | Description | Key Columns |
|------|-------------|-------------|
| `customers.csv` | Customer master (17 columns) | customer_id, name, dob, employment, account_tier, risk_classification, credit_score_band |
| `customer_addresses.csv` | Initial addresses | street, city, country (SCD Type 2 ready) |
| `employees.csv` | Employee hierarchy | employee_id, position_level, manager_id, performance_rating |
| `client_assignments.csv` | Customer-advisor mapping | assignment_id, customer_id, advisor_id, dates (SCD Type 2) |
| `accounts.csv` | Account master | account_id, account_type, base_currency, status |
| `pep_data.csv` | PEP reference data | Fuzzy matching capabilities |
| `customer_status.csv` | Status history | ACTIVE, CLOSED, CHURNED, REACTIVATED, DORMANT (SCD Type 2) |

### Lifecycle & Updates (SCD Type 2)
| Pattern | Description |
|---------|-------------|
| `address_updates/customer_addresses_YYYY-MM-DD.csv` | Date-stamped address changes for audit trails |
| `customer_updates/customer_updates_YYYY-MM-DD.csv` | Employment, tier, contact, risk profile changes |
| `customer_events/customer_events_YYYY-MM-DD.csv` | 8 event types: onboarding, changes, upgrades, closures, churn |

### Transaction Data
| Pattern | Description | Key Fields |
|---------|-------------|------------|
| `pay_transactions_YYYY-MM-DD.csv` | Daily payments | booking_date, value_date, amount (signed), currency, counterparty |
| `trades_YYYY-MM-DD.csv` | Daily equity trades | FIX protocol compliant: trade_date, symbol, isin, side, price, commission |
| `fx_rates_YYYY-MM-DD.csv` | Daily FX rates | Mid/bid/ask rates for multi-currency support |

### Fixed Income & Commodities
| File | Description | FRTB Metrics |
|------|-------------|--------------|
| `fixed_income_trades.csv` | Bonds & interest rate swaps | duration, DV01, credit_spread, liquidity_score |
| `commodity_trades.csv` | Energy, metals, agricultural | delta, volatility, spot/forward prices |

### Unstructured & Supporting
| Type | Files |
|------|-------|
| SWIFT Messages | `*.xml` (ISO20022 pacs.008, pacs.002) |
| Emails | `*.txt` (mortgage application threads) |
| Reports | `generation_summary.txt` (data volumes and statistics) |

**Scaling**: 100 customers → 15 employees | 1K customers → 15-18 employees | 10K customers → 66 employees (auto-balanced at ~170 clients/advisor)

---

## Data Characteristics & Configuration

### Realistic Transaction Patterns
- **Business Hours**: 9 AM - 5 PM concentration
- **Weekday Focus**: Business days with automatic weekend skipping
- **Amount Distribution**: Log-normal for natural spread
- **Settlement Timing**: Type/amount/currency-based (0-3 days)
  - Small (< $1K): T+0 or T+1
  - Medium ($1K-$10K): T+0 to T+2  
  - Large (> $10K): T+0 to T+3 (verification)
  - International: +1-2 days for non-USD

### AML Anomaly Patterns (7 Types)
1. **Large Amounts** - Significantly above baselines
2. **High Frequency** - Unusual transaction volumes
3. **Suspicious Counterparties** - Shell companies, offshore
4. **Round Amounts** - 10K, 50K, 100K (structuring)
5. **Off-Hours** - Outside business hours/weekends
6. **Rapid Succession** - Multiple large in short periods
7. **New Beneficiary Large** - Large to new counterparties

### Configuration Options
Customize via command line or `config.py`:
- Customer count • Anomaly % (default: 5%)
- Period (default: 19 months for churn)
- Transaction frequency • Amount ranges • Currencies

### Performance & Dependencies
- **Speed**: ~1000 transactions/second
- **Scaling**: Linear up to 10K customers
- **Requirements**: Faker • NumPy • Python standard library

---

## Troubleshooting

### Quick Fixes

| Issue | Solution |
|-------|----------|
| `ModuleNotFoundError: 'faker'` | `python -m venv venv && source venv/bin/activate && pip install -r requirements.txt` |
| `Customer file not found` | Generate data first: `./data_generator.sh 100 --clean` |
| `Connection not found` | Add connection: `snow connection add <my-sf-connection>` |
| `Database does not exist` | Create it: `snow sql -c <connection> -q "CREATE DATABASE AAA_DEV_SYNTHETIC_BANK;"` |
| `Tag does not exist` | Deploy will create automatically, or manually: `CREATE TAG SENSITIVITY_LEVEL;` |
| `Stream has no data` | Re-upload: `./upload-data.sh --CONNECTION_NAME=<connection>` |

### Data Quality Validation

```sql
-- Quick counts
SELECT COUNT(*) as customers FROM CRMI_RAW_TB_CUSTOMER;
SELECT COUNT(*) as accounts FROM ACCI_ACCOUNT;
SELECT COUNT(*) as transactions FROM PAYI_TRANSACTION;

-- Anomaly distribution
SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN has_anomaly THEN 1 END) as anomalous,
    ROUND(100.0 * COUNT(CASE WHEN has_anomaly THEN 1 END) / COUNT(*), 2) as anomaly_pct
FROM CRMI_RAW_TB_CUSTOMER;
```

---