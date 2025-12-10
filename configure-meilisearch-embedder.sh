#!/bin/bash

############################################################
# Meilisearch Embedder Configuration Script
############################################################
# Configures vector embeddings for Meilisearch based on .env settings
############################################################

set -e

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please run ./setup.sh first to generate configuration."
    exit 1
fi

# Load configuration from .env
echo "Loading configuration from .env..."
MEILI_KEY=$(grep -m1 MEILI_MASTER_KEY .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_ENABLED=$(grep -m1 MEILISEARCH_EMBEDDER_ENABLED .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_SOURCE=$(grep -m1 MEILISEARCH_EMBEDDER_SOURCE .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_MODEL=$(grep -m1 MEILISEARCH_EMBEDDER_MODEL .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_NAME=$(grep -m1 MEILISEARCH_EMBEDDER_NAME .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_API_KEY=$(grep -m1 MEILISEARCH_EMBEDDER_API_KEY .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_URL=$(grep -m1 MEILISEARCH_EMBEDDER_URL .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_DIMENSIONS=$(grep -m1 MEILISEARCH_EMBEDDER_DIMENSIONS .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
EMBEDDER_DOC_TEMPLATE=$(grep -m1 MEILISEARCH_EMBEDDER_DOCUMENT_TEMPLATE .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)
INDEX_NAME=$(grep -m1 VITE_MEILISEARCH_INDEX .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)

# Default index name if not found
INDEX_NAME=${INDEX_NAME:-web_docs}

# Check if embedder is enabled
if [ "$EMBEDDER_ENABLED" != "true" ]; then
    echo "Error: Embedder is not enabled in .env"
    echo "Set MEILISEARCH_EMBEDDER_ENABLED=true and configure other embedder settings."
    exit 1
fi

# Check required fields
if [ -z "$MEILI_KEY" ]; then
    echo "Error: MEILI_MASTER_KEY not found in .env"
    exit 1
fi

if [ -z "$EMBEDDER_SOURCE" ] || [ -z "$EMBEDDER_MODEL" ]; then
    echo "Error: MEILISEARCH_EMBEDDER_SOURCE and MEILISEARCH_EMBEDDER_MODEL are required"
    exit 1
fi

# Check if Meilisearch is running
echo "Checking if Meilisearch is running..."
if ! curl -sf http://localhost:7700/health > /dev/null 2>&1; then
    echo "Error: Meilisearch is not running or not accessible at http://localhost:7700"
    echo "Please start the stack with: docker compose up -d"
    exit 1
fi

echo "✓ Meilisearch is running"

# Function to escape strings for JSON
json_escape() {
    local string="$1"
    # Escape backslashes first, then quotes, newlines, tabs, etc.
    string="${string//\\/\\\\}"  # \ -> \\
    string="${string//\"/\\\"}"  # " -> \"
    string="${string//$'\n'/\\n}"  # newline -> \n
    string="${string//$'\r'/\\r}"  # carriage return -> \r
    string="${string//$'\t'/\\t}"  # tab -> \t
    echo "$string"
}

# Build embedder configuration JSON with proper escaping
echo "Building embedder configuration..."
EMBEDDER_CONFIG="{"
EMBEDDER_CONFIG+="\"source\":\"$(json_escape "${EMBEDDER_SOURCE}")\""
EMBEDDER_CONFIG+=",\"model\":\"$(json_escape "${EMBEDDER_MODEL}")\""

if [ -n "$EMBEDDER_API_KEY" ]; then
    EMBEDDER_CONFIG+=",\"apiKey\":\"$(json_escape "${EMBEDDER_API_KEY}")\""
fi

if [ -n "$EMBEDDER_URL" ]; then
    EMBEDDER_CONFIG+=",\"url\":\"$(json_escape "${EMBEDDER_URL}")\""
fi

if [ -n "$EMBEDDER_DIMENSIONS" ]; then
    EMBEDDER_CONFIG+=",\"dimensions\":${EMBEDDER_DIMENSIONS}"
fi

if [ -n "$EMBEDDER_DOC_TEMPLATE" ]; then
    EMBEDDER_CONFIG+=",\"documentTemplate\":\"$(json_escape "${EMBEDDER_DOC_TEMPLATE}")\""
fi

EMBEDDER_CONFIG+="}"

echo "Embedder configuration:"
echo "  Name: ${EMBEDDER_NAME}"
echo "  Source: ${EMBEDDER_SOURCE}"
echo "  Model: ${EMBEDDER_MODEL}"
echo "  Index: ${INDEX_NAME}"

# Configure the embedder via API
echo ""
echo "Configuring embedder in Meilisearch..."
# Escape embedder name for JSON key
ESCAPED_EMBEDDER_NAME=$(json_escape "${EMBEDDER_NAME}")
EMBEDDER_RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH \
    "http://localhost:7700/indexes/${INDEX_NAME}/settings/embedders" \
    -H "Authorization: Bearer ${MEILI_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"${ESCAPED_EMBEDDER_NAME}\":${EMBEDDER_CONFIG}}")

# Extract HTTP code from response
HTTP_CODE=$(echo "$EMBEDDER_RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$EMBEDDER_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
    echo ""
    echo "✓ Embedder configured successfully!"
    echo ""
    echo "Task UID: $(echo "$RESPONSE_BODY" | grep -o '"taskUid":[0-9]*' | cut -d: -f2)"
    echo ""
    echo "Vector search is now available for the '${INDEX_NAME}' index."
    echo "You can monitor the task status in the Meilisearch admin UI at:"
    echo "  http://localhost:7702"
else
    echo ""
    echo "✗ Failed to configure embedder"
    echo "HTTP Status: $HTTP_CODE"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi
