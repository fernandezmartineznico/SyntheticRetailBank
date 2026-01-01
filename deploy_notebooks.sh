#!/bin/bash

# =============================================================================
# Snowflake Notebooks Deployment Script
# =============================================================================
# Deploys all compliance notebooks to Snowflake
# Usage: ./deploy_notebooks.sh --CONNECTION_NAME=<connection> --DATABASE=<database>
# =============================================================================

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
CONNECTION_NAME=""
DATABASE=""
SCHEMA="PUBLIC"
WAREHOUSE="MD_TEST_WH"

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --CONNECTION_NAME=*)
      CONNECTION_NAME="${arg#*=}"
      shift
      ;;
    --DATABASE=*)
      DATABASE="${arg#*=}"
      shift
      ;;
    --SCHEMA=*)
      SCHEMA="${arg#*=}"
      shift
      ;;
    --WAREHOUSE=*)
      WAREHOUSE="${arg#*=}"
      shift
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: $0 --CONNECTION_NAME=<connection> --DATABASE=<database> [--SCHEMA=<schema>] [--WAREHOUSE=<warehouse>]"
      exit 1
      ;;
  esac
done

# Validate required parameters
if [[ -z "$CONNECTION_NAME" ]]; then
  echo -e "${RED}❌ Error: --CONNECTION_NAME is required${NC}"
  echo "Usage: $0 --CONNECTION_NAME=<connection> --DATABASE=<database>"
  exit 1
fi

if [[ -z "$DATABASE" ]]; then
  echo -e "${RED}❌ Error: --DATABASE is required${NC}"
  echo "Usage: $0 --CONNECTION_NAME=<connection> --DATABASE=<database>"
  exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NOTEBOOKS_DIR="$SCRIPT_DIR/notebooks"

echo ""
echo "📓 SNOWFLAKE NOTEBOOKS DEPLOYMENT"
echo "=================================="
echo "Connection: $CONNECTION_NAME"
echo "Database:   $DATABASE"
echo "Schema:     $SCHEMA"
echo "Warehouse:  $WAREHOUSE"
echo ""

# Check if notebooks directory exists
if [[ ! -d "$NOTEBOOKS_DIR" ]]; then
  echo -e "${RED}❌ Notebooks directory not found: $NOTEBOOKS_DIR${NC}"
  exit 1
fi

# Find all notebook files
NOTEBOOKS=$(find "$NOTEBOOKS_DIR" -maxdepth 1 -name "*.ipynb" -type f 2>/dev/null | sort)

if [[ -z "$NOTEBOOKS" ]]; then
  echo -e "${YELLOW}⚠️  No .ipynb files found in $NOTEBOOKS_DIR${NC}"
  exit 0
fi

# Count notebooks
NOTEBOOK_COUNT=$(echo "$NOTEBOOKS" | wc -l | tr -d ' ')
echo "Found $NOTEBOOK_COUNT notebook(s) to deploy"
echo ""

# Create stage for notebooks if it doesn't exist
STAGE_NAME="NOTEBOOKS_STAGE"
echo "📦 Creating/verifying stage: @$SCHEMA.$STAGE_NAME"
set +e
snow sql \
  -q "CREATE STAGE IF NOT EXISTS $DATABASE.$SCHEMA.$STAGE_NAME COMMENT='Temporary stage for notebook deployment';" \
  --connection "$CONNECTION_NAME" \
  > /dev/null 2>&1
set -e
echo -e "   ${GREEN}✅ Stage ready${NC}"
echo ""

# Deploy each notebook
SUCCESS_COUNT=0
FAILED_COUNT=0
DEPLOYED_NOTEBOOKS=()

