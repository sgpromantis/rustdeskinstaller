# Server Integration Guide

## ✅ Image Published to GHCR
The Docker image has been successfully built and pushed to:
```
ghcr.io/sgpromantis/rustdeskinstaller:latest
```

## 📋 Prerequisites on Server

### 1. Create directories for persistent storage
```bash
mkdir -p rustdesk-generator/{exe,png,media}
chmod 755 rustdesk-generator/{exe,png,media}
```

### 2. Add to your .env file
Add these variables to your existing `.env` file on the server:
```bash
# RustDesk Generator Configuration
GHUSER=sgpromantis
GHBEARER=your_github_personal_access_token_here
REPONAME=rustdeskinstaller
SECRET_KEY=YOUR_RANDOM_SECRET_KEY_HERE_CHANGE_THIS
```

**Generate a SECRET_KEY:**
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(50))"
```

**Note:** Use your GitHub Personal Access Token with `repo` and `workflow` permissions.

## 🐳 Add Service to docker-compose.yml

Add this service definition to your existing `docker-compose.yml` under the `services:` section, right after the RustDesk section:

```yaml
  # ═══════════════════════════════════════════════════════════════════════════
  #  RUSTDESK GENERATOR (Custom Installer Builder)
  # ═══════════════════════════════════════════════════════════════════════════

  rustdesk-generator:
    image: ghcr.io/sgpromantis/rustdeskinstaller:latest
    container_name: rustdesk-generator
    restart: unless-stopped
    
    environment:
      # GitHub Configuration
      - GHUSER=${GHUSER}
      - GHBEARER=${GHBEARER}
      - REPONAME=${REPONAME}
      
      # Django Configuration
      - SECRET_KEY=${SECRET_KEY}
      - GENURL=https://rustdesk.${DOMAIN}
      - PROTOCOL=https
      - ALLOWED_HOSTS=rustdesk.${DOMAIN}
    
    volumes:
      # Persistent storage for generated files
      - ./rustdesk-generator/exe:/app/exe
      - ./rustdesk-generator/png:/app/png
      - ./rustdesk-generator/media:/app/media
    
    networks:
      - proxy
    
    labels:
      # Traefik configuration
      - "traefik.enable=true"
      
      # Router - matches web paths for Django app
      - "traefik.http.routers.rustdesk-gen.rule=Host(`rustdesk.${DOMAIN}`) && (PathPrefix(`/generator`) || PathPrefix(`/updategh`) || PathPrefix(`/api/updategh`) || PathPrefix(`/check_for_file`) || PathPrefix(`/download`) || PathPrefix(`/get_png`) || PathPrefix(`/save_custom_client`) || PathPrefix(`/creategh`) || PathPrefix(`/startgh`))"
      - "traefik.http.routers.rustdesk-gen.entrypoints=https"
      - "traefik.http.routers.rustdesk-gen.tls=true"
      - "traefik.http.routers.rustdesk-gen.tls.certresolver=letsencrypt"
      - "traefik.http.routers.rustdesk-gen.service=rustdesk-gen"
      - "traefik.http.services.rustdesk-gen.loadbalancer.server.port=8000"
      
      # Priority: Higher than RustDesk server to match Django paths first
      - "traefik.http.routers.rustdesk-gen.priority=100"
      
      # Auto-update with Watchtower
      - "com.centurylinklabs.watchtower.enable=true"
      - "traefik.docker.network=proxy"
```

## 🚀 Deployment Commands

### On your server:

1. **Navigate to your docker-compose directory:**
   ```bash
   cd /path/to/your/docker-compose/directory
   ```

2. **Edit .env file:**
   ```bash
   nano .env
   # Add the RustDesk Generator variables shown above
   ```

3. **Edit docker-compose.yml:**
   ```bash
   nano docker-compose.yml
   # Add the rustdesk-generator service definition shown above
   ```

4. **Pull the image from GHCR:**
   ```bash
   docker compose pull rustdesk-generator
   ```

5. **Start the service:**
   ```bash
   docker compose up -d rustdesk-generator
   ```

6. **Check logs:**
   ```bash
   docker compose logs -f rustdesk-generator
   ```

## ✅ Verification

Once deployed, the generator will be available at:
- **Web UI:** `https://rustdesk.promantis.de/generator`
- **Status Callback:** `https://rustdesk.promantis.de/updategh` (used by GitHub Actions)
- **API Callback:** `https://rustdesk.promantis.de/api/updategh` (alternative endpoint)

## 🔄 Updates

The service has Watchtower auto-update enabled. When you push a new image to GHCR, Watchtower will automatically update the container within 60 seconds.

To manually update:
```bash
docker compose pull rustdesk-generator
docker compose up -d rustdesk-generator
```

## 🎯 Next Steps

After deploying the generator:

1. **Test the web interface:**
   ```
   https://rustdesk.promantis.de/generator
   ```

2. **Run the build script locally** to trigger installer generation:
   ```bash
   cd c:\Users\SebastianGorr\GitHub\rustdeskinstaller
   python trigger_builds.py
   ```

3. **Monitor build progress** via GitHub Actions:
   - Windows: Workflow ID 236678191
   - macOS: Workflow ID 236678184
   - Linux: Workflow ID 236678174

## 📊 Architecture

```
Client Request → Traefik (Port 443) → Path-based Routing
                                      ↓
                    /generator → rustdesk-generator:8000 (Django)
                    /updategh  → rustdesk-generator:8000 (Django)
                    /api/*     → rustdesk-generator:8000 (Django)
                                      ↓
                    Other paths → hbbs:21118 (RustDesk Web UI)
```

The priority routing ensures Django paths match before RustDesk protocol handlers.

## 🔧 Troubleshooting

### Check if container is running:
```bash
docker ps | grep rustdesk-generator
```

### View detailed logs:
```bash
docker compose logs --tail=100 rustdesk-generator
```

### Test connectivity:
```bash
curl -I https://rustdesk.promantis.de/generator
```

### Restart service:
```bash
docker compose restart rustdesk-generator
```

### Check Traefik routing:
Visit `https://traefik-rust.promantis.de` and verify the `rustdesk-gen` router is active.
