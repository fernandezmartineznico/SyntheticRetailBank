# Snowflake DDL Deployment Guide

This directory holds the complete DDL (in Snowflake syntax) for the **Synthetic Retail Bank** data model. It includes schemas for customer data (CRM), multi-currency support, SCD Type 2 address tracking, Exposed Person compliance, payment anomaly detection, and advanced analytics.


## File Structure

The DDL is organized by **business domain** to ensure a clear separation of concerns and independence. Within each domain, individual files are used for each **data maturity layer** to reduce internal dependencies.

```
structure/
 000_database_setup.sql # Database and warehouse creation
 001_get_listings.sql # Snowflake Data Exchange: Global Sanctions Data Setup
 002_SANC_sanction_data.sql # Sanctions data integration
 010_CRMI_customer_master.sql # CRM Raw: Customer Master Data & Exposed Person System
 011_ACCI_accounts.sql # CRM Raw: Account Master Data
 015_EMPI_employees.sql # CRM Raw: Employee Master Data & Client Assignments
 020_REFI_fx_rates.sql # REF Raw: FX Rates Reference Data
 030_PAYI_transactions.sql # PAY Raw: Payment Transactions
 035_ICGI_swift_messages.sql # PAY Raw: SWIFT ISO20022 Message Processing
 040_EQTI_equity_trades.sql # EQT Raw: Equity Trading
 050_FIII_fixed_income.sql # FII Raw: Fixed Income Trading
 055_CMDI_commodities.sql # CMD Raw: Commodity Trading
 060_LOAI_loans_documents.sql # LOA Raw: Loan & Document Processing
 311_ACCA_accounts_agg.sql # CRM Agg: Account Aggregation Layer
 312_CRMA_LIFECYCLE.sql # CRM Agg: Customer Lifecycle & Churn Prediction
 415_EMPA_employee_analytics.sql # CRM Agg: Employee Analytics & Hierarchy Views
 320_REFA_fx_analytics.sql # REF Agg: FX Rates Analytics & Volatility
 330_PAYA_anomaly_detection.sql # PAY Agg: Payment Anomaly Detection & Account Balances
 330_PAYA_transaction_summary.sql # PAY Agg: Transaction Summary for Customer 360
 335_ICGA_swift_lifecycle.sql # PAY Agg: SWIFT Message Aggregation & Lifecycle
 410_CRMA_customer_360.sql # CRM Agg: Customer 360° with Balances & Transactions
 340_EQTA_equity_analytics.sql # EQT Agg: Equity Trading Analytics & Portfolio
 350_FIIA_fixed_income_analytics.sql # FII Agg: Fixed Income Analytics & Risk Metrics
 355_CMDA_commodity_analytics.sql # CMD Agg: Commodity Analytics & Delta Risk
 500_REPP_core_reporting.sql # REP Agg: Core Reporting & Analytics
 510_REPP_equity_reporting.sql # REP Agg: Equity Trading Reporting
 520_REPP_credit_risk.sql # REP Agg: Credit Risk & IRB Reporting
 525_REPP_frtb_market_risk.sql # REP Agg: FRTB Market Risk Capital Calculations
 540_REPP_bcbs239_compliance.sql # REP Agg: BCBS 239 Risk Data Aggregation
 600_REPP_portfolio_performance.sql # REP Agg: Portfolio Performance & TWR
 700_semantic_view.sql # Business-friendly semantic view
 README_DEPLOYMENT.md # This deployment guide
```

## Object Prefix Matrix

### Prefix per **Data Architecture Layers:**

| **Layer** | **Schemas** | **Schema Object - Prefixes** <br/> (Tables / View /...) |
|-------------------------------------|------------------------------------------------------------------------------|------------------------------------------------------------------|
| ** DAP** <br/> Data Products | | |
| ** AGG** <br/> Aggregation Layer | CRM_AGG_001<br/>PAY_AGG_001<br/>EQT_AGG_001<br/>FII_AGG_001<br/>CMD_AGG_001<br/>REP_AGG_001 | CRMA_<br/>ACCA_<br/>PAYA_<br/>ICGA_<br/>EQTA_<br/>FIIA_<br/>CMDA_<br/>REPP_ |
| ** RAW** <br/> RAW / Landing zone | CRM_RAW_001<br/>REF_RAW_001<br/>PAY_RAW_001<br/>EQT_RAW_001<br/>FII_RAW_001<br/>CMD_RAW_001 | CRMI_<br/>ACCI_<br/>REFI_<br/>PAYI_<br/>EQTI_<br/>ICGI_<br/>FIII_<br/>CMDI_ |



### ** Naming Convention:**

#### Schema - Naming
- 1-3 position: Business domain (CRM, PAY, EQT, ICG, REF, REP,...)
- 4 position: "_")
- 5-7 position: data maturity layer (RAW, AGG,..., DAP)
- 8 position: "_")
- 9-14 position: versioning (V000, +1 = minor changes, +10	= major changes)


#### Schema Object - Prefixes (Tables / View /...)
- 1-3 position: Business domain (CRM, PAY, EQT, ICG, REF, REP,...)
- 4 position: software component with data maturity layer (I=Ingestion/Raw, A=Aggregation, P=Processing/DAP)
- Examples: 
 - `CRMI_` = **CRM Ingestion** (RAW layer)
 - `CRMA_` = **CRM Aggregation** (AGG layer)
 - `PAYA_` = **PAY Aggregation** (AGG layer)

## Deployment Order

** CRITICAL: Execute files in the exact order listed below to ensure proper dependencies:**

### 1. Database Setup
```sql
-- Execute first: Database and warehouse creation
@000_database_setup.sql
```

### 1a. Snowflake Data Exchange Setup (Optional)
**External Data Source**: Global Sanctions Data

```sql
-- Execute after database setup: Global sanctions data from Data Exchange
@001_get_listings.sql
```

**Purpose:**
- **Compliance Data**: Import global sanctions and watchlist data
- **PEP Screening**: Enhance Politically Exposed Persons screening
- **Regulatory Support**: Provide external reference data for compliance
- **Risk Management**: Support KYC/AML processes with real-time data

**Prerequisites:**
- Snowflake account with Data Exchange access
- Legal terms acceptance for data usage
- Email verification for listing access

**Objects Created:**
- **Database**: `REF_DAP_GLOBAL_SANCTIONS_DATA_SET`
- **Schema**: `GLOBAL_SANCTIONS_DATA`
- **Table**: `SANCTIONS_DATAFEED` - Comprehensive international sanctions data

**Key Features:**
- **Real-Time Updates**: Regular updates for current sanctions information
- **Global Coverage**: International sanctions and watchlist data
- **Compliance Integration**: Direct integration with customer screening processes
- **Regulatory Reporting**: Support for audit and compliance requirements

