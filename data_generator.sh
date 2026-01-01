#!/bin/bash

# Complete Synthetic Bank Data Generator
# Generates all data types: customers, transactions, SWIFT, PEP, mortgages, lifecycles, market data

echo "=================================================="
echo "Synthetic Bank - Complete Data Generation"
echo "=================================================="
echo ""

# Configuration
NUM_CUSTOMERS=${1:-20}  # Default 20, can override with first argument
OUTPUT_DIR="generated_data"
PERIOD=19  # 19 months for full dormancy and churn testing

# Cleanup previous output if requested
if [ "$2" == "--clean" ] || [ "$2" == "-c" ]; then
    if [ -d "$OUTPUT_DIR" ]; then
        echo "🧹 Cleaning previous output..."
        rm -rf "$OUTPUT_DIR"
    fi
fi

echo ""
echo "=================================================="
echo "Generating Complete Banking Dataset"
echo "=================================================="
echo "Configuration:"
echo "  - Customers: $NUM_CUSTOMERS"
echo "  - Period: $PERIOD months"
echo "  - Output: $OUTPUT_DIR/"
echo ""
echo "Generators:"
echo "  ✓ Customer master data & transactions"
echo "  ✓ SWIFT ISO20022 messages"
echo "  ✓ PEP (Politically Exposed Persons) data"
echo "  ✓ Mortgage application emails"
echo "  ✓ Address updates (SCD Type 2)"
echo "  ✓ Customer updates (employment, account tier)"
echo "  ✓ Customer lifecycle events & status history"
echo "  ✓ Fixed income trades (bonds & swaps)"
echo "  ✓ Commodity trades (energy, metals, agricultural)"
echo ""

./venv/bin/python main.py \
    --customers $NUM_CUSTOMERS \
    --anomaly-rate 3.0 \
    --period $PERIOD \
    --output-dir "$OUTPUT_DIR" \
    --generate-swift \
    --swift-percentage 40 \
    --generate-pep \
    --pep-records 150 \
    --generate-mortgage-emails \
    --mortgage-customers 5 \
    --generate-address-updates \
    --address-update-files 9 \
    --generate-customer-snapshot \
    --generate-customer-updates \
    --customer-update-files 8 \
    --generate-lifecycle \
    --generate-fixed-income \
    --fixed-income-trades $((NUM_CUSTOMERS * 5)) \
    --generate-commodities \
    --commodity-trades $((NUM_CUSTOMERS * 2)) \
    --clean

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ FAILED: Data generation failed"
    exit 1
fi

echo ""
echo "✅ PASSED: All data generated successfully"

echo ""
echo "=================================================="
echo "DATA VALIDATION"
echo "=================================================="

# Verify core files exist
echo "📁 Validating generated files..."

VALIDATION_PASSED=true

# Master data files
if [ ! -f "${OUTPUT_DIR}/master_data/customers.csv" ]; then
    echo "   ❌ customers.csv not found"
    VALIDATION_PASSED=false
fi

if [ ! -f "${OUTPUT_DIR}/master_data/accounts.csv" ]; then
    echo "   ❌ accounts.csv not found"
    VALIDATION_PASSED=false
fi

if [ ! -f "${OUTPUT_DIR}/master_data/customer_addresses.csv" ]; then
    echo "   ❌ customer_addresses.csv not found"
    VALIDATION_PASSED=false
fi

if [ ! -d "${OUTPUT_DIR}/master_data/customer_events" ]; then
    echo "   ❌ customer_events/ directory not found"
    VALIDATION_PASSED=false
fi

if [ ! -f "${OUTPUT_DIR}/master_data/customer_status.csv" ]; then
    echo "   ❌ customer_status.csv not found"
    VALIDATION_PASSED=false
fi

# PEP data
if [ ! -f "${OUTPUT_DIR}/master_data/pep_data.csv" ]; then
    echo "   ❌  pep_data.csv not found"
fi

