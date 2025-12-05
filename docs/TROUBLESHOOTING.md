# Troubleshooting Guide - AI Tool Server Stack

## 🔍 Diagnostic Flowchart

### START HERE: Service won't start?

```
Service won't start
    ↓
Check logs: docker compose logs [service]
    ↓
┌─────────────────────────────────────────┐
│  Error message indicates...             │
├─────────────────────────────────────────┤
│                                         │
│  "Port already in use"                  │
│  └→ Change port in .env                 │
│     └→ docker compose up -d             │
│                                         │
│  "Connection refused" (database)        │
│  └→ Check db health: docker compose    │
│     exec db pg_isready -U postgres      │
│     └→ If unhealthy: restart db         │
│                                         │
│  "Permission denied"                    │
│  └→ Check volume permissions           │
│     └→ sudo chown -R $(id -u):$(id -g) │
│        volumes/                         │
│                                         │
│  "Out of memory"                        │
│  └→ Increase Docker memory limit       │
│     └→ Stop other services              │
│                                         │
│  "Network error"                        │
│  └→ Recreate networks:                 │
│     docker compose down                 │
│     docker compose up -d                │
│                                         │
│  "Environment variable not set"         │
│  └→ Check .env file exists             │
│     └→ Verify all required vars set    │
│                                         │
└─────────────────────────────────────────┘
```

## 🚨 Common Issues & Solutions

### Issue 1: "Cannot start service langflow: driver failed"

**Symptoms:**
- Langflow container fails to start
- Error about volume mounting

**Solutions:**
```bash
# Check if directory exists
ls -la volumes/langflow

# Create if missing
mkdir -p volumes/langflow/{db,data}

# Fix permissions
sudo chown -R $(id -u):$(id -g) volumes/langflow

# Restart
docker compose restart langflow
```

---

### Issue 2: "Connection refused" when accessing services

**Symptoms:**
- Can't access http://localhost:7860 or other URLs
- Services show as "Up" in docker ps

**Solutions:**
```bash
# Check if service is actually listening
docker compose ps

# Check logs for binding errors
docker compose logs langflow | grep -i "listening\|bind\|error"

# Verify port mapping
docker compose ps --format "table {{.Name}}\t{{.Ports}}"

# Check if port is already in use on host
sudo lsof -i :7860
sudo netstat -tulpn | grep :7860

# Change port in .env if needed
# Then restart: docker compose up -d
```

---

### Issue 3: "Unhealthy" status in docker ps

**Symptoms:**
- Service shows as "unhealthy" in docker compose ps
- Service not responding to requests

**Solutions:**
```bash
# Check health check logs
docker compose logs [service] | tail -50

# Check if service endpoint is accessible
docker compose exec [service] curl -f http://localhost:[port]/health

# Common fixes:
# 1. Database not ready - wait and check again
docker compose logs db

# 2. Dependency not started - check depends_on services
docker compose ps

# 3. Restart with fresh state
docker compose restart [service]
```

---

### Issue 4: Langflow can't connect to database

**Symptoms:**
- Langflow logs show database connection errors
- "could not connect to server" messages

**Solutions:**
```bash
# Check if postgres-langflow is running
docker compose ps postgres-langflow

# Check database health
docker compose exec postgres-langflow pg_isready -U langflow

# Verify connection string in logs
docker compose logs langflow | grep LANGFLOW_DATABASE_URL

# Check network connectivity
docker compose exec langflow ping postgres-langflow

# Reset database if corrupted
docker compose down
docker volume rm $(docker volume ls -q | grep langflow)
docker compose up -d
```

---

### Issue 5: Open WebUI can't connect to Ollama

**Symptoms:**
- Open WebUI can't see models
- "Failed to fetch models" error

**Solutions:**
```bash
# Verify Ollama is running on host
ollama list
ollama serve

# Check if Open WebUI can reach host
docker compose exec open-webui curl http://host.docker.internal:11434

# Verify environment variable
docker compose exec open-webui env | grep OLLAMA

# Check if using correct URL format
# Should be: http://host.docker.internal:11434
# Not: http://localhost:11434

# Restart Open WebUI
docker compose restart open-webui
```

---

### Issue 6: Supabase Studio won't load

**Symptoms:**
- Blank page or loading forever
- Studio accessible but shows errors

**Solutions:**
```bash
# Check all required services are healthy
docker compose ps | grep supabase

# Analytics must be healthy (Studio depends on it)
docker compose logs analytics | tail -50

# Check if database is accessible
docker compose exec db psql -U postgres -c "SELECT version();"

# Verify Kong gateway is working
curl http://localhost:8000/health

# Check Studio logs for specific errors
docker compose logs supabase-studio

# Full restart of Supabase stack
docker compose restart analytics db kong supabase-studio
```

---

### Issue 7: "No space left on device"

**Symptoms:**
- Services fail to start or create files
- Docker operations fail

