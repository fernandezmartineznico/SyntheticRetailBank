-- ============================================================
-- SEMANTIC VIEW - Business-Friendly Data Access
-- Created on: 2025-10-05 (Deployed after all reporting schemas)
-- ============================================================
--
-- OVERVIEW:
-- This semantic view provides a unified, business-friendly interface to all
-- reporting tables across multiple schemas. It combines core reporting,
-- equity trading, credit risk, FRTB, and portfolio performance data into
-- a single accessible view for business users and analytics tools.
--
-- BUSINESS PURPOSE:
-- - Single interface for all reporting and analytics data
-- - Business-friendly column names and descriptions
-- - Unified access to cross-domain analytics
-- - Simplified querying for business intelligence tools
-- - Consistent data access patterns across all reporting domains
--
-- PREREQUISITES:
-- - All reporting schemas must be deployed first:
--   * 500_REPP_core_reporting.sql (Core reporting)
--   * 510_REPP_EQUITY.sql (Equity trading)
--   * 520_REPP_CREDIT_RISK.sql (Credit risk)
--   * 525_REPP_FRTB.sql (FRTB market risk)
--   * 530_REPP_PORTFOLIO.sql (Portfolio performance)
-- - All dynamic tables must be created and refreshed
-- - This view is deployed as 550_semantic_view.sql in the deployment sequence
--
-- USAGE:
-- - Business users can query this view directly
-- - Analytics tools can use this as the primary data source
-- - Reports can be built on top of this unified view
-- - Cross-domain analysis becomes straightforward
--
-- RELATED SCHEMAS:
-- - REP_AGG_001: Core reporting tables
-- - REP_AGG_001: Equity trading tables (510_REPP_EQUITY.sql)
-- - REP_AGG_001: Credit risk tables (520_REPP_CREDIT_RISK.sql)
-- - REP_AGG_001: FRTB tables (525_REPP_FRTB.sql)
-- - REP_AGG_001: Portfolio performance tables (530_REPP_PORTFOLIO.sql)
-- ============================================================

USE DATABASE AAA_DEV_SYNTHETIC_BANK;
USE SCHEMA REP_AGG_001;

-- ============================================================
-- REPP_SEMANTIC_VIEW - Unified Business Data Access
-- ============================================================
-- Comprehensive semantic view combining all reporting tables
-- for unified business intelligence and analytics access

