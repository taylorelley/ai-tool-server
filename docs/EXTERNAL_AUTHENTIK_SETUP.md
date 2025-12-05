# Connecting to External Authentik - Setup Guide

## 🎯 Overview

This stack is configured to use your **existing Authentik instance** for Single Sign-On (SSO). Authentik runs elsewhere on your network, and this stack's services (Open WebUI, Langflow) will authenticate through it.

## 📋 Prerequisites

- ✅ Authentik instance already running and accessible
- ✅ Admin access to your Authentik instance
- ✅ Network connectivity from Docker host to Authentik
- ✅ Authentik URL (e.g., `https://auth.yourdomain.com` or `http://192.168.1.100:9000`)

## 🔧 Step 1: Configure .env File

### Set Authentik URL

Edit `.env` and update:

```bash
# Point to your existing Authentik instance
AUTHENTIK_URL=https://auth.yourdomain.com

# Or if using IP address:
AUTHENTIK_URL=http://192.168.1.100:9000

# Or if Authentik is on the same Docker host:
AUTHENTIK_URL=http://host.docker.internal:9000
```

### Set Service URLs

```bash
# Update for your deployment
OPEN_WEBUI_URL=http://localhost:8080
LANGFLOW_URL=http://localhost:7860

# For production with domains:
OPEN_WEBUI_URL=https://chat.yourdomain.com
LANGFLOW_URL=https://flow.yourdomain.com
```

## 🌐 Step 2: Verify Network Connectivity

Before proceeding, ensure your Docker containers can reach Authentik:

```bash
# Start the stack
docker compose up -d

# Test connectivity from Open WebUI container
docker compose exec open-webui curl -I https://auth.yourdomain.com

# Expected: HTTP 200 or 301/302 redirect
# If connection fails, check:
# - Firewall rules
# - DNS resolution
# - Network routing
```

### Common Network Scenarios

#### Scenario 1: Authentik on Same Docker Host

If Authentik is running in Docker on the same machine:

```bash
# Use host.docker.internal
AUTHENTIK_URL=http://host.docker.internal:9000
```

#### Scenario 2: Authentik on Different Machine (Same Network)

```bash
# Use Authentik's IP address or hostname
AUTHENTIK_URL=https://192.168.1.100:9000
# or
AUTHENTIK_URL=https://auth.local
```

#### Scenario 3: Authentik with Public Domain

```bash
# Use the public URL
AUTHENTIK_URL=https://auth.yourdomain.com
```

## 🔐 Step 3: Configure OAuth in Authentik

### For Open WebUI

#### 3.1 Create OAuth2/OpenID Provider

1. Log into your Authentik instance
2. Navigate to **Admin Interface**
3. Go to **Applications** → **Providers**
4. Click **Create**
5. Select **OAuth2/OpenID Provider**

Configure the provider:

| Field | Value |
|-------|-------|
| Name | `Open WebUI` |
| Authorization flow | `default-provider-authorization-implicit-consent` |
| Client type | `Confidential` |
| Client ID | *Auto-generated - copy this!* |
| Client Secret | *Auto-generated - copy this!* |
| Redirect URIs | `http://localhost:8080/oauth/oidc/callback` |
|  | (or `https://chat.yourdomain.com/oauth/oidc/callback` for production) |
| Signing Key | Select any available key |
| Encryption Key | **Leave BLANK** (critical!) |

**Advanced Settings**:
- Scopes: Select `openid`, `email`, `profile`
- Subject mode: `Based on the User's hashed ID`

Click **Finish** and **copy the Client ID and Client Secret**!

#### 3.2 Create Application

1. Go to **Applications** → **Applications**
2. Click **Create**
3. Configure:

| Field | Value |
|-------|-------|
| Name | `Open WebUI` |
| Slug | `open-webui` |
| Provider | Select `Open WebUI` (from step 3.1) |
| UI settings | Optional: Add icon, description |

4. Click **Create**

#### 3.3 Update .env with OAuth Credentials

Edit your `.env` file:

```bash
# Add the credentials from Authentik
OPEN_WEBUI_OAUTH_CLIENT_ID=your_client_id_here
OPEN_WEBUI_OAUTH_CLIENT_SECRET=your_client_secret_here
```

#### 3.4 Restart Open WebUI

```bash
docker compose restart open-webui
```

#### 3.5 Test SSO

1. Navigate to `http://localhost:8080`
2. You should see **"Continue with Authentik"** button
3. Click it to authenticate via your Authentik instance
4. After successful authentication, you'll be redirected back

**Note**: New users will have "Pending" status and require admin approval.

### For Langflow (When Supported)

**Current Status**: Langflow doesn't officially support OIDC yet ([Issue #2855](https://github.com/langflow-ai/langflow/issues/2855)).

When support is added, follow the same steps but use:
- Redirect URI: `http://localhost:7860/api/auth/callback/authentik`
- Application slug: `langflow`

Then update `.env`:
```bash
LANGFLOW_OAUTH_CLIENT_ID=your_client_id_here
LANGFLOW_OAUTH_CLIENT_SECRET=your_client_secret_here
```

## 🛡️ Step 4: Security Considerations

### Firewall Rules

Ensure these ports are accessible:

**From Docker containers to Authentik:**
- Port 443 (HTTPS) - if using `https://auth.yourdomain.com`
- Port 9000 (or your Authentik port) - if using HTTP

