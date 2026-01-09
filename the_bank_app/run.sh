#!/bin/bash
# Quick start script for Synthetic Retail Bank

echo "═══════════════════════════════════════════════════════════"
echo "🏦 Synthetic Retail Bank - Quick Start"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
    echo "✅ Virtual environment created"
    echo ""
fi

# Activate virtual environment
echo "🔌 Activating virtual environment..."
source venv/bin/activate
echo "✅ Virtual environment activated"
echo ""

# Check if dependencies are installed
if [ ! -f "venv/lib/python3.*/site-packages/streamlit" ]; then
    echo "📥 Installing dependencies..."
    pip install -r requirements.txt
    echo "✅ Dependencies installed"
    echo ""
fi

# Check if secrets.toml exists
if [ ! -f ".streamlit/secrets.toml" ]; then
    echo "⚠️  WARNING: .streamlit/secrets.toml not found!"
    echo ""
    echo "Please create .streamlit/secrets.toml with your Snowflake credentials:"
    echo ""
    echo "[snowflake]"
    echo "account = \"your-account\""
    echo "user = \"your-username\""
    echo "password = \"your-password\""
    echo "warehouse = \"your-warehouse\""
    echo "database = \"AAA_DEV_SYNTHETIC_BANK\""
    echo "schema = \"CRM_AGG_001\""
    echo "role = \"ACCOUNTADMIN\""
    echo ""
    echo "See .streamlit/secrets.toml.example for reference"
    echo ""
    exit 1
fi

# Run Streamlit app
echo "🚀 Starting Synthetic Retail Bank..."
echo ""
echo "The app will open in your browser at: http://localhost:8501"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""

streamlit run app.py