CREATE OR REPLACE SEMANTIC VIEW REPP_SEMANTIC_VIEW
	tables (
		-- Core Reporting Tables (500_REPP_core_reporting.sql)
		REPP_AGG_DT_ANOMALY_ANALYSIS,
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT,
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY,
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE,
		REPP_AGG_DT_CUSTOMER_SUMMARY,
		REPP_AGG_DT_HIGH_RISK_PATTERNS,
		
		-- Equity Trading Tables (510_REPP_EQUITY.sql)
		REPP_AGG_DT_EQUITY_SUMMARY,
		REPP_AGG_DT_EQUITY_POSITIONS,
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE,
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES,
		
		-- Credit Risk Tables (520_REPP_CREDIT_RISK.sql)
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS,
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS,
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY,
		REPP_AGG_DT_IRB_RWA_SUMMARY,
		REPP_AGG_DT_IRB_RISK_TRENDS,
		
		-- FRTB Tables (525_REPP_FRTB.sql)
		REPP_AGG_DT_FRTB_RISK_POSITIONS,
		REPP_AGG_DT_FRTB_SENSITIVITIES,
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES,
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS,
		
		-- Portfolio Performance Tables (600_REPP_PORTFOLIO.sql)
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE
	)
	facts (
		-- Core Reporting Facts
		REPP_AGG_DT_ANOMALY_ANALYSIS.ANOMALOUS_AMOUNT as ANOMALOUS_AMOUNT comment='Total value of suspicious transactions',
		REPP_AGG_DT_ANOMALY_ANALYSIS.ANOMALOUS_TRANSACTIONS as ANOMALOUS_TRANSACTIONS comment='Count of flagged transactions',
		REPP_AGG_DT_ANOMALY_ANALYSIS.ANOMALY_PERCENTAGE as ANOMALY_PERCENTAGE comment='Percentage of anomalous activity',
		REPP_AGG_DT_ANOMALY_ANALYSIS.TOTAL_TRANSACTIONS as TOTAL_TRANSACTIONS comment='Total transaction count for baseline comparison',
		
		-- Currency Exposure Facts
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.AVG_FX_RATE as AVG_FX_RATE comment='Average exchange rate for this currency',
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.MAX_FX_RATE as MAX_FX_RATE comment='Highest exchange rate observed',
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.MIN_FX_RATE as MIN_FX_RATE comment='Lowest exchange rate observed',
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.TOTAL_CHF_AMOUNT as TOTAL_CHF_AMOUNT comment='Total exposure in CHF equivalent',
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.TOTAL_ORIGINAL_AMOUNT as TOTAL_ORIGINAL_AMOUNT comment='Total exposure in original currency',
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.TRANSACTION_COUNT as TRANSACTION_COUNT comment='Number of transactions in this currency',
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.UNIQUE_CUSTOMERS as UNIQUE_CUSTOMERS comment='Number of unique customers with this currency exposure',
		
		-- Historical Currency Facts
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.AMOUNT_30_DAYS_AGO as AMOUNT_30_DAYS_AGO comment='Exposure amount 30 days ago for trend analysis',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_AVG_AMOUNT as DAILY_AVG_AMOUNT comment='Average daily exposure amount',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_MAX_AMOUNT as DAILY_MAX_AMOUNT comment='Maximum daily exposure amount',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_MIN_AMOUNT as DAILY_MIN_AMOUNT comment='Minimum daily exposure amount',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_TOTAL_AMOUNT as DAILY_TOTAL_AMOUNT comment='Total daily exposure amount',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_TRANSACTION_COUNT as DAILY_TRANSACTION_COUNT comment='Number of transactions on this date',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_UNIQUE_CUSTOMERS as DAILY_UNIQUE_CUSTOMERS comment='Number of unique customers on this date',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.GROWTH_RATE_30D_PERCENT as GROWTH_RATE_30D_PERCENT comment='30-day growth rate percentage',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.ROLLING_7D_AVG_DAILY_AMOUNT as ROLLING_7D_AVG_DAILY_AMOUNT comment='7-day rolling average daily amount',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.ROLLING_7D_TOTAL_AMOUNT as ROLLING_7D_TOTAL_AMOUNT comment='7-day rolling total amount',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.ROLLING_7D_TRANSACTION_COUNT as ROLLING_7D_TRANSACTION_COUNT comment='7-day rolling transaction count',
		
		-- Settlement Exposure Facts
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.AVG_SETTLEMENT_DAYS as AVG_SETTLEMENT_DAYS comment='Average settlement time in days',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.BACKDATED_SETTLEMENTS as BACKDATED_SETTLEMENTS comment='Settlements with backdated value dates',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.DELAYED_SETTLEMENTS as DELAYED_SETTLEMENTS comment='Settlements delayed beyond standard period',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.SAME_DAY_SETTLEMENTS as SAME_DAY_SETTLEMENTS comment='Immediate settlement transactions',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.SETTLEMENT_TOTAL_AMOUNT as SETTLEMENT_TOTAL_AMOUNT comment='Total amount settling in this currency',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.SETTLEMENT_TRANSACTION_COUNT as SETTLEMENT_TRANSACTION_COUNT comment='Number of transactions settling on this date',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.T_PLUS_1_SETTLEMENTS as T_PLUS_1_SETTLEMENTS comment='Next business day settlements',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.T_PLUS_2_3_SETTLEMENTS as T_PLUS_2_3_SETTLEMENTS comment='Standard settlement period transactions',
		
		-- Customer Summary Facts
		REPP_AGG_DT_CUSTOMER_SUMMARY.ANOMALOUS_TRANSACTIONS as ANOMALOUS_TRANSACTIONS comment='Count of transactions with suspicious patterns',
		REPP_AGG_DT_CUSTOMER_SUMMARY.AVG_TRANSACTION_AMOUNT as AVG_TRANSACTION_AMOUNT comment='Average transaction size for customer profiling',
		REPP_AGG_DT_CUSTOMER_SUMMARY.CURRENCY_COUNT as CURRENCY_COUNT comment='Number of different currencies in customer portfolio',
		REPP_AGG_DT_CUSTOMER_SUMMARY.MAX_TRANSACTION_AMOUNT as MAX_TRANSACTION_AMOUNT comment='Largest single transaction for risk assessment',
		REPP_AGG_DT_CUSTOMER_SUMMARY.TOTAL_ACCOUNTS as TOTAL_ACCOUNTS comment='Number of accounts held by customer',
		REPP_AGG_DT_CUSTOMER_SUMMARY.TOTAL_BASE_AMOUNT as TOTAL_BASE_AMOUNT comment='Total transaction volume in base currency',
		REPP_AGG_DT_CUSTOMER_SUMMARY.TOTAL_TRANSACTIONS as TOTAL_TRANSACTIONS comment='Total number of transactions across all accounts',
		
		-- High Risk Patterns Facts
		REPP_AGG_DT_HIGH_RISK_PATTERNS.AMOUNT as AMOUNT comment='Transaction amount in original currency',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.SETTLEMENT_DAYS as SETTLEMENT_DAYS comment='Number of days between booking and settlement',
		
		-- Equity Trading Facts
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.CHF_VALUE as CHF_VALUE comment='Trade value in CHF for threshold monitoring',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.PRICE as PRICE comment='Execution price per unit',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.QUANTITY as QUANTITY comment='Number of shares/units traded',
		
		-- Credit Risk Facts
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.DAYS_PAST_DUE as DAYS_PAST_DUE comment='Days past due at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.LGD_RATE as LGD_RATE comment='Loss Given Default rate at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.PD_1_YEAR as PD_1_YEAR comment='Probability of Default (1-year) at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.PD_LIFETIME as PD_LIFETIME comment='Lifetime Probability of Default at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.RISK_WEIGHT as RISK_WEIGHT comment='Risk weight percentage at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total exposure amount at this point in time',
		
		-- Portfolio Performance Facts
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.TOTAL_PORTFOLIO_VALUE_CHF as TOTAL_PORTFOLIO_VALUE_CHF comment='Total portfolio value in CHF',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.TOTAL_PORTFOLIO_TWR_PERCENTAGE as TOTAL_PORTFOLIO_TWR_PERCENTAGE comment='Combined Time Weighted Return for entire portfolio (%)',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.ANNUALIZED_PORTFOLIO_TWR as ANNUALIZED_PORTFOLIO_TWR comment='Annualized portfolio TWR (%)',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.SHARPE_RATIO as SHARPE_RATIO comment='Risk-adjusted return (Sharpe Ratio)',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.MAX_DRAWDOWN_PERCENTAGE as MAX_DRAWDOWN_PERCENTAGE comment='Maximum peak-to-trough decline (%)'
	)
	dimensions (
		-- Core Reporting Dimensions
		REPP_AGG_DT_ANOMALY_ANALYSIS.ANOMALY_TYPES as ANOMALY_TYPES comment='Types of anomalies detected for investigation',
		REPP_AGG_DT_ANOMALY_ANALYSIS.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for compliance tracking',
		REPP_AGG_DT_ANOMALY_ANALYSIS.FULL_NAME as FULL_NAME comment='Customer name for investigation reports',
		REPP_AGG_DT_ANOMALY_ANALYSIS.IS_ANOMALOUS_CUSTOMER as IS_ANOMALOUS_CUSTOMER comment='Customer-level anomaly flag from profiling',
		
		-- Currency Exposure Dimensions
		REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT.CURRENCY as CURRENCY comment='Currency for exposure analysis',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.CURRENCY as CURRENCY comment='Currency for historical trend analysis',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_EXPOSURE_CATEGORY as DAILY_EXPOSURE_CATEGORY comment='Exposure level classification for risk management',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.DAILY_VOLUME_CATEGORY as DAILY_VOLUME_CATEGORY comment='Volume level classification for liquidity planning',
		REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY.EXPOSURE_DATE as EXPOSURE_DATE comment='Business date for time series analysis',
		
		-- Settlement Exposure Dimensions
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.CURRENCY as CURRENCY comment='Currency for settlement risk analysis',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.SETTLEMENT_DATE as SETTLEMENT_DATE comment='Settlement date for liquidity planning',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.SETTLEMENT_RISK_LEVEL as SETTLEMENT_RISK_LEVEL comment='Overall settlement risk classification',
		REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE.SETTLEMENT_TIMING_TYPE as SETTLEMENT_TIMING_TYPE comment='Settlement timing pattern for operational planning',
		
		-- Customer Summary Dimensions
		REPP_AGG_DT_CUSTOMER_SUMMARY.ACCOUNT_CURRENCIES as ACCOUNT_CURRENCIES comment='Comma-separated list of all currencies used by customer',
		REPP_AGG_DT_CUSTOMER_SUMMARY.CUSTOMER_ID as CUSTOMER_ID comment='Unique customer identifier for relationship management (CUST_XXXXX format)',
		REPP_AGG_DT_CUSTOMER_SUMMARY.FULL_NAME as FULL_NAME comment='Customer full name (First + Last) for reporting and compliance',
		REPP_AGG_DT_CUSTOMER_SUMMARY.HAS_ANOMALY as HAS_ANOMALY comment='Flag indicating if customer has anomalous behavior patterns',
		REPP_AGG_DT_CUSTOMER_SUMMARY.ONBOARDING_DATE as ONBOARDING_DATE comment='Date when customer relationship was established',
		
		-- High Risk Patterns Dimensions
		REPP_AGG_DT_HIGH_RISK_PATTERNS.BOOKING_DATE as BOOKING_DATE comment='Date when transaction was booked in system',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.CURRENCY as CURRENCY comment='Currency code (ISO 4217) of the transaction',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for risk profiling',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.DESCRIPTION as DESCRIPTION comment='Transaction description text for analysis',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.DIRECTION as DIRECTION comment='Transaction flow direction (IN/OUT)',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.RISK_CATEGORY as RISK_CATEGORY comment='Primary risk classification for compliance review (HIGH_AMOUNT/ANOMALOUS/OFFSHORE/CRYPTO/etc.)',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.TRANSACTION_ID as TRANSACTION_ID comment='Unique identifier for each transaction',
		REPP_AGG_DT_HIGH_RISK_PATTERNS.VALUE_DATE as VALUE_DATE comment='Settlement date for the transaction',
		
		-- Equity Trading Dimensions
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.ACCOUNT_ID as ACCOUNT_ID comment='Account identifier for position tracking',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for large trade monitoring',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.MARKET as MARKET comment='Market/exchange where trade was executed',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.SIDE as SIDE comment='Trade direction (1=Buy, 2=Sell)',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.SYMBOL as SYMBOL comment='Security symbol for concentration risk analysis',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.TRADE_DATE as TRADE_DATE comment='Trade execution date for compliance tracking',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.TRADE_ID as TRADE_ID comment='Unique trade identifier for audit trail',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.VENUE as VENUE comment='Trading venue for best execution analysis',
		
		-- Credit Risk Dimensions
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.CREDIT_RATING as CREDIT_RATING comment='Credit rating at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for historical tracking',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.DEFAULT_FLAG as DEFAULT_FLAG comment='Whether customer was in default at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.EFFECTIVE_DATE as EFFECTIVE_DATE comment='Date when this rating became effective',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.RATING_DATE as RATING_DATE comment='Date when rating was calculated',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.WATCH_LIST_FLAG as WATCH_LIST_FLAG comment='Whether customer was on watch list at this point in time',
		
		-- Portfolio Performance Dimensions
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.ACCOUNT_ID as ACCOUNT_ID comment='Account identifier for portfolio tracking',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for relationship management',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.ACCOUNT_TYPE as ACCOUNT_TYPE comment='Account type (CHECKING/SAVINGS/BUSINESS/INVESTMENT)',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.BASE_CURRENCY as BASE_CURRENCY comment='Base currency for reporting',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.PERFORMANCE_CATEGORY as PERFORMANCE_CATEGORY comment='Performance classification (EXCELLENT/GOOD/NEUTRAL/POOR/NEGATIVE)',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.RISK_CATEGORY as RISK_CATEGORY comment='Risk classification (LOW/MODERATE/HIGH/VERY_HIGH)',
		REPP_AGG_DT_PORTFOLIO_PERFORMANCE.PORTFOLIO_TYPE as PORTFOLIO_TYPE comment='Portfolio composition type (CASH_ONLY/EQUITY_FOCUSED/FI_FOCUSED/COMMODITY_FOCUSED/BALANCED/MULTI_ASSET)'
	)
	with extension (CA='{"tables":[{"name":"REPP_AGG_DT_ANOMALY_ANALYSIS","dimensions":[{"name":"ANOMALY_TYPES"},{"name":"CUSTOMER_ID"},{"name":"FULL_NAME"},{"name":"IS_ANOMALOUS_CUSTOMER"}],"facts":[{"name":"ANOMALOUS_AMOUNT"},{"name":"ANOMALOUS_TRANSACTIONS"},{"name":"ANOMALY_PERCENTAGE"},{"name":"TOTAL_TRANSACTIONS"}]},{"name":"REPP_AGG_DT_CURRENCY_EXPOSURE_CURRENT","dimensions":[{"name":"CURRENCY"}],"facts":[{"name":"AVG_FX_RATE"},{"name":"MAX_FX_RATE"},{"name":"MIN_FX_RATE"},{"name":"TOTAL_CHF_AMOUNT"},{"name":"TOTAL_ORIGINAL_AMOUNT"},{"name":"TRANSACTION_COUNT"},{"name":"UNIQUE_CUSTOMERS"}]},{"name":"REPP_AGG_DT_CURRENCY_EXPOSURE_HISTORY","dimensions":[{"name":"CURRENCY"},{"name":"DAILY_EXPOSURE_CATEGORY"},{"name":"DAILY_VOLUME_CATEGORY"}],"facts":[{"name":"AMOUNT_30_DAYS_AGO"},{"name":"DAILY_AVG_AMOUNT"},{"name":"DAILY_MAX_AMOUNT"},{"name":"DAILY_MIN_AMOUNT"},{"name":"DAILY_TOTAL_AMOUNT"},{"name":"DAILY_TRANSACTION_COUNT"},{"name":"DAILY_UNIQUE_CUSTOMERS"},{"name":"GROWTH_RATE_30D_PERCENT"},{"name":"ROLLING_7D_AVG_DAILY_AMOUNT"},{"name":"ROLLING_7D_TOTAL_AMOUNT"},{"name":"ROLLING_7D_TRANSACTION_COUNT"}],"time_dimensions":[{"name":"EXPOSURE_DATE"}]},{"name":"REPP_AGG_DT_CURRENCY_SETTLEMENT_EXPOSURE","dimensions":[{"name":"CURRENCY"},{"name":"SETTLEMENT_RISK_LEVEL"},{"name":"SETTLEMENT_TIMING_TYPE"}],"facts":[{"name":"AVG_SETTLEMENT_DAYS"},{"name":"BACKDATED_SETTLEMENTS"},{"name":"DELAYED_SETTLEMENTS"},{"name":"SAME_DAY_SETTLEMENTS"},{"name":"SETTLEMENT_TOTAL_AMOUNT"},{"name":"SETTLEMENT_TRANSACTION_COUNT"},{"name":"T_PLUS_1_SETTLEMENTS"},{"name":"T_PLUS_2_3_SETTLEMENTS"}],"time_dimensions":[{"name":"SETTLEMENT_DATE"}]},{"name":"REPP_AGG_DT_CUSTOMER_SUMMARY","dimensions":[{"name":"ACCOUNT_CURRENCIES"},{"name":"CUSTOMER_ID"},{"name":"FULL_NAME"},{"name":"HAS_ANOMALY"}],"facts":[{"name":"ANOMALOUS_TRANSACTIONS"},{"name":"AVG_TRANSACTION_AMOUNT"},{"name":"CURRENCY_COUNT"},{"name":"MAX_TRANSACTION_AMOUNT"},{"name":"TOTAL_ACCOUNTS"},{"name":"TOTAL_BASE_AMOUNT"},{"name":"TOTAL_TRANSACTIONS"}],"time_dimensions":[{"name":"ONBOARDING_DATE"}]},{"name":"REPP_AGG_DT_HIGH_RISK_PATTERNS","dimensions":[{"name":"CURRENCY"},{"name":"CUSTOMER_ID"},{"name":"DESCRIPTION"},{"name":"DIRECTION"},{"name":"RISK_CATEGORY"},{"name":"TRANSACTION_ID"}],"facts":[{"name":"AMOUNT"},{"name":"SETTLEMENT_DAYS"}],"time_dimensions":[{"name":"BOOKING_DATE"},{"name":"VALUE_DATE"}]},{"name":"REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES","dimensions":[{"name":"ACCOUNT_ID"},{"name":"CUSTOMER_ID"},{"name":"MARKET"},{"name":"SIDE"},{"name":"SYMBOL"},{"name":"TRADE_ID"},{"name":"VENUE"}],"facts":[{"name":"CHF_VALUE"},{"name":"PRICE"},{"name":"QUANTITY"}],"time_dimensions":[{"name":"TRADE_DATE"}]},{"name":"REPP_AGG_DT_CUSTOMER_RATING_HISTORY","dimensions":[{"name":"CREDIT_RATING"},{"name":"CUSTOMER_ID"},{"name":"DEFAULT_FLAG"},{"name":"WATCH_LIST_FLAG"}],"facts":[{"name":"DAYS_PAST_DUE"},{"name":"LGD_RATE"},{"name":"PD_1_YEAR"},{"name":"PD_LIFETIME"},{"name":"RISK_WEIGHT"},{"name":"TOTAL_EXPOSURE_CHF"}],"time_dimensions":[{"name":"EFFECTIVE_DATE"},{"name":"RATING_DATE"}]},{"name":"REPP_AGG_DT_PORTFOLIO_PERFORMANCE","dimensions":[{"name":"ACCOUNT_ID"},{"name":"CUSTOMER_ID"},{"name":"ACCOUNT_TYPE"},{"name":"BASE_CURRENCY"},{"name":"PERFORMANCE_CATEGORY"},{"name":"RISK_CATEGORY"},{"name":"PORTFOLIO_TYPE"}],"facts":[{"name":"TOTAL_PORTFOLIO_VALUE_CHF"},{"name":"TOTAL_PORTFOLIO_TWR_PERCENTAGE"},{"name":"ANNUALIZED_PORTFOLIO_TWR"},{"name":"SHARPE_RATIO"},{"name":"MAX_DRAWDOWN_PERCENTAGE"}],"time_dimensions":[{"name":"MEASUREMENT_PERIOD_START"},{"name":"MEASUREMENT_PERIOD_END"}]}]}');

