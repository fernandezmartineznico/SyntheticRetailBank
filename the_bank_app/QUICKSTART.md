# Quick Start Guide

Get the Synthetic Retail Bank running in 5 minutes!

## Prerequisites

- Python 3.10 or higher
- Snowflake account with access to:
  - `AAA_DEV_SYNTHETIC_BANK.CRM_AGG_001` (Customer, Employee, Account data)
  - `AAA_DEV_SYNTHETIC_BANK.PAY_AGG_001` (Payment/AML data - optional)
- Deployed tables:
  - `CRMA_AGG_DT_CUSTOMER_360` (required)
  - `PAYA_AGG_DT_TRANSACTION_ANOMALIES` (optional - for AML monitoring)
  - `EMPA_AGG_DT_ADVISOR_PERFORMANCE` (optional - for wealth management)

## Installation (3 steps)

### Step 1: Configure Snowflake Connection

Create `.streamlit/secrets.toml`:

```bash
cp.streamlit/secrets.toml.example.streamlit/secrets.toml
```

Edit `.streamlit/secrets.toml` with your credentials:

```toml
[snowflake]
account = "sfseeurope-mdaeppen" # Your account
user = "your-username"
password = "your-password"
warehouse = "your-warehouse"
database = "AAA_DEV_SYNTHETIC_BANK"
schema = "CRM_AGG_001"
role = "ACCOUNTADMIN"
```

### Step 2: Run the Quick Start Script

```bash
./run.sh
```

This will:
- Create virtual environment (if needed)
- Install dependencies
- Start Streamlit app

### Step 3: Open in Browser

The app automatically opens at: **http://localhost:8501**

---

## Manual Setup (if run.sh doesn't work)

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run app
streamlit run app.py
```

---

## First Time Usage

### 1. Test Connection (Settings Tab)

1. Navigate to the **⚙️ Settings** tab (last tab)
2. Check connection status (should show green ✅)
3. Click **🔍 Test Connection** to verify
4. If fails, check `.streamlit/secrets.toml` credentials

### 2. Explore Customer Data (Customer 360° Tab)

1. Go to **👤 Customer 360°** tab (first tab)
2. Try searching for customers by:
   - Name (e.g., "John")
   - Country (select from dropdown)
   - Account Tier (PLATINUM, GOLD, etc.)
3. Click a customer to view detailed 360° profile

### 3. Check Risk Dashboard (Risk & Compliance Tab)

1. Go to **🛡️ Risk & Compliance** tab
2. Review key metrics:
   - Total high-risk customers
   - PEP matches
   - Sanctions screening results
3. Export high-risk customer list (CSV)

### 4. Explore New Dashboards

**🚨 AML Monitoring** - View transaction monitoring alerts and anomalies
- Key metrics: Total alerts, unique customers, anomaly rate
- Alert trend analysis over time
- Export AML reports for regulatory submissions

**💳 Lending Operations** - Monitor credit portfolio and risk
- Credit score distribution
- Risk classification breakdown
- Lending portfolio analysis

**💎 Wealth Management** - Track advisor performance and AUM
- Total assets under management
- Top advisors by AUM
- Advisor capacity analysis

**⚖️ Sanctions Control** - Monitor sanctions screening
- Sanctions matches requiring review
- Exact vs. fuzzy match distribution
- Risk level analysis

**👥 Advisor Management** - Manage advisor workload
- Advisor capacity and availability
- Client assignment optimization
- Team performance metrics

**🔍 KYC Screening** - Monitor PEP matches and KYC completeness
- PEP screening results
- KYC data completeness by country
- Customers requiring review

**📊 Data Quality** - Monitor data completeness and quality
- Field-level completeness metrics
- Missing data analysis
- Quality threshold monitoring

**📋 Compliance Risk** - Overall compliance risk profile
- Enterprise-wide risk metrics
- Risk distribution by geography
- Action items and remediation tracking

**📈 Churn & Lifecycle** - Customer lifecycle and churn prediction
- Lifecycle stage distribution (NEW/ACTIVE/MATURE/DECLINING/DORMANT/CHURNED)
- Churn probability analysis and at-risk customers
- Premium customer retention (GOLD/PLATINUM >70% churn risk)
- Dormant account reactivation (>180 days inactive)
- Revenue at risk calculator

### 5. Try AI Query (Ask AI Tab)

1. Go to **💬 Ask AI** tab
2. Try example query: "Show me all PLATINUM customers in Switzerland"
3. Click **🚀 Ask** to get AI-powered response
4. **Note**: Requires Cortex AI Agent to be deployed

---

## Troubleshooting

### "Failed to connect to Snowflake"

**Solution:**
- Check `.streamlit/secrets.toml` exists
- Verify account format: `account.region.cloud`
- Test credentials in Snowsight first

### "Error loading customer data"

**Solution:**
- Verify table exists: `SELECT * FROM CRMA_AGG_DT_CUSTOMER_360 LIMIT 10;`
- Check user has SELECT privileges
- Ensure database/schema are correct

### "AI query failed"

**Solution:**
- AI queries require Cortex AI Agent deployment
- Deploy: `structure/750_CRM_INTELLIGENCE_AGENT.sql`
- Fallback: Use manual search in Customer 360° tab

### "Module not found" errors

**Solution:**
```bash
source venv/bin/activate # Activate virtual environment
pip install -r requirements.txt # Reinstall dependencies
```

---

## Next Steps

Once running successfully:

1. **Explore all tabs** to understand available features
2. **Customize queries** in `utils/data_loaders.py`
3. **Add visualizations** in `utils/visualizations.py`
4. **Deploy to production** (see README.md for deployment options)

---

## Support

- **Full documentation**: See `README.md`
- **Business guide**: `../docs/crm_business_guide.md`
- **UX plan**: `../docs/crm_streamlit_ux_plan.md`

---

** You're ready to explore your customer intelligence platform!**

