# Authentik SSO Integration Guide

## 🎯 Overview

This stack uses **Authentik** as the centralized Single Sign-On (SSO) provider for all services:
- **Open WebUI** - Full OIDC/OAuth2 integration ✅
- **Langflow** - Experimental OIDC support (when available) ⚠️
- **Supabase Studio** - Basic auth (Authentik integration possible via reverse proxy) 🔧

Authentik provides:
- Single Sign-On across all applications
- Multi-Factor Authentication (MFA)
- User and group management
- OAuth2/OIDC, SAML support
- Customizable authentication flows

## 📋 Prerequisites

- Stack deployed and running
- Access to Authentik admin interface
- Domain names configured (for production)

## 🚀 Initial Authentik Setup

### 1. Access Authentik

After starting the stack:
```bash
docker compose up -d
```

Navigate to: **http://localhost:9000/if/flow/initial-setup/**

### 2. Create Admin Account

- Enter your desired admin email
- Set a strong password
- Complete the setup wizard

### 3. Access Admin Interface

- Click the user icon (top right)
- Select "Admin Interface"

## 🔧 Configure OAuth for Open WebUI

### Step 1: Create OAuth2/OIDC Provider

1. Navigate to **Applications** → **Providers**
2. Click **Create**
3. Select **OAuth2/OpenID Provider**
4. Configure:

| Setting | Value |
|---------|-------|
| Name | `Open WebUI` |
| Authorization flow | `default-provider-authorization-implicit-consent` |
| Client type | `Confidential` |
| Client ID | Auto-generated (copy this!) |
| Client Secret | Auto-generated (copy this!) |
| Redirect URIs | `http://localhost:8080/oauth/oidc/callback` |
| Signing Key | Select any available key |
| **IMPORTANT** | Leave "Encryption Key" BLANK |

5. Under **Advanced protocol settings**:
   - Scopes: Select `openid`, `email`, `profile`
   - Subject mode: `Based on the User's hashed ID`

6. Click **Finish**

**IMPORTANT**: Copy the Client ID and Client Secret!

### Step 2: Create Application

1. Navigate to **Applications** → **Applications**
2. Click **Create**
3. Configure:

| Setting | Value |
|---------|-------|
| Name | `Open WebUI` |
| Slug | `open-webui` |
| Provider | Select `Open WebUI` (from Step 1) |
| UI settings (optional) | Add logo/description |

4. Click **Create**

### Step 3: Update Environment Variables

Edit your `.env` file:

```bash
# Open WebUI OAuth Configuration
OPEN_WEBUI_URL=http://localhost:8080
OPEN_WEBUI_OAUTH_CLIENT_ID=<paste Client ID from Step 1>
OPEN_WEBUI_OAUTH_CLIENT_SECRET=<paste Client Secret from Step 1>
ENABLE_OAUTH_SIGNUP=true
ENABLE_LOCAL_LOGIN=true  # Set to false to disable local auth

# Authentik Issuer
AUTHENTIK_ISSUER_URL=http://localhost:9000
```

### Step 4: Restart Open WebUI

```bash
docker compose restart open-webui
```

### Step 5: Test SSO Login

1. Navigate to **http://localhost:8080**
2. You should see "Continue with Authentik" button
3. Click it and authenticate with Authentik
4. You'll be redirected back to Open WebUI

**Note**: First-time users will need admin approval. Log in as admin to approve pending users at **http://localhost:8080/admin/users**

## 🔧 Configure OAuth for Langflow (When Supported)

