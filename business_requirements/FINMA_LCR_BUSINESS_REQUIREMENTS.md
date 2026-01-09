# FINMA LCR Reporting Module - Business Requirements

## Executive Summary

This module automates the calculation and reporting of the **Liquidity Coverage Ratio (LCR)** for Swiss banks, a mandatory regulatory filing under **FINMA Circular 2015/2** and the **Liquidity Ordinance (LiqV)**. The solution provides real-time liquidity monitoring, automated compliance alerting, and AI-powered analytics to support Treasury operations and regulatory submissions.

**Regulatory Basis**: FINMA Circular 2015/2, LiqV Art. 14-20, Basel III LCR Framework  

---

## Business Objectives

### Primary Goals
1. **Regulatory Compliance**: Automate quarterly LCR submissions to Swiss National Bank (SNB)
2. **Risk Management**: Daily monitoring of liquidity position against 100% minimum threshold
3. **Early Warning**: Automated alerts for potential breaches before they occur
4. **Operational Efficiency**: Eliminate manual spreadsheet calculations and reduce reporting time from days to hours
5. **Audit Trail**: Complete data lineage from source systems to regulatory submission

### Key Stakeholders
- **Treasury Department**: Daily liquidity monitoring and funding decisions
- **Risk Management**: Compliance oversight and stress testing
- **Finance**: Monthly board reporting and quarterly SNB submissions
- **Audit & Compliance**: Regulatory examination support
- **Executive Management**: Strategic liquidity planning

---

## Regulatory Context

### Legal Framework
- **Liquidity Ordinance (LiqV)**: Articles 14-20 define HQLA and outflow calculations
- **FINMA Circular 2015/2**: "Liquidity risks - banks" - operational requirements
- **Basel III Framework**: International LCR standard (100% minimum)
- **SNB Survey LCR_P**: Quarterly submission requirement

### Key Requirements
| Requirement | Specification | Business Impact |
|------------|---------------|-----------------|
| **Minimum LCR** | 100% | Banks must hold sufficient liquid assets to survive 30-day stress scenario |
| **Reporting Frequency** | Monthly (internal) / Quarterly (SNB) | Continuous monitoring vs. periodic submission |
| **Data Timeliness** | T+1 (next business day) | Daily positions must be reconciled by end of next day |
| **Stress Scenario** | 30-day stressed outflows | Conservative assumptions for deposit withdrawals |
| **Accuracy Threshold** | <1% error tolerance | High data quality required for regulatory acceptance |

---

## Business Logic Overview

### The LCR Formula

```
LCR = (Stock of High-Quality Liquid Assets / Net Cash Outflows over 30 days) × 100%
```

**Compliance Thresholds**:
- **≥ 100%**: PASS (Fully compliant)
- **95-99%**: WARNING (Immediate action required)
- **< 95%**: FAIL (Regulatory breach - report to FINMA within 24 hours)

---

## High-Quality Liquid Assets (HQLA) - Numerator

### Asset Classification

Banks hold various liquid assets, but only certain types qualify as HQLA under FINMA rules. These are classified into three levels with different "haircuts" (discounts):

#### Level 1 Assets (0% haircut - full value counts)
- **Cash reserves at Swiss National Bank**
- **Physical cash in vaults**
- **Swiss Confederation bonds** (sovereign debt)
- **Foreign government bonds** (only AA- or better rating)

**Business Rule**: Level 1 assets have no discount - CHF 100M counts as CHF 100M HQLA

#### Level 2A Assets (15% haircut - 85% of value counts)
- **Canton bonds** (with federal guarantee)
- **Covered bonds / Pfandbriefe** (Swiss mortgage bonds)

**Business Rule**: CHF 100M of canton bonds counts as CHF 85M HQLA

#### Level 2B Assets (50% haircut - only half of value counts)
- **Swiss Market Index (SMI) equities** (only SMI constituents qualify)
- **High-quality corporate bonds** (AA- or better, non-financial)