**From users to services:**
- Port 8080 - Open WebUI
- Port 7860 - Langflow  
- Port 3000 - Supabase Studio
- Port 8000 - Supabase API

### SSL/TLS Recommendations

For production:

1. **Use HTTPS for Authentik**
   - Certificate from Let's Encrypt or your CA
   - Update `AUTHENTIK_URL=https://auth.yourdomain.com`

2. **Use reverse proxy for AI services**
   - Nginx or Traefik with SSL termination
   - Update redirect URIs in Authentik to use HTTPS

3. **Update OAuth redirect URIs**
   ```
   Production: https://chat.yourdomain.com/oauth/oidc/callback
   NOT: http://localhost:8080/oauth/oidc/callback
   ```

### Network Security

```bash
# If using firewall, allow traffic:
# From Docker host to Authentik
sudo ufw allow out to <authentik-ip> port 9000

# From internet to services (if public)
sudo ufw allow 8080/tcp  # Open WebUI
sudo ufw allow 7860/tcp  # Langflow
```

## 🐛 Troubleshooting

### Issue: "Failed to fetch OIDC configuration"

**Possible causes:**
1. Authentik URL is incorrect
2. Network connectivity issue
3. Firewall blocking connection

**Solution:**
```bash
# Test connectivity
docker compose exec open-webui curl -v ${AUTHENTIK_URL}/.well-known/openid-configuration

# Check logs
docker compose logs open-webui | grep -i auth
docker compose logs open-webui | grep -i oidc

# Verify AUTHENTIK_URL in .env
cat .env | grep AUTHENTIK_URL
```

### Issue: "Redirect URI mismatch"

**Solution:**
1. In Authentik, verify redirect URI exactly matches
2. Check protocol (`http://` vs `https://`)
3. Check port number
4. No trailing slashes
5. Correct path: `/oauth/oidc/callback`

Example correct URIs:
- ✅ `http://localhost:8080/oauth/oidc/callback`
- ✅ `https://chat.yourdomain.com/oauth/oidc/callback`
- ❌ `http://localhost:8080/oauth/oidc/callback/` (trailing slash)
- ❌ `http://localhost:8080/` (missing path)

### Issue: "Connection refused" or "Connection timeout"

**For Authentik on same Docker host:**
```bash
# Try host.docker.internal
AUTHENTIK_URL=http://host.docker.internal:9000

# Or find Docker bridge IP
docker network inspect bridge | grep Gateway
# Use gateway IP: http://172.17.0.1:9000
```

**For Authentik on different machine:**
```bash
# Check firewall
ping <authentik-ip>
telnet <authentik-ip> 9000

# Check from container
docker compose exec open-webui ping <authentik-ip>
docker compose exec open-webui curl -I http://<authentik-ip>:9000
```

### Issue: "No SSO button appears"

**Checklist:**
```bash
# 1. Verify WEBUI_URL is set BEFORE OAuth setup
echo $WEBUI_URL

# 2. Check OAuth variables are set
cat .env | grep OAUTH

# 3. Verify Authentik URL is accessible
docker compose exec open-webui curl -I ${AUTHENTIK_URL}

# 4. Check logs
docker compose logs open-webui | tail -50

# 5. Restart with clean state
docker compose down
docker compose up -d
```

### Issue: SSL Certificate Errors

If using self-signed certificates for Authentik:

**Not recommended**, but if needed:
```bash
# Add to Open WebUI environment (not secure!)
- NODE_TLS_REJECT_UNAUTHORIZED=0
```

**Better solution**: Use proper SSL certificates (Let's Encrypt)

## 📊 Verification Checklist

After setup, verify:

- [ ] Can access Authentik at `${AUTHENTIK_URL}`
- [ ] Docker containers can reach Authentik
- [ ] OAuth provider created in Authentik
- [ ] Application created and linked to provider
- [ ] Client ID and Secret copied to .env
- [ ] Open WebUI restarted
- [ ] SSO button appears on Open WebUI login page
- [ ] Can click SSO button and redirect to Authentik
- [ ] Can authenticate in Authentik
- [ ] Successfully redirected back to Open WebUI
- [ ] User created in Open WebUI (pending approval)

## 🔄 Production Deployment

### Update All URLs

```bash
# .env for production
AUTHENTIK_URL=https://auth.yourdomain.com
OPEN_WEBUI_URL=https://chat.yourdomain.com
LANGFLOW_URL=https://flow.yourdomain.com
SUPABASE_PUBLIC_URL=https://api.yourdomain.com
```

### Update OAuth Redirect URIs in Authentik

1. Admin Interface → Applications → Providers
2. Edit your Open WebUI provider
3. Update Redirect URIs:
   - Remove: `http://localhost:8080/oauth/oidc/callback`
   - Add: `https://chat.yourdomain.com/oauth/oidc/callback`
4. Save

### Restart Services

```bash
docker compose down
docker compose up -d
```

## 📚 Additional Resources

- **Authentik Docs**: https://docs.goauthentik.io/
- **Open WebUI SSO**: https://docs.openwebui.com/features/auth/sso/
- **Authentik OAuth Provider**: https://docs.goauthentik.io/docs/providers/oauth2/

## 🎉 Success!

Once configured, your users can:
1. Visit Open WebUI
2. Click "Continue with Authentik"
3. Authenticate once in Authentik
4. Access all integrated services with SSO

**Benefits:**
- Centralized user management in your existing Authentik
- Single login for multiple services
- MFA and security policies from Authentik apply
- No need to maintain separate Authentik instance