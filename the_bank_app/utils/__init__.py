"""
Utils package for Synthetic Retail Bank
Contains utility modules for Snowflake connection, data loading, visualizations, and AI agent calls
"""

from .snowflake_connection import get_snowflake_session, test_connection, execute_query
from .agent_caller import call_agent_rest_api
from .data_loaders import (
    load_customer_360,
    load_high_risk_customers,
    load_risk_distribution,
    load_pep_sanctions_summary,
    load_account_tier_distribution,
    load_geographic_distribution
)
from .visualizations import (
    plot_risk_distribution,
    plot_account_tier_distribution,
    plot_geographic_distribution,
    plot_risk_score_histogram,
    plot_pep_sanctions_summary,
    plot_account_holdings_by_tier
)

__all__ = [
    'get_snowflake_session',
    'test_connection',
    'execute_query',
    'call_agent_rest_api',
    'load_customer_360',
    'load_high_risk_customers',
    'load_risk_distribution',
    'load_pep_sanctions_summary',
    'load_account_tier_distribution',
    'load_geographic_distribution',
    'plot_risk_distribution',
    'plot_account_tier_distribution',
    'plot_geographic_distribution',
    'plot_risk_score_histogram',
    'plot_pep_sanctions_summary',
    'plot_account_holdings_by_tier'
]

