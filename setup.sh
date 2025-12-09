#!/bin/bash

############################################################
# AI Tool Server Stack - Interactive Setup Script
############################################################
# Configures: Langflow, Open WebUI, Supabase, Meilisearch
# Optional: OAuth/OIDC SSO, AI Providers, SMTP
############################################################

set -e

# Enhanced color palette
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# Text formatting
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'

# Box drawing characters
BOX_H="━"
BOX_V="┃"
BOX_TL="┏"
BOX_TR="┓"
BOX_BL="┗"
BOX_BR="┛"
BOX_VR="┣"
BOX_VL="┫"
BOX_HU="┻"
BOX_HD="┳"

# Progress tracking
TOTAL_STEPS=7
CURRENT_STEP=0

# Clear screen and show header
clear
echo ""
echo -e "${CYAN}${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
echo -e "${CYAN}${BOX_V}${NC}                                                           ${CYAN}${BOX_V}${NC}"
echo -e "${CYAN}${BOX_V}${NC}     ${WHITE}${BOLD}🚀 AI Tool Server Stack - Interactive Setup${NC}      ${CYAN}${BOX_V}${NC}"
echo -e "${CYAN}${BOX_V}${NC}                                                           ${CYAN}${BOX_V}${NC}"
echo -e "${CYAN}${BOX_V}${NC}     ${DIM}Langflow • Open WebUI • Supabase • Meilisearch${NC}     ${CYAN}${BOX_V}${NC}"
echo -e "${CYAN}${BOX_V}${NC}                                                           ${CYAN}${BOX_V}${NC}"
echo -e "${CYAN}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_BR}${NC}"
echo ""

