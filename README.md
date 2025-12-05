# AI Tool Server Stack

A comprehensive Docker Compose stack combining AI development tools (Langflow, Open WebUI) with Supabase backend infrastructure.

## 🏗️ Architecture

This stack integrates AI development tools with Supabase as the backend storage layer:

### AI Tools Layer
- **Langflow** (port 7860) - Visual AI workflow builder with direct Supabase integration
- **Open WebUI** (port 8080) - Modern LLM chat interface
- **Playwright** (internal) - Browser automation for Open WebUI

### Supabase Backend Layer (Storage for AI Flows)
- **PostgreSQL** - Primary database with pgvector for embeddings
- **PostgREST** - Auto-generated REST API for database access
- **GoTrue** - Authentication & user management
- **Realtime** - WebSocket subscriptions for live updates
- **Storage** - File storage with image transformation
- **Kong** - API gateway (port 8000)
- **Studio** - Database management UI (port 3001)
- **Edge Functions** - Serverless functions
- **Analytics** - Logging & monitoring

### Key Integration Points
- **Langflow → Supabase PostgreSQL**: Direct database access for storing flow data, chat history, embeddings
- **Langflow → Supabase REST API**: Use PostgREST for CRUD operations in flows
- **Langflow → Supabase Storage**: File upload/download in processing pipelines
- **Langflow → Supabase Auth**: User authentication in multi-user flows
- **Langflow → pgvector**: Vector similarity search for RAG applications

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose V2
- 4GB+ RAM recommended
- (Optional) Ollama running locally for LLM inference

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Clone or download the stack files
cd ai-tool-server

# Make setup script executable
chmod +x setup.sh

# Run setup to generate secure secrets
./setup.sh
```

### 2. Create Required Supabase Files

Supabase requires several SQL initialization files. Create the directory structure:

```bash
mkdir -p volumes/db
mkdir -p volumes/api
mkdir -p volumes/functions
mkdir -p volumes/logs
mkdir -p volumes/pooler
mkdir -p volumes/storage
```

Download the required files from the Supabase repository:
```bash
# These files are needed in volumes/db/
curl -o volumes/db/realtime.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/realtime.sql
curl -o volumes/db/webhooks.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/webhooks.sql
curl -o volumes/db/roles.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/roles.sql
curl -o volumes/db/jwt.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/jwt.sql
curl -o volumes/db/_supabase.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/_supabase.sql
curl -o volumes/db/logs.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/logs.sql
curl -o volumes/db/pooler.sql https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/db/pooler.sql

# Kong configuration
curl -o volumes/api/kong.yml https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/api/kong.yml

# Vector configuration
mkdir -p volumes/logs
curl -o volumes/logs/vector.yml https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/logs/vector.yml

# Pooler configuration
curl -o volumes/pooler/pooler.exs https://raw.githubusercontent.com/supabase/supabase/master/docker/volumes/pooler/pooler.exs
```

### 3. Configure Environment

Edit `.env` and update:

```bash
# For production deployment
SUPABASE_PUBLIC_URL=https://your-domain.com
API_EXTERNAL_URL=https://api.your-domain.com
SITE_URL=https://your-domain.com

# If using Ollama
OLLAMA_BASE_URL=http://host.docker.internal:11434

# If using OpenAI
OPENAI_API_KEY=sk-your-openai-key

# SMTP for email (if needed)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
```

### 4. Start the Stack

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Check service health
docker compose ps
```

### 5. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Langflow | http://localhost:7860 | Create on first visit |
| Open WebUI | http://localhost:8080 | Create on first visit |
| Supabase Studio | http://localhost:3001 | From .env |
| Supabase API | http://localhost:8000 | Use API keys |

## 🔧 Configuration

### Using with Ollama

1. Install Ollama on your host machine
2. Pull a model: `ollama pull llama3.2`
3. The stack is pre-configured to connect via `host.docker.internal:11434`

### Using with OpenAI

1. Set `OPENAI_API_KEY` in `.env`
2. Both Langflow and Open WebUI will use this key