create or replace semantic view AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.CREDIT_RISK_IRB_REPORTING
	tables (
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS,
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS,
		REPP_AGG_DT_IRB_RISK_TRENDS,
		REPP_AGG_DT_IRB_RWA_SUMMARY,
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY
	)
	facts (
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.DAYS_PAST_DUE as DAYS_PAST_DUE comment='Current days past due for default identification',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.EAD_AMOUNT as EAD_AMOUNT comment='Exposure at Default amount in CHF - total exposure',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.LGD_RATE as LGD_RATE comment='Loss Given Default rate (%) - expected loss severity',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.PD_1_YEAR as PD_1_YEAR comment='Probability of Default over 1 year horizon (%)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.PD_LIFETIME as PD_LIFETIME comment='Lifetime Probability of Default (%)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.RISK_WEIGHT as RISK_WEIGHT comment='Risk weight (%) for RWA calculation under IRB approach',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.SECURED_EXPOSURE_CHF as SECURED_EXPOSURE_CHF comment='Secured portion of exposure with collateral',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total credit exposure across all facilities in CHF',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.UNSECURED_EXPOSURE_CHF as UNSECURED_EXPOSURE_CHF comment='Unsecured exposure without collateral',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.AVERAGE_EXPOSURE_CHF as AVERAGE_EXPOSURE_CHF comment='Average exposure per customer in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CAPITAL_REQUIREMENT_CHF as CAPITAL_REQUIREMENT_CHF comment='Minimum capital requirement (8% of RWA) in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.COLLATERAL_COVERAGE_RATIO as COLLATERAL_COVERAGE_RATIO comment='Secured exposure as % of total exposure',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CONCENTRATION_RISK_SCORE as CONCENTRATION_RISK_SCORE comment='Portfolio concentration risk score (1-10 scale)',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CUSTOMER_COUNT as CUSTOMER_COUNT comment='Number of customers in this rating/segment combination',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.DEFAULT_COUNT as DEFAULT_COUNT comment='Number of customers currently in default',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.DEFAULT_RATE as DEFAULT_RATE comment='Default rate (%) within this portfolio segment',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.EXPECTED_LOSS_CHF as EXPECTED_LOSS_CHF comment='Expected Loss = EAD × PD × LGD in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.RISK_WEIGHTED_ASSETS_CHF as RISK_WEIGHTED_ASSETS_CHF comment='Risk Weighted Assets under IRB approach in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.SECURED_EXPOSURE_CHF as SECURED_EXPOSURE_CHF comment='Total secured exposure with collateral in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total credit exposure in CHF for this portfolio segment',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.UNSECURED_EXPOSURE_CHF as UNSECURED_EXPOSURE_CHF comment='Total unsecured exposure without collateral in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.VINTAGE_MONTHS as VINTAGE_MONTHS comment='Average customer vintage in months for maturity analysis',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WATCH_LIST_COUNT as WATCH_LIST_COUNT comment='Number of customers on credit watch list',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WATCH_LIST_RATE as WATCH_LIST_RATE comment='Watch list rate (%) within this portfolio segment',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WEIGHTED_AVG_LGD as WEIGHTED_AVG_LGD comment='Exposure-weighted average Loss Given Default (%)',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WEIGHTED_AVG_PD as WEIGHTED_AVG_PD comment='Exposure-weighted average Probability of Default (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_LGD_RATE as AVG_LGD_RATE comment='Average LGD rate across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_PD_1_YEAR as AVG_PD_1_YEAR comment='Average 1-year PD across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_PD_LIFETIME as AVG_PD_LIFETIME comment='Average lifetime PD across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_RISK_WEIGHT as AVG_RISK_WEIGHT comment='Average risk weight across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.BACKTESTING_ACCURACY as BACKTESTING_ACCURACY comment='Model backtesting accuracy (%) against actual defaults',
		REPP_AGG_DT_IRB_RISK_TRENDS.CURED_DEFAULTS as CURED_DEFAULTS comment='Number of defaults that cured on this date',
		REPP_AGG_DT_IRB_RISK_TRENDS.DEFAULT_RATE as DEFAULT_RATE comment='Observed default rate on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.EXPECTED_LOSS_CHF as EXPECTED_LOSS_CHF comment='Total Expected Loss on this date in CHF',
		REPP_AGG_DT_IRB_RISK_TRENDS.MODEL_PERFORMANCE_SCORE as MODEL_PERFORMANCE_SCORE comment='PD model performance score (1-10, 10=best)',
		REPP_AGG_DT_IRB_RISK_TRENDS.NET_DEFAULT_CHANGE as NET_DEFAULT_CHANGE comment='Net change in default count (new - cured)',
		REPP_AGG_DT_IRB_RISK_TRENDS.NEW_DEFAULTS as NEW_DEFAULTS comment='Number of new defaults identified on this date',
		REPP_AGG_DT_IRB_RISK_TRENDS.RATING_MIGRATIONS_DOWN as RATING_MIGRATIONS_DOWN comment='Number of customers with rating downgrades',
		REPP_AGG_DT_IRB_RISK_TRENDS.RATING_MIGRATIONS_UP as RATING_MIGRATIONS_UP comment='Number of customers with rating upgrades',
		REPP_AGG_DT_IRB_RISK_TRENDS.STRESS_TEST_MULTIPLIER as STRESS_TEST_MULTIPLIER comment='Stress testing multiplier applied to base PD',
		REPP_AGG_DT_IRB_RISK_TRENDS.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total portfolio exposure on this date in CHF',
		REPP_AGG_DT_IRB_RISK_TRENDS.TOTAL_RWA_CHF as TOTAL_RWA_CHF comment='Total Risk Weighted Assets on this date in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.AVERAGE_RISK_WEIGHT as AVERAGE_RISK_WEIGHT comment='Portfolio-weighted average risk weight (%)',
		REPP_AGG_DT_IRB_RWA_SUMMARY.CORPORATE_EXPOSURE_CHF as CORPORATE_EXPOSURE_CHF comment='Total corporate portfolio exposure in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.CORPORATE_RWA_CHF as CORPORATE_RWA_CHF comment='Corporate portfolio Risk Weighted Assets in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.DEFAULT_CUSTOMERS as DEFAULT_CUSTOMERS comment='Total number of customers in default across all portfolios',
		REPP_AGG_DT_IRB_RWA_SUMMARY.LEVERAGE_RATIO as LEVERAGE_RATIO comment='Simulated leverage ratio (%) - regulatory minimum 3%',
		REPP_AGG_DT_IRB_RWA_SUMMARY.PORTFOLIO_DEFAULT_RATE as PORTFOLIO_DEFAULT_RATE comment='Overall portfolio default rate (%)',
		REPP_AGG_DT_IRB_RWA_SUMMARY.RETAIL_EXPOSURE_CHF as RETAIL_EXPOSURE_CHF comment='Total retail portfolio exposure in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.RETAIL_RWA_CHF as RETAIL_RWA_CHF comment='Retail portfolio Risk Weighted Assets in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.SME_EXPOSURE_CHF as SME_EXPOSURE_CHF comment='Total SME portfolio exposure in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.SME_RWA_CHF as SME_RWA_CHF comment='SME portfolio Risk Weighted Assets in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TIER1_CAPITAL_RATIO as TIER1_CAPITAL_RATIO comment='Simulated Tier 1 capital ratio (%) - regulatory minimum 6%',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_CAPITAL_RATIO as TOTAL_CAPITAL_RATIO comment='Simulated total capital ratio (%) - regulatory minimum 8%',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_CAPITAL_REQUIREMENT_CHF as TOTAL_CAPITAL_REQUIREMENT_CHF comment='Total minimum capital requirement (8% of RWA) in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_CUSTOMERS as TOTAL_CUSTOMERS comment='Total number of customers across all portfolios',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_EXPECTED_LOSS_CHF as TOTAL_EXPECTED_LOSS_CHF comment='Total Expected Loss across all portfolios in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total credit exposure across all portfolios in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_RWA_CHF as TOTAL_RWA_CHF comment='Total Risk Weighted Assets under IRB approach in CHF',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.DAYS_PAST_DUE as DAYS_PAST_DUE comment='Days past due at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.LGD_RATE as LGD_RATE comment='Loss Given Default rate at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.PD_1_YEAR as PD_1_YEAR comment='Probability of Default (1-year) at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.PD_LIFETIME as PD_LIFETIME comment='Lifetime Probability of Default at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.RISK_WEIGHT as RISK_WEIGHT comment='Risk weight percentage at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total exposure amount at this point in time'
	)
	dimensions (
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.CREDIT_RATING as CREDIT_RATING comment='Internal credit rating (AAA to D scale)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for credit risk assessment',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.DEFAULT_FLAG as DEFAULT_FLAG comment='Boolean flag indicating if customer is in default (90+ DPD)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.FULL_NAME as FULL_NAME comment='Customer name for credit reporting',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.ONBOARDING_DATE as ONBOARDING_DATE comment='Customer relationship start date for vintage analysis',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.PORTFOLIO_SEGMENT as PORTFOLIO_SEGMENT comment='Portfolio segment (RETAIL/CORPORATE/SME/SOVEREIGN)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.RATING_DATE as RATING_DATE comment='Date when credit rating was assigned/updated',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.RATING_METHODOLOGY as RATING_METHODOLOGY comment='Rating methodology used (FOUNDATION_IRB/ADVANCED_IRB)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.WATCH_LIST_FLAG as WATCH_LIST_FLAG comment='Boolean flag for customers on credit watch list',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CREDIT_RATING as CREDIT_RATING comment='Credit rating bucket for portfolio analysis',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.PORTFOLIO_SEGMENT as PORTFOLIO_SEGMENT comment='Portfolio segment for risk aggregation (RETAIL/CORPORATE/SME)',
		REPP_AGG_DT_IRB_RISK_TRENDS.PORTFOLIO_SEGMENT as PORTFOLIO_SEGMENT comment='Portfolio segment for trend analysis',
		REPP_AGG_DT_IRB_RISK_TRENDS.TREND_DATE as TREND_DATE comment='Date for time series analysis of risk parameters',
		REPP_AGG_DT_IRB_RWA_SUMMARY.CALCULATION_DATE as CALCULATION_DATE comment='Date of RWA calculation for regulatory reporting',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.CREDIT_RATING as CREDIT_RATING comment='Credit rating at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for historical tracking',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.DEFAULT_FLAG as DEFAULT_FLAG comment='Whether customer was in default at this point in time',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.EFFECTIVE_DATE as EFFECTIVE_DATE comment='Date when this rating became effective',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.RATING_DATE as RATING_DATE comment='Date when rating was calculated',
		REPP_AGG_DT_CUSTOMER_RATING_HISTORY.WATCH_LIST_FLAG as WATCH_LIST_FLAG comment='Whether customer was on watch list at this point in time'
	)
	with extension (CA='{"tables":[{"name":"REPP_AGG_DT_IRB_CUSTOMER_RATINGS","dimensions":[{"name":"CREDIT_RATING","sample_values":["AAA","CCC"]},{"name":"CUSTOMER_ID","sample_values":["CUST_00376","CUST_00406","CUST_00417"]},{"name":"DEFAULT_FLAG","sample_values":["FALSE","TRUE"]},{"name":"FULL_NAME","sample_values":["Emil Ellingsen","Peter Lindström","Ubaldo Fermi"]},{"name":"PORTFOLIO_SEGMENT","sample_values":["RETAIL"]},{"name":"RATING_METHODOLOGY","sample_values":["FOUNDATION_IRB"]},{"name":"WATCH_LIST_FLAG","sample_values":["FALSE","TRUE"]}],"facts":[{"name":"DAYS_PAST_DUE","sample_values":["120","0"]},{"name":"EAD_AMOUNT","sample_values":["11160.40","-34919.18","15204.16"]},{"name":"LGD_RATE","sample_values":["45.00"]},{"name":"PD_1_YEAR","sample_values":["0.10","15.00"]},{"name":"PD_LIFETIME","sample_values":["0.30","25.00"]},{"name":"RISK_WEIGHT","sample_values":["20.00","150.00"]},{"name":"SECURED_EXPOSURE_CHF","sample_values":["0.00","1484.84","-6362.20"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["11160.40","-34919.18","15204.16"]},{"name":"UNSECURED_EXPOSURE_CHF","sample_values":["4464.16","-6614.75","-346.48"]}],"time_dimensions":[{"name":"ONBOARDING_DATE","sample_values":["2023-07-25","2025-04-28","2025-08-23"]},{"name":"RATING_DATE","sample_values":["2025-10-08"]}]},{"name":"REPP_AGG_DT_IRB_PORTFOLIO_METRICS","dimensions":[{"name":"CREDIT_RATING","sample_values":["AAA","CCC"]},{"name":"PORTFOLIO_SEGMENT","sample_values":["RETAIL"]}],"facts":[{"name":"AVERAGE_EXPOSURE_CHF","sample_values":["1021.68","-7234.52"]},{"name":"CAPITAL_REQUIREMENT_CHF","sample_values":["27184.96","-51220.37"]},{"name":"COLLATERAL_COVERAGE_RATIO","sample_values":["60.00"]},{"name":"CONCENTRATION_RISK_SCORE","sample_values":["9","3"]},{"name":"CUSTOMER_COUNT","sample_values":["59","1663"]},{"name":"DEFAULT_COUNT","sample_values":["59","0"]},{"name":"DEFAULT_RATE","sample_values":["0.00","100.00"]},{"name":"EXPECTED_LOSS_CHF","sample_values":["-28811.46","764.58"]},{"name":"RISK_WEIGHTED_ASSETS_CHF","sample_values":["339811.97","-640254.62"]},{"name":"SECURED_EXPOSURE_CHF","sample_values":["1019436.01","-256101.85"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["1699059.87","-426836.41"]},{"name":"UNSECURED_EXPOSURE_CHF","sample_values":["-170734.56","679623.86"]},{"name":"VINTAGE_MONTHS","sample_values":["31.02","32.36"]},{"name":"WATCH_LIST_COUNT","sample_values":["3","0"]},{"name":"WATCH_LIST_RATE","sample_values":["0.00","5.08"]},{"name":"WEIGHTED_AVG_LGD","sample_values":["45.00"]},{"name":"WEIGHTED_AVG_PD","sample_values":["0.10","15.00"]}]},{"name":"REPP_AGG_DT_IRB_RISK_TRENDS","dimensions":[{"name":"PORTFOLIO_SEGMENT","sample_values":["RETAIL"]}],"facts":[{"name":"AVG_LGD_RATE","sample_values":["45.00"]},{"name":"AVG_PD_1_YEAR","sample_values":["0.61"]},{"name":"AVG_PD_LIFETIME","sample_values":["1.15"]},{"name":"AVG_RISK_WEIGHT","sample_values":["24.45"]},{"name":"BACKTESTING_ACCURACY","sample_values":["87.20"]},{"name":"CURED_DEFAULTS","sample_values":["0"]},{"name":"DEFAULT_RATE","sample_values":["3.43"]},{"name":"EXPECTED_LOSS_CHF","sample_values":["-28046.88"]},{"name":"MODEL_PERFORMANCE_SCORE","sample_values":["9"]},{"name":"NET_DEFAULT_CHANGE","sample_values":["59"]},{"name":"NEW_DEFAULTS","sample_values":["59"]},{"name":"RATING_MIGRATIONS_DOWN","sample_values":["0"]},{"name":"RATING_MIGRATIONS_UP","sample_values":["0"]},{"name":"STRESS_TEST_MULTIPLIER","sample_values":["1.00"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["1272223.46"]},{"name":"TOTAL_RWA_CHF","sample_values":["-300442.64"]}],"time_dimensions":[{"name":"TREND_DATE","sample_values":["2025-10-08"]}]},{"name":"REPP_AGG_DT_IRB_RWA_SUMMARY","facts":[{"name":"AVERAGE_RISK_WEIGHT","sample_values":["-23.62"]},{"name":"CORPORATE_EXPOSURE_CHF","sample_values":["0.00"]},{"name":"CORPORATE_RWA_CHF","sample_values":["0.00"]},{"name":"DEFAULT_CUSTOMERS","sample_values":["59"]},{"name":"LEVERAGE_RATIO","sample_values":["5.80"]},{"name":"PORTFOLIO_DEFAULT_RATE","sample_values":["3.43"]},{"name":"RETAIL_EXPOSURE_CHF","sample_values":["1272223.46"]},{"name":"RETAIL_RWA_CHF","sample_values":["-300442.65"]},{"name":"SME_EXPOSURE_CHF","sample_values":["0.00"]},{"name":"SME_RWA_CHF","sample_values":["0.00"]},{"name":"TIER1_CAPITAL_RATIO","sample_values":["15.20"]},{"name":"TOTAL_CAPITAL_RATIO","sample_values":["18.50"]},{"name":"TOTAL_CAPITAL_REQUIREMENT_CHF","sample_values":["-24035.41"]},{"name":"TOTAL_CUSTOMERS","sample_values":["1722"]},{"name":"TOTAL_EXPECTED_LOSS_CHF","sample_values":["-28046.88"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["1272223.46"]},{"name":"TOTAL_RWA_CHF","sample_values":["-300442.65"]}],"time_dimensions":[{"name":"CALCULATION_DATE","sample_values":["2025-10-08"]}]},{"name":"REPP_AGG_DT_CUSTOMER_RATING_HISTORY","dimensions":[{"name":"CREDIT_RATING","sample_values":["AAA","CCC"]},{"name":"CUSTOMER_ID","sample_values":["CUST_00003","CUST_00002","CUST_00062"]},{"name":"DEFAULT_FLAG","sample_values":["FALSE","TRUE"]},{"name":"WATCH_LIST_FLAG","sample_values":["FALSE","TRUE"]}],"facts":[{"name":"DAYS_PAST_DUE","sample_values":["120","0"]},{"name":"LGD_RATE","sample_values":["45.00"]},{"name":"PD_1_YEAR","sample_values":["0.10","15.00"]},{"name":"PD_LIFETIME","sample_values":["0.30","25.00"]},{"name":"RISK_WEIGHT","sample_values":["20.00","150.00"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["12239.98","-13636.38","1684.34"]}],"time_dimensions":[{"name":"EFFECTIVE_DATE","sample_values":["2025-10-08"]},{"name":"RATING_DATE","sample_values":["2025-10-08"]}]}]}');

