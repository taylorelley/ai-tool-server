# Automatic Configuration Reference

This document describes all automatic configurations applied to Open WebUI and Langflow by the setup script.

## Overview

When you run `./setup.sh`, the script automatically configures:
- ✅ AI Model Providers (Ollama, OpenAI, Anthropic, OpenRouter)
- ✅ Playwright Service (for web scraping)
- ✅ Meilisearch Integration (for documentation search)
- ✅ Supabase Backend (database, storage, auth)
- ✅ OAuth/OIDC Authentication
- ✅ PostgreSQL Database (optional)

All configurations are applied via environment variables in `docker-compose.override.yml`.

## Open WebUI Automatic Configuration

### AI Model Providers

Open WebUI automatically connects to configured AI providers via environment variables:

| Provider | Environment Variable | Configured When |
|----------|---------------------|-----------------|
| **Ollama** | `OLLAMA_BASE_URL` | You enable Ollama in setup |
| **OpenAI** | `OPENAI_API_KEY` | You provide OpenAI API key |
| **Anthropic** | `ANTHROPIC_API_KEY` | You provide Anthropic API key |
| **OpenRouter** | `OPENROUTER_API_KEY` | You provide OpenRouter API key |

**How it works:**
- The setup script prompts for each provider
- API keys are stored in `.env`
- Environment variables are added to `docker-compose.override.yml`
- Open WebUI automatically detects and uses these providers

**No manual configuration needed** - providers appear automatically in the model selection dropdown.

### Playwright Integration

**Purpose:** Enables web scraping and screenshot features in Open WebUI

**Configuration:**
```yaml
environment:
  - PLAYWRIGHT_SERVICE_URL=http://playwright:3000
```

**Status:** ✅ **Automatically configured** in `docker-compose.yaml`

**Features enabled:**
- Web page scraping for RAG
- Screenshot capture
- Web content extraction

### Meilisearch Integration

**Purpose:** Fast search of indexed documentation

**Configuration:**
```yaml
environment:
  - MEILISEARCH_URL=http://meilisearch:7700
  - MEILISEARCH_API_KEY=${MEILI_MASTER_KEY}
  - ENABLE_RAG_WEB_SEARCH=true
```

**Status:** ✅ **Automatically configured** when you enable Meilisearch in setup

**How to complete setup:**

1. **During setup:** Choose "yes" when prompted to configure Meilisearch
2. **After starting services:** Run `docker compose run scrapix` to index documentation
3. **Import the tool:**
   - Option A: Use the installer script:
     ```bash
     ./scripts/install-meilisearch-tool.sh
     ```
   - Option B: Manual import:
     - Go to Admin Panel → Tools → Import Tool
     - Upload: `volumes/open-webui/tools/meilisearch_search.py`

**Features enabled:**
- Search Open WebUI, Anthropic, OpenAI, Meilisearch documentation
- Fast, typo-tolerant search with highlighting
- Automatically configured from environment variables
- **Built-in Web Interface** at http://localhost:7700
  - Search preview with live results
  - Index management and statistics
  - Document browser and settings
  - API key management

**Accessing Web Interface:**
```bash
# Get your API key
grep MEILI_MASTER_KEY .env

# Access the interface
open http://localhost:7700
# Provide MEILI_MASTER_KEY when prompted
```

### Supabase Backend Integration

**Purpose:** Provides PostgreSQL database, storage, and auth backend

**Configuration:**
```yaml
environment:
  - SUPABASE_URL=http://kong:8000
  - SUPABASE_ANON_KEY=${ANON_KEY}
```

**Status:** ✅ **Automatically configured** for all installations

**Features enabled:**
- Access to Supabase PostgreSQL via PostgREST API
- File storage through Supabase Storage
- Authentication via Supabase Auth

### OAuth/OIDC Authentication

**Purpose:** Single Sign-On with external identity providers

**Configuration:**
```yaml
environment:
  - ENABLE_OAUTH_SIGNUP=${ENABLE_OAUTH_SIGNUP}
  - ENABLE_OAUTH_PERSISTENT_CONFIG=${ENABLE_OAUTH_PERSISTENT_CONFIG}
  - OAUTH_MERGE_ACCOUNTS_BY_EMAIL=${OAUTH_MERGE_ACCOUNTS_BY_EMAIL}
  - OAUTH_PROVIDER_NAME=${OAUTH_PROVIDER_NAME}
  - OPENID_PROVIDER_URL=${OPENID_PROVIDER_URL}
  - OAUTH_CLIENT_ID=${OPEN_WEBUI_OAUTH_CLIENT_ID}
  - OAUTH_CLIENT_SECRET=${OPEN_WEBUI_OAUTH_CLIENT_SECRET}
  - OAUTH_SCOPES=${OAUTH_SCOPES}
  - OPENID_REDIRECT_URI=${OPEN_WEBUI_URL}/oauth/oidc/callback
  - ENABLE_PASSWORD_AUTH=${ENABLE_PASSWORD_AUTH}
```

**Status:** ✅ **Automatically configured** when you provide OAuth settings in setup

**Supported providers:**
- Authentik
- Keycloak
- Google
- Microsoft/Azure AD
- Auth0
- Any OIDC-compliant provider

### PostgreSQL Database (Optional)

**Purpose:** Use PostgreSQL instead of SQLite for production deployments

