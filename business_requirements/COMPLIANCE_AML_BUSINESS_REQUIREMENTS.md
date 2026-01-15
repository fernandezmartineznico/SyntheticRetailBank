# Business Requirements Specification: Compliance & AML Framework for EMEA Retail Banking

## Document Control

| Attribute | Value |
|-----------|-------|
| **Document Title** | Compliance & Anti-Money Laundering (AML) Framework - Business Requirements |
| **Document Version** | 1.0 |
| **Last Updated** | January 2026 |
| **Document Owner** | Chief Compliance Officer |
| **Business Sponsor** | Head of Compliance & Regulatory Affairs |
| **Target Audience** | Board of Directors, Executive Management, Compliance Officers, Internal Audit, Regulators |
| **Regulatory Scope** | EMEA (Switzerland, EU, UK, Germany, France, Italy, Austria, Netherlands, Nordics) |

---

## 1. Executive Summary

### 1.1 Business Context

Financial institutions operating across EMEA jurisdictions face an increasingly complex compliance landscape with stringent **Anti-Money Laundering (AML)**, **Counter-Terrorist Financing (CTF)**, **Know Your Customer (KYC)**, and **Sanctions** requirements. Failure to comply results in:

- **Enforcement Actions**: Fines ranging from CHF 100K to EUR 500M+ (Credit Suisse CHF 240M fine 2018, ING Bank EUR 775M fine 2018)
- **License Restrictions**: Operating bans in specific jurisdictions
- **Reputational Damage**: Loss of customer and investor confidence
- **Criminal Liability**: Personal liability for directors and compliance officers

This specification defines a **unified Compliance & AML Framework** that ensures compliance across all EMEA jurisdictions while enabling **operational efficiency**, **real-time risk visibility**, and **regulatory confidence**.

### 1.2 Strategic Business Objectives

| Objective | Business Value | Success Metric |
|-----------|---------------|----------------|
| **Regulatory Compliance** | Zero material breaches, no enforcement actions | 100% compliance with all EMEA regulations |
| **Operational Excellence** | Reduce manual effort by 70%, accelerate customer onboarding | KYC processing time < 24h (low risk) |
| **Risk Mitigation** | Early detection of suspicious activity, proactive risk management | False positive rate < 5%, zero sanctions breaches |
| **Business Enablement** | Support cross-border expansion with scalable compliance | Onboard new jurisdictions in < 90 days |
| **Cost Optimization** | Consolidate fragmented compliance tools, reduce vendor costs | 30% reduction in compliance technology spend |

### 1.3 Implementation Status

The framework leverages existing capabilities implemented in **Snowflake Notebooks** with extensions for EMEA-wide coverage:

| Capability | Current Implementation | Coverage | Gap Analysis |
|-----------|----------------------|----------|--------------|
| **Sanctions Screening** | ✅ [sanctions_embargo_control.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/sanctions_embargo_control.ipynb) | OFAC, EU, UN, UK, CH | Missing: National lists (BaFin, AFM, CSSF) |
| **KYC & Customer Screening** | ✅ [customer_screening_kyc.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/customer_screening_kyc.ipynb) | PEP screening, risk classification | Missing: Beneficial ownership registry (UBO) |
| **Compliance Risk Management** | ✅ [compliance_risk_management.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/compliance_risk_management.ipynb) | Enterprise risk dashboard | Missing: Regulatory breach incident management |
| **Transaction Monitoring** | ✅ [aml_transaction_monitoring.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/aml_transaction_monitoring.ipynb) | Alert management, SAR filing | Missing: Cross-border reporting (FIU integration) |
| **Golden Record & MDM** | ⚠️ Partial (AGG layer exists) | Data architecture established | Missing: Reconciliation jobs, conflict resolution UI, formal policy |

---

## 2. Regulatory Framework & EMEA Mapping

### 2.1 Primary Regulatory Drivers

This framework satisfies the following **EMEA regulatory pillars**:

#### 🇨🇭 **Switzerland**
- **AMLA (Anti-Money Laundering Act)**: Customer due diligence, beneficial owner identification, record keeping (Art. 3-7)
- **AMLO-FINMA (AML Ordinance)**: Enhanced due diligence for PEPs, high-risk jurisdictions, correspondent banking (Art. 13-23)
- **SECO Sanctions Lists**: Swiss-specific embargoes and asset freezes (State Secretariat for Economic Affairs)
- **FINMA Circular 2016/7**: Client identification and beneficial ownership verification
- **MROS Reporting**: Suspicious Activity Reports to Money Laundering Reporting Office Switzerland (Art. 9 AMLA)

#### 🇪🇺 **European Union**
- **6AMLD (6th Anti-Money Laundering Directive)**: Criminal liability for legal entities, extended predicate offenses (Directive 2018/1673)
- **GDPR (General Data Protection Regulation)**: Personal data processing for AML purposes (Art. 6, 9, Recital 41)
- **EBA Guidelines on AML/CFT Risk Factors**: Risk-based approach, simplified vs. enhanced due diligence (EBA/GL/2021/02)
- **EU Sanctions Regime**: Common Foreign and Security Policy (CFSP) asset freezes and restrictive measures
- **FATF Recommendations**: Financial Action Task Force 40 Recommendations (global standard, EU implementation)

#### 🇬🇧 **United Kingdom**
- **MLR 2017 (Money Laundering Regulations)**: Enhanced due diligence for high-risk jurisdictions, PEPs (Reg. 33-35)
- **Proceeds of Crime Act 2002 (POCA)**: Suspicious Activity Reports (SARs) to National Crime Agency (NCA)
- **OFSI Sanctions**: Office of Financial Sanctions Implementation licensing regime
- **FCA Handbook (SYSC 3/6)**: Systems and controls for financial crime, senior management accountability

#### 🇩🇪 **Germany**
- **GwG (Geldwäschegesetz)**: German AML Act, customer due diligence, beneficial ownership (§ 10-18)
- **BaFin Circular 3/2020**: Minimum requirements for compliance, risk-based approach
- **Transparenzregister**: Central beneficial ownership register (§ 20-28 GwG)
- **AWG (Außenwirtschaftsgesetz)**: Export control and sanctions enforcement

#### 🇫🇷 **France**
- **Monetary and Financial Code (L561-1 to L574-3)**: AML obligations, customer due diligence
- **AMF Regulations**: Financial markets authority compliance requirements
- **TRACFIN Reporting**: Financial Intelligence Unit suspicious transaction reporting
- **LCB-FT (Lutte Contre le Blanchiment)**: French AML/CFT framework

#### 🇮🇹 **Italy**
- **Legislative Decree 231/2007**: Italian AML framework (transposition of EU directives)
- **Bank of Italy Provisions**: Customer due diligence, organizational requirements
- **UIF Reporting**: Financial Intelligence Unit (Unità di Informazione Finanziaria) reporting

#### 🇳🇱 **Netherlands**
- **Wwft (Wet ter voorkoming van witwassen)**: Dutch AML Act, customer verification, UBO registry
- **DNB Guidance**: De Nederlandsche Bank supervisory expectations
- **FIU-Nederland Reporting**: Unusual transaction reporting obligations

#### 🇦🇹 **Austria**
- **FM-GwG (Finanzmarkt-Geldwäschegesetz)**: Financial Market AML Act
- **FMA Guidelines**: Austrian Financial Market Authority compliance expectations
- **A-FIU Reporting**: Austrian Financial Intelligence Unit reporting

#### 🇸🇪 🇩🇰 🇳🇴 **Nordic Countries**
- **Sweden**: Penningtvättslagen (2017:630) - AML Act, Finansinspektionen supervision
- **Denmark**: Hvidvaskloven - Danish AML Act, Finanstilsynet oversight
- **Norway**: Hvitvaskingsloven - Norwegian AML Act, Finanstilsynet compliance requirements

### 2.2 Cross-Jurisdictional Harmonization

| Requirement Area | EU Harmonized | UK Post-Brexit | Swiss Alignment | Implementation Approach |
|-----------------|---------------|----------------|-----------------|------------------------|
| **Customer Due Diligence** | ✅ Yes (6AMLD) | ✅ MLR 2017 aligned | ⚠️ Equivalence regime | Single EU/EEA process + Swiss adaptations |
| **PEP Screening** | ✅ Yes (EBA Guidelines) | ✅ FCA aligned | ✅ FINMA aligned | Unified global PEP database |
| **Sanctions Lists** | ❌ No (EU + National) | ❌ OFSI independent | ❌ SECO independent | Multi-list screening engine |
| **SAR Reporting** | ❌ No (National FIUs) | ❌ NCA (UK) | ❌ MROS (CH) | Jurisdiction-specific reporting workflows |
| **Record Retention** | ⚠️ Partial (5-10 years) | ✅ 5 years (POCA) | ✅ 10 years (AMLA) | 10-year global retention policy |