for NOTEBOOK_PATH in $NOTEBOOKS; do
  NOTEBOOK_FILE=$(basename "$NOTEBOOK_PATH")
  NOTEBOOK_NAME="${NOTEBOOK_FILE%.ipynb}"
  
  echo -e "${BLUE}📓 Deploying: $NOTEBOOK_NAME${NC}"
  echo "   File: $NOTEBOOK_FILE"
  
  # Step 1: Upload notebook file to stage
  echo "   → Uploading to stage..."
  set +e
  UPLOAD_OUTPUT=$(snow stage copy \
    "$NOTEBOOK_PATH" \
    "@$DATABASE.$SCHEMA.$STAGE_NAME" \
    --connection "$CONNECTION_NAME" \
    --overwrite \
    2>&1)
  UPLOAD_RESULT=$?
  set -e
  
  if [[ $UPLOAD_RESULT -ne 0 ]]; then
    echo -e "   ${RED}❌ Upload failed${NC}"
    echo "   Error: $UPLOAD_OUTPUT"
    FAILED_COUNT=$((FAILED_COUNT + 1))
    echo ""
    continue
  fi
  echo "   → Upload complete"
  
  # Step 2: Create notebook from stage
  echo "   → Creating notebook..."
  set +e
  CREATE_OUTPUT=$(snow notebook create \
    "$NOTEBOOK_NAME" \
    --notebook-file "@$DATABASE.$SCHEMA.$STAGE_NAME/$NOTEBOOK_FILE" \
    --database "$DATABASE" \
    --schema "$SCHEMA" \
    --warehouse "$WAREHOUSE" \
    --connection "$CONNECTION_NAME" \
    2>&1)
  
  RESULT=$?
  set -e
  
  if [[ $RESULT -eq 0 ]]; then
    echo -e "   ${GREEN}✅ Successfully deployed${NC}"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    DEPLOYED_NOTEBOOKS+=("$NOTEBOOK_NAME")
    
    # Extract URL if present
    URL=$(echo "$CREATE_OUTPUT" | grep -o 'https://[^ ]*' | head -1)
    if [[ -n "$URL" ]]; then
      echo "   🔗 URL: $URL"
    fi
  else
    echo -e "   ${RED}❌ Deployment failed${NC}"
    echo "   Error: $CREATE_OUTPUT"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
  echo ""
done

# Clean up stage
echo "🧹 Cleaning up temporary stage..."
set +e
snow sql \
  -q "DROP STAGE IF EXISTS $DATABASE.$SCHEMA.$STAGE_NAME;" \
  --connection "$CONNECTION_NAME" \
  > /dev/null 2>&1
set -e
echo ""

# Summary
echo ""
echo "======================================"
echo "📊 DEPLOYMENT SUMMARY"
echo "======================================"
echo -e "${GREEN}✅ Successfully deployed: $SUCCESS_COUNT${NC}"

if [[ $SUCCESS_COUNT -gt 0 ]]; then
  echo ""
  echo "Deployed notebooks:"
  for NB in "${DEPLOYED_NOTEBOOKS[@]}"; do
    echo "   • $NB"
  done
fi

if [[ $FAILED_COUNT -gt 0 ]]; then
  echo -e "${RED}❌ Failed: $FAILED_COUNT${NC}"
fi

echo ""
echo "📍 Location: $DATABASE.$SCHEMA"
echo "🔗 Access: Snowsight → Projects → Notebooks"
echo ""

if [[ $SUCCESS_COUNT -eq $NOTEBOOK_COUNT ]]; then
  echo -e "${GREEN}🎉 All notebooks deployed successfully!${NC}"
  echo ""
  echo "Next steps:"
  echo "1. Open Snowsight and navigate to: Projects → Notebooks"
  echo "2. Find your notebooks in: $DATABASE.$SCHEMA"
  echo "3. Run any notebook - no password needed!"
  echo "4. For automation, see: notebooks/WORKSPACE_SETUP.md"
  exit 0
else
  echo -e "${YELLOW}⚠️  Some notebooks failed to deploy${NC}"
  echo "Please check the error messages above"
  exit 1
fi