**Integration Points:**
- Cross-reference with `CRMI_EXPOSED_PERSON` data
- Enhance customer onboarding screening processes
- Support transaction monitoring and counterparty screening
- Provide evidence for regulatory compliance and audit requirements

### 2. Customer Master Data & Exposed Person System
**Business Domain**: `CRM`

```sql
-- Execute second: Core customer data and compliance
@010_CRMI_customer_master.sql
```

**Objects Created:**
- **Schema**: `CRM_RAW_001`
- **Stages**: `CRMI_CUSTOMERS`, `CRMI_ADDRESSES`, `CRMI_EXPOSED_PERSON`, `CRMI_CUSTOMER_EVENTS`
- **File Formats**: `CRMI_FF_CUSTOMER_CSV`, `CRMI_FF_ADDRESS_CSV`, `CRMI_FF_EXPOSED_PERSON_CSV`, `CRMI_FF_CUSTOMER_EVENT_CSV`, `CRMI_FF_CUSTOMER_STATUS_CSV`
- **Tables**: `CRMI_CUSTOMER`, `CRMI_ADDRESSES`, `CRMI_EXPOSED_PERSON`, `CRMI_CUSTOMER_EVENT`, `CRMI_CUSTOMER_STATUS`
- **Streams**: `CRMI_STREAM_CUSTOMER_FILES`, `CRMI_STREAM_ADDRESS_FILES`, `CRMI_STREAM_EXPOSED_PERSON_FILES`, `CRMI_STREAM_CUSTOMER_EVENT_FILES`, `CRMI_STREAM_CUSTOMER_STATUS_FILES`
- **Tasks**: `CRMI_TASK_LOAD_CUSTOMERS`, `CRMI_TASK_LOAD_ADDRESSES`, `CRMI_TASK_LOAD_EXPOSED_PERSON`, `CRMI_TASK_LOAD_CUSTOMER_EVENTS`, `CRMI_TASK_LOAD_CUSTOMER_STATUS`

**Key Features:**
- **Customer Master Data**: Core customer information with extended attributes (12 EMEA countries)
- **REPORTING_CURRENCY**: Country-based currency assignment (EUR, GBP, NOK, SEK, DKK, PLN)
- **SCD Type 2 Customer Attributes**: Append-only base table with `INSERT_TIMESTAMP_UTC` and composite PK tracking changes in employment, account tier, contact info, and risk profile
- **SCD Type 2 Addresses**: Append-only base table with `INSERT_TIMESTAMP_UTC` and composite PK for address history tracking
- **Exposed Person Compliance**: Politically Exposed Persons for regulatory compliance
- **Customer Lifecycle Events**: Comprehensive event tracking (ONBOARDING, ADDRESS_CHANGE, EMPLOYMENT_CHANGE, ACCOUNT_UPGRADE, ACCOUNT_DOWNGRADE, ACCOUNT_CLOSE, REACTIVATION, CHURN, DORMANT_DETECTED)
- **Customer Status History**: SCD Type 2 status tracking for lifecycle analytics
- **Automated Loading**: Stream-triggered serverless tasks (1-hour schedule for master data, 5-minute for lifecycle events)

### 3. Account Master Data
**Business Domain**: `CRM`

```sql
-- Execute third: Account information
@011_ACCI_accounts.sql
```

**Objects Created:**
- **Schema**: `CRM_RAW_001`
- **Stages**: `ACCI_ACCOUNTS`
- **File Formats**: `ACCI_FF_ACCOUNT_CSV`
- **Tables**: `ACCI_ACCOUNTS`
- **Streams**: `ACCI_STREAM_ACCOUNT_FILES`
- **Tasks**: `ACCI_TASK_LOAD_ACCOUNTS`

### 3a. Employee Master Data & Client Assignments
**Business Domain**: `CRM`

```sql
-- Execute after accounts: Employee hierarchy and client-advisor relationships
@015_EMPI_employees.sql
```

**Objects Created:**
- **Schema**: `CRM_RAW_001`
- **Stages**: `EMPI_EMPLOYEES`, `EMPI_CLIENT_ASSIGNMENTS`
- **File Formats**: `EMPI_FF_EMPLOYEE_CSV`, `EMPI_FF_ASSIGNMENT_CSV`
- **Tables**: `EMPI_EMPLOYEE`, `EMPI_CLIENT_ASSIGNMENT`
- **Streams**: `EMPI_STREAM_EMPLOYEE_FILES`, `EMPI_STREAM_ASSIGNMENT_FILES`
- **Tasks**: `EMPI_TASK_LOAD_EMPLOYEES`, `EMPI_TASK_LOAD_ASSIGNMENTS`

**Key Features:**
- **Employee Hierarchy**: 3-tier structure (Client Advisors, Team Leaders, Super Team Leaders)
- **Dynamic Scaling**: Advisor count scales with customer base (200 clients/advisor)
- **Client Assignments**: SCD Type 2 relationship tracking with assignment history
- **Performance Tracking**: Performance ratings, certifications, languages spoken
- **Geographic Coverage**: Multi-country deployment with regional management
- **Self-Referencing Hierarchy**: Manager relationships within employee table
- **Assignment Reasons**: INITIAL_ONBOARDING, TRANSFER, ESCALATION, REBALANCING
- **Automated Loading**: Stream-triggered serverless tasks (1-hour schedule)

**Note:** Foreign key to `CRMI_CUSTOMER` is not enforced due to SCD Type 2 composite primary key.

### 4. FX Rates Reference Data
**Business Domain**: `REF`

```sql
-- Execute fourth: Foreign exchange rates
@020_REFI_fx_rates.sql
```

**Objects Created:**
- **Schema**: `REF_RAW_001`
- **Stages**: `REFI_FX_RATES`
- **File Formats**: `REFI_FF_FX_RATES_CSV`
- **Tables**: `REFI_FX_RATES`
- **Streams**: `REFI_STREAM_FX_RATE_FILES`
- **Tasks**: `REFI_TASK_LOAD_FX_RATES`

**Key Features:**
- **Multi-Currency Support**: Daily FX rates with bid/ask spreads
- **Real-Time Rates**: Latest rates for currency conversion
- **Reference Data**: Central FX rate repository for all schemas

### 4a. FX Rates Aggregation Layer
**Business Domain**: `REF`

```sql
-- Execute after raw layer: Enhanced FX rates with analytics
@320_REFA_fx_analytics.sql
```

**Objects Created:**
- **Schema**: `REF_AGG_001`
- **Dynamic Tables**: `REFA_AGG_DT_FX_RATES_ENHANCED` - Enhanced FX rates with analytics and volatility metrics

