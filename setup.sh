#!/bin/bash

############################################################
# AI Tool Server Stack with External Authentik SSO
# Setup Script
############################################################
# This script helps you generate secure secrets and
# create your .env file from the template
############################################################

set -e

echo "=============================================="
echo "AI Tool Server Stack - Initial Setup"
echo "with External Authentik SSO Integration"
echo "=============================================="
echo ""

# Check if .env already exists
if [ -f .env ]; then
    read -p ".env file already exists. Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled."
        exit 0
    fi
    echo "Backing up existing .env to .env.backup"
    cp .env .env.backup
fi

# Check if .env.template exists
if [ ! -f .env.template ]; then
    echo "Error: .env.template not found!"
    exit 1
fi

echo "Copying .env.template to .env..."
cp .env.template .env

echo ""
echo "Generating secure secrets..."
echo ""

# Function to generate a random secret
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Function to generate a longer secret
generate_long_secret() {
    local length=$1
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to replace a value in .env
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

echo "=== Supabase/Langflow Secrets ==="
echo "1. JWT Secret..."
JWT_SECRET=$(generate_secret)
replace_env_value "JWT_SECRET" "$JWT_SECRET"

echo "2. Service Role Key (using JWT Secret)..."
replace_env_value "SERVICE_ROLE_KEY" "$JWT_SECRET"

echo "3. Anonymous Key..."
ANON_KEY=$(generate_secret)
replace_env_value "ANON_KEY" "$ANON_KEY"

echo "4. WebUI Secret Key..."
WEBUI_SECRET=$(generate_secret)
replace_env_value "WEBUI_SECRET_KEY" "$WEBUI_SECRET"

echo "5. Secret Key Base (64 chars)..."
SECRET_KEY_BASE=$(generate_long_secret 64)
replace_env_value "SECRET_KEY_BASE" "$SECRET_KEY_BASE"

echo "6. PG Meta Crypto Key..."
PG_META_CRYPTO=$(generate_secret)
replace_env_value "PG_META_CRYPTO_KEY" "$PG_META_CRYPTO"

echo "7. Vault Encryption Key..."
VAULT_ENC=$(generate_secret)
replace_env_value "VAULT_ENC_KEY" "$VAULT_ENC"

echo "8. Logflare Public Token..."
LOGFLARE_PUBLIC=$(generate_secret)
replace_env_value "LOGFLARE_PUBLIC_ACCESS_TOKEN" "$LOGFLARE_PUBLIC"

echo "9. Logflare Private Token..."
LOGFLARE_PRIVATE=$(generate_secret)
replace_env_value "LOGFLARE_PRIVATE_ACCESS_TOKEN" "$LOGFLARE_PRIVATE"

echo ""
echo "=== Database Passwords ==="
echo "10. PostgreSQL Password..."
POSTGRES_PASS=$(generate_secret)
replace_env_value "POSTGRES_PASSWORD" "$POSTGRES_PASS"

echo "11. Langflow Database Password..."
LANGFLOW_PASS=$(generate_secret)
replace_env_value "LANGFLOW_DB_PASSWORD" "$LANGFLOW_PASS"

echo "12. Dashboard Password..."
DASHBOARD_PASS=$(generate_secret)
replace_env_value "DASHBOARD_PASSWORD" "$DASHBOARD_PASS"

echo ""
echo "=============================================="
echo "Setup Complete!"
echo "=============================================="
echo ""
echo "Your .env file has been created with secure secrets."
echo ""
echo "CRITICAL NEXT STEPS:"
echo ""
echo "1. Update AUTHENTIK_URL in .env:"
echo "   Point to your existing Authentik instance"
echo "   Example: AUTHENTIK_URL=https://auth.yourdomain.com"
echo "   Or: AUTHENTIK_URL=http://192.168.1.100:9000"
echo ""
echo "2. Update other URLs in .env:"
echo "   - OPEN_WEBUI_URL"
echo "   - LANGFLOW_URL"
echo "   - SUPABASE_PUBLIC_URL"
echo "   - SMTP settings (if using email)"
echo ""
echo "3. Download required Supabase files:"
echo "   See README.md 'Create Required Supabase Files' section"
echo ""
echo "4. Start the stack:"
echo "   docker compose up -d"
echo ""
echo "5. Configure OAuth in your Authentik instance:"
echo "   a. Log into your Authentik at: \${AUTHENTIK_URL}"
echo "   b. Admin Interface > Applications > Providers"
echo "   c. Create OAuth2/OpenID Provider for Open WebUI"
echo "      - Redirect URI: http://localhost:8080/oauth/oidc/callback"
echo "   d. Create Application linked to the provider"
echo "   e. Copy Client ID and Client Secret"
echo ""
echo "6. Add OAuth credentials to .env:"
echo "   OPEN_WEBUI_OAUTH_CLIENT_ID=<from Authentik>"
echo "   OPEN_WEBUI_OAUTH_CLIENT_SECRET=<from Authentik>"
echo ""
echo "7. Restart Open WebUI:"
echo "   docker compose restart open-webui"
echo ""
echo "8. Test SSO login at http://localhost:8080"
echo ""
echo "=============================================="
echo "Service URLs (after starting):"
echo "=============================================="
echo "  - Authentik:         \${AUTHENTIK_URL} (external)"
echo "  - Langflow:          http://localhost:7860"
echo "  - Open WebUI:        http://localhost:8080"
echo "  - Supabase Studio:   http://localhost:3000"
echo "  - Supabase API:      http://localhost:8000"
echo ""
echo "See AUTHENTIK_SSO_GUIDE.md for detailed OAuth setup!"
echo ""

# Set proper permissions
chmod 600 .env

echo "✓ .env file permissions set to 600 (owner read/write only)"
echo ""