create or replace semantic view AAA_DEV_SYNTHETIC_BANK.REP_AGG_001.EQUITY_TRADING_REPORTING_ANALYTICS
	tables (
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE,
		REPP_AGG_DT_EQUITY_POSITIONS,
		REPP_AGG_DT_EQUITY_SUMMARY,
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES
	)
	facts (
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.AVG_FX_RATE as AVG_FX_RATE comment='Average FX rate used for currency conversion',
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.MAX_FX_RATE as MAX_FX_RATE comment='Maximum FX rate observed',
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.MIN_FX_RATE as MIN_FX_RATE comment='Minimum FX rate observed',
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.TOTAL_CHF_VOLUME as TOTAL_CHF_VOLUME comment='Total trading volume converted to CHF',
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.TOTAL_ORIGINAL_VOLUME as TOTAL_ORIGINAL_VOLUME comment='Total trading volume in original currency',
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.TRADE_COUNT as TRADE_COUNT comment='Number of equity trades in this currency',
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.UNIQUE_CUSTOMERS as UNIQUE_CUSTOMERS comment='Number of customers trading in this currency',
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.UNIQUE_SYMBOLS as UNIQUE_SYMBOLS comment='Number of different securities traded in this currency',
		REPP_AGG_DT_EQUITY_POSITIONS.AVG_PRICE as AVG_PRICE comment='Average trading price',
		REPP_AGG_DT_EQUITY_POSITIONS.MAX_PRICE as MAX_PRICE comment='Highest trading price observed',
		REPP_AGG_DT_EQUITY_POSITIONS.MIN_PRICE as MIN_PRICE comment='Lowest trading price observed',
		REPP_AGG_DT_EQUITY_POSITIONS.NET_POSITION as NET_POSITION comment='Net position across all customers (positive = long, negative = short)',
		REPP_AGG_DT_EQUITY_POSITIONS.TOTAL_BOUGHT as TOTAL_BOUGHT comment='Total quantity purchased',
		REPP_AGG_DT_EQUITY_POSITIONS.TOTAL_CHF_VOLUME as TOTAL_CHF_VOLUME comment='Total trading volume in CHF',
		REPP_AGG_DT_EQUITY_POSITIONS.TOTAL_SOLD as TOTAL_SOLD comment='Total quantity sold',
		REPP_AGG_DT_EQUITY_POSITIONS.TOTAL_TRADES as TOTAL_TRADES comment='Total number of trades in this security',
		REPP_AGG_DT_EQUITY_POSITIONS.UNIQUE_CUSTOMERS as UNIQUE_CUSTOMERS comment='Number of customers holding this security',
		REPP_AGG_DT_EQUITY_SUMMARY.AVG_TRADE_SIZE_CHF as AVG_TRADE_SIZE_CHF comment='Average trade size for customer profiling',
		REPP_AGG_DT_EQUITY_SUMMARY.BUY_TRADES as BUY_TRADES comment='Number of buy transactions',
		REPP_AGG_DT_EQUITY_SUMMARY.NET_CHF_POSITION as NET_CHF_POSITION comment='Net position (positive = net buyer, negative = net seller)',
		REPP_AGG_DT_EQUITY_SUMMARY.SELL_TRADES as SELL_TRADES comment='Number of sell transactions',
		REPP_AGG_DT_EQUITY_SUMMARY.TOTAL_CHF_VOLUME as TOTAL_CHF_VOLUME comment='Total trading volume in CHF',
		REPP_AGG_DT_EQUITY_SUMMARY.TOTAL_COMMISSION_CHF as TOTAL_COMMISSION_CHF comment='Total commission fees paid',
		REPP_AGG_DT_EQUITY_SUMMARY.TOTAL_TRADES as TOTAL_TRADES comment='Total number of equity transactions',
		REPP_AGG_DT_EQUITY_SUMMARY.UNIQUE_SYMBOLS as UNIQUE_SYMBOLS comment='Number of different securities traded',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.CHF_VALUE as CHF_VALUE comment='Trade value in CHF for threshold monitoring',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.PRICE as PRICE comment='Execution price per unit',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.QUANTITY as QUANTITY comment='Number of shares/units traded'
	)
	dimensions (
		REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE.CURRENCY as CURRENCY comment='Trading currency for FX exposure analysis',
		REPP_AGG_DT_EQUITY_POSITIONS.ISIN as ISIN comment='International Securities Identification Number',
		REPP_AGG_DT_EQUITY_POSITIONS.LAST_TRADE_DATE as LAST_TRADE_DATE comment='Most recent trading date for this security',
		REPP_AGG_DT_EQUITY_POSITIONS.SYMBOL as SYMBOL comment='Security symbol for position tracking',
		REPP_AGG_DT_EQUITY_SUMMARY.ACCOUNT_ID as ACCOUNT_ID comment='Account identifier for position tracking',
		REPP_AGG_DT_EQUITY_SUMMARY.BASE_CURRENCY as BASE_CURRENCY comment='Account base currency for reporting',
		REPP_AGG_DT_EQUITY_SUMMARY.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for portfolio analysis',
		REPP_AGG_DT_EQUITY_SUMMARY.FIRST_TRADE_DATE as FIRST_TRADE_DATE comment='First trading activity date',
		REPP_AGG_DT_EQUITY_SUMMARY.LAST_TRADE_DATE as LAST_TRADE_DATE comment='Most recent trading activity date',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.ACCOUNT_ID as ACCOUNT_ID comment='Account identifier for position tracking',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for large trade monitoring',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.MARKET as MARKET comment='Market/exchange where trade was executed',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.SIDE as SIDE comment='Trade direction (1=Buy, 2=Sell)',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.SYMBOL as SYMBOL comment='Security symbol for concentration risk analysis',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.TRADE_DATE as TRADE_DATE comment='Trade execution date for compliance tracking',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.TRADE_ID as TRADE_ID comment='Unique trade identifier for audit trail',
		REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES.VENUE as VENUE comment='Trading venue for best execution analysis'
	)
	with extension (CA='{"tables":[{"name":"REPP_AGG_DT_EQUITY_CURRENCY_EXPOSURE","dimensions":[{"name":"CURRENCY","sample_values":["USD","GBP","EUR"]}],"facts":[{"name":"AVG_FX_RATE","sample_values":["1.000000"]},{"name":"MAX_FX_RATE","sample_values":["1.000000"]},{"name":"MIN_FX_RATE","sample_values":["1.000000"]},{"name":"TOTAL_CHF_VOLUME","sample_values":["2035148699.29","8365093595.80","25174876347.54"]},{"name":"TOTAL_ORIGINAL_VOLUME","sample_values":["2035148699.29","8365093595.80","25174876347.54"]},{"name":"TRADE_COUNT","sample_values":["94691","47419","47614"]},{"name":"UNIQUE_CUSTOMERS","sample_values":["357"]},{"name":"UNIQUE_SYMBOLS","sample_values":["13","10"]}]},{"name":"REPP_AGG_DT_EQUITY_POSITIONS","dimensions":[{"name":"ISIN","sample_values":["JP1043904676","DE8745224774","GB7245599669"]},{"name":"SYMBOL","sample_values":["BT","UHR","VOD"]}],"facts":[{"name":"AVG_PRICE","sample_values":["2326.000000","118.150000","1183.120000"]},{"name":"MAX_PRICE","sample_values":["779.530000","237.170000","288.350000"]},{"name":"MIN_PRICE","sample_values":["2326.000000","118.150000","665.660000"]},{"name":"NET_POSITION","sample_values":["-641.0052","76.2108","141.7614"]},{"name":"TOTAL_BOUGHT","sample_values":["66.0135","875.1826","773.0249"]},{"name":"TOTAL_CHF_VOLUME","sample_values":["9210.53","2476757.67","73718.45"]},{"name":"TOTAL_SOLD","sample_values":["344.1674","22.2980","202.2941"]},{"name":"TOTAL_TRADES","sample_values":["1"]},{"name":"UNIQUE_CUSTOMERS","sample_values":["1"]}],"time_dimensions":[{"name":"LAST_TRADE_DATE","sample_values":["2024-05-16T09:09:55.593+0000","2025-07-22T13:41:15.906+0000","2025-06-11T13:45:51.916+0000"]}]},{"name":"REPP_AGG_DT_EQUITY_SUMMARY","dimensions":[{"name":"ACCOUNT_ID","sample_values":["CUST_00540_INVESTMENT_01","CUST_00993_INVESTMENT_01","CUST_00388_INVESTMENT_02"]},{"name":"BASE_CURRENCY","sample_values":["USD","CAD","EUR"]},{"name":"CUSTOMER_ID","sample_values":["CUST_00678","CUST_00239","CUST_00330"]}],"facts":[{"name":"AVG_TRADE_SIZE_CHF","sample_values":["396937.18","429564.62","375571.36"]},{"name":"BUY_TRADES","sample_values":["171","371","392"]},{"name":"NET_CHF_POSITION","sample_values":["-4552622.98","10113997.40","16446452.10"]},{"name":"SELL_TRADES","sample_values":["179","386","349"]},{"name":"TOTAL_CHF_VOLUME","sample_values":["333794525.46","312785258.32","340452052.71"]},{"name":"TOTAL_COMMISSION_CHF","sample_values":["1979370.52","1437498.20","1781677.26"]},{"name":"TOTAL_TRADES","sample_values":["770","1166","1080"]},{"name":"UNIQUE_SYMBOLS","sample_values":["52","53"]}],"time_dimensions":[{"name":"FIRST_TRADE_DATE","sample_values":["2024-03-21T11:08:18.254+0000","2024-03-18T09:21:41.742+0000","2024-03-18T09:36:25.051+0000"]},{"name":"LAST_TRADE_DATE","sample_values":["2025-10-07T13:03:53.217+0000","2025-10-07T14:48:33.820+0000","2025-10-07T14:09:48.566+0000"]}]},{"name":"REPP_AGG_DT_HIGH_VALUE_EQUITY_TRADES","dimensions":[{"name":"ACCOUNT_ID","sample_values":["CUST_00236_INVESTMENT_02","CUST_00282_INVESTMENT_02","CUST_00821_INVESTMENT_01"]},{"name":"CUSTOMER_ID","sample_values":["CUST_00433","CUST_00247","CUST_00193"]},{"name":"MARKET","sample_values":["TSE","LSE","NYSE"]},{"name":"SIDE","sample_values":["1","2"]},{"name":"SYMBOL","sample_values":["HSBA","6861","7203"]},{"name":"TRADE_ID","sample_values":["TRD_8D17370D4A90","TRD_36409D93A576","TRD_E6D51F9981FC"]},{"name":"VENUE","sample_values":["CROSS","CHI-X","SIP"]}],"facts":[{"name":"CHF_VALUE","sample_values":["1583897.99","1590727.70","1596866.39"]},{"name":"PRICE","sample_values":["4825.000000","1767.310000","2373.000000"]},{"name":"QUANTITY","sample_values":["705.3454","342.8277","607.1505"]}],"time_dimensions":[{"name":"TRADE_DATE","sample_values":["2025-03-06T11:27:47.819+0000","2024-03-26T15:29:39.422+0000","2025-04-03T12:27:32.073+0000"]}]}]}');