# TUI Helper Functions
print_step_header() {
    local step_num=$1
    local step_title=$2
    CURRENT_STEP=$step_num

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${BOLD}Step ${step_num}/${TOTAL_STEPS}:${NC} ${WHITE}${step_title}${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_subsection() {
    echo ""
    echo -e "${DIM}┌─ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

print_success() {
    echo -e "${GREEN}✓${NC}  $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "${RED}✗${NC}  $1"
}

print_separator() {
    echo -e "${GRAY}─────────────────────────────────────────────────────────────${NC}"
}

print_prompt() {
    echo -e "${CYAN}▸${NC} $1"
}

print_config_item() {
    local label=$1
    local value=$2
    echo -e "  ${DIM}${label}:${NC} ${WHITE}${value}${NC}"
}

# Pre-flight checks
echo -e "${MAGENTA}${BOX_TL}${BOX_H}${BOX_H}${BOX_H} Pre-flight Checks ${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${NC}"
echo ""

# Check for required commands
MISSING_COMMANDS=()
for cmd in openssl curl docker; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_COMMANDS+=("$cmd")
        print_error "$cmd not found"
    else
        print_success "$cmd found"
    fi
done

if [ ${#MISSING_COMMANDS[@]} -gt 0 ]; then
    echo ""
    print_error "Missing required dependencies"
    echo ""
    echo "Please install the missing dependencies and try again."
    exit 1
fi

# Check Docker is running
if ! docker info &> /dev/null 2>&1; then
    print_error "Docker is not running"
    echo ""
    echo "Please start Docker and try again."
    exit 1
else
    print_success "Docker is running"
fi

echo ""
print_separator
echo ""

# Check if .env already exists
if [ -f .env ]; then
    print_warning ".env file already exists!"
    read -p "Overwrite? This will backup the existing file. (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    backup_file=".env.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Backing up existing .env to $backup_file"
    cp .env "$backup_file"
fi

# Check if .env.template exists
if [ ! -f .env.template ]; then
    print_error "Error: .env.template not found!"
    exit 1
fi

print_success "Copying .env.template to .env..."
cp .env.template .env
echo ""

# Create required volume directories
print_info "Creating required volume directories..."
mkdir -p volumes/langflow/data volumes/langflow/db
mkdir -p volumes/open-webui/data volumes/open-webui/tools
mkdir -p volumes/playwright
mkdir -p volumes/meilisearch
mkdir -p volumes/db volumes/api volumes/functions volumes/logs volumes/pooler volumes/storage

# Set proper permissions for Langflow data directory
# Langflow container runs as non-root user and needs write access
chmod -R 777 volumes/langflow/data

print_success "Volume directories created"
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

print_step_header 1 "OAuth/OIDC Configuration (Optional)"

print_info "Configure Single Sign-On (SSO) with OAuth/OIDC providers"
echo -e "  ${DIM}Supported: Authentik, Keycloak, Google, Azure AD, etc.${NC}"
echo ""

OAUTH_CONFIGURED=false
if prompt_yes_no "Configure OAuth/OIDC for SSO?" "n"; then
    OAUTH_CONFIGURED=true
    echo ""
    print_subsection "OAuth Provider Settings"
    echo ""
    echo -e "  ${DIM}Examples:${NC}"
    echo -e "  ${DIM}• https://auth.yourdomain.com${NC}"
    echo -e "  ${DIM}• https://keycloak.yourdomain.com/realms/myrealm${NC}"
    echo ""
    while true; do
        print_prompt "OAuth Provider Base URL"
        prompt_with_default "" "http://localhost:9000" OAUTH_URL
        if validate_url "$OAUTH_URL"; then
            replace_env_value "OAUTH_PROVIDER_URL" "$OAUTH_URL"
            break
        else
            print_error "Invalid URL format"
        fi
    done

    # Open WebUI OAuth Configuration
    echo ""
    print_prompt "OAuth Provider Name (shown to users)"
    prompt_with_default "" "SSO" OAUTH_NAME
    replace_env_value "OAUTH_PROVIDER_NAME" "$OAUTH_NAME"

    echo ""
    print_subsection "OpenID Configuration"
    echo ""
    echo -e "  ${DIM}Examples:${NC}"
    echo -e "  ${DIM}• Authentik: ${OAUTH_URL}/application/o/open-webui/.well-known/openid-configuration${NC}"
    echo -e "  ${DIM}• Keycloak: Include realm in base URL above${NC}"
    echo ""
    print_prompt "OpenID Provider URL"
    prompt_with_default "" "" OPENID_URL
    if [ -n "$OPENID_URL" ]; then
        replace_env_value "OPENID_PROVIDER_URL" "$OPENID_URL"
    fi

    echo ""
    print_subsection "Client Credentials"
    echo ""
    print_prompt "OAuth Client ID"
    prompt_with_default "" "" OAUTH_CLIENT_ID
    replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_ID" "$OAUTH_CLIENT_ID"

    echo ""
    print_prompt "OAuth Client Secret (hidden)"
    read -s OAUTH_CLIENT_SECRET
    echo ""
    replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_SECRET" "$OAUTH_CLIENT_SECRET"

    # Set sensible OAuth defaults
    replace_env_value "ENABLE_OAUTH_SIGNUP" "true"
    replace_env_value "ENABLE_OAUTH_PERSISTENT_CONFIG" "true"
    replace_env_value "OAUTH_MERGE_ACCOUNTS_BY_EMAIL" "true"
    replace_env_value "OAUTH_SCOPES" "openid email profile"
    replace_env_value "ENABLE_PASSWORD_AUTH" "true"

    echo ""
    print_success "OAuth/OIDC configured successfully"
else
    print_info "Skipping OAuth configuration - using local authentication only"
fi
echo ""

print_step_header 2 "Service URLs"

print_info "Configure URLs for your services (for OAuth callbacks and production)"
echo ""

if prompt_yes_no "Is this a production deployment?" "n"; then
    PRODUCTION=true
    echo ""
    prompt_with_default "Your domain name" "yourdomain.com" DOMAIN

    OPEN_WEBUI_URL="https://chat.${DOMAIN}"
    LANGFLOW_URL="https://flow.${DOMAIN}"
    SUPABASE_PUBLIC_URL="https://db-api.${DOMAIN}"
    API_EXTERNAL_URL="https://db-api.${DOMAIN}"
    SITE_URL="https://db-admin.${DOMAIN}"

    echo ""
    print_info "Auto-configured URLs:"
    echo ""
    print_config_item "Open WebUI      " "$OPEN_WEBUI_URL"
    print_config_item "Langflow        " "$LANGFLOW_URL"
    print_config_item "Supabase API    " "$SUPABASE_PUBLIC_URL"
    print_config_item "Supabase Studio " "$SITE_URL"
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

    print_success "Using localhost URLs for development"
fi

replace_env_value "OPEN_WEBUI_URL" "$OPEN_WEBUI_URL"
replace_env_value "LANGFLOW_URL" "$LANGFLOW_URL"
replace_env_value "SUPABASE_PUBLIC_URL" "$SUPABASE_PUBLIC_URL"
replace_env_value "API_EXTERNAL_URL" "$API_EXTERNAL_URL"
replace_env_value "SITE_URL" "$SITE_URL"
echo ""

print_step_header 3 "AI Model Backend Configuration"

print_info "Configure AI providers (you can configure multiple)"
echo ""

# Ollama
print_subsection "Ollama (Local Models)"
if prompt_yes_no "Configure Ollama?" "n"; then
    echo ""
    print_prompt "Ollama URL"
    prompt_with_default "" "http://host.docker.internal:11434" OLLAMA_URL
    replace_env_value "OLLAMA_BASE_URL" "$OLLAMA_URL"
    print_success "Ollama configured"
fi

# OpenAI
print_subsection "OpenAI"
if prompt_yes_no "Configure OpenAI?" "n"; then
    echo ""
    print_prompt "Enter your OpenAI API key (starts with sk-)"
    read -s OPENAI_KEY
    echo ""
    if [ -n "$OPENAI_KEY" ]; then
        replace_env_value "OPENAI_API_KEY" "$OPENAI_KEY"
        print_success "OpenAI configured"
    else
        print_warning "No API key entered"
    fi
fi

# Anthropic
print_subsection "Anthropic (Claude)"
if prompt_yes_no "Configure Anthropic?" "n"; then
    echo ""
    print_prompt "Enter your Anthropic API key (starts with sk-ant-)"
    read -s ANTHROPIC_KEY
    echo ""
    if [ -n "$ANTHROPIC_KEY" ]; then
        replace_env_value "ANTHROPIC_API_KEY" "$ANTHROPIC_KEY"
        print_success "Anthropic configured"
    else
        print_warning "No API key entered"
    fi
fi

# OpenRouter
print_subsection "OpenRouter (Multi-Provider)"
if prompt_yes_no "Configure OpenRouter?" "n"; then
    echo ""
    print_prompt "Enter your OpenRouter API key (starts with sk-or-)"
    read -s OPENROUTER_KEY
    echo ""
    if [ -n "$OPENROUTER_KEY" ]; then
        replace_env_value "OPENROUTER_API_KEY" "$OPENROUTER_KEY"
        print_success "OpenRouter configured"
    else
        print_warning "No API key entered"
    fi
fi
echo ""

print_step_header 4 "SMTP Configuration (Optional)"

if prompt_yes_no "Configure SMTP for email notifications?" "n"; then
    echo ""
    prompt_with_default "SMTP Host" "smtp.gmail.com" SMTP_HOST

    while true; do
        prompt_with_default "SMTP Port" "587" SMTP_PORT
        if validate_port "$SMTP_PORT"; then
            break
        else
            print_error "Invalid port number. Please enter a number between 1-65535"
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
            print_error "Invalid email format. Please try again"
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

    print_success "SMTP configured"
else
    print_info "Skipping SMTP configuration"
fi
echo ""

print_step_header 5 "Generating Secure Secrets"

print_info "Generating 13 cryptographically secure secrets..."
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

total_secrets=$((${#secrets[@]} + 1))
counter=1

for secret_pair in "${secrets[@]}"; do
    IFS=':' read -r key name <<< "$secret_pair"
    value=$(generate_secret)
    replace_env_value "$key" "$value"
    echo -e "  ${DIM}[${counter}/${total_secrets}]${NC} ${GREEN}✓${NC} $name"
    ((counter++))
done

echo ""
SECRET_KEY_BASE=$(generate_long_secret 64)
replace_env_value "SECRET_KEY_BASE" "$SECRET_KEY_BASE"
echo -e "  ${DIM}[${counter}/${total_secrets}]${NC} ${GREEN}✓${NC} Secret Key Base (64 chars)"
echo ""

print_success "All secrets generated securely"
echo ""

# Set default app name
replace_env_value "WEBUI_NAME" "Open WebUI"

print_step_header 6 "Meilisearch Configuration"

print_info "Meilisearch provides fast search for indexed documentation"
echo "  Scrapix can automatically scrape and index websites into Meilisearch"
echo ""

if prompt_yes_no "Configure Meilisearch for document search?" "y"; then
    echo ""
    print_success "Meilisearch Master Key has been generated automatically"
    echo ""

    if prompt_yes_no "Configure Scrapix to index documentation sites?" "y"; then
        echo ""
        print_info "Creating scrapix.config.json from template..."

        # Check if config already exists
        if [ -f scrapix.config.json ]; then
            print_warning "scrapix.config.json already exists"
        else
            # Create config from template, replacing the placeholder
            sed "s/\${MEILI_MASTER_KEY}/$(grep MEILI_MASTER_KEY .env | cut -d '=' -f2)/g" \
                scrapix.config.json.template > scrapix.config.json
            print_success "Created scrapix.config.json"
            echo ""
            echo "Default indexed sites:"
            echo "  • Open WebUI docs"
            echo "  • Anthropic/Claude docs"
            echo "  • OpenAI docs"
            echo "  • Meilisearch docs"
            echo ""
            print_info "Edit scrapix.config.json to customize the list of sites to index"
        fi
    fi

    echo ""
    print_success "Meilisearch configured"
    echo ""
    print_config_item "Web Interface" "http://localhost:7700"
    print_config_item "Index Command" "docker compose run scrapix"
    echo ""
    print_info "To use Meilisearch in Open WebUI:"
    echo -e "   ${DIM}1.${NC} Start the stack: ${DIM}docker compose up -d${NC}"
    echo -e "   ${DIM}2.${NC} Import the tool: ${DIM}Admin Panel → Tools → Import Tool${NC}"
    echo -e "   ${DIM}3.${NC} Upload: ${DIM}volumes/open-webui/tools/meilisearch_search.py${NC}"
    echo -e "   ${DIM}4.${NC} The tool will auto-configure from environment variables"
    MEILISEARCH_CONFIGURED=true
else
    print_info "Skipping Meilisearch configuration"
    MEILISEARCH_CONFIGURED=false
fi
echo ""

print_step_header 7 "Generating Configuration"

print_info "Creating docker-compose.override.yml..."
echo ""

# Build override file content
OVERRIDE_CONTENT="# Auto-generated by setup.sh\n"
OVERRIDE_CONTENT+="# Optional configurations for AI providers, OAuth, and integrations\n\n"
OVERRIDE_CONTENT+="services:\n"

# Check if override file already exists
if [ -f docker-compose.override.yml ]; then
    print_warning "docker-compose.override.yml already exists!"
    read -p "Overwrite? This will backup the existing file. (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        backup_file="docker-compose.override.yml.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Backing up to $backup_file"
        cp docker-compose.override.yml "$backup_file"
    else
        print_warning "Skipping override file creation"
        echo ""
        print_info "Continuing with existing docker-compose.override.yml"
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
        print_success "PostgreSQL database configured"
    else
        print_info "Using SQLite (default)"
    fi

    # Write the override file
    echo -e "$OVERRIDE_CONTENT" > docker-compose.override.yml
    print_success "Created docker-compose.override.yml"
    echo "   Optional configurations will be applied on 'docker compose up'"
fi
echo ""

# Set proper permissions
chmod 600 .env

echo ""
print_separator
echo ""
echo -e "${GREEN}${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║                    ✓ Setup Complete!                     ║${NC}"
echo -e "${GREEN}${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Configuration Summary
echo -e "${CYAN}${BOLD}Configuration Summary${NC}"
echo ""
print_config_item "Secrets Generated   " "13 cryptographically secure keys"
print_config_item "Environment File    " ".env (permissions: 600)"

if [ "$PRODUCTION" = true ]; then
    print_config_item "Deployment Mode     " "Production (${DOMAIN})"
else
    print_config_item "Deployment Mode     " "Development (localhost)"
fi

if [ "$OAUTH_CONFIGURED" = true ]; then
    print_config_item "Authentication      " "OAuth/OIDC + Local"
else
    print_config_item "Authentication      " "Local only"
fi

# Count configured AI providers
AI_PROVIDERS=""
[ -n "$OLLAMA_URL" ] && AI_PROVIDERS="${AI_PROVIDERS}Ollama, "
[ -n "$OPENAI_KEY" ] && AI_PROVIDERS="${AI_PROVIDERS}OpenAI, "
[ -n "$ANTHROPIC_KEY" ] && AI_PROVIDERS="${AI_PROVIDERS}Anthropic, "
[ -n "$OPENROUTER_KEY" ] && AI_PROVIDERS="${AI_PROVIDERS}OpenRouter, "
AI_PROVIDERS=${AI_PROVIDERS%, }
if [ -n "$AI_PROVIDERS" ]; then
    print_config_item "AI Providers        " "$AI_PROVIDERS"
else
    print_config_item "AI Providers        " "None (configure manually)"
fi

if [ -n "$SMTP_HOST" ]; then
    print_config_item "Email Notifications " "Enabled (${SMTP_HOST})"
else
    print_config_item "Email Notifications " "Disabled"
fi

if [ "$MEILISEARCH_CONFIGURED" = true ]; then
    print_config_item "Document Search     " "Meilisearch enabled"
else
    print_config_item "Document Search     " "Not configured"
fi

if [ -f docker-compose.override.yml ] && [ "$SKIP_OVERRIDE" != true ]; then
    print_config_item "Override File       " "docker-compose.override.yml created"
fi

echo ""
print_separator
echo ""
echo -e "${CYAN}${BOLD}Next Steps${NC}"
echo ""
echo -e "${YELLOW}▸${NC} ${BOLD}1. Download Supabase Files${NC}"
echo -e "   ${DIM}See README.md 'Create Required Supabase Files' section${NC}"
echo ""
echo -e "${YELLOW}▸${NC} ${BOLD}2. Start the Stack${NC}"
echo -e "   ${CYAN}docker compose up -d${NC}"
echo ""
if [ "$MEILISEARCH_CONFIGURED" = true ]; then
    echo -e "${YELLOW}▸${NC} ${BOLD}3. Index Documentation${NC} ${DIM}(optional)${NC}"
    echo -e "   ${CYAN}docker compose run scrapix${NC}"
    echo ""
fi
echo -e "${YELLOW}▸${NC} ${BOLD}$([ "$MEILISEARCH_CONFIGURED" = true ] && echo "4" || echo "3"). Access Your Services${NC}"
echo ""
print_config_item "Open WebUI      " "$OPEN_WEBUI_URL"
print_config_item "Langflow        " "$LANGFLOW_URL"
print_config_item "Supabase Studio " "$SITE_URL"
print_config_item "Supabase API    " "$SUPABASE_PUBLIC_URL"
if [ "$MEILISEARCH_CONFIGURED" = true ]; then
    print_config_item "Meilisearch     " "http://localhost:7700"
fi
if [ "$OAUTH_CONFIGURED" = true ]; then
    print_config_item "OAuth Provider  " "$OAUTH_URL"
fi
echo ""
print_separator
echo ""
echo -e "${MAGENTA}${BOLD}📚 Documentation${NC}"
echo ""
print_config_item "Full Guide      " "README.md"
print_config_item "Authentik Setup " "docs/EXTERNAL_AUTHENTIK_SETUP.md"
print_config_item "Quick Reference " "docs/QUICK_REFERENCE.md"
print_config_item "Troubleshooting " "docs/TROUBLESHOOTING.md"
echo ""
print_success "Setup completed successfully!"
echo ""