**Key Features:**
- **Enhanced Analytics**: Spreads, volatility, trends, risk classifications
- **Real-Time Metrics**: Current rates, moving averages, position analysis
- **Risk Management**: Volatility and spread-based risk classifications

### 5. Payment Transactions
**Business Domain**: `PAY`

```sql
-- Execute fifth: Payment data
@030_PAYI_transactions.sql
```

**Objects Created:**
- **Schema**: `PAY_RAW_001`
- **Stages**: `PAYI_TRANSACTIONS`
- **File Formats**: `PAYI_FF_TRANSACTION_CSV`
- **Tables**: `PAYI_TRANSACTIONS`
- **Streams**: `PAYI_STREAM_TRANSACTION_FILES`
- **Tasks**: `PAYI_TASK_LOAD_TRANSACTIONS`

**Key Features:**
- **Multi-Currency Transactions**: Support for all EMEA currencies
- **Base Currency Conversion**: Automatic FX conversion to base currency
- **Anomaly Detection Ready**: Transaction patterns for behavioral analysis

### 6. Equity Trading
**Business Domain**: `EQT`

```sql
-- Execute sixth: Trading data
@040_EQTI_equity_trades.sql
```

**Objects Created:**
- **Schema**: `EQT_RAW_001`
- **Stages**: `EQTI_TRADES`
- **File Formats**: `EQTI_FF_TRADES_CSV`
- **Tables**: `EQTI_TRADES`
- **Streams**: `EQTI_STREAM_TRADES_FILES`
- **Tasks**: `EQTI_TASK_LOAD_TRADES`

### 7. Fixed Income Trading (FRTB)
**Business Domain**: `FII`

```sql
-- Execute seventh: Fixed income trades (bonds and swaps)
@050_FIII_fixed_income.sql
```

**Objects Created:**
- **Schema**: `FII_RAW_001`
- **Stages**: `FIII_STAGE`
- **Tables**: `FIII_TRADES`
- **Streams**: `FIII_TRADES_STREAM`
- **Tasks**: `FIII_LOAD_TRADES_TASK` (serverless, 60 min)

**Key Features:**
- **Government Bonds**: Sovereign debt (CHF, EUR, USD, GBP)
- **Corporate Bonds**: Investment grade and high yield with credit ratings
- **Interest Rate Swaps**: SARON, EURIBOR, SOFR, SONIA
- **FRTB Risk Metrics**: Duration, DV01, credit spreads, liquidity scores
- **Automated Loading**: Serverless task for CSV ingestion

### 8. Commodity Trading (FRTB)
**Business Domain**: `CMD`

```sql
-- Execute eighth: Commodity trades (energy, metals, agricultural)
@055_CMDI_commodities.sql
```

**Objects Created:**
- **Schema**: `CMD_RAW_001`
- **Stages**: `CMDI_STAGE`
- **Tables**: `CMDI_TRADES`
- **Streams**: `CMDI_TRADES_STREAM`
- **Tasks**: `CMDI_LOAD_TRADES_TASK` (serverless, 60 min)

**Key Features:**
- **Energy**: Crude Oil (WTI, Brent), Natural Gas, Heating Oil
- **Precious Metals**: Gold, Silver, Platinum, Palladium
- **Base Metals**: Copper, Aluminum, Zinc, Nickel
- **Agricultural**: Corn, Wheat, Soybeans, Coffee, Sugar
- **FRTB Risk Metrics**: Delta, volatility, spot/forward prices, liquidity scores
- **Physical Delivery**: Delivery month, location, and contract tracking

### 9. SWIFT ISO20022 Message Processing
**Business Domain**: `ICG` 

```sql
-- Execute fifth: SWIFT message processing (raw layer)
@035_ICGI_swift_messages.sql
```

**Objects Created:**
- **Schema**: `PAY_RAW_001`
- **Stages**: `ICGI_RAW_SWIFT_INBOUND`
- **File Formats**: `ICGI_XML_FILE_FORMAT`
- **Tables**: `ICGI_RAW_SWIFT_MESSAGES`
- **Streams**: `ICGI_STREAM_SWIFT_FILES`
- **Tasks**: `ICGI_TASK_LOAD_SWIFT_MESSAGES`

**Key Features:**
- **SWIFT Message Processing**: PACS.008 and PACS.002 message types
- **XML Processing**: Structured SWIFT message parsing with PARSE_XML()
- **Stream-Based Automation**: Automatic file detection and processing

## AGGREGATION LAYER

Execute after all raw layer schemas are deployed.

** CRITICAL AGGREGATION LAYER DEPLOYMENT ORDER:**

For Customer 360 and Employee Analytics to work correctly, deploy in this exact sequence:

1. **Account Aggregation** (`311_ACCA_accounts_agg.sql`) - Creates `ACCA_AGG_DT_ACCOUNTS` for account metadata
2. **Payment Anomaly Detection** (`330_PAYA_anomaly_detection.sql`) - Creates `PAYA_AGG_DT_ACCOUNT_BALANCES` for balance metrics and `PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY` for transaction aggregation
3. **Customer 360** (`410_CRMA_customer_360.sql`) - Depends on #1 and #2 for complete customer profile (uses direct transaction join for performance)
4. **Employee Analytics** (`415_EMPA_employee_analytics.sql`) - Depends on #3 for customer metrics in advisor performance views

**Dependency Flow:**
```
RAW DATA (ACCI_ACCOUNTS, PAYI_TRANSACTIONS, CRMI_CUSTOMER, CRMI_ADDRESSES)
 ↓
ACCOUNT AGGREGATION (311_ACCA_accounts_agg.sql)
 ↓
ACCOUNT BALANCES (330_PAYA_anomaly_detection.sql)
 ↓
TRANSACTION SUMMARY (330_PAYA_transaction_summary.sql)
 ↓
CUSTOMER 360 (410_CRMA_customer_360.sql)
 ↓
EMPLOYEE ANALYTICS (415_EMPA_employee_analytics.sql)
```

---

### 7a. Transaction Summary Aggregation
**Business Domain**: `PAY`

```sql
-- Execute BEFORE Customer 360: Pre-aggregated transaction metrics
@330_PAYA_transaction_summary.sql
```