**Solutions:**
```bash
# Check disk usage
df -h
docker system df

# Clean up unused Docker resources
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Remove stopped containers
docker container prune

# Check volume sizes
du -sh volumes/*

# If still full, remove old backups
rm -rf backup-*

# Consider moving volumes to larger disk
```

---

### Issue 8: Services very slow or unresponsive

**Symptoms:**
- High CPU/memory usage
- Services timeout
- Host system sluggish

**Solutions:**
```bash
# Check resource usage
docker stats

# Identify resource hog
docker stats --no-stream | sort -k 4 -h

# Check host resources
free -h
top

# Stop non-essential services
docker compose stop [service]

# Add resource limits to docker-compose.yaml:
# deploy:
#   resources:
#     limits:
#       cpus: '2'
#       memory: 2G

# Restart Docker daemon
sudo systemctl restart docker
```

---

### Issue 9: "Cannot connect to Docker daemon"

**Symptoms:**
- Docker commands fail
- "Is the docker daemon running?" error

**Solutions:**
```bash
# Check if Docker is running
sudo systemctl status docker

# Start Docker if stopped
sudo systemctl start docker

# Check user permissions
sudo usermod -aG docker $USER
newgrp docker

# Verify socket permissions
ls -la /var/run/docker.sock

# Restart Docker
sudo systemctl restart docker
```

---

### Issue 10: Environment variables not being read

**Symptoms:**
- Services use default values
- Configuration doesn't apply

**Solutions:**
```bash
# Verify .env exists in same directory as docker-compose.yaml
ls -la .env

# Check .env format (no spaces around =)
cat .env | grep -v "^#" | head

# Verify variable syntax
# WRONG: PORT = 8080
# RIGHT: PORT=8080

# Force recreation to pick up new env vars
docker compose down
docker compose up -d

# Check if variable is set in container
docker compose exec [service] env | grep [VARIABLE]
```

---

## 🔧 Advanced Troubleshooting

### Get detailed container information
```bash
docker inspect [container-name]
docker compose config
```

### Check network connectivity between services
```bash
docker compose exec langflow ping db
docker compose exec open-webui nc -zv playwright 3000
```

### View real-time logs from multiple services
```bash
docker compose logs -f langflow open-webui | grep -i error
```

### Check for mount issues
```bash
docker compose exec [service] ls -la /path/in/container
```

### Validate docker-compose.yaml syntax
```bash
docker compose config
```

---

## 🆘 Emergency Recovery

### Complete reset (NUCLEAR OPTION - destroys all data)
```bash
# Backup first if possible!
docker compose down -v
rm -rf volumes/*
./setup.sh
# Re-download Supabase files
docker compose up -d
```

### Restore from backup
```bash
docker compose down
tar -xzf backup-[date].tar.gz
docker compose up -d
```

---

## 📞 Still Having Issues?

1. **Check logs systematically**
   ```bash
   docker compose logs > full-logs.txt
   ```

2. **Verify system requirements**
   - Docker version: `docker --version` (need 20.10+)
   - Compose version: `docker compose version` (need V2)
   - Free memory: `free -h` (need 4GB+)
   - Free disk: `df -h` (need 10GB+)

3. **Create minimal reproduction**
   ```bash
   docker compose down
   docker compose up -d db postgres-langflow
   # Test if databases work first
   docker compose up -d langflow
   # Add services one at a time
   ```

4. **Check GitHub issues**
   - Langflow: https://github.com/logspace-ai/langflow/issues
   - Open WebUI: https://github.com/open-webui/open-webui/issues
   - Supabase: https://github.com/supabase/supabase/issues

5. **Generate diagnostic report**
   ```bash
   echo "=== Docker Info ===" > diagnostic.txt
   docker version >> diagnostic.txt
   echo "=== Compose Info ===" >> diagnostic.txt
   docker compose version >> diagnostic.txt
   echo "=== Service Status ===" >> diagnostic.txt
   docker compose ps >> diagnostic.txt
   echo "=== Resource Usage ===" >> diagnostic.txt
   docker stats --no-stream >> diagnostic.txt
   echo "=== Recent Logs ===" >> diagnostic.txt
   docker compose logs --tail=100 >> diagnostic.txt
   ```

---

## 💡 Prevention Tips

1. **Regular maintenance**
   ```bash
   # Weekly: clean up unused resources
   docker system prune

   # Monthly: update images
   docker compose pull && docker compose up -d
   ```

2. **Monitor disk space**
   ```bash
   df -h
   du -sh volumes/*
   ```

3. **Keep backups**
   ```bash
   # Automated backup script
   0 2 * * 0 cd /path/to/stack && ./backup.sh
   ```

4. **Document changes**
   - Note any `.env` changes
   - Keep track of custom modifications
   - Maintain a change log

---

**Remember**: When in doubt, check the logs first!
```bash
docker compose logs -f [service-name]
```