# Retail Loans & Mortgages – Business Requirements (EMEA)

## 1. Purpose & Scope

This document defines business requirements for the origination, servicing, and lifecycle management of retail loans and mortgages for a universal/retail bank operating across EMEA. It is intended to:

- **Provide a shared view** for Business, Risk, Compliance, Operations, and Technology on required capabilities.
- **Align process and data requirements** with key regulatory frameworks (EU and selected EMEA markets).
- **Serve as a baseline** for solution design, including data and analytics platforms, decisioning engines, and integration to core banking systems.

The focus is on:

- **Unsecured loans**: personal/consumer loans, overdrafts, credit lines.
- **Secured retail lending**: residential mortgages (owner-occupied and buy-to-let), home equity loans/lines of credit.

Corporate lending, specialist asset-backed lending (e.g. auto finance via dealers), and pure SME/commercial portfolios are out of scope except where they use the same shared platforms.

---

## 2. In-Scope Products & Channels

### 2.1 Product Types

- **Personal loans (unsecured)**
  - Fixed-term instalment loans (e.g. debt consolidation, auto, education, renovation).
  - Revolving credit/overdrafts linked to current accounts.

- **Residential mortgages**
  - Owner-occupied (annuity/interest-only, fixed or variable rate).
  - Buy-to-let / investment properties.
  - Bridge loans and construction/renovation loans (where managed in retail book).

- **Home equity loans and lines of credit** secured on residential property.

- **Associated protection products** (reference only)
  - Payment protection insurance (PPI), life, disability, unemployment covers.
  - Property insurance requirements as loan conditions.

### 2.2 Channels

- **Digital**: web, mobile app, partner APIs (brokers, aggregators, fintech partners).
- **Assisted**: branch, call centre, relationship managers.
- **Third-party intermediaries**: brokers, comparison sites, white-label partners.

Business requirements must support consistent outcomes and controls across all channels.

---

## 3. Key Stakeholders & Roles

- **Retail Banking / Product Management**
  - Defines product features, pricing strategy, eligibility rules.

- **Risk Management (Credit, Model Risk, Operational Risk)**
  - Owns underwriting standards, risk appetite and portfolio limits.
  - Approves models (PD/LGD/EAD, affordability, pricing, early warning).

- **Compliance & Legal**
  - Ensures alignment with consumer protection, mortgage, AML/CTF and data protection laws across jurisdictions.

- **Credit Operations / Lending Operations**
  - Executes origination, documentation, disbursement, servicing, collections.

- **IT / Data / Analytics**
  - Delivers systems supporting decisioning, data quality, reporting, and auditability.

- **Internal Audit**
  - Performs independent review of adherence to policies and regulatory expectations.

---

## 4. Regulatory & Policy Drivers (EMEA Focus)

The platform and processes must be designed to enable compliance with, and efficient adaptation to, the following regulatory frameworks (non-exhaustive, varies by country):

### 4.1 EU-Level Regulations & Guidelines

- **Mortgage Credit Directive (MCD) – Directive 2014/17/EU**
  - Pre-contractual information (ESIS), advice vs. execution-only, reflection periods.
  - Robust creditworthiness assessment and affordability analysis before granting a mortgage.

- **Consumer Credit Directive (CCD – Directive 2008/48/EC and revised Directive (EU) 2023/2225)**
  - Standardised information (SECCI), APR/CAPR disclosures, early repayment rights, responsible lending obligations for unsecured consumer loans.

- **EBA Guidelines on Loan Origination and Monitoring (EBA/GL/2020/06)**
  - Governance, data, and model risk standards for credit granting and ongoing monitoring.
  - Detailed expectations for loan origination data, credit decisioning, collateral valuation, and monitoring.

- **Capital Requirements Regulation & Directive (CRR / CRD)**
  - Risk-weighted assets (RWA) calculations for retail exposures and residential mortgages.
  - IRB/Standardised approaches, collateral recognition (including LTV-based preferential risk weights), and expected loss calculations.
  - Note: Slotting approaches apply to specialised lending (e.g. income-producing real estate) and are not used for standard retail mortgages.

- **GDPR – Regulation (EU) 2016/679**
  - Lawful basis for processing personal data for underwriting and monitoring.
  - Transparency, data minimisation, purpose limitation, retention limits, and data subject rights.

- **Anti-Money Laundering Directives (AMLD 4/5/6)**
  - KYC/CDD, beneficial ownership, PEPs, sanctions screening as they relate to lending relationships.

- **Consumer Protection & Distance Marketing**
  - Unfair Commercial Practices Directive, Distance Marketing of Financial Services Directive.
  - Clear, non-misleading advertising, fair treatment, and complaint handling.

- **ESG & Sustainable Lending (Emerging Supervisory Expectations)**
  - **EBA Guidelines on Loan Origination and Monitoring**: Explicitly require consideration of ESG factors in credit risk assessment and collateral valuation.
  - **ECB Guide on Climate-Related and Environmental Risks**: Expectations for banks to integrate climate and environmental risks into business strategy, governance, and risk management.
  - **EU Taxonomy Regulation (Regulation (EU) 2020/852)**: Classification system for environmentally sustainable economic activities, relevant for "green mortgage" products and ESG disclosures.
  - **SFDR (Sustainable Finance Disclosure Regulation)**: Disclosure requirements for financial products with sustainability characteristics.
  - **Key Requirements**:
    - **Property Valuation**: Consideration of energy efficiency, environmental risks (flood, subsidence, climate transition risks) in collateral valuations.
    - **Risk Appetite & Concentration**: Assessment of portfolio concentration in high climate-risk areas or energy-inefficient properties.
    - **Product Design**: Development of "green mortgage" products with preferential pricing for energy-efficient properties.
    - **Data Capture**: Collection of property-level ESG data (Energy Performance Certificate ratings, flood risk zones, renovation/improvement flags).
    - **Scenario Analysis**: Forward-looking assessment of climate transition and physical risk impacts on mortgage portfolios.
    - **Disclosure**: Where applicable, reporting on proportion of green/sustainable lending in line with EU Taxonomy.

### 4.2 National Supervisory Expectations (Examples)

- **UK (post-Brexit, for UK operations):**
  - FCA Handbook: MCOB (mortgages), CONC (consumer credit), and Consumer Duty (fair value, good customer outcomes).
  - PRA rules on capital, risk management, and model governance.

- **Switzerland (FINMA & Federal Council Requirements):**
  
  **Regulatory Framework:**
  - **FINMA Circular 2008/44**: "Mortgage Lending Risks" - comprehensive requirements for mortgage origination and monitoring
  - **FINMA Circular 2019/02**: "Operational Risks and Resilience - Banks" - operational risk in lending processes
  - **Self-Regulatory Organizations (SROs)**: Swiss Banking Association guidelines on responsible mortgage lending
  - **Federal Act on Consumer Credit (CCA)**: Consumer protection for unsecured retail loans
  - **Capital Adequacy Ordinance (CAO)**: Risk weighting and capital requirements for residential mortgages
  
  **Important Note on Regulatory Sources**: Many of the specific parameters detailed below (e.g., 5% imputed interest rate for affordability testing, 33% affordability threshold, 10% hard equity minimum, 2nd rank amortization requirements) are implemented as bank policy in line with **Swiss Bankers Association (SBA) self-regulation and FINMA supervisory expectations**, rather than being codified directly in law. FINMA supervises adherence to these industry standards through Circular 2008/44 and ongoing supervision, making them **de facto mandatory** for prudent mortgage lending in Switzerland. The 80% maximum LTV and equity composition requirements have become market-wide practice strongly endorsed by FINMA, with deviations requiring enhanced justification and capital treatment.
  
  **Mortgage Lending Specific Requirements:**
  
  1. **Loan-to-Value (LTV) Limits:**
     - **Maximum LTV: 80%** for owner-occupied residential property (minimum 20% equity required)
     - **Of the 20% equity requirement:**
       - Minimum **10% must be "hard equity"** (cash, savings, securities - NOT 2nd pillar pension funds)
       - Up to **10% can be "soft equity"** (2nd pillar pension withdrawal allowed, subject to conditions)
     - **Renovation/Extension loans:** LTV calculated on post-renovation value with independent valuation
     - **Investment properties (rental/buy-to-let):** May require higher equity (typically 25-30% bank practice)
  
  2. **Affordability Assessment (Tragbarkeit):**
     - **Imputed interest rate:** Must use **minimum 5% p.a.** for affordability calculation (regardless of actual rate)
       - Even if market rate is 2%, affordability tested at 5% to ensure customer can withstand rate increases
     - **Maximum affordability threshold:** Total housing costs (interest + amortization + ancillary costs) must not exceed **33% of gross household income**
     - **Housing costs calculation:**
       - Imputed interest at 5% on total mortgage amount
       - Amortization (minimum 1% p.a. of loan amount - see below)
       - Ancillary costs: 1% of property value (maintenance, utilities, insurance, property tax)
     - **Income verification:** Must use sustainable, verifiable income (exclude bonuses, overtime unless regular and documented over 2+ years)
     - **Retirement affordability:** Must demonstrate affordability continues into retirement (using expected pension income)
  
  3. **Mandatory Amortization:**
     - **80% LTV threshold:** Portion of mortgage exceeding 66.67% LTV (i.e., the "2nd rank" between 67% and 80% LTV) must be **amortized to 66.67% LTV within 15 years**
       - Example: CHF 800,000 property, CHF 640,000 mortgage (80% LTV)
         - 1st rank: CHF 533,360 (66.67% LTV) - no mandatory amortization
         - 2nd rank: CHF 106,640 (13.33% LTV) - must be fully amortized within 15 years
     - **Amortization schedule:** Must be **direct amortization** (reducing principal) or indirect via 3rd pillar pension (Säule 3a), subject to limits
     - **Retirement rule:** Full mortgage balance must be amortized to maximum 66.67% LTV **by retirement age (typically 65)** or demonstrate ongoing affordability at 5% imputed rate with pension income
     - **No amortization requirement** for 1st rank (up to 66.67% LTV) - can remain outstanding indefinitely if affordability maintained
  
  4. **Property Valuation Standards:**
     - **Independent professional valuation** required for all mortgage lending
     - **Valuation methods:** Recognized methods include sales comparison, income capitalization (for rental properties), and cost approach
     - **Revaluation frequency:** 
       - Minimum every **3 years** for standard residential mortgages
       - Annually for investment properties or higher-risk segments
       - Event-driven (e.g., significant market corrections, property modifications, refinancing requests)
     - **Conservative valuation principles:** Must use sustainable long-term value, not peak market values
  
  5. **Foreign Currency Mortgages:**
     - **Strict requirements** for CHF mortgages to non-CHF income earners (e.g., cross-border workers)
     - Enhanced affordability assessment with **currency stress scenarios**
     - Explicit **disclosure of FX risk** and customer acknowledgment
     - FINMA expectation: generally discouraged unless customer has natural FX hedge
  
  6. **Documentation & Disclosure:**
     - **Standardized Pre-Contractual Information Sheet (PCIS):** Must provide clear, comprehensible information on:
       - Loan amount, term, interest rate (fixed or variable), total cost of credit
       - Amortization schedule and obligations
       - LTV ratio and equity composition
       - Affordability calculation and assumptions (5% imputed rate, 33% threshold)
       - Rights and obligations, early repayment conditions, fees
     - **Annual statement:** Borrowers must receive annual statement showing outstanding balance, payments made, LTV evolution
     - **Right to early repayment:** Customers have legal right to prepay with **compensation to lender** for fixed-rate period (calculated per CCA rules for consumer credit; market practice for mortgages)
  
  7. **Monitoring & Portfolio Management:**
     - **Ongoing monitoring** of LTV ratios, especially in declining property markets
     - **Early warning indicators:** Arrears, payment difficulties, deteriorating financial situation
     - **Forbearance frameworks:** Restructuring options for borrowers in temporary difficulty (payment holidays, term extensions, interest-only periods) - must be documented and reported
     - **Capital add-ons:** FINMA may impose higher risk weights or capital buffers if portfolio risk concentrations identified
  
  8. **Conduct & Consumer Protection:**
     - **Suitability assessment:** Lender must ensure mortgage is suitable for customer's needs and financial situation
     - **Responsible lending principle:** Must not grant credit that creates over-indebtedness risk
     - **Complaint handling:** Effective complaint resolution process with option to escalate to Ombudsman
     - **Data protection:** Full compliance with Swiss Federal Act on Data Protection (FADP) - consent for data processing, right to access/rectification
  
  9. **Reporting to FINMA:**
     - **Quarterly reporting:** Mortgage portfolio statistics (volume, LTV distribution, arrears, new originations)
     - **Ad-hoc reporting:** Material risk events, portfolio deterioration, policy breaches
     - **Stress testing:** Participation in FINMA-coordinated stress tests for real estate/mortgage risk
  
  **Unsecured Consumer Credit (CCA Requirements):**
  - **Maximum interest rate:** No explicit cap, but must be "reasonable" and transparent
  - **CAPR (Cost of Annual Percentage Rate) disclosure:** Mandatory standardized cost disclosure
  - **Cooling-off period:** 7-14 days (depending on product) for reflection and withdrawal without penalty
  - **Creditworthiness check:** Must verify borrower's ability to repay without undue hardship
  - **Debt collection restrictions:** Strict rules on collection practices, late fees, and enforcement
  
  **Key Differences from EU Standards:**
  - More conservative affordability testing (5% imputed rate vs. variable EU stress tests)
  - Specific hard equity requirement (10%) unique to Switzerland
  - Strong amortization culture (2nd rank must be amortized within 15 years)
  - Self-regulatory framework plays larger role alongside FINMA supervision

- **Other EMEA Jurisdictions**
  - Local transpositions of EU directives and additional rules (e.g. debt-to-income or LTV caps by national authorities, affordability "stress rate" rules, responsible lending codes, foreclosure & forbearance frameworks).

The business solution must be parameterised to support country-specific overlays (e.g. different maximum LTVs, interest rate stress margins, standard income assumptions) without bespoke system development per jurisdiction.

**Switzerland Parameterization Requirements:**
- LTV caps: 80% (owner-occupied), configurable per property type
- Hard equity minimum: 10% of property value
- Affordability imputed rate: 5% (system default, overridable for testing)
- Affordability threshold: 33% of gross income
- Ancillary costs assumption: 1% of property value annually
- Amortization threshold: 66.67% LTV (2nd rank amortization requirement)
- Amortization period: 15 years for 2nd rank
- Retirement amortization: Full balance to 66.67% by age 65
- Revaluation frequency: Every 3 years (standard), annually (investment)

---

## 5. High-Level Business Objectives

- **Regulatory-compliant credit granting**
  - Demonstrably responsible lending decisions that meet MCD/CCD and local rules.
  - Transparent, consistent, and documented creditworthiness and affordability assessment.

- **Profitable, risk-adjusted growth**
  - Optimise risk-return via pricing, risk-based segmentation, and portfolio steering.
  - Improve approval rates for creditworthy customers while controlling impairments and capital consumption.

- **Superior customer experience**
  - Fast, mostly digital journeys with minimal friction but robust controls.
  - Clear communication of costs, risks, and rights, including early repayment options.

- **Operational resilience and efficiency**
  - Straight-through-processing (STP) for low-risk segments; efficient handling for exceptions.
  - Scalable, resilient platforms with strong auditability, monitoring, and change management.

- **Data quality and governance**
  - High-quality, traceable data to support underwriting, IFRS9/impairment, stress testing, and regulatory reporting.

---

## 6. End-to-End Process Overview

1. **Lead & Pre-Application**
   - Marketing, eligibility pre-checks, basic simulations (loan amount, term, indicative rate).

2. **Application Capture**
   - Customer and product details, consent capture, document upload, ESIS generation (mortgages) or SECCI generation (unsecured consumer credit).

3. **KYC/CDD & Screening**
   - Identity verification, sanctions and PEP checks, risk classification.

4. **Credit Assessment & Decisioning**
   - Income and expense verification, affordability calculations, scoring, risk-based decision.

5. **Collateral Management (for secured loans)**
   - Property details, valuation, legal checks, collateral registration.

6. **Offer, Contracting & Disbursement**
   - Binding offer, cooling-off where applicable, signatures, disbursement.

7. **Servicing & Lifecycle Management**
   - Payment processing, interest/fee accruals, changes (rate, term, restructuring).

8. **Arrears, Collections & Forbearance**
   - Early arrears management, hardship assessments, restructures, enforcement.

9. **Closure & Post-Closure**
   - Redemption, collateral release, data retention/archiving.

---

## 7. Functional Business Requirements

### 7.1 Lead Management & Pre-Application

**Requirements**

- Provide pre-qualification tools based on:
  - Basic customer attributes (age, employment type, residency status).
  - High-level debt limits (e.g. high-level debt-to-income / DTI check using declared data and bureau data where permitted).

- Allow customers and staff to run loan simulations:
  - Amount, term, rate type, currency (where applicable).
  - Display APR/CAPR and total cost of credit in line with CCD/MCD.

- Enforce country- and product-specific eligibility rules, including at least the following dimensions and required data:

  **Customer profile eligibility**
  - **Required data**: date of birth/age, nationality, residency status (resident/non-resident, EEA/non-EEA), marital status, number of dependants, customer segment (e.g. mass, affluent, private), existing customer vs. new-to-bank, relationship tenure.
  - **Typical rules**: minimum/maximum age at origination and at maturity; permitted nationalities/residencies per country; minimum relationship tenure for certain products (e.g. preferential mortgage rates for existing customers).

  **KYC / regulatory eligibility**
  - **Required data**: KYC status (completed/expired), CDD risk rating (low/medium/high), sanctions/PEP flags, adverse media flags, tax residency, FATCA/CRS indicators.
  - **Typical rules**: loans only granted where KYC is completed and not expired; additional approvals for high-risk CDD ratings; restrictions or prohibitions for certain high-risk countries, occupations, or PEPs in line with AML and sanctions policies.

  **Credit history & behavioural eligibility**
  - **Required data**: internal behavioural score, external bureau score(s), existing arrears and delinquencies, insolvency/bankruptcy flags, number of recent credit enquiries, existing internal exposure and utilisation levels.
  - **Typical rules**: minimum risk score thresholds by product; exclusion or tighter limits where serious delinquencies, bankruptcies, or fraud markers exist; maximum number of open/active credit facilities.

  **Income, employment and affordability-related eligibility**
  - **Required data**: employment status (employed, self-employed, retired, student), contract type (permanent, fixed-term, temporary), length of employment, income components (fixed, variable, bonus, rental, other), income documentation type (payslip, tax return, bank statement), verified total debt obligations (internal + bureau), standardised living cost assumptions.
  - **Typical rules**: minimum stable income thresholds, minimum length of employment or business operation, permitted/discounted treatment of variable income, specific rules for self-employed and contractors, maximum DTI/DSTI ratios per segment.

  **Product and collateral-specific eligibility (especially for mortgages)**
  - **Required data**: property type (house, flat, multi-unit, commercial/residential mix), use (owner-occupied vs. buy-to-let), location (country/region/postcode), construction status (existing/new build), collateral valuation and value, requested LTV and loan amount, currency.
  - **Typical rules**: maximum LTVs by occupancy type and property type; exclusion of certain property types (e.g. agriculturally zoned, non-standard construction) or locations; minimum and maximum loan amounts and terms; restrictions on FX-denominated lending for customers without income in the loan currency (per national rules).

  **Channel and distribution eligibility**
  - **Required data**: acquisition channel (direct, branch, broker, aggregator, partner), partner/broker identifier, advice vs. execution-only flag.
  - **Typical rules**: differentiated eligibility criteria or limits for broker vs. direct channels; additional checks for execution-only journeys to ensure understanding of risks and suitability where required by local regulation.

### 7.2 Application Capture

**Requirements**

- Capture structured application data consistently across channels:
  - Personal data (identity, contact, marital status, dependants).
  - Income (base, variable, rental, other), employer details, self-employment data.
  - Existing debt obligations: internal exposures, external loans/credit cards via credit bureau where permitted.
  - Loan details: purpose, requested amount, term, repayment type, rate type, currency (if multi-currency), insurance preferences.
  - For mortgages: property address, type, occupancy, purchase price, requested LTV, construction status.

- Capture consents and disclosures:
  - Consent for bureau checks and data processing (GDPR-compliant).
  - Acknowledgment of having received pre-contractual information (ESIS/SECCI).
  - Consent/preferences for digital communication.

- Support document collection and validation:
  - Income proof (payslips, tax returns, bank statements).
  - ID documents, residence permits.
  - Property documents: purchase contract, land registry extract, property plans, valuations.

- Provide real-time validation:
  - Mandatory fields, format checks, logical consistency (e.g. age vs. employment start date).
  - Duplicate application detection.

### 7.3 KYC / Customer Due Diligence (CDD)

**Requirements**

- Integrate with KYC/AML platforms to:
  - Verify identity (document and biometric checks where applicable).
  - Perform sanctions, PEP, adverse media screening.
  - Assign CDD risk rating (e.g. low/medium/high) and determine required review depth.

- Ensure KYC results are:
  - Linked to the lending application and customer master record.
  - Recorded with timestamps, decision logs, and reviewer identifiers where manual.

- Prevent loan approval and disbursement until required KYC/CDD checks are passed or appropriately escalated and approved under documented exceptions.

### 7.4 Creditworthiness & Affordability Assessment

**Requirements**

- Implement standardised affordability assessment aligned with MCD/CCD and local rules:
  - Calculate net disposable income (NDI), including reasonable assumptions for living expenses (country-specific standard budgets) and stress scenarios (rate shocks, income drops where required).
  - Support DTI / DSTI metrics (debt-to-income / debt service-to-income) and enforce configurable thresholds by product, country, segment.

- Integrate with credit bureaus and internal exposure systems:
  - Retrieve external debts, arrears, credit scores where permitted.
  - Aggregate total obligations (internal + external) in affordability calculations.

- Support risk-based decisioning:
  - Automated scoring (behavioural, application, bureau) with override rules and manual review paths.
  - Policy rules for declines (e.g. serious delinquencies, insolvency flags) and refer conditions.

- Support simulation and scenario analysis:
  - Interest rate stress (e.g. +300 bps or as per national guidance) on variable/floating-rate loans.
  - Currency stress for FX-denominated loans (where available).

- Maintain transparent, explainable decisions:
  - Retain the full calculation of affordability, contributing data elements, and reasons for decision.
  - Provide clear customer-facing reasons for decline in line with regulatory expectations.

### 7.5 Collateral, Valuation & LTV Management (Mortgages & Secured Loans)

**Requirements**

- Capture and maintain collateral master data:
  - Property type, location, size, use, construction year, energy performance where relevant.
  - Ownership details, co-borrowers and guarantors, land registry identifiers.

- Integrate with valuation services:
  - Support automated valuation models (AVM) and/or manual appraisals.
  - Store valuation documents, valuation methodology, provider, date, and value.

- Calculate and enforce LTV-related rules:
  - Initial and current LTV: loan amount vs. property value.
  - Regulatory and internal LTV caps by product, segment and occupancy type.

- Support collateral lifecycle:
  - Revaluations (periodic or event-driven), property improvements, partial releases.
  - Collateral substitution / property switching where product permits.

- Manage collateral registration:
  - Legal charge/mortgage registration with land registries/cadastres.
  - Tracking of registration status as pre-condition for full disbursement where policy requires.

### 7.6 Offer, Contracting & Disbursement

**Requirements**

- Generate binding offers and contracts in line with local law:
  - ESIS/SECCI and contract templates per country, product, and channel.
  - Inclusion of key terms: interest rate, APR, fees, repayment schedule, security, cooling-off periods, early repayment conditions, and applicable charges.

- Support cooling-off and reflection periods as per MCD and local rules:
  - Block or restrict disbursement where reflection periods still apply (unless explicitly waived where legally allowed).

- Support electronic and wet signatures:
  - eIDAS-compliant e-signatures where applicable.
  - Full audit trail of who signed what, when, and via which channel.

- Orchestrate disbursement logic:
  - For mortgages: align disbursement with property completion milestones and legal completion.
  - For personal loans: enable immediate or scheduled disbursement.
  - Support multiple payees (seller, notary, customer) as per legal and business rules.

### 7.7 Servicing & Lifecycle Events

**Requirements**

- Manage account-level servicing:
  - Payment schedule creation and maintenance.
  - Interest accruals, capitalisation rules, fee application.
  - Payment allocation priorities (interest, fees, principal, arrears).

- Support customer-initiated changes:
  - Partial prepayments, full early repayment, rate switches, term changes, payment holidays.
  - Recalculation of instalments and disclosures of impact (shorter term vs. lower instalment options).

- Support bank-initiated changes:
  - Rate resets (e.g. after fixed-rate period ends), margin adjustments, reference rate changes (e.g. IBOR transition).
  - Transparent communication of changes with legally required notice periods.

- Enable portability and refinancing:
  - Porting of mortgages to new properties where product design allows.
  - Internal refinancing / product switching with appropriate re-assessment of creditworthiness where required by regulation.

- **Mortgage Portability (Property Substitution)** - common in UK, Switzerland, and some other EMEA markets:
  - **Process Requirements**:
    - Customer initiates request to move existing mortgage from Property A to new Property B (e.g., house move).
    - Existing mortgage terms (interest rate, remaining term, balance) are preserved, subject to new property meeting collateral standards.
    - No Early Repayment Charges (ERCs) apply when porting within fixed-rate period (regulatory expectation in UK under FCA MCOB rules).
  - **Data & Workflow Requirements**:
    - Capture new property details (address, type, valuation) and link to existing loan account.
    - Obtain new property valuation (AVM or full appraisal) and calculate new LTV based on outstanding balance vs. new property value.
    - Re-assess affordability if loan amount increases (e.g., customer wants to borrow additional funds for more expensive property).
    - If new LTV exceeds policy limits or affordability deteriorates, offer alternatives: reduce loan amount, decline porting (customer must apply for new mortgage), or charge ERC if customer exits to competitor.
    - **Collateral Substitution**: Release charge on Property A, register charge on Property B. Track both properties in collateral history for audit trail.
    - **Timeline Tracking**: Coordinate legal completion timelines for Property A sale and Property B purchase to avoid funding gaps or double-collateral periods.
  - **Regulatory Requirements**: Provide clear disclosure of portability rights in mortgage offer. Track portability requests and outcomes for conduct risk monitoring.