---

## 3. Business Requirements (Functional)

### BR-01: Customer Due Diligence (CDD) & Know Your Customer (KYC)

#### BR-01.1 Customer Identification & Verification
**Objective**: No business relationship shall be established without verified identity per AMLA Art. 3, 6AMLD Art. 13, GwG § 11.

**Business Rules**:
- **Individual Customers**: Government-issued ID (passport, national ID), proof of address (utility bill < 3 months)
- **Corporate Customers**: Certificate of incorporation, shareholder registry, UBO declaration (Form A/B)
- **Verification Method**: 
  - **In-Person**: Branch officer verification with photocopy retention
  - **Remote**: Video identification (qualified electronic signature) per eIDAS Regulation
  - **Third-Party Reliance**: Due diligence by regulated entities within EEA (6AMLD Art. 25)

**Regulatory References**:
- FINMA Circular 2016/7, Art. 3-5 (Switzerland)
- 6AMLD Art. 13, EBA Guidelines GL/2021/02 (EU)
- MLR 2017 Reg. 28 (UK)

**Implementation Status**: ✅ **IMPLEMENTED** in [customer_screening_kyc.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/customer_screening_kyc.ipynb)
- Customer risk segmentation dashboard
- PEP screening against global databases
- Risk classification (Critical/High/Medium/Low)

**Gaps**:
- ❌ UBO (Ultimate Beneficial Owner) registry integration (Transparenzregister DE, FINMA Art. 5a CH)
- ❌ Automated Form A/B generation for corporate clients
- ❌ Video identification workflow (eIDAS qualified signature)

#### BR-01.2 Risk-Based Approach & Enhanced Due Diligence (EDD)
**Objective**: Apply proportionate due diligence based on risk classification per FATF Recommendation 10.

**Risk Classification Matrix**:

| Customer Segment | Country Risk | PEP Status | Expected Annual Turnover | Due Diligence Level | Review Frequency |
|-----------------|--------------|------------|--------------------------|---------------------|------------------|
| **Low Risk** | Low-risk FATF compliant | No | < CHF 100K | Standard (SDD) | 5 years |
| **Medium Risk** | Medium-risk jurisdiction | No | CHF 100K-1M | Standard (SDD) | 3 years |
| **High Risk** | High-risk jurisdiction | Yes (Domestic PEP) | CHF 1M-10M | Enhanced (EDD) | Annual |
| **Critical Risk** | FATF blacklist/graylist | Yes (Foreign PEP) | > CHF 10M | Enhanced (EDD) | Continuous |

**Enhanced Due Diligence Triggers** (AMLO-FINMA Art. 13, EBA GL/2021/02):
1. **Politically Exposed Persons (PEPs)**: Senior officials, close associates, family members
2. **High-Risk Jurisdictions**: FATF blacklist, EU high-risk third countries, SECO sanctions
3. **Correspondent Banking**: Cross-border banking relationships (6AMLD Art. 24)
4. **Cash-Intensive Businesses**: Money services, casinos, precious metal dealers
5. **Complex Structures**: Trusts, foundations, bearer shares (prohibited in Switzerland since 2019)

**EDD Requirements**:
- Senior management approval (Board for Foreign PEPs)
- Source of wealth verification (tax returns, audited financials, inheritance documents)
- Purpose of business relationship documentation
- Enhanced transaction monitoring (24-month baseline establishment)
- Ongoing media monitoring (Adverse Media screening)

**Regulatory References**:
- AMLO-FINMA Art. 13-23 (Switzerland)
- 6AMLD Art. 18-19, EBA Guidelines GL/2021/02 (EU)
- MLR 2017 Reg. 33-35 (UK)

**Implementation Status**: ✅ **IMPLEMENTED** in [customer_screening_kyc.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/customer_screening_kyc.ipynb)
- Risk segmentation based on customer attributes
- PEP identification and flagging
- Geographic risk concentration analysis

**Gaps**:
- ❌ Source of wealth documentation workflow
- ❌ Senior management approval workflow for high-risk onboarding
- ❌ Adverse Media screening integration (Dow Jones, LexisNexis)

#### BR-01.3 Beneficial Ownership Identification (UBO)
**Objective**: Identify and verify natural persons who ultimately own or control corporate entities per 4AMLD Art. 3(6), FINMA Art. 5a.

**UBO Definition** (FATF Recommendation 24, 6AMLD):
- Natural person who ultimately **owns** > 25% of shares/voting rights
- Natural person who **controls** the entity through other means (management, financing)
- If no UBO identified above 25% threshold: **Senior Managing Official** (CEO, CFO)

**UBO Verification Requirements**:
- **Form A**: Swiss UBO declaration (FINMA template)
- **Form B**: Foreign entity declaration (FINMA template)
- **Supporting Documents**: Shareholder registry, trust deed, partnership agreement
- **Transparency Register**: Mandatory registration in national UBO registries (Germany, Netherlands, France)

**Complex Structures**:
- **Trusts**: Settlor, trustee, protector, beneficiaries (all identified per 5AMLD)
- **Foundations**: Founder, board members, beneficiaries
- **Bearer Shares**: Prohibited in Switzerland (abolition 2019), high risk in other jurisdictions
- **Multi-Tier Holdings**: Cascade UBO analysis through holding structures

**Regulatory References**:
- FINMA Circular 2016/7, Art. 5a (Switzerland)
- 5AMLD Art. 30-31, 6AMLD Art. 3(6) (EU)
- MLR 2017 Reg. 5, 28, 36 (UK)
- GwG § 20-28 Transparenzregister (Germany)

**Implementation Status**: ❌ **NOT IMPLEMENTED** - Critical Gap
**Required Implementation**:
- UBO registry integration (Transparenzregister DE, Companies House UK, FINMA register CH)
- Form A/B digital workflow with e-signature
- UBO verification evidence storage (10-year retention)
- Cascade UBO analysis for multi-tier structures

---

### BR-02: Sanctions & Embargo Screening

#### BR-02.1 Real-Time Sanctions Screening
**Objective**: Prevent transactions involving sanctioned individuals, entities, or jurisdictions per UN Resolution 1373, EU CFSP, SECO Ordinances.

**Screening Universe**:

| List Source | Jurisdiction | Update Frequency | Legal Obligation | Breach Penalty |
|------------|--------------|------------------|------------------|----------------|
| **OFAC SDN** | USA (extraterritorial) | Daily | Yes (global USD clearing) | Up to USD 20M per violation |
| **EU Consolidated List** | European Union | Daily | Yes (EU operations) | Unlimited fines, criminal liability |
| **UN Security Council** | Global | Weekly | Yes (all member states) | Diplomatic sanctions |
| **UK OFSI** | United Kingdom | Daily | Yes (UK operations) | Up to GBP 1M or 50% of transaction |
| **SECO Sanctions** | Switzerland | Daily | Yes (CH operations) | CHF 10M or 5 years imprisonment |
| **National Lists** | BaFin (DE), AFM (NL), etc. | Weekly | Jurisdiction-specific | Per national law |

**Screening Touchpoints**:
1. **Customer Onboarding**: Name, DOB, nationality, address against all lists
2. **Periodic Re-Screening**: Daily batch screening of entire customer base
3. **Transaction Screening**: Real-time pre-settlement screening (payment messages, SWIFT, card transactions)
4. **Beneficial Owner Screening**: UBO/shareholder screening for corporate entities
5. **Counterparty Screening**: SWIFT message field screening (Ordering Customer, Beneficiary)

**Fuzzy Matching Logic**:
- **Exact Match (100%)**: Immediate "Hard Block" (transaction rejected)
- **High Confidence (90-99%)**: Manual review within 1 hour, potential block
- **Medium Confidence (70-89%)**: Manual review within 4 hours, monitoring
- **Low Confidence (< 70%)**: False positive, dismiss with documentation

**Matching Criteria**:
- Name similarity (Levenshtein distance, phonetic matching)
- Date of birth (exact, +/- 1 day tolerance for data errors)
- Nationality/Citizenship
- ID number (passport, national ID)
- Address (country, city)

**Regulatory References**:
- SECO Embargoes Ordinance (SR 946.231, Switzerland)
- EU Regulation 833/2014 (Russia sanctions)
- UK Sanctions and Anti-Money Laundering Act 2018
- OFAC 31 CFR Part 501-598 (USA)

**Implementation Status**: ✅ **IMPLEMENTED** in [sanctions_embargo_control.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/sanctions_embargo_control.ipynb)
- Multi-list screening (OFAC, EU, UN, UK, CH)
- Screening effectiveness dashboard
- Sanctions hit management
- List update tracking