### Network Architecture

The stack uses two Docker networks with cross-network access:
- `ai-tools-net` - For Langflow, Open WebUI, Playwright communication
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
│   └── data/        # Chat history & settings
├── playwright/      # Browser data
├── db/
│   └── data/        # Supabase PostgreSQL data
├── storage/         # Uploaded files
└── functions/       # Edge functions
```

## 🔐 Security Best Practices

1. **Change all default secrets** - Run `./setup.sh` to generate secure values
2. **Restrict .env permissions** - `chmod 600 .env`
3. **Use strong passwords** - Minimum 16 characters
4. **Enable firewall rules** - Limit port access
5. **Regular backups** - Backup `./volumes/` directory
6. **Update regularly** - Keep Docker images updated
7. **TLS/SSL in production** - Use reverse proxy (nginx/Traefik)

## 🛠️ Management Commands

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
```

### Updates

```bash
# Pull latest images
docker compose pull

# Recreate containers with new images
docker compose up -d --force-recreate
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
```

### Port conflicts

If ports are already in use, edit `.env`:
```bash
LANGFLOW_PORT=7861
OPEN_WEBUI_PORT=8081
STUDIO_PORT=3002
```

### Database connection issues

```bash
# Check database health
docker compose exec db pg_isready -U postgres

# Restart database services
docker compose restart db postgres-langflow
```

### Langflow can't connect to LLM

```bash
# If using Ollama, verify it's running on host
ollama list

# Test connection from inside container
docker compose exec langflow curl http://host.docker.internal:11434

# Check environment variables
docker compose exec langflow env | grep OLLAMA
```

### Open WebUI can't access models

```bash
# Verify Playwright service
docker compose ps playwright

# Check Open WebUI logs
docker compose logs open-webui

# Restart Open WebUI
docker compose restart open-webui
```

### Supabase Studio won't load

```bash
# Check all Supabase dependencies
docker compose ps | grep supabase

# Verify analytics service (required dependency)
docker compose logs analytics

# Restart Studio
docker compose restart supabase-studio
```

### Out of disk space

```bash
# Check Docker disk usage
docker system df

# Clean up unused resources
docker system prune -a --volumes

# Remove old images
docker image prune -a
```

## 📊 Monitoring

### Resource Usage

```bash
# View resource consumption
docker stats

# Check disk usage by service
du -sh volumes/*
```

### Health Checks

```bash
# All services with health checks
docker compose ps --format "table {{.Name}}\t{{.Status}}"

# Test endpoints
curl http://localhost:7860/health      # Langflow
curl http://localhost:8080/health      # Open WebUI
curl http://localhost:8000/health      # Supabase API
curl http://localhost:3001/api/profile # Supabase Studio
```

## 🔄 Backup & Restore

### Full Backup

```bash
#!/bin/bash
# backup.sh - Backup all data

BACKUP_DIR="backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Stop services
docker compose down

# Backup volumes
cp -r volumes "$BACKUP_DIR/"

# Backup configuration
cp .env "$BACKUP_DIR/"
cp docker-compose.yaml "$BACKUP_DIR/"

# Restart services
docker compose up -d

echo "Backup created in $BACKUP_DIR"
```

### Restore from Backup

```bash
#!/bin/bash
# restore.sh - Restore from backup

if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup-directory>"
    exit 1
fi

BACKUP_DIR=$1

# Stop services
docker compose down -v

# Restore volumes
rm -rf volumes
cp -r "$BACKUP_DIR/volumes" .

# Restore configuration
cp "$BACKUP_DIR/.env" .
cp "$BACKUP_DIR/docker-compose.yaml" .

# Start services
docker compose up -d

echo "Restore completed from $BACKUP_DIR"
```

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
    server_name api.yourdomain.com;
    
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
    server_name studio.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:3001;
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
sudo certbot --nginx -d api.yourdomain.com
sudo certbot --nginx -d studio.yourdomain.com