- **Product Switching (Rate Type Changes)**:
  - **Trigger Events**:
    - End of fixed-rate period: customer automatically moves to Standard Variable Rate (SVR) unless they proactively switch to new fixed/tracker product.
    - Customer-initiated: customer requests switch from variable to fixed, or from one fixed rate to another (potentially incurring ERCs).
  - **Automated Product Switch Logic**:
    - **No Re-underwriting Required**: For existing customers in good standing (no arrears, no material adverse change in circumstances), allow simplified product switch without full credit re-assessment.
    - **Pricing**: Offer risk-based pricing based on current LTV (may be lower than origination LTV due to principal repayment and property appreciation) and customer loyalty/relationship status.
    - **Rate Change Notification**: Provide advance notice (typically 30-90 days before fixed period ends) with:
      - Current rate ending, new SVR rate that will apply, estimated monthly payment change.
      - Alternative fixed/tracker products available with indicative rates and fees.
      - Online/app-based switching capability for frictionless customer experience.
  - **Exceptions Requiring Re-underwriting**:
    - Customer requests additional borrowing concurrent with product switch.
    - Significant arrears or payment difficulties during current product term.
    - Adverse changes in customer circumstances (job loss, income reduction, increased debts) flagged by early warning systems.
  - **Fee Structure**: Application fees, valuation fees (if required), and early repayment charges (if switching before fixed period ends) must be disclosed transparently.
  - **Data Requirements**: Maintain product history on loan account (original product, switch dates, reasons for switch, fees charged) for MI and customer journey analysis.