**Gaps**:
- ❌ National list integration (BaFin, AFM, DNB, FMA)
- ❌ Real-time SWIFT message screening (pre-settlement blocking)
- ❌ Automated list update ingestion (currently manual)
- ❌ False positive machine learning optimization

#### BR-02.2 Asset Freeze & Fund Blocking
**Objective**: Immediately freeze assets and block transactions upon sanctions match per Art. 2-4 SECO Ordinance, EU Regulation 2580/2001.

**Blocking Requirements**:
- **Hard Block**: 100% sanctions match → Immediate transaction rejection
- **Asset Freeze**: Freeze all accounts/assets of sanctioned customer within 4 hours of identification
- **Regulatory Notification**: Report to SECO (CH), OFSI (UK), or national authority within 24 hours
- **License Application**: Apply for license to release humanitarian funds (SECO Art. 9-11)
- **Record Retention**: Maintain blocking records for 10 years (AMLA Art. 7)

**Business Impact**:
- **Customer Communication**: Cannot inform customer of blocking (tipping off prohibition)
- **Reputational Risk**: Board notification for any sanctions breach
- **Legal Risk**: Personal liability for compliance officer if breach not reported

**Regulatory References**:
- SECO Embargoes Ordinance Art. 2-4 (Switzerland)
- EU Regulation 2580/2001 Art. 2 (Asset Freeze)
- MLR 2017 Reg. 18-21 (UK)

**Implementation Status**: ⚠️ **PARTIAL** - Screening implemented, blocking workflow manual
**Required Implementation**:
- Automated asset freeze workflow upon 100% match
- SECO/OFSI reporting automation (secure portal integration)
- License application workflow for humanitarian payments
- Customer account freeze notification (internal only)

---

### BR-03: Transaction Monitoring & Suspicious Activity Reporting

#### BR-03.1 Automated Transaction Monitoring (TM)
**Objective**: Detect money laundering, terrorist financing, and fraud patterns per AMLA Art. 8, 6AMLD Art. 7, POCA 2002.

**Monitoring Scenarios** (Based on FATF Recommendations, EBA Guidelines):

| Scenario ID | Typology | Detection Logic | Investigation Priority | SAR Threshold |
|-------------|----------|-----------------|------------------------|---------------|
| **TM-01** | **Structuring (Smurfing)** | Multiple deposits < CHF 10K totaling > CHF 15K within 3 days | High | 70% confidence |
| **TM-02** | **Velocity** | > 200% increase in monthly transaction volume vs. baseline | Medium | Manual review |
| **TM-03** | **Round-Amount Transactions** | Repeated transactions in round amounts (CHF 5,000, 10,000, 50,000) | Low | Pattern analysis |
| **TM-04** | **Rapid Movement of Funds** | Deposits followed by immediate wire transfers within 24 hours | High | 80% confidence |
| **TM-05** | **High-Risk Jurisdiction** | Transactions to/from FATF graylist/blacklist countries | High | Any amount |
| **TM-06** | **Dormant Account Reactivation** | No activity > 12 months, then sudden large transaction | Medium | > CHF 25K |
| **TM-07** | **Cash Concentration** | > CHF 20K cash deposits per month for non-cash-intensive business | Medium | Pattern analysis |
| **TM-08** | **Cross-Border Wire Transfers** | > CHF 100K cross-border transfers without clear business purpose | High | Manual review |
| **TM-09** | **Third-Party Payments** | Payments to third parties not previously disclosed in CDD | Medium | > CHF 50K |
| **TM-10** | **Loan Repayment (Early)** | Loan repaid within 30 days of disbursement from unexplained source | High | Any amount |

**Baseline Establishment**:
- **Onboarding Baseline**: Expected transaction volume, geographies, counterparties declared during KYC
- **Behavioral Baseline**: 6-month historical pattern for existing customers
- **Peer Group Baseline**: Industry/segment average for comparison

**Alert Investigation Process**:
1. **L1 Screening (15 min)**: Automated false positive filtering (known counterparties, seasonal patterns)
2. **L2 Investigation (45 min)**: Analyst reviews transaction details, customer profile, CDD documentation
3. **L3 Escalation (2-4 hours)**: Compliance officer enhanced review, external database checks
4. **Disposition Decision**:
   - **Close (False Positive)**: Document rationale, retain records 5 years
   - **Monitor**: Enhanced surveillance for 90 days, re-evaluate
   - **Escalate to SAR/STR**: File suspicious activity report to FIU

**Regulatory References**:
- AMLA Art. 8, AMLO-FINMA Art. 24-28 (Switzerland)
- 6AMLD Art. 7, EBA Guidelines GL/2021/02 (EU)
- POCA 2002 s.330-332, MLR 2017 Reg. 46 (UK)

**Implementation Status**: ✅ **IMPLEMENTED** in [aml_transaction_monitoring.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/aml_transaction_monitoring.ipynb)
- Alert volume & SAR filing metrics
- Alert backlog management
- SLA breach tracking
- Risk heatmaps by product, geography, channel

**Gaps**:
- ❌ Scenario #7 (Cash Concentration) - cash data not in model
- ❌ Scenario #10 (Early Loan Repayment) - loan data not integrated
- ❌ False positive machine learning tuning
- ❌ Integrated case management system for alert workflow

#### BR-03.2 Suspicious Activity Reporting (SAR/STR)
**Objective**: File suspicious activity reports with Financial Intelligence Units per AMLA Art. 9, POCA s.330, 6AMLD Art. 33.

**SAR Filing Obligations**:

| Jurisdiction | FIU | Filing Threshold | Filing Deadline | Tipping Off Prohibition | Penalties for Non-Filing |
|-------------|-----|------------------|-----------------|-------------------------|-------------------------|
| **Switzerland** | MROS | Any suspicion | As soon as possible | Yes (Art. 10a AMLA) | CHF 500K or 5 years imprisonment |
| **EU/EEA** | National FIUs | Any suspicion | Immediate | Yes (Art. 39 6AMLD) | EUR 5M or 10% turnover |
| **UK** | NCA (UKFIU) | Any suspicion | ASAP (< 10 days best practice) | Yes (s.333A POCA) | Unlimited fine, 5 years imprisonment |
| **Germany** | FIU Deutschland | Any suspicion | Immediate | Yes (§ 47 GwG) | EUR 150K or 2 years imprisonment |
| **France** | TRACFIN | Any suspicion | ASAP | Yes (L574-1 CMF) | EUR 22.5K or 3 years imprisonment |

**SAR Content Requirements** (FATF Recommendation 29):
- Customer identity (name, DOB, address, ID number)
- Transaction details (date, amount, currency, counterparty, purpose)
- Reason for suspicion (structured narrative explaining red flags)
- Supporting documentation (transaction logs, CDD files, investigation notes)
- Investigator identity and disposition rationale

**Tipping Off Prohibition**:
- **Cannot inform customer** of SAR filing or ongoing investigation
- **Cannot close account** immediately after SAR (suspicion alert)
- **Can terminate relationship** after FIU feedback or 90-day cooling-off period

**Quality Control**:
- **SAR Quality Review**: Compliance officer review before submission
- **Defensive Filing**: File SAR even if investigation inconclusive (risk mitigation)
- **FIU Feedback**: Track FIU follow-up requests and law enforcement outcomes

**Regulatory References**:
- AMLA Art. 9, 10a (Switzerland)
- 6AMLD Art. 33, 39 (EU)
- POCA 2002 s.330-333 (UK)
- GwG § 43-47 (Germany)

**Implementation Status**: ⚠️ **PARTIAL** - SAR metrics tracked, filing workflow manual
**Required Implementation**:
- Automated SAR form generation (jurisdiction-specific templates)
- Secure FIU portal integration (goAML, MROS portal, NCA system)
- Tipping off controls (prevent customer notification after SAR)
- FIU feedback tracking and case management

---

### BR-04: Compliance Risk Management & Governance

#### BR-04.1 Enterprise Compliance Risk Dashboard
**Objective**: Provide Board and Executive Management with real-time compliance risk visibility per FINMA Circular 2017/1, EBA Guidelines GL/2017/11.

**Board Reporting Requirements**:
- **Quarterly**: Compliance risk heatmap, KPI dashboard, regulatory breach tracker
- **Annual**: Compliance effectiveness attestation, independent audit findings
- **Ad-Hoc**: Material breaches, enforcement actions, regulatory inquiries

**Key Risk Indicators (KRIs)**:

