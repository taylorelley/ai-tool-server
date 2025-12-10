#!/bin/bash

############################################################
# AI Tool Server Stack - Health Check Script
############################################################
# This script validates the configuration and checks
# service health before deployment
############################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo -e "${BLUE}=============================================="
echo "AI Tool Server Stack - Health Check"
echo -e "==============================================${NC}"
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${RED}✗ CRITICAL: .env file not found${NC}"
    echo "  Run ./setup.sh to create configuration"
    exit 1
fi

echo -e "${GREEN}✓${NC} .env file exists"
echo ""

# Load .env file
set -a
source .env
set +a

echo -e "${BLUE}Checking required environment variables...${NC}"
echo ""

# Required variables that must not be empty
REQUIRED_VARS=(
    "POSTGRES_PASSWORD"
    "JWT_SECRET"
    "ANON_KEY"
    "SERVICE_ROLE_KEY"
    "SECRET_KEY_BASE"
    "PG_META_CRYPTO_KEY"
    "VAULT_ENC_KEY"
    "WEBUI_SECRET_KEY"
    "LANGFLOW_DB_PASSWORD"
    "DASHBOARD_PASSWORD"
    "LOGFLARE_PUBLIC_ACCESS_TOKEN"
    "LOGFLARE_PRIVATE_ACCESS_TOKEN"
)

for var in "${REQUIRED_VARS[@]}"; do
    value="${!var}"
    if [ -z "$value" ]; then
        echo -e "${RED}✗ CRITICAL: $var is not set${NC}"
        ((ERRORS++))
    elif [[ "$value" == "changeme"* ]]; then
        echo -e "${RED}✗ CRITICAL: $var still has default 'changeme' value${NC}"
        ((ERRORS++))
    else
        echo -e "${GREEN}✓${NC} $var is set"
    fi
done

echo ""
echo -e "${BLUE}Checking service URLs...${NC}"
echo ""

# Check URL formats
URL_VARS=(
    "OPEN_WEBUI_URL"
    "LANGFLOW_URL"
    "SUPABASE_PUBLIC_URL"
    "API_EXTERNAL_URL"
    "SITE_URL"
)

for var in "${URL_VARS[@]}"; do
    value="${!var}"
    if [ -z "$value" ]; then
        echo -e "${YELLOW}⚠${NC}  WARNING: $var is not set"
        ((WARNINGS++))
    elif [[ $value =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
        echo -e "${GREEN}✓${NC} $var: $value"
    else
        echo -e "${RED}✗ ERROR: $var has invalid URL format${NC}"
        ((ERRORS++))
    fi
done

echo ""
echo -e "${BLUE}Checking port availability...${NC}"
echo ""

# Check if lsof is available
if ! command -v lsof &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}  WARNING: lsof utility not found - skipping port availability checks"
    echo "  Install lsof to enable port checks: sudo apt-get install lsof (Debian/Ubuntu) or sudo yum install lsof (RHEL/CentOS)"
    ((WARNINGS++))
else
    # Check if ports are available
    PORTS=(
        "LANGFLOW_PORT:7860:Langflow"
        "OPEN_WEBUI_PORT:8080:Open WebUI"
        "STUDIO_PORT:3001:Supabase Studio"
        "KONG_HTTP_PORT:8000:Supabase API"
    )

    for port_info in "${PORTS[@]}"; do
        IFS=':' read -r var default_port name <<< "$port_info"
        port="${!var:-$default_port}"

        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠${NC}  WARNING: Port $port ($name) is already in use"
            ((WARNINGS++))
        else
            echo -e "${GREEN}✓${NC} Port $port ($name) is available"
        fi
    done
fi

echo ""
echo -e "${BLUE}Checking required directories...${NC}"
echo ""

# Check if required directories exist
REQUIRED_DIRS=(
    "volumes/db"
    "volumes/api"
    "volumes/functions"
    "volumes/logs"
    "volumes/pooler"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $dir exists"
    else
        echo -e "${RED}✗ ERROR: $dir does not exist${NC}"
        ((ERRORS++))
    fi
done

echo ""
echo -e "${BLUE}Checking required files...${NC}"
echo ""

# Check if required files exist
REQUIRED_FILES=(
    "volumes/db/realtime.sql"
    "volumes/db/webhooks.sql"
    "volumes/db/roles.sql"
    "volumes/db/jwt.sql"
    "volumes/db/_supabase.sql"
    "volumes/db/logs.sql"
    "volumes/db/pooler.sql"
    "volumes/api/kong.yml"
    "volumes/logs/vector.yml"
    "volumes/pooler/pooler.exs"
    "volumes/functions/main/index.ts"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file exists"
    else
        echo -e "${RED}✗ ERROR: $file does not exist${NC}"
        ((ERRORS++))
    fi
done

echo ""
echo -e "${BLUE}Checking Docker...${NC}"
echo ""

# Check if Docker is running
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker is running"

    # Check Docker Compose version
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✓${NC} Docker Compose V2 is available"
    else
        echo -e "${RED}✗ ERROR: Docker Compose V2 is not available${NC}"
        ((ERRORS++))
    fi
else
    echo -e "${RED}✗ ERROR: Docker is not running${NC}"
    ((ERRORS++))
fi

echo ""
echo -e "${BLUE}Checking AI backend configuration...${NC}"
echo ""

# Check AI backend
if [ -n "$OPENAI_API_KEY" ]; then
    echo -e "${GREEN}✓${NC} OpenAI API key is configured"
elif [ -n "$OLLAMA_BASE_URL" ]; then
    echo -e "${GREEN}✓${NC} Ollama URL is configured: $OLLAMA_BASE_URL"
else
    echo -e "${YELLOW}⚠${NC}  WARNING: No AI backend configured (OpenAI or Ollama)"
    ((WARNINGS++))
fi

# Check SMTP configuration
echo ""
echo -e "${BLUE}Checking SMTP configuration...${NC}"
echo ""

if [ -n "$SMTP_HOST" ] && [ -n "$SMTP_USER" ] && [ -n "$SMTP_PASS" ]; then
    echo -e "${GREEN}✓${NC} SMTP is configured"
else
    echo -e "${YELLOW}⚠${NC}  WARNING: SMTP is not fully configured"
    echo "  Email notifications will not work"
    ((WARNINGS++))
fi

# Summary
echo ""
echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}Health Check Summary${NC}"
echo -e "${BLUE}==============================================${NC}"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! System is ready to deploy.${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. docker compose up -d"
    echo "  2. docker compose logs -f"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) found${NC}"
    echo "  The system can be deployed but some features may not work."
    echo ""
    echo "Review warnings above and fix if needed."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    echo ""
    echo "Please fix the errors above before deploying."
    echo "Run this script again after making fixes."
    exit 1
fi
