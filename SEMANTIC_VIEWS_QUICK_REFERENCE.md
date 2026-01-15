# Semantic Views Quick Reference Guide
## AAA Synthetic Bank - Data Access Layer

> **Purpose**: This document describes the semantic layer (Layer 4) that provides AI-agent-friendly views.  
> **For architecture**: See [SYSTEM_ARCHITECTURE.md](SYSTEM_ARCHITECTURE.md)  
> **For deployment**: See [structure/README_DEPLOYMENT.md](structure/README_DEPLOYMENT.md)

---

## Overview

**5 Consolidated Semantic Views** - AI-ready, notebook-friendly interface to the banking platform.

**Current Status**: 4 of 5 DEPLOYED | 3 AI Agents LIVE

```
┌─────────────────────────────────────────────────────────────────┐
│                    SNOWFLAKE INTELLIGENCE                       │
│                     (AI Agents Layer)                           │
├─────────────────────────────────────────────────────────────────┤
│   CRM Agent    │  Compliance  │   Wealth    │  Risk & Regulatory│
│ CRM_Customer_  │    Agent     │   Advisor   │      Agent        │
│     360        │ COMPLIANCE_  │   Agent     │      (TBD)        │
│    DEPLOYED    │ MONITORING_  │  WEALTH_    │                   │
│                │    AGENT     │  ADVISOR_   │                   │
│                │   DEPLOYED   │   AGENT     │                   │
│                │              │  DEPLOYED   │                   │
└───────┬────────┴──────┬───────┴──────┬──────┴─────────┬─────────┘
        │               │              │                │
┌───────▼───────────────▼──────────────▼────────────────▼─────────┐
│         SEMANTIC VIEWS (Business Layer - 5 UNIFIED VIEWS)       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CRM DOMAIN (710, 715) DEPLOYED                                 │
│  ├─ 710: CRMA_SV_CUSTOMER_360                                   │
│  │        48 attrs: Customer profile + compliance + lifecycle   │
│  │                                                              │
│  └─ 715: EMPA_SV_EMPLOYEE_ADVISOR                               │
│           Advisor/customer relationships + performance metrics  │
│                                                                 │
│  PAY DOMAIN (720) DEPLOYED                                      │
│  └─ 720: PAYA_SV_COMPLIANCE_MONITORING                          │
│          33 attrs: AML transaction monitoring + anomaly scoring │
│                                                                 │
│  WEALTH DOMAIN (730) DEPLOYED                                   │
│  └─ 730: REPA_SV_WEALTH_MANAGEMENT                              │
│          61 attrs: Portfolio performance + risk metrics         │
│                                                                 │
│  RISK DOMAIN (740) PENDING                                      │
│  └─ 740: REPA_SV_RISK_REPORTING                                 │
│          Cross-domain risk aggregation + regulatory compliance  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
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

**Total: 5 Semantic Views (Consolidated Architecture)**  
**Deployed: 4 of 5 | AI Agents: 3 LIVE**

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
- **740**: Cross-domain risk aggregation ⏳ **PENDING**

**AI Agents Deployed**:
- **CRM_Customer_360** (uses CRMA_SV_CUSTOMER_360 + EMPA_SV_EMPLOYEE_ADVISOR)
- **COMPLIANCE_MONITORING_AGENT** (uses PAYA_SV_COMPLIANCE_MONITORING + CRMA_SV_CUSTOMER_360)
- **WEALTH_ADVISOR_AGENT** (uses REPA_SV_WEALTH_MANAGEMENT + CRMA_SV_CUSTOMER_360 + EMPA_SV_EMPLOYEE_ADVISOR)

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
- Notebooks needed to query 3-5 views each
- AI agents had inconsistent data access patterns

### After: 5 Consolidated Views
- **710**: Customer 360° (4 views → 1, 48 attrs consolidated)
- **715**: Employee/Advisor (NEW, fills gap in advisor analytics)
- **720**: AML Monitoring (2 views → 1, 33 attrs)
- **730**: Wealth Management (3 views → 1, 61 attrs)
- **740**: Risk Reporting (NEW, cross-domain)

**Benefits**:
- 📉 **50% reduction** in view count
- 🚀 **Faster queries** - fewer JOINs per notebook
- 🤖 **AI-friendly** - consistent interface for agents
- 📊 **Better analytics** - consolidated attributes
- 🔧 **Easier maintenance** - single source per domain

---

**Document Version**: 2.0  
**Last Updated**: January 2026  
**Maintained By**: Data Engineering Team  
**Next Review**: Q2 2026

