# AI Tool Server Stack

**A production-ready, self-hosted AI development platform combining powerful AI tools (Langflow, Open WebUI) with enterprise-grade Supabase backend infrastructure.**

## 🌟 Why This Stack?

Deploy a complete AI application development environment in minutes with:

- **One-Command Setup** - Automated configuration with `./setup.sh`
- **Zero SaaS Fees** - Fully self-hosted with complete control
- **Production Ready** - Enterprise authentication, database, and file storage
- **AI Integration** - Pre-configured support for Ollama, OpenAI, Anthropic, and OpenRouter
- **Vector Search** - Built-in pgvector for RAG applications
- **Fast Search** - Meilisearch with semantic search and typo-tolerance
- **Web Scraping** - Playwright integration for data extraction
- **Multi-User** - OAuth/OIDC SSO with row-level security
- **Serverless Functions** - Deno Edge Functions for custom logic

## 📖 Table of Contents

- [What's Inside](#-whats-inside)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Configuration](#-configuration)
- [Data Persistence](#-data-persistence)
- [Security Best Practices](#-security-best-practices)
- [Management Commands](#-management-commands)
- [Troubleshooting](#-troubleshooting)
- [Monitoring](#-monitoring)
- [Backup & Restore](#-backup--restore)
- [Production Deployment](#-production-deployment)
- [Langflow + Supabase Integration](#-langflow--supabase-integration)
- [Advanced Configuration](#-advanced-configuration)
- [Additional Resources](#-additional-resources)
- [Use Cases](#-use-cases)
- [Getting Help](#-getting-help)

## 🎁 What's Inside

### AI Development Tools

| Service | Port | Description |
|---------|------|-------------|
| **Langflow** | 7860 | Visual AI workflow builder with drag-and-drop interface for creating LLM applications |
| **Open WebUI** | 8080 | Modern chat interface with custom tool support, web scraping, and multi-model support |
| **Meilisearch** | 7700 | Lightning-fast search engine with vector embeddings and typo-tolerance |
| **Meilisearch Search UI** | 7701 | Web interface for hybrid search (keyword + semantic) with live results |
| **Meilisearch Admin UI** | 7702 | Admin panel for index management, settings, API keys, and analytics |
| **Playwright** | internal | Browser automation service for web scraping and content extraction |
| **Scrapix** | on-demand | Web scraper for indexing documentation sites into Meilisearch |

### Supabase Backend Infrastructure

| Service | Port | Description |
|---------|------|-------------|
| **PostgreSQL** | 5432 | Primary database with pgvector extension for embeddings |
| **Kong (API Gateway)** | 8000 | Auto-generated REST API via PostgREST with authentication |
| **Supabase Studio** | 3001 | Database management UI with visual query builder |
| **GoTrue Auth** | internal | User authentication and management with OAuth support |
| **Realtime** | internal | WebSocket subscriptions for live database updates |
| **Storage** | internal | File storage with image transformation (S3-like interface) |
| **Edge Functions** | internal | Serverless Deno functions at `/functions/v1/*` |
| **Analytics (Logflare)** | internal | Log aggregation and monitoring |
| **Connection Pooler** | internal | Database connection pooling with Supavisor |

### Key Features

✅ **Vector Database** - pgvector for semantic search and RAG
✅ **Hybrid Search** - Combine keyword and semantic search with Meilisearch
✅ **OAuth/OIDC** - Authentik, Keycloak, Google, Microsoft, Auth0 support
✅ **Multi-Model AI** - Use Ollama, OpenAI, Anthropic, OpenRouter simultaneously
✅ **Web Scraping** - Playwright integration for extracting web content
✅ **Real-time Data** - WebSocket subscriptions for live updates
✅ **File Storage** - Upload/download with image transformation
✅ **Edge Functions** - Custom serverless API endpoints
✅ **Auto-Generated API** - REST API automatically created from database schema
✅ **Row-Level Security** - Multi-tenant data isolation

## 🏗️ Architecture

This stack integrates AI development tools with Supabase as the backend storage layer:

```
┌─────────────────────────────────────────────────────────────────┐
│                        AI TOOLS LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐            │
│  │  Langflow   │  │ Open WebUI  │  │ Meilisearch  │            │
│  │   :7860     │  │    :8080    │  │    :7700     │            │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘            │
│         │                │                │                     │
│         └────────┬───────┴────────────────┘                     │
│                  │                                               │
│         ┌────────┴────────┐      ┌──────────────┐               │
│         │   Playwright    │      │   Scrapix    │               │
│         │   (internal)    │      │ (on-demand)  │               │
│         └─────────────────┘      └──────────────┘               │
└─────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SUPABASE BACKEND LAYER                        │
│                                                                  │
│  ┌────────────┐   ┌──────────┐   ┌─────────────┐               │
│  │ PostgreSQL │◄──┤   Kong   │◄──┤   GoTrue    │               │
│  │  +pgvector │   │   :8000  │   │    Auth     │               │
│  └─────┬──────┘   └────┬─────┘   └─────────────┘               │
│        │               │                                         │
│  ┌─────┴──────┐   ┌────┴─────┐   ┌─────────────┐               │
│  │  Realtime  │   │ Storage  │   │    Edge     │               │
│  │  (WebSocket)│   │  (S3-like)│   │  Functions  │               │
│  └────────────┘   └──────────┘   └─────────────┘               │
│                                                                  │
│  ┌────────────┐   ┌──────────┐                                  │
│  │   Studio   │   │Analytics │                                  │
│  │   :3001    │   │(Logflare)│                                  │
│  └────────────┘   └──────────┘                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Integration Points

- **Langflow ↔ Supabase PostgreSQL** - Direct database access for storing flow data, chat history, and embeddings
- **Langflow ↔ Supabase REST API** - Use PostgREST for CRUD operations in workflows
- **Langflow ↔ Supabase Storage** - File upload/download in processing pipelines
- **Langflow ↔ Supabase Auth** - User authentication in multi-user flows
- **Langflow ↔ pgvector** - Vector similarity search for RAG applications
- **Open WebUI ↔ Meilisearch** - Fast documentation search via custom tool
- **Open WebUI ↔ Playwright** - Web scraping and content extraction
- **Scrapix ↔ Meilisearch** - Automatic documentation indexing

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose V2
- 4GB+ RAM recommended (8GB+ for production)
- `openssl` command (for generating secrets)
- `curl` command (for downloading files)
- `whiptail` (for interactive setup - usually pre-installed)
- (Optional) AI provider: Ollama (local), OpenAI, Anthropic, or OpenRouter

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Clone or download the stack files
cd ai-tool-server

# Make scripts executable
chmod +x setup.sh scripts/*.sh

# Run interactive setup wizard
./setup.sh
```

The setup script will:
- ✅ Check for required dependencies (docker, openssl, curl)
- ✅ Validate all your inputs (URLs, emails, ports)
- ✅ Generate cryptographically secure secrets
- ✅ Configure service URLs and AI backends
- ✅ Set up SMTP if needed
- ✅ **Automatically configure Open WebUI and Langflow** with:
  - AI model providers (Ollama, OpenAI, Anthropic, OpenRouter)
  - Playwright service for web scraping
  - Meilisearch for documentation search
  - Supabase backend integration
  - OAuth/OIDC authentication
- ✅ **Create docker-compose.override.yml** for advanced configurations:
  - PostgreSQL database for Open WebUI (instead of SQLite)
  - Resource limits for production deployments
  - Automatic backup and merge of existing override files

**📖 See [AUTOMATIC_CONFIGURATION.md](AUTOMATIC_CONFIGURATION.md) for complete details on all automatic configurations.**

### 2. Create Required Supabase Files

Supabase requires several SQL initialization files. Create the directory structure:

```bash
mkdir -p volumes/db volumes/api volumes/functions volumes/logs volumes/pooler volumes/storage
```

Download the required files from the Supabase repository:

```bash
# Database initialization SQL files
curl -o volumes/db/realtime.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/realtime.sql
curl -o volumes/db/webhooks.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/webhooks.sql
curl -o volumes/db/roles.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/roles.sql
curl -o volumes/db/jwt.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/jwt.sql
curl -o volumes/db/_supabase.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/_supabase.sql
curl -o volumes/db/logs.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/logs.sql
curl -o volumes/db/pooler.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/pooler.sql

# Kong API gateway configuration
curl -o volumes/api/kong.yml https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/api/kong.yml

# Vector logging configuration
curl -o volumes/logs/vector.yml https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/logs/vector.yml

# Database connection pooler configuration
curl -o volumes/pooler/pooler.exs https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/pooler/pooler.exs
```

### 3. Configure Environment

Edit `.env` and update for your deployment:

```bash
# For production deployment
SUPABASE_PUBLIC_URL=https://db.your-domain.com
API_EXTERNAL_URL=https://db.your-domain.com
SITE_URL=https://db.your-domain.com:3001

# OAuth Provider Configuration
OAUTH_PROVIDER_URL=https://auth.your-domain.com
OAUTH_PROVIDER_NAME=SSO

# AI Provider Configuration (configure one or more)
OLLAMA_BASE_URL=http://host.docker.internal:11434
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key
OPENROUTER_API_KEY=sk-or-your-openrouter-key

# SMTP for email (if needed)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### 4. Validate Configuration

Before starting, run the health check:

```bash
./scripts/health-check.sh
```

This validates:
- All required environment variables are set
- No default "changeme" passwords remain
- Required files and directories exist
- Ports are available
- Docker is running

### 5. Start the Stack

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service health
docker compose ps
```

### 6. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Langflow** | http://localhost:7860 | Create on first visit |
| **Open WebUI** | http://localhost:8080 | Create on first visit |
| **Meilisearch API** | http://localhost:7700 | API Key: `MEILI_MASTER_KEY` from .env |
| **Meilisearch Search UI** | http://localhost:7701 | Hybrid search interface |
| **Meilisearch Admin UI** | http://localhost:7702 | Full admin panel |
| **Supabase Studio** | http://localhost:3001 | `DASHBOARD_USERNAME` / `DASHBOARD_PASSWORD` from .env |
| **Supabase API** | http://localhost:8000 | API keys: `ANON_KEY` / `SERVICE_ROLE_KEY` |

## 🔧 Configuration

### Using with Ollama

1. Install Ollama on your host machine
2. Pull a model: `ollama pull llama3.2`
3. The stack is pre-configured to connect via `host.docker.internal:11434`

### Using with OpenAI

1. Set `OPENAI_API_KEY` in `.env`
2. Both Langflow and Open WebUI will use this key

### Using with Anthropic

1. Get your API key from [console.anthropic.com](https://console.anthropic.com/)
2. Set `ANTHROPIC_API_KEY` in `.env`
3. Both Langflow and Open WebUI will use this key

### Using with OpenRouter

1. Get your API key from [openrouter.ai](https://openrouter.ai/)
2. Set `OPENROUTER_API_KEY` in `.env`
3. Configure models in Open WebUI or Langflow using OpenRouter endpoints

### Using Meilisearch for Document Search

Meilisearch provides fast, typo-tolerant search for indexed documentation. It integrates with Open WebUI via a custom Tool.

#### Initial Setup

During `./setup.sh`, choose "yes" when prompted to configure Meilisearch. This will:
- Generate a secure `MEILI_MASTER_KEY`
- Create `scrapix.config.json` with default documentation sites to index

Default indexed sites include:
- Open WebUI documentation
- Anthropic/Claude documentation
- OpenAI documentation
- Meilisearch documentation

#### Indexing Documentation

After starting the stack, run Scrapix to index the configured sites:

```bash
# Start all services first
docker compose up -d

# Run Scrapix to index documentation
docker compose run scrapix

# This may take several minutes depending on the number of sites
# Scrapix will scrape and index all content into Meilisearch
```

#### Using the Meilisearch Tool in Open WebUI

**Option A: Automatic Installation (Recommended)**

```bash
# Run the automatic installer script
./scripts/install-meilisearch-tool.sh

# Provide your Open WebUI admin credentials when prompted
# The tool will be automatically installed and configured
```

**Option B: Manual Installation**

1. **Access Open WebUI Admin Panel**:
   - Go to http://localhost:8080
   - Click your profile → Admin Panel → Tools

2. **Import the Tool**:
   - Click "Import Tool"
   - Upload: `volumes/open-webui/tools/meilisearch_search.py`
   - The tool will auto-configure from environment variables

3. **Verify Configuration** (optional):
   - Find "Meilisearch Documentation Search" in the tools list
   - Click the settings icon to verify Valves (settings):
     - **MEILISEARCH_URL**: `http://meilisearch:7700` ✅ Auto-configured
     - **MEILISEARCH_API_KEY**: Your `MEILI_MASTER_KEY` ✅ Auto-configured
     - **MEILISEARCH_INDEX**: `web_docs` ✅ Auto-configured
     - **RESULTS_LIMIT**: `5` (adjust if needed)

**Using the Tool in Chat:**

- Start a new chat in Open WebUI
- The AI will automatically use the Meilisearch tool when you ask questions about:
  - Open WebUI features and configuration
  - Claude/Anthropic API usage
  - OpenAI API documentation
  - Meilisearch setup and usage
- Example queries:
  - "How do I configure OAuth in Open WebUI?"
  - "What are Claude's rate limits?"
  - "How do I use OpenAI function calling?"

#### Using the Meilisearch Web Interfaces

Meilisearch includes two built-in web interfaces:

**1. Search UI (Port 7701) - Hybrid Search Interface**

A modern search interface for testing hybrid search (keyword + semantic):

- **Access**: http://localhost:7701
- **Features**:
  - Real-time search with live results
  - Adjust semantic ratio (keyword vs. vector search weight)
  - View result highlights and relevance scores
  - Filter by index
  - Responsive design

**2. Admin UI (Port 7702) - Full Management Panel**

Complete admin interface for managing Meilisearch:

- **Access**: http://localhost:7702
- **API Key**: Enter your `MEILI_MASTER_KEY` from `.env` when prompted
- **Features**:
  - 🔍 **Search Preview** - Test searches across all indexes
  - 📊 **Index Management** - View all indexes, document counts, settings
  - 📄 **Document Browser** - Browse and inspect indexed documents
  - ⚙️ **Settings** - Configure synonyms, stop words, ranking rules
  - 🔑 **API Keys** - Manage API keys and permissions
  - 📈 **Stats** - View index statistics and search analytics

**Quick Access:**

```bash
# Get your Meilisearch Master Key
grep MEILI_MASTER_KEY .env

# Open Search UI (hybrid search interface)
open http://localhost:7701
# Or: xdg-open http://localhost:7701 (Linux)
# Or: start http://localhost:7701 (Windows)

# Open Admin UI (full management panel)
open http://localhost:7702
# Or: xdg-open http://localhost:7702 (Linux)
# Or: start http://localhost:7702 (Windows)
```

#### Customizing Indexed Sites

Edit `scrapix.config.json` to add or remove sites:

```json
{
  "start_urls": [
    "https://docs.openwebui.com",
    "https://docs.anthropic.com",
    "https://platform.openai.com/docs",
    "https://docs.meilisearch.com",
    "https://your-custom-docs-site.com"
  ],
  "strategy": "docssearch",
  "urls_to_exclude": [
    "*/api-reference/*",
    "*/changelog/*"
  ]
}
```

After editing, re-run Scrapix to update the index:

```bash
# Clear the existing index (optional)
curl -X DELETE "http://localhost:7700/indexes/web_docs" \
  -H "Authorization: Bearer YOUR_MEILI_MASTER_KEY"

# Re-index with updated configuration
docker compose run scrapix
```

#### Configuring Vector Embeddings

Meilisearch supports semantic search via vector embeddings. Configure an embedder:

```bash
# Run the embedder configuration script
./configure-meilisearch-embedder.sh
```

The script supports:
- **OpenAI** - Use OpenAI's embedding models
- **Ollama** - Use local Ollama embeddings
- **HuggingFace** - Use HuggingFace embedding models

After configuration, your searches will combine keyword and semantic matching for better results.

#### Scrapix Strategies

Choose the appropriate scraping strategy in `scrapix.config.json`:

- **`docssearch`** (recommended for documentation) - Optimized for documentation sites with hierarchical structure
- **`default`** - General-purpose web scraping
- **`schema`** - Extracts structured data using schema.org markup

#### Monitoring Meilisearch

```bash
# Check Meilisearch health
curl http://localhost:7700/health

# View index stats
curl "http://localhost:7700/indexes/web_docs/stats" \
  -H "Authorization: Bearer YOUR_MEILI_MASTER_KEY"

# Search directly via API
curl "http://localhost:7700/indexes/web_docs/search" \
  -H "Authorization: Bearer YOUR_MEILI_MASTER_KEY" \
  -H "Content-Type: application/json" \
  --data-binary '{ "q": "oauth configuration" }'
```

#### Combining with Web Search

Open WebUI can use both Meilisearch (for indexed documentation) and web search (for current information):

- **Meilisearch** - Fast, accurate search of indexed documentation
- **Web Search** - Real-time information from the internet

The AI will choose the appropriate tool based on your query.

### Network Architecture

The stack uses two Docker networks with cross-network access:
- `ai-tools-net` - For Langflow, Open WebUI, Meilisearch, Playwright communication
- `supabase-net` - For all Supabase services

**Important**: Langflow and Open WebUI are connected to BOTH networks, allowing them to:
- Access Supabase services directly (PostgreSQL, Kong API, Storage, etc.)
- Use Supabase as the backend for flows and data storage
- Communicate with each other for workflow integration

## 📁 Data Persistence

All data is stored in `./volumes/`:

```
volumes/
├── langflow/
│   ├── db/          # Langflow PostgreSQL data
│   └── data/        # Langflow flows & configs
├── open-webui/
│   ├── data/        # Chat history & settings
│   └── tools/       # Custom Open WebUI Tools (e.g., Meilisearch)
├── meilisearch/     # Indexed documentation data
├── playwright/      # Browser data
├── db/
│   └── data/        # Supabase PostgreSQL data
├── storage/         # Uploaded files
├── functions/       # Edge functions
├── api/             # Kong configuration
├── logs/            # Vector logging
└── pooler/          # Database pooler config
```

**Backup Recommendation**: Regularly backup the entire `volumes/` directory (see [Backup & Restore](#-backup--restore)).

## 🔐 Security Best Practices

1. **Change all default secrets** - Run `./setup.sh` to generate secure values
2. **Restrict .env permissions** - `chmod 600 .env`
3. **Use strong passwords** - Minimum 16 characters
4. **Enable firewall rules** - Limit port access (ufw/iptables)
5. **Regular backups** - Backup `./volumes/` directory
6. **Update regularly** - Keep Docker images updated
7. **TLS/SSL in production** - Use reverse proxy (nginx/Traefik)
8. **Review exposed ports** - Only expose necessary services
9. **Enable audit logging** - Monitor access to sensitive data
10. **Implement rate limiting** - Prevent abuse

## 🛠️ Management Commands

### Health Check

Run before and after deployment to validate configuration:

```bash
# Check configuration and service status
./scripts/health-check.sh
```

The health check validates:
- Environment variables are properly set
- No insecure default passwords remain
- All required files exist
- Ports are available
- Docker is running
- AI backend is configured

### Service Control

```bash
# Start specific service
docker compose up -d langflow

# Stop all services
docker compose down

# Stop and remove volumes (DANGER: deletes data)
docker compose down -v

# Restart service
docker compose restart open-webui

# View logs for specific service
docker compose logs -f langflow

# View logs for all services
docker compose logs -f

# Check service status
docker compose ps
```

### Database Management

```bash
# Access Supabase PostgreSQL
docker compose exec db psql -U postgres

# Access Langflow PostgreSQL
docker compose exec postgres-langflow psql -U langflow

# Backup Supabase database
docker compose exec db pg_dump -U postgres postgres > backup.sql

# Restore database
docker compose exec -T db psql -U postgres < backup.sql

# Check database health
docker compose exec db pg_isready -U postgres
```

### Updates

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d --force-recreate

# View current versions
docker compose images
```

## 🐛 Troubleshooting

### Services won't start

```bash
# Check logs
docker compose logs

# Check service status
docker compose ps

# Verify .env file
cat .env | grep -v "^#" | grep -v "^$"

# Run health check
./scripts/health-check.sh
```

### Port conflicts

If ports are already in use, edit `.env`:

```bash
LANGFLOW_PORT=7861
OPEN_WEBUI_PORT=8081
STUDIO_PORT=3002
MEILISEARCH_PORT=7701
```

**Note**: Studio port defaults to 3001 to avoid conflicts with common development servers.

### Database connection issues

```bash
# Check database health
docker compose exec db pg_isready -U postgres

# Restart database services
docker compose restart db postgres-langflow

# Check database logs
docker compose logs db
```

### Langflow can't connect to LLM

```bash
# If using Ollama, verify it's running on host
ollama list

# Test connection from inside container
docker compose exec langflow curl http://host.docker.internal:11434

# Check environment variables
docker compose exec langflow env | grep OLLAMA

# Restart Langflow
docker compose restart langflow
```

### Open WebUI can't access models

```bash
# Verify Playwright service
docker compose ps playwright

# Check Open WebUI logs
docker compose logs open-webui

# Restart Open WebUI
docker compose restart open-webui

# Check AI provider configuration
docker compose exec open-webui env | grep -E 'OLLAMA|OPENAI|ANTHROPIC'
```

### Meilisearch search not working

```bash
# Check Meilisearch health
docker compose ps meilisearch
curl http://localhost:7700/health

# Verify index exists and has documents
curl "http://localhost:7700/indexes/web_docs/stats" \
  -H "Authorization: Bearer YOUR_MEILI_MASTER_KEY"

# Check if Scrapix has been run
docker compose logs scrapix

# Re-index documentation
docker compose run scrapix

# Verify the Meilisearch Tool is configured in Open WebUI
# Admin Panel → Tools → Meilisearch Documentation Search → Settings
# Ensure MEILISEARCH_API_KEY matches MEILI_MASTER_KEY from .env
```

### Scrapix fails to index sites

```bash
# Check Scrapix logs for errors
docker compose logs scrapix

# Verify scrapix.config.json exists and is valid
cat scrapix.config.json | jq

# Ensure Meilisearch is healthy before running Scrapix
docker compose ps meilisearch

# Try running Scrapix with verbose output
docker compose run scrapix run -p /app/scrapix.config.json

# Common issues:
# - Network connectivity (Scrapix needs internet access)
# - Invalid URLs in start_urls
# - Sites blocking automated access (check robots.txt)
# - Meilisearch not ready (wait 30s after starting)
```

### Supabase Studio won't load

```bash
# Check all Supabase dependencies
docker compose ps | grep supabase

# Check Studio logs
docker compose logs supabase-studio

# Restart Studio
docker compose restart supabase-studio

# Verify Kong gateway is running
docker compose ps kong
```

### Out of disk space

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Check volume sizes
du -sh volumes/*
```

**📖 For more troubleshooting, see [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**

## 📊 Monitoring

### Resource Usage

```bash
# View resource consumption
docker stats

# Check disk usage by service
du -sh volumes/*

# Monitor specific service
docker stats langflow open-webui
```

### Health Checks

```bash
# All services with health checks
docker compose ps --format "table {{.Name}}\t{{.Status}}"

# Test endpoints
curl http://localhost:7860/health      # Langflow
curl http://localhost:8080/health      # Open WebUI
curl http://localhost:7700/health      # Meilisearch
curl http://localhost:8000/health      # Supabase API
curl http://localhost:3001/api/profile # Supabase Studio
```

### Log Monitoring

```bash
# Follow all logs
docker compose logs -f

# Follow specific service
docker compose logs -f langflow

# View last 100 lines
docker compose logs --tail=100

# Filter logs by time
docker compose logs --since 30m

# Search logs
docker compose logs | grep ERROR
```

## 🔄 Backup & Restore

Automated backup and restore scripts are included in the `scripts/` directory.

### Create a Backup

```bash
# Create compressed backup
./scripts/backup.sh

# Create uncompressed backup
./scripts/backup.sh false
```

The backup script will:
1. Stop services gracefully
2. Copy all volumes (databases, configurations, files)
3. Backup .env and docker-compose files
4. Create backup metadata
5. Compress the backup (optional)
6. Restart services

Backup includes:
- All database data (Supabase, Langflow)
- Uploaded files and storage
- Configuration files (.env, docker-compose.yaml)
- Edge functions
- Logs
- Meilisearch indexes

### Restore from Backup

```bash
# Restore from compressed backup
./scripts/restore.sh backup-20240101-120000.tar.gz

# Restore from uncompressed backup
./scripts/restore.sh backup-20240101-120000
```

The restore script will:
1. Stop services
2. Backup current data before restoring (safety backup)
3. Extract and restore volumes
4. Restore configuration files
5. Restart services

**Warning**: Restore will replace all current data. A safety backup is created automatically.

### Backup Best Practices

- Schedule regular backups (cron job)
- Store backups off-site (S3, external drive)
- Test restore process periodically
- Encrypt backups if they contain sensitive data
- Keep multiple backup versions

## 🌐 Production Deployment

### Using with Reverse Proxy (Nginx)

Example Nginx configuration:

```nginx
# /etc/nginx/sites-available/ai-tools

# Langflow
server {
    listen 80;
    server_name langflow.yourdomain.com;

    location / {
        proxy_pass http://localhost:7860;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Open WebUI
server {
    listen 80;
    server_name chat.yourdomain.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Supabase API
server {
    listen 80;
    server_name db-api.yourdomain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Supabase Studio
server {
    listen 80;
    server_name db-admin.yourdomain.com;

    location / {
        proxy_pass http://localhost:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Meilisearch Search UI (optional, if exposing publicly)
server {
    listen 80;
    server_name search.yourdomain.com;

    location / {
        proxy_pass http://localhost:7701;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SSL with Let's Encrypt

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificates
sudo certbot --nginx -d langflow.yourdomain.com
sudo certbot --nginx -d chat.yourdomain.com
sudo certbot --nginx -d db-api.yourdomain.com
sudo certbot --nginx -d db-admin.yourdomain.com
sudo certbot --nginx -d search.yourdomain.com

# Auto-renewal (already configured by certbot)
sudo certbot renew --dry-run
```

### Environment Variables for Production

Update `.env` for production:

```bash
# Use production domains
SUPABASE_PUBLIC_URL=https://db-api.yourdomain.com
API_EXTERNAL_URL=https://db-api.yourdomain.com
SITE_URL=https://db-admin.yourdomain.com

# Disable auto-login for security
LANGFLOW_AUTO_LOGIN=false
DISABLE_SIGNUP=true

# Enable authentication
WEBUI_AUTH=true

# Use production SMTP
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key

# Pin versions for reproducible deployments
LANGFLOW_VERSION=1.0.18
OPEN_WEBUI_VERSION=v0.1.100
```

### Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw allow 22/tcp      # SSH

# Block direct access to service ports
sudo ufw deny 7860/tcp     # Langflow
sudo ufw deny 8080/tcp     # Open WebUI
sudo ufw deny 8000/tcp     # Supabase API
sudo ufw deny 3001/tcp     # Supabase Studio

# Enable firewall
sudo ufw enable
```

### Security Checklist for Production

Before going to production:

- [ ] Change all default passwords and secrets
- [ ] Set up firewall rules (ufw/iptables)
- [ ] Configure SSL/TLS certificates
- [ ] Enable audit logging
- [ ] Set up intrusion detection
- [ ] Regular security updates
- [ ] Implement rate limiting
- [ ] Configure backup encryption
- [ ] Review and minimize exposed ports
- [ ] Set up monitoring and alerts
- [ ] Disable auto-signup (set `DISABLE_SIGNUP=true`)
- [ ] Use strong authentication (OAuth/OIDC)
- [ ] Enable row-level security in Supabase
- [ ] Review API key permissions

## 🔌 Langflow + Supabase Integration

### Quick Start: Using Supabase in Langflow Flows

Langflow has direct access to all Supabase services. Here's how to use them:

#### 1. PostgreSQL Database Access

In any Langflow flow, use the **PostgreSQL** component:

**Connection Details:**
- Host: `db`
- Port: `5432`
- Database: `postgres`
- User: `postgres`
- Password: (from your `.env` file - `POSTGRES_PASSWORD`)

**Example Use Cases:**
- Store chat history for conversational memory
- Save processed documents and metadata
- Log flow executions
- Store user preferences

#### 2. Vector Search with pgvector

Enable vector search in Supabase Studio:

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE embeddings (
    id BIGSERIAL PRIMARY KEY,
    content TEXT,
    embedding vector(1536),  -- For OpenAI embeddings
    metadata JSONB
);

CREATE INDEX ON embeddings USING ivfflat (embedding vector_cosine_ops);
```

Then use in Langflow for RAG applications:
- Generate embeddings with OpenAI/HuggingFace components
- Store in PostgreSQL with INSERT
- Query with similarity search for relevant context

#### 3. Supabase REST API

Use the **API Request** component in Langflow:

**Base URL:** `http://kong:8000/rest/v1/`

**Required Headers:**
```json
{
  "apikey": "your-anon-key-from-env",
  "Authorization": "Bearer your-anon-key-from-env",
  "Content-Type": "application/json"
}
```

**Example Operations:**
- `GET /rest/v1/table_name` - Read data
- `POST /rest/v1/table_name` - Insert data
- `PATCH /rest/v1/table_name?id=eq.123` - Update data
- `DELETE /rest/v1/table_name?id=eq.123` - Delete data

#### 4. File Storage

Upload and download files in Langflow flows:

**Upload URL:** `http://kong:8000/storage/v1/object/bucket-name/filename`
**Download URL:** `http://kong:8000/storage/v1/object/bucket-name/filename`

Perfect for:
- Processing uploaded documents
- Storing generated files
- Managing media in AI pipelines

#### 5. Authentication

Integrate user authentication in multi-user flows:

**Sign Up:** `POST http://kong:8000/auth/v1/signup`
**Sign In:** `POST http://kong:8000/auth/v1/token?grant_type=password`

Use with Row Level Security (RLS) to ensure users only access their own data.

### Complete Integration Guide

For detailed examples, flow patterns, and advanced usage, see:
**[LANGFLOW_SUPABASE_INTEGRATION.md](docs/LANGFLOW_SUPABASE_INTEGRATION.md)**

This guide includes:
- Complete flow examples (chatbot with memory, RAG, etc.)
- Database schema templates
- Vector search setup
- Security best practices
- Testing procedures

## 🔧 Advanced Configuration

### Local Development Customization

For local development customizations without modifying the main docker-compose.yaml:

```bash
# Create override file
cp docker-compose.override.yml.template docker-compose.override.yml

# Edit with your customizations
nano docker-compose.override.yml

# Docker Compose automatically merges override files
docker compose up -d
```

Use cases for override file:
- Add development tools (pgAdmin, Redis, etc.)
- Change resource limits
- Add custom environment variables
- Mount additional volumes
- Override ports without editing .env

### Edge Functions

Create custom Supabase Edge Functions:

```bash
# Create a new function
mkdir -p volumes/functions/my-function
nano volumes/functions/my-function/index.ts

# Restart functions service
docker compose restart functions

# Access at: http://localhost:8000/functions/v1/my-function
```

See `volumes/functions/README.md` for detailed examples and documentation.

Example functions included:
- `main/` - Main entrypoint (required by runtime)
- `hello-world/` - Simple example function

### Resource Limits

Adjust resource limits in docker-compose.override.yml:

```yaml
services:
  langflow:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 4G
        reservations:
          cpus: '1'
          memory: 2G
```

### Scaling Considerations

#### Horizontal Scaling

For production workloads:

1. **Database** - Consider external managed PostgreSQL (AWS RDS, Supabase Cloud)
2. **Storage** - Use S3-compatible storage (see Supabase S3 configuration)
3. **Load Balancing** - Use nginx/HAProxy for multiple instances
4. **Caching** - Add Redis for session management

#### Vertical Scaling

- Increase RAM allocation for services
- Add CPU cores
- Use SSD storage for databases
- Optimize database indexes

## 📚 Additional Resources

### Documentation Links

- **[QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - Command cheat sheet and quick reference
- **[LANGFLOW_SUPABASE_INTEGRATION.md](docs/LANGFLOW_SUPABASE_INTEGRATION.md)** - Integration guide and examples
- **[AUTHENTIK_SSO_GUIDE.md](docs/AUTHENTIK_SSO_GUIDE.md)** - SSO setup with Authentik
- **[EXTERNAL_AUTHENTIK_SETUP.md](docs/EXTERNAL_AUTHENTIK_SETUP.md)** - External authentication provider setup
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[AUTOMATIC_CONFIGURATION.md](AUTOMATIC_CONFIGURATION.md)** - Details on automatic service setup

### External Documentation

- [Langflow Docs](https://docs.langflow.org/)
- [Open WebUI Docs](https://docs.openwebui.com/)
- [Supabase Docs](https://supabase.com/docs)
- [Meilisearch Docs](https://docs.meilisearch.com/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Deno Edge Functions](https://deno.land/manual)

### Community & Support

- Langflow GitHub: https://github.com/logspace-ai/langflow
- Open WebUI GitHub: https://github.com/open-webui/open-webui
- Supabase GitHub: https://github.com/supabase/supabase
- Meilisearch GitHub: https://github.com/meilisearch/meilisearch

## 🎯 Use Cases

This integrated stack is ideal for:

- **RAG Applications** - Build retrieval-augmented generation with pgvector and Meilisearch
- **Conversational AI** - Chat apps with persistent memory in Supabase
- **Document Processing** - Upload, process, and store documents with metadata
- **Multi-User AI Tools** - User authentication and data isolation with Supabase Auth
- **AI Workflows** - Complex flows with database state management
- **Knowledge Bases** - Vector search across large document collections with hybrid search
- **Internal AI Tools** - Team-wide deployment with user management and SSO
- **Rapid Prototyping** - Full-stack AI apps with auth, database, and storage
- **Edge Deployment** - Self-hosted AI infrastructure with complete control
- **Research & Development** - Experiment with different AI models and workflows
- **Customer Support** - Build AI-powered support systems with chat history
- **Content Generation** - Create content pipelines with AI and storage

## 📞 Getting Help

If you encounter issues:

1. **Run health check**: `./scripts/health-check.sh`
2. **Check the troubleshooting section** above
3. **Review service logs**: `docker compose logs [service-name]`
4. **Verify environment configuration**: `cat .env | grep -v "^#" | grep -v "^$"`
5. **Check GitHub issues** for known problems
6. **Ensure system meets prerequisites**
7. **Review documentation** in the `docs/` directory

### Useful Diagnostic Commands

```bash
# Full health check
./scripts/health-check.sh

# Check all service status
docker compose ps

# View all logs
docker compose logs

# Check specific service
docker compose logs -f langflow

# Verify Docker resources
docker system df
docker stats

# Test database connection
docker compose exec db pg_isready -U postgres

# Check network connectivity
docker compose exec langflow curl http://kong:8000/health

# Verify environment variables
docker compose exec langflow env | grep -E 'OLLAMA|OPENAI|SUPABASE'
```

## 🤝 Contributing

Improvements and suggestions are welcome! Areas for contribution:

1. Additional AI tool integrations
2. Enhanced monitoring and alerting
3. Performance optimization
4. Security hardening
5. Additional example flows and functions
6. Documentation improvements
7. Testing and CI/CD

## 📝 Version Information

### Current Versions (Default)

- **Langflow**: latest
- **Open WebUI**: main
- **Supabase**: Full self-hosted stack (v2.x)
- **PostgreSQL**: 15.x with pgvector
- **Meilisearch**: latest
- **Playwright**: 1.49.1

To update versions, modify the version variables in `.env`.

**Production Recommendation**: Pin specific versions in `.env` instead of using `latest` or `main` to ensure reproducible deployments:

```bash
LANGFLOW_VERSION=1.0.18
OPEN_WEBUI_VERSION=v0.1.100
MEILISEARCH_VERSION=v1.5.1
```

## ⚠️ Known Limitations

1. **Network isolation** - AI tools and Supabase are on separate networks by design (for security)
2. **Resource intensive** - Requires 4GB+ RAM, more for heavy workloads
3. **Initial setup** - Requires downloading Supabase initialization files
4. **Email delivery** - Requires external SMTP service configuration
5. **S3 storage** - File storage uses local filesystem by default (can be configured for S3)
6. **Langflow SSO** - OAuth support is experimental (see GitHub issue #2855)

## 📄 License

This docker-compose configuration is provided as-is. Individual components are licensed under their respective licenses:

- **Langflow**: MIT License
- **Open WebUI**: MIT License
- **Supabase**: Apache 2.0 License
- **Meilisearch**: MIT License

---

**Note**: This is a development/self-hosted configuration. For production deployments, follow the security checklist and implement additional hardening measures.

**Last updated**: December 2024