**Objects Created:**
- **Schema**: `PAY_AGG_001`
- **Dynamic Tables** (merged from 330_PAYA_anomaly_detection.sql):
  - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` - Behavioral anomaly detection
  - `PAYA_AGG_DT_ACCOUNT_BALANCES` - Real-time account balances
  - `PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY` - Pre-aggregated transaction metrics per customer

**Key Features:**
- **Transaction Metrics**: 12-month and all-time transaction counts by customer
- **Transaction Types**: Debit/credit breakdown, internal/external transfers
- **Activity Analysis**: Average monthly transactions, days since last transaction
- **Engagement Flags**: Dormancy detection (180+ days), high-activity identification (>50 txn/month)
- **Performance Optimization**: Pre-computed metrics eliminate real-time aggregation overhead
- **Customer 360 Integration**: Primary source for transaction activity in Customer 360 view
- **60-Minute Refresh**: Matches Customer 360 refresh cadence for consistency

**Prerequisites:**
- `030_PAYI_transactions.sql` (raw transaction data)
- `011_ACCI_accounts.sql` (account master data for customer mapping)

### 8. Customer 360° Aggregation with Balances & Transactions
**Business Domain**: `CRM`

```sql
-- Execute AFTER transaction summary and account balances: Customer 360° with financial metrics
@410_CRMA_customer_360.sql
```

**Objects Created:**
- **Schema**: `CRM_AGG_001`
- **Dynamic Tables** (5 tables): 
 - `CRMA_AGG_DT_ADDRESSES_CURRENT` - Latest address per customer (operational view)
 - `CRMA_AGG_DT_ADDRESSES_HISTORY` - Full address SCD Type 2 with VALID_FROM/VALID_TO (analytical view)
 - `CRMA_AGG_DT_CUSTOMER_CURRENT` - Latest customer attributes per customer (operational view)
 - `CRMA_AGG_DT_CUSTOMER_HISTORY` - Full customer attribute SCD Type 2 with VALID_FROM/VALID_TO (analytical view)
 - `CRMA_AGG_DT_CUSTOMER_360` - Comprehensive 360° view with balances, transactions, PEP/sanctions matching

**Key Features:**
- **Dual SCD Type 2 Implementation**: Complete history tracking for both customer attributes AND addresses
- **Balance Metrics (Phase 1)**: AUM tracking with `TOTAL_BALANCE`, account type balances (checking, savings, business, investment)
- **Transaction Metrics (Phase 2)**: Engagement scoring with transaction counts, dormancy flags, activity levels
- **Customer Attributes History**: Tracks changes in employment, account tier, contact info, risk classification
- **Address History**: Tracks all address changes with full audit trail
- **Exposed Person Matching**: Advanced `EDITDISTANCE` fuzzy matching for compliance screening
- **Sanctions Screening**: Global sanctions data integration with fuzzy matching and accuracy scoring
- **Risk Assessment**: Combined PEP, sanctions, and anomaly risk scoring
- **60-Minute Refresh**: Near-real-time operational queries

**Prerequisites (CRITICAL):**
1. `311_ACCA_accounts_agg.sql` - Creates `ACCA_AGG_DT_ACCOUNTS` (for account type counts and metadata)
2. `330_PAYA_anomaly_detection.sql` - Creates `PAYA_AGG_DT_ACCOUNT_BALANCES` (for balance metrics) and `PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY` (for transaction aggregation)
3. Must deploy in this exact order or Customer 360 will fail
4. Note: Customer 360 uses direct transaction joins (Option A) for performance, but `PAYA_AGG_DT_CUSTOMER_TRANSACTION_SUMMARY` is available as an alternative (Option B)


### 9. Account Aggregation Layer
```sql
-- Execute ninth: Account master data aggregation
@311_ACCA_accounts_agg.sql
```

**Objects Created:**
- **Schema**: `CRM_AGG_001`
- **Dynamic Tables**: `ACCA_AGG_DT_ACCOUNTS` - Enhanced account master data

**Key Features:**
- **Data Architecture**: Proper Raw → Aggregation → Analytics layering
- **Enhanced Metadata**: Account type flags and classification
- **Processing Metadata**: Aggregation timestamps and source tracking

### 9a. Employee Analytics & Hierarchy (Dynamic Tables + Views)
**Business Domain**: `CRM`

```sql
-- Execute AFTER Customer 360: Employee performance and relationship analytics
@415_EMPA_employee_analytics.sql
```

**Objects Created:**
- **Schema**: `CRM_AGG_001`
- **Hybrid Architecture** (3 Dynamic Tables + 5 Views):
 - **Dynamic Tables** (Auto-refreshed every 60 minutes):
 - `EMPA_AGG_DT_ADVISOR_PERFORMANCE` - Client advisor KPIs (AUM, client counts, capacity)
 - `EMPA_AGG_DT_PORTFOLIO_BY_ADVISOR` - Portfolio valuations by advisor with currency exposure
 - `EMPA_AGG_DT_TEAM_LEADER_DASHBOARD` - Team aggregations for management reporting
 - **Views** (Real-time):
 - `EMPA_AGG_VW_EMPLOYEE_HIERARCHY` - Recursive org chart with full paths and levels
 - `EMPA_AGG_VW_ORGANIZATIONAL_CHART` - Flat org structure with direct reports
 - `EMPA_AGG_VW_CURRENT_ASSIGNMENTS` - Active client-advisor relationships with customer metrics
 - `EMPA_AGG_VW_ASSIGNMENT_HISTORY` - Full assignment audit trail (SCD Type 2)
 - `EMPA_AGG_VW_WORKLOAD_DISTRIBUTION` - Capacity planning and workload balance analysis

**Why Hybrid Architecture?**
- **Dynamic Tables**: Heavy aggregations (performance metrics, portfolio valuations) benefit from pre-computation and hourly refresh
- **Views**: Recursive queries, simple lookups, and audit trails remain as views for real-time accuracy and simplicity

**Key Features:**
- **AUM Tracking**: Assets Under Management per advisor from `CRMA_AGG_DT_CUSTOMER_360.TOTAL_BALANCE`
- **Transaction Activity**: Engagement metrics from `CRMA_AGG_DT_CUSTOMER_360` (direct transaction aggregation)
- **Performance Analytics**: Advisor ranking, portfolio value, client counts, capacity utilization
- **Workforce Optimization**: Workload distribution, capacity analysis, hiring triggers
- **Team Management**: Team leader dashboards with aggregated metrics and performance ratings
- **Compliance**: Assignment history for audit trails and relationship stability tracking
- **Revenue Projection**: Estimated annual revenue based on 1% AUM fee assumption

**Prerequisites (CRITICAL):**
1. `410_CRMA_customer_360.sql` - Provides customer balance and transaction metrics
2. `CRMA_AGG_DT_CUSTOMER_CURRENT` - Current customer attributes (from Customer 360 file)
3. `015_EMPI_employees.sql` - Employee master data and client assignments
4. Must deploy after Customer 360 or views will fail

**Business Value:**
- **Relationship Management**: Track customer-advisor assignments and tenure
- **Compensation**: Data-driven incentive calculations based on AUM and performance
- **Capacity Planning**: Identify overloaded advisors and available capacity
- **Risk Management**: Monitor high-risk client concentration per advisor
- **Succession Planning**: Performance ratings and organizational hierarchy for talent management

### 10. Payment Anomaly Detection & Account Balances
```sql
-- Execute tenth: Payment analytics and anomaly detection
@330_PAYA_anomaly_detection.sql
```

**Objects Created:**
- **Schema**: `PAY_AGG_001`
- **Dynamic Tables**: 
 - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` - Behavioral anomaly detection
 - `PAYA_AGG_DT_ACCOUNT_BALANCES` - Real-time account balances with FX conversion