# Auto-renewal (already configured by certbot)
sudo certbot renew --dry-run
```

### Environment Variables for Production

Update `.env` for production:

```bash
# Use production domains
SUPABASE_PUBLIC_URL=https://api.yourdomain.com
API_EXTERNAL_URL=https://api.yourdomain.com
SITE_URL=https://studio.yourdomain.com

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
```

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
**[LANGFLOW_SUPABASE_INTEGRATION.md](computer:///mnt/user-data/outputs/LANGFLOW_SUPABASE_INTEGRATION.md)**

This guide includes:
- Complete flow examples (chatbot with memory, RAG, etc.)
- Database schema templates
- Vector search setup
- Security best practices
- Testing procedures

## 📚 Additional Resources

### Documentation Links

- [Langflow Docs](https://docs.langflow.org/)
- [Open WebUI Docs](https://docs.openwebui.com/)
- [Supabase Docs](https://supabase.com/docs)
- [Docker Compose Docs](https://docs.docker.com/compose/)

### Community & Support

- Langflow GitHub: https://github.com/logspace-ai/langflow
- Open WebUI GitHub: https://github.com/open-webui/open-webui
- Supabase GitHub: https://github.com/supabase/supabase

## 🤝 Contributing

Improvements and suggestions are welcome! Areas for contribution:

1. Additional AI tool integrations
2. Enhanced monitoring and alerting
3. Automated backup scripts
4. Performance optimization
5. Security hardening

## 📝 Version Information

### Current Versions (Default)

- Langflow: latest
- Open WebUI: main
- Supabase: Full self-hosted stack (v2.x)
- PostgreSQL: 15.x
- Playwright: 1.49.1

To update versions, modify the version variables in `.env`.

## ⚠️ Known Limitations

1. **Network isolation** - AI tools and Supabase are on separate networks by design
2. **Resource intensive** - Requires 4GB+ RAM, more for heavy workloads
3. **Initial setup** - Requires downloading Supabase initialization files
4. **Email delivery** - Requires external SMTP service configuration
5. **S3 storage** - File storage uses local filesystem by default

## 🔐 Security Considerations

### Before Production

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

### Secrets Management

Never commit `.env` to version control. Consider using:
- Docker secrets for production
- External secret managers (HashiCorp Vault, AWS Secrets Manager)
- Environment variable injection from CI/CD

## 📈 Scaling Considerations

### Horizontal Scaling

For production workloads:

1. **Database** - Consider external managed PostgreSQL (AWS RDS, Supabase Cloud)
2. **Storage** - Use S3-compatible storage (see Supabase S3 configuration)
3. **Load Balancing** - Use nginx/HAProxy for multiple instances
4. **Caching** - Add Redis for session management

### Vertical Scaling

Adjust resource limits in docker-compose.yaml:

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

## 🎯 Use Cases

This integrated stack is ideal for:

- **RAG Applications** - Build retrieval-augmented generation with pgvector
- **Conversational AI** - Chat apps with persistent memory in Supabase
- **Document Processing** - Upload, process, and store documents with metadata
- **Multi-User AI Tools** - User authentication and data isolation with Supabase Auth
- **AI Workflows** - Complex flows with database state management
- **Knowledge Bases** - Vector search across large document collections
- **Internal AI Tools** - Team-wide deployment with user management
- **Rapid Prototyping** - Full-stack AI apps with auth, database, and storage
- **Edge Deployment** - Self-hosted AI infrastructure with complete control

## 📞 Getting Help

If you encounter issues:

1. Check the troubleshooting section above
2. Review service logs: `docker compose logs [service-name]`
3. Verify environment configuration
4. Check GitHub issues for known problems
5. Ensure system meets prerequisites

## 📄 License

This docker-compose configuration is provided as-is. Individual components are licensed under their respective licenses:

- Langflow: MIT License
- Open WebUI: MIT License  
- Supabase: Apache 2.0 License

---

**Note**: This is a development/self-hosted configuration. For production deployments, consider using managed services or implementing additional security hardening measures.

Last updated: December 2025