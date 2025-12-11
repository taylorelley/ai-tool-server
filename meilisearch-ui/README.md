# Meilisearch UI - Runtime Configuration Fix

## Problem

The original `meilisearch-ui` service used a pre-built Docker image with Vite environment variables. This caused a critical issue:

**Vite environment variables (`VITE_*`) are build-time variables**, not runtime variables. This means:

1. When the Docker image is built, Vite compiles the environment variables directly into the JavaScript bundle
2. Setting these variables in `docker-compose.yaml` has **no effect** because the JavaScript is already compiled
3. When the frontend loads in your browser, it tries to connect to Meilisearch with an empty or incorrect API key
4. This results in a **403 "invalid API key" error**

## Solution

This directory contains a custom Dockerfile and entrypoint script that **inject environment variables at runtime**:

### How It Works

1. **Custom Dockerfile** (`Dockerfile`)
   - Extends the base `meilisearch-simple-hybrid-search-frontend` image
   - Adds a custom entrypoint script

2. **Entrypoint Script** (`entrypoint.sh`)
   - Runs when the container starts (not when the image is built)
   - Creates a `config.js` file with runtime environment variables
   - Injects this config file into `index.html`
   - The frontend loads this config file and uses the runtime values

3. **Updated docker-compose.yaml**
   - Now builds the image locally instead of using the pre-built one
   - Environment variables are properly injected at container startup

### Files

- **`Dockerfile`** - Extends base image with custom entrypoint
- **`entrypoint.sh`** - Script that injects runtime environment variables
- **`README.md`** - This documentation

## Usage

The fix is automatic when you use `docker compose up`:

```bash
# Build and start services
docker compose up -d

# Rebuild if needed
docker compose build meilisearch-ui
docker compose up -d meilisearch-ui
```

## Configuration

Environment variables are passed through from `docker-compose.yaml`:

- `VITE_MEILISEARCH_HOST` - Meilisearch server URL
- `VITE_MEILISEARCH_API_KEY` - Meilisearch API key (from `MEILI_MASTER_KEY`)
- `VITE_MEILISEARCH_INDEX` - Default search index
- `VITE_APP_TITLE` - Application title
- `VITE_MEILISEARCH_SEMANTIC_RATIO` - Semantic search ratio
- `VITE_MEILISEARCH_EMBEDDER` - Embedder name

## Verification

After starting the container, you can verify the runtime config:

```bash
# Check the generated config file
docker exec meilisearch-ui cat /usr/share/nginx/html/config.js

# Check container logs for injection messages
docker logs meilisearch-ui
```

You should see:
```
🔧 Injecting runtime environment variables into Meilisearch UI...
✅ Runtime config created at /usr/share/nginx/html/config.js
📝 Configuration:
   Host: http://localhost:7700
   Index: web_docs
   API Key: ***configured***
✅ Runtime config script injected into index.html
🚀 Starting nginx...
```

## Technical Details

### Why Vite Variables Don't Work at Runtime

Vite uses environment variables during the build process:

```javascript
// During build, Vite replaces this:
const apiKey = import.meta.env.VITE_MEILISEARCH_API_KEY;

// With this (hardcoded):
const apiKey = "abc123...";
```

Once built, the JavaScript bundle contains hardcoded values. Setting environment variables in Docker **after** the build has no effect.

### Our Runtime Injection Approach

Instead, we generate a config file at container startup:

```javascript
// config.js (generated at runtime)
window.__RUNTIME_CONFIG__ = {
  VITE_MEILISEARCH_API_KEY: "actual-runtime-value"
};
```

The frontend can then access these values:

```javascript
const apiKey = window.__RUNTIME_CONFIG__.VITE_MEILISEARCH_API_KEY;
```

This pattern works because:
1. The config file is created when the container starts
2. It uses actual environment variable values from the running container
3. The frontend loads this file and uses the runtime values
4. No rebuild required when changing environment variables

## Maintenance

If you need to modify the runtime configuration:

1. Edit `entrypoint.sh` to add/remove environment variables
2. Rebuild the image: `docker compose build meilisearch-ui`
3. Restart the service: `docker compose up -d meilisearch-ui`

## Troubleshooting

### Still getting 403 errors?

1. Check that the `MEILI_MASTER_KEY` is set in `.env`:
   ```bash
   grep MEILI_MASTER_KEY .env
   ```

2. Verify the config file was generated:
   ```bash
   docker exec meilisearch-ui cat /usr/share/nginx/html/config.js
   ```

3. Check container logs:
   ```bash
   docker logs meilisearch-ui
   ```

### Frontend not loading config?

The entrypoint script automatically injects the config.js script tag into index.html. If this fails:

1. Check the container logs for errors
2. Manually verify index.html:
   ```bash
   docker exec meilisearch-ui grep "config.js" /usr/share/nginx/html/index.html
   ```

### Need to change API key?

1. Update `.env` with new `MEILI_MASTER_KEY`
2. Restart the container:
   ```bash
   docker compose restart meilisearch-ui
   ```

The entrypoint script runs on every container start, so it will pick up the new value.