**Key Features:**
- **Behavioral Anomaly Detection**: Multi-dimensional transaction analysis
- **Account Balance Management**: Real-time balance calculation with intelligent transaction allocation
- **Dynamic FX Integration**: Real-time currency conversion using `REF_RAW_001.REFI_FX_RATES`
- **Risk Scoring**: Composite anomaly scores with operational alerting thresholds

### 11. SWIFT Message Aggregation
```sql
-- Execute sixth: SWIFT message aggregation (PAY_AGG_001)
@335_ICGA_swift_lifecycle.sql
```

**Objects Created:**
- **Schema**: `PAY_AGG_001`
- **Dynamic Tables**: 
 - `ICGA_AGG_DT_SWIFT_PACS008` - Parsed SWIFT PACS.008 customer credit transfer instructions
 - `ICGA_AGG_DT_SWIFT_PACS002` - Parsed SWIFT PACS.002 payment status reports and acknowledgments
 - `ICGA_AGG_DT_SWIFT_PAYMENT_LIFECYCLE` - Complete payment lifecycle view joining instructions with status reports

### 12. Equity Trading Aggregation & Analytics
```sql
-- Execute: Equity trading analytics
@340_EQTA_equity_analytics.sql
```

**Objects Created:**
- **Schema**: `EQT_AGG_001`
- **Dynamic Tables**: 
 - `EQTA_AGG_DT_TRADE_SUMMARY` - Enriched trade-level analytics with metadata and classifications
 - `EQTA_AGG_DT_PORTFOLIO_POSITIONS` - Current holdings and positions per account with P&L
 - `EQTA_AGG_DT_CUSTOMER_ACTIVITY` - Customer trading behavior and activity metrics

**Key Features:**
- **Trade Analytics**: Comprehensive trade-level view with execution quality metrics
- **Portfolio Positions**: Real-time position tracking with realized P&L calculation
- **Customer Behavior**: Trading activity patterns and engagement analysis
- **Commission Analysis**: Commission rate tracking in basis points
- **Settlement Tracking**: Settlement period analysis and monitoring

### 13. Fixed Income Aggregation & Analytics (FRTB)
```sql
-- Execute: Fixed income analytics
@350_FIIA_fixed_income_analytics.sql
```

**Objects Created:**
- **Schema**: `FII_AGG_001`
- **Dynamic Tables** (5 tables):
 - `FIIA_AGG_DT_TRADE_SUMMARY` - Enriched trade analytics with risk metrics
 - `FIIA_AGG_DT_PORTFOLIO_POSITIONS` - Current holdings by customer/issuer
 - `FIIA_AGG_DT_DURATION_ANALYSIS` - Interest rate risk metrics (duration, DV01)
 - `FIIA_AGG_DT_CREDIT_EXPOSURE` - Credit risk by rating and issuer type
 - `FIIA_AGG_DT_YIELD_CURVE` - Yield curve construction by currency

**Key Features:**
- **Interest Rate Risk**: Duration and DV01 analytics for rate sensitivity
- **Credit Risk**: Exposure aggregation by credit rating and issuer
- **Yield Curve**: Multi-currency yield curve construction
- **Maturity Analysis**: Position bucketing by maturity (short/medium/long term)
- **FRTB Compliance**: Risk metrics for Standardized Approach capital calculations

### 14. Commodity Aggregation & Analytics (FRTB)
```sql
-- Execute: Commodity analytics
@355_CMDA_commodity_analytics.sql
```

**Objects Created:**
- **Schema**: `CMD_AGG_001`
- **Dynamic Tables** (5 tables):
 - `CMDA_AGG_DT_TRADE_SUMMARY` - Enriched trade analytics with risk metrics
 - `CMDA_AGG_DT_PORTFOLIO_POSITIONS` - Current holdings by commodity type
 - `CMDA_AGG_DT_DELTA_EXPOSURE` - Price risk exposure by commodity class
 - `CMDA_AGG_DT_VOLATILITY_ANALYSIS` - Volatility metrics and regime classification
 - `CMDA_AGG_DT_DELIVERY_SCHEDULE` - Physical delivery tracking and logistics

**Key Features:**
- **Delta Risk**: Price sensitivity aggregation by commodity class
- **Volatility Analysis**: Volatility regime classification (LOW/NORMAL/HIGH/EXTREME)
- **Physical Delivery**: Delivery obligation tracking for futures and forwards
- **Concentration Risk**: Position concentration analysis by commodity type
- **FRTB Compliance**: Risk metrics for Standardized Approach capital calculations

### 15. Core Reporting & Analytics
```sql
-- Execute: Core reporting tables
@500_REPP_core_reporting.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (10 core tables): 
 - `REPP_AGG_DT_CUSTOMER_SUMMARY` - Comprehensive customer profiling with transaction statistics
 - `REPP_AGG_DT_DAILY_TRANSACTION_SUMMARY` - Daily transaction volume and pattern analysis
 - `REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT` - Current foreign exchange exposure monitoring
 - `REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY` - Historical FX exposure trends
 - `REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE` - Settlement timing and liquidity risk
 - `REPP_AGG_DT_ANOMALY_ANALYSIS` - Customer-level anomaly detection
 - `REPP_AGG_DT_HIGH_RISK_PATTERNS` - High-risk transaction pattern detection
 - `REPP_AGG_DT_SETTLEMENT_ANALYSIS` - Settlement timing analysis
 - `REPP_AGG_DT_LIFECYCLE_ANOMALIES` - Lifecycle event correlation with transaction anomalies for AML detection

**Key Features:**
- **Customer Analytics**: 360° customer view with transaction profiling
- **FX Risk Management**: Multi-dimensional currency exposure analysis
- **Compliance Monitoring**: Anomaly detection and suspicious activity reporting
- **Settlement Risk**: Liquidity and operational risk monitoring
- **Lifecycle AML Correlation**: Cross-domain detection of suspicious patterns (e.g., dormant accounts reactivated followed by high-value transfers)

### 14. Equity Trading Reporting
```sql
-- Execute: Equity trading reporting
@510_REPP_equity_reporting.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (4 tables): 
 - `REPP_AGG_DT_EQUITY_SUMMARY` - Customer equity trading activity summary
 - `REPP_AGG_DT_EQUITY_POSITIONS` - Position summary by security
 - `REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE` - FX exposure from equity trades
 - `REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES` - Large trade compliance monitoring

