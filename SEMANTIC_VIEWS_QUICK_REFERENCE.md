# Semantic Views Quick Reference Guide
## AAA Synthetic Bank - Data Access Layer

> **Purpose**: This document describes the semantic layer (Layer 4) that provides AI-agent-friendly views.  
> **For architecture**: See [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)  
> **For deployment**: See [structure/README_DEPLOYMENT.md](structure/README_DEPLOYMENT.md)

---

## Overview

**7 Semantic View Domains** - AI-ready, notebook-friendly interface to the banking platform.

**Current Status**: 6 of 7 DEPLOYED | 4 AI Agents LIVE

```
┌───────────────────────────────────────────────────────────────────────┐
│                      SNOWFLAKE INTELLIGENCE                           │
│                       (AI Agents Layer)                               │
├───────────────────────────────────────────────────────────────────────┤
│   CRM Agent    │ Compliance │  Wealth  │    Loan     │  Liquidity    │
│ CRM_Customer_  │   Agent    │  Advisor │  Portfolio  │     Risk      │
│     360        │ COMPLIANCE │  Agent   │    Agent    │     Agent     │
│    DEPLOYED    │ MONITORING │  WEALTH  │    LOAN_    │  LIQUIDITY_   │
│                │   AGENT    │ ADVISOR  │ PORTFOLIO_  │     RISK_     │
│                │  DEPLOYED  │  AGENT   │    AGENT    │     AGENT     │
│                │            │ DEPLOYED │   DEPLOYED  │   DEPLOYED    │
└───────┬────────┴────┬───────┴────┬─────┴──────┬──────┴────┬──────────┘
        │             │            │            │           │
┌───────▼─────────────▼────────────▼────────────▼───────────▼──────────┐
│         SEMANTIC VIEWS (Business Layer - 7 UNIFIED DOMAINS)          │
├──────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  CRM DOMAIN (710, 715) DEPLOYED                                      │
│  ├─ 710: CRMA_SV_CUSTOMER_360                                        │
│  │        48 attrs: Customer profile + compliance + lifecycle        │
│  └─ 715: EMPA_SV_EMPLOYEE_ADVISOR                                    │
│           Advisor/customer relationships + performance metrics       │
│                                                                      │
│  PAY DOMAIN (720) DEPLOYED                                           │
│  └─ 720: PAYA_SV_COMPLIANCE_MONITORING                               │
│          33 attrs: AML transaction monitoring + anomaly scoring      │
│                                                                      │
│  WEALTH DOMAIN (730) DEPLOYED                                        │
│  └─ 730: REPA_SV_WEALTH_MANAGEMENT                                   │
│          61 attrs: Portfolio performance + risk metrics              │
│                                                                      │
│  LCR DOMAIN (750) DEPLOYED                                           │
│  └─ 750: LCRS_SV_LCR_* (5 views)                                     │
│          FINMA LCR monitoring, HQLA, outflows, compliance status     │
│                                                                      │
│  LOAN PORTFOLIO DOMAIN (765) DEPLOYED                                │
│  └─ 765: LOAS_SV_* (5 views)                                         │
│          Retail loans & mortgages, LTV, DTI, affordability, compl.   │
│                                                                      │
│  RISK DOMAIN (740) PENDING                                           │
│  └─ 740: REPA_SV_RISK_REPORTING                                      │
│          Cross-domain risk aggregation + regulatory compliance       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Naming Convention

### Format: `[DOMAIN][MATURITY]_SV_[PURPOSE]`

**Standard**: Follows existing database naming pattern
- **Domain**: CRM, PAY, EMP, REP (3-letter prefix)
- **Maturity**: A (Aggregation layer - all semantic views)
- **SV**: Semantic View (consistent with TB=table, DT=dynamic table, VW=view)
- **Purpose**: Descriptive name in CAPS_WITH_UNDERSCORES

| Domain | Full Name | Purpose | Example |
|--------|-----------|---------|---------|
| **CRMA** | CRM Aggregation | Customer data, compliance, lifecycle | `CRMA_SV_CUSTOMER_360` |
| **EMPA** | Employee Aggregation | Employee/advisor relationships | `EMPA_SV_EMPLOYEE_ADVISOR` |
| **PAYA** | Payment Aggregation | AML & sanctions compliance | `PAYA_SV_COMPLIANCE_MONITORING` |
| **REPA** | Reporting Aggregation | Wealth, portfolios, risk, credit | `REPA_SV_WEALTH_MANAGEMENT`, `REPA_SV_RISK_REPORTING` |

---

## Complete View Inventory

**Total: 7 Semantic View Domains | 14 Semantic Views**  
**Deployed: 6 of 7 | AI Agents: 4 LIVE**

### CRM DOMAIN (Customer Relationship Management)

| #   | View Name | File | What It Consolidates | Status | Used By |
|-----|-----------|------|----------------------|--------|---------|
| **710** | **CRMA_SV_CUSTOMER_360** | 710_CRMA_SV_CUSTOMER_360.sql | **[4 views → 1]**<br>• Customer profile (48 attrs)<br>• Compliance & Risk (PEP, sanctions)<br>• Lifecycle & Churn prediction<br>• Address intelligence<br>• Advisor assignment | ✅ **DEPLOYED** | All notebooks, Streamlit, **CRM_Customer_360 Agent** |
| **715** | **EMPA_SV_EMPLOYEE_ADVISOR** | 715_EMPA_SV_EMPLOYEE_ADVISOR.sql | **[NEW]**<br>• Employee/advisor relationships<br>• Performance metrics from customer data<br>• AUM, retention, capacity planning | ✅ **DEPLOYED** | Employee notebook, Streamlit, **CRM_Customer_360 Agent** |

**Source Tables (710)**:
- `CRMA_AGG_DT_CUSTOMER_360` (primary - 70+ attributes including advisor assignment)

**Source Tables (715)**:
- `EMPA_AGG_DT_ADVISORS` (created in 415_EMPA_employee_analytics.sql)
- Employee base data from `EMPI_RAW_TB_EMPLOYEE`

---

### PAY DOMAIN (Payments & Compliance)

| #   | View Name | File | What It Consolidates | Status | Used By |
|-----|-----------|------|----------------------|--------|---------|
| **720** | **PAYA_SV_COMPLIANCE_MONITORING** | 720_PAYA_SV_COMPLIANCE_MONITORING.sql | **[AML Monitoring]**<br>• Transaction monitoring (33 attrs)<br>• Anomaly detection & scoring<br>• Velocity, timing, amount analysis<br>• Customer & account context | ✅ **DEPLOYED** | AML notebook, **COMPLIANCE_MONITORING_AGENT** |

**Source Tables (720)**:
- `PAYA_AGG_DT_TRANSACTION_ANOMALIES` (primary - 33 attributes)
- `CRMA_AGG_DT_CUSTOMER_360` (customer context - LEFT JOIN in detailed view)
- `ACCA_AGG_DT_ACCOUNTS` (account details - LEFT JOIN in detailed view)

**Views Created**:
- `PAYA_SV_COMPLIANCE_MONITORING` (semantic view - for AI agent)
- `PAYA_SV_COMPLIANCE_MONITORING_DETAILED` (regular view with JOINs - for direct queries)
- `PAYA_SV_AML_MONITORING` (backward compatibility alias)

**Data Coverage**: 353,119 transactions analyzed
- 185,713 Normal behavior
- 97,742 Moderate anomalies
- 52,275 High anomalies
- 17,389 Critical anomalies

**Business Value**: €3.165M+ (€1.165M labor + €2M+ penalty avoidance)

---

### WEALTH DOMAIN (Wealth Management & Lending)

| #   | View Name | File | What It Consolidates | Status | Used By |
|-----|-----------|------|----------------------|--------|---------|
| **730** | **REPA_SV_WEALTH_MANAGEMENT** | 730_REPA_SV_WEALTH_MANAGEMENT.sql | **[3 views → 1]**<br>• Portfolio performance (multi-asset)<br>• Credit risk IRB (Basel)<br>• Equity trading & positions<br>• Advisor assignments | ✅ **DEPLOYED** | Wealth notebook, Lending notebook, **WEALTH_ADVISOR_AGENT** |

**Source Tables (730)**:
- `REPP_AGG_DT_PORTFOLIO_PERFORMANCE` (primary)
- `ACCA_AGG_DT_ACCOUNTS` (account details)
- `CRMA_AGG_DT_CUSTOMER_360` (customer context)
- `REPP_AGG_DT_IRB_CUSTOMER_RATINGS` (LEFT JOIN - credit risk)
- `REPP_AGG_DT_EQUITY_POSITIONS` (LEFT JOIN - equity holdings)
- `EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR` (LEFT JOIN)

**Business Value**: €9M+ (€3.2M AUM growth + €5.8M capital optimization)

---

### LCR DOMAIN (Liquidity Coverage Ratio - FINMA Compliance)

| #   | View Name | File | What It Consolidates | Status | Used By |
|-----|-----------|------|----------------------|--------|---------|
| **750** | **LCRS_SV_LCR_CURRENT** | 750_LCRS_SV_LCR_SEMANTIC_MODELS.sql | **[LCR Current Status]**<br>• Daily LCR ratio<br>• HQLA components (L1, L2A, L2B)<br>• Net cash outflows<br>• Compliance status | ✅ **DEPLOYED** | LCR notebook, Streamlit, **LIQUIDITY_RISK_AGENT** |
| **750** | **LCRS_SV_LCR_TREND** | 750_LCRS_SV_LCR_SEMANTIC_MODELS.sql | **[90-Day Trend Analysis]**<br>• Rolling LCR ratios<br>• Trend analysis<br>• Volatility metrics<br>• Breach tracking | ✅ **DEPLOYED** | LCR notebook, **LIQUIDITY_RISK_AGENT** |
| **750** | **LCRS_SV_HQLA_HOLDINGS** | 750_LCRS_SV_LCR_SEMANTIC_MODELS.sql | **[HQLA Holdings Detail]**<br>• Asset type breakdown<br>• Liquidity levels (L1/L2A/L2B)<br>• Haircuts applied<br>• Diversification metrics | ✅ **DEPLOYED** | LCR notebook, **LIQUIDITY_RISK_AGENT** |
| **750** | **LCRS_SV_DEPOSIT_OUTFLOWS** | 750_LCRS_SV_LCR_SEMANTIC_MODELS.sql | **[Deposit Outflows]**<br>• Deposit types & stability<br>• Run-off rates<br>• Counterparty classification<br>• Operational vs retail | ✅ **DEPLOYED** | LCR notebook, **LIQUIDITY_RISK_AGENT** |
| **750** | **LCRS_SV_LCR_ALERTS** | 750_LCRS_SV_LCR_SEMANTIC_MODELS.sql | **[Regulatory Alerts]**<br>• Breach detection<br>• Warning thresholds<br>• Recommended actions<br>• Severity classification | ✅ **DEPLOYED** | LCR notebook, **LIQUIDITY_RISK_AGENT** |

**Source Tables (750)**:
- `REPP_AGG_DT_LCR_DAILY` (daily calculations - 6 months history)
- `REPP_AGG_DT_LCR_TREND` (90-day rolling analysis)
- `REPP_AGG_VW_LCR_HQLA_HOLDINGS_DETAIL` (HQLA asset breakdown)
- `REPP_AGG_VW_LCR_DEPOSIT_BALANCES_DETAIL` (deposit outflows)
- `REPP_AGG_VW_LCR_ALERTS` (active alerts and breaches)

**Data Coverage**: 
- 180+ days of daily LCR calculations
- CHF 15B+ HQLA portfolio
- CHF 12B+ deposit base
- Real-time breach monitoring

**Business Value**: 
- FINMA compliance automation (100% requirement)
- Early warning system (105% threshold)
- Regulatory reporting automation
- SNB submission support

---

### LOAN PORTFOLIO DOMAIN (Retail Loans & Mortgages)

| #   | View Name | File | What It Consolidates | Status | Used By |
|-----|-----------|------|----------------------|--------|---------|
| **765** | **LOAS_SV_PORTFOLIO_CURRENT** | 765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql | **[Portfolio Summary]**<br>• Loan counts by product/country/status<br>• Total exposure<br>• Average amounts & terms<br>• Approval rates | ✅ **DEPLOYED** | Loan portfolio notebook, Streamlit, **LOAN_PORTFOLIO_AGENT** |
| **765** | **LOAS_SV_LTV_DISTRIBUTION** | 765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql | **[LTV Analysis]**<br>• LTV buckets (0-50%, 50-60%, ...>90%)<br>• Risk concentration<br>• Collateral values<br>• High-risk identification | ✅ **DEPLOYED** | Loan portfolio notebook, **LOAN_PORTFOLIO_AGENT** |
| **765** | **LOAS_SV_APPLICATION_FUNNEL** | 765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql | **[Application Funnel]**<br>• Approval/decline rates<br>• Channel performance<br>• Product conversion<br>• Processing metrics | ✅ **DEPLOYED** | Loan portfolio notebook, **LOAN_PORTFOLIO_AGENT** |
| **765** | **LOAS_SV_AFFORDABILITY_ANALYSIS** | 765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql | **[Affordability Assessment]**<br>• DTI & DSTI ratios<br>• Swiss 33⅓% rule compliance<br>• Pass/fail rates by country<br>• Income vs debt analysis | ✅ **DEPLOYED** | Loan portfolio notebook, **LOAN_PORTFOLIO_AGENT** |
| **765** | **LOAS_SV_COMPLIANCE_SCREENING** | 765_LOAS_SV_LOAN_PORTFOLIO_SEMANTIC_MODELS.sql | **[Compliance Integration]**<br>• Sanctions & PEP screening<br>• Vulnerable customer flags<br>• Risk ratings<br>• Compliance holds | ✅ **DEPLOYED** | Loan portfolio notebook, **LOAN_PORTFOLIO_AGENT** |

**Source Tables (765)**:
- `LOAR_AGG_DT_PORTFOLIO_SUMMARY` (portfolio aggregates)
- `LOAR_AGG_DT_LTV_DISTRIBUTION` (LTV risk buckets)
- `LOAR_AGG_DT_APPLICATION_FUNNEL` (application metrics)
- `LOAR_AGG_DT_AFFORDABILITY_SUMMARY` (affordability assessments)
- `LOAR_AGG_VW_COMPLIANCE_SCREENING` (compliance status)
- `CRMA_AGG_DT_CUSTOMER_360` (customer context - JOIN)

**Data Coverage**: 
- Multi-country: CHE, GBR, DEU, FRA, PRT, ITA, ESP
- Product types: Mortgages, personal loans
- Real-time application tracking
- Integrated compliance screening

**Business Value**: 
- Regulatory compliance (FINMA, FCA, DORA)
- Risk-based lending decisions
- Vulnerable customer protection
- Multi-jurisdiction affordability rules

---

### RISK DOMAIN (Cross-Domain Risk Aggregation & Regulatory)

| #   | View Name | File | What It Consolidates | Status | Used By |
|-----|-----------|------|----------------------|--------|---------|
| **740** | **REPA_SV_RISK_REPORTING** | 740_REPA_SV_RISK_REPORTING.sql | **[Cross-domain aggregation]**<br>• BCBS 239 risk aggregation<br>• FRTB market risk capital<br>• Currency exposure (FX risk)<br>• Data quality monitoring<br>• High-risk pattern detection | ⏳ **PENDING** | **RISK_REGULATORY_AGENT** (TBD), CRO, Risk Management, Board |

**Source Tables (740)**:
- `REPP_AGG_DT_ANOMALY_ANALYSIS` (primary - cross-domain anomalies)
- `REPP_AGG_DT_HIGH_RISK_PATTERNS` (risk pattern detection)
- `REPP_AGG_DT_BCBS239_RISK_AGGREGATION` (Basel III risk aggregation)
- `REPP_AGG_DT_BCBS239_DATA_QUALITY` (data quality metrics)
- `REPP_AGG_DT_BCBS239_REGULATORY_REPORTING` (regulatory readiness)
- `REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT` (FX risk)
- `REPP_AGG_DT_FRTB_CAPITAL_CHARGES` (LEFT JOIN - FRTB SA-TB capital)
- `REPP_AGG_DT_FRTB_RISK_POSITIONS` (LEFT JOIN - trading book)
- `REPP_AGG_DT_FRTB_SENSITIVITIES` (LEFT JOIN - delta sensitivities)

**Key Characteristics**:
- **Aggregated metrics** (not operational/transactional data)
- **Cross-domain** (consolidates risk from CRM + PAY + WEALTH)
- **Regulatory-focused** (BCBS 239, FRTB, Basel III/IV calculations)
- **Executive-level** (board-ready KPIs)
- **Meta-data** (data quality, completeness, timeliness)

**Sample AI Agent Questions**:
1. "What is our total Risk-Weighted Assets (RWA) across all portfolios?"
2. "Show me all high-risk patterns across customers, transactions, and portfolios"
3. "What's our FRTB capital charge for the equity trading book?"
4. "Are we compliant with BCBS 239 risk data aggregation principles?"
5. "Show me currency exposure across all customer portfolios"
6. "What are our top 10 risk concentrations by geography and product?"
7. "What percentage of our risk data meets regulatory quality standards?"

---

## Status Legend

| Status | Meaning | Action Required |
|--------|---------|----------------|
| ✅ **Deployed** | Semantic view & AI agent deployed and operational | None - monitoring only |
| ⏳ **Pending** | Planned but not yet implemented | Development in progress or scheduled |
| ⚠️ **Awaiting Dependencies** | Waiting for upstream schemas/tables | Blocked - dependencies must be created first |

**Deployment Progress**:
- **710**: Customer 360° view (4 views consolidated) ✅ **DEPLOYED**
- **715**: Employee/Advisor relationships ✅ **DEPLOYED**
- **720**: AML transaction monitoring ✅ **DEPLOYED**
- **730**: Portfolio performance (61 attrs) ✅ **DEPLOYED**
- **750**: LCR liquidity monitoring (5 views) ✅ **DEPLOYED**
- **765**: Loan portfolio analysis (5 views) ✅ **DEPLOYED**
- **740**: Cross-domain risk aggregation ⏳ **PENDING**

**AI Agents Deployed**:
- **CRM_Customer_360** (uses CRMA_SV_CUSTOMER_360 + EMPA_SV_EMPLOYEE_ADVISOR)
- **COMPLIANCE_MONITORING_AGENT** (uses PAYA_SV_COMPLIANCE_MONITORING + CRMA_SV_CUSTOMER_360)
- **WEALTH_ADVISOR_AGENT** (uses REPA_SV_WEALTH_MANAGEMENT + CRMA_SV_CUSTOMER_360 + EMPA_SV_EMPLOYEE_ADVISOR)
- **LIQUIDITY_RISK_AGENT** (uses LCRS_SV_* 5 LCR views)
- **LOAN_PORTFOLIO_AGENT** (uses LOAS_SV_* 5 loan portfolio views)

---

## Use Case Mapping

### Notebooks → Semantic Views

| Notebook | Primary Semantic View | Status | What It Provides |
|----------|----------------------|--------|------------------|
| **AML Transaction Monitoring** | **PAYA_SV_COMPLIANCE_MONITORING** (720) | ✅ **DEPLOYED** | Transaction anomalies, velocity analysis, customer context |
| **Compliance Risk Management** | **CRMA_SV_CUSTOMER_360** (710) + **PAYA_SV_COMPLIANCE_MONITORING** (720) | ✅ **DEPLOYED** | Customer risk + PEP + AML anomalies in 2 views |
| **Customer Screening & KYC** | **CRMA_SV_CUSTOMER_360** (710) | ✅ **DEPLOYED** | Customer profile, compliance, risk, address, advisor - all unified (70+ attrs) |
| **Employee Relationship Mgmt** | **EMPA_SV_EMPLOYEE_ADVISOR** (715) + **CRMA_SV_CUSTOMER_360** (710) | ✅ **DEPLOYED** | Advisor relationships + customer data + performance metrics |
| **Lending Operations** | **REPA_SV_WEALTH_MANAGEMENT** (730) | ✅ **DEPLOYED** | Portfolio performance, equity trading, risk metrics (61 attrs) |
| **Wealth Management** | **REPA_SV_WEALTH_MANAGEMENT** (730) | ✅ **DEPLOYED** | Portfolio performance (61 attrs), equity trading, asset allocation, risk metrics |
| **Sanctions & Embargo Control** | **PAYA_SV_COMPLIANCE_MONITORING** (720) | ⏳ **Phase 2** | Sanctions lists (OFAC, EU, UN, UK, CH) - awaiting SAN_AGG_001 |
| **Controls & Data Quality** | **REPA_SV_RISK_REPORTING** (740) | ⏳ **PENDING** | Data quality metrics, cross-domain risk aggregation, BCBS 239 |

**Key Benefit**: Each notebook now uses 1-2 views max (down from 3-5 views)  
**Phase 1**: 6 notebooks operational with new semantic views

---

### Streamlit App → Semantic Views

| Streamlit Module | Data Loaders | Semantic View | Status | What Changed |
|------------------|--------------|---------------|--------|--------------|
| **Customer 360 Tab** | `load_customer_360()`, `load_high_risk_customers()` | **CRMA_SV_CUSTOMER_360** (710) | ✅ **READY** | 1 view instead of 2 (70+ attrs) |
| **AML Monitoring Tab** | `load_aml_alerts()`, `load_aml_metrics()` | **PAYA_SV_COMPLIANCE_MONITORING_DETAILED** (720) | ✅ **READY** | 353K transactions, anomaly detection |
| **Compliance Tab** | `load_pep_matches()`, `load_sanctions_matches()` | **CRMA_SV_CUSTOMER_360** (710) + **PAYA_SV_COMPLIANCE_MONITORING_DETAILED** (720) | ✅ **READY** | 2 views instead of 3 |
| **Lifecycle Tab** | `load_customer_lifecycle()`, `load_high_churn_risk_customers()` | **CRMA_SV_CUSTOMER_360** (710) | ✅ **READY** | Lifecycle data included in customer 360 |
| **Advisor Performance** | `load_advisor_performance()` | **EMPA_SV_EMPLOYEE_ADVISOR** (715) | ✅ **READY** | New view with performance metrics |
| **Lending Tab** | `load_lending_portfolio()` | **REPA_SV_WEALTH_MANAGEMENT** (730) | ✅ **DEPLOYED** | Includes portfolio context |
| **Wealth Tab** | `load_wealth_portfolios()`, `load_advisor_performance()` | **REPA_SV_WEALTH_MANAGEMENT** (730) + **EMPA_SV_EMPLOYEE_ADVISOR** (715) | ✅ **DEPLOYED** | 2 views instead of 3 |

---

## Deployment Files

| File | Schema | Objects Created | Purpose |
|------|--------|-----------------|---------|
| **710_CRMA_SV_CUSTOMER_360.sql** | CRM_AGG_001 | 1 semantic view | Customer 360° unified view |
| **715_EMPA_SV_EMPLOYEE_ADVISOR.sql** | CRM_AGG_001 | 1 semantic view | Advisor performance & relationships |
| **720_PAYA_SV_COMPLIANCE_MONITORING.sql** | PAY_AGG_001 | 3 views (1 semantic + 1 detailed + 1 alias) | AML transaction monitoring |
| **730_REPA_SV_WEALTH_MANAGEMENT.sql** | REP_AGG_001 | 1 semantic view | Portfolio performance & wealth analytics |
| **740_REPA_SV_RISK_REPORTING.sql** | REP_AGG_001 | 1 semantic view | Cross-domain risk aggregation (pending) |

**Location**: `structure/` directory (deployed in numerical order)

**Deployment**:
```bash
./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK --CONNECTION_NAME=<my-sf-connection>
```

---

## Migration Summary

### Before: 10+ Fragmented Views
- CRM domain had 4 separate views (customer, compliance, lifecycle, address)
- Payment domain had 2 views (AML, sanctions - incomplete)
- Reporting domain had 3+ views (portfolio, equity, credit)
- LCR had no semantic layer (direct table queries only)
- Loan portfolio had no semantic layer (direct table queries only)
- Notebooks needed to query 3-5 views each
- AI agents had inconsistent data access patterns

### After: 7 Consolidated Domains | 14 Semantic Views
- **710**: Customer 360° (4 views → 1, 48 attrs consolidated)
- **715**: Employee/Advisor (NEW, fills gap in advisor analytics)
- **720**: AML Monitoring (2 views → 1, 33 attrs)
- **730**: Wealth Management (3 views → 1, 61 attrs)
- **750**: LCR Monitoring (NEW, 5 views for FINMA compliance)
- **765**: Loan Portfolio (NEW, 5 views for retail lending)
- **740**: Risk Reporting (NEW, cross-domain) - PENDING

**Benefits**:
- 📉 **65% reduction** in complexity (from fragmented queries to unified domains)
- 🚀 **Faster queries** - fewer JOINs per notebook
- 🤖 **AI-friendly** - consistent interface for 5 agents (4 deployed)
- 📊 **Better analytics** - consolidated attributes across domains
- 🔧 **Easier maintenance** - single source per domain
- 🏦 **Regulatory ready** - FINMA LCR, DORA, Basel compliance built-in

---

**Document Version**: 3.0  
**Last Updated**: January 18, 2026  
**Maintained By**: Data Engineering Team  
**Next Review**: Q2 2026

---

## Recent Updates (Version 3.0)

### Added (January 2026):
- **LCR Domain (750)**: 5 semantic views for FINMA liquidity monitoring
  - `LCRS_SV_LCR_CURRENT` - Daily LCR ratio and compliance status
  - `LCRS_SV_LCR_TREND` - 90-day rolling trend analysis
  - `LCRS_SV_HQLA_HOLDINGS` - HQLA asset breakdown by level
  - `LCRS_SV_DEPOSIT_OUTFLOWS` - Deposit run-off rates
  - `LCRS_SV_LCR_ALERTS` - Regulatory breach alerts
  
- **Loan Portfolio Domain (765)**: 5 semantic views for retail lending
  - `LOAS_SV_PORTFOLIO_CURRENT` - Portfolio summary by country/product/status
  - `LOAS_SV_LTV_DISTRIBUTION` - LTV risk bucket analysis
  - `LOAS_SV_APPLICATION_FUNNEL` - Application conversion metrics
  - `LOAS_SV_AFFORDABILITY_ANALYSIS` - DTI/DSTI affordability assessment
  - `LOAS_SV_COMPLIANCE_SCREENING` - Integrated PEP/sanctions screening

- **AI Agents**: 
  - `LIQUIDITY_RISK_AGENT` (850) - FINMA LCR monitoring and alerts
  - `LOAN_PORTFOLIO_AGENT` (865) - Retail loans & mortgages portfolio

### Statistics:
- **Total Domains**: 7 (6 deployed, 1 pending)
- **Total Semantic Views**: 14 (12 deployed, 2 pending with domain 740)
- **AI Agents**: 4 deployed (CRM, Compliance, Wealth, Liquidity, Loan Portfolio)
- **Streamlit Tabs**: 16 (all using semantic views)
- **Notebooks**: 8+ operational