# Count directory files
TRANSACTION_FILES=$(find "${OUTPUT_DIR}/payment_transactions" -name "pay_transactions_*.csv" 2>/dev/null | wc -l | tr -d ' ')
EQUITY_FILES=$(find "${OUTPUT_DIR}/equity_trades" -name "trades_*.csv" 2>/dev/null | wc -l | tr -d ' ')
FX_FILES=$(find "${OUTPUT_DIR}/fx_rates" -name "fx_rates_*.csv" 2>/dev/null | wc -l | tr -d ' ')
ADDRESS_UPDATE_FILES=$(find "${OUTPUT_DIR}/master_data/address_updates" -name "customer_addresses_*.csv" 2>/dev/null | wc -l | tr -d ' ')
CUSTOMER_UPDATE_FILES=$(find "${OUTPUT_DIR}/master_data/customer_updates" -name "customer_updates_*.csv" 2>/dev/null | wc -l | tr -d ' ')
CUSTOMER_EVENT_FILES=$(find "${OUTPUT_DIR}/master_data/customer_events" -name "customer_events_*.csv" 2>/dev/null | wc -l | tr -d ' ')
SWIFT_FILES=$(find "${OUTPUT_DIR}/swift_messages" -name "*.xml" 2>/dev/null | wc -l | tr -d ' ')
EMAIL_FILES=$(find "${OUTPUT_DIR}/emails" -name "*.eml" 2>/dev/null | wc -l | tr -d ' ')
FI_FILES=$(find "${OUTPUT_DIR}/fixed_income_trades" -name "*.csv" 2>/dev/null | wc -l | tr -d ' ')
COMMODITY_FILES=$(find "${OUTPUT_DIR}/commodity_trades" -name "*.csv" 2>/dev/null | wc -l | tr -d ' ')

echo ""
echo "📊 File Counts:"
echo "   Payment transaction files: $TRANSACTION_FILES"
echo "   Equity trade files: $EQUITY_FILES"
echo "   FX rate files: $FX_FILES"
echo "   Address update files: $ADDRESS_UPDATE_FILES"
echo "   Customer update files: $CUSTOMER_UPDATE_FILES"
echo "   Customer event files: $CUSTOMER_EVENT_FILES"
echo "   SWIFT messages: $SWIFT_FILES"
echo "   Mortgage emails: $EMAIL_FILES"
echo "   Fixed income files: $FI_FILES"
echo "   Commodity files: $COMMODITY_FILES"

# Count records
CUSTOMER_COUNT=$(tail -n +2 "${OUTPUT_DIR}/master_data/customers.csv" 2>/dev/null | wc -l | tr -d ' ')
# Count total events across all date-based files
EVENT_COUNT=0
if [ -d "${OUTPUT_DIR}/master_data/customer_events" ]; then
    for event_file in "${OUTPUT_DIR}/master_data/customer_events"/*.csv; do
        if [ -f "$event_file" ]; then
            COUNT=$(tail -n +2 "$event_file" 2>/dev/null | wc -l | tr -d ' ')
            EVENT_COUNT=$((EVENT_COUNT + COUNT))
        fi
    done
fi

echo ""
echo "📊 Record Counts:"
echo "   Customers: $CUSTOMER_COUNT"
echo "   Lifecycle events: $EVENT_COUNT"

if [ "$VALIDATION_PASSED" = false ]; then
    echo ""
    echo "❌ Some critical files are missing"
    exit 1
fi

echo ""
echo "=================================================="
echo "GENERATION SUMMARY"
echo "=================================================="
echo "✅ All data generation completed successfully!"
echo ""
echo "📂 Generated Data Structure:"
echo ""
echo "   ${OUTPUT_DIR}/"
echo "   ├── master_data/"
echo "   │   ├── customers.csv ($CUSTOMER_COUNT customers) [with extended attributes]"
echo "   │   ├── accounts.csv"
echo "   │   ├── customer_addresses.csv"
echo "   │   ├── customer_status.csv"
echo "   │   ├── pep_data.csv"
echo "   │   ├── address_updates/ ($ADDRESS_UPDATE_FILES files)"
echo "   │   ├── customer_updates/ ($CUSTOMER_UPDATE_FILES files)"
echo "   │   └── customer_events/ ($CUSTOMER_EVENT_FILES files, $EVENT_COUNT events)"
echo "   ├── payment_transactions/ ($TRANSACTION_FILES files)"
echo "   ├── equity_trades/ ($EQUITY_FILES files)"
echo "   ├── fixed_income_trades/ ($FI_FILES files)"
echo "   ├── commodity_trades/ ($COMMODITY_FILES files)"
echo "   ├── fx_rates/ ($FX_FILES files)"
echo "   ├── swift_messages/ ($SWIFT_FILES XML files)"
echo "   └── emails/ ($EMAIL_FILES email files)"
echo ""
echo "🎉 Synthetic Bank Data Generation COMPLETE!"
echo ""
echo "📖 Next Steps:"
echo "   1. Review generated data in: $OUTPUT_DIR/"
echo "   2. Deploy to Snowflake: ./deploy_structure.sh --DATABASE=AAA_DEV_SYNTHETIC_BANK"
echo "   3. Upload data: ./upload-data.sh"
echo ""
echo "💡 Usage:"
echo "   # Generate with custom customer count:"
echo "   ./data_generator.sh 100"
echo ""
echo "   # Generate with cleanup:"
echo "   ./data_generator.sh 100 --clean"
echo ""
echo "   # Generate default (20 customers):"
echo "   ./data_generator.sh"