CREATE OR REPLACE SEMANTIC VIEW FRTB_MARKET_RISK_REPORTING
	tables (
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES,
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS,
		REPP_AGG_DT_FRTB_RISK_POSITIONS,
		REPP_AGG_DT_FRTB_SENSITIVITIES,
		REPP_AGG_DT_IRB_RWA_SUMMARY,
		REPP_AGG_DT_IRB_RISK_TRENDS,
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS,
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS,
		REPP_AGG_DT_CUSTOMER_SUMMARY
	)
	facts (
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.CURVATURE_CAPITAL_CHARGE_CHF as CURVATURE_CAPITAL_CHARGE_CHF comment='Curvature capital charge',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.DELTA_CAPITAL_CHARGE_CHF as DELTA_CAPITAL_CHARGE_CHF comment='Delta capital charge',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.GROSS_DELTA_CHF as GROSS_DELTA_CHF comment='Gross delta sensitivity',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.NET_DELTA_CHF as NET_DELTA_CHF comment='Net delta sensitivity',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.NMRF_ADD_ON_CHF as NMRF_ADD_ON_CHF comment='NMRF capital add-on',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.RISK_WEIGHT as RISK_WEIGHT comment='FRTB risk weight (%)',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.TOTAL_CAPITAL_CHARGE_CHF as TOTAL_CAPITAL_CHARGE_CHF comment='Total capital charge for bucket',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.VEGA_CAPITAL_CHARGE_CHF as VEGA_CAPITAL_CHARGE_CHF comment='Vega capital charge',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.CAPITAL_ADD_ON_CHF as CAPITAL_ADD_ON_CHF comment='Additional capital requirement',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.DELTA_CHF as DELTA_CHF comment='Delta sensitivity',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.LIQUIDITY_SCORE as LIQUIDITY_SCORE comment='Liquidity score (1-10)',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.POSITION_VALUE_CHF as POSITION_VALUE_CHF comment='Position value in CHF',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.DELTA_CHF as DELTA_CHF comment='Delta sensitivity in CHF',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.LIQUIDITY_SCORE as LIQUIDITY_SCORE comment='Liquidity score (1-10)',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.POSITION_VALUE_CHF as POSITION_VALUE_CHF comment='Position value in CHF',
		REPP_AGG_DT_FRTB_SENSITIVITIES.GROSS_DELTA_CHF as GROSS_DELTA_CHF comment='Gross delta (sum of absolute values)',
		REPP_AGG_DT_FRTB_SENSITIVITIES.GROSS_VEGA_CHF as GROSS_VEGA_CHF comment='Gross vega (sum of absolute values)',
		REPP_AGG_DT_FRTB_SENSITIVITIES.LARGEST_POSITION_CHF as LARGEST_POSITION_CHF comment='Largest single position value',
		REPP_AGG_DT_FRTB_SENSITIVITIES.LONG_POSITIONS as LONG_POSITIONS comment='Number of long positions',
		REPP_AGG_DT_FRTB_SENSITIVITIES.NET_DELTA_CHF as NET_DELTA_CHF comment='Net delta (long - short)',
		REPP_AGG_DT_FRTB_SENSITIVITIES.NET_VEGA_CHF as NET_VEGA_CHF comment='Net vega (long - short)',
		REPP_AGG_DT_FRTB_SENSITIVITIES.NMRF_POSITIONS as NMRF_POSITIONS comment='Number of NMRF positions',
		REPP_AGG_DT_FRTB_SENSITIVITIES.SHORT_POSITIONS as SHORT_POSITIONS comment='Number of short positions',
		REPP_AGG_DT_FRTB_SENSITIVITIES.TOTAL_POSITIONS as TOTAL_POSITIONS comment='Number of positions',
		REPP_AGG_DT_IRB_RWA_SUMMARY.AVERAGE_RISK_WEIGHT as AVERAGE_RISK_WEIGHT comment='Portfolio-weighted average risk weight (%)',
		REPP_AGG_DT_IRB_RWA_SUMMARY.CORPORATE_EXPOSURE_CHF as CORPORATE_EXPOSURE_CHF comment='Total corporate portfolio exposure in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.CORPORATE_RWA_CHF as CORPORATE_RWA_CHF comment='Corporate portfolio Risk Weighted Assets in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.DEFAULT_CUSTOMERS as DEFAULT_CUSTOMERS comment='Total number of customers in default across all portfolios',
		REPP_AGG_DT_IRB_RWA_SUMMARY.LEVERAGE_RATIO as LEVERAGE_RATIO comment='Simulated leverage ratio (%) - regulatory minimum 3%',
		REPP_AGG_DT_IRB_RWA_SUMMARY.PORTFOLIO_DEFAULT_RATE as PORTFOLIO_DEFAULT_RATE comment='Overall portfolio default rate (%)',
		REPP_AGG_DT_IRB_RWA_SUMMARY.RETAIL_EXPOSURE_CHF as RETAIL_EXPOSURE_CHF comment='Total retail portfolio exposure in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.RETAIL_RWA_CHF as RETAIL_RWA_CHF comment='Retail portfolio Risk Weighted Assets in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.SME_EXPOSURE_CHF as SME_EXPOSURE_CHF comment='Total SME portfolio exposure in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.SME_RWA_CHF as SME_RWA_CHF comment='SME portfolio Risk Weighted Assets in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TIER1_CAPITAL_RATIO as TIER1_CAPITAL_RATIO comment='Simulated Tier 1 capital ratio (%) - regulatory minimum 6%',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_CAPITAL_RATIO as TOTAL_CAPITAL_RATIO comment='Simulated total capital ratio (%) - regulatory minimum 8%',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_CAPITAL_REQUIREMENT_CHF as TOTAL_CAPITAL_REQUIREMENT_CHF comment='Total minimum capital requirement (8% of RWA) in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_CUSTOMERS as TOTAL_CUSTOMERS comment='Total number of customers across all portfolios',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_EXPECTED_LOSS_CHF as TOTAL_EXPECTED_LOSS_CHF comment='Total Expected Loss across all portfolios in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total credit exposure across all portfolios in CHF',
		REPP_AGG_DT_IRB_RWA_SUMMARY.TOTAL_RWA_CHF as TOTAL_RWA_CHF comment='Total Risk Weighted Assets under IRB approach in CHF',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_LGD_RATE as AVG_LGD_RATE comment='Average LGD rate across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_PD_1_YEAR as AVG_PD_1_YEAR comment='Average 1-year PD across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_PD_LIFETIME as AVG_PD_LIFETIME comment='Average lifetime PD across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.AVG_RISK_WEIGHT as AVG_RISK_WEIGHT comment='Average risk weight across portfolio on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.BACKTESTING_ACCURACY as BACKTESTING_ACCURACY comment='Model backtesting accuracy (%) against actual defaults',
		REPP_AGG_DT_IRB_RISK_TRENDS.CURED_DEFAULTS as CURED_DEFAULTS comment='Number of defaults that cured on this date',
		REPP_AGG_DT_IRB_RISK_TRENDS.DEFAULT_RATE as DEFAULT_RATE comment='Observed default rate on this date (%)',
		REPP_AGG_DT_IRB_RISK_TRENDS.EXPECTED_LOSS_CHF as EXPECTED_LOSS_CHF comment='Total Expected Loss on this date in CHF',
		REPP_AGG_DT_IRB_RISK_TRENDS.MODEL_PERFORMANCE_SCORE as MODEL_PERFORMANCE_SCORE comment='PD model performance score (1-10, 10=best)',
		REPP_AGG_DT_IRB_RISK_TRENDS.NET_DEFAULT_CHANGE as NET_DEFAULT_CHANGE comment='Net change in default count (new - cured)',
		REPP_AGG_DT_IRB_RISK_TRENDS.NEW_DEFAULTS as NEW_DEFAULTS comment='Number of new defaults identified on this date',
		REPP_AGG_DT_IRB_RISK_TRENDS.RATING_MIGRATIONS_DOWN as RATING_MIGRATIONS_DOWN comment='Number of customers with rating downgrades',
		REPP_AGG_DT_IRB_RISK_TRENDS.RATING_MIGRATIONS_UP as RATING_MIGRATIONS_UP comment='Number of customers with rating upgrades',
		REPP_AGG_DT_IRB_RISK_TRENDS.STRESS_TEST_MULTIPLIER as STRESS_TEST_MULTIPLIER comment='Stress testing multiplier applied to base PD',
		REPP_AGG_DT_IRB_RISK_TRENDS.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total portfolio exposure on this date in CHF',
		REPP_AGG_DT_IRB_RISK_TRENDS.TOTAL_RWA_CHF as TOTAL_RWA_CHF comment='Total Risk Weighted Assets on this date in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.AVERAGE_EXPOSURE_CHF as AVERAGE_EXPOSURE_CHF comment='Average exposure per customer in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CAPITAL_REQUIREMENT_CHF as CAPITAL_REQUIREMENT_CHF comment='Minimum capital requirement (8% of RWA) in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.COLLATERAL_COVERAGE_RATIO as COLLATERAL_COVERAGE_RATIO comment='Secured exposure as % of total exposure',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CONCENTRATION_RISK_SCORE as CONCENTRATION_RISK_SCORE comment='Portfolio concentration risk score (1-10 scale)',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CUSTOMER_COUNT as CUSTOMER_COUNT comment='Number of customers in this rating/segment combination',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.DEFAULT_COUNT as DEFAULT_COUNT comment='Number of customers currently in default',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.DEFAULT_RATE as DEFAULT_RATE comment='Default rate (%) within this portfolio segment',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.EXPECTED_LOSS_CHF as EXPECTED_LOSS_CHF comment='Expected Loss = EAD × PD × LGD in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.RISK_WEIGHTED_ASSETS_CHF as RISK_WEIGHTED_ASSETS_CHF comment='Risk Weighted Assets under IRB approach in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.SECURED_EXPOSURE_CHF as SECURED_EXPOSURE_CHF comment='Total secured exposure with collateral in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total credit exposure in CHF for this portfolio segment',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.UNSECURED_EXPOSURE_CHF as UNSECURED_EXPOSURE_CHF comment='Total unsecured exposure without collateral in CHF',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.VINTAGE_MONTHS as VINTAGE_MONTHS comment='Average customer vintage in months for maturity analysis',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WATCH_LIST_COUNT as WATCH_LIST_COUNT comment='Number of customers on credit watch list',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WATCH_LIST_RATE as WATCH_LIST_RATE comment='Watch list rate (%) within this portfolio segment',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WEIGHTED_AVG_LGD as WEIGHTED_AVG_LGD comment='Exposure-weighted average Loss Given Default (%)',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.WEIGHTED_AVG_PD as WEIGHTED_AVG_PD comment='Exposure-weighted average Probability of Default (%)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.DAYS_PAST_DUE as DAYS_PAST_DUE comment='Current days past due for default identification',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.EAD_AMOUNT as EAD_AMOUNT comment='Exposure at Default amount in CHF - total exposure',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.LGD_RATE as LGD_RATE comment='Loss Given Default rate (%) - expected loss severity',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.PD_1_YEAR as PD_1_YEAR comment='Probability of Default over 1 year horizon (%)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.PD_LIFETIME as PD_LIFETIME comment='Lifetime Probability of Default (%)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.RISK_WEIGHT as RISK_WEIGHT comment='Risk weight (%) for RWA calculation under IRB approach',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.SECURED_EXPOSURE_CHF as SECURED_EXPOSURE_CHF comment='Secured portion of exposure with collateral',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.TOTAL_EXPOSURE_CHF as TOTAL_EXPOSURE_CHF comment='Total credit exposure across all facilities in CHF',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.UNSECURED_EXPOSURE_CHF as UNSECURED_EXPOSURE_CHF comment='Unsecured exposure without collateral',
		REPP_AGG_DT_CUSTOMER_SUMMARY.ANOMALOUS_TRANSACTIONS as ANOMALOUS_TRANSACTIONS comment='Count of transactions with suspicious patterns',
		REPP_AGG_DT_CUSTOMER_SUMMARY.AVG_TRANSACTION_AMOUNT as AVG_TRANSACTION_AMOUNT comment='Average transaction size for customer profiling',
		REPP_AGG_DT_CUSTOMER_SUMMARY.CURRENCY_COUNT as CURRENCY_COUNT comment='Number of different currencies in customer portfolio',
		REPP_AGG_DT_CUSTOMER_SUMMARY.MAX_TRANSACTION_AMOUNT as MAX_TRANSACTION_AMOUNT comment='Largest single transaction for risk assessment',
		REPP_AGG_DT_CUSTOMER_SUMMARY.TOTAL_ACCOUNTS as TOTAL_ACCOUNTS comment='Number of accounts held by customer',
		REPP_AGG_DT_CUSTOMER_SUMMARY.TOTAL_BASE_AMOUNT as TOTAL_BASE_AMOUNT comment='Total transaction volume in base currency',
		REPP_AGG_DT_CUSTOMER_SUMMARY.TOTAL_TRANSACTIONS as TOTAL_TRANSACTIONS comment='Total number of transactions across all accounts'
	)
	dimensions (
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.LAST_UPDATED as LAST_UPDATED comment='Timestamp when calculated',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.RISK_BUCKET as RISK_BUCKET comment='Risk bucket within risk class',
		REPP_AGG_DT_FRTB_CAPITAL_CHARGES.RISK_CLASS as RISK_CLASS comment='EQUITY, FX, INTEREST_RATE, COMMODITY, CREDIT_SPREAD',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.INSTRUMENT_NAME as INSTRUMENT_NAME comment='Instrument name/identifier',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.LAST_UPDATED as LAST_UPDATED comment='Timestamp when calculated',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.NMRF_REASON as NMRF_REASON comment='Reason for NMRF classification',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.RISK_BUCKET as RISK_BUCKET comment='Risk bucket within risk class',
		REPP_AGG_DT_FRTB_NMRF_ANALYSIS.RISK_CLASS as RISK_CLASS comment='EQUITY, FX, INTEREST_RATE, COMMODITY, CREDIT_SPREAD',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.ACCOUNT_ID as ACCOUNT_ID comment='Investment account',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.CURRENCY as CURRENCY comment='Trading currency',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.INSTRUMENT_NAME as INSTRUMENT_NAME comment='Instrument name/identifier',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.INSTRUMENT_TYPE as INSTRUMENT_TYPE comment='Type of instrument',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.IS_NMRF as IS_NMRF comment='Non-Modellable Risk Factor flag',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.LAST_UPDATED as LAST_UPDATED comment='Timestamp when calculated',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.RISK_BUCKET as RISK_BUCKET comment='Risk bucket within risk class',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.RISK_CLASS as RISK_CLASS comment='EQUITY, FX, INTEREST_RATE, COMMODITY, CREDIT_SPREAD',
		REPP_AGG_DT_FRTB_RISK_POSITIONS.VEGA_CHF as VEGA_CHF comment='Vega sensitivity in CHF (if applicable)',
		REPP_AGG_DT_FRTB_SENSITIVITIES.LAST_UPDATED as LAST_UPDATED comment='Timestamp when calculated',
		REPP_AGG_DT_FRTB_SENSITIVITIES.RISK_BUCKET as RISK_BUCKET comment='Risk bucket within risk class',
		REPP_AGG_DT_FRTB_SENSITIVITIES.RISK_CLASS as RISK_CLASS comment='EQUITY, FX, INTEREST_RATE, COMMODITY, CREDIT_SPREAD',
		REPP_AGG_DT_IRB_RWA_SUMMARY.CALCULATION_DATE as CALCULATION_DATE comment='Date of RWA calculation for regulatory reporting',
		REPP_AGG_DT_IRB_RISK_TRENDS.PORTFOLIO_SEGMENT as PORTFOLIO_SEGMENT comment='Portfolio segment for trend analysis',
		REPP_AGG_DT_IRB_RISK_TRENDS.TREND_DATE as TREND_DATE comment='Date for time series analysis of risk parameters',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.CREDIT_RATING as CREDIT_RATING comment='Credit rating bucket for portfolio analysis',
		REPP_AGG_DT_IRB_PORTFOLIO_METRICS.PORTFOLIO_SEGMENT as PORTFOLIO_SEGMENT comment='Portfolio segment for risk aggregation (RETAIL/CORPORATE/SME)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.CREDIT_RATING as CREDIT_RATING comment='Internal credit rating (AAA to D scale)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.CUSTOMER_ID as CUSTOMER_ID comment='Customer identifier for credit risk assessment',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.DEFAULT_FLAG as DEFAULT_FLAG comment='Boolean flag indicating if customer is in default (90+ DPD)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.FULL_NAME as FULL_NAME comment='Customer name for credit reporting',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.ONBOARDING_DATE as ONBOARDING_DATE comment='Customer relationship start date for vintage analysis',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.PORTFOLIO_SEGMENT as PORTFOLIO_SEGMENT comment='Portfolio segment (RETAIL/CORPORATE/SME/SOVEREIGN)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.RATING_DATE as RATING_DATE comment='Date when credit rating was assigned/updated',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.RATING_METHODOLOGY as RATING_METHODOLOGY comment='Rating methodology used (FOUNDATION_IRB/ADVANCED_IRB)',
		REPP_AGG_DT_IRB_CUSTOMER_RATINGS.WATCH_LIST_FLAG as WATCH_LIST_FLAG comment='Boolean flag for customers on credit watch list',
		REPP_AGG_DT_CUSTOMER_SUMMARY.ACCOUNT_CURRENCIES as ACCOUNT_CURRENCIES comment='Comma-separated list of all currencies used by customer',
		REPP_AGG_DT_CUSTOMER_SUMMARY.CUSTOMER_ID as CUSTOMER_ID comment='Unique customer identifier for relationship management (CUST_XXXXX format)',
		REPP_AGG_DT_CUSTOMER_SUMMARY.FULL_NAME as FULL_NAME comment='Customer full name (First + Last) for reporting and compliance',
		REPP_AGG_DT_CUSTOMER_SUMMARY.HAS_ANOMALY as HAS_ANOMALY comment='Flag indicating if customer has anomalous behavior patterns',
		REPP_AGG_DT_CUSTOMER_SUMMARY.ONBOARDING_DATE as ONBOARDING_DATE comment='Date when customer relationship was established'
	)
	with extension (CA='{"tables":[{"name":"REPP_AGG_DT_FRTB_CAPITAL_CHARGES","dimensions":[{"name":"RISK_BUCKET","sample_values":["EQUITY_LARGE_CAP","COMM_ENERGY","COMM_AGRI"]},{"name":"RISK_CLASS","sample_values":["COMMODITY","EQUITY","CREDIT_SPREAD"]}],"facts":[{"name":"CURVATURE_CAPITAL_CHARGE_CHF","sample_values":["1264100","3968925","5991821361.55"]},{"name":"DELTA_CAPITAL_CHARGE_CHF","sample_values":["7584600","27782475","3043.5"]},{"name":"GROSS_DELTA_CHF","sample_values":["19024691","79378500","119836427231.07"]},{"name":"NET_DELTA_CHF","sample_values":["-6624000","4571500","198629230.51"]},{"name":"NMRF_ADD_ON_CHF","sample_values":["0","25362.49","39689250"]},{"name":"RISK_WEIGHT","sample_values":["30.0","25.0","1.5"]},{"name":"TOTAL_CAPITAL_CHARGE_CHF","sample_values":["955125","35950928169.32","8848700"]},{"name":"VEGA_CAPITAL_CHARGE_CHF","sample_values":["0.00"]}],"time_dimensions":[{"name":"LAST_UPDATED","sample_values":["2025-10-07T17:55:13.935+0000"]}]},{"name":"REPP_AGG_DT_FRTB_NMRF_ANALYSIS","dimensions":[{"name":"CUSTOMER_ID","sample_values":["CUST_00709","CUST_00750","CUST_00494"]},{"name":"INSTRUMENT_NAME","sample_values":["Wheat","Soybeans","Credit Suisse Group AG"]},{"name":"NMRF_REASON","sample_values":["ILLIQUID","OTHER"]},{"name":"RISK_BUCKET","sample_values":["IR_CORPORATE","COMM_AGRI","CS_HY"]},{"name":"RISK_CLASS","sample_values":["COMMODITY","CREDIT_SPREAD","INTEREST_RATE"]}],"facts":[{"name":"CAPITAL_ADD_ON_CHF","sample_values":["167812.5","4481250","3712500"]},{"name":"DELTA_CHF","sample_values":["69.63","3750000","-500000"]},{"name":"LIQUIDITY_SCORE","sample_values":["4","5"]},{"name":"POSITION_VALUE_CHF","sample_values":["276500","179200","7425000"]}],"time_dimensions":[{"name":"LAST_UPDATED","sample_values":["2025-10-07T17:49:35.967+0000"]}]},{"name":"REPP_AGG_DT_FRTB_RISK_POSITIONS","dimensions":[{"name":"ACCOUNT_ID","sample_values":["CUST_00920_INVESTMENT_02","CUST_00503_INVESTMENT_01","CUST_00110_INVESTMENT_01"]},{"name":"CURRENCY","sample_values":["USD","CHF","EUR"]},{"name":"CUSTOMER_ID","sample_values":["CUST_00691","CUST_00997","CUST_00079"]},{"name":"INSTRUMENT_NAME","sample_values":["TSLA","ABB","V"]},{"name":"INSTRUMENT_TYPE","sample_values":["ENERGY","EQUITY","AGRICULTURAL"]},{"name":"IS_NMRF","sample_values":["FALSE","TRUE"]},{"name":"RISK_BUCKET","sample_values":["COMM_PRECIOUS","EQUITY_LARGE_CAP","COMM_AGRI"]},{"name":"RISK_CLASS","sample_values":["COMMODITY","EQUITY","CREDIT_SPREAD"]},{"name":"VEGA_CHF"}],"facts":[{"name":"DELTA_CHF","sample_values":["123714.3","123011.75","123718.96"]},{"name":"LIQUIDITY_SCORE","sample_values":["4","6","8"]},{"name":"POSITION_VALUE_CHF","sample_values":["123714.3","123011.75","123718.96"]}],"time_dimensions":[{"name":"LAST_UPDATED","sample_values":["2025-10-07T17:49:35.967+0000"]}]},{"name":"REPP_AGG_DT_FRTB_SENSITIVITIES","dimensions":[{"name":"RISK_BUCKET","sample_values":["COMM_PRECIOUS","COMM_ENERGY","COMM_AGRI"]},{"name":"RISK_CLASS","sample_values":["COMMODITY","CREDIT_SPREAD","EQUITY"]}],"facts":[{"name":"GROSS_DELTA_CHF","sample_values":["79378500","19024691","119836427231.07"]},{"name":"GROSS_VEGA_CHF","sample_values":["0.00000"]},{"name":"LARGEST_POSITION_CHF","sample_values":["13567580.4","14548000","8962500"]},{"name":"LONG_POSITIONS","sample_values":["41","142743","39"]},{"name":"NET_DELTA_CHF","sample_values":["948129","-6624000","4571500"]},{"name":"NET_VEGA_CHF","sample_values":["0.00000"]},{"name":"NMRF_POSITIONS","sample_values":["76","20","0"]},{"name":"SHORT_POSITIONS","sample_values":["32","37","35"]},{"name":"TOTAL_POSITIONS","sample_values":["76","70","74"]}],"time_dimensions":[{"name":"LAST_UPDATED","sample_values":["2025-10-07T17:55:13.935+0000"]}]},{"name":"REPP_AGG_DT_IRB_RWA_SUMMARY","facts":[{"name":"AVERAGE_RISK_WEIGHT","sample_values":["-23.615555792376"]},{"name":"CORPORATE_EXPOSURE_CHF","sample_values":["0.00"]},{"name":"CORPORATE_RWA_CHF","sample_values":["0.00000000"]},{"name":"DEFAULT_CUSTOMERS","sample_values":["59"]},{"name":"LEVERAGE_RATIO","sample_values":["5.8"]},{"name":"PORTFOLIO_DEFAULT_RATE","sample_values":["3.426249"]},{"name":"RETAIL_EXPOSURE_CHF","sample_values":["1272223.46"]},{"name":"RETAIL_RWA_CHF","sample_values":["-300442.64100000"]},{"name":"SME_EXPOSURE_CHF","sample_values":["0.00"]},{"name":"SME_RWA_CHF","sample_values":["0.00000000"]},{"name":"TIER1_CAPITAL_RATIO","sample_values":["15.2"]},{"name":"TOTAL_CAPITAL_RATIO","sample_values":["18.5"]},{"name":"TOTAL_CAPITAL_REQUIREMENT_CHF","sample_values":["-24035.4112800000"]},{"name":"TOTAL_CUSTOMERS","sample_values":["1722"]},{"name":"TOTAL_EXPECTED_LOSS_CHF","sample_values":["-28046.880733500000"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["1272223.46"]},{"name":"TOTAL_RWA_CHF","sample_values":["-300442.64100000"]}],"time_dimensions":[{"name":"CALCULATION_DATE","sample_values":["2025-10-08"]}]},{"name":"REPP_AGG_DT_IRB_RISK_TRENDS","dimensions":[{"name":"PORTFOLIO_SEGMENT","sample_values":["RETAIL"]}],"facts":[{"name":"AVG_LGD_RATE","sample_values":["45.000000"]},{"name":"AVG_PD_1_YEAR","sample_values":["0.6105110"]},{"name":"AVG_PD_LIFETIME","sample_values":["1.1462834"]},{"name":"AVG_RISK_WEIGHT","sample_values":["24.454123"]},{"name":"BACKTESTING_ACCURACY","sample_values":["87.2"]},{"name":"CURED_DEFAULTS","sample_values":["0"]},{"name":"DEFAULT_RATE","sample_values":["3.426249"]},{"name":"EXPECTED_LOSS_CHF","sample_values":["-28046.880733500000"]},{"name":"MODEL_PERFORMANCE_SCORE","sample_values":["9"]},{"name":"NET_DEFAULT_CHANGE","sample_values":["59"]},{"name":"NEW_DEFAULTS","sample_values":["59"]},{"name":"RATING_MIGRATIONS_DOWN","sample_values":["0"]},{"name":"RATING_MIGRATIONS_UP","sample_values":["0"]},{"name":"STRESS_TEST_MULTIPLIER","sample_values":["1"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["1272223.46"]},{"name":"TOTAL_RWA_CHF","sample_values":["-300442.64100000"]}],"time_dimensions":[{"name":"TREND_DATE","sample_values":["2025-10-08"]}]},{"name":"REPP_AGG_DT_IRB_PORTFOLIO_METRICS","dimensions":[{"name":"CREDIT_RATING","sample_values":["AAA","CCC"]},{"name":"PORTFOLIO_SEGMENT","sample_values":["RETAIL"]}],"facts":[{"name":"AVERAGE_EXPOSURE_CHF","sample_values":["1021.68362598","-7234.51542373"]},{"name":"CAPITAL_REQUIREMENT_CHF","sample_values":["-51220.3692000000","27184.9579200000"]},{"name":"COLLATERAL_COVERAGE_RATIO","sample_values":["60.000000000"]},{"name":"CONCENTRATION_RISK_SCORE","sample_values":["9","3"]},{"name":"CUSTOMER_COUNT","sample_values":["59","1663"]},{"name":"DEFAULT_COUNT","sample_values":["59","0"]},{"name":"DEFAULT_RATE","sample_values":["0.000000","100.000000"]},{"name":"EXPECTED_LOSS_CHF","sample_values":["764.576941500000","-28811.457675000000"]},{"name":"RISK_WEIGHTED_ASSETS_CHF","sample_values":["-640254.61500000","339811.97400000"]},{"name":"SECURED_EXPOSURE_CHF","sample_values":["1019435.922","-256101.846"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["1699059.87","-426836.41"]},{"name":"UNSECURED_EXPOSURE_CHF","sample_values":["-170734.564","679623.948"]},{"name":"VINTAGE_MONTHS","sample_values":["31.016949","32.358388"]},{"name":"WATCH_LIST_COUNT","sample_values":["3","0"]},{"name":"WATCH_LIST_RATE","sample_values":["0.000000","5.084746"]},{"name":"WEIGHTED_AVG_LGD","sample_values":["45.00000000"]},{"name":"WEIGHTED_AVG_PD","sample_values":["0.100000000","15.000000000"]}]},{"name":"REPP_AGG_DT_IRB_CUSTOMER_RATINGS","dimensions":[{"name":"CREDIT_RATING","sample_values":["AAA","CCC"]},{"name":"CUSTOMER_ID","sample_values":["CUST_00376","CUST_00406","CUST_00417"]},{"name":"DEFAULT_FLAG","sample_values":["FALSE","TRUE"]},{"name":"FULL_NAME","sample_values":["Emil Ellingsen","Peter Lindström","Ubaldo Fermi"]},{"name":"PORTFOLIO_SEGMENT","sample_values":["RETAIL"]},{"name":"RATING_METHODOLOGY","sample_values":["FOUNDATION_IRB"]},{"name":"WATCH_LIST_FLAG","sample_values":["FALSE","TRUE"]}],"facts":[{"name":"DAYS_PAST_DUE","sample_values":["120","0"]},{"name":"EAD_AMOUNT","sample_values":["11160.40","-34919.18","15204.16"]},{"name":"LGD_RATE","sample_values":["45"]},{"name":"PD_1_YEAR","sample_values":["15.0","0.1"]},{"name":"PD_LIFETIME","sample_values":["0.3","25.0"]},{"name":"RISK_WEIGHT","sample_values":["20","150"]},{"name":"SECURED_EXPOSURE_CHF","sample_values":["-6362.196","6696.240","15814.656"]},{"name":"TOTAL_EXPOSURE_CHF","sample_values":["11160.40","-34919.18","15204.16"]},{"name":"UNSECURED_EXPOSURE_CHF","sample_values":["-4241.464","4464.160","2446.712"]}],"time_dimensions":[{"name":"ONBOARDING_DATE","sample_values":["2023-07-25","2025-04-28","2025-08-23"]},{"name":"RATING_DATE","sample_values":["2025-10-08"]}]},{"name":"REPP_AGG_DT_CUSTOMER_SUMMARY","dimensions":[{"name":"ACCOUNT_CURRENCIES","sample_values":["USD, GBP","GBP","EUR, GBP, JPY"]},{"name":"CUSTOMER_ID","sample_values":["CUST_00130","CUST_00333","CUST_00530"]},{"name":"FULL_NAME","sample_values":["Markus Martinsen","Tilde Paulsen","Jari Marttila"]},{"name":"HAS_ANOMALY","sample_values":["FALSE","TRUE"]}],"facts":[{"name":"ANOMALOUS_TRANSACTIONS","sample_values":["4","2","0"]},{"name":"AVG_TRANSACTION_AMOUNT","sample_values":["-778.86902439","169.70600000","347.38767442"]},{"name":"CURRENCY_COUNT","sample_values":["1","2","3"]},{"name":"MAX_TRANSACTION_AMOUNT","sample_values":["6700.22","8322.03","14094.15"]},{"name":"TOTAL_ACCOUNTS","sample_values":["256","111","195"]},{"name":"TOTAL_BASE_AMOUNT","sample_values":["-8128.07","-12330.90","-12206.74"]},{"name":"TOTAL_TRANSACTIONS","sample_values":["256","111","195"]}],"time_dimensions":[{"name":"ONBOARDING_DATE","sample_values":["2022-04-27","2022-12-14","2023-06-16"]}]}]}');

-- ============================================================
-- 550_semantic_view.sql - Unified Business Data Access completed!
-- ============================================================