**Key Features:**
- **Trading Activity**: Customer-level trading statistics and profiling
- **Position Concentration**: Security-level position tracking and risk analysis
- **Currency Exposure**: FX risk from multi-currency equity trading
- **Compliance**: High-value trade monitoring (>100k CHF threshold)

### 15. Credit Risk & IRB Reporting
```sql
-- Execute: Credit risk and IRB analytics
@520_REPP_credit_risk.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (5 tables): 
 - `REPP_AGG_DT_IRB_CUSTOMER_RATINGS` - Customer-level credit ratings and risk parameters
 - `REPP_AGG_DT_IRB_PORTFOLIO_METRICS` - Portfolio-level risk aggregation
 - `REPP_AGG_DT_CUSTOMER_RATING_HISTORY` - Historical rating tracking (SCD Type 2)
 - `REPP_AGG_DT_IRB_RWA_SUMMARY` - Risk Weighted Assets summary
 - `REPP_AGG_DT_IRB_RISK_TRENDS` - Risk parameter trends and model validation

**Key Features:**
- **Basel III/IV Compliance**: IRB approach for regulatory capital calculation
- **Credit Rating System**: Internal rating scale (AAA to CCC) with PD/LGD/EAD
- **RWA Calculation**: Risk Weighted Assets and capital requirements
- **Rating Migrations**: Historical tracking of rating changes and defaults
- **Model Validation**: Backtesting and performance monitoring

### 22. Portfolio Performance Reporting
```sql
-- Execute: Portfolio performance analytics
@600_REPP_portfolio_performance.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (1 table): 
 - `REPP_AGG_DT_PORTFOLIO_PERFORMANCE` - Integrated cash + equity performance

**Key Features:**
- **Time Weighted Return (TWR)**: Industry-standard performance measurement
- **Multi-Asset Integration**: Combined cash and equity performance
- **Portfolio Allocation**: Cash vs. equity allocation analysis
- **Risk Metrics**: Sharpe Ratio, volatility, max drawdown (placeholders)
- **Performance Classification**: Automated performance categorization
- **Wealth Management**: Client reporting and advisory analytics

### 19. FRTB Market Risk Reporting
```sql
-- Execute: FRTB market risk capital calculations
@525_REPP_frtb_market_risk.sql
```

### 20. BCBS 239 Risk Data Aggregation & Reporting
```sql
-- Execute: BCBS 239 compliance reporting
@540_REPP_bcbs239_compliance.sql
```

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (6 tables):
 - `REPP_AGG_DT_BCBS239_RISK_AGGREGATION` - Comprehensive risk aggregation across all risk types
 - `REPP_AGG_DT_BCBS239_EXECUTIVE_DASHBOARD` - Executive risk dashboard with key risk indicators
 - `REPP_AGG_DT_BCBS239_REGULATORY_REPORTING` - BCBS 239 compliant regulatory reporting
 - `REPP_AGG_DT_BCBS239_RISK_CONCENTRATION` - Real-time risk concentration analysis
 - `REPP_AGG_DT_BCBS239_RISK_LIMITS` - Automated risk limit monitoring
 - `REPP_AGG_DT_BCBS239_DATA_QUALITY` - Comprehensive data quality monitoring

**Key Features:**
- **BCBS 239 Compliance**: Full implementation of Basel Committee principles for risk data aggregation
- **Executive Risk Management**: Comprehensive risk dashboards for senior management
- **Risk Concentration Analysis**: Real-time monitoring of risk concentrations and portfolio diversification
- **Regulatory Reporting**: BCBS 239 compliant regulatory reporting capabilities
- **Data Quality Governance**: Comprehensive data quality monitoring with completeness, accuracy, and timeliness metrics
- **Risk Limit Monitoring**: Automated risk limit monitoring with utilization tracking and alert management
- **IT Infrastructure Monitoring**: System performance, data processing times, and infrastructure health metrics

**BCBS 239 Principles Implemented:**
- **Governance**: Risk data aggregation and reporting governance
- **Data Architecture**: IT infrastructure for risk data aggregation
- **Accuracy & Integrity**: Risk data accuracy and integrity
- **Completeness**: Risk data completeness
- **Timeliness**: Risk data aggregation and reporting timeliness
- **Adaptability**: Risk data aggregation and reporting adaptability
- **Comprehensiveness**: Risk data aggregation and reporting comprehensiveness
- **Clarity**: Risk data aggregation and reporting clarity
- **Frequency**: Risk data aggregation and reporting frequency
- **Distribution**: Risk data aggregation and reporting distribution
- **Review**: Risk data aggregation and reporting review

### 21. Business Semantic View
```sql
-- Execute: Unified business-friendly data access
@550_semantic_view.sql
```

**Objects Created:**
- **Semantic View** (1 view):
 - `REPP_SEMANTIC_VIEW` - Unified business-friendly interface to all reporting tables

**Key Features:**
- **Unified Access**: Single view across all reporting domains
- **Business-Friendly**: Simplified column names and descriptions
- **Cross-Domain Analytics**: Combines core, equity, credit risk, FRTB, and portfolio data
- **BI Integration**: Optimized for business intelligence tools
- **Consistent Patterns**: Standardized data access across all business areas

**Prerequisites:**
- All reporting schemas must be deployed first (500-530 series)
- All dynamic tables must be created and refreshed
- This view is deployed last in the sequence

**Objects Created:**
- **Schema**: `REP_AGG_001`
- **Dynamic Tables** (4 tables):
 - `REPP_AGG_DT_FRTB_RISK_POSITIONS` - Consolidated positions by risk class
 - `REPP_AGG_DT_FRTB_SENSITIVITIES` - Delta/Vega/Curvature sensitivities
 - `REPP_AGG_DT_FRTB_CAPITAL_CHARGES` - SA capital charges by risk bucket
 - `REPP_AGG_DT_FRTB_NMRF_ANALYSIS` - Non-Modellable Risk Factor identification

**Key Features:**
- **FRTB Standardized Approach**: Basel III/IV compliant capital calculations
- **Multi-Asset Coverage**: Equity, FX, Interest Rate, Commodity, Credit Spread
- **Risk Sensitivities**: Delta, Vega, and Curvature risk aggregation
- **Capital Requirements**: Risk-weighted capital charges by risk bucket
- **NMRF Identification**: Illiquid position identification and capital add-ons
- **Risk Bucketing**: Granular risk classification per FRTB framework
- **Regulatory Reporting**: Ready for Basel III/IV compliance reporting