**Business Rule**: CHF 100M of SMI equities counts as CHF 50M HQLA

### The 40% Cap Rule (Critical Business Rule)

**Regulatory Constraint**: Level 2 assets (2A + 2B combined) cannot exceed 40% of total HQLA.

**Mathematical expression**: Level 2 ≤ 2/3 × Level 1

**Business Impact**: 
- Banks cannot rely predominantly on lower-quality liquid assets
- Forces diversification into government bonds and cash
- If cap is breached, excess Level 2B is discarded first, then Level 2A

**Example**:
- Level 1: CHF 150M → Maximum Level 2 allowed = CHF 100M (2/3 × 150M)
- If actual Level 2 = CHF 120M → CHF 20M is discarded from HQLA calculation
- This can significantly impact the LCR ratio and requires active management

### Eligibility Exclusions
- Bonds maturing within 30 days (insufficient liquidity horizon)
- Non-SMI equities (too volatile or illiquid)
- Structured products, derivatives, securitizations
- Corporate bonds rated below AA- (credit risk too high)

---

## Net Cash Outflows - Denominator

### Deposit Run-off Rates

In a stress scenario, banks assume different percentages of deposits will be withdrawn within 30 days:

| Customer Segment | Run-off Rate | Business Rationale |
|-----------------|-------------|-------------------|
| **Retail - Stable** | 5% | Salary accounts, long-term relationships - customers unlikely to withdraw |
| **Retail - Insured** | 3% | Deposits up to CHF 100K protected by deposit insurance - even more stable |
| **Retail - Less Stable** | 10% | High-balance savings, weak relationships - higher flight risk |
| **Corporate - Operational** | 25% | Payroll and clearing accounts - needed for business operations |
| **Corporate - Non-Operational** | 40% | Treasury deposits - can be withdrawn quickly |
| **Financial Institutions** | 100% | Bank-to-bank deposits - assume full withdrawal in stress |
| **Wholesale Funding** | 100% | Non-operational unsecured funding - full outflow expected |

### Relationship Adjustments (Risk Mitigation)

Banks can apply **discounts** (lower run-off rates) for deep customer relationships:

| Relationship Factor | Adjustment | Business Logic |
|--------------------|-----------|----------------|
| **3+ active products** | -2% | Customers with checking + savings + investment less likely to leave |
| **Direct debit mandate** | -1% | Salary/pension direct deposit indicates strong commitment |
| **Tenure < 18 months** | +5% penalty | New customers are higher flight risk |

**Example**:
- Base rate: 5% (Retail Stable)
- Customer has 4 products: -2% → 3%
- Has direct debit: -1% → 2%
- Final run-off rate: 2% (vs. 5% base)

**Business Benefit**: Recognizes value of relationship banking and rewards customer retention efforts

---

## Solution Architecture (Business View)

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    SOURCE SYSTEMS                           │
│  ┌──────────────────┐        ┌──────────────────┐           │
│  │ Treasury System  │        │ Core Banking     │           │
│  │ (HQLA Holdings)  │        │ (Deposits)       │           │
│  └────────┬─────────┘        └────────┬─────────┘           │
└───────────┼───────────────────────────┼─────────────────────┘
            │                           │
            │         Daily Extract (T+1)
            │                           │
┌───────────▼───────────────────────────▼─────────────────────┐
│  LAYER 1: RAW DATA STORAGE (Snowflake)                      │
│  ├─ HQLA Holdings (securities positions)                    │
│  ├─ Deposit Balances (account balances)                     │
│  └─ Reference Data (asset types, run-off rates)             │
└───────────┬───────────────────────────┬─────────────────────┘
            │                           │
            │    Automated Calculation (60-min refresh)
            │                           │
