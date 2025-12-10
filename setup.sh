#!/bin/bash

############################################################
# AI Tool Server Stack - Interactive Setup Script
############################################################
# Configures: Langflow, Open WebUI, Supabase, Meilisearch
# Optional: OAuth/OIDC SSO, AI Providers, SMTP
############################################################

set -e

# Progress tracking
TOTAL_STEPS=7
CURRENT_STEP=0

# Whiptail is now a required dependency (checked in pre-flight)

# Welcome screen
whiptail --title "AI Tool Server Stack - Setup Wizard" \
         --msgbox "\n🚀  Welcome to AI Tool Server Stack Installation  🚀\n\nThis wizard will guide you through configuring:\n\n  • Langflow - AI workflow automation\n  • Open WebUI - Chat interface\n  • Supabase - Backend infrastructure\n  • Meilisearch - Document search\n\nThe setup will take approximately 5 minutes.\n\nPress OK to begin." \
         18 70

# Pre-flight checks
PREFLIGHT_OUTPUT=""
PREFLIGHT_FAILED=false

# Check for required commands
for cmd in openssl curl docker whiptail; do
    if ! command -v $cmd &> /dev/null; then
        PREFLIGHT_OUTPUT+="✗ $cmd - NOT FOUND\n"
        PREFLIGHT_FAILED=true
    else
        PREFLIGHT_OUTPUT+="✓ $cmd - Found\n"
    fi
done

# Check Docker is running
if ! docker info &> /dev/null 2>&1; then
    PREFLIGHT_OUTPUT+="✗ Docker - NOT RUNNING\n"
    PREFLIGHT_FAILED=true
else
    PREFLIGHT_OUTPUT+="✓ Docker - Running\n"
fi

if [ "$PREFLIGHT_FAILED" = true ]; then
    whiptail --title "Pre-flight Check Failed" \
             --msgbox "Some required dependencies are missing or not running:\n\n$PREFLIGHT_OUTPUT\nPlease install missing dependencies:\n\nUbuntu/Debian: sudo apt-get install <package>\nCentOS/RHEL:   sudo yum install <package>\nmacOS:         brew install <package>" \
             20 70
    exit 1
else
    whiptail --title "Pre-flight Checks" \
             --msgbox "All pre-flight checks passed!\n\n$PREFLIGHT_OUTPUT\nReady to proceed with installation." \
             16 70
fi

# Check if .env already exists
if [ -f .env ]; then
    if whiptail --title "Existing Configuration" \
                --yesno ".env file already exists!\n\nDo you want to overwrite it?\n\nThe existing file will be backed up." \
                12 60; then
        backup_file=".env.backup.$(date +%Y%m%d_%H%M%S)"
        cp .env "$backup_file"
        whiptail --title "Backup Created" --msgbox "Existing .env backed up to:\n$backup_file" 10 60
    else
        whiptail --title "Setup Cancelled" --msgbox "Setup cancelled by user." 8 40
        exit 0
    fi
fi

# Check if .env.template exists
if [ ! -f .env.template ]; then
    whiptail --title "Error" --msgbox "Error: .env.template not found!\n\nPlease ensure you're running this script from the project root directory." 10 60
    exit 1
fi

# Create environment and directories with progress
{
    echo "0"; sleep 0.2
    cp .env.template .env
    echo "20"; sleep 0.2
    mkdir -p volumes/langflow/data volumes/langflow/db
    echo "40"; sleep 0.2
    mkdir -p volumes/open-webui/data volumes/open-webui/tools
    echo "60"; sleep 0.2
    mkdir -p volumes/playwright volumes/meilisearch
    echo "80"; sleep 0.2
    mkdir -p volumes/db volumes/api volumes/functions volumes/logs volumes/pooler volumes/storage
    chmod -R 770 volumes/langflow/data
    echo "100"; sleep 0.2
} | whiptail --title "Initializing" --gauge "Creating environment and volume directories..." 8 70 0

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

    # Escape special characters for sed (order matters!)
    # 1. Backslash first (so we don't re-escape our own escapes)
    # 2. Then ampersand (sed replacement special char)
    # 3. Then pipe (our delimiter)
    local escaped_value="$value"
    escaped_value="${escaped_value//\\/\\\\}"  # \ -> \\
    escaped_value="${escaped_value//&/\\&}"    # & -> \&
    escaped_value="${escaped_value//|/\\|}"    # | -> \|

    sed "${SED_INPLACE[@]}" "s|^${key}=.*|${key}=${escaped_value}|" .env
}

