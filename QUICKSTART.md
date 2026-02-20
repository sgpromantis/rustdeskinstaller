# Quick Start - Deploy from GHCR

This is the fastest way to deploy the RustDesk Generator app using the pre-built Docker image.

## 🚀 Quick Deploy (5 minutes)

On your server with Traefik already running:

```bash
# 1. Create directory
mkdir -p /opt/rustdeskinstaller && cd /opt/rustdeskinstaller

# 2. Download docker-compose.yml
curl -o docker-compose.yml https://raw.githubusercontent.com/sgpromantis/rustdeskinstaller/master/docker-compose.yml

# 3. Create .env file
cat > .env << 'EOF'
GHUSER=sgpromantis
GHBEARER=your_github_token_here
REPONAME=rustdeskinstaller
SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(50))")
GENURL=https://rustdesk.promantis.de
PROTOCOL=https
EOF

# 4. Create directories
mkdir -p exe png media && chmod 755 exe png media

# 5. Start!
docker-compose up -d

# 6. Check logs
docker-compose logs -f
```

## 📦 Docker Image

- **Registry:** GitHub Container Registry (GHCR)
- **Image:** `ghcr.io/sgpromantis/rustdeskinstaller:latest`
- **Public:** Yes, no authentication required
- **Auto-updated:** Builds automatically on every push to master

## 🔄 Update

```bash
docker-compose pull && docker-compose up -d
```

## 📚 Full Documentation

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete details.

## 🛠️ Development

To build locally instead of using GHCR:

```bash
docker-compose -f docker-compose.dev.yml up -d --build
```

---

**After deployment:**
- Web UI: `https://rustdesk.promantis.de/generator`
- Status endpoint: `https://rustdesk.promantis.de/updategh`