**Current Status**: Langflow has an open feature request for SSO support ([Issue #2855](https://github.com/langflow-ai/langflow/issues/2855)).

When Langflow adds official OIDC support, follow similar steps:

### Step 1: Create Provider

1. **Applications** → **Providers** → **Create**
2. **OAuth2/OpenID Provider**
3. Configure:
   - Name: `Langflow`
   - Redirect URIs: `http://localhost:7860/api/auth/callback/authentik`
   - Copy Client ID and Secret

### Step 2: Create Application

1. **Applications** → **Applications** → **Create**
2. Name: `Langflow`, Slug: `langflow`
3. Provider: `Langflow`

### Step 3: Update .env

```bash
LANGFLOW_URL=http://localhost:7860
LANGFLOW_OAUTH_CLIENT_ID=<Client ID>
LANGFLOW_OAUTH_CLIENT_SECRET=<Client Secret>
```

### Step 4: Restart

```bash
docker compose restart langflow
```

## 🔒 Supabase Studio with Authentik

Supabase Studio uses basic authentication by default. For Authentik SSO integration, you need a reverse proxy (Nginx/Traefik) with Authentik forward auth.

### Option 1: Keep Basic Auth

Studio is protected by Kong's basic auth:
- Username: `supabase` (from `DASHBOARD_USERNAME`)
- Password: From `DASHBOARD_PASSWORD` in .env

### Option 2: Reverse Proxy with Authentik (Advanced)

Example Nginx configuration with Authentik forward auth:

```nginx
location /studio/ {
    auth_request /outpost.goauthentik.io/auth/nginx;
    auth_request_set $auth_cookie $upstream_http_set_cookie;
    add_header Set-Cookie $auth_cookie;
    
    proxy_pass http://localhost:3000/;
    proxy_set_header Host $host;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
}

location /outpost.goauthentik.io {
    proxy_pass http://localhost:9000/outpost.goauthentik.io;
    proxy_set_header Host $host;
}
```

## 👥 User & Group Management

### Create Users

1. **Directory** → **Users** → **Create**
2. Fill in user details
3. Set password or send invitation email

### Create Groups

1. **Directory** → **Groups** → **Create**
2. Name the group (e.g., `open-webui-admins`)
3. Add users to the group

### Assign Groups to Applications

1. **Applications** → Select your app
2. **Policy / Group / User Bindings** tab
3. **Create Binding** → Select group
4. Set order and enable binding

## 🔐 Enable Multi-Factor Authentication (MFA)

### Global MFA Policy

1. **Flows & Stages** → **Stages**
2. Find or create authenticator stages:
   - **TOTP Authenticator Setup Stage**
   - **TOTP Authenticator Validation Stage**
3. **Flows & Stages** → **Flows**
4. Edit `default-authentication-flow`
5. Add MFA stages to the flow

### Per-Application MFA

1. **Applications** → Select application
2. **Policy Bindings** tab
3. Create policy requiring MFA for specific groups

## 🌐 Production Configuration

### Update URLs for Production

```bash
# .env file
AUTHENTIK_ISSUER_URL=https://auth.yourdomain.com
OPEN_WEBUI_URL=https://chat.yourdomain.com
LANGFLOW_URL=https://flow.yourdomain.com
SUPABASE_PUBLIC_URL=https://api.yourdomain.com

# Update OAuth Redirect URIs in Authentik
# Open WebUI: https://chat.yourdomain.com/oauth/oidc/callback
# Langflow: https://flow.yourdomain.com/api/auth/callback/authentik
```

### SSL/TLS Setup

For production, use a reverse proxy with SSL:

```nginx
# Authentik
server {
    listen 443 ssl http2;
    server_name auth.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Open WebUI
server {
    listen 443 ssl http2;
    server_name chat.yourdomain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 🐛 Troubleshooting

### Issue: "Redirect URI mismatch"

**Solution**: Ensure redirect URI in Authentik exactly matches your application URL:
- Open WebUI: `http://localhost:8080/oauth/oidc/callback`
- Include the protocol (`http://` or `https://`)
- Match the port number

### Issue: "No SSO button appears in Open WebUI"

**Checklist**:
1. `WEBUI_URL` is set BEFORE enabling OAuth
2. `OPENID_PROVIDER_URL` is correct
3. `OAUTH_CLIENT_ID` and `OAUTH_CLIENT_SECRET` are set
4. Container was restarted after env changes

**Fix**:
```bash
# If ENABLE_OAUTH_PERSISTENT_CONFIG=true (default)
# Either set it to false:
echo "ENABLE_OAUTH_PERSISTENT_CONFIG=false" >> .env

# OR update via Admin Panel instead of .env
# Go to Admin Panel > Settings > update OAuth settings

docker compose restart open-webui
```

### Issue: "Failed to fetch user info"

**Solution**: Verify that Authentik provider includes these scopes:
- `openid`
- `email`
- `profile`

Also check that "Encryption Key" is LEFT BLANK in provider settings.

### Issue: "OPENID_PROVIDER_URL not found"

**Solution**: Verify the URL format is correct:
```bash
# Correct format:
OPENID_PROVIDER_URL=http://localhost:9000/application/o/open-webui/.well-known/openid-configuration

# NOT:
OPENID_PROVIDER_URL=http://localhost:9000  # Too short
OPENID_PROVIDER_URL=http://localhost:9000/application/o/open-webui/  # Missing discovery path
```

### Issue: Users created but status is "Pending"

**Solution**: This is normal! Admins must approve new users:
1. Log in to Open WebUI as admin
2. Go to **Admin Panel** > **Users**
3. Find pending user
4. Change role from "Pending" to "User" or "Admin"

### Issue: Can't log in after enabling SSO

**Solution**: If you disabled local login (`ENABLE_LOGIN_FORM=false`) but SSO isn't working:

```bash
# Temporarily re-enable local login
sed -i 's/ENABLE_LOGIN_FORM=false/ENABLE_LOGIN_FORM=true/' .env
docker compose restart open-webui

# Log in with local account
# Fix SSO configuration
# Test SSO works
# Then disable local login again if desired
```

## 📚 Advanced Configurations

### Custom Authentication Flows

Authentik allows you to customize the entire authentication flow:

1. **Flows & Stages** → **Flows**
2. Duplicate `default-authentication-flow`
3. Add/remove/reorder stages:
   - Email verification
   - Terms of service acceptance
   - Custom prompts
   - External OAuth sources

4. Assign custom flow to your provider

### Social Login Integration

Add Google, GitHub, Microsoft, etc. as authentication sources:

1. **System** → **Sources** → **Create**
2. Select source type (e.g., "OAuth Source: Google")
3. Configure OAuth credentials from the provider
4. Add source to authentication flow

### Group-Based Access Control

Control which groups can access specific applications:

1. **Policies** → **Create** → **Group Membership Policy**
2. Select required groups
3. **Applications** → Select app → **Policy Bindings**
4. Bind the group policy

### Automated User Provisioning

Use SCIM or LDAP to provision users from external systems:

1. **Providers** → **Create** → **SCIM Provider**
2. Configure endpoint and credentials
3. Map user attributes
4. External system pushes users to Authentik

## 🔗 Integration with External Services

### Slack/Discord Bot Authentication

Authentik can authenticate bots and service accounts:

1. Create a service account user
2. Generate an API token
3. Use token in bot configuration

### CI/CD Pipeline Authentication

Protect CI/CD systems with Authentik:

1. Configure OAuth provider for Jenkins/GitLab
2. Users authenticate via Authentik
3. Centralized access control

## 📊 Monitoring & Auditing

### View Authentication Logs

1. **Events** → **Logs**
2. Filter by:
   - User
   - Application
   - Event type (login, logout, failed auth)
   - Date range

### Set Up Alerts

1. **Events** → **Notification Rules**
2. Create rules for:
   - Failed login attempts
   - Account lockouts
   - Privilege escalations

### Export Logs

Authentik logs can be exported to external systems:
- Syslog
- Elasticsearch
- Splunk
- Custom webhooks

## 🎓 Best Practices

1. **Use Strong Passwords**: Enforce password policies in Authentik
2. **Enable MFA**: Require MFA for admin accounts at minimum
3. **Regular Backups**: Backup Authentik database regularly
4. **Audit Logs**: Review authentication logs periodically
5. **Principle of Least Privilege**: Grant minimum required permissions
6. **Session Management**: Configure appropriate session timeouts
7. **Test in Staging**: Test SSO changes in non-production first
8. **Document Changes**: Keep track of provider/app configurations
9. **Monitor Failed Logins**: Set up alerts for suspicious activity
10. **Update Regularly**: Keep Authentik updated for security patches

## 📞 Getting Help

- **Authentik Docs**: https://docs.goauthentik.io/
- **Open WebUI SSO Docs**: https://docs.openwebui.com/features/auth/sso/
- **Langflow Issues**: https://github.com/langflow-ai/langflow/issues

## 🎉 Success!

You now have a fully integrated SSO system with Authentik! All users can authenticate once and access multiple services seamlessly.

**Next Steps**:
- Configure MFA for enhanced security
- Set up additional OAuth providers (Google, GitHub, etc.)
- Customize authentication flows for your needs
- Integrate more applications with Authentik