# Function to prompt for input with default value
prompt_with_default() {
    local prompt=$1
    local default=$2
    local varname=$3

    local result
    result=$(whiptail --title "AI Tool Server Stack" \
                     --backtitle "Step $CURRENT_STEP of $TOTAL_STEPS" \
                     --inputbox "$prompt" \
                     10 70 \
                     "$default" \
                     3>&1 1>&2 2>&3)

    # If user cancelled, use default
    if [ $? -eq 0 ]; then
        printf -v "$varname" '%s' "$result"
    else
        printf -v "$varname" '%s' "$default"
    fi
}

# Function to prompt for password/secret
prompt_password() {
    local prompt=$1
    local varname=$2

    local result
    result=$(whiptail --title "AI Tool Server Stack" \
                     --backtitle "Step $CURRENT_STEP of $TOTAL_STEPS" \
                     --passwordbox "$prompt" \
                     10 70 \
                     3>&1 1>&2 2>&3)

    printf -v "$varname" '%s' "$result"
}

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt=$1
    local default=$2

    local default_item=""
    if [ "$default" = "n" ]; then
        default_item="--defaultno"
    fi

    if whiptail --title "AI Tool Server Stack" \
                --backtitle "Step $CURRENT_STEP of $TOTAL_STEPS" \
                --yesno "$prompt" \
                10 70 \
                $default_item 3>&1 1>&2 2>&3; then
        return 0
    else
        return 1
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

CURRENT_STEP=1

# Step 1: Service URLs (no intro dialog needed)

if prompt_yes_no "Is this a production deployment?" "n"; then
    PRODUCTION=true
    prompt_with_default "Your domain name" "yourdomain.com" DOMAIN

    OPEN_WEBUI_URL="https://chat.${DOMAIN}"
    LANGFLOW_URL="https://flow.${DOMAIN}"
    SUPABASE_PUBLIC_URL="https://db-api.${DOMAIN}"
    API_EXTERNAL_URL="https://db-api.${DOMAIN}"
    SITE_URL="https://db-admin.${DOMAIN}"
    MEILISEARCH_URL="https://search-api.${DOMAIN}"
    MEILISEARCH_UI_URL="https://search.${DOMAIN}"

    if prompt_yes_no "Customize auto-configured URLs?" "n"; then
        prompt_with_default "Open WebUI URL" "$OPEN_WEBUI_URL" OPEN_WEBUI_URL
        prompt_with_default "Langflow URL" "$LANGFLOW_URL" LANGFLOW_URL
        prompt_with_default "Supabase API URL" "$SUPABASE_PUBLIC_URL" SUPABASE_PUBLIC_URL
        prompt_with_default "Supabase Studio URL" "$SITE_URL" SITE_URL
        prompt_with_default "Meilisearch URL" "$MEILISEARCH_URL" MEILISEARCH_URL
        prompt_with_default "Meilisearch UI URL" "$MEILISEARCH_UI_URL" MEILISEARCH_UI_URL
        API_EXTERNAL_URL="$SUPABASE_PUBLIC_URL"
    fi
