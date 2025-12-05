#!/bin/bash

############################################################
# AI Tool Server Stack with External Authentik SSO
# Interactive Setup Script
############################################################
# This script creates a production-ready .env file
############################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=============================================="
echo "AI Tool Server Stack - Interactive Setup"
echo "with External Authentik SSO Integration"
echo -e "==============================================${NC}"
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

# Function to generate a random secret (alphanumeric only for safety)
generate_secret() {
    openssl rand -hex 16
}

# Function to generate a longer secret
generate_long_secret() {
    local length=$1
    openssl rand -hex $(($length / 2))
}

# Function to replace a value in .env (safely handles special characters)
replace_env_value() {
    local key=$1
    local value=$2
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|^${key}=.*|${key}=${value}|" .env
    else
        # Linux
        sed -i "s|^${key}=.*|${key}=${value}|" .env
    fi
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

echo -e "${BLUE}=== Step 1: External Authentik Configuration ===${NC}"
echo ""
echo "Enter the URL of your existing Authentik instance."
echo "Examples:"
echo "  - https://auth.yourdomain.com"
echo "  - http://192.168.1.100:9000"
echo "  - http://host.docker.internal:9000 (if Authentik on same Docker host)"
echo ""
prompt_with_default "Authentik URL" "http://localhost:9000" AUTHENTIK_URL
replace_env_value "AUTHENTIK_URL" "$AUTHENTIK_URL"
echo -e "${GREEN}✓${NC} Authentik URL set"
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
    SUPABASE_PUBLIC_URL="https://api.${DOMAIN}"
    API_EXTERNAL_URL="https://api.${DOMAIN}"
    SITE_URL="https://studio.${DOMAIN}"
    
    echo ""
    echo "Auto-configured URLs:"
    echo "  Open WebUI:      $OPEN_WEBUI_URL"
    echo "  Langflow:        $LANGFLOW_URL"
    echo "  Supabase API:    $SUPABASE_PUBLIC_URL"
    echo "  Studio:          $SITE_URL"
    echo ""
    
    if prompt_yes_no "Customize these URLs?" "n"; then
        prompt_with_default "Open WebUI URL" "$OPEN_WEBUI_URL" OPEN_WEBUI_URL
        prompt_with_default "Langflow URL" "$LANGFLOW_URL" LANGFLOW_URL
        prompt_with_default "Supabase API URL" "$SUPABASE_PUBLIC_URL" SUPABASE_PUBLIC_URL
        prompt_with_default "Studio URL" "$SITE_URL" SITE_URL
        API_EXTERNAL_URL="$SUPABASE_PUBLIC_URL"
    fi
else
    PRODUCTION=false
    OPEN_WEBUI_URL="http://localhost:8080"
    LANGFLOW_URL="http://localhost:7860"
    SUPABASE_PUBLIC_URL="http://localhost:8000"
    API_EXTERNAL_URL="http://localhost:8000"
    SITE_URL="http://localhost:3000"
    
    echo -e "${GREEN}✓${NC} Using localhost URLs for development"
fi

replace_env_value "OPEN_WEBUI_URL" "$OPEN_WEBUI_URL"
replace_env_value "LANGFLOW_URL" "$LANGFLOW_URL"
replace_env_value "SUPABASE_PUBLIC_URL" "$SUPABASE_PUBLIC_URL"
replace_env_value "API_EXTERNAL_URL" "$API_EXTERNAL_URL"
replace_env_value "SITE_URL" "$SITE_URL"
echo ""

echo -e "${BLUE}=== Step 3: AI Model Backend ===${NC}"
echo ""
echo "Which AI backend will you use?"
echo "  1) Ollama (local)"
echo "  2) OpenAI API"
echo "  3) Both"
echo "  4) Neither (configure later)"
echo ""
read -p "Select [1-4]: " AI_BACKEND

case $AI_BACKEND in
    1)
        echo ""
        prompt_with_default "Ollama URL" "http://host.docker.internal:11434" OLLAMA_URL
        replace_env_value "OLLAMA_BASE_URL" "$OLLAMA_URL"
        echo -e "${GREEN}✓${NC} Ollama configured"
        ;;
    2)
        echo ""
        echo "Enter your OpenAI API key (starts with sk-):"
        read -s OPENAI_KEY
        echo ""
        if [ -n "$OPENAI_KEY" ]; then
            replace_env_value "OPENAI_API_KEY" "$OPENAI_KEY"
            echo -e "${GREEN}✓${NC} OpenAI API key configured"
        else
            echo -e "${YELLOW}⚠️  No API key entered${NC}"
        fi
        ;;
    3)
        echo ""
        prompt_with_default "Ollama URL" "http://host.docker.internal:11434" OLLAMA_URL
        replace_env_value "OLLAMA_BASE_URL" "$OLLAMA_URL"
        
        echo ""
        echo "Enter your OpenAI API key (starts with sk-):"
        read -s OPENAI_KEY
        echo ""
        if [ -n "$OPENAI_KEY" ]; then
            replace_env_value "OPENAI_API_KEY" "$OPENAI_KEY"
            echo -e "${GREEN}✓${NC} Both backends configured"
        fi
        ;;
    *)
        echo -e "${YELLOW}⚠️  Skipping AI backend configuration${NC}"
        ;;
