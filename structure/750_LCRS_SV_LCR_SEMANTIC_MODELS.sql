-- ============================================================================
-- 750_LCRS_SV_LCR_SEMANTIC_MODELS.sql
-- LCR Semantic Models for Cortex Analyst AI Agent
-- ============================================================================
-- Purpose: Semantic view for AI agent with NLQ metadata, synonyms, and comments
-- Used by: 850_LIQUIDITY_RISK_AGENT.sql (Cortex Analyst AI Agent)
-- Related: 361_LIQA_BusinessReporting_FINMA_LCR.sql (regular views for dashboards)
-- ============================================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================================
-- SEMANTIC VIEW 1: LCR Current Status
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LCRS_SV_LCR_CURRENT
tables (
  lcr_data AS REPP_AGG_DT_LCR_DAILY
    COMMENT = 'LCR daily calculation with HQLA, outflows, and compliance status'
)

facts (
  -- Date
  lcr_data.AS_OF_DATE as AS_OF_DATE 
    WITH SYNONYMS = ('reporting date', 'calculation date', 'snapshot date', 'data date')
    comment='Date of LCR calculation | as of date | reporting date',
  
  lcr_data.BANK_ID as BANK_ID
    comment='Bank identifier',
  
  -- Primary LCR Metrics
  lcr_data.LCR_RATIO as LCR_RATIO
    WITH SYNONYMS = ('LCR', 'liquidity ratio', 'coverage ratio', 'LCR percentage', 'liquidity coverage ratio')
    comment='Liquidity Coverage Ratio percentage. Primary liquidity metric. Must be >= 100% for FINMA compliance',
  
  lcr_data.LCR_STATUS as LCR_STATUS
    WITH SYNONYMS = ('compliance status', 'regulatory status', 'FINMA status', 'status')
    comment='LCR compliance status | pass/fail status | compliance level',
  
  lcr_data.SEVERITY as SEVERITY
    WITH SYNONYMS = ('status color', 'alert level', 'traffic light')
    comment='Alert severity | RED/YELLOW/GREEN status indicator',
  
  -- HQLA (Numerator)
  lcr_data.HQLA_TOTAL as HQLA_TOTAL
    WITH SYNONYMS = ('HQLA', 'liquid assets', 'high quality assets', 'total HQLA', 'numerator', 'total liquid assets')
    comment='Total High-Quality Liquid Assets in CHF. LCR numerator. Assets available for 30-day stress scenario',
  
  lcr_data.L1_TOTAL as L1_TOTAL
    WITH SYNONYMS = ('Level 1', 'Level 1 assets', 'L1 HQLA', 'highest quality assets', 'zero haircut assets')
    comment='Level 1 HQLA (0% haircut): SNB reserves, cash, Swiss government bonds',
  
  lcr_data.L2A_TOTAL as L2A_TOTAL
    WITH SYNONYMS = ('Level 2A', 'Level 2A assets', 'L2A HQLA')
    comment='Level 2A HQLA (15% haircut): Canton bonds, covered bonds',
  
  lcr_data.L2B_TOTAL as L2B_TOTAL
    WITH SYNONYMS = ('Level 2B', 'Level 2B assets', 'L2B HQLA')
    comment='Level 2B HQLA (50% haircut): SMI equities, corporate bonds',
  
  lcr_data.L2_UNCAPPED as L2_UNCAPPED
    WITH SYNONYMS = ('Level 2 before cap', 'uncapped Level 2')
    comment='Level 2 assets before applying 40% cap',
  
  lcr_data.L2_CAPPED as L2_CAPPED
    WITH SYNONYMS = ('Level 2 after cap', 'capped Level 2')
    comment='Level 2 assets after applying 40% cap',
  
  -- 40% Cap
  lcr_data.CAP_APPLIED as CAP_APPLIED
    WITH SYNONYMS = ('40% cap applied', 'Level 2 cap triggered', 'cap status', 'is cap active')
    comment='Whether 40% cap on Level 2 assets is applied',
  
  lcr_data.DISCARDED_L2 as DISCARDED_L2
    WITH SYNONYMS = ('discarded Level 2', 'excess Level 2', 'capped assets')
    comment='Discarded Level 2 assets due to 40% cap',
  
  -- Net Cash Outflows (Denominator)
  lcr_data.OUTFLOW_TOTAL as OUTFLOW_TOTAL
    WITH SYNONYMS = ('total outflows', 'cash outflows', 'net outflows', 'denominator', 'stressed outflows')
    comment='Total 30-day stressed net cash outflows in CHF. LCR denominator',
  
  lcr_data.OUTFLOW_RETAIL as OUTFLOW_RETAIL
    WITH SYNONYMS = ('retail outflows', 'individual customer outflows')
    comment='Retail customer outflows',
  
  lcr_data.OUTFLOW_CORP as OUTFLOW_CORP
    WITH SYNONYMS = ('corporate outflows', 'business customer outflows')
    comment='Corporate customer outflows',
  
  lcr_data.OUTFLOW_FI as OUTFLOW_FI
    WITH SYNONYMS = ('FI outflows', 'financial institution outflows', 'bank outflows', 'wholesale outflows')
    comment='Financial institution outflows | interbank outflows',
  
  -- Liquidity Buffer
  lcr_data.LCR_BUFFER_CHF as LCR_BUFFER_CHF
    WITH SYNONYMS = ('buffer', 'liquidity buffer', 'cushion', 'excess liquidity', 'safety margin')
    comment='Liquidity buffer (HQLA minus Outflows) in CHF',
  
  lcr_data.LCR_BUFFER_PCT as LCR_BUFFER_PCT
    WITH SYNONYMS = ('buffer percentage', 'buffer percent')
    comment='Liquidity buffer as percentage of outflows',
  
  -- Portfolio Counts
  lcr_data.TOTAL_HOLDINGS as TOTAL_HOLDINGS
    WITH SYNONYMS = ('securities count', 'HQLA securities', 'holdings count', 'portfolio size')
    comment='Number of HQLA securities',
  
  lcr_data.TOTAL_DEPOSIT_ACCOUNTS as TOTAL_DEPOSIT_ACCOUNTS
    WITH SYNONYMS = ('deposit accounts', 'account count')
    comment='Number of deposit accounts',
  
  -- Data Quality
  lcr_data.CALCULATION_TIMESTAMP as CALCULATION_TIMESTAMP
    WITH SYNONYMS = ('calculation time', 'data timestamp', 'calculated at')
    comment='When LCR was last calculated'
);

-- Note: Semantic views inherit permissions from underlying tables, no explicit GRANT needed

SELECT 'Created LCRS_SV_LCR_CURRENT semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 2: HQLA Portfolio Breakdown
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LCRS_SV_HQLA_BREAKDOWN
tables (
  hqla_data AS REPP_AGG_DT_LCR_HQLA
    COMMENT = 'HQLA holdings by level and asset type'
)

facts (
  hqla_data.AS_OF_DATE as AS_OF_DATE
    WITH SYNONYMS = ('reporting date', 'date')
    comment='Date of HQLA snapshot',
  
  hqla_data.HQLA_LEVEL as HQLA_LEVEL
    WITH SYNONYMS = ('level', 'asset level', 'regulatory level')
    comment='HQLA regulatory level: L1, L2A, L2B',
  
  hqla_data.ASSET_TYPE as ASSET_TYPE
    WITH SYNONYMS = ('asset', 'asset class', 'security type')
    comment='Type of asset (CASH_SNB, GOVT_BOND_CHF, etc)',
  
  hqla_data.HOLDINGS_COUNT as HOLDINGS_COUNT
    WITH SYNONYMS = ('count', 'number of holdings', 'securities count')
    comment='Number of securities',
  
  hqla_data.MARKET_VALUE_CHF as MARKET_VALUE_CHF
    WITH SYNONYMS = ('market value', 'value', 'gross value')
    comment='Market value before haircuts',
  
  hqla_data.HAIRCUT_PCT as HAIRCUT_PCT
    WITH SYNONYMS = ('haircut', 'haircut percentage')
    comment='Regulatory haircut percentage',
  
  hqla_data.HQLA_VALUE_CHF as HQLA_VALUE_CHF
    WITH SYNONYMS = ('HQLA value', 'value after haircut', 'net value')
    comment='HQLA value after applying haircut',
  
  hqla_data.PCT_OF_TOTAL_HQLA as PCT_OF_TOTAL_HQLA
    WITH SYNONYMS = ('percentage', 'percent of total', 'composition')
    comment='Percentage of total HQLA'
);

SELECT 'Created LCRS_SV_HQLA_BREAKDOWN semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 3: Deposit Outflow Breakdown
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LCRS_SV_OUTFLOW_BREAKDOWN
tables (
  outflow_data AS REPP_AGG_DT_LCR_OUTFLOW
    COMMENT = 'Deposit outflows by counterparty type'
)