else
    PRODUCTION=false
    OPEN_WEBUI_URL="http://localhost:8080"
    LANGFLOW_URL="http://localhost:7860"
    SUPABASE_PUBLIC_URL="http://localhost:8000"
    API_EXTERNAL_URL="http://localhost:8000"
    SITE_URL="http://localhost:3001"
    MEILISEARCH_URL="http://localhost:7700"
    MEILISEARCH_UI_URL="http://localhost:7701"
fi

replace_env_value "OPEN_WEBUI_URL" "$OPEN_WEBUI_URL"
replace_env_value "LANGFLOW_URL" "$LANGFLOW_URL"
replace_env_value "SUPABASE_PUBLIC_URL" "$SUPABASE_PUBLIC_URL"
replace_env_value "API_EXTERNAL_URL" "$API_EXTERNAL_URL"
replace_env_value "SITE_URL" "$SITE_URL"
replace_env_value "MEILISEARCH_URL" "$MEILISEARCH_URL"
replace_env_value "MEILISEARCH_UI_URL" "$MEILISEARCH_UI_URL"

CURRENT_STEP=2

# Step 2: Generate secrets
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

# Generate secrets with progress gauge
{
    for secret_pair in "${secrets[@]}"; do
        IFS=':' read -r key name <<< "$secret_pair"
        percentage=$((counter * 100 / total_secrets))
        echo "$percentage"
        echo "XXX"
        echo "Generating secret $counter of $total_secrets:\n$name"
        echo "XXX"

        value=$(generate_secret)
        replace_env_value "$key" "$value"
        ((counter++))
    done

    # Generate SECRET_KEY_BASE (64 chars)
    percentage=$((counter * 100 / total_secrets))
    echo "$percentage"
    echo "XXX"
    echo "Generating secret $counter of $total_secrets:\nSecret Key Base (64 chars)"
    echo "XXX"

    SECRET_KEY_BASE=$(generate_long_secret 64)
    replace_env_value "SECRET_KEY_BASE" "$SECRET_KEY_BASE"

    echo "100"
} | whiptail --title "Generating Secrets" --gauge "Initializing secret generation..." 8 70 0

# Set default app name
replace_env_value "WEBUI_NAME" "Open WebUI"

CURRENT_STEP=3

# Step 3: AI Providers
# Ollama
if prompt_yes_no "Configure Ollama? (Local Models)" "n"; then
    prompt_with_default "Ollama URL" "http://host.docker.internal:11434" OLLAMA_URL
    replace_env_value "OLLAMA_BASE_URL" "$OLLAMA_URL"
fi

# OpenAI
if prompt_yes_no "Configure OpenAI? (GPT-4, GPT-3.5, etc.)" "n"; then
    prompt_password "OpenAI API Key (starts with sk-)" OPENAI_KEY
    if [ -n "$OPENAI_KEY" ]; then
        replace_env_value "OPENAI_API_KEY" "$OPENAI_KEY"
    fi
fi

# Anthropic
if prompt_yes_no "Configure Anthropic? (Claude models)" "n"; then
    prompt_password "Anthropic API Key (starts with sk-ant-)" ANTHROPIC_KEY
    if [ -n "$ANTHROPIC_KEY" ]; then
        replace_env_value "ANTHROPIC_API_KEY" "$ANTHROPIC_KEY"
    fi
fi

# OpenRouter
if prompt_yes_no "Configure OpenRouter? (Multi-Provider Gateway)" "n"; then
    prompt_password "OpenRouter API Key (starts with sk-or-)" OPENROUTER_KEY
    if [ -n "$OPENROUTER_KEY" ]; then
        replace_env_value "OPENROUTER_API_KEY" "$OPENROUTER_KEY"
    fi
fi

CURRENT_STEP=4