┌───────────▼───────────────────────────▼─────────────────────┐
│  LAYER 2: CALCULATION ENGINE                                │
│  ├─ Apply haircuts to HQLA                                  │
│  ├─ Apply 40% cap rule                                      │
│  ├─ Calculate deposit outflows                              │
│  └─ Apply relationship discounts                            │
└───────────┬───────────────────────────┬─────────────────────┘
            │                           │
            │         LCR = HQLA / Outflows × 100%
            │                           │
┌───────────▼───────────────────────────▼─────────────────────┐
│  LAYER 3: REPORTING & ANALYTICS                             │
│  ├─ Daily LCR calculation                                   │
│  ├─ 90-day trend analysis                                   │
│  ├─ Automated breach alerts                                 │
│  ├─ Monthly summary reports                                 │
│  └─ SNB XML export (quarterly submission)                   │
└───────────┬───────────────────────────┬─────────────────────┘
            │                           │
┌───────────▼───────────────────────────▼─────────────────────┐
│  LAYER 4: CONSUMPTION LAYER                                 │
│  ├─ 📊 Executive Dashboard (Streamlit)                      │
│  ├─ 🤖 AI Agent (natural language queries)                  │
│  ├─ 📧 Email Alerts (breach notifications)                  │
│  └─ 📄 SNB Quarterly Report                                 │
└─────────────────────────────────────────────────────────────┘
```

## Deliverables

### 1. Database Schemas
- **RAW Layer**: Ingest and store daily positions
- **Calculation Layer**: Apply business rules (haircuts, cap rule, run-offs)
- **Reporting Layer**: Final LCR metrics, trend analysis, alerts
- **Semantic Layer**: AI-ready data views for natural language querying

### 2. Automated Calculation Engine
- Applies all FINMA business rules automatically
- 60-minute refresh cycle (near real-time monitoring)
- Handles multi-currency positions with FX conversion
- Tracks data lineage for audit compliance

### 3. Interactive Dashboard (Snowflake Notebook)
**The 5 Key Sections**:
1. **Current LCR Status**: Today's ratio with color-coded compliance (GREEN/YELLOW/RED)
2. **Trend Analysis**: 90-day historical chart with moving averages
3. **HQLA Breakdown**: Composition by level and asset type
4. **Outflow Analysis**: Breakdown by customer segment
5. **Monthly Summary**: SNB submission preparation

### 4. AI-Powered Analytics (Cortex AI Agent)
Natural language interface for LCR queries:
- "What is our current LCR ratio?"
- "Show me HQLA breakdown by level. Is the 40% cap applied?"
- "What are the deposit outflows by customer segment?"
- "Are there any breach alerts or high volatility warnings?"

### 5. Automated Alerting System
**Real-time notifications for**:
- LCR drops below 105% (warning threshold)
- LCR drops below 100% (regulatory breach)
- Daily swing exceeds 10 percentage points
- 40% cap rule triggered
- Data quality issues detected

### 6. Synthetic Data Generator (Python)
Generates realistic test data for:
- 8 HQLA asset types with proper credit ratings
- 7 deposit types with customer relationships
- Multi-currency support (CHF, EUR, USD, GBP)
- Time-series data (1-365 days)
- Configurable volumes for testing

### 7. Documentation
- Business requirements (this document)
- Technical implementation guide
- User manual for Treasury team
- Audit trail documentation
- Regulatory mapping (FINMA Circular 2015/2)

---

## Business Value & Benefits

### Operational Benefits
| Benefit | Before (Manual) | After (Automated) | Impact |
|---------|----------------|-------------------|---------|
| **Calculation Time** | 2-3 days | 60 minutes | 95% faster |
| **Data Accuracy** | ~95% (manual errors) | 99.9% (automated) | Audit-ready |
| **Breach Detection** | Retrospective (after breach) | Proactive (predictive alerts) | Risk reduction |
| **Reporting Effort** | 40 hours/quarter | 2 hours/quarter | 95% effort reduction |
| **Audit Preparation** | Days (reconstruct calculations) | Minutes (full lineage) | Compliance-ready |

### Strategic Benefits
1. **Regulatory Confidence**: Demonstrates sophisticated liquidity risk management to FINMA
2. **Risk Mitigation**: Early warning system prevents regulatory breaches
3. **Cost Optimization**: Reduces need for excess liquidity buffer through precise monitoring
4. **Business Insights**: AI analytics reveal funding strategy opportunities
5. **Competitive Advantage**: Showcase of advanced analytics and AI integration

### Showcase Features (Technical Excellence)
1. **Production-Grade Regulatory Engineering**: Complex 40% cap rule with spillover logic
2. **AI Integration**: Natural language querying via Snowflake Cortex
3. **Real-Time Monitoring**: Dynamic tables with automated refresh
4. **Multi-Layer Architecture**: Clean separation of RAW → AGG → REP → SEMANTIC layers
5. **Data Quality Framework**: 5 automated validation checks with alerting
6. **Compliance-First Design**: Built-in audit trail and regulatory mapping

---

## Key Metrics & KPIs

### Regulatory Compliance Metrics
- **LCR Ratio**: Target ≥ 110% (10% buffer above minimum)
- **Breach Days**: Target = 0 days per year
- **Volatility**: Target < 5% day-over-day change
- **Data Quality**: Target > 99.5% accuracy

### Operational Metrics
- **Report Generation Time**: Target < 2 hours
- **System Availability**: Target > 99.9%
- **Alert Response Time**: Target < 1 hour
- **SNB Submission**: On-time 100% (quarterly deadline)

---

## Success Criteria

### Must-Have (Go-Live Requirements)
- [ ] LCR calculation matches manual validation (±0.1%)
- [ ] 40% cap rule applies correctly in all scenarios
- [ ] Daily data refresh completes within SLA (60 minutes)
- [ ] Breach alerts trigger within 5 minutes of detection
- [ ] SNB XML export passes format validation
- [ ] Dashboard accessible to all Treasury users

### Nice-to-Have (Post-Go-Live Enhancements)
- [ ] Integration with existing Streamlit app (`the_bank_app`)
- [ ] Historical trend analysis (2+ years)
- [ ] Scenario analysis tool (stress testing)
- [ ] Mobile dashboard for executives
- [ ] API integration with Treasury Management System

---

## Regulatory References

### Primary Sources
1. **FINMA Circular 2015/2**: "Liquidity risks - banks"
   - Link: https://www.finma.ch/en/documentation/circulars/
2. **Liquidity Ordinance (LiqV)**: Articles 14-20
   - Link: https://www.admin.ch/gov/de/start/bundesrecht.html
3. **Basel III LCR Framework**: Basel Committee on Banking Supervision
   - Link: https://www.bis.org/bcbs/publ/d295.htm
4. **SNB Survey Specifications**: LCR_P Quarterly Filing
   - Link: https://data.snb.ch/en/surveys

### Industry Best Practices
- Swiss Bankers Association (SBA): Liquidity Risk Management Guidelines
- FINMA: Supervisory Review Process (SREP) expectations
- EBA: Guidelines on LCR disclosure requirements

---

## Future Enhancements (Roadmap)

### Short Term (6 months)
- Intraday LCR monitoring (3 snapshots per day)
- Integration with market data feeds (real-time bond prices)
- What-if scenario analysis tool
- Enhanced mobile dashboard

### Medium Term (12 months)
- Net Stable Funding Ratio (NSFR) module
- Stress testing framework (FINMA scenarios)
- Integration with BCBS 239 compliance reporting
- Advanced AI predictions (LCR forecasting)

### Long Term (24 months)
- Full FINMA reporting suite (liquidity, capital, credit)
- Real-time regulatory reporting (regulatory data lake)
- Blockchain-based audit trail
- Cross-border liquidity management (multi-entity)

---
