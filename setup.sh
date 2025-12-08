#!/bin/bash

############################################################
# AI Tool Server Stack - Interactive Setup Script
############################################################
# Configures: Langflow, Open WebUI, Supabase, Meilisearch
# Optional: OAuth/OIDC SSO, AI Providers, SMTP
############################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================="
echo "AI Tool Server Stack"
echo "Interactive Setup"
echo -e "==============================================${NC}"
echo ""

# Pre-flight checks
echo -e "${BLUE}Running pre-flight checks...${NC}"
echo ""

# Check for required commands
MISSING_COMMANDS=()
for cmd in openssl curl docker; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_COMMANDS+=("$cmd")
    fi
done

if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Error: The following required commands are missing:${NC}"
    for cmd in "${MISSING_COMMANDS[@]}"; do
        echo "  - $cmd"
    done
    echo ""
    echo "Please install the missing dependencies and try again."
    exit 1
fi

echo -e "${GREEN}✓${NC} All required commands found (openssl, curl, docker)"

# Check Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Error: Docker is not running${NC}"
    echo "Please start Docker and try again."
    exit 1
fi

echo -e "${GREEN}✓${NC} Docker is running"
echo ""

# Check if .env already exists
if [ -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file already exists!${NC}"
    read -p "Overwrite? This will backup the existing file. (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    backup_file=".env.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓${NC} Backing up existing .env to $backup_file"
    cp .env "$backup_file"
fi

# Check if .env.template exists
if [ ! -f .env.template ]; then
    echo -e "${RED}✗ Error: .env.template not found!${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Copying .env.template to .env..."
cp .env.template .env
echo ""

# Create required volume directories
echo -e "${BLUE}Creating required volume directories...${NC}"
mkdir -p volumes/langflow/data volumes/langflow/db
mkdir -p volumes/open-webui/data volumes/open-webui/tools
mkdir -p volumes/playwright
mkdir -p volumes/meilisearch
mkdir -p volumes/db volumes/api volumes/functions volumes/logs volumes/pooler volumes/storage

# Set proper permissions for Langflow data directory
# Langflow container runs as non-root user and needs write access
chmod -R 777 volumes/langflow/data

echo -e "${GREEN}✓${NC} Volume directories created"
echo ""

# Function to generate a random secret (alphanumeric only for safety)
generate_secret() {
    openssl rand -hex 16
}

# Function to generate a longer secret
generate_long_secret() {
    local length=$1
    openssl rand -hex $(($length / 2))
}

# Detect sed version and set appropriate flags
if sed --version 2>&1 | grep -q GNU; then
    SED_INPLACE=(-i)
else
    SED_INPLACE=(-i '')
fi

# Function to replace a value in .env (safely handles special characters)
replace_env_value() {
    local key=$1
    local value=$2

    sed "${SED_INPLACE[@]}" "s|^${key}=.*|${key}=${value}|" .env
}

# Function to prompt for input with default value
prompt_with_default() {
    local prompt=$1
    local default=$2
    local varname=$3
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " value
        value=${value:-$default}
    else
        read -p "$prompt: " value
    fi
    
    eval $varname="'$value'"
}

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt=$1
    local default=$2

    if [ "$default" = "y" ]; then
        read -p "$prompt (Y/n): " -n 1 -r
    else
        read -p "$prompt (y/N): " -n 1 -r
    fi
    echo

    if [ "$default" = "y" ]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Function to validate URL format
validate_url() {
    local url=$1
    if [[ $url =~ ^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate email format
validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate port number
validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ $port -ge 1 ] && [ $port -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

echo -e "${BLUE}=== Step 1: OAuth/OIDC Configuration (Optional) ===${NC}"
echo ""
echo "Configure Single Sign-On (SSO) with OAuth/OIDC providers"
echo "(Authentik, Keycloak, Google, Azure AD, etc.)"
echo ""

OAUTH_CONFIGURED=false
if prompt_yes_no "Configure OAuth/OIDC for SSO?" "n"; then
    OAUTH_CONFIGURED=true
    echo ""
    echo "Examples: https://auth.yourdomain.com, https://keycloak.yourdomain.com/realms/myrealm"
    while true; do
        prompt_with_default "OAuth Provider Base URL" "http://localhost:9000" OAUTH_URL
        if validate_url "$OAUTH_URL"; then
            replace_env_value "OAUTH_PROVIDER_URL" "$OAUTH_URL"
            break
        else
            echo -e "${RED}✗ Invalid URL format${NC}"
        fi
    done

    # Open WebUI OAuth Configuration
    echo ""
    prompt_with_default "OAuth Provider Name (shown to users)" "SSO" OAUTH_NAME
    replace_env_value "OAUTH_PROVIDER_NAME" "$OAUTH_NAME"

    echo ""
    echo "OpenID Provider URL examples:"
    echo "  Authentik: ${OAUTH_URL}/application/o/open-webui/.well-known/openid-configuration"
    echo "  Keycloak: Include realm in base URL above"
    echo ""
    prompt_with_default "OpenID Provider URL" "" OPENID_URL
    if [ -n "$OPENID_URL" ]; then
        replace_env_value "OPENID_PROVIDER_URL" "$OPENID_URL"
    fi

    echo ""
    prompt_with_default "OAuth Client ID" "" OAUTH_CLIENT_ID
    replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_ID" "$OAUTH_CLIENT_ID"

    echo ""
    echo "Enter OAuth Client Secret:"
    read -s OAUTH_CLIENT_SECRET
    echo ""
    replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_SECRET" "$OAUTH_CLIENT_SECRET"

    # Set sensible OAuth defaults
    replace_env_value "ENABLE_OAUTH_SIGNUP" "true"
    replace_env_value "ENABLE_OAUTH_PERSISTENT_CONFIG" "true"
    replace_env_value "OAUTH_MERGE_ACCOUNTS_BY_EMAIL" "true"
    replace_env_value "OAUTH_SCOPES" "openid email profile"
    replace_env_value "ENABLE_PASSWORD_AUTH" "true"

    echo -e "${GREEN}✓${NC} OAuth/OIDC configured"
else
    echo -e "${BLUE}ℹ${NC}  Skipping OAuth configuration - local authentication only"
fi
echo ""

echo -e "${BLUE}=== Step 2: Service URLs ===${NC}"
echo ""
echo "Configure URLs for your services (for OAuth callbacks and production)."
echo ""

if prompt_yes_no "Is this a production deployment?" "n"; then
    PRODUCTION=true
    echo ""
    prompt_with_default "Your domain name" "yourdomain.com" DOMAIN

    OPEN_WEBUI_URL="https://chat.${DOMAIN}"
    LANGFLOW_URL="https://flow.${DOMAIN}"
    SUPABASE_PUBLIC_URL="https://db.${DOMAIN}"
    API_EXTERNAL_URL="https://db.${DOMAIN}"
    SITE_URL="https://db.${DOMAIN}:3001"

    echo ""
    echo "Auto-configured URLs:"
    echo "  Open WebUI:       $OPEN_WEBUI_URL"
    echo "  Langflow:         $LANGFLOW_URL"
    echo "  Supabase API:     $SUPABASE_PUBLIC_URL"
    echo "  Supabase Studio:  $SITE_URL"
    echo ""

    if prompt_yes_no "Customize these URLs?" "n"; then
        prompt_with_default "Open WebUI URL" "$OPEN_WEBUI_URL" OPEN_WEBUI_URL
        prompt_with_default "Langflow URL" "$LANGFLOW_URL" LANGFLOW_URL
        prompt_with_default "Supabase API URL" "$SUPABASE_PUBLIC_URL" SUPABASE_PUBLIC_URL
        prompt_with_default "Supabase Studio URL" "$SITE_URL" SITE_URL
        API_EXTERNAL_URL="$SUPABASE_PUBLIC_URL"
    fi
else
    PRODUCTION=false
    OPEN_WEBUI_URL="http://localhost:8080"
    LANGFLOW_URL="http://localhost:7860"
    SUPABASE_PUBLIC_URL="http://localhost:8000"
    API_EXTERNAL_URL="http://localhost:8000"
    SITE_URL="http://localhost:3001"
    
    echo -e "${GREEN}✓${NC} Using localhost URLs for development"
fi

replace_env_value "OPEN_WEBUI_URL" "$OPEN_WEBUI_URL"
replace_env_value "LANGFLOW_URL" "$LANGFLOW_URL"
replace_env_value "SUPABASE_PUBLIC_URL" "$SUPABASE_PUBLIC_URL"
replace_env_value "API_EXTERNAL_URL" "$API_EXTERNAL_URL"
replace_env_value "SITE_URL" "$SITE_URL"
echo ""

echo -e "${BLUE}=== Step 3: AI Model Backend Configuration ===${NC}"
echo ""
echo "Configure AI providers (you can configure multiple):"
echo ""

# Ollama
if prompt_yes_no "Configure Ollama (local)?" "n"; then
    echo ""
    prompt_with_default "Ollama URL" "http://host.docker.internal:11434" OLLAMA_URL
    replace_env_value "OLLAMA_BASE_URL" "$OLLAMA_URL"
    echo -e "${GREEN}✓${NC} Ollama configured"
fi
echo ""

# OpenAI
if prompt_yes_no "Configure OpenAI?" "n"; then
    echo ""
    echo "Enter your OpenAI API key (starts with sk-):"
    read -s OPENAI_KEY
    echo ""
    if [ -n "$OPENAI_KEY" ]; then
        replace_env_value "OPENAI_API_KEY" "$OPENAI_KEY"
        echo -e "${GREEN}✓${NC} OpenAI configured"
    else
        echo -e "${YELLOW}⚠️  No API key entered${NC}"
    fi
fi
echo ""

# Anthropic
if prompt_yes_no "Configure Anthropic?" "n"; then
    echo ""
    echo "Enter your Anthropic API key (starts with sk-ant-):"
    read -s ANTHROPIC_KEY
    echo ""
    if [ -n "$ANTHROPIC_KEY" ]; then
        replace_env_value "ANTHROPIC_API_KEY" "$ANTHROPIC_KEY"
        echo -e "${GREEN}✓${NC} Anthropic configured"
    else
        echo -e "${YELLOW}⚠️  No API key entered${NC}"
    fi
fi
echo ""

# OpenRouter
if prompt_yes_no "Configure OpenRouter?" "n"; then
    echo ""
    echo "Enter your OpenRouter API key (starts with sk-or-):"
    read -s OPENROUTER_KEY
    echo ""
    if [ -n "$OPENROUTER_KEY" ]; then
        replace_env_value "OPENROUTER_API_KEY" "$OPENROUTER_KEY"
        echo -e "${GREEN}✓${NC} OpenRouter configured"
    else
        echo -e "${YELLOW}⚠️  No API key entered${NC}"
    fi
fi
echo ""

echo -e "${BLUE}=== Step 4: SMTP Configuration (Optional) ===${NC}"
echo ""
if prompt_yes_no "Configure SMTP for email notifications?" "n"; then
    echo ""
    prompt_with_default "SMTP Host" "smtp.gmail.com" SMTP_HOST

    while true; do
        prompt_with_default "SMTP Port" "587" SMTP_PORT
        if validate_port "$SMTP_PORT"; then
            break
        else
            echo -e "${RED}✗ Invalid port number. Please enter a number between 1-65535.${NC}"
        fi
    done

    prompt_with_default "SMTP Username" "" SMTP_USER

    echo "SMTP Password:"
    read -s SMTP_PASS
    echo ""

    while true; do
        prompt_with_default "From Email Address" "$SMTP_USER" SMTP_ADMIN_EMAIL
        if validate_email "$SMTP_ADMIN_EMAIL"; then
            break
        else
            echo -e "${RED}✗ Invalid email format. Please try again.${NC}"
        fi
    done

    prompt_with_default "From Name" "AI Tool Server" SMTP_SENDER_NAME
    
    if prompt_yes_no "Use TLS?" "y"; then
        SMTP_USE_TLS="true"
    else
        SMTP_USE_TLS="false"
    fi
    
    replace_env_value "SMTP_HOST" "$SMTP_HOST"
    replace_env_value "SMTP_PORT" "$SMTP_PORT"
    replace_env_value "SMTP_USER" "$SMTP_USER"
    replace_env_value "SMTP_PASS" "$SMTP_PASS"
    replace_env_value "SMTP_ADMIN_EMAIL" "$SMTP_ADMIN_EMAIL"
    replace_env_value "SMTP_SENDER_NAME" "$SMTP_SENDER_NAME"
    replace_env_value "SMTP_USE_TLS" "$SMTP_USE_TLS"
    
    echo -e "${GREEN}✓${NC} SMTP configured"
else
    echo -e "${YELLOW}⚠️  Skipping SMTP configuration${NC}"
fi
echo ""

echo -e "${BLUE}=== Step 5: Generating Secure Secrets ===${NC}"
echo ""
echo "Generating 13 cryptographically secure secrets..."
echo ""

secrets=(
    "JWT_SECRET:JWT Secret"
    "SERVICE_ROLE_KEY:Service Role Key"
    "ANON_KEY:Anonymous Key"
    "WEBUI_SECRET_KEY:WebUI Secret Key"
    "PG_META_CRYPTO_KEY:PG Meta Crypto Key"
    "VAULT_ENC_KEY:Vault Encryption Key"
    "LOGFLARE_PUBLIC_ACCESS_TOKEN:Logflare Public Token"
    "LOGFLARE_PRIVATE_ACCESS_TOKEN:Logflare Private Token"
    "POSTGRES_PASSWORD:PostgreSQL Password"
    "LANGFLOW_DB_PASSWORD:Langflow DB Password"
    "DASHBOARD_PASSWORD:Dashboard Password"
    "MEILI_MASTER_KEY:Meilisearch Master Key"
)

counter=1
for secret_pair in "${secrets[@]}"; do
    IFS=':' read -r key name <<< "$secret_pair"
    value=$(generate_secret)
    replace_env_value "$key" "$value"
    echo -e "  ${counter}. ${GREEN}✓${NC} $name"
    ((counter++))
done

echo ""
echo "Generating SECRET_KEY_BASE (64 chars)..."
SECRET_KEY_BASE=$(generate_long_secret 64)
replace_env_value "SECRET_KEY_BASE" "$SECRET_KEY_BASE"
echo -e "  13. ${GREEN}✓${NC} Secret Key Base"
echo ""

# Set default app name
replace_env_value "WEBUI_NAME" "Open WebUI"

echo -e "${BLUE}=== Step 6: Meilisearch Configuration ===${NC}"
echo ""
echo "Meilisearch provides fast search for indexed documentation."
echo "Scrapix can automatically scrape and index websites into Meilisearch."
echo ""

if prompt_yes_no "Configure Meilisearch for document search?" "y"; then
    echo ""
    echo "Meilisearch Master Key has been generated automatically."
    echo ""

    if prompt_yes_no "Configure Scrapix to index documentation sites?" "y"; then
        echo ""
        echo "Creating scrapix.config.json from template..."

        # Check if config already exists
        if [ -f scrapix.config.json ]; then
            echo -e "${YELLOW}⚠️  scrapix.config.json already exists${NC}"
        else
            # Create config from template, replacing the placeholder
            sed "s/\${MEILI_MASTER_KEY}/$(grep MEILI_MASTER_KEY .env | cut -d '=' -f2)/g" \
                scrapix.config.json.template > scrapix.config.json
            echo -e "${GREEN}✓${NC} Created scrapix.config.json"
            echo ""
            echo "Default indexed sites:"
            echo "  • Open WebUI docs"
            echo "  • Anthropic/Claude docs"
            echo "  • OpenAI docs"
            echo "  • Meilisearch docs"
            echo ""
            echo "Edit scrapix.config.json to customize the list of sites to index."
        fi
    fi

    echo ""
    echo -e "${GREEN}✓${NC} Meilisearch configured"
    echo "   Access Meilisearch at http://localhost:7700"
    echo "   Run 'docker compose run scrapix' to index documentation"
    echo ""
    echo -e "${BLUE}ℹ  To use Meilisearch in Open WebUI:${NC}"
    echo "   1. Start the stack: docker compose up -d"
    echo "   2. Import the tool: Admin Panel → Tools → Import Tool"
    echo "   3. Upload: volumes/open-webui/tools/meilisearch_search.py"
    echo "   4. The tool will auto-configure from environment variables"
    MEILISEARCH_CONFIGURED=true
else
    echo -e "${YELLOW}⚠️${NC} Skipping Meilisearch configuration"
    MEILISEARCH_CONFIGURED=false
fi
echo ""

echo -e "${BLUE}=== Step 7: Generating Configuration ===${NC}"
echo ""
echo "Creating docker-compose.override.yml..."
echo ""

# Build override file content
OVERRIDE_CONTENT="# Auto-generated by setup.sh\n"
OVERRIDE_CONTENT+="# Optional configurations for AI providers, OAuth, and integrations\n\n"
OVERRIDE_CONTENT+="services:\n"

# Check if override file already exists
if [ -f docker-compose.override.yml ]; then
    echo -e "${YELLOW}⚠️  docker-compose.override.yml already exists!${NC}"
    read -p "Overwrite? This will backup the existing file. (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_file="docker-compose.override.yml.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✓${NC} Backing up to $backup_file"
        cp docker-compose.override.yml "$backup_file"
    else
        echo -e "${YELLOW}⚠️  Skipping override file creation${NC}"
        echo ""
        echo -e "${BLUE}ℹ${NC}  Continuing with existing docker-compose.override.yml"
        echo ""
        chmod 600 .env
        # Jump to completion section
        SKIP_OVERRIDE=true
    fi
fi

if [ "$SKIP_OVERRIDE" != true ]; then
    # Langflow configuration
    OVERRIDE_CONTENT+="\n  langflow:\n"
    OVERRIDE_CONTENT+="    environment:\n"

    # AI Provider API Keys
    if [ -n "$OLLAMA_URL" ]; then
        OVERRIDE_CONTENT+="      - OLLAMA_BASE_URL=\${OLLAMA_BASE_URL}\n"
    fi
    if [ -n "$OPENAI_KEY" ]; then
        OVERRIDE_CONTENT+="      - OPENAI_API_KEY=\${OPENAI_API_KEY}\n"
    fi
    if [ -n "$ANTHROPIC_KEY" ]; then
        OVERRIDE_CONTENT+="      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}\n"
    fi
    if [ -n "$OPENROUTER_KEY" ]; then
        OVERRIDE_CONTENT+="      - OPENROUTER_API_KEY=\${OPENROUTER_API_KEY}\n"
    fi

    # Supabase Integration
    OVERRIDE_CONTENT+="      - SUPABASE_URL=http://kong:8000\n"
    OVERRIDE_CONTENT+="      - SUPABASE_ANON_KEY=\${ANON_KEY}\n"
    OVERRIDE_CONTENT+="      - SUPABASE_SERVICE_KEY=\${SERVICE_ROLE_KEY}\n"
    OVERRIDE_CONTENT+="      - SUPABASE_DB_HOST=\${POSTGRES_HOST}\n"
    OVERRIDE_CONTENT+="      - SUPABASE_DB_PORT=\${POSTGRES_PORT}\n"
    OVERRIDE_CONTENT+="      - SUPABASE_DB_NAME=\${POSTGRES_DB}\n"
    OVERRIDE_CONTENT+="      - SUPABASE_DB_USER=postgres\n"
    OVERRIDE_CONTENT+="      - SUPABASE_DB_PASSWORD=\${POSTGRES_PASSWORD}\n"

    # Open WebUI configuration
    OVERRIDE_CONTENT+="\n  open-webui:\n"
    OVERRIDE_CONTENT+="    environment:\n"

    # AI Provider API Keys
    if [ -n "$OLLAMA_URL" ]; then
        OVERRIDE_CONTENT+="      - OLLAMA_BASE_URL=\${OLLAMA_BASE_URL}\n"
    fi
    if [ -n "$OPENAI_KEY" ]; then
        OVERRIDE_CONTENT+="      - OPENAI_API_KEY=\${OPENAI_API_KEY}\n"
    fi
    if [ -n "$ANTHROPIC_KEY" ]; then
        OVERRIDE_CONTENT+="      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}\n"
    fi
    if [ -n "$OPENROUTER_KEY" ]; then
        OVERRIDE_CONTENT+="      - OPENROUTER_API_KEY=\${OPENROUTER_API_KEY}\n"
    fi

    # OAuth Configuration (if configured)
    if [ -n "$OPENID_URL" ]; then
        OVERRIDE_CONTENT+="      - ENABLE_OAUTH_SIGNUP=\${ENABLE_OAUTH_SIGNUP}\n"
        OVERRIDE_CONTENT+="      - ENABLE_OAUTH_PERSISTENT_CONFIG=\${ENABLE_OAUTH_PERSISTENT_CONFIG}\n"
        OVERRIDE_CONTENT+="      - OAUTH_MERGE_ACCOUNTS_BY_EMAIL=\${OAUTH_MERGE_ACCOUNTS_BY_EMAIL}\n"
        OVERRIDE_CONTENT+="      - OAUTH_PROVIDER_NAME=\${OAUTH_PROVIDER_NAME}\n"
        OVERRIDE_CONTENT+="      - OPENID_PROVIDER_URL=\${OPENID_PROVIDER_URL}\n"
        OVERRIDE_CONTENT+="      - OAUTH_CLIENT_ID=\${OPEN_WEBUI_OAUTH_CLIENT_ID}\n"
        OVERRIDE_CONTENT+="      - OAUTH_CLIENT_SECRET=\${OPEN_WEBUI_OAUTH_CLIENT_SECRET}\n"
        OVERRIDE_CONTENT+="      - OAUTH_SCOPES=\${OAUTH_SCOPES}\n"
        OVERRIDE_CONTENT+="      - OPENID_REDIRECT_URI=\${OPEN_WEBUI_URL}/oauth/oidc/callback\n"
        OVERRIDE_CONTENT+="      - ENABLE_PASSWORD_AUTH=\${ENABLE_PASSWORD_AUTH}\n"
    fi

    # Supabase Integration
    OVERRIDE_CONTENT+="      - SUPABASE_URL=http://kong:8000\n"
    OVERRIDE_CONTENT+="      - SUPABASE_ANON_KEY=\${ANON_KEY}\n"

    # Meilisearch Integration (if configured)
    if [ "$MEILISEARCH_CONFIGURED" = true ]; then
        OVERRIDE_CONTENT+="      - MEILISEARCH_URL=http://meilisearch:7700\n"
        OVERRIDE_CONTENT+="      - MEILISEARCH_API_KEY=\${MEILI_MASTER_KEY}\n"
        OVERRIDE_CONTENT+="      - ENABLE_RAG_WEB_SEARCH=true\n"
    fi

    # PostgreSQL option
    if prompt_yes_no "Use PostgreSQL for Open WebUI instead of SQLite?" "n"; then
        OVERRIDE_CONTENT+="      - DATABASE_URL=postgresql://postgres:\${POSTGRES_PASSWORD}@db:5432/postgres\n"
        echo -e "${GREEN}✓${NC} PostgreSQL database configured"
    else
        echo -e "${BLUE}ℹ${NC}  Using SQLite (default)"
    fi

    # Write the override file
    echo -e "$OVERRIDE_CONTENT" > docker-compose.override.yml
    echo -e "${GREEN}✓${NC} Created docker-compose.override.yml"
    echo "   Optional configurations will be applied on 'docker compose up'"
fi
echo ""

# Set proper permissions
chmod 600 .env

echo -e "${GREEN}=============================================="
echo "✓ Setup Complete!"
echo -e "==============================================${NC}"
echo ""
echo "Your .env file has been created with:"
echo "  • 12 secure secrets (auto-generated)"
echo "  • Service URLs configured"
echo "  • AI backend configured"
if [ "$PRODUCTION" = true ]; then
    echo "  • Production URLs set"
fi
if [ -n "$SMTP_HOST" ]; then
    echo "  • SMTP configured"
fi
if [ -f docker-compose.override.yml ] && [ "$SKIP_OVERRIDE" != true ]; then
    echo "  • docker-compose.override.yml created with optional configs"
fi
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}NEXT STEPS:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Download required Supabase files:"
echo "   See README.md 'Create Required Supabase Files' section"
echo ""
echo "2. Start the stack:"
echo "   docker compose up -d"
echo ""
if [ "$MEILISEARCH_CONFIGURED" = true ]; then
    echo "3. Index documentation (optional):"
    echo "   docker compose run scrapix"
    echo ""
fi
echo "$([ "$MEILISEARCH_CONFIGURED" = true ] && echo "4" || echo "3"). Access services:"
echo "   • Open WebUI:      $OPEN_WEBUI_URL"
echo "   • Langflow:        $LANGFLOW_URL"
echo "   • Supabase Studio: $SITE_URL"
echo "   • Supabase API:    $SUPABASE_PUBLIC_URL"
if [ "$MEILISEARCH_CONFIGURED" = true ]; then
    echo "   • Meilisearch:     http://localhost:7700"
fi
if [ "$OAUTH_CONFIGURED" = true ]; then
    echo "   • OAuth Provider:  $OAUTH_URL"
fi
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "📚 Documentation:"
echo "   • Full guide:        README.md"
echo "   • Authentik setup:   EXTERNAL_AUTHENTIK_SETUP.md"
echo "   • Quick reference:   QUICK_REFERENCE.md"
echo "   • Troubleshooting:   TROUBLESHOOTING.md"
echo ""
echo -e "${GREEN}✓ .env file permissions set to 600 (secure)${NC}"
echo ""