# Step 4: SMTP
if prompt_yes_no "Configure SMTP for email notifications?" "n"; then
    prompt_with_default "SMTP Host" "smtp.gmail.com" SMTP_HOST

    while true; do
        prompt_with_default "SMTP Port" "587" SMTP_PORT
        if validate_port "$SMTP_PORT"; then
            break
        else
            whiptail --title "Invalid Port" --msgbox "\nInvalid port number.\n\nPlease enter a number between 1-65535" 10 50
        fi
    done

    prompt_with_default "SMTP Username" "" SMTP_USER

    prompt_password "SMTP Password" SMTP_PASS

    while true; do
        prompt_with_default "From Email Address" "$SMTP_USER" SMTP_ADMIN_EMAIL
        if validate_email "$SMTP_ADMIN_EMAIL"; then
            break
        else
            whiptail --title "Invalid Email" --msgbox "\nInvalid email format.\n\nPlease enter a valid email address." 10 50
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
fi

CURRENT_STEP=5

# Step 5: OAuth/OIDC
OAUTH_CONFIGURED=false
if prompt_yes_no "Configure OAuth/OIDC for SSO?" "n"; then
    OAUTH_CONFIGURED=true

    while true; do
        prompt_with_default "OAuth Provider Base URL" "http://localhost:9000" OAUTH_URL
        if validate_url "$OAUTH_URL"; then
            replace_env_value "OAUTH_PROVIDER_URL" "$OAUTH_URL"
            break
        else
            whiptail --title "Invalid URL" --msgbox "\nInvalid URL format. Please enter a valid URL starting with http:// or https://" 10 60
        fi
    done

    prompt_with_default "OAuth Provider Name (shown to users)" "SSO" OAUTH_NAME
    replace_env_value "OAUTH_PROVIDER_NAME" "$OAUTH_NAME"

    prompt_with_default "OpenID Provider URL (leave empty if using base URL)" "" OPENID_URL
    # Always set OPENID_PROVIDER_URL when OAuth is configured
    if [ -n "$OPENID_URL" ]; then
        replace_env_value "OPENID_PROVIDER_URL" "$OPENID_URL"
    else
        # Fallback to OAUTH_URL if no separate OpenID URL provided
        replace_env_value "OPENID_PROVIDER_URL" "$OAUTH_URL"
    fi

    prompt_with_default "OAuth Client ID" "" OAUTH_CLIENT_ID
    replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_ID" "$OAUTH_CLIENT_ID"

    prompt_password "OAuth Client Secret" OAUTH_CLIENT_SECRET
    replace_env_value "OPEN_WEBUI_OAUTH_CLIENT_SECRET" "$OAUTH_CLIENT_SECRET"

    # Set sensible OAuth defaults
    replace_env_value "ENABLE_OAUTH_SIGNUP" "true"
    replace_env_value "ENABLE_OAUTH_PERSISTENT_CONFIG" "true"
    replace_env_value "OAUTH_MERGE_ACCOUNTS_BY_EMAIL" "true"
    replace_env_value "OAUTH_SCOPES" "openid email profile"
    replace_env_value "ENABLE_PASSWORD_AUTH" "true"
fi

CURRENT_STEP=6