**FRTB Risk Classes:**
1. **Equity Risk** - Delta from equity positions (25% risk weight)
2. **FX Risk** - Delta from multi-currency exposures (15% risk weight)
3. **Interest Rate Risk** - Delta and DV01 from bonds/swaps (1.5-3% risk weight)
4. **Commodity Risk** - Delta from commodities (20-35% risk weight by type)
5. **Credit Spread Risk** - From corporate bonds (2-6% risk weight by rating)

## Schema Architecture

### RAW LAYER (Data Ingestion)
| Schema | Purpose | Key Objects | Refresh Strategy |
|----------------|----------------------------------|----------------------------------------------------------------|------------------------|
| `CRM_RAW_001` | Customer Master, Lifecycle & Employees | CRMI_CUSTOMER, CRMI_ADDRESSES, CRMI_EXPOSED_PERSON, CRMI_CUSTOMER_EVENT, CRMI_CUSTOMER_STATUS, ACCI_ACCOUNTS, EMPI_EMPLOYEE, EMPI_CLIENT_ASSIGNMENT | Stream-triggered serverless tasks |
| `REF_RAW_001` | Reference Data | REFI_FX_RATES | Stream-triggered tasks |
| `PAY_RAW_001` | Payment Transactions & SWIFT | PAYI_TRANSACTIONS, ICGI_RAW_SWIFT_MESSAGES | Stream-triggered tasks |
| `EQT_RAW_001` | Equity Trading | EQTI_TRADES | Stream-triggered tasks |
| `FII_RAW_001` | Fixed Income Trading | FIII_TRADES | Serverless tasks (60 min) |
| `CMD_RAW_001` | Commodity Trading | CMDI_TRADES | Serverless tasks (60 min) |

### AGGREGATION LAYER (Business Logic)
| Schema | Purpose | Key Objects | Refresh Strategy |
|----------------|--------------------------|--------------------------------------------------------|-----------------------|
| `CRM_AGG_001` | Customer Analytics, Lifecycle & Employee Performance | Address SCD Type 2 (Current/History), Customer Attribute SCD Type 2 (Current/History), Customer 360° with balances/transactions, Account aggregation, Lifecycle metrics, Churn prediction, Employee hierarchy & analytics (3 DTs + 5 views) | Dynamic tables (60 min) + Views (real-time) |
| `REF_AGG_001` | Reference Analytics | FX rates with analytics and volatility metrics | 1-hour dynamic tables |
| `PAY_AGG_001` | Payment Analytics | Anomaly detection, Account balances, Transaction summary, SWIFT processing | 1-hour dynamic tables |
| `EQT_AGG_001` | Equity Trading Analytics | Portfolio positions, Trade summary, Customer activity | 1-hour dynamic tables |
| `FII_AGG_001` | Fixed Income Analytics | Duration/DV01, Credit exposure, Yield curve | 1-hour dynamic tables |
| `CMD_AGG_001` | Commodity Analytics | Delta exposure, Volatility, Delivery schedule | 1-hour dynamic tables |
| `REP_AGG_001` | Reporting & FRTB & BCBS239| Cross-domain reporting, Lifecycle AML correlation, FRTB capital, BCBS 239 compliance | 1-hour dynamic tables |

## Advanced Features

### Multi-Currency Support
- **Customer Reporting Currencies**: Country-based currency assignment (EUR, GBP, NOK, SEK, DKK, PLN)
- **FX Rate Integration**: Real-time currency conversion using `REF_RAW_001.REFI_FX_RATES`
- **Dynamic Base Currency**: Automatic detection from transaction data
- **Account Balance Conversion**: Real-time FX conversion for account currency display

### SCD Type 2 Dimensional Management
**Customer Attributes:**
- **Base Table**: `CRMI_CUSTOMER` with append-only structure and composite PK (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)
- **Current View**: `CRMA_AGG_DT_CUSTOMER_CURRENT` for operational queries (latest attributes per customer)
- **History View**: `CRMA_AGG_DT_CUSTOMER_HISTORY` with VALID_FROM/VALID_TO for analytical queries
- **Tracked Attributes**: Employment info, account tier, contact preferences, risk classification, credit score

**Customer Addresses:**
- **Base Table**: `CRMI_ADDRESSES` with append-only structure and composite PK (CUSTOMER_ID, INSERT_TIMESTAMP_UTC)
- **Current View**: `CRMA_AGG_DT_ADDRESSES_CURRENT` for operational queries (latest address per customer)
- **History View**: `CRMA_AGG_DT_ADDRESSES_HISTORY` with VALID_FROM/VALID_TO for analytical queries
- **Automated Processing**: Dynamic tables handle all SCD Type 2 logic and VALID_FROM/VALID_TO calculations

### Payment Anomaly Detection
- **Behavioral Analysis**: Multi-dimensional customer behavior profiling
- **Statistical Scoring**: Z-scores for amount, timing, and velocity anomalies
- **Risk Classification**: CRITICAL, HIGH, MODERATE, NORMAL classifications
- **Operational Alerting**: Immediate review and enhanced monitoring flags

### Account Balance Management
- **Real-Time Balances**: Dynamic calculation with transaction allocation logic
- **Multi-Account Support**: CHECKING, SAVINGS, BUSINESS, INVESTMENT accounts
- **FX Integration**: Currency conversion using actual market rates
- **Balance Analytics**: Activity levels, risk indicators, and categorization

### Exposed Person Compliance System
- **Master Data**: `CRMI_EXPOSED_PERSON` table with comprehensive PEP information
- **Risk Categories**: DOMESTIC, FOREIGN, INTERNATIONAL_ORG, FAMILY_MEMBER, CLOSE_ASSOCIATE
- **Reference Links**: URL sources for compliance documentation
- **Fuzzy Matching**: Advanced name matching for compliance screening

### Customer 360° View with Financial Metrics
- **Comprehensive Data**: `CRMA_AGG_DT_CUSTOMER_360` integrates all customer dimensions:
 - Current customer attributes (employment, account tier, contact, risk profile)
 - Current address information
 - Current lifecycle status and churn prediction
 - Account summary across all account types
 - **Balance Metrics (Phase 1)**: Total balance (AUM), account type balances, min/max/avg balances
 - **Transaction Metrics (Phase 2)**: Transaction counts, activity levels, dormancy flags, engagement scores
 - Exposed Person fuzzy matching and compliance flags
 - Global sanctions screening with accuracy scoring
- **Operational Views**: Separate current/history views for attributes and addresses support both operational and analytical use cases
- **Fuzzy Exposed Person Matching**: `EDITDISTANCE` functions for similar name detection (compliance screening)
- **Sanctions Integration**: Global sanctions data from Snowflake Data Exchange with fuzzy matching
- **Risk Assessment**: Combined PEP, sanctions, and anomaly risk scoring with numerical scores (0-100)
- **Lifecycle Integration**: Current status, churn probability, lifecycle stage, and risk indicators
- **Historical Tracking**: Full audit trail for all attribute and address changes with VALID_FROM/VALID_TO ranges
- **Performance**: 60-minute refresh for consistent data snapshots across all dependent analytics

### Employee Analytics & Relationship Management
- **Employee Hierarchy**: 3-tier organizational structure (Client Advisors → Team Leaders → Super Team Leaders)
- **Dynamic Scaling**: Employee count scales automatically with customer base (200 clients per advisor)
- **Advisor Performance Tracking**: 8 analytical views providing comprehensive workforce analytics:
 - **Hierarchy Views**: Recursive org chart with full reporting paths and levels
 - **Performance Metrics**: AUM per advisor, client counts, transaction activity, capacity utilization
 - **Portfolio Analytics**: Portfolio valuations by advisor with currency exposure and revenue projections
 - **Team Management**: Aggregated metrics for team leaders with performance distributions
 - **Assignment Tracking**: Current and historical client-advisor relationships (SCD Type 2)
 - **Workload Distribution**: Capacity planning and balance analysis by country/region
- **AUM Tracking**: Assets Under Management per advisor from Customer 360 balance metrics
- **Transaction Activity**: Engagement metrics integrated from transaction summary
- **Revenue Projection**: Estimated annual revenue based on 1% AUM fee assumption
- **Compliance**: Complete audit trail of client assignment changes with reasons
- **Workforce Optimization**: Identify overloaded advisors, available capacity, and hiring triggers
- **Real-Time Data**: Views query latest data for up-to-the-minute workforce insights

### Customer Lifecycle Management
- **Event Tracking**: 9 event types (ONBOARDING, ADDRESS_CHANGE, EMPLOYMENT_CHANGE, ACCOUNT_UPGRADE, ACCOUNT_DOWNGRADE, ACCOUNT_CLOSE, REACTIVATION, CHURN, DORMANT_DETECTED)
- **Status History**: SCD Type 2 tracking with IS_CURRENT flags for regulatory reporting
- **Churn Prediction**: Calculated churn probability based on transaction patterns and dormancy (>180 days)
- **Lifecycle Stages**: NEW, ACTIVE, MATURE, DECLINING, DORMANT, CHURNED
- **Risk Indicators**: IS_DORMANT and IS_AT_RISK flags for proactive retention campaigns
- **AML Correlation**: Cross-domain detection linking lifecycle events with transaction anomalies
- **JSON Event Details**: Structured event metadata stored as VARIANT (single quotes in CSV, converted to valid JSON)
- **Near-Real-Time Processing**: 5-minute task schedule for lifecycle events and status updates

### SWIFT Message Processing
- **ISO20022 Support**: PACS.008 (payment initiation) and PACS.002 (payment status)
- **XML Processing**: Native Snowflake XML parsing
- **Automated Loading**: Stream-triggered processing
- **Message Correlation**: Joined views for complete payment flows

## Object Naming Standards

### Consistent Naming Convention
- **Raw Tables**: `{DOMAIN}I_{OBJECT}` (e.g., `CRMI_CUSTOMER`, `PAYI_TRANSACTIONS`)
- **Aggregation Tables**: `{DOMAIN}A_AGG_DT_{OBJECT}` (e.g., `ICGA_AGG_DT_SWIFT_PACS008`)
- **Dynamic Tables**: `{SCHEMA}_DT_{PURPOSE}` (e.g., `CRMA_AGG_DT_ADDRESSES_CURRENT`)
- **Stages**: `{DOMAIN}I_{OBJECT}` (e.g., `CRMI_CUSTOMERS`)
- **File Formats**: `{DOMAIN}I_FF_{OBJECT}_CSV` (e.g., `CRMI_FF_CUSTOMER_CSV`)
- **Streams**: `{DOMAIN}I_STREAM_{OBJECT}_FILES`
- **Tasks**: `{DOMAIN}I_TASK_LOAD_{OBJECT}`

### Domain Prefixes
- **CRMI**: Customer Master Ingestion
- **CRMA**: Customer Master Aggregation
- **ACCI**: Account Ingestion
- **ACCA**: Account Aggregation
- **EMPI**: Employee Master Ingestion
- **EMPA**: Employee Performance Aggregation
- **REFI**: Reference Data Ingestion
- **REFA**: Reference Data Aggregation
- **PAYI**: Payment Ingestion
- **PAYA**: Payment Aggregation
- **EQTI**: Equity Trading Ingestion
- **ICGI**: Interbank Clearing Gateway Ingestion
- **ICGA**: Interbank Clearing Gateway Aggregation
- **REPP**: Reporting

## Configuration

### Warehouse Settings
All tasks and dynamic tables use: **`MD_TEST_WH`**

To change warehouse:
```sql
-- Search and replace 'MD_TEST_WH' with your warehouse name across all files
```

### Refresh Strategy
- **Tasks**: 1-hour schedule with stream-based triggering
- **Dynamic Tables**: 1-hour `TARGET_LAG` for consistent refresh
- **High-Value Trades**: 1-hour refresh for risk management

### Error Handling
- **Tasks**: `ON_ERROR = CONTINUE` for resilient processing
- **Pattern Matching**: Specific file patterns for each data type
- **Comprehensive Logging**: Built-in Snowflake task logging


## Data Loading

### Automated File Upload Process

Use the automated upload script for seamless data loading:

```bash
# Execute the automated upload script
./upload-data.sh --CONNECTION_NAME=<my-sf-connection>

# Or run in dry-run mode to preview the uploads
./upload-data.sh --CONNECTION_NAME=<my-sf-connection> --DRY_RUN
```

**Features:**
- Uploads all generated data to appropriate Snowflake stages
- Handles customer master data, addresses, lifecycle events, PEP data
- Uploads payment transactions, SWIFT messages, equity/fixed income/commodity trades
- Includes loan documents (emails and PDFs)
- Progress tracking and error handling
- Automatic stage detection and file validation

**See:** `../upload-data.sh` for complete upload automation and stage mappings

### Automated Processing
1. **Streams detect** new files automatically
2. **Tasks process** files within 1 hour
3. **Dynamic tables refresh** according to TARGET_LAG
4. **Data flows** through the complete pipeline

---

**Complete Synthetic Bank Data Platform - Ready to show case!**
