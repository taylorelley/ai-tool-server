# AI Tool Server Stack - Quick Reference

## 🚀 Initial Setup (One-time)

```bash
chmod +x setup.sh
./setup.sh
# Edit .env with your settings
# Download Supabase files (see README)
docker compose up -d
```

## 🎮 Daily Operations

### Start/Stop Services

```bash
docker compose up -d              # Start all services
docker compose down               # Stop all services
docker compose restart [service]  # Restart specific service
docker compose ps                 # Check service status
```

### View Logs

```bash
docker compose logs -f                    # All services
docker compose logs -f langflow           # Langflow only
docker compose logs -f open-webui         # Open WebUI only
docker compose logs --tail=100 [service]  # Last 100 lines
```

### Access Services

| Service | URL | Purpose |
|---------|-----|---------|
| Langflow | http://localhost:7860 | AI workflow builder |
| Open WebUI | http://localhost:8080 | Chat interface |
| Supabase Studio | http://localhost:3001 | Database UI |
| Supabase API | http://localhost:8000 | REST API |

## 🔧 Common Tasks

### Update Images

```bash
docker compose pull
docker compose up -d --force-recreate
```

### Backup Data

```bash
# Quick backup
docker compose down
tar -czf backup-$(date +%Y%m%d).tar.gz volumes/ .env
docker compose up -d
```

### Clean Up

```bash
docker system prune -a --volumes  # Remove unused resources
docker volume ls                  # List volumes
docker compose down -v            # Remove all (DANGER!)
```

### Database Access

```bash
# Supabase PostgreSQL
docker compose exec db psql -U postgres

# Langflow PostgreSQL
docker compose exec postgres-langflow psql -U langflow -d langflow
```

## 🐛 Quick Troubleshooting

### Service won't start
```bash
docker compose logs [service-name]
docker compose restart [service-name]
```

### Port already in use
Edit `.env` and change the port variables

### Out of memory
```bash
docker stats                    # Check usage
docker compose restart [service]
```

### Reset everything
```bash
docker compose down -v
rm -rf volumes/
./setup.sh
# Re-download Supabase files
docker compose up -d
```

## 🔑 Generate New Secrets

```bash
# Single secret
openssl rand -base64 32

# Multiple secrets
for i in {1..5}; do openssl rand -base64 32; done
```

## 📊 Health Checks

```bash
# Quick check all services
docker compose ps

# Test endpoints
curl http://localhost:7860/health     # Langflow
curl http://localhost:8080/health     # Open WebUI
curl http://localhost:8000/health     # Supabase
```

## 🔒 Security Quick Checks

```bash
# Check .env permissions (should be 600)
ls -l .env

# Verify no default passwords
grep "changeme" .env

# Check exposed ports
docker compose ps --format "table {{.Name}}\t{{.Ports}}"
```

## 💾 Resource Monitoring

```bash
# Real-time resource usage
docker stats

# Disk usage by service
du -sh volumes/*

# Docker disk usage
docker system df
```

## 🔄 Service Dependencies

Start order (automatic but useful to know):
1. Database services (db, postgres-langflow, vector)
2. Analytics
3. Core Supabase (auth, rest, storage, meta, kong)
4. AI Tools (langflow, open-webui, playwright)

## 📝 Configuration Files

```
.
├── docker-compose.yaml   # Service definitions
├── .env                  # Configuration (don't commit!)
├── .env.template         # Template for .env
├── setup.sh             # Setup script
├── README.md            # Full documentation
└── volumes/             # Persistent data
    ├── langflow/
    ├── open-webui/
    ├── db/
    ├── storage/
    └── ...
```

## 🆘 Emergency Commands

### Service crashed
```bash
docker compose restart [service]
```

### Complete reset (DANGER: deletes all data!)
```bash
docker compose down -v
rm -rf volumes/
# Re-run setup
```

### View container details
```bash
docker compose config              # Validate config
docker inspect [container-name]    # Detailed info
```

### Network issues
```bash
docker network ls                  # List networks
docker compose down && docker compose up -d  # Recreate
```

## 📱 Quick URLs (Bookmarks)

Save these for quick access:
- Langflow: http://localhost:7860
- Chat: http://localhost:8080
- Studio: http://localhost:3001
- API Docs: http://localhost:8000/rest/v1/

## 🔗 Important Variables in .env

**Must Change:**
- All `changeme_*` values
- `POSTGRES_PASSWORD`
- `JWT_SECRET`
- `ANON_KEY` and `SERVICE_ROLE_KEY`
- `WEBUI_SECRET_KEY`

**Configure for your setup:**
- `OLLAMA_BASE_URL` (if using Ollama)
- `OPENAI_API_KEY` (if using OpenAI)
- `SMTP_*` settings (for emails)

**Production additions:**
- `SUPABASE_PUBLIC_URL`
- `API_EXTERNAL_URL`
- `SITE_URL`

## 📞 Need Help?

1. Check logs: `docker compose logs [service]`
2. Read full docs: `README.md`
3. Verify config: `cat .env | grep -v "^#"`
4. Check GitHub issues for services
5. Restart: `docker compose restart`

---
**Tip**: Keep this file handy for quick command reference!