| KRI ID | Metric | Target | Escalation Threshold | Board Escalation | Data Source |
|--------|--------|--------|---------------------|------------------|-------------|
| **KRI-01** | % Customers with Incomplete KYC | < 5% | > 10% | > 15% | CRM_AGG_001 |
| **KRI-02** | Average KYC Processing Time (Low Risk) | < 24h | > 48h | > 72h | Onboarding System |
| **KRI-03** | Sanctions Screening False Positive Rate | < 5% | > 10% | > 15% | Sanctions Engine |
| **KRI-04** | AML Alert Backlog (> 30 days overdue) | 0 | > 10 alerts | > 25 alerts | TM System |
| **KRI-05** | SAR Filing Rate (per 1,000 customers) | 0.5-2.0 | < 0.1 or > 5.0 | < 0.05 or > 10.0 | FIU Reports |
| **KRI-06** | PEP/High-Risk Customer Concentration | < 2% | > 5% | > 10% | Customer Screening |
| **KRI-07** | Regulatory Breach Incidents (Material) | 0 | 1 | 2+ | Incident Management |
| **KRI-08** | Compliance Training Completion Rate | > 95% | < 85% | < 75% | LMS |

**Regulatory References**:
- FINMA Circular 2017/1 (Corporate Governance - Switzerland)
- EBA Guidelines GL/2017/11 (Internal Governance - EU)
- FCA SYSC 3/6 (Systems and Controls - UK)

**Implementation Status**: ✅ **IMPLEMENTED** in [compliance_risk_management.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/compliance_risk_management.ipynb)
- Overall compliance risk profile dashboard
- Risk segmentation by category
- Geographic risk concentration
- High-risk customer tracking

**Gaps**:
- ❌ Automated KRI calculation and threshold alerting
- ❌ Board reporting automation (PDF export, executive summary)
- ❌ Regulatory breach incident tracking
- ❌ Remediation action tracker with SLA monitoring

#### BR-04.2 Three Lines of Defense Model
**Objective**: Establish clear accountability per Basel Committee Corporate Governance Principles, FINMA Circular 2017/1.

**Organizational Structure**:

| Line | Function | Responsibility | Escalation to Board | Independence |
|------|----------|---------------|-------------------|--------------|
| **1st Line** | Business Units | Own & manage risk, execute controls | Material breaches | Reports to CEO |
| **2nd Line** | Compliance Function | Set policy, monitor, challenge | Quarterly risk report | Reports to Board Risk Committee |
| **3rd Line** | Internal Audit | Independent assurance, test effectiveness | Annual audit plan, findings | Reports to Audit Committee |

**Compliance Function Responsibilities** (AMLO-FINMA Art. 3, 6AMLD Art. 8):
- **Policy & Procedures**: Develop and maintain AML/CFT policies, procedures, and controls
- **Risk Assessment**: Annual enterprise-wide ML/TF risk assessment (business-wide risk assessment - BWRA)
- **Monitoring & Testing**: Test effectiveness of controls, quality assurance of investigations
- **Training**: Deliver AML/CFT training to all staff (annual mandatory, role-based specialized)
- **Regulatory Liaison**: Interact with FINMA, FIUs, and other regulators
- **Reporting**: Report to Board Risk Committee, submit annual compliance attestation

**Compliance Officer Requirements**:
- **Qualification**: Certified AML specialist (CAMS, ICA, FINMA-recognized)
- **Experience**: Minimum 5 years AML/Compliance experience in financial services
- **Independence**: Direct reporting line to Board Risk Committee (no business line reporting)
- **Resources**: Adequate budget and headcount (industry benchmark: 1 FTE per 50-100 staff)

**Regulatory References**:
- AMLO-FINMA Art. 3 (Switzerland)
- 6AMLD Art. 8 (EU)
- MLR 2017 Reg. 21 (UK)

**Implementation Status**: ⚠️ **PARTIAL** - Risk dashboards exist, organizational model to be formalized
**Required Implementation**:
- Formalize 3LOD roles and responsibilities (RACI matrix)
- Compliance function charter approved by Board
- Annual enterprise-wide ML/TF risk assessment (BWRA)
- Compliance training program with completion tracking

---

## 4. Data Requirements

### 4.1 Master Data Elements

| Data Domain | Critical Fields | Business Rule | Regulatory Mandate | Source System | Data Quality SLA |
|------------|----------------|---------------|-------------------|---------------|-----------------|
| **Customer Identity** | CUSTOMER_ID, FIRST_NAME, FAMILY_NAME, DATE_OF_BIRTH, NATIONALITY | Mandatory, verified during onboarding | AMLA Art. 3, 6AMLD Art. 13 | CRM_RAW_001.CRMI_RAW_TB_CUSTOMER | 99.9% complete |
| **Customer Address** | STREET_ADDRESS, CITY, ZIPCODE, COUNTRY | Current and 5-year history | AMLA Art. 3, GwG § 11 | CRM_RAW_001.CRMI_RAW_TB_ADDRESSES | 99.5% complete |
| **Beneficial Owner** | UBO_NAME, UBO_DOB, UBO_OWNERSHIP_PCT | > 25% ownership threshold | FINMA Art. 5a, 5AMLD Art. 30 | **MISSING** - To be implemented | N/A |
| **PEP Status** | IS_PEP, PEP_CATEGORY, PEP_FUNCTION | Daily screening, version control | AMLO-FINMA Art. 13, EBA GL/2021/02 | Customer Screening | 100% coverage |
| **Risk Classification** | RISK_CLASSIFICATION, RISK_SCORE, LAST_REVIEW_DATE | Risk-based approach, annual review | FATF R.10, 6AMLD Art. 18 | Customer Screening | 100% coverage |
| **Sanctions Match** | SANCTIONS_HIT, MATCH_CONFIDENCE, DISPOSITION | Real-time screening, audit trail | SECO Ordinance, EU CFSP | Sanctions Engine | < 200ms latency |
| **Transaction** | TRANSACTION_ID, AMOUNT, CURRENCY, COUNTERPARTY | All transactions monitored | AMLA Art. 8, POCA s.330 | PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS | 100% capture |
| **Alert/SAR** | ALERT_ID, SCENARIO_ID, DISPOSITION, SAR_ID | Investigation workflow, 10-year retention | AMLA Art. 9, 6AMLD Art. 33 | PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES | 100% audit trail |

### 4.2 Data Lineage & Auditability

**Regulatory Requirement**: AMLA Art. 7, GDPR Art. 30, 6AMLD Art. 40
- **Record Retention**: 10 years from relationship termination (Swiss requirement, most stringent in EMEA)
- **Audit Trail**: All screening decisions, alert investigations, and dispositions must be logged
- **Data Lineage**: Track data provenance from source system to regulatory report
- **Right to Erasure**: GDPR exemption for AML/CFT purposes (Art. 17(3)(e)) - data retained despite erasure request

### 4.3 Data Privacy & Access Controls

**GDPR Compliance** (Regulation 2016/679):
- **Lawful Basis**: Processing necessary for compliance with legal obligation (Art. 6(1)(c))
- **Special Category Data**: Criminal convictions, sanctions data (Art. 10) - explicit safeguards required
- **Data Minimization**: Only collect data necessary for AML/CFT purpose (Art. 5(1)(c))
- **Access Controls**: Need-to-know basis, role-based access control (RBAC)
- **Data Transfer**: Standard Contractual Clauses (SCCs) for third-country transfers (e.g., OFAC screening in USA)

**Swiss FADP Compliance** (Federal Act on Data Protection):
- **Equivalence**: Swiss FADP recognized as equivalent to GDPR
- **Data Transfer**: No restrictions for intra-EEA/Switzerland transfers
- **Transparency**: Privacy notice to customers explaining AML/CFT data usage

### 4.4 Golden Record & Master Data Management (MDM)

#### 4.4.1 The Golden Record Problem

**Business Risk**: In multi-system compliance architectures, the same customer attribute (e.g., PEP status, risk classification, sanctions match) may exist in multiple systems with **conflicting values**. This creates:

- **Regulatory Breach Risk**: Customer flagged as PEP in screening system but treated as low-risk in transaction monitoring
- **Audit Findings**: Regulators discover discrepancies during inspections (common FINMA/BaFin finding)
- **Operational Inefficiency**: Manual reconciliation effort, duplicate investigations
- **Legal Liability**: Compliance officer cannot demonstrate "single version of truth" (FINMA Circular 2017/1 requirement)

**Real-World Example**:
```
Scenario: Customer John Doe screened in compliance notebook
- Screening Result: PEP = YES (matches World-Check database)
- Risk Classification: HIGH
- Enhanced Due Diligence: REQUIRED

BUT Core Banking System shows:
- PEP = NO (not updated)
- Risk Classification: MEDIUM
- Transaction Monitoring: Standard thresholds applied

Result: High-risk PEP transactions not properly monitored → Regulatory breach
```

#### 4.4.2 Golden Record Definition

**Golden Record**: The **authoritative, single source of truth** for a specific data attribute, with defined:
1. **System of Record (SOR)**: Which system owns the data
2. **Update Authority**: Which process can modify the data
3. **Synchronization Protocol**: How data propagates to downstream systems
4. **Conflict Resolution**: What happens when discrepancies are detected
5. **Audit Trail**: Full lineage of all changes with timestamp and user ID