# Step 6: Meilisearch & Scrapix
SCRAPIX_CONFIGURED=false
if prompt_yes_no "Configure Scrapix to index documentation sites?" "y"; then
        SCRAPIX_CONFIGURED=true
        # Check if config already exists
        if [ -f scrapix.env ]; then
            whiptail --title "Config Exists" \
                     --msgbox "\nscrapix.env already exists.\n\nSkipping config generation." \
                     10 50
        else
            # Ask if user wants to use default URLs or customize
            if whiptail --title "Scrapix URLs" \
                        --yesno "\nWould you like to use the default documentation URLs?\n\nDefault sites:\n  • Open WebUI docs\n  • Anthropic/Claude docs\n  • OpenAI docs\n  • Meilisearch docs\n\nSelect No to enter your own URLs." \
                        16 60; then
                # Use default URLs
                SCRAPIX_URLS='["https://docs.openwebui.com","https://docs.anthropic.com","https://platform.openai.com/docs","https://docs.meilisearch.com"]'
                URLS_DISPLAY="  • Open WebUI documentation\n  • Anthropic/Claude documentation\n  • OpenAI documentation\n  • Meilisearch documentation"
            else
                # Collect custom URLs
                whiptail --title "Custom URLs" \
                         --msgbox "\nEnter documentation URLs to scrape and index.\n\nExamples:\n  • https://docs.openwebui.com\n  • https://docs.anthropic.com\n  • https://python.langchain.com/docs\n\nYou'll be prompted to add URLs one at a time." \
                         16 60

                SCRAPIX_URLS='[]'
                URLS_DISPLAY=""
                URL_COUNT=0

                while true; do
                    URL_PROMPT="Enter documentation URL $(($URL_COUNT + 1))"
                    if [ $URL_COUNT -gt 0 ]; then
                        URL_PROMPT+="\n\nCurrent URLs: $URL_COUNT"
                    fi

                    prompt_with_default "$URL_PROMPT (leave empty to finish)" "" CUSTOM_URL

                    # If empty, user is done
                    if [ -z "$CUSTOM_URL" ]; then
                        if [ $URL_COUNT -eq 0 ]; then
                            whiptail --title "No URLs Entered" \
                                     --msgbox "\nNo URLs entered. Using default list instead." \
                                     10 50
                            SCRAPIX_URLS='["https://docs.openwebui.com","https://docs.anthropic.com","https://platform.openai.com/docs","https://docs.meilisearch.com"]'
                            URLS_DISPLAY="  • Open WebUI documentation\n  • Anthropic/Claude documentation\n  • OpenAI documentation\n  • Meilisearch documentation"
                        fi
                        break
                    fi

                    # Validate URL format
                    if ! validate_url "$CUSTOM_URL"; then
                        whiptail --title "Invalid URL" \
                                 --msgbox "\nInvalid URL format: $CUSTOM_URL\n\nPlease enter a valid URL starting with http:// or https://" \
                                 10 60
                        continue
                    fi

                    # Add URL to JSON array
                    if [ "$SCRAPIX_URLS" = "[]" ]; then
                        SCRAPIX_URLS="[\"$CUSTOM_URL\"]"
                    else
                        # Remove closing bracket, add comma and new URL, close bracket
                        SCRAPIX_URLS="${SCRAPIX_URLS%]},\"$CUSTOM_URL\"]"
                    fi

                    # Add to display list
                    URLS_DISPLAY+="  • $CUSTOM_URL\n"
                    ((URL_COUNT++))

                    # Ask if they want to add more
                    if ! prompt_yes_no "Add another URL?" "y"; then
                        break
                    fi
                done
            fi

            # Generate scrapix.env with user's URLs
            # Extract and validate MEILI_MASTER_KEY
            MEILI_KEY=$(grep -m1 MEILI_MASTER_KEY .env | cut -d '=' -f2 | tr -d '"' | tr -d "'" | xargs)

            if [ -z "$MEILI_KEY" ]; then
                # Degrade gracefully instead of failing hard
                whiptail --title "Missing Meilisearch Key" \
                         --msgbox "\n⚠ WARNING: MEILI_MASTER_KEY not found in .env\n\nScrapix requires a Meilisearch master key to function.\nSkipping Scrapix configuration.\n\nYou can configure it later by re-running setup.sh" \
                         14 60
                SCRAPIX_CONFIGURED=false
            else

                # Create JSON config as a single-line string (no whitespace to avoid parsing issues)
                CRAWLER_CONFIG="{\"start_urls\":${SCRAPIX_URLS},\"meilisearch_url\":\"http://meilisearch:7700\",\"meilisearch_api_key\":\"${MEILI_KEY}\",\"meilisearch_index_uid\":\"web_docs\",\"strategy\":\"docssearch\",\"headless\":true,\"batch_size\":100,\"urls_to_exclude\":[\"*/api-reference/*\",\"*/changelog/*\"],\"additional_request_headers\":{}}"

                # Validate JSON before writing
                if ! jq -e . >/dev/null 2>&1 <<< "$CRAWLER_CONFIG"; then
                    whiptail --title "Configuration Error" \
                             --msgbox "\n✗ ERROR: Invalid crawler configuration JSON\n\nSkipping Scrapix setup.\n\nThis may be due to malformed URLs in the configuration." \
                             12 60
                    SCRAPIX_CONFIGURED=false
                else
                    cat > scrapix.env <<EOF
# Scrapix Configuration
# Auto-generated by setup.sh
CRAWLER_CONFIG=${CRAWLER_CONFIG}
EOF
                fi
            fi
        fi
fi

# Meilisearch UI Configuration
if prompt_yes_no "Configure Meilisearch UI settings?" "n"; then
    prompt_with_default "Search UI Title" "AI Tool Server Search" VITE_APP_TITLE
    replace_env_value "VITE_APP_TITLE" "$VITE_APP_TITLE"

    prompt_with_default "Default Search Index" "web_docs" VITE_MEILISEARCH_INDEX
    replace_env_value "VITE_MEILISEARCH_INDEX" "$VITE_MEILISEARCH_INDEX"

    prompt_with_default "Semantic Ratio (0.0=keyword, 1.0=semantic)" "0.5" VITE_SEMANTIC_RATIO
    replace_env_value "VITE_MEILISEARCH_SEMANTIC_RATIO" "$VITE_SEMANTIC_RATIO"

    prompt_with_default "Vector Embedder Name" "default" VITE_EMBEDDER
    replace_env_value "VITE_MEILISEARCH_EMBEDDER" "$VITE_EMBEDDER"
else
    # Set defaults
    replace_env_value "VITE_APP_TITLE" "AI Tool Server Search"
    replace_env_value "VITE_MEILISEARCH_INDEX" "web_docs"
    replace_env_value "VITE_MEILISEARCH_SEMANTIC_RATIO" "0.5"
    replace_env_value "VITE_MEILISEARCH_EMBEDDER" "default"
fi

CURRENT_STEP=7

# Step 7: Generate docker-compose.override.yml
# Build override file content
OVERRIDE_CONTENT="# Auto-generated by setup.sh\n"
OVERRIDE_CONTENT+="# Optional configurations for AI providers, OAuth, and integrations\n\n"
OVERRIDE_CONTENT+="services:\n"

# Check if override file already exists
SKIP_OVERRIDE=false
if [ -f docker-compose.override.yml ]; then
    if whiptail --title "Override File Exists" \
                --yesno "\ndocker-compose.override.yml already exists!\n\nOverwrite? The existing file will be backed up." \
                12 60; then
        backup_file="docker-compose.override.yml.backup.$(date +%Y%m%d_%H%M%S)"
        cp docker-compose.override.yml "$backup_file"
        whiptail --title "Backup Created" \
                 --msgbox "\nExisting file backed up to:\n${backup_file}" \
                 10 60
    else
        whiptail --title "Keeping Existing File" \
                 --msgbox "\nSkipping override file creation.\n\nContinuing with existing docker-compose.override.yml" \
                 10 60
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
    if [ "$OAUTH_CONFIGURED" = true ]; then
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

    # Meilisearch Integration (core component)
    OVERRIDE_CONTENT+="      - MEILISEARCH_URL=http://meilisearch:7700\n"
    OVERRIDE_CONTENT+="      - MEILISEARCH_API_KEY=\${MEILI_MASTER_KEY}\n"
    OVERRIDE_CONTENT+="      - ENABLE_RAG_WEB_SEARCH=true\n"

    # PostgreSQL option
    if prompt_yes_no "Use PostgreSQL for Open WebUI instead of SQLite?" "n"; then
        OVERRIDE_CONTENT+="      - DATABASE_URL=postgresql://postgres:\${POSTGRES_PASSWORD}@db:5432/postgres\n"
    fi

    # Scrapix service (only if configured)
    if [ "$SCRAPIX_CONFIGURED" = true ]; then
        OVERRIDE_CONTENT+="\n  scrapix:\n"
        OVERRIDE_CONTENT+="    container_name: scrapix\n"
        OVERRIDE_CONTENT+="    image: getmeili/scrapix:\${SCRAPIX_VERSION:-latest}\n"
        OVERRIDE_CONTENT+="    restart: \"no\"\n"
        OVERRIDE_CONTENT+="    depends_on:\n"
        OVERRIDE_CONTENT+="      meilisearch:\n"
        OVERRIDE_CONTENT+="        condition: service_healthy\n"
        OVERRIDE_CONTENT+="    env_file:\n"
        OVERRIDE_CONTENT+="      - scrapix.env\n"
        OVERRIDE_CONTENT+="    networks:\n"
        OVERRIDE_CONTENT+="      - ai-tools-net\n"
    fi

    # Write the override file
    echo -e "$OVERRIDE_CONTENT" > docker-compose.override.yml