esac
echo ""

echo -e "${BLUE}=== Step 4: SMTP Configuration (Optional) ===${NC}"
echo ""
if prompt_yes_no "Configure SMTP for email notifications?" "n"; then
    echo ""
    prompt_with_default "SMTP Host" "smtp.gmail.com" SMTP_HOST
    prompt_with_default "SMTP Port" "587" SMTP_PORT
    prompt_with_default "SMTP Username/Email" "" SMTP_USER
    echo "SMTP Password:"
    read -s SMTP_PASS
    echo ""
    prompt_with_default "From Email Address" "$SMTP_USER" SMTP_ADMIN_EMAIL
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
echo "Generating 12 cryptographically secure secrets..."
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
echo -e "  12. ${GREEN}✓${NC} Secret Key Base"
echo ""

echo -e "${BLUE}=== Step 6: Authentik OAuth Configuration ===${NC}"
echo ""
echo "You need to configure OAuth providers in your Authentik instance."
echo ""
echo -e "${YELLOW}After starting the stack, follow these steps:${NC}"
echo ""
echo "1. Log into Authentik: $AUTHENTIK_URL"
echo "2. Go to Admin Interface > Applications > Providers"
echo "3. Create OAuth2/OpenID Provider for Open WebUI:"
echo "   - Redirect URI: ${OPEN_WEBUI_URL}/oauth/oidc/callback"
echo "4. Copy the Client ID and Client Secret"
echo ""

if prompt_yes_no "Do you already have OAuth credentials from Authentik?" "n"; then
    echo ""
    prompt_with_default "Open WebUI OAuth Client ID" "" OPEN_WEBUI_CLIENT_ID
    
    if [ -n "$OPEN_WEBUI_CLIENT_ID" ]; then
        replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_ID" "$OPEN_WEBUI_CLIENT_ID"
        
        echo "Open WebUI OAuth Client Secret:"
        read -s OPEN_WEBUI_CLIENT_SECRET
        echo ""
        
        if [ -n "$OPEN_WEBUI_CLIENT_SECRET" ]; then
            replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_SECRET" "$OPEN_WEBUI_CLIENT_SECRET"
            echo -e "${GREEN}✓${NC} OAuth credentials configured"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  You'll need to configure OAuth later${NC}"
    echo "   Update these in .env after creating the provider:"
    echo "   - OPEN_WEBUI_OAUTH_CLIENT_ID"
    echo "   - OPEN_WEBUI_OAUTH_CLIENT_SECRET"
fi
echo ""

echo -e "${BLUE}=== Step 7: Additional Configuration ===${NC}"
echo ""

if prompt_yes_no "Disable local login (SSO only for Open WebUI)?" "n"; then
    replace_env_value "ENABLE_LOCAL_LOGIN" "false"
    echo -e "${GREEN}✓${NC} Local login disabled (SSO only)"
else
    replace_env_value "ENABLE_LOCAL_LOGIN" "true"
    echo -e "${GREEN}✓${NC} Local login enabled"
fi
echo ""

if prompt_yes_no "Enable OAuth signup for new users?" "y"; then
    replace_env_value "ENABLE_OAUTH_SIGNUP" "true"
    echo -e "${GREEN}✓${NC} OAuth signup enabled"
else
    replace_env_value "ENABLE_OAUTH_SIGNUP" "false"
    echo -e "${YELLOW}⚠️${NC} OAuth signup disabled"
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
if [ -z "$OPEN_WEBUI_CLIENT_ID" ]; then
    echo "3. Configure OAuth in Authentik ($AUTHENTIK_URL):"
    echo "   - Create OAuth2 Provider for Open WebUI"
    echo "   - Redirect URI: ${OPEN_WEBUI_URL}/oauth/oidc/callback"
    echo "   - Update .env with Client ID and Secret"
    echo "   - Restart: docker compose restart open-webui"
    echo ""
fi
echo "4. Access services:"
echo "   • Authentik:       $AUTHENTIK_URL"
echo "   • Open WebUI:      $OPEN_WEBUI_URL"
echo "   • Langflow:        $LANGFLOW_URL"
echo "   • Supabase Studio: $SITE_URL"
echo "   • Supabase API:    $SUPABASE_PUBLIC_URL"
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