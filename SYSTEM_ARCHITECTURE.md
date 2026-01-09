# Synthetic Banking System - Architecture Documentation

**Version**: 2.0  
**Date**: January 2026  
**Status**: Production Ready

> **Purpose**: This document describes the conceptual architecture, data flows, and integration patterns.  
> **For deployment instructions**: See [structure/README_DEPLOYMENT.md](structure/README_DEPLOYMENT.md)  
> **For semantic views**: See [SEMANTIC_VIEWS_QUICK_REFERENCE.md](SEMANTIC_VIEWS_QUICK_REFERENCE.md)

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Architecture Layers](#architecture-layers)
3. [Data Flow Patterns](#data-flow-patterns)
4. [Schema Design Principles](#schema-design-principles)
5. [Python Data Generation Architecture](#python-data-generation-architecture)
6. [Integration Points](#integration-points)
7. [Security & Compliance](#security--compliance)

---

## 1. System Overview

### 1.1 Purpose

Enterprise-grade synthetic banking data platform demonstrating:
- **Customer Due Diligence (CDD)** testing
- **Anti-Money Laundering (AML)** detection patterns
- **Churn Prediction** analytics with ML-ready features
- **FRTB** (Fundamental Review of Trading Book) compliance
- **Regulatory Reporting** (Basel III/IV, BCBS 239, MiFID II)

### 1.2 Technology Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    TECHNOLOGY STACK                         │
├─────────────────────────────────────────────────────────────┤
│ Data Warehouse: Snowflake (Dynamic Tables, Tasks, Streams) │
│ Data Generation: Python 3.12+ (Faker, NumPy, CSV)          │
│ Orchestration:   Bash scripts (automated deployment)       │
│ Notebooks:       Snowflake Notebooks with Streamlit        │
│ Version Control: Git                                        │
│ Documentation:   Markdown, ASCII Diagrams                   │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 System Scope

**Data Domains**:
- Customer Master Data (EMEA, 12 countries) with SCD Type 2
- Employee Hierarchy & Client-Advisor Relationships
- Account Management (4 account types)
- Payment Transactions (multi-currency, anomaly detection)
- SWIFT ISO20022 Messages (PACS.008, PACS.002)
- Multi-Asset Trading: Equity, Fixed Income, Commodities
- FX Rates & Currency Analytics
- PEP & Sanctions Screening
- Customer Lifecycle Events (9 event types)
- Churn Prediction & Risk Classification

**Key Metrics**:
- Scalable: 100 → 10,000+ customers
- 4 trading asset classes
- 12 EMEA countries
- 9 lifecycle event types
- 7 AML anomaly patterns
- SCD Type 2 tracking for customer attributes, addresses, status, assignments

---

## 2. Architecture Layers

### 2.1 Four-Tier Data Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│              SNOWFLAKE DATA ARCHITECTURE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Layer 0: EXTERNAL SOURCES                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  • Python Generators → CSV/XML files                     │  │
│  │  • Snowflake Data Exchange → Global Sanctions Data      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  Layer 1: RAW DATA INGESTION (RAW_001 Schemas)                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CRM_RAW_001:  Customers, Addresses, PEP, Events        │  │
│  │  PAY_RAW_001:  Transactions, SWIFT Messages             │  │
│  │  EQT_RAW_001:  Equity Trades                            │  │
│  │  FII_RAW_001:  Bonds, Interest Rate Swaps              │  │
│  │  CMD_RAW_001:  Commodities (Energy, Metals, Agri)      │  │
│  │  REF_RAW_001:  FX Rates                                 │  │
│  │                                                           │  │
│  │  Pattern: Immutable, append-only, source of truth       │  │
│  │  Loading: Streams → Serverless Tasks (auto-triggered)   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  Layer 2: AGGREGATION (AGG_001 Schemas)                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CRM_AGG_001:  Customer 360°, SCD Type 2, Lifecycle    │  │
│  │  PAY_AGG_001:  Anomaly Detection, Account Balances     │  │
│  │  ACC_AGG_001:  Account Aggregation                     │  │
│  │  EQT_AGG_001:  Portfolio Positions, Trade Analytics    │  │
│  │  FII_AGG_001:  Duration, Credit Exposure, Yield Curve  │  │
│  │  CMD_AGG_001:  Delta Risk, Volatility Analysis         │  │
│  │  REF_AGG_001:  FX Analytics, Volatility                │  │
│  │                                                           │  │
│  │  Pattern: Business logic, single-domain aggregations    │  │
│  │  Loading: Dynamic Tables (60-min auto-refresh)          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  Layer 3: REPORTING & ANALYTICS (REP_AGG_001)                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Cross-Domain Analytics:                                 │  │
│  │  • Portfolio Performance (TWR, Sharpe, Risk Metrics)    │  │
│  │  • Credit Risk IRB (Basel III/IV, RWA)                  │  │
│  │  • FRTB Market Risk (Sensitivities, Capital Charges)    │  │
│  │  • BCBS 239 (Risk Aggregation, Data Quality)            │  │
│  │  • Lifecycle AML Correlation                            │  │
│  │                                                           │  │
│  │  Pattern: Multi-domain joins, complex calculations      │  │
│  │  Loading: Dynamic Tables (60-min auto-refresh)          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          ↓                                      │
│  Layer 4: SEMANTIC LAYER (Consolidated Views)                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  5 AI-Ready Semantic Views:                              │  │
│  │  • CRMA_SV_CUSTOMER_360 (Customer profile + compliance) │  │
│  │  • EMPA_SV_EMPLOYEE_ADVISOR (Advisor performance)       │  │
│  │  • PAYA_SV_COMPLIANCE_MONITORING (AML alerts)           │  │
│  │  • REPA_SV_WEALTH_MANAGEMENT (Portfolio analytics)      │  │
│  │  • REPA_SV_RISK_REPORTING (Cross-domain risk)           │  │
│  │                                                           │  │
│  │  Pattern: AI agent interface, notebook-ready            │  │
│  │  Loading: Views (real-time)                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Layer Responsibilities

#### Layer 1: RAW (Source of Truth)
- **Purpose**: Immutable source data, audit trail
- **Pattern**: Append-only, no transformations
- **Loading**: Stream-triggered serverless tasks
- **Refresh**: Real-time (on file arrival via PUT command)
- **Retention**: Permanent (regulatory compliance)

#### Layer 2: AGGREGATION (Business Logic)
- **Purpose**: Single-domain aggregations, SCD Type 2 tracking
- **Pattern**: Dynamic tables with business rules
- **Loading**: Auto-refresh from RAW layer
- **Refresh**: 60-minute target lag
- **Features**: Customer 360°, anomaly detection, balance calculation

#### Layer 3: REPORTING (Cross-Domain Analytics)
- **Purpose**: Multi-domain reporting, regulatory calculations
- **Pattern**: Complex joins, Basel/FRTB/BCBS calculations
- **Loading**: Auto-refresh from AGG layer
- **Refresh**: 60-minute target lag
- **Features**: Portfolio performance, credit risk, market risk, data quality

#### Layer 4: SEMANTIC (AI Interface)
- **Purpose**: Simplified, AI-agent-friendly views
- **Pattern**: Consolidated views per business domain
- **Loading**: Real-time views on AGG/REP layers
- **Refresh**: Instant (view refresh)
- **Features**: Natural language queries, notebook integration, AI agents

---

## 3. Data Flow Patterns

### 3.1 End-to-End Data Pipeline

```
┌────────────────────────────────────────────────────────────────────┐
│                    DATA PIPELINE FLOW                              │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  GENERATION                                                        │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Python Generators                                        │    │
│  │  ├─ customer_generator.py → customers.csv                │    │
│  │  ├─ pay_transaction_generator.py → pay_transactions*.csv │    │
│  │  ├─ equity_generator.py → trades*.csv                    │    │
│  │  ├─ customer_lifecycle_generator.py → events*.csv        │    │
│  │  └─ ...13 generators total                               │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓ (PUT command)                           │
│  INGESTION                                                         │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Internal Stages (DIRECTORY = ENABLE, AUTO_REFRESH)      │    │
│  │  ├─ @CRMI_RAW_STAGE_CUSTOMERS                            │    │
│  │  ├─ @PAYI_RAW_STAGE_TRANSACTIONS                         │    │
│  │  └─ ...8 stages                                           │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓ (Stream detection)                      │
│  PROCESSING                                                        │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Streams detect new files → Tasks execute COPY INTO      │    │
│  │  ├─ CRMI_RAW_STREAM_CUSTOMER_FILES                       │    │
│  │  ├─ CRMI_RAW_TASK_LOAD_CUSTOMERS                         │    │
│  │  └─ Pattern: Stream → Task → Table                       │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓ (Auto-refresh)                          │
│  AGGREGATION                                                       │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Dynamic Tables (60-min LAG)                             │    │
│  │  ├─ CRMA_AGG_DT_CUSTOMER_360 (Customer profile)          │    │
│  │  ├─ PAYA_AGG_DT_TRANSACTION_ANOMALIES (AML detection)    │    │
│  │  ├─ REPP_AGG_DT_PORTFOLIO_PERFORMANCE (TWR calculation)  │    │
│  │  └─ ...40+ dynamic tables                                │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓ (Real-time views)                       │
│  SEMANTIC LAYER                                                    │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  5 Consolidated Views for AI Agents                      │    │
│  │  ├─ CRMA_SV_CUSTOMER_360                                 │    │
│  │  ├─ PAYA_SV_COMPLIANCE_MONITORING                        │    │
│  │  └─ ...5 semantic views                                  │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓                                         │
│  CONSUMPTION                                                       │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  • Snowflake Notebooks (8 interactive dashboards)        │    │
│  │  • AI Agents (CRM_Customer_360, COMPLIANCE_MONITORING)   │    │
│  │  • BI Tools (Tableau, Power BI, Snowsight)              │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### 3.2 Customer Lifecycle Data Flow

```
┌────────────────────────────────────────────────────────────────────┐
│              CUSTOMER LIFECYCLE EVENT PIPELINE                     │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  PHASE 1: Data-Driven Events (Cannot be randomly generated)       │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  customer_generator.py                                    │    │
│  │  └─ ONBOARDING events (from ONBOARDING_DATE)             │    │
│  │                                                            │    │
│  │  address_update_generator.py                              │    │
│  │  └─ ADDRESS_CHANGE events (exact timestamps from CSV)    │    │
│  │                                                            │    │
│  │  customer_update_generator.py                             │    │
│  │  └─ ACCOUNT_UPGRADE, ACCOUNT_DOWNGRADE,                  │    │
│  │     EMPLOYMENT_CHANGE (exact timestamps)                  │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓                                         │
│  PHASE 2: Random Events (Controlled generation)                   │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  customer_lifecycle_generator.py                          │    │
│  │  ├─ ACCOUNT_CLOSE (40% weight, 0-2 per customer)         │    │
│  │  ├─ REACTIVATION (30% weight, only for closed accounts)  │    │
│  │  ├─ CHURN (20% weight, 0-2 per customer)                 │    │
│  │  └─ DORMANT_DETECTED (10% weight, 0-2 per customer)      │    │
│  │                                                            │    │
│  │  Rules:                                                    │    │
│  │  • NO events for dormant customers                        │    │
│  │  • ONLY REACTIVATION for closed customers                │    │
│  │  • Time deltas: 30-900 days (normal distribution)        │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓                                         │
│  STATUS HISTORY GENERATION (SCD Type 2)                           │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  customer_status.csv                                      │    │
│  │  ├─ Initial: ACTIVE (at onboarding)                      │    │
│  │  ├─ Transitions: ACCOUNT_CLOSE → CLOSED                  │    │
│  │  │                CHURN → CLOSED                          │    │
│  │  │                REACTIVATION → REACTIVATED              │    │
│  │  └─ SCD Type 2: start_date, end_date, is_current         │    │
│  └──────────────────────────────────────────────────────────┘    │
│                          ↓                                         │
│  SNOWFLAKE INGESTION                                              │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │  Tables:                                                   │    │
│  │  ├─ CRMI_RAW_TB_CUSTOMER_EVENT (append-only events)      │    │
│  │  └─ CRMI_RAW_TB_CUSTOMER_STATUS (SCD Type 2 status)      │    │
│  │                                                            │    │
│  │  Dynamic Tables:                                           │    │
│  │  ├─ CRMA_AGG_DT_CUSTOMER_360 (current status + events)   │    │
│  │  └─ REPP_AGG_DT_LIFECYCLE_ANOMALIES (AML correlation)    │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘

**Critical Synchronization Points:**
1. ADDRESS_CHANGE events MUST use exact timestamps from address_updates/*.csv
2. ACCOUNT_UPGRADE/DOWNGRADE MUST match customer_updates/*.csv timestamps
3. Churn model uses transaction inactivity, NOT event frequency
4. AML correlation: 30-day window between lifecycle events and anomalies
```

---

## 4. Schema Design Principles

### 4.1 Naming Convention

**Schema Pattern**: `{DOMAIN}_{LAYER}_{VERSION}`
- Example: `CRM_RAW_001`, `PAY_AGG_001`, `REP_AGG_001`

**Object Pattern**: `{DOMAIN}{LAYER}_[OBJECT_TYPE]_{NAME}`
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

### 4.2 SCD Type 2 Pattern

**Customer Attributes** (employment, account tier, risk profile):
```
CRMI_RAW_TB_CUSTOMER (base table - append-only)
  PK: (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)
  ↓
CRMA_AGG_DT_CUSTOMER_CURRENT (operational view - latest only)
  PK: CUSTOMER_ID
  ↓
CRMA_AGG_DT_CUSTOMER_HISTORY (analytical view - full history)
  PK: (CUSTOMER_ID, VALID_FROM)
  Columns: VALID_FROM, VALID_TO, IS_CURRENT
```

**Customer Addresses**:
```
CRMI_RAW_TB_ADDRESSES (base table - append-only)
  PK: (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)
  ↓
CRMA_AGG_DT_ADDRESSES_CURRENT (operational view - latest only)
  PK: CUSTOMER_ID
  ↓
CRMA_AGG_DT_ADDRESSES_HISTORY (analytical view - full history)
  PK: (CUSTOMER_ID, VALID_FROM)
  Columns: VALID_FROM, VALID_TO, IS_CURRENT
```

**Customer Status**:
```
CRMI_RAW_TB_CUSTOMER_STATUS (SCD Type 2)
  PK: STATUS_ID
  Columns: CUSTOMER_ID, STATUS, START_DATE, END_DATE, IS_CURRENT
```

**Client-Advisor Assignments**:
```
EMPI_RAW_TB_CLIENT_ASSIGNMENT (SCD Type 2)
  PK: ASSIGNMENT_ID
  Columns: CUSTOMER_ID, ADVISOR_ID, START_DATE, END_DATE, IS_CURRENT, ASSIGNMENT_REASON
```

### 4.3 Key Relationships

```
┌──────────────────────────────────────────────────────────────┐
│                  ENTITY RELATIONSHIPS                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  CRMI_RAW_TB_CUSTOMER (SCD Type 2)                          │
│  ├─ PK: (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)                 │
│  │                                                            │
│  ├──→ CRMI_RAW_TB_ADDRESSES (1:N, SCD Type 2)               │
│  │    └─ PK: (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)            │
│  │                                                            │
│  ├──→ CRMI_RAW_TB_CUSTOMER_EVENT (1:N, append-only)         │
│  │    └─ 9 event types: ONBOARDING → CHURN                  │
│  │                                                            │
│  ├──→ CRMI_RAW_TB_CUSTOMER_STATUS (1:N, SCD Type 2)         │
│  │    └─ Status lifecycle: ACTIVE → CLOSED → REACTIVATED    │
│  │                                                            │
│  ├──→ ACCI_RAW_TB_ACCOUNTS (1:N)                            │
│  │    ├─ PK: ACCOUNT_ID                                      │
│  │    └─ 4 types: CHECKING, SAVINGS, BUSINESS, INVESTMENT   │
│  │                                                            │
│  └──→ EMPI_RAW_TB_CLIENT_ASSIGNMENT (1:N, SCD Type 2)       │
│       └─ Advisor relationship tracking                       │
│                                                               │
│  ACCI_RAW_TB_ACCOUNTS                                        │
│  └──→ PAYI_RAW_TB_TRANSACTIONS (1:N)                         │
│       ├─ PK: TRANSACTION_ID                                  │
│       ├─ Multi-currency support                              │
│       └─ Anomaly patterns embedded in DESCRIPTION            │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 5. Python Data Generation Architecture

### 5.1 Generator Modules (13 Generators)

```
┌────────────────────────────────────────────────────────────────┐
│              PYTHON GENERATOR ARCHITECTURE                     │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ORCHESTRATION                                                 │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  main.py (command-line interface)                    │    │
│  │  ├─ Configuration management (config.py)             │    │
│  │  ├─ Generator orchestration                          │    │
│  │  ├─ Summary report generation                        │    │
│  │  └─ Error handling and logging                       │    │
│  └──────────────────────────────────────────────────────┘    │
│                          ↓                                     │
│  MASTER DATA GENERATORS                                        │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  customer_generator.py                                │    │
│  │  ├─ EMEA locale (12 countries)                       │    │
│  │  ├─ Faker library for names/addresses                │    │
│  │  └─ Extended attributes (employment, tier, risk)     │    │
│  │                                                        │    │
│  │  employee_generator.py                                │    │
│  │  ├─ 3-tier hierarchy (advisors → leaders → super)    │    │
│  │  ├─ Dynamic scaling (200 clients per advisor)        │    │
│  │  └─ Performance ratings, certifications              │    │
│  │                                                        │    │
│  │  pep_generator.py                                     │    │
│  │  └─ Politically Exposed Persons data                 │    │
│  └──────────────────────────────────────────────────────┘    │
│                          ↓                                     │
│  TRANSACTION GENERATORS                                        │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  pay_transaction_generator.py                         │    │
│  │  ├─ 7 anomaly patterns                               │    │
│  │  ├─ Business hours concentration                     │    │
│  │  └─ Multi-currency, FX conversion                    │    │
│  │                                                        │    │
│  │  equity_generator.py                                  │    │
│  │  ├─ FIX protocol compliant                           │    │
│  │  └─ Stock trades with commissions                    │    │
│  │                                                        │    │
│  │  fixed_income_generator.py                            │    │
│  │  ├─ Government bonds (CHF, EUR, USD, GBP)            │    │
│  │  ├─ Corporate bonds (credit ratings)                 │    │
│  │  └─ Interest rate swaps (SARON, EURIBOR, SOFR)       │    │
│  │                                                        │    │
│  │  commodity_generator.py                               │    │
│  │  └─ Energy, metals, agricultural (delta risk)        │    │
│  └──────────────────────────────────────────────────────┘    │
│                          ↓                                     │
│  LIFECYCLE GENERATORS                                          │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  customer_lifecycle_generator.py                      │    │
│  │  ├─ Phase 1: Data-driven events (5 types)            │    │
│  │  ├─ Phase 2: Random events (4 types)                 │    │
│  │  └─ Status history (SCD Type 2)                      │    │
│  │                                                        │    │
│  │  address_update_generator.py                          │    │
│  │  └─ SCD Type 2 address changes (time-series)         │    │
│  │                                                        │    │
│  │  customer_update_generator.py                         │    │
│  │  └─ Employment, account tier, risk profile changes   │    │
│  └──────────────────────────────────────────────────────┘    │
│                          ↓                                     │
│  SUPPORTING GENERATORS                                         │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  fx_generator.py                                      │    │
│  │  └─ Daily FX rates (mid/bid/ask)                     │    │
│  │                                                        │    │
│  │  swift_generator.py                                   │    │
│  │  └─ ISO20022 XML messages (PACS.008, PACS.002)       │    │
│  │                                                        │    │
│  │  mortgage_email_generator.py                          │    │
│  │  └─ Unstructured email threads (PDF documents)       │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                                │
└────────────────────────────────────────────────────────────────┘

**Performance**: ~1000 transactions/second • Linear scaling to 10K customers
```

### 5.2 AML Anomaly Pattern Implementation

**7 Anomaly Types** (embedded in transaction descriptions):

1. **Large Amounts** - `[LARGE_AMOUNT]` - Transaction significantly above customer baseline
2. **High Frequency** - `[HIGH_FREQUENCY]` - Unusual transaction volume per day
3. **Suspicious Counterparties** - `[SUSPICIOUS_COUNTERPARTY]` - Shell companies, offshore entities
4. **Round Amounts** - `[ROUND_AMOUNT]` - Exact multiples (10K, 50K, 100K) indicating structuring
5. **Off-Hours** - `[OFF_HOURS]` - Outside business hours or weekends
6. **Rapid Succession** - `[RAPID_SUCCESSION]` - Multiple large transactions in short window
7. **New Beneficiary Large** - `[NEW_BENEFICIARY_LARGE]` - Large amount to new counterparty

**Detection Strategy** (in aggregation layer):
```sql
-- PAYA_AGG_DT_TRANSACTION_ANOMALIES
CASE 
  WHEN DESCRIPTION LIKE '%[LARGE_AMOUNT]%' THEN 'LARGE_AMOUNT_ANOMALY'
  WHEN DESCRIPTION LIKE '%[HIGH_FREQUENCY]%' THEN 'HIGH_FREQUENCY_ANOMALY'
  -- ... pattern matching for all 7 types
END AS ANOMALY_TYPE
```

---

## 6. Integration Points

### 6.1 External Data Sources

**Snowflake Data Exchange** (optional):
```
┌────────────────────────────────────────────────────────────┐
│  AAA_DEV_SYNTHETIC_BANK_REF_DAP_GLOBAL_SANCTIONS_DATA_SET  │
│  └─ Global Sanctions Data (OFAC, EU, UN, UK, CH lists)    │
│                                                             │
│  Integration:                                               │
│  └─ CRMA_AGG_DT_CUSTOMER_360 performs fuzzy matching      │
│     against SANCTIONS_DATAFEED table                       │
│                                                             │
│  Benefits:                                                  │
│  ├─ Real-time sanctions screening                         │
│  ├─ Compliance evidence for audits                        │
│  └─ Regulatory reporting support                          │
└────────────────────────────────────────────────────────────┘
```

### 6.2 Data Synchronization Rules

**Critical Synchronization Points**:

1. **Address Changes ↔ Lifecycle Events**
   - `CRMI_RAW_TB_ADDRESSES.INSERT_TIMESTAMP_UTC` MUST MATCH
   - `CRMI_RAW_TB_CUSTOMER_EVENT.EVENT_TIMESTAMP_UTC` (for ADDRESS_CHANGE events)
   - ADDRESS_CHANGE events use EXACT timestamps from `address_updates/*.csv`

2. **Customer Attribute Changes ↔ Lifecycle Events**
   - `CRMI_RAW_TB_CUSTOMER.INSERT_TIMESTAMP_UTC` MUST MATCH
   - `CRMI_RAW_TB_CUSTOMER_EVENT.EVENT_TIMESTAMP_UTC` (for ACCOUNT_UPGRADE, EMPLOYMENT_CHANGE)
   - Customer attribute changes create BOTH:
     1. New `CRMI_RAW_TB_CUSTOMER` record (SCD Type 2)
     2. Corresponding lifecycle event with same timestamp

3. **Lifecycle Events → Churn Prediction**
   - `PAYI_RAW_TB_TRANSACTIONS.LAST_BOOKING_DATE` drives `CHURN_PROBABILITY`
   - Churn model uses transaction inactivity, NOT event frequency
   - Dormant customers (>180 days) have NO events by definition

4. **Lifecycle Events → AML Correlation**
   - `CRMI_RAW_TB_CUSTOMER_EVENT.EVENT_DATE` within 30-day window of
   - `PAYA_AGG_DT_TRANSACTION_ANOMALIES.BOOKING_DATE`
   - `REPP_AGG_DT_LIFECYCLE_ANOMALIES` correlates high-risk events with suspicious transactions

---

## 7. Security & Compliance

### 7.1 Data Classification (Snowflake Tags)

```
┌────────────────────────────────────────────────────────────┐
│           DATA SENSITIVITY CLASSIFICATION                  │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  Tag: SENSITIVITY_LEVEL                                    │
│                                                            │
│  TOP_SECRET:                                               │
│  ├─ CRMI_RAW_TB_CUSTOMER.CUSTOMER_ID                      │
│  ├─ CRMI_RAW_TB_ADDRESSES.STREET_ADDRESS                  │
│  └─ PAYI_RAW_TB_TRANSACTIONS.TRANSACTION_ID               │
│                                                            │
│  RESTRICTED:                                               │
│  ├─ CRMI_RAW_TB_CUSTOMER.FIRST_NAME                       │
│  ├─ CRMI_RAW_TB_CUSTOMER.FAMILY_NAME                      │
│  ├─ PAYI_RAW_TB_TRANSACTIONS.AMOUNT                       │
│  └─ PAYI_RAW_TB_TRANSACTIONS.COUNTERPARTY_ACCOUNT         │
│                                                            │
│  PUBLIC:                                                   │
│  ├─ REFI_RAW_TB_FX_RATES (all fields)                     │
│  └─ Reference data (no PII)                               │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 7.2 Regulatory Compliance Features

**GDPR & Data Protection**:
- Automated PII tagging with `SENSITIVITY_LEVEL`
- Data minimization in aggregation layers
- Audit trail via SCD Type 2 tracking

**Basel III/IV**:
- IRB approach: PD, LGD, EAD modeling
- RWA calculation in `REPP_AGG_DT_IRB_RWA_SUMMARY`
- Capital adequacy ratios

**FRTB**:
- Market risk sensitivities (delta, vega, curvature)
- Capital charges by risk class
- Non-Modellable Risk Factor (NMRF) identification

**BCBS 239**:
- Risk data aggregation across domains
- Data quality monitoring (completeness, accuracy, timeliness)
- Regulatory reporting capabilities

**MiFID II**:
- Best execution tracking
- Transaction cost analysis
- Client reporting (TWR, Sharpe ratio)

---

## Appendix: Domain Prefixes Reference

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

**Document Version**: 2.0  
**Last Updated**: January 2026  
**Maintained By**: Architecture Team  
**Next Review**: Q2 2026