**Configuration:**
```yaml
environment:
  - DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/postgres
```

**Status:** ⚙️ **Optional** - prompted during setup (Step 8)

**When to use:**
- Production deployments
- Multiple Open WebUI instances (horizontal scaling)
- Better performance with large datasets

## Langflow Automatic Configuration

### AI Model Providers

Langflow automatically receives the same provider configurations:

```yaml
environment:
  - OLLAMA_BASE_URL=${OLLAMA_BASE_URL}
  - OPENAI_API_KEY=${OPENAI_API_KEY}
  - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
  - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
```

**Status:** ✅ **Automatically configured** based on your setup choices

### Supabase Integration

Langflow receives full Supabase connection details:

```yaml
environment:
  - SUPABASE_URL=http://kong:8000
  - SUPABASE_ANON_KEY=${ANON_KEY}
  - SUPABASE_SERVICE_KEY=${SERVICE_ROLE_KEY}
  - SUPABASE_DB_HOST=${POSTGRES_HOST}
  - SUPABASE_DB_PORT=${POSTGRES_PORT}
  - SUPABASE_DB_NAME=${POSTGRES_DB}
  - SUPABASE_DB_USER=postgres
  - SUPABASE_DB_PASSWORD=${POSTGRES_PASSWORD}
```

**Status:** ✅ **Automatically configured** for all installations

**Features enabled:**
- Direct PostgreSQL database access
- Supabase REST API integration
- File storage access
- pgvector for embeddings

## Configuration Files

### Main Configuration File: `.env`

Generated by `./setup.sh` with:
- 13 cryptographically secure secrets
- Service URLs
- AI provider API keys
- OAuth/OIDC settings
- SMTP configuration (optional)
- Meilisearch master key

**Security:** Automatically set to mode 600 (read/write for owner only)

### Override File: `docker-compose.override.yml`

Auto-generated by `./setup.sh` with all optional configurations:
- AI provider environment variables
- OAuth settings
- Supabase integration
- Meilisearch integration
- PostgreSQL database (if enabled)

**Automatic merging:** Docker Compose automatically merges this with `docker-compose.yaml`

## Verification

### Check Active Configuration

```bash
# View all Open WebUI environment variables
docker compose exec open-webui env | grep -E '(OLLAMA|OPENAI|ANTHROPIC|OPENROUTER|MEILISEARCH|PLAYWRIGHT|SUPABASE|OAUTH)'

# View docker-compose.override.yml
cat docker-compose.override.yml
```

### Test Providers

```bash
# Start services
docker compose up -d

# Check Open WebUI logs for provider detection
docker compose logs open-webui | grep -i "provider\|model"

# Access Open WebUI
open http://localhost:8080
# Check: Settings → Models (should show all configured providers)
```

### Test Meilisearch

```bash
# Check if Meilisearch is accessible
curl http://localhost:7700/health

# Verify Meilisearch environment variables in Open WebUI
docker compose exec open-webui env | grep MEILISEARCH

# Install and test the tool
./scripts/install-meilisearch-tool.sh
```

## Manual Configuration (Not Required)

The following are **NOT needed** if you run `./setup.sh`:

- ❌ Manual provider configuration in Open WebUI UI
- ❌ Manual Playwright service URL entry
- ❌ Manual OAuth configuration in Admin Panel
- ❌ Manual database connection strings
- ❌ Manual API key entry in UI

Everything is configured automatically via environment variables!

## Troubleshooting

### Providers Not Showing

1. **Check environment variables:**
   ```bash
   docker compose exec open-webui env | grep API_KEY
   ```

2. **Verify override file:**
   ```bash
   cat docker-compose.override.yml
   ```

3. **Restart Open WebUI:**
   ```bash
   docker compose restart open-webui
   ```

### Meilisearch Tool Not Working

1. **Check environment variables:**
   ```bash
   docker compose exec open-webui env | grep MEILISEARCH
   ```

2. **Verify Meilisearch is running:**
   ```bash
   docker compose ps meilisearch
   curl http://localhost:7700/health
   ```

3. **Check if documentation is indexed:**
   ```bash
   docker compose logs scrapix
   ```

4. **Reinstall the tool:**
   ```bash
   ./scripts/install-meilisearch-tool.sh
   ```

### OAuth Not Working

1. **Verify OAuth environment variables:**
   ```bash
   docker compose exec open-webui env | grep -E '(OAUTH|OPENID)'
   ```

2. **Check redirect URI matches:**
   - Should be: `${OPEN_WEBUI_URL}/oauth/oidc/callback`
   - Configure this in your OAuth provider

3. **Test OIDC discovery endpoint:**
   ```bash
   curl ${OPENID_PROVIDER_URL}
   ```

## Summary of Automatic Features

| Feature | Status | Configuration Required |
|---------|--------|----------------------|
| AI Model Providers | ✅ Automatic | Provide API keys in setup |
| Playwright Service | ✅ Automatic | None - always enabled |
| Meilisearch Search | ✅ Automatic | Import tool after setup |
| Supabase Backend | ✅ Automatic | None - always enabled |
| OAuth/OIDC SSO | ✅ Automatic | Provide OAuth details in setup |
| PostgreSQL DB | ⚙️ Optional | Choose in setup (Step 8) |

**Result:** Zero manual configuration needed in the Open WebUI UI for standard features!
