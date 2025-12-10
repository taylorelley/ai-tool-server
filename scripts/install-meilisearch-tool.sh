#!/bin/bash

############################################################
# Install Meilisearch Tool in Open WebUI
# This script automatically imports the Meilisearch search tool
############################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=============================================="
echo "Meilisearch Tool Installation for Open WebUI"
echo -e "==============================================${NC}"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${RED}✗ Error: .env file not found${NC}"
    echo "Please run ./setup.sh first"
    exit 1
fi

# Load environment variables
source .env

# Check if Open WebUI is running
echo -e "${BLUE}Checking if Open WebUI is running...${NC}"
if ! docker compose ps open-webui | grep -q "Up"; then
    echo -e "${RED}✗ Open WebUI is not running${NC}"
    echo "Start it with: docker compose up -d open-webui"
    exit 1
fi
echo -e "${GREEN}✓${NC} Open WebUI is running"
echo ""

# Prompt for admin credentials
echo -e "${BLUE}Please provide your Open WebUI admin credentials:${NC}"
read -p "Email: " ADMIN_EMAIL
read -s -p "Password: " ADMIN_PASSWORD
echo ""
echo ""

# Get Open WebUI URL
OPEN_WEBUI_URL="${OPEN_WEBUI_URL:-http://localhost:8080}"

echo -e "${BLUE}Logging in to Open WebUI...${NC}"

# Login to get auth token
LOGIN_RESPONSE=$(curl -s -X POST "${OPEN_WEBUI_URL}/api/v1/auths/signin" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"${ADMIN_EMAIL}\",\"password\":\"${ADMIN_PASSWORD}\"}")

# Extract token
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')

if [ -z "$TOKEN" ]; then
    echo -e "${RED}✗ Login failed${NC}"
    echo "Please check your credentials"
    exit 1
fi

echo -e "${GREEN}✓${NC} Logged in successfully"
echo ""

# Read the tool file
TOOL_FILE="volumes/open-webui/tools/meilisearch_search.py"
if [ ! -f "$TOOL_FILE" ]; then
    echo -e "${RED}✗ Tool file not found: $TOOL_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}Installing Meilisearch search tool...${NC}"

# Read tool content and create JSON payload
TOOL_CONTENT=$(cat "$TOOL_FILE" | jq -Rs .)

PAYLOAD=$(cat <<EOF
{
  "name": "meilisearch_search",
  "content": $TOOL_CONTENT,
  "meta": {
    "description": "Search indexed documentation using Meilisearch",
    "manifest": {
      "title": "Meilisearch Documentation Search",
      "version": "1.1.0",
      "author": "AI Tool Server Stack"
    }
  }
}
EOF
)

# Install the tool
INSTALL_RESPONSE=$(curl -s -X POST "${OPEN_WEBUI_URL}/api/v1/tools/create" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d "$PAYLOAD")

if echo "$INSTALL_RESPONSE" | grep -q "id"; then
    echo -e "${GREEN}✓${NC} Meilisearch tool installed successfully!"
    echo ""
    echo -e "${BLUE}ℹ  The tool is now available in Open WebUI${NC}"
    echo "   It will automatically use the configured Meilisearch instance"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "   1. Go to Admin Panel → Tools to verify installation"
    echo "   2. Run 'docker compose run scrapix' to index documentation"
    echo "   3. Start using the tool in your chats!"
else
    echo -e "${RED}✗ Installation failed${NC}"
    echo "Response: $INSTALL_RESPONSE"
    exit 1
fi