facts (
  outflow_data.AS_OF_DATE as AS_OF_DATE
    WITH SYNONYMS = ('reporting date', 'date')
    comment='Date of deposit snapshot',
  
  outflow_data.COUNTERPARTY_TYPE as COUNTERPARTY_TYPE
    WITH SYNONYMS = ('counterparty', 'customer type', 'deposit type')
    comment='Type of counterparty (RETAIL, CORPORATE, FINANCIAL_INSTITUTION)',
  
  outflow_data.ACCOUNT_COUNT as ACCOUNT_COUNT
    WITH SYNONYMS = ('accounts', 'number of accounts')
    comment='Number of deposit accounts',
  
  outflow_data.CUSTOMER_COUNT as CUSTOMER_COUNT
    WITH SYNONYMS = ('customers', 'number of customers')
    comment='Number of unique customers',
  
  outflow_data.BALANCE_CHF as BALANCE_CHF
    WITH SYNONYMS = ('balance', 'deposit balance', 'deposits')
    comment='Total deposit balance in CHF',
  
  outflow_data.RUN_OFF_RATE as RUN_OFF_RATE
    WITH SYNONYMS = ('run-off rate', 'runoff rate', 'withdrawal rate')
    comment='Weighted average run-off rate',
  
  outflow_data.OUTFLOW_AMOUNT_CHF as OUTFLOW_AMOUNT_CHF
    WITH SYNONYMS = ('outflow', 'stressed outflow', 'withdrawal amount')
    comment='Expected 30-day outflow amount',
  
  outflow_data.PCT_OF_TOTAL_OUTFLOWS as PCT_OF_TOTAL_OUTFLOWS
    WITH SYNONYMS = ('percentage of outflows', 'outflow percentage')
    comment='Percentage of total outflows',
  
  outflow_data.PCT_OF_TOTAL_DEPOSITS as PCT_OF_TOTAL_DEPOSITS
    WITH SYNONYMS = ('percentage of deposits', 'deposit percentage')
    comment='Percentage of total deposits'
);

SELECT 'Created LCRS_SV_OUTFLOW_BREAKDOWN semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 4: LCR 90-Day Trend
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LCRS_SV_TREND_90DAY
tables (
  trend_data AS REPP_AGG_DT_LCR_DAILY
    COMMENT = 'Daily LCR ratios for trend analysis'
)

facts (
  trend_data.AS_OF_DATE as AS_OF_DATE
    WITH SYNONYMS = ('date', 'reporting date', 'day')
    comment='Date of LCR calculation',
  
  trend_data.LCR_RATIO as LCR_RATIO
    WITH SYNONYMS = ('LCR', 'ratio', 'liquidity ratio')
    comment='Daily LCR ratio percentage',
  
  trend_data.LCR_STATUS as LCR_STATUS
    WITH SYNONYMS = ('status', 'compliance status')
    comment='Compliance status (PASS/WARNING/FAIL)',
  
  trend_data.SEVERITY as SEVERITY
    WITH SYNONYMS = ('severity', 'color', 'alert level')
    comment='Severity indicator (GREEN/YELLOW/RED)',
  
  trend_data.HQLA_TOTAL as HQLA_TOTAL
    WITH SYNONYMS = ('HQLA', 'liquid assets')
    comment='Total HQLA in CHF',
  
  trend_data.OUTFLOW_TOTAL as OUTFLOW_TOTAL
    WITH SYNONYMS = ('outflows', 'cash outflows')
    comment='Total net cash outflows',
  
  trend_data.LCR_BUFFER_CHF as LCR_BUFFER_CHF
    WITH SYNONYMS = ('buffer', 'liquidity buffer', 'excess')
    comment='Liquidity buffer in CHF',
  
  trend_data.CAP_APPLIED as CAP_APPLIED
    WITH SYNONYMS = ('cap applied', '40% cap', 'cap status')
    comment='Whether 40% cap was applied'
);

SELECT 'Created LCRS_SV_TREND_90DAY semantic view' AS status;

-- ============================================================================
-- SEMANTIC VIEW 5: Active Compliance Alerts
-- ============================================================================

CREATE OR REPLACE SEMANTIC VIEW LCRS_SV_ALERTS_ACTIVE
tables (
  alerts_data AS REPP_AGG_VW_LCR_ALERTS
    COMMENT = 'Active LCR compliance alerts'
)

facts (
  alerts_data.AS_OF_DATE as AS_OF_DATE
    WITH SYNONYMS = ('date', 'alert date')
    comment='Date of alert',
  
  alerts_data.LCR_RATIO as LCR_RATIO
    WITH SYNONYMS = ('LCR', 'ratio')
    comment='LCR ratio when alert triggered',
  
  alerts_data.LCR_STATUS as LCR_STATUS
    WITH SYNONYMS = ('status', 'compliance status')
    comment='Compliance status',
  
  alerts_data.SEVERITY as SEVERITY
    WITH SYNONYMS = ('severity', 'alert severity', 'priority')
    comment='Alert severity level',
  
  alerts_data.TOTAL_ALERT_COUNT as TOTAL_ALERT_COUNT
    WITH SYNONYMS = ('alert count', 'number of alerts', 'alerts')
    comment='Total number of active alerts',
  
  alerts_data.HIGHEST_SEVERITY as HIGHEST_SEVERITY
    WITH SYNONYMS = ('highest severity', 'max severity', 'worst severity')
    comment='Highest severity among all alerts'
);

SELECT 'Created LCRS_SV_ALERTS_ACTIVE semantic view' AS status;
-- ============================================================================