#### 4.4.3 System of Record (SOR) Designation

**Compliance Data Golden Records** (AAA Synthetic Bank Architecture):

| Data Element | Golden Record System | Update Authority | Synchronization | Conflict Resolution | Regulatory Justification |
|-------------|---------------------|------------------|----------------|---------------------|-------------------------|
| **Customer Identity** (Name, DOB, Address) | **CRM_RAW_001.CRMI_RAW_TB_CUSTOMER** | Onboarding System | Real-time (event-driven) | SOR always wins | AMLA Art. 3 (verified identity) |
| **PEP Status** | **Compliance Screening Platform** → Stored in **CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360** | Daily screening batch | Daily (overnight) | Most recent screening wins | AMLO-FINMA Art. 13 (continuous monitoring) |
| **Risk Classification** | **Compliance Risk Engine** → Stored in **CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360** | Risk model + manual override | Real-time (model) + event-based (manual) | Manual override > Model | FATF R.10 (risk-based approach) |
| **Sanctions Match** | **Sanctions Screening Engine** | Real-time screening | Real-time (pre-transaction) | 100% match = immediate block | SECO Ordinance (asset freeze) |
| **KYC Status** (Complete/Incomplete/Expired) | **CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360** | Onboarding workflow + periodic review | Event-driven (status change) | Most recent status wins | AMLA Art. 3 (verification requirement) |
| **Transaction Monitoring Alerts** | **PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES** | TM Engine | Real-time (alert generation) | No conflicts (append-only) | AMLA Art. 8 (monitoring obligation) |
| **SAR/STR Filing Status** | **Compliance Case Management System** | Compliance Officer | Event-driven (SAR filed) | No conflicts (immutable after filing) | AMLA Art. 9 (reporting obligation) |
| **Enhanced Due Diligence (EDD) Status** | **CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360** | Compliance Officer approval | Event-driven (EDD completed) | Most recent EDD wins | AMLO-FINMA Art. 13 (EDD requirements) |

#### 4.4.4 Data Synchronization Architecture

**Current AAA Synthetic Bank Data Flow**:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DATA FLOW ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────┘

1. RAW Layer (System of Record - Source Systems)
   ├─ CRM_RAW_001.CRMI_RAW_TB_CUSTOMER (Customer identity)
   ├─ CRM_RAW_001.CRMI_RAW_TB_ADDRESSES (Address history)
   └─ PAY_RAW_001.PAYI_RAW_TB_TRANSACTIONS (Transaction universe)
                          ↓
                  [Snowflake Streams]
                          ↓
2. AGG Layer (Golden Record - Aggregated Truth)
   ├─ CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 (Customer Golden Record)
   │  └─ Contains: PEP_FLAG, RISK_CLASSIFICATION, SANCTIONS_FLAG, KYC_STATUS
   └─ PAY_AGG_001.PAYA_AGG_DT_TRANSACTION_ANOMALIES (AML Alerts)
                          ↓
              [Dynamic Table Refresh: 60 min]
                          ↓
3. Reporting Layer (Read-Only Consumption)
   ├─ Snowflake Notebooks (Analysis, screening dashboards)
   ├─ Streamlit App (LCR monitoring, customer 360 dashboards)
   └─ Semantic Views (AI agents, BI tools)
                          ↓
              [CRITICAL RULE: Read-only!]
                          ↓
4. Feedback Loop (Updates propagate back to SOR)
   └─ Compliance Officer manual overrides → CRM_AGG_001 → Audit log
```

**Synchronization Protocols**:

| Update Type | Frequency | Mechanism | Latency | Failure Handling |
|------------|-----------|-----------|---------|------------------|
| **Customer Identity Changes** | Real-time | Snowflake Stream → Dynamic Table | < 60 min | Alert on stream failure |
| **PEP Screening Results** | Daily batch | Overnight screening job → AGG layer | 24 hours | Manual escalation if job fails |
| **Sanctions Screening** | Real-time | Pre-transaction API call | < 200ms | Block transaction if screening unavailable |
| **Risk Classification Changes** | Event-driven | Risk model recalculation → AGG layer | < 15 min | Alert compliance officer |
| **Manual Compliance Overrides** | Event-driven | Compliance UI → AGG layer → Audit log | < 5 min | Two-person approval for critical changes |

#### 4.4.5 Conflict Resolution Rules

**Scenario 1: PEP Status Conflict**
- **Problem**: Screening system identifies new PEP match, but customer record not updated in AGG layer
- **Detection**: Daily reconciliation job compares screening results vs. AGG layer
- **Resolution**: 
  1. Screening system result always wins (most recent intelligence)
  2. Auto-update AGG layer with PEP flag + timestamp + screening source
  3. Generate compliance alert for manual review (confirm match accuracy)
  4. Freeze any in-flight high-value transactions pending review
- **Audit Trail**: Log original value, new value, reason for change, system timestamp

**Scenario 2: Manual Risk Classification Override**
- **Problem**: Compliance officer manually upgrades customer from MEDIUM → HIGH risk, but risk model downgrades back to MEDIUM on next run
- **Resolution**:
  1. Manual overrides have priority over model (business rule)
  2. Override flag stored in AGG layer: `RISK_CLASSIFICATION_OVERRIDE = TRUE`
  3. Risk model respects override flag (does not recalculate)
  4. Override valid for 12 months (annual review required per AMLO-FINMA Art. 13)
  5. After 12 months: Override expires, model recalculates, compliance notified
- **Audit Trail**: Log override reason (free text), approver ID, expiry date

**Scenario 3: Sanctions Match Discrepancy**
- **Problem**: Real-time transaction screening shows NO match, but daily batch screening shows 90% match (new sanctions list update)
- **Resolution**:
  1. **Immediate action**: Freeze all accounts for customer (within 4 hours)
  2. Compliance officer investigates match (manual review within 1 hour)
  3. If TRUE positive: Asset freeze, regulatory notification (SECO/OFSI)
  4. If FALSE positive: Unfreeze accounts, add to whitelist (prevent future false positives)
- **Audit Trail**: Log both screening results, investigation notes, disposition decision

**Scenario 4: Notebook vs. AGG Layer Discrepancy**
- **Problem**: Compliance notebook shows PEP = YES (from local screening), but AGG layer shows PEP = NO
- **Resolution**:
  1. **Rule**: AGG layer (CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360) is ALWAYS Golden Record
  2. Notebooks are **read-only analytical tools** (cannot create compliance flags)
  3. If notebook discovers new PEP: Compliance officer must manually update AGG layer via UI
  4. AGG layer update triggers audit log + workflow notification
- **Regulatory Justification**: Single source of truth required for audit trail (FINMA Circular 2017/1)

#### 4.4.6 Data Quality Controls

**Completeness Checks** (Daily Automated):
- **Rule**: Every customer in CRM_RAW_001 must have exactly ONE record in CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360
- **Validation**: `COUNT(DISTINCT CUSTOMER_ID)` in RAW = AGG layer
- **Alert**: If discrepancy > 0.1%, escalate to data steward

**Consistency Checks** (Real-time):
- **Rule**: PEP = YES → RISK_CLASSIFICATION must be HIGH or CRITICAL (business rule)
- **Validation**: Check constraint on AGG layer table
- **Alert**: If violated, reject update + compliance notification

**Timeliness Checks** (Hourly):
- **Rule**: Customer updates in RAW layer must propagate to AGG layer within 60 minutes (Dynamic Table refresh SLA)
- **Validation**: Compare `LAST_MODIFIED_TIMESTAMP` in RAW vs. AGG
- **Alert**: If lag > 90 minutes, escalate to platform team

**Accuracy Checks** (Monthly):
- **Rule**: Sample 100 customers, manually verify PEP/sanctions status against external databases (World-Check, OFAC)
- **Validation**: Compliance officer manual review
- **Alert**: If accuracy < 99%, investigate screening engine configuration

#### 4.4.7 Regulatory Implications

**Audit Readiness**:
- **FINMA/BaFin Common Finding**: "The institution could not provide a single, consistent view of customer risk classification across systems."
- **Remediation**: Implement Golden Record with clear SOR designation, audit trail, and reconciliation controls

**Enforcement Action Risk**:
- **Credit Suisse 2018 (CHF 240M fine)**: Inadequate monitoring of PEPs due to fragmented data systems
- **ING Bank 2018 (EUR 775M fine)**: Customer risk ratings not properly integrated into transaction monitoring

**Best Practice** (EBA Guidelines GL/2021/02):
> "Financial institutions shall establish a single customer view (Golden Record) that consolidates all compliance-relevant attributes from multiple source systems, with clear data governance and lineage."

#### 4.4.8 Implementation Requirements (Current Gaps)

| Requirement | Status | Priority | Implementation Effort |
|------------|--------|----------|---------------------|
| **Formalize Golden Record policy document** | ❌ Not implemented | **Critical** | 2 weeks (documentation) |
| **Daily reconciliation job (RAW ↔ AGG)** | ⚠️ Partial (manual checks) | **High** | 4 weeks (automated SQL job) |
| **Conflict resolution workflow** | ❌ Not implemented | **High** | 6 weeks (UI + workflow engine) |
| **Data quality dashboard** | ⚠️ Partial (notebooks exist) | **Medium** | 4 weeks (real-time KPIs) |
| **Compliance override UI** | ❌ Not implemented | **High** | 6 weeks (Streamlit app extension) |
| **Audit trail (immutable log)** | ⚠️ Partial (database logging) | **Critical** | 8 weeks (blockchain-style hashing) |
| **Read-only enforcement (notebooks)** | ✅ Implemented (by design) | **Low** | N/A (architectural) |

#### 4.4.9 Governance & Ownership

| Role | Responsibility | Accountability |
|------|---------------|----------------|
| **Chief Data Officer** | Golden Record policy, MDM strategy | Board Risk Committee |
| **Chief Compliance Officer** | Compliance data definitions, conflict resolution rules | Board Risk Committee |
| **Data Steward (Compliance Domain)** | Daily reconciliation, data quality monitoring | CCO |
| **Platform Engineering** | Technical implementation, synchronization jobs | CTO |
| **Internal Audit** | Independent validation of Golden Record integrity | Audit Committee |

**Review Cycle**:
- **Quarterly**: Data quality KPIs, reconciliation exceptions
- **Annual**: Golden Record policy review, SOR designation changes
- **Ad-Hoc**: System of Record changes (requires Board Risk Committee approval)

---

## 5. Non-Functional Requirements

### NFR-01: Performance & Latency
- **Real-Time Sanctions Screening**: < 200ms for payment screening (SLA for SWIFT message processing)
- **Batch Customer Re-Screening**: Complete daily re-screening of entire customer base < 4 hours (overnight batch)
- **Alert Investigation Dashboard**: Page load time < 3 seconds (user experience)
- **SAR Submission**: Submit to FIU portal < 5 minutes (avoid timeout issues)

### NFR-02: Scalability & Volume
- **Customer Base**: Support 1M+ customers across EMEA (future growth 20% p.a.)
- **Transaction Volume**: Process 10M+ transactions/month (peak 50K/hour during business hours)
- **Alert Volume**: Handle 5,000+ alerts/month (target false positive rate < 5%)
- **Sanctions Lists**: Screen against 50K+ sanctioned entities (OFAC 10K, EU 15K, UN 5K, others 20K)

### NFR-03: Auditability & Compliance
- **Audit Trail**: 100% of screening decisions, alert investigations, and dispositions logged with timestamp, user ID, and version
- **Data Retention**: Retain all compliance records for 10 years (AMLA requirement)
- **Tamper-Proof**: Immutable audit logs (blockchain-style hashing for forensic integrity)
- **Regulatory Reporting**: Generate regulatory reports on-demand (< 1 hour turnaround for regulator inquiries)

### NFR-04: Data Security & Privacy
- **Encryption**: Data-at-rest (AES-256) and data-in-transit (TLS 1.3) encryption
- **Access Controls**: Role-based access control (RBAC), multi-factor authentication (MFA) for privileged users
- **Data Masking**: PII masked in non-production environments (GDPR Art. 32)
- **Segregation of Duties**: No single user can both investigate and approve SAR filing

### NFR-05: Availability & Disaster Recovery
- **System Availability**: 99.9% uptime (8.76 hours downtime/year allowance)
- **Disaster Recovery**: RPO < 4 hours, RTO < 8 hours (regulatory reporting continuity)
- **Backup**: Daily incremental backups, weekly full backups, offsite storage
- **Business Continuity**: Manual fallback procedures for sanctions screening during system outage

---

## 6. Acceptance Criteria & Key Performance Indicators (KPIs)

### 6.1 Regulatory Compliance KPIs

| KPI | Target | Measurement Method | Reporting Frequency | Escalation Threshold |
|-----|--------|-------------------|-------------------|---------------------|
| **KYC Completeness** | > 95% | % customers with complete CDD documentation | Monthly | < 90% |
| **KYC Processing Time (Low Risk)** | < 24h | Median time from application to approval | Weekly | > 48h |
| **KYC Processing Time (High Risk)** | < 5 days | Median time from application to approval | Weekly | > 10 days |
| **Sanctions Screening Coverage** | 100% | % transactions screened before settlement | Daily | < 99.9% |
| **Sanctions False Positive Rate** | < 5% | % alerts dismissed as false positives | Monthly | > 10% |
| **Sanctions Breach Incidents** | 0 | Count of payments processed to sanctioned entities | Continuous | 1 |
| **AML Alert Investigation SLA** | > 90% | % alerts investigated within 48 hours | Weekly | < 80% |
| **SAR Filing Rate** | 0.5-2.0 per 1,000 customers | SARs filed / Total customer base * 1,000 | Quarterly | < 0.1 or > 5.0 |
| **Regulatory Breach Incidents** | 0 | Count of material breaches requiring regulatory notification | Continuous | 1 |
| **Compliance Training Completion** | > 95% | % staff completed annual AML training | Quarterly | < 85% |

### 6.2 Operational Efficiency KPIs

| KPI | Target | Business Benefit | Data Source |
|-----|--------|-----------------|-------------|
| **Customer Onboarding Straight-Through Processing** | > 60% | Reduce manual effort by 70% | Onboarding System |
| **Alert-to-SAR Conversion Rate** | 3-8% | Optimize investigation effort | AML System |
| **Average Time per Alert Investigation** | 45 min | Compliance team productivity | Case Management |
| **Sanctions List Update Time** | < 4h | Regulatory risk mitigation | Sanctions Engine |
| **Compliance Cost per Customer** | < CHF 50 | Operational efficiency | Finance System |

### 6.3 Quality Assurance Metrics

| Quality Metric | Target | Validation Method | Audit Frequency |
|---------------|--------|------------------|----------------|
| **False Positive Rate (Sanctions)** | < 5% | Sample review of dismissed alerts | Monthly |
| **False Negative Rate (Sanctions)** | 0% | Retrospective testing against new sanctions | Weekly |
| **SAR Quality Score** | > 85% | FIU feedback, internal QA review | Quarterly |
| **Data Quality (Customer Master)** | > 99% | Completeness, accuracy, timeliness checks | Daily |
| **Alert Investigation Quality** | > 90% | QA review of investigation rationale | Monthly (10% sample) |

---

## 7. Implementation Roadmap

### Phase 1: Foundation (Q1 2026) - **ANALYTICAL DASHBOARDS COMPLETE, OPERATIONAL WORKFLOWS NEEDED**

#### Notebook Coverage Assessment

The current notebooks provide **strong analytical and reporting capabilities** but are **read-only analytical tools**. They require **operational workflow enhancements** to meet full business requirements.

| Notebook | Business Requirement Coverage | Status | Critical Gaps |
|----------|------------------------------|--------|---------------|
| **customer_screening_kyc.ipynb** | **BR-01: Customer Due Diligence & KYC** | 🟡 **65% Complete** | ❌ UBO verification workflow<br>❌ Video ID/eIDAS integration<br>❌ Adverse Media screening<br>❌ Source of wealth documentation<br>❌ Senior management approval workflow<br>❌ Form A/B generation |
| **sanctions_embargo_control.ipynb** | **BR-02: Sanctions & Embargo Screening** | 🟡 **40% Complete** | ❌ Real sanctions list integration (only country checks)<br>❌ Fuzzy matching engine<br>❌ Real-time pre-settlement screening<br>❌ National lists (BaFin, AFM, DNB, FMA)<br>❌ Asset freeze workflow<br>❌ SECO/OFSI reporting automation |
| **aml_transaction_monitoring.ipynb** | **BR-03: Transaction Monitoring & SAR Filing** | 🟡 **60% Complete** | ❌ Specific TM scenarios (structuring, velocity)<br>❌ SAR form generation & FIU integration<br>❌ Case management system<br>❌ Tipping-off controls<br>❌ Behavioral baseline establishment |
| **compliance_risk_management.ipynb** | **BR-04: Compliance Risk Management** | 🟡 **50% Complete** | ❌ Regulatory breach incident tracking<br>❌ KRI automation & threshold alerting<br>❌ Remediation action tracker<br>❌ Compliance training tracking<br>❌ Golden Record reconciliation dashboard |

#### What Works Well (Analytical Reporting) ✅

**1. customer_screening_kyc.ipynb - Strong Capabilities:**
- ✅ Risk segmentation dashboard (PEP, sanctions, risk tiers)
- ✅ Customer audit trail (profile, risk history, address history)
- ✅ KYC completeness and aging analysis (policy-based refresh cycles)
- ✅ Alert aging and SLA tracking (tiered SLA policies)
- ✅ Multi-dimensional reporting (board-ready exports)
- ✅ Regulatory response templates (15-minute turnaround)

**2. sanctions_embargo_control.ipynb - Strong Capabilities:**
- ✅ Screening effectiveness dashboard (coverage metrics)
- ✅ Transaction volume tracking (30-day screening universe)
- ✅ High-risk country identification (RU, BY, KP, IR, SY, CU, VE)
- ✅ Control validation evidence (zero-breach demonstration)
- ✅ Timestamped audit trail exports

**3. aml_transaction_monitoring.ipynb - Strong Capabilities:**
- ✅ Alert volume & SAR filing metrics (quarterly trends)
- ✅ Backlog management and SLA breach analysis
- ✅ Multi-dimensional risk heatmap (country, amount tier, customer type)
- ✅ False positive rate tracking
- ✅ Estimated SAR filings by jurisdiction (CH, DE, AT, Nordics)
- ✅ Alerts-per-SAR efficiency metric

**4. compliance_risk_management.ipynb - Strong Capabilities:**
- ✅ Enterprise risk profile dashboard
- ✅ Risk concentration metrics (Critical, High, PEP, Sanctions)
- ✅ Board-ready reporting and exports
- ✅ Risk appetite monitoring

#### Critical Gaps Requiring Enhancement (Operational Workflows) ❌

**Gap Category 1: Real Sanctions Integration (CRITICAL)**
- **Current State**: Notebooks check customer country field only (e.g., `COUNTRY IN ('RU', 'BY')`)
- **Business Requirement**: Real-time screening against OFAC SDN, EU Consolidated List, UN, UK OFSI, SECO lists
- **Impact**: **Cannot detect actual sanctioned individuals/entities** - only geographic risk
- **Required Enhancement**: 
  - Integrate external sanctions data feeds (Refinitiv, Dow Jones, OFAC API)
  - Implement fuzzy matching engine (Levenshtein distance, phonetic matching)
  - Real-time transaction screening (< 200ms SLA)
  - Hard block workflow for 100% matches
  - Asset freeze automation

**Gap Category 2: UBO (Ultimate Beneficial Owner) Verification (REGULATORY CRITICAL)**
- **Current State**: No UBO data model or workflow
- **Business Requirement**: BR-01.3 - Identify and verify beneficial owners > 25% ownership
- **Regulatory Mandate**: FINMA Art. 5a, 5AMLD Art. 30, GwG § 20-28
- **Impact**: **Non-compliance with FINMA/BaFin/EU regulatory requirements**
- **Required Enhancement**:
  - UBO registry integration (Transparenzregister DE, Companies House UK, FINMA register CH)
  - Form A/B digital workflow with e-signature
  - Cascade UBO analysis for multi-tier structures
  - 10-year retention of UBO verification evidence

**Gap Category 3: Operational Case Management (HIGH PRIORITY)**
- **Current State**: Notebooks identify alerts but no workflow for investigation/disposition
- **Business Requirement**: BR-03.1 - Automated alert investigation workflow (L1/L2/L3)
- **Impact**: **Manual Excel-based alert tracking** - no audit trail, no SLA enforcement
- **Required Enhancement**:
  - Integrated case management system (alert assignment, investigation notes, disposition)
  - Two-person approval for SAR filing (segregation of duties)
  - Tipping-off controls (prevent customer notification post-SAR)
  - FIU portal integration for automated SAR submission

**Gap Category 4: Golden Record Reconciliation (DATA GOVERNANCE)**
- **Current State**: Notebooks read from AGG layer but no reconciliation checks
- **Business Requirement**: Section 4.4 - Daily reconciliation, conflict resolution
- **Impact**: **Risk of data discrepancies** between screening results and core banking
- **Required Enhancement**:
  - Daily reconciliation job (RAW ↔ AGG layer completeness checks)
  - Data quality dashboard (completeness, consistency, timeliness)
  - Conflict resolution workflow (notebook flags vs. AGG layer flags)
  - Automated alerts for discrepancies > 0.1%

**Gap Category 5: Transaction Monitoring Scenarios (AML EFFECTIVENESS)**
- **Current State**: Generic anomaly detection, no specific FATF scenarios
- **Business Requirement**: BR-03.1 - 10 specific TM scenarios (structuring, velocity, etc.)
- **Impact**: **Cannot detect sophisticated ML/TF patterns** (smurfing, layering, etc.)
- **Required Enhancement**:
  - Implement TM-01 (Structuring): Multiple deposits < threshold totaling > CHF 15K within 3 days
  - Implement TM-02 (Velocity): > 200% increase in monthly volume vs. baseline
  - Implement TM-04 (Rapid Movement): Deposits followed by wire transfers < 24h
  - Implement TM-05 (High-Risk Jurisdiction): Transactions to FATF graylist/blacklist
  - Behavioral baseline establishment (6-month historical pattern per customer)

**Gap Category 6: Enhanced Due Diligence (EDD) Workflow (COMPLIANCE)**
- **Current State**: Risk classification exists but no EDD workflow
- **Business Requirement**: BR-01.2 - Senior management approval, source of wealth verification
- **Impact**: **Cannot demonstrate EDD compliance** for high-risk customers
- **Required Enhancement**:
  - Senior management approval workflow (Board approval for Foreign PEPs)
  - Source of wealth documentation upload (tax returns, audited financials)
  - Purpose of business relationship questionnaire
  - Enhanced monitoring flag (24-month baseline for high-risk)
  - Adverse Media screening integration (Dow Jones Factiva, LexisNexis)

**Gap Category 7: Regulatory Reporting Automation (EFFICIENCY)**
- **Current State**: Manual CSV exports from notebooks
- **Business Requirement**: BR-04.1 - Automated regulatory reporting
- **Impact**: **Labor-intensive manual reporting** - 3-5 days per regulatory submission
- **Required Enhancement**:
  - Automated board pack generation (PDF with executive summary, KPIs, charts)
  - KRI calculation and threshold alerting (email when KRI > escalation threshold)
  - Remediation action tracker (SLA monitoring, owner accountability)
  - Regulatory breach incident management (timeline, root cause, remediation)

#### Recommended Action Plan

**Phase 1A: Operational Workflows (Q1-Q2 2026) - 16 weeks**
1. **Integrated Case Management System** (6 weeks)
   - Alert assignment and investigation workflow
   - SAR filing workflow with two-person approval
   - Tipping-off controls
   
2. **Golden Record Reconciliation** (4 weeks)
   - Daily reconciliation job (RAW ↔ AGG)
   - Data quality dashboard
   - Conflict resolution alerts

3. **EDD Workflow** (6 weeks)
   - Senior management approval workflow
   - Source of wealth documentation upload
   - Adverse Media screening integration

**Phase 1B: Real Sanctions Integration (Q2-Q3 2026) - 12 weeks**
1. **Sanctions Data Feeds** (4 weeks)
   - Integrate OFAC, EU, UN, UK, SECO, national lists
   - Daily automated list updates
   
2. **Fuzzy Matching Engine** (4 weeks)
   - Name similarity (Levenshtein distance)
   - Phonetic matching
   - Confidence scoring (exact, high, medium, low)

3. **Real-Time Transaction Screening** (4 weeks)
   - Pre-settlement screening API (< 200ms SLA)
   - Hard block for 100% matches
   - Asset freeze workflow

**Phase 1C: UBO Verification (Q3-Q4 2026) - 10 weeks**
1. **UBO Registry Integration** (6 weeks)
   - Transparenzregister (DE), Companies House (UK), FINMA (CH)
   - API integration for automated lookups
   
2. **Form A/B Digital Workflow** (4 weeks)
   - E-signature integration (DocuSign, Adobe Sign)
   - Cascade UBO analysis for multi-tier structures
   - 10-year retention compliance

**Phase 1D: Transaction Monitoring Scenarios (Q4 2026) - 8 weeks**
1. **Implement 5 Core Scenarios** (6 weeks)
   - TM-01 Structuring, TM-02 Velocity, TM-04 Rapid Movement, TM-05 High-Risk Jurisdiction, TM-08 Cross-Border Wire
   
2. **Behavioral Baseline Engine** (2 weeks)
   - 6-month historical pattern per customer
   - Peer group benchmarking

#### Summary: Current vs. Target State

| Capability | Current State (Notebooks) | Target State (Full Implementation) | Effort |
|-----------|--------------------------|-----------------------------------|--------|
| **Analytical Reporting** | ✅ **Excellent** (Board-ready dashboards) | ✅ Maintain current capabilities | 0 weeks |
| **Operational Workflows** | ❌ **Missing** (Manual Excel tracking) | ✅ Integrated case management, approvals, SLA enforcement | 16 weeks |
| **Real Sanctions Screening** | ❌ **Geographic only** (country checks) | ✅ Real-time multi-list screening with fuzzy matching | 12 weeks |
| **UBO Verification** | ❌ **Not implemented** | ✅ Registry integration, Form A/B workflow | 10 weeks |
| **Transaction Monitoring** | ⚠️ **Generic anomaly detection** | ✅ 10 FATF-aligned scenarios with baselines | 8 weeks |
| **Golden Record Governance** | ⚠️ **Implicit** (AGG layer exists) | ✅ Daily reconciliation, conflict resolution, data quality dashboard | 4 weeks |

**Total Enhancement Effort**: 50 weeks (can be parallelized to ~6-9 months with proper resourcing)

**Bottom Line**: The notebooks provide **strong analytical foundations** (65% of requirements) but need **operational workflow enhancements** (remaining 35%) to achieve full regulatory compliance. They excel at **"What happened?"** (reporting) but lack **"What should we do?"** (workflow automation).

### Phase 2: EMEA Expansion (Q2-Q3 2026) - **IN PROGRESS**
- 🔄 National sanctions list integration (BaFin, AFM, DNB, FMA, AMF, Bank of Italy)
- 🔄 UBO registry integration (Transparenzregister DE, Companies House UK, FINMA register CH)
- 🔄 Multi-FIU reporting automation (MROS, NCA, FIU Deutschland, TRACFIN, others)
- 🔄 Adverse Media screening integration (Dow Jones, LexisNexis, Refinitiv)

### Phase 3: Advanced Analytics (Q4 2026)
- ⏳ Machine learning false positive optimization (sanctions + AML alerts)
- ⏳ Behavioral baseline auto-tuning (dynamic TM scenario calibration)
- ⏳ Network analysis for complex structures (beneficial ownership cascade, related parties)
- ⏳ Predictive risk scoring (customer risk migration prediction)

### Phase 4: Regulatory Tech (2027)
- ⏳ Automated regulatory reporting (EBA ITSIII, MROS XML, NCA goAML)
- ⏳ RegTech AI for KYC document extraction (OCR, NLP, DocAI)
- ⏳ Real-time SWIFT screening (pre-settlement blocking integration)
- ⏳ Blockchain audit trail for immutable compliance records

---

## 8. Governance & Maintenance

### 8.1 Document Ownership

| Role | Responsibility | Approval Authority |
|------|---------------|-------------------|
| **Chief Compliance Officer** | Document owner, annual review | Board Risk Committee |
| **Head of AML** | Operational implementation, KPI tracking | CCO |
| **Head of Sanctions** | Sanctions policy, list management | CCO |
| **Data Privacy Officer** | GDPR/FADP compliance, data minimization | Board Risk Committee |
| **Internal Audit** | Independent assurance, effectiveness testing | Audit Committee |

### 8.2 Review & Update Cycle

- **Annual Review**: Full document review, regulatory change assessment (January each year)
- **Semi-Annual KPI Review**: Adjust thresholds based on performance trends (June, December)
- **Quarterly Board Reporting**: Compliance risk dashboard, KRI breaches, regulatory updates
- **Ad-Hoc Updates**: Regulatory changes, enforcement actions, material incidents

### 8.3 Model Validation

**Independent Validation Requirement** (EBA Guidelines GL/2017/11, FINMA Circular 2017/1):
- **Frequency**: Every 18 months
- **Scope**: TM scenario effectiveness, sanctions screening accuracy, risk model calibration
- **Validator**: External consultant or Internal Audit (independent of 2nd line)
- **Deliverables**: Validation report, remediation action plan, Board presentation

---

## 9. References & Supporting Documentation

### 9.1 Regulatory References

#### Switzerland
- [FINMA Anti-Money Laundering Ordinance (AMLO-FINMA)](https://www.finma.ch/en/regulations/self-regulatory-organisations-sros/anti-money-laundering/)
- [FINMA Circular 2016/7 - Video and online identification](https://www.finma.ch/en/~/media/finma/dokumente/dokumentencenter/myfinma/rundschreiben/finma-rs-2016-07.pdf)
- [SECO Sanctions Lists](https://www.seco.admin.ch/seco/en/home/Aussenwirtschaftspolitik_Wirtschaftliche_Zusammenarbeit/Wirtschaftsbeziehungen/exportkontrollen-und-sanktionen/sanktionen-embargos.html)
- [MROS (Money Laundering Reporting Office Switzerland)](https://www.fedpol.admin.ch/fedpol/en/home/kriminalitaet/geldwaescherei.html)

#### European Union
- [6th Anti-Money Laundering Directive (6AMLD)](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32018L1673)
- [EBA Guidelines on ML/TF Risk Factors (GL/2021/02)](https://www.eba.europa.eu/regulation-and-policy/anti-money-laundering-and-countering-financing-terrorism)
- [EU Sanctions Map](https://www.sanctionsmap.eu/)

#### United Kingdom
- [Money Laundering Regulations 2017 (MLR 2017)](https://www.legislation.gov.uk/uksi/2017/692/contents)
- [FCA Financial Crime Guide](https://www.handbook.fca.org.uk/handbook/FC/)
- [UK Sanctions List (OFSI)](https://www.gov.uk/government/organisations/office-of-financial-sanctions-implementation)

#### Germany
- [Geldwäschegesetz (GwG) - German AML Act](https://www.gesetze-im-internet.de/gwg_2008/)
- [BaFin Guidance on Money Laundering](https://www.bafin.de/EN/Aufsicht/BankenFinanzdienstleister/Geldwaesche/geldwaesche_node_en.html)
- [Transparenzregister (Beneficial Ownership Register)](https://www.transparenzregister.de/treg/en/)

### 9.2 Implementation Notebooks

| Capability | Notebook | Coverage | Last Updated |
|-----------|----------|----------|--------------|
| **Sanctions Screening** | [sanctions_embargo_control.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/sanctions_embargo_control.ipynb) | OFAC, EU, UN, UK, CH lists | Jan 2026 |
| **KYC & Customer Screening** | [customer_screening_kyc.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/customer_screening_kyc.ipynb) | PEP screening, risk classification | Jan 2026 |
| **Compliance Risk Management** | [compliance_risk_management.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/compliance_risk_management.ipynb) | Enterprise risk dashboard | Jan 2026 |
| **Transaction Monitoring** | [aml_transaction_monitoring.ipynb](https://github.com/zBrainiac/SyntheticRetailBank/blob/main/notebooks/aml_transaction_monitoring.ipynb) | Alert management, SAR filing | Jan 2026 |

---

## 10. Appendices

### Appendix A: FATF High-Risk Jurisdictions (January 2026)

**FATF Blacklist** (Call for Action):
- Democratic People's Republic of Korea (DPRK)
- Iran
- Myanmar

**FATF Graylist** (Increased Monitoring):
- Albania, Barbados, Burkina Faso, Cameroon, Democratic Republic of Congo, Gibraltar, Haiti, Jamaica, Mali, Mozambique, Nigeria, Panama, Philippines, Senegal, South Africa, South Sudan, Syria, Tanzania, Trinidad and Tobago, Turkey, Uganda, United Arab Emirates, Vietnam, Yemen

### Appendix B: EU High-Risk Third Countries (Delegated Regulation 2016/1675)

Afghanistan, Barbados, Burkina Faso, Cameroon, Cayman Islands, Democratic Republic of the Congo, Gibraltar, Haiti, Jamaica, Jordan, Mali, Morocco, Mozambique, Myanmar, Nicaragua, Nigeria, Pakistan, Panama, Philippines, Senegal, South Sudan, Syria, Tanzania, Trinidad and Tobago, Turkey, Uganda, United Arab Emirates, Vanuatu, Vietnam, Yemen, Zimbabwe

### Appendix C: Glossary of Terms

- **AML**: Anti-Money Laundering
- **CFT**: Counter-Terrorist Financing
- **CDD**: Customer Due Diligence
- **EDD**: Enhanced Due Diligence
- **FATF**: Financial Action Task Force
- **FIU**: Financial Intelligence Unit
- **KYC**: Know Your Customer
- **ML/TF**: Money Laundering / Terrorist Financing
- **PEP**: Politically Exposed Person
- **SAR**: Suspicious Activity Report (USA, UK)
- **STR**: Suspicious Transaction Report (EU, Switzerland)
- **UBO**: Ultimate Beneficial Owner

---

**Document End**

*This document represents business requirements only. Technical implementation specifications, data models, and system architecture are documented separately.*