fi

# Set proper permissions
chmod 600 .env

# Build service URLs summary
SUMMARY="✨  SETUP COMPLETE!  ✨\n\n"
SUMMARY+="━━━━━ YOUR SERVICES ━━━━━\n\n"
SUMMARY+="Open WebUI:      ${OPEN_WEBUI_URL}\n"
SUMMARY+="Langflow:        ${LANGFLOW_URL}\n"
SUMMARY+="Supabase Studio: ${SITE_URL}\n"
SUMMARY+="Supabase API:    ${SUPABASE_PUBLIC_URL}\n"
SUMMARY+="Meilisearch API: ${MEILISEARCH_URL}\n"
SUMMARY+="Meilisearch UI:  ${MEILISEARCH_UI_URL}\n"

if [ "$OAUTH_CONFIGURED" = true ]; then
    SUMMARY+="\nOAuth Provider:  ${OAUTH_URL}\n"
fi

# Show service URLs
whiptail --title "Setup Complete! 🎉" \
         --msgbox "$SUMMARY" \
         16 70

# Ask if user wants to start the stack
if whiptail --title "Start the Stack?" \
            --yesno "\nWould you like to start the AI Tool Server Stack now?\n\nThis will run: docker compose up -d\n\nThe services will start in the background." \
            12 60; then

    # Show starting message
    whiptail --title "Starting Stack" \
             --msgbox "\nStarting Docker Compose stack...\n\nThis may take a few moments." \
             10 50

    # Run docker compose up -d and capture output
    if COMPOSE_OUTPUT=$(docker compose up -d 2>&1); then
        whiptail --title "Stack Started! 🚀" \
                 --msgbox "\n✓ AI Tool Server Stack is now running!\n\nYour services are starting up:\n\n  Open WebUI:      ${OPEN_WEBUI_URL}\n  Langflow:        ${LANGFLOW_URL}\n  Supabase Studio: ${SITE_URL}\n\nNote: Services may take 1-2 minutes to fully initialize.\n\nCheck status: docker compose ps\nView logs: docker compose logs -f" \
                 18 70
    else
        whiptail --title "Error Starting Stack" \
                 --msgbox "\n✗ Docker Compose failed:\n\n${COMPOSE_OUTPUT}\n\nCommon issues:\n  • Docker daemon not running\n  • Port conflicts\n  • Missing images\n  • Insufficient disk space\n\nTry manually: docker compose up -d" \
                 20 75 \
                 --scrolltext
    fi
else
    whiptail --title "Setup Complete" \
             --msgbox "\nSetup complete!\n\nWhen you're ready to start the stack, run:\n  docker compose up -d\n\nSee README.md for next steps." \
             12 60
fi