- **Interest Rate Floor Handling** (for reference rate-linked products):
  - **Contractual Floor Clauses**: Many EMEA mortgage contracts specify that the reference rate (EURIBOR, SARON, SONIA, etc.) cannot drop below 0.00% for the purpose of calculating the customer's interest rate.
    - Example: "Customer Rate = MAX(0%, Reference Rate) + Margin"
    - In negative rate environments (e.g., EURIBOR -0.50%), customer pays only the margin (e.g., 1.50%), not margin minus 0.50% (which would be 1.00%).
  - **System Requirements**:
    - Store contractual_floor_rate (typically 0.00%) in loan account configuration.
    - Apply floor in interest calculation engine: `Effective Rate = MAX(contractual_floor_rate, reference_rate) + margin`.
    - Distinguish between contractual floor (in customer contract) and economic floor (bank's funding cost floor) for risk management.
  - **Transparency & Disclosure**:
    - Clearly disclose floor clauses in pre-contractual documentation (ESIS) and loan contract.
    - Where floors materially benefit the bank in negative rate environments, ensure fair value assessment and Consumer Duty compliance (UK) or equivalent consumer protection standards (EU).
  - **Data & Reporting**: Track prevalence of floor clauses in portfolio, impact on Net Interest Margin (NIM) in low-rate scenarios, and customer complaints related to floors.

### 7.8 Arrears, Collections & Forbearance

**Requirements**

- Detect and classify early arrears:
  - Automate arrears ageing (days past due, missed instalments, cured vs. rolling).
  - Trigger early-stage contact strategies and risk flags.

- Support forbearance and hardship solutions:
  - Offer structured options: payment holidays, term extensions, interest-only periods, rate reductions, capitalisation of arrears.
  - Assess and record customer's changed circumstances, updated affordability, and suitability of measures.
  - Ensure alignment with national forbearance and foreclosure frameworks and consumer protection expectations.

- Manage collections workflow:
  - Segmentation of accounts by risk, behaviour, and vulnerability (where permitted).
  - Case management, action history, communication logs.
  - Integration with legal collections, foreclosure, and asset disposal processes.

- Provide governance and reporting:
  - Track forborne exposures, non-performing exposures (NPE), and cure rates in line with EBA definitions.
  - Support IFRS9 staging, provisioning, and expected credit loss (ECL) calculations.

- **Handle vulnerable customers appropriately** (where vulnerability flags are captured and legally permissible):
  - **Identification**: Capture vulnerability indicators such as age (elderly), health conditions, financial difficulties, recent bereavement, language barriers, or mental capacity concerns (aligned with FCA Consumer Duty expectations in UK, similar conduct principles in other jurisdictions).
  - **Treatment Strategies**: Ensure vulnerability flags influence collections and forbearance approaches:
    - Route vulnerable customers to specialist teams trained in vulnerability handling.
    - Adapt communication cadence and channels (e.g., allow longer response times, offer face-to-face or telephone options over digital-only contact).
    - Proactively offer forbearance solutions and signpost to debt advice services (e.g., Citizens Advice, Money Advice Service, local equivalents).
    - Apply heightened scrutiny to ensure fair treatment and avoid causing additional harm or distress.
  - **Safeguards**: Require management approval and documentation for enforcement actions (e.g., foreclosure proceedings) against vulnerable customers.
  - **Monitoring**: Track outcomes for vulnerable customers separately to ensure fair treatment and identify any systemic issues.

- **Complaints Management for Lending-Related Issues**:
  - **Capture and Classify**: Record all complaints related to loan origination, servicing, affordability, collections, or forbearance with:
    - Complaint type classification (e.g., affordability concerns, mis-selling allegations, collections conduct, fee disputes, documentation errors, service quality).
    - Customer details, loan/application reference, date received, channel (phone, email, letter, branch, regulator referral).
  - **Resolution SLAs**: Define and enforce time-bound resolution targets:
    - Acknowledgment within 2-5 business days (varies by jurisdiction).
    - Resolution within 8 weeks (EU standard under MCD/CCD and FCA rules), or escalation to Financial Ombudsman / alternative dispute resolution (ADR) schemes.
    - Expedited handling for vulnerable customers or high-severity issues (e.g., imminent foreclosure, incorrect arrears reporting to credit bureaus).
  - **Root Cause Analysis**: For each complaint, capture:
    - Root cause category (policy issue, system error, staff error, unclear communication, external factor).
    - Remediation actions taken (refund, compensation, apology, process correction).
    - Preventive measures to avoid recurrence (policy update, staff training, system enhancement).
  - **Governance & Reporting**: Feed complaints data into:
    - Product and process improvement initiatives (linked to Section 8.3 Customer & Conduct Outcomes).
    - Senior management and board reporting on conduct risk.
    - Regulatory reporting where required (e.g., FCA complaints return, national competent authority filings).
  - **Fair Outcomes**: Ensure complaints handling demonstrates fair treatment, transparency, and good customer outcomes (aligned with Consumer Duty principles and conduct regulations).

### 7.9 Right of Withdrawal & Cooling-Off Period Tracking

**Regulatory Context**: Under EU Consumer Credit Directive (CCD), Swiss Federal Act on Consumer Credit (CCA), and similar EMEA consumer protection laws, borrowers have a statutory right to withdraw from a credit agreement within a defined period (typically 14 days) without giving a reason and without penalty.

**Requirements**:

- **Cooling-Off Period Calculation & Enforcement**:
  - **Start Date Precision**: The cooling-off period begins when:
    - The credit agreement is signed by the borrower (for physical/wet signatures).
    - The borrower receives all mandatory pre-contractual information and contract terms (for distance contracts/electronic signatures).
    - Whichever is later, per local law.
  - **System Capture**: Store `cooling_off_period_start_timestamp` (UTC timestamp with millisecond precision) at the moment the triggering event occurs (contract signature confirmation, document delivery confirmation).
  - **End Date Calculation**: Automatically calculate `cooling_off_period_end_timestamp` by adding the statutory period (e.g., 14 calendar days in EU/CCD, 14 days in Switzerland/CCA) to the start timestamp, accounting for weekends, public holidays, and time-of-day rules per jurisdiction.
  - **Business Rules**: The system must:
    - **Block Disbursement**: Prevent loan disbursement (transfer of funds to customer or seller) until the cooling-off period has expired, unless the customer has explicitly waived the right in writing where legally permitted (e.g., for urgent property completions).
    - **Waiver Capture**: If customer requests early disbursement by waiving cooling-off rights, capture: `waiver_requested_date`, `waiver_granted_date`, `waiver_reason` (e.g., "urgent property completion deadline"), `waiver_consent_method` (signed form, digital acknowledgment).
    - **Withdrawal Request Handling**: If customer exercises right of withdrawal within the cooling-off period:
      - Immediately halt any pending disbursement.
      - Reverse the loan booking (cancel the account, unwind any interest accruals).
      - Release collateral charges (if registered).
      - Refund any fees paid (setup fees, valuation fees) where required by law.
      - Retain audit trail: `withdrawal_request_date`, `withdrawal_effective_date`, `withdrawal_method` (email, letter, phone, in-person), `funds_returned_date`.

- **Data Model Requirements**:
  - **Loan Account Entity - Add Withdrawal Tracking Attributes**:
    - `cooling_off_period_applicable` (boolean - some products/channels may be exempt).
    - `cooling_off_period_start_timestamp` (UTC timestamp).
    - `cooling_off_period_end_timestamp` (UTC timestamp).
    - `cooling_off_period_status` (ACTIVE, EXPIRED, WAIVED, WITHDRAWN).
    - `cooling_off_waiver_requested` (boolean).
    - `cooling_off_waiver_granted_timestamp` (UTC timestamp).
    - `cooling_off_waiver_reason` (varchar).
    - `cooling_off_withdrawal_requested` (boolean).
    - `cooling_off_withdrawal_request_timestamp` (UTC timestamp).
    - `cooling_off_withdrawal_effective_timestamp` (UTC timestamp).
    - `cooling_off_withdrawal_reason` (varchar - customer reason if provided, e.g., "changed mind", "found better offer").

- **Disbursement Control Logic**:
  - **Pre-Disbursement Check**: Before executing disbursement, the system must verify:
    - `cooling_off_period_status IN ('EXPIRED', 'WAIVED')`.
    - If status is 'ACTIVE' (period has not yet expired and no waiver), disbursement is blocked with clear error message: "Disbursement cannot proceed - statutory cooling-off period active until [end_timestamp]."
  - **Scheduled Disbursement**: For loans with future disbursement dates (e.g., property completion in 3 weeks), the system must schedule the disbursement check for the later of: cooling-off expiry date OR planned disbursement date.

- **Reporting & Monitoring**:
  - **MI & Conduct Risk Reporting**: Track and report:
    - Number and % of customers exercising right of withdrawal, by product, channel, and reason (where available).
    - Number and % of early disbursement waivers requested and granted.
    - Any disbursements that occurred before cooling-off expiry (system should prevent this, but manual overrides or system errors must be flagged and investigated).
  - **Audit Trail**: Provide full audit trail for each loan showing cooling-off period dates, any waivers, withdrawal requests, and disbursement decisions, for regulatory inspection and customer complaints.

- **Customer Communication**:
  - **At Signature**: Clearly communicate to the customer:
    - "You have the right to withdraw from this agreement within 14 days starting from [cooling-off start date]."
    - "If you wish to withdraw, please contact us at [contact details] before [cooling-off end date]."
    - "If you need the funds urgently before the cooling-off period ends, you may request early disbursement by waiving your right of withdrawal."
  - **Pre-Expiry Reminder**: Optionally, send reminder 1-2 days before cooling-off expiry: "Your cooling-off period for loan [account_id] expires on [date]. If you wish to proceed, no action is needed. If you wish to cancel, please contact us immediately."

**Jurisdictional Variations**:
- **Switzerland (CCA)**: 14-day cooling-off period for consumer credit. Waiver permitted for urgent situations with explicit written consent.
- **EU (CCD)**: 14 calendar days. Waiver permitted only if consumer expressly requests it and acknowledges loss of withdrawal right.
- **UK (FCA CONC rules)**: Similar 14-day period for consumer credit. Mortgages regulated under MCOB have different reflection periods (7 days before offer acceptance for mortgages, distinct from post-contract withdrawal).
- **System Requirement**: The `cooling_off_period_days` and associated rules must be configurable per country and product type in the Country-Regime Configuration entity (Section 8.1).

---

## 8. Data, Analytics & Reporting Requirements

### 8.1 Data Model & Quality

**Requirements**

Define and maintain a harmonised logical data model for retail loans and mortgages across EMEA, with at least the following core entities and key attributes:

#### Product Catalogue (Reference Data / Configuration)
- **Keys**: product_id, country_code, effective_from_date, version_number.
- **Product Classification**:
  - product_type (MORTGAGE_OWNER_OCCUPIED, MORTGAGE_BUY_TO_LET, MORTGAGE_BRIDGE, PERSONAL_LOAN_TERM, PERSONAL_LOAN_REVOLVING, OVERDRAFT, HOME_EQUITY_LOAN, HOME_EQUITY_LINE_OF_CREDIT).
  - regulatory_scope (MCD_IN_SCOPE, CCD_IN_SCOPE, EXEMPT_BUSINESS_PURPOSE, OUT_OF_SCOPE).
  - customer_segment (MASS_MARKET, AFFLUENT, PRIVATE_BANKING, PROFESSIONAL_BORROWER, FIRST_TIME_BUYER).
- **Product Parameters**:
  - min_loan_amount, max_loan_amount (per country and segment).
  - min_term_months, max_term_months.
  - min_ltv, max_ltv (for secured products - varies by country, occupancy type, and customer segment).
  - interest_rate_type (FIXED, VARIABLE, MIXED_FIXED_THEN_VARIABLE, CAP_AND_COLLAR).
  - amortization_type (ANNUITY, INTEREST_ONLY, BULLET, BALLOON, FLEXIBLE).
  - repayment_frequency (MONTHLY, QUARTERLY, BI_ANNUAL, ANNUAL).
  - eligible_currencies (CHF, EUR, GBP, etc. - with FX lending restrictions per jurisdiction).
- **Eligibility Rules** (high-level flags pointing to detailed rule engine):
  - min_customer_age, max_customer_age_at_origination, max_customer_age_at_maturity.
  - permitted_employment_types (EMPLOYED_PERMANENT, EMPLOYED_TEMPORARY, SELF_EMPLOYED, RETIRED, STUDENT).
  - min_income_threshold (country-specific).
  - permitted_property_types (for mortgages: HOUSE, FLAT, TOWNHOUSE, MULTI_UNIT, exclusions for non-standard construction).
  - kyc_requirements (KYC_STANDARD, KYC_ENHANCED_PEP, KYC_ENHANCED_HIGH_RISK).
- **Pricing & Fees**:
  - base_rate_reference (LIBOR, EURIBOR, SONIA, SARON, bank_base_rate).
  - margin_range_min, margin_range_max (risk-based pricing band).
  - arrangement_fee, valuation_fee, early_repayment_charge_structure, annual_admin_fee, late_payment_fee.
  - fee_waiver_rules (e.g., waived for premier customers, promotional campaigns).
- **Channel & Distribution**:
  - permitted_channels (DIRECT_DIGITAL, DIRECT_BRANCH, BROKER_INTERMEDIARY, AGGREGATOR, WHITE_LABEL_PARTNER).
  - advice_vs_execution_only (both, advice_only, execution_only).
  - broker_commission_structure (where applicable).
- **Product Lifecycle & Governance**:
  - product_status (ACTIVE, SUSPENDED, WITHDRAWN, CLOSED_TO_NEW_BUSINESS).
  - launch_date, withdrawal_date, sunset_date (for closed books).
  - approval_authority (product committee sign-off, regulatory notifications).
  - last_review_date, next_review_due_date.
- **ESG & Green Products**:
  - is_green_product (boolean flag for products incentivizing energy-efficient properties).
  - green_eligibility_criteria (minimum_EPC_rating, renovation_commitment_required).
  - green_pricing_discount (margin reduction for qualifying properties).

#### Country-Regime Configuration (Reference Data / Configuration)
- **Keys**: country_code, regulatory_regime (e.g., SWITZERLAND_FINMA, UK_FCA, EU_MCD), effective_from_date.
- **LTV & Equity Rules**:
  - max_ltv_owner_occupied, max_ltv_buy_to_let, max_ltv_investment.
  - hard_equity_minimum_pct (e.g., 10% for Switzerland), soft_equity_allowed_pct.
  - second_rank_amortization_threshold_ltv (e.g., 66.67% for Switzerland), second_rank_amortization_years.
- **Affordability & Stress Testing**:
  - affordability_test_interest_rate (imputed rate, e.g., 5% for Switzerland regardless of market rate).
  - affordability_dsti_threshold (Debt Service to Income maximum, e.g., 33% for Switzerland, 40% for UK).
  - affordability_dti_threshold (Debt to Income maximum where applicable).
  - ancillary_cost_assumption_pct (e.g., 1% of property value for Switzerland).
  - rate_stress_margin_bps (e.g., +300 bps stress test for UK variable rate mortgages).
- **KYC & Refresh Policies**:
  - kyc_refresh_standard_months (e.g., 36 months), kyc_refresh_high_risk_months (e.g., 24 months), kyc_refresh_pep_months (e.g., 12 months).
  - kyc_documentary_evidence_requirements (per customer segment and risk rating).
- **Forbearance & Collections**:
  - max_payment_holiday_months, max_term_extension_years, max_interest_only_period_months.
  - arrears_collection_strategy_triggers (days past due thresholds for escalation).
  - foreclosure_timeline_typical_days (varies significantly by jurisdiction).
- **Regulatory Reporting Requirements**:
  - loan_level_reporting_required (boolean, e.g., true for certain EU member states).
  - reporting_frequency (quarterly, monthly), reporting_templates (references to regulatory schemas).
- **Product Restrictions & Prohibitions**:
  - fx_lending_restrictions (e.g., restrict CHF mortgages to customers with CHF income or strong FX hedge).
  - restricted_property_types (e.g., agriculturally zoned, houseboats, mobile homes).
  - restricted_customer_segments (e.g., non-residents, undischarged bankrupts).

#### Customer
- **Keys**: customer_id (group-wide), country_of_residence, primary_relationship_entity.
- **Attributes**: name, date_of_birth, gender (where legally permitted), nationality, residency_status, marital_status, number_of_dependants, contact_details, employment_status, occupation, vulnerable_customer_flag (where regulated, e.g. UK), tax_residency, FATCA/CRS_indicators, KYC_status, CDD_risk_rating, PEP_flag, sanctions_flag.

#### Application
- **Keys**: application_id, application_date_time, channel_id, country_of_booking, product_type (e.g. unsecured_loan, owner_occupied_mortgage, buy_to_let), application_status.
- **Attributes**: requested_amount, requested_term_months, requested_currency, purpose_of_loan, advice_vs_execution_only_flag, broker_or_partner_id (if intermediary), initial_pricing_offer (rate, margin, fees), consent_flags (bureau, marketing, data_processing), versioning (origination vs. reprice vs. restructure applications).
- **Relationships**: links to one or more Applicant/Co-Applicant/Guarantor records (see below).

#### Applicant / Co-Applicant / Guarantor (Application Parties)
- **Keys**: applicant_id, application_id, party_role (PRIMARY_APPLICANT, CO_APPLICANT, GUARANTOR, THIRD_PARTY_SECURITY_PROVIDER).
- **Party Identification**:
  - customer_id (link to Customer entity if existing bank customer), OR
  - applicant_first_name, applicant_last_name, applicant_date_of_birth, applicant_address (for new-to-bank applicants or guarantors).
- **Party Role & Responsibility**:
  - party_role (PRIMARY_APPLICANT: main borrower; CO_APPLICANT: joint borrower with equal liability; GUARANTOR: third-party credit support; THIRD_PARTY_SECURITY_PROVIDER: e.g., parent providing collateral).
  - liability_type (JOINT_AND_SEVERAL, SEVERAL_ONLY, GUARANTEE_LIMITED, GUARANTEE_UNLIMITED).
  - liability_percentage (for several-only arrangements, e.g., 50/50 split).
- **KYC & Compliance** (applies to ALL parties, not just primary applicant):
  - kyc_status (COMPLETED, PENDING, EXPIRED, ENHANCED_DUE_DILIGENCE_REQUIRED).
  - cdd_risk_rating (LOW, MEDIUM, HIGH, CRITICAL).
  - pep_flag, sanctions_flag, adverse_media_flag (from screening - all parties must be screened).
  - kyc_completion_date, kyc_expiry_date.
  - identity_verification_method (BRANCH_IN_PERSON, VIDEO_IDENT, EIDAS_QUALIFIED_SIGNATURE, EXISTING_CUSTOMER).
- **Financial Contribution to Affordability**:
  - contributes_to_income (boolean - does this party's income count toward affordability?).
  - gross_income, net_income (if contributing).
  - employment_status, employment_type, employer_name, years_in_employment.
  - existing_debts_and_commitments (internal + bureau, if income is counted).
  - individual_dti_ratio, individual_dsti_ratio.
  - affordability_contribution_weight (e.g., 100% for primary and co-applicant, 0% for non-income guarantor).
- **Relationship to Property/Collateral**:
  - is_property_owner (for co-owners providing security).
  - property_ownership_percentage (e.g., 50% ownership in jointly-owned property).
  - occupancy_intention (WILL_OCCUPY, WILL_NOT_OCCUPY - relevant for MCD owner-occupied vs buy-to-let classification).
- **Legal & Contractual**:
  - party_consent_to_credit_check (required for all parties).
  - party_signature_status (PENDING, SIGNED, WITNESSED).
  - party_signature_date, signature_method (WET_SIGNATURE, EIDAS_ESIGNATURE, ADVANCED_ESIGNATURE).
  - legal_capacity_confirmed (e.g., not under legal guardianship, bankruptcy, etc.).
- **Communication & Contact**:
  - contact_phone, contact_email, preferred_contact_method.
  - communication_language_preference.
  - correspondence_address (if different from property address).
- **Vulnerability Characteristics** (aligned with UK FCA Consumer Duty and emerging EU consumer protection expectations):
  - **vulnerable_customer_flag** (boolean - master flag indicating any vulnerability characteristics present).
  - **Vulnerability Categories** (multiple may apply simultaneously):
    - **Health-Related Vulnerability**:
      - physical_disability_flag, mental_health_condition_flag, serious_illness_flag, cognitive_impairment_flag.
      - vulnerability_severity (MILD, MODERATE, SEVERE - influences treatment approach).
    - **Life Events**:
      - recent_bereavement_flag (within 12 months), relationship_breakdown_flag, job_loss_or_income_shock_flag.
      - domestic_abuse_or_coercion_flag (requires specialist handling and safeguarding protocols).
    - **Financial Resilience**:
      - low_financial_resilience_flag (limited savings, income volatility, high debt-to-income, recent arrears on other obligations).
      - over_indebtedness_risk_flag (multiple creditors, county court judgments, debt management plan).
    - **Capability & Understanding**:
      - low_literacy_or_numeracy_flag, limited_language_proficiency (requires translated materials or interpreter).
      - limited_digital_capability_flag (requires non-digital contact channels).
      - age_related_vulnerability (very young first-time buyers with limited experience, elderly customers with declining capacity).
    - **Power of Attorney / Legal Capacity**:
      - has_power_of_attorney_flag (boolean), poa_holder_name, poa_holder_contact, poa_type (FINANCIAL, HEALTH_AND_WELFARE, LASTING, ENDURING).
      - legal_capacity_concerns_flag (e.g., mental capacity assessment required under Mental Capacity Act in UK or equivalent).
      - appointed_representative_flag (for customers lacking capacity, decisions made by representative).
  - **Vulnerability Documentation**:
    - vulnerability_identification_date, vulnerability_identified_by (CUSTOMER_SELF_DECLARED, STAFF_OBSERVATION, THIRD_PARTY_NOTIFICATION).
    - vulnerability_review_date (periodic re-assessment, e.g., annually or when circumstances change).
    - vulnerability_notes (free text for context - e.g., "customer has terminal illness, requires expedited forbearance decisions").
  - **Treatment & Safeguards Applied**:
    - requires_specialist_team_flag (route to trained vulnerability handlers).
    - requires_extended_response_time_flag (allow longer cooling-off periods, decision timelines).
    - communication_adaptations_required (LARGE_PRINT, AUDIO, VIDEO, FACE_TO_FACE_ONLY, NOMINATED_THIRD_PARTY).
    - automatic_forbearance_eligibility_flag (fast-track forbearance for vulnerable customers in financial difficulty).
- **Notes & Special Considerations**:
  - relationship_to_primary_applicant (SPOUSE, PARENT, CHILD, SIBLING, BUSINESS_PARTNER, OTHER).
  - guarantor_advice_received (for guarantors - regulatory expectation that they receive independent legal advice in some jurisdictions).
  - guarantor_vulnerability_assessment_completed (for vulnerable guarantors, especially elderly parents, ensure they understand liability and received appropriate advice).

**Regulatory & Business Rationale**:
- **MCD & CCD Requirements**: Where co-applicants or guarantors exist, each must undergo proper KYC and creditworthiness assessment.
- **Affordability Assessment**: Income and debts of ALL parties with joint liability or income contribution must be aggregated.
- **Legal Enforceability**: Clear documentation of each party's role, liability, and consent is critical for collections and enforcement.
- **Fair Treatment & Vulnerability**: Guarantors (especially parental guarantees) may be vulnerable customers requiring additional protections and disclosure.

#### Mortgage/Loan Account (Exposure)
- **Keys**: account_id, account_open_date, account_status, portfolio_segment (e.g. prime, near_prime), booking_entity, IFRS9_stage.
- **Attributes**: approved_amount, current_outstanding_principal, interest_rate_type (fixed/variable/mixed), current_interest_rate, margin_over_reference_rate, amortisation_type (annuity, interest_only, bullet), contractual_term_months, remaining_term_months, repayment_frequency, product_variant (e.g. green_mortgage, first_time_buyer), linked_insurance_products.

#### Property / Collateral (for mortgages and secured lending)
- **Keys**: collateral_id, property_identifier (e.g. land_registry_id), collateral_type, collateral_status.
- **Attributes**: property_address (country, region, postcode), property_type (house, flat, multi_unit, mixed_use), occupancy_type (owner_occupied, buy_to_let, holiday_home), construction_year, valuation_value, valuation_date, valuation_method (AVM/manual/hybrid), valuation_provider, original_LTV, current_LTV, legal_charge_rank, foreclosure_status.
- **ESG & Environmental Risk Attributes** (per EBA GL and ECB climate risk guidance):
  - **Energy Performance**: energy_performance_certificate_rating (A+ to G scale per EU directive, or country equivalent), energy_consumption_kwh_per_m2, heating_system_type, insulation_quality, renewable_energy_features (solar panels, heat pumps).
  - **Climate Physical Risk**: flood_risk_zone (high/medium/low per national mapping), coastal_erosion_risk, subsidence_risk, wildfire_risk_zone, climate_vulnerability_score.
  - **Green Features**: green_mortgage_eligible (boolean flag for EU Taxonomy alignment), recent_energy_improvements (insulation, window upgrades, heating system), planned_renovation_commitment (linked to green mortgage incentives).
  - **Environmental Assessments**: soil_contamination_flag, asbestos_presence, radon_risk, environmental_survey_date.
  - **Transition Risk Indicators**: property_carbon_footprint_estimate, pathway_to_net_zero_alignment (for new-build or extensively renovated properties).

#### Collateral-to-Loan Relationship (Link Table for M:M Relationships)

**Rationale**: In complex retail lending scenarios, the relationship between loans and collateral is not always simple 1:1 or 1:N. The following scenarios require a **Many-to-Many (M:M)** relationship managed via a **Link Table**:

1. **Cross-Collateralization**: One loan secured by multiple properties (e.g., mortgage secured by both primary residence and holiday home to achieve acceptable LTV).
2. **Pooled Collateral**: Multiple loans secured by a single property (e.g., primary mortgage + home equity line of credit on the same property).
3. **Second Charges / Junior Liens**: The bank holds a 2nd rank mortgage on a property where another lender holds the 1st rank. Multiple lenders have simultaneous charges on the same collateral.
4. **Collateral Substitution During Portability**: When a customer ports their mortgage from Property A to Property B, there is a transitional period where both properties may be linked to the same loan account for audit and legal tracking.

**Link Table Entity: `Loan_Collateral_Link`**

- **Keys**:
  - link_id (unique identifier for each loan-collateral linkage).
  - account_id (FK to Mortgage/Loan Account).
  - collateral_id (FK to Property/Collateral).
  - effective_from_date (when this collateral began securing this loan).
  - effective_to_date (when this collateral ceased securing this loan - NULL if still active).

- **Attributes**:
  - **charge_rank** (1ST, 2ND, 3RD, SUBSEQUENT - the bank's ranking on this collateral for this loan).
  - **charge_amount** (the monetary value of the charge/lien registered - may differ from loan balance if partially secured).
  - **collateral_allocation_pct** (if one property secures multiple loans, what % of this property's value is allocated to this loan for LTV and recovery calculations).
  - **charge_registration_status** (PENDING, REGISTERED, DISCHARGED, DISPUTED).
  - **registration_authority_reference** (land registry reference number, cadastral ID, or equivalent).
  - **priority_agreement_flag** (boolean - indicates if an intercreditor or subordination agreement exists with other lenders on the same collateral).
  - **portability_transition_flag** (boolean - TRUE if this is a transitional link during mortgage porting).
  - **notes** (free text for context - e.g., "2nd charge subject to consent from 1st charge holder [Competitor Bank]").

- **Derived Metrics**:
  - **Loan-Level LTV**: For a given loan, calculate weighted average LTV across all linked collateral, considering charge rank and allocation percentages.
  - **Collateral-Level Exposure**: For a given property, sum all loans (internal and, where known, external) to assess total encumbrance and residual security value.
  - **Recovery Waterfall**: In default scenarios, model expected recovery based on charge rank, property value, and seniority of claims.

**Data Quality & Governance**:
- **Mandatory Validation**: Ensure that every secured loan account has at least one active link (effective_to_date IS NULL) to a collateral record. Alerts if loan is flagged as secured but no active collateral link exists.
- **Charge Rank Validation**: For the same collateral_id, ensure no duplicate charge_rank values from the same lender (the bank cannot hold two "1st charges" on the same property).
- **Historical Tracking**: Maintain full history of collateral links (never delete - use effective_to_date for temporal tracking) to support portability audits, charge release tracking, and regulatory inquiries.

#### Income & Expense Profile
- **Keys**: income_profile_id, effective_from_date, calculation_method.
- **Attributes**: gross_income, net_income, income_components (fixed_salary, variable_bonus, rental_income, other_income) with currency and frequency, verified_vs_declared_flags, living_expenses (standard_budget vs. declared), total_debt_obligations (internal + bureau), DTI_ratio, DSTI_ratio, affordability_result (pass/fail, reason_codes).

#### Payment Schedule & Transactions
- **Payment Schedule Attributes**: schedule_id, schedule_generation_date, instalment_amount, principal_component, interest_component, fee_component, due_dates, balloon_or_residual_amounts, grace_periods.
- **Transaction Attributes**: transaction_id, posting_date, value_date, transaction_type (instalment_payment, prepayment, fee, interest_capitalisation, write_off, recovery), amount, currency, channel, arrears_bucket_after_transaction.

#### Risk & Behavioural Data
- **Attributes**: application_score, behavioural_score, bureau_score(s), probability_of_default (PD) segment, LGD_model_segment, early_warning_indicators (payment_behaviour_flags, utilisation_patterns), NPE_flag, forbearance_flag, days_past_due, default_date, cure_date.

#### Communications & Customer Interactions
(aligned with synthetic email generation use cases)
- **Keys**: communication_id, customer_id, account_id (where applicable), channel (email, sms, letter, app_message), journey_stage (pre_approval, approval, drawdown, arrears, restructuring, retention).
- **Attributes**: template_id, subject_line, send_timestamp, delivery_status, open_and_click_metrics (where permitted), language, country_specific_disclosures_included (Y/N), conduct_risk_flags (e.g. potential_mis_sale_indicator based on content/rules).

---

**Ensure data quality management is embedded across the lifecycle:**

- Define mandatory attributes per entity and per lifecycle stage, aligned with EBA loan origination guidelines and national supervisor expectations (e.g. application cannot proceed to underwriting without minimum income, employment, KYC, property and valuation data; mortgage account cannot be boarded to production without collateral registration status).

- Implement validation rules at capture and ingestion:
  - Format, domain, and range checks (e.g. age, term, LTV, DTI/DSTI thresholds by product and country).
  - Cross-entity consistency checks (e.g. country_of_residence vs. booking_entity vs. collateral_country; currency_of_income vs. loan_currency for FX-mortgage eligibility).
  - Referential integrity between customer, application, account, collateral, and communication records.

- Maintain data lineage from source systems (channels, core banking, bureau feeds, valuation providers, communication platforms) through transformation into analytical and reporting layers, so that any regulatory report, risk calculation, or synthetic email use case can be traced back to the originating records and business events.

- Monitor and remediate data quality via metrics and workflows:
  - KPIs (e.g. % of applications with complete income/expense data, % of mortgage accounts with up-to-date valuations, % of records with valid customer_id and account_id links, % communications with correct journey_stage tagging).
  - Issue management workflows for systematic data defects (identification, ownership, remediation plan, and control enhancements).

**Data Retention & Archiving**:

- Define and implement entity-specific retention periods aligned with GDPR Article 5(1)(e) (storage limitation), local regulations, and internal policies:
  - **Applications**: Minimum 7 years post-decision (or longer where regulatory reporting obligations exist, e.g., EBA loan-level data requirements).
  - **Loan Accounts & Transactions**: Minimum 7-10 years post-closure (varies by jurisdiction; longer for tax, audit, and litigation purposes).
  - **Affordability Calculations & Decisioning Records**: Minimum 7 years to support regulatory examinations and customer complaints.
  - **KYC & CDD Documentation**: Minimum 5-7 years post-relationship termination (aligned with AML/CTF record-keeping requirements per AMLD).
  - **Collateral Valuation Reports**: Minimum 10 years (may be required for legal disputes, insurance claims, or regulatory reviews).
  - **Customer Communications**: Minimum 7 years for regulatory compliance and complaint handling (aligned with MiFID II/distance selling/consumer credit retention expectations).
  - **Model Documentation & Validation Reports**: Life of model + 7 years post-decommissioning (for model risk governance and audit trail).
- Implement automated archiving processes:
  - Move aged data from operational databases to secure archival storage (e.g., read-only data lakes, compliance archives).
  - Maintain data lineage and retrieval mechanisms for regulatory inspections, audits, and customer subject access requests (GDPR Article 15).
- Define secure deletion procedures post-retention:
  - Irreversible deletion or physical destruction of data beyond retention periods, unless legal hold or ongoing litigation requires preservation.
  - Documented evidence of deletion for GDPR accountability and compliance audits.

**Data Masking & Pseudonymisation**:

- Implement pseudonymisation and masking for personal data used beyond retention windows or in non-production environments (GDPR Article 25 - data protection by design):
  - **Non-Production Environments** (development, testing, UAT, analytics sandboxes):
    - **Pseudonymisation**: Replace direct identifiers (names, addresses, contact details, national ID numbers) with hashed or tokenised equivalents.
    - **Masking**: Apply format-preserving masking to sensitive fields (e.g., partial masking of account numbers, dates of birth with year preserved but day/month masked).
    - **Synthetic Data**: Where feasible, use synthetic data generation for testing and model development (e.g., AAA Synthetic Bank approach with `mortgage_email_generator.py`).
  - **Analytics & Reporting Beyond Retention**:
    - Aggregate data to cohort/segment level to remove individual identifiability (k-anonymity principles).
    - Use tokenised customer IDs that cannot be reverse-engineered without access to secure key management systems.
  - **Masking Standards**:
    - Preserve analytical utility (e.g., maintain data distributions, referential integrity, and statistical properties for model training and portfolio analysis).
    - Apply role-based access controls (RBAC) to unmasked production data, limiting access to authorised personnel with legitimate business need.
    - Audit and log access to unmasked sensitive data for accountability and GDPR Article 32 security requirements.

### 8.2 Risk, Finance & Regulatory Reporting

**Requirements**

- Provide data to support:
  - Regulatory capital and risk reporting (e.g. COREP, FINREP, local templates).
  - IFRS9 / impairment calculations (PD, LGD, EAD inputs, staging, write-offs, recoveries).
  - Stress testing and scenario analysis, including macroeconomic overlays on retail portfolios.

- Enable granular, explainable loan-level reporting:
  - To national competent authorities (NCAs) and central banks (e.g. loan-level data for mortgage markets where required).
  - For supervisory deep dives into underwriting standards, collateral, and affordability outcomes.

### 8.3 Customer & Conduct Outcomes

**Requirements**

- Capture and analyse data on:
  - Sales practices, product mix, cross-sell, and potential mis-selling indicators.
  - Customer complaints, resolution times, outcomes, and root causes.
  - Outcomes for vulnerable customers where such categories exist in local rules (e.g. UK Consumer Duty).

- Provide management information (MI) to demonstrate:
  - Fair treatment of customers across the product lifecycle.
  - That pricing, fees, and product structures deliver fair value to customers (not excessive or hidden charges).

---

## 9. Controls, Governance & Audit

**Requirements**

- Define and maintain credit policies and standards:
  - Documented rulesets for each product, country, and segment.
  - Clear ownership, approval, and review cycles (at least annually or on regulatory change).

- Implement control framework:
  - Preventive controls: eligibility rules, automated policy rules, system-enforced caps.
  - Detective controls: sampling, post-disbursement quality checks, portfolio monitoring.

- Ensure segregation of duties:
  - Separation between origination, underwriting, and approval hierarchies.
  - Independent model validation and risk oversight.

- Provide full audit trail:
  - Who changed what (policy, configuration, data), when, and why.
  - Underwriting and override logs, including rationale and approvals.

### 9.1 Model Risk Management

**Regulatory Context**: EBA Guidelines on Loan Origination and Monitoring (EBA/GL/2020/06) require robust governance for automated models and credit decisioning, including explainability, validation, and ongoing monitoring.

**Scope of Models**:
- Application scoring models (behavioural, bureau-based, application score)
- Affordability and debt-service models (income verification, expense calculation, stress testing)
- Pricing models (risk-based pricing, margin calculation, competitive positioning)
- Property valuation models (AVM - Automated Valuation Models, price indices)
- Early Warning Systems (EWS) for portfolio monitoring and arrears prediction
- Credit decisioning engines (automated policy rules, override detection)
- Any AI/ML models used in credit assessment, fraud detection, or customer segmentation

**Requirements**:

#### Model Governance Framework
- **Model Owner**: Clear accountability for each model (typically Risk, Credit Analytics, or Pricing)
- **Model Inventory**: Centralized register of all models with classification (high/medium/low materiality based on usage, exposure, complexity)
- **Model Approval**: Formal approval process by Model Risk Committee before production deployment
- **Three Lines of Defense**:
  - 1st Line: Model development and ownership (Risk, Credit Analytics)
  - 2nd Line: Independent model validation and ongoing review (Model Risk Management function)
  - 3rd Line: Internal Audit periodic review of model risk framework

#### Model Development & Documentation Standards
- **Conceptual Soundness**: Model design aligned with economic theory and lending principles
- **Data Quality**: Input data quality assessment, minimum data requirements, data lineage documentation
- **Model Documentation**: Comprehensive documentation including:
  - Model purpose, scope, and limitations
  - Methodology and assumptions
  - Development sample characteristics and performance metrics
  - Sensitivity analysis and scenario testing results
  - Known model limitations and compensating controls
- **Versioning & Change Control**: Version management with documented changes, change approval, and impact assessment

#### Independent Model Validation
- **Pre-Production Validation**: Independent review before initial deployment covering:
  - Conceptual soundness and methodology review
  - Data quality and representativeness assessment
  - Back-testing and performance validation on out-of-sample data
  - Sensitivity and stress testing
  - Implementation verification (code review, unit testing)
- **Periodic Re-Validation**: At least annually for material models, or triggered by:
  - Significant performance degradation
  - Material portfolio or market changes
  - Regulatory changes or guidance updates
  - Model enhancements or methodology changes
- **Challenger Models**: Where feasible, maintain alternative models or approaches to benchmark performance

#### Ongoing Monitoring & Performance Tracking
- **Performance Metrics**: Regular monitoring (at least quarterly) of:
  - **Accuracy metrics**: For scoring models, track calibration (predicted vs actual default rates), discrimination (Gini, KS statistics), concentration curves
  - **Affordability models**: Track predicted vs actual payment difficulties, false positive/negative rates
  - **Pricing models**: Track achieved margins vs predicted, competitive win rates, profitability by segment
  - **Valuation models**: Compare AVM estimates to actual transaction prices (validation sample)
- **Model Drift**: Detection and measurement of:
  - Population drift (changes in customer/application characteristics)
  - Performance drift (deterioration in predictive accuracy)
  - Environmental drift (macroeconomic, regulatory, competitive changes)
- **Override Analysis**: Systematic tracking and analysis of:
  - Override frequency and reasons (risk, policy, customer relationship)
  - Override outcomes vs model recommendations
  - Identification of systematic override patterns suggesting model weakness
- **Bias & Fairness Monitoring**: Where applicable and legally permissible:
  - Monitoring for unintended bias across customer segments
  - Fair lending analysis (consistent treatment across protected characteristics)
  - Explainability and transparency of decisioning

#### Explainability & Transparency (GDPR Article 22 Compliance)
- **Automated Decision Rights**: Where credit decisions are made solely by automated means:
  - Customers must be informed that the decision is automated
  - Customers have the right to request human review and intervention
  - Customers can contest automated decisions
- **Decision Explanations**: System must provide:
  - **Primary adverse action reasons**: Top 3-5 factors contributing to decline or adverse pricing (e.g., insufficient income, high debt-to-income ratio, credit history gaps, LTV exceeds policy limits)
  - **Structured reason codes**: Standardized reason codes aligned with regulations (FCRA in US analogs, CCD/MCD disclosure expectations in EU)
  - **Customer-facing explanations**: Clear, non-technical language explaining decision rationale

- **Explainability Standards & Technical Implementation**:
  
  - **For All Automated Declines and Adverse Decisions**:
    - **MANDATORY**: The system must store the **top 3-5 negative contribution factors** (reason codes) for every automated decline, adverse pricing decision, or LTV/loan amount reduction.
    - **Data Structure**: Create a `decision_reason_codes` table or JSON structure linked to each application_id or decision_id:
      ```
      decision_reason_id (PK)
      application_id (FK)
      decision_type (DECLINE, ADVERSE_PRICING, REDUCED_AMOUNT, REFER_TO_MANUAL_REVIEW)
      reason_rank (1, 2, 3, 4, 5 - ranked by contribution magnitude)
      reason_code (standardized code, e.g., DTI_EXCEEDS_THRESHOLD, INSUFFICIENT_INCOME, CREDIT_SCORE_BELOW_MINIMUM)
      reason_description (human-readable, customer-facing text)
      feature_name (technical model feature name, e.g., debt_to_income_ratio, credit_bureau_score)
      feature_value (actual value for this application, e.g., 0.48 for DTI)
      threshold_or_policy_value (threshold that was breached, e.g., 0.40 for DTI threshold)
      contribution_score (quantified impact on decision - SHAP value, weight, or equivalent)
      contribution_score_method (SHAP, LIME, RULE_BASED, LINEAR_WEIGHT)
      model_version_used (to support audit and model change tracking)
      ```
    - **Retention**: Reason codes must be retained for the full regulatory retention period (typically 5-10 years post-application) to support customer complaints, regulatory audits, and fair lending reviews.

  - **Model Explainability Techniques** (by model type):
    
    - **Rule-Based / Policy Decisioning Engines**:
      - For simple policy rules (e.g., "IF DTI > 40% THEN DECLINE"), reason codes are directly derived from violated rules.
      - Store: rule_name, rule_condition, actual_value, threshold_value.
    
    - **Linear Models (Logistic Regression, Linear Scoring)**:
      - Reason codes derived from feature coefficients (weights) multiplied by standardized feature values.
      - Rank features by absolute contribution to final score: |coefficient × (feature_value - mean)|.
      - Store: top 3-5 features with highest negative contribution to approval/score.
    
    - **Tree-Based Models (Random Forest, Gradient Boosting, XGBoost)**:
      - **SHAP (SHapley Additive exPlanations)** is the **recommended explainability method** for tree-based models.
      - **Implementation**:
        - At decision time, calculate SHAP values for each input feature for the specific application.
        - SHAP values quantify each feature's contribution to the model output (e.g., probability of default, credit score).
        - For **declines**, rank features by most negative SHAP value (features pushing score below approval threshold).
        - Store top 3-5 features with most negative SHAP values as reason codes.
      - **Example**:
        ```
        Application ID: APP_12345
        Decision: DECLINE (Credit Score = 625, Threshold = 650)
        
        Top Reason Codes (SHAP-derived):
        1. credit_bureau_score = 580 (SHAP: -45) - "Credit score below minimum requirement"
        2. debt_to_income_ratio = 0.52 (SHAP: -30) - "Debt-to-income ratio exceeds 40% limit"
        3. months_in_current_employment = 4 (SHAP: -18) - "Insufficient employment tenure"
        4. late_payments_last_12m = 2 (SHAP: -12) - "Recent payment delinquencies"
        5. number_of_credit_inquiries = 5 (SHAP: -8) - "Multiple recent credit applications"
        ```
      - **SHAP Library**: Use Python `shap` library (shap.TreeExplainer for tree models) or equivalent in production scoring environment.
      - **Performance Consideration**: SHAP calculation can be computationally expensive for deep ensembles. Optimize by:
        - Pre-computing SHAP for representative samples during model validation.
        - Using approximate SHAP (e.g., shap.TreeExplainer with `feature_perturbation='interventional'`).
        - Caching SHAP baseline values (expected model output on training data).
    
    - **Neural Networks / Deep Learning Models**:
      - **LIME (Local Interpretable Model-agnostic Explanations)** or **Integrated Gradients** are suitable for neural networks.
      - **LIME Implementation**:
        - Generate perturbed samples around the specific application's feature values.
        - Train a local linear surrogate model to approximate the neural network's behavior in the local region.
        - Rank features by the surrogate model's coefficients (similar to linear models).
        - Store top 3-5 features with most negative contributions as reason codes.
      - **Alternative**: Layer-wise Relevance Propagation (LRP) or attention mechanisms for deep networks.
      - **Performance**: LIME is computationally lighter than SHAP but less theoretically robust. Use for real-time decisions; store results for audit.
    
    - **Black Box / Third-Party Models** (where internal explainability is not possible):
      - If using third-party bureau scores or proprietary models without access to internals:
        - Request **adverse action reason codes** from vendor (legally required in many jurisdictions).
        - If vendor cannot provide, implement **shadow linear model** or **challenger model** using available features to generate approximate reason codes.
        - Flag these as "APPROXIMATE_VENDOR_MODEL" in the reason code method field.
      - **Compensating Control**: Require human review for all declines where explainability is weak, or restrict use of black-box models to low-materiality decisions only.

  - **Explainability Governance**:
    - **Model Validation Requirement**: Model validation must include explainability testing:
      - Verify that reason codes are sensible, consistent, and aligned with known model behavior.
      - Test on edge cases (e.g., marginal declines) to ensure reason codes are stable and meaningful.
      - Compare automated reason codes with human underwriter expectations for consistency.
    - **Monitoring**:
      - Track frequency distribution of reason codes (e.g., "DTI_EXCEEDS_THRESHOLD" appears in 45% of declines).
      - Detect anomalies (e.g., sudden shift in reason code distribution may indicate model drift or data quality issue).
    - **Customer Communication**:
      - Translate technical reason codes into **customer-facing adverse action notices**:
        - "Your application was declined because your debt-to-income ratio (52%) exceeds our lending policy limit (40%). You may improve your eligibility by reducing existing debts or increasing income."
      - Provide contact details for customers to request human review or dispute the decision.
    - **Fair Lending & Bias Detection**:
      - Analyze reason code distribution across protected classes (where legally permitted and for internal fairness monitoring).
      - Ensure that reason codes do not systematically disadvantage protected groups (e.g., proxy discrimination via feature selection).

  - **Audit Trail**:
    - Maintain audit trail linking decisions to specific model versions, input data, thresholds, and **explainability outputs** (SHAP/LIME values, reason codes).
    - Ensure full reproducibility: given application_id and model_version, can regenerate the exact decision and reason codes.

#### Documentation & Audit Trail
- **Model Change Log**: Record of all model changes, including parameter adjustments, recalibrations, and methodology updates
- **Decision Log**: Retain records of:
  - Model-driven decisions (application ID, model version, input data, outputs, final decision)
  - Overrides and exceptions (who, when, why, outcome)
  - Customer explanations provided (for complaint handling and audit)
- **Audit Evidence**: Maintain evidence for regulatory inspections:
  - Model validation reports and sign-offs
  - Monitoring dashboards and performance reviews
  - Model Risk Committee minutes and decisions
  - Override analysis and remediation actions

#### Model Remediation & Lifecycle Management
- **Performance Thresholds**: Define triggers for model review or decommissioning:
  - Accuracy degradation beyond tolerance (e.g., >5% deterioration in Gini coefficient)
  - Significant override rates (e.g., >15% of automated decisions overridden)
  - Regulatory concerns or supervisor feedback
- **Remediation Actions**: Defined process for:
  - Model recalibration (parameter updates using recent data)
  - Model redevelopment (methodology change, feature engineering)
  - Model decommissioning and replacement
  - Interim compensating controls while remediation in progress
- **End-of-Life**: Formal process for retiring models with data archiving and transition planning

---

## 10. Non-Functional Requirements

**Requirements**

- **Scalability and performance**
  - Support high application volumes and peak loads (e.g. rate campaigns) with acceptable response times.

- **Availability & resilience**
  - High-availability architecture with appropriate RPO/RTO.
  - Business continuity and disaster recovery aligned with operational resilience expectations.

- **Digital Operational Resilience (DORA - EU Regulation 2022/2554)**
  - **ICT Risk Management**: Comprehensive framework for identifying, protecting against, detecting, responding to, recovering from, and learning from ICT-related incidents.
  - **Incident Management**: Incident reporting, classification, and escalation processes for ICT disruptions.
  - **Digital Operational Resilience Testing**: Regular testing including threat-led penetration testing (TLPT) for critical entities.
  - **Third-Party ICT Risk Management**: Due diligence, monitoring, and contractual arrangements for ICT service providers (especially critical third parties).
  - **Information Sharing**: Participation in threat intelligence and cyber threat information sharing arrangements.
  - Note: DORA applies to EU operations and covers lending platforms, decisioning engines, document management, and customer portals.

- **Security & privacy**
  - Role-based access control (RBAC), least-privilege principles.
  - Encryption in transit and at rest, strong key management.
  - Compliance with GDPR and local data residency requirements (e.g. data localisation where mandated).

- **Configurability**
  - Country-level parameterisation of lending rules, thresholds, templates, and communication content.
  - Ability to introduce new products / variants with minimal IT change.

- **Observability & monitoring**
  - Logging, metrics, and alerting across critical processes (decisioning, KYC, disbursement, collections).
  - Dashboards for business, risk, and IT stakeholders.

---

## 11. Assumptions & Out-of-Scope

### Assumptions

- A separate enterprise KYC/AML platform exists and is integrated.
- Group-level data, analytics and reporting platforms provide shared risk/finance capabilities (e.g. IFRS9 engine, regulatory reporting factory).
- Country entities are willing to converge on a common target operating model with parameterisation rather than bespoke processes.

### Out-of-scope (for this document)

- Detailed technical architecture and vendor selection.
- Non-retail lending (SME, corporate, project finance) except where using the same core capabilities.
- Detailed HR, training and incentive structures for sales and underwriting staff, though these must be aligned with responsible lending principles and conduct rules.

---

## 12. Implementation Alignment with Existing AAA Synthetic Bank Infrastructure

This section maps the business requirements to the existing data platform capabilities, demonstrating how the retail loans and mortgages module can be built using established infrastructure and reusable components.

### 12.1 Existing Infrastructure Capabilities

#### A. Customer Master & 360-Degree View
**Existing Component**: `structure/410_CRMA_customer_360.sql`

**Capabilities Already Implemented**:
- Comprehensive customer profile with master data (name, DOB, onboarding date, contact details)
- Current and historical address tracking (SCD Type 2)
- Employment and income range tracking
- Risk classification and credit score bands
- Account relationships and balances (AUM tracking)
- Transaction activity metrics (engagement scoring, dormancy detection)
- PEP and sanctions screening integration
- Advisor assignment and relationship management

**Reusable for Retail Loans**:
- Customer eligibility checking (age, residency, KYC status, risk classification)
- Income verification and affordability assessment baseline
- Existing relationship tenure for preferential pricing
- Address history for residential stability analysis
- Combined risk scoring (credit, AML, transaction anomalies)

**Integration Point**:
```sql
-- Example: Loan application eligibility check using Customer 360
SELECT 
    c.CUSTOMER_ID,
    c.FULL_NAME,
    c.DATE_OF_BIRTH,
    DATEDIFF(year, c.DATE_OF_BIRTH, CURRENT_DATE()) as AGE,
    c.COUNTRY,
    c.RISK_CLASSIFICATION,
    c.CREDIT_SCORE_BAND,
    c.INCOME_RANGE,
    c.EMPLOYMENT_TYPE,
    c.TOTAL_BALANCE as EXISTING_AUM,
    c.TOTAL_ACCOUNTS,
    c.DAYS_SINCE_LAST_TRANSACTION,
    c.OVERALL_RISK_RATING,
    c.REQUIRES_SANCTIONS_REVIEW,
    c.REQUIRES_EXPOSED_PERSON_REVIEW,
    DATEDIFF(day, c.ONBOARDING_DATE, CURRENT_DATE()) as RELATIONSHIP_TENURE_DAYS
FROM CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 c
WHERE c.CURRENT_STATUS = 'ACTIVE'
  AND DATEDIFF(year, c.DATE_OF_BIRTH, CURRENT_DATE()) BETWEEN 18 AND 75  -- Age eligibility
  AND c.OVERALL_RISK_RATING NOT IN ('CRITICAL')  -- Basic risk screening
  AND c.REQUIRES_SANCTIONS_REVIEW = FALSE;  -- Sanctions clearance
```

#### B. KYC & Compliance Screening
**Existing Components**: 
- `structure/302_CRMA_sanctions_screening.sql` - Sanctions screening with fuzzy matching
- `notebooks/customer_screening_kyc.ipynb` - KYC compliance dashboard

**Capabilities Already Implemented**:
- Real-time sanctions screening (OFAC, EU, UN lists)
- PEP identification with accuracy scoring
- Risk-based KYC refresh policies
- SLA tracking and breach alerting
- Customer audit trails for regulatory inquiries
- Multi-signal matching (name, DOB, nationality)

**Reusable for Retail Loans**:
- Mandatory KYC/AML checks before loan approval (Section 7.3)
- Enhanced due diligence for high-risk applicants
- Automated compliance screening in loan origination workflow
- Regulatory audit evidence generation
- Customer suitability assessment

**Integration Point**:
```sql
-- Example: Loan application compliance screening
WITH loan_application_compliance AS (
    SELECT 
        c.CUSTOMER_ID,
        c.FULL_NAME,
        c.COUNTRY,
        c.RISK_CLASSIFICATION,
        -- KYC Status
        CASE 
            WHEN DATEDIFF(day, c.ONBOARDING_DATE, CURRENT_DATE()) > 365 
                 AND c.OVERALL_RISK_RATING IN ('HIGH', 'CRITICAL')
            THEN 'KYC_REFRESH_REQUIRED'
            WHEN DATEDIFF(day, c.ONBOARDING_DATE, CURRENT_DATE()) > 1095
            THEN 'KYC_REFRESH_REQUIRED'
            ELSE 'KYC_CURRENT'
        END as KYC_STATUS,
        -- Sanctions Screening
        sanctions.SANCTIONS_MATCH_TYPE,
        sanctions.ALERT_PRIORITY as SANCTIONS_ALERT_PRIORITY,
        sanctions.DISPOSITION_RECOMMENDATION,
        -- PEP Status
        c.EXPOSED_PERSON_MATCH_TYPE as PEP_STATUS,
        c.OVERALL_EXPOSED_PERSON_RISK,
        -- Overall Eligibility
        CASE 
            WHEN c.REQUIRES_SANCTIONS_REVIEW = TRUE THEN 'BLOCKED_SANCTIONS'
            WHEN c.EXPOSED_PERSON_MATCH_TYPE = 'EXACT_MATCH' 
                 AND c.OVERALL_EXPOSED_PERSON_RISK = 'CRITICAL' THEN 'ENHANCED_DD_REQUIRED'
            WHEN c.OVERALL_RISK_RATING = 'CRITICAL' THEN 'MANUAL_REVIEW_REQUIRED'
            WHEN DATEDIFF(day, c.ONBOARDING_DATE, CURRENT_DATE()) > 365 
                 AND c.OVERALL_RISK_RATING IN ('HIGH', 'CRITICAL') THEN 'KYC_REFRESH_REQUIRED'
            ELSE 'COMPLIANT'
        END as COMPLIANCE_STATUS
    FROM CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 c
    LEFT JOIN CRM_AGG_001.CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING sanctions
        ON c.CUSTOMER_ID = sanctions.CUSTOMER_ID
)
SELECT * FROM loan_application_compliance
WHERE COMPLIANCE_STATUS IN ('COMPLIANT', 'ENHANCED_DD_REQUIRED');  -- Filter eligible customers
```

#### C. Document Ingestion & Management
**Existing Component**: `structure/065_LOAI_loans_documents.sql`

**Capabilities Already Implemented**:
- Automated document ingestion (emails, PDFs) via internal stages
- Stream-based processing for near real-time document loading
- Metadata capture (filename, load timestamp, source)
- DocAI-ready storage (VARIANT format for flexible schema)
- Automated stage cleanup and retention management
- Serverless task orchestration

**Reusable for Retail Loans**:
- Loan application document upload (income proof, ID documents, property documents)
- Email communication tracking (customer inquiries, application submissions)
- Contract and agreement storage
- Audit trail maintenance
- Document lifecycle management

**Integration Point**:
```sql
-- Existing stages can be reused for loan documents:
-- LOAI_RAW_STAGE_EMAIL_INBOUND: mortgage inquiry emails, application confirmations
-- LOAI_RAW_STAGE_PDF_INBOUND: loan agreements, income verification, property valuations

-- Example: Query loan-related documents
SELECT 
    FILE_NAME,
    LOAD_TS,
    RAW_CONTENT:customer_id::STRING as CUSTOMER_ID,
    RAW_CONTENT:application_id::STRING as APPLICATION_ID,
    RAW_CONTENT:document_type::STRING as DOCUMENT_TYPE,
    RAW_CONTENT:property_value::NUMBER as PROPERTY_VALUE,
    RAW_CONTENT:loan_amount::NUMBER as LOAN_AMOUNT
FROM LOA_RAW_001.LOAI_RAW_TB_DOCUMENTS
WHERE FILE_NAME LIKE '%mortgage%'
  AND LOAD_TS >= DATEADD(day, -30, CURRENT_DATE())
ORDER BY LOAD_TS DESC;
```

#### D. Email Generation & Customer Communications
**Existing Component**: `mortgage_email_generator.py`

**Capabilities Already Implemented**:
- Country-specific mortgage data (property values, LTV ratios, interest rates, currencies)
- Realistic mortgage application data generation
- Multi-email type generation (customer-facing, internal underwriting, loan officer)
- Risk-based content personalization
- Compliance-aligned disclosures
- Email metadata for tracking (application ID, customer ID, timestamps)

**Reusable for Retail Loans**:
- Pre-approval communication templates
- Application confirmation emails
- Document request notifications
- Loan officer assignment communications
- Risk assessment summaries
- Compliance disclosure generation

**Swiss Regulatory Parameters** (already implemented in `mortgage_email_generator.py`):
```python
# Country-specific data for Switzerland aligns with FINMA requirements:
'Switzerland': {
    'avg_property_value': 650000,      # CHF - reflects Swiss market
    'max_loan_to_value': 0.80,         # FINMA maximum 80% LTV
    'typical_rate': 2.75,              # Market rate (2-3% typical in 2026)
    'imputed_rate_affordability': 5.0, # FINMA affordability test rate (not in emails, but used in underwriting)
    'affordability_threshold': 0.33,   # Maximum 33% of gross income for housing costs
    'hard_equity_minimum': 0.10,       # Minimum 10% hard equity (cash/securities)
    'soft_equity_allowed': 0.10,       # Up to 10% soft equity (2nd pillar pension)
    'second_rank_threshold': 0.6667,   # 2nd rank starts above 66.67% LTV
    'second_rank_amortization_years': 15, # Must amortize 2nd rank in 15 years
    'ancillary_cost_pct': 0.01,        # 1% of property value annually (maintenance, utilities, tax)
    'retirement_ltv_max': 0.6667,      # Must reduce to 66.67% LTV by retirement
    'retirement_age': 65,              # Standard Swiss retirement age
    'currency': 'CHF',
    'email_domain': 'chbank.ch',
    'phone': '41-555-BANK'
}
```

**Data Alignment**:
```python
# mortgage_email_generator.py already generates data aligned with BRS Section 8.1:
# - Customer profile (name, DOB, employment, income)
# - Application data (amount, term, purpose, channel)
# - Property/collateral data (address, type, value, LTV)
# - Income & expense profile (monthly income, debt ratios)
# - Risk assessment (credit score, DTI, LTV, anomaly flags)
# - Communications tracking (email type, timestamps, journey stage)

# Example: Generated email contains BRS-compliant data structure
MortgageRequest(
    application_id='MTG_CUST_00001_20260117',
    customer=Customer(customer_id, first_name, family_name, date_of_birth, onboarding_date, has_anomaly),
    address=CustomerAddress(street_address, city, state, zipcode, country),
    loan_amount=450000.00,  # Requested amount
    property_value=550000.00,  # Collateral value (CHF for Switzerland example)
    down_payment=100000.00,  # 18% down (meets Swiss 20% equity requirement)
    loan_term_years=30,
    interest_rate=2.75,  # Market rate (Switzerland typical)
    monthly_income=8500.00,
    employment_type='Full-time Employee',
    employment_years=8,
    property_type='Single Family Home',
    purpose='Purchase Primary Residence',
    credit_score=720,
    debt_to_income_ratio=0.32  # 32% DTI
)

# Switzerland-specific affordability calculation (per FINMA requirements):
# - Imputed interest rate: 5% (not market rate of 2.75%)
# - Monthly imputed interest: CHF 450,000 * 0.05 / 12 = CHF 1,875
# - Amortization (2nd rank): CHF 83,333 / 15 years / 12 months = CHF 463/month
#   (Portion from 66.67% to 80% LTV must be amortized)
# - Ancillary costs: CHF 550,000 * 0.01 / 12 = CHF 458/month
# - Total housing costs: CHF 1,875 + CHF 463 + CHF 458 = CHF 2,796/month
# - Affordability ratio: CHF 2,796 / CHF 8,500 = 32.9% (within 33% threshold ✓)
# - LTV: 81.8% → Requires 20% equity (CHF 110,000)
#   - Hard equity required: CHF 55,000 (10% of property value)
#   - Soft equity allowed: CHF 55,000 (can use 2nd pillar pension)
```

#### E. Core Reporting & Analytics
**Existing Component**: `structure/500_REPP_core_reporting.sql`

**Capabilities Already Implemented**:
- Customer-level aggregations (balances, transaction summaries, account counts)
- Daily transaction summaries
- Currency exposure tracking (current and historical)
- Anomaly detection and pattern analysis
- Settlement risk analysis
- Lifecycle event tracking

**Reusable for Retail Loans**:
- Loan portfolio aggregations (outstanding balances, payment status, delinquency rates)
- Daily loan activity summaries (disbursements, repayments, prepayments)
- Currency exposure for FX-denominated loans
- Payment anomaly detection (missed payments, irregular patterns)
- Loan lifecycle analytics (origination to closure)

**Integration Point**:
```sql
-- Example: Extend REPP_AGG_DT_CUSTOMER_SUMMARY for loan portfolio metrics
CREATE OR REPLACE DYNAMIC TABLE REPP_AGG_DT_CUSTOMER_LOAN_SUMMARY(
    CUSTOMER_ID VARCHAR(30),
    TOTAL_LOAN_ACCOUNTS NUMBER(10,0),
    TOTAL_OUTSTANDING_PRINCIPAL NUMBER(18,2),
    TOTAL_MONTHLY_PAYMENT NUMBER(18,2),
    MORTGAGE_ACCOUNTS NUMBER(10,0),
    UNSECURED_LOAN_ACCOUNTS NUMBER(10,0),
    TOTAL_LOAN_BALANCE NUMBER(18,2),
    WEIGHTED_AVG_INTEREST_RATE NUMBER(5,2),
    OLDEST_LOAN_ORIGINATION_DATE DATE,
    NEWEST_LOAN_ORIGINATION_DATE DATE,
    ACCOUNTS_IN_ARREARS NUMBER(10,0),
    TOTAL_ARREARS_AMOUNT NUMBER(18,2),
    DAYS_PAST_DUE_MAX NUMBER(10,0),
    LAST_PAYMENT_DATE DATE,
    PAYMENT_TO_INCOME_RATIO NUMBER(5,2),
    LOAN_TO_VALUE_WEIGHTED_AVG NUMBER(5,2),
    LAST_UPDATED TIMESTAMP_NTZ
) 
TARGET_LAG = '60 MINUTE' 
WAREHOUSE = MD_TEST_WH
COMMENT = 'Customer-level loan portfolio summary extending REPP core reporting capabilities'
AS
SELECT 
    c.CUSTOMER_ID,
    COUNT(l.LOAN_ACCOUNT_ID) as TOTAL_LOAN_ACCOUNTS,
    SUM(l.OUTSTANDING_PRINCIPAL) as TOTAL_OUTSTANDING_PRINCIPAL,
    SUM(l.MONTHLY_PAYMENT_AMOUNT) as TOTAL_MONTHLY_PAYMENT,
    COUNT(CASE WHEN l.LOAN_TYPE IN ('MORTGAGE_OWNER_OCCUPIED','MORTGAGE_BUY_TO_LET') THEN 1 END) as MORTGAGE_ACCOUNTS,
    COUNT(CASE WHEN l.LOAN_TYPE IN ('PERSONAL_LOAN','OVERDRAFT') THEN 1 END) as UNSECURED_LOAN_ACCOUNTS,
    SUM(l.CURRENT_BALANCE) as TOTAL_LOAN_BALANCE,
    AVG(l.CURRENT_INTEREST_RATE) as WEIGHTED_AVG_INTEREST_RATE,
    MIN(l.ORIGINATION_DATE) as OLDEST_LOAN_ORIGINATION_DATE,
    MAX(l.ORIGINATION_DATE) as NEWEST_LOAN_ORIGINATION_DATE,
    COUNT(CASE WHEN l.DAYS_PAST_DUE > 0 THEN 1 END) as ACCOUNTS_IN_ARREARS,
    SUM(CASE WHEN l.DAYS_PAST_DUE > 0 THEN l.ARREARS_AMOUNT ELSE 0 END) as TOTAL_ARREARS_AMOUNT,
    MAX(l.DAYS_PAST_DUE) as DAYS_PAST_DUE_MAX,
    MAX(l.LAST_PAYMENT_DATE) as LAST_PAYMENT_DATE,
    -- Calculate payment-to-income using customer 360 income data
    SUM(l.MONTHLY_PAYMENT_AMOUNT) / NULLIF(c360.MONTHLY_INCOME_ESTIMATED, 0) as PAYMENT_TO_INCOME_RATIO,
    AVG(l.LOAN_TO_VALUE_RATIO) as LOAN_TO_VALUE_WEIGHTED_AVG,
    CURRENT_TIMESTAMP() as LAST_UPDATED
FROM CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_CURRENT c
LEFT JOIN LOA_AGG_001.LOAA_AGG_DT_LOAN_ACCOUNTS l
    ON c.CUSTOMER_ID = l.CUSTOMER_ID
LEFT JOIN CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 c360
    ON c.CUSTOMER_ID = c360.CUSTOMER_ID
GROUP BY c.CUSTOMER_ID, c360.MONTHLY_INCOME_ESTIMATED;
```

### 12.2 New Components Required for Retail Loans Module

While significant infrastructure can be reused, the following new components are required:

#### A. Loan Application Data Model (LOA_RAW_001 schema - extends existing)
```sql
-- New tables required:
-- LOAI_RAW_TB_LOAN_APPLICATIONS (application master data)
-- LOAI_RAW_TB_PROPERTY_COLLATERAL (property/collateral details)
-- LOAI_RAW_TB_INCOME_VERIFICATION (income & expense profiles)
-- LOAI_RAW_TB_APPLICATION_DOCUMENTS (document metadata with links to LOAI_RAW_TB_DOCUMENTS)
```

#### B. Loan Account Management (LOA_AGG_001 schema - new)
```sql
-- New dynamic tables required:
-- LOAA_AGG_DT_LOAN_ACCOUNTS (loan account master)
-- LOAA_AGG_DT_PAYMENT_SCHEDULES (amortization schedules)
-- LOAA_AGG_DT_LOAN_TRANSACTIONS (disbursements, payments, prepayments)
-- LOAA_AGG_DT_ARREARS_COLLECTIONS (arrears tracking & forbearance)
-- LOAA_AGG_DT_COLLATERAL_VALUATIONS (property valuation history)
```

#### C. Loan Origination Business Logic (LOA_AGG_001 schema - new)
```sql
-- New views/functions required:
-- LOAA_AGG_VW_AFFORDABILITY_CALCULATOR (DTI/DSTI calculations per country)
-- LOAA_AGG_VW_LTV_CALCULATOR (loan-to-value with regulatory caps)
-- LOAA_AGG_VW_ELIGIBILITY_RULES (product eligibility by customer segment & country)
-- LOAA_AGG_VW_PRICING_ENGINE (risk-based pricing by segment)
```

#### D. Regulatory Reporting Views (REP_AGG_001 schema - extends existing)
```sql
-- Extends REPP core reporting with loan-specific views:
-- REPP_AGG_VW_LOAN_PORTFOLIO_SUMMARY (portfolio metrics by product/country/risk)
-- REPP_AGG_VW_LOAN_ORIGINATION_REGISTER (regulatory loan-level data)
-- REPP_AGG_VW_LTV_DISTRIBUTION (LTV monitoring for regulatory caps)
-- REPP_AGG_VW_ARREARS_NPE_ANALYSIS (NPE classification & forbearance tracking)
```

### 12.3 Data Lineage & Integration Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ CUSTOMER ONBOARDING & KYC (Existing - Reused)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│ CRM_RAW_001.CRMI_RAW_TB_CUSTOMER                                           │
│ CRM_RAW_001.CRMI_RAW_TB_ADDRESSES                                          │
│ CRM_RAW_001.CRMI_RAW_TB_EXPOSED_PERSON                                     │
│         ↓                                                                    │
│ CRM_AGG_001.CRMA_AGG_DT_CUSTOMER_360 (Master customer view)                │
│ CRM_AGG_001.CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING                       │
└─────────────────────────────────────────────────────────────────────────────┘
                               ↓ (Customer eligibility check)
┌─────────────────────────────────────────────────────────────────────────────┐
│ LOAN APPLICATION CAPTURE (New - Mortgage Email Generator Integration)      │
├─────────────────────────────────────────────────────────────────────────────┤
│ mortgage_email_generator.py → Generated application emails                 │
│         ↓                                                                    │
│ LOA_RAW_001.LOAI_RAW_STAGE_EMAIL_INBOUND (Existing stage - reused)         │
│ LOA_RAW_001.LOAI_RAW_TB_EMAILS (Existing table - reused)                   │
│         ↓                                                                    │
│ LOA_RAW_001.LOAI_RAW_TB_LOAN_APPLICATIONS (New - structured application)   │
│ LOA_RAW_001.LOAI_RAW_TB_PROPERTY_COLLATERAL (New - property details)       │
│ LOA_RAW_001.LOAI_RAW_TB_INCOME_VERIFICATION (New - income/expense)         │
└─────────────────────────────────────────────────────────────────────────────┘
                               ↓ (Application processing)
┌─────────────────────────────────────────────────────────────────────────────┐
│ UNDERWRITING & DECISIONING (New with existing Customer 360 integration)    │
├─────────────────────────────────────────────────────────────────────────────┤
│ LOA_AGG_001.LOAA_AGG_VW_AFFORDABILITY_CALCULATOR                           │
│   ↳ Uses: CRMA_AGG_DT_CUSTOMER_360.INCOME_RANGE                            │
│   ↳ Uses: CRMA_AGG_DT_CUSTOMER_360.TOTAL_BALANCE (existing debts)          │
│         ↓                                                                    │
│ LOA_AGG_001.LOAA_AGG_VW_ELIGIBILITY_RULES                                  │
│   ↳ Uses: CRMA_AGG_DT_CUSTOMER_360.RISK_CLASSIFICATION                     │
│   ↳ Uses: CRMA_AGG_DT_CUSTOMER_360.OVERALL_RISK_RATING                     │
│   ↳ Uses: CRMA_AGG_VW_SANCTIONS_CUSTOMER_SCREENING                         │
│         ↓                                                                    │
│ LOA_AGG_001.LOAA_AGG_DT_LOAN_DECISIONS (Application + Decision)            │
└─────────────────────────────────────────────────────────────────────────────┘
                               ↓ (Approved applications)
┌─────────────────────────────────────────────────────────────────────────────┐
│ LOAN ACCOUNT MANAGEMENT (New)                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│ LOA_AGG_001.LOAA_AGG_DT_LOAN_ACCOUNTS (Account master)                     │
│ LOA_AGG_001.LOAA_AGG_DT_PAYMENT_SCHEDULES (Amortization)                   │
│ LOA_AGG_001.LOAA_AGG_DT_LOAN_TRANSACTIONS (Payments)                       │
│ LOA_AGG_001.LOAA_AGG_DT_ARREARS_COLLECTIONS (Collections)                  │
└─────────────────────────────────────────────────────────────────────────────┘
                               ↓ (Portfolio reporting)
┌─────────────────────────────────────────────────────────────────────────────┐
│ REGULATORY & BUSINESS REPORTING (Extends existing REPP)                    │
├─────────────────────────────────────────────────────────────────────────────┤
│ REP_AGG_001.REPP_AGG_DT_CUSTOMER_LOAN_SUMMARY (Extends REPP_AGG_DT_       │
│              CUSTOMER_SUMMARY)                                              │
│ REP_AGG_001.REPP_AGG_VW_LOAN_PORTFOLIO_SUMMARY                             │
│ REP_AGG_001.REPP_AGG_VW_LTV_DISTRIBUTION                                   │
│ REP_AGG_001.REPP_AGG_VW_ARREARS_NPE_ANALYSIS                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 12.4 Deployment Sequence

**Phase 1: Reuse Existing Infrastructure (Week 1)**
1. ✅ Customer 360 already deployed (`410_CRMA_customer_360.sql`)
2. ✅ Sanctions screening already deployed (`302_CRMA_sanctions_screening.sql`)
3. ✅ Document ingestion already deployed (`065_LOAI_loans_documents.sql`)
4. ✅ Core reporting already deployed (`500_REPP_core_reporting.sql`)
5. ✅ Email generator already implemented (`mortgage_email_generator.py`)

**Phase 2: Loan Application Layer (Week 2-3)**
1. Create `LOA_RAW_001.LOAI_RAW_TB_LOAN_APPLICATIONS`
2. Create `LOA_RAW_001.LOAI_RAW_TB_PROPERTY_COLLATERAL`
3. Create `LOA_RAW_001.LOAI_RAW_TB_INCOME_VERIFICATION`
4. Create `LOA_RAW_001.LOAI_RAW_TB_APPLICATION_DOCUMENTS`
5. Integrate `mortgage_email_generator.py` output with application tables

**Phase 3: Loan Origination Logic (Week 4-5)**
1. Create `LOA_AGG_001.LOAA_AGG_VW_AFFORDABILITY_CALCULATOR`
2. Create `LOA_AGG_001.LOAA_AGG_VW_LTV_CALCULATOR`
3. Create `LOA_AGG_001.LOAA_AGG_VW_ELIGIBILITY_RULES`
4. Create `LOA_AGG_001.LOAA_AGG_VW_PRICING_ENGINE`
5. Create `LOA_AGG_001.LOAA_AGG_DT_LOAN_DECISIONS`

**Phase 4: Loan Account Management (Week 6-8)**
1. Create `LOA_AGG_001.LOAA_AGG_DT_LOAN_ACCOUNTS`
2. Create `LOA_AGG_001.LOAA_AGG_DT_PAYMENT_SCHEDULES`
3. Create `LOA_AGG_001.LOAA_AGG_DT_LOAN_TRANSACTIONS`
4. Create `LOA_AGG_001.LOAA_AGG_DT_ARREARS_COLLECTIONS`
5. Create `LOA_AGG_001.LOAA_AGG_DT_COLLATERAL_VALUATIONS`

**Phase 5: Extended Reporting (Week 9-10)**
1. Extend `REP_AGG_001.REPP_AGG_DT_CUSTOMER_SUMMARY` with loan metrics
2. Create `REP_AGG_001.REPP_AGG_VW_LOAN_PORTFOLIO_SUMMARY`
3. Create `REP_AGG_001.REPP_AGG_VW_LOAN_ORIGINATION_REGISTER`
4. Create `REP_AGG_001.REPP_AGG_VW_LTV_DISTRIBUTION`
5. Create `REP_AGG_001.REPP_AGG_VW_ARREARS_NPE_ANALYSIS`

**Phase 6: Notebooks & Dashboards (Week 11-12)**
1. Create `notebooks/loan_origination_dashboard.ipynb`
2. Create `notebooks/loan_portfolio_monitoring.ipynb`
3. Extend `notebooks/customer_screening_kyc.ipynb` with loan-specific KYC checks
4. Create `notebooks/loan_arrears_collections.ipynb`

### 12.5 Reusable Component Summary

| Component | Existing SQL File | Reuse Percentage | Extension Required |
|-----------|------------------|------------------|-------------------|
| Customer Master Data | `410_CRMA_customer_360.sql` | 90% | Add loan-specific metrics |
| KYC/AML Screening | `302_CRMA_sanctions_screening.sql` | 100% | None - direct reuse |
| Document Ingestion | `065_LOAI_loans_documents.sql` | 100% | None - direct reuse |
| Core Reporting | `500_REPP_core_reporting.sql` | 70% | Add loan portfolio views |
| Email Generation | `mortgage_email_generator.py` | 80% | Integrate with application tables |
| Compliance Dashboard | `customer_screening_kyc.ipynb` | 60% | Add loan eligibility checks |

**Total Infrastructure Reuse**: ~75% of required capabilities already exist

---

**Document Version**: 1.1  
**Last Updated**: 2026-01-17  
**Owner**: Retail Banking & Risk Management  
**Reviewers**: Compliance, IT, Credit Operations, Data Platform Team
