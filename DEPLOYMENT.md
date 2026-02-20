# RustDesk Generator Django App - Deployment Guide

This guide will help you deploy the RustDesk Generator Django app alongside your existing RustDesk server (hbbs/hbbr) behind Traefik.

## Overview

The setup adds a Django container to handle the web UI and status callbacks from GitHub Actions, while your RustDesk server continues to handle the protocol traffic.

## Architecture

```
rustdesk.promantis.de
    ├── /generator, /updategh, /api/* → Django App (port 8000)
    └── RustDesk Protocol (ports 21115-21119) → hbbs/hbbr
```

## Prerequisites

- Traefik reverse proxy already running
- Network named `traefik-network` (or adjust docker-compose.yml)
- Your existing RustDesk server running

## Deployment Steps

### 1. Prepare the Server

SSH into your server:
```bash
ssh user@rustdesk.promantis.de
```

### 2. Clone or Copy the Repository

```bash
cd /opt  # or your preferred location
git clone https://github.com/sgpromantis/rustdeskinstaller.git
cd rustdeskinstaller
```

Or if already cloned, pull latest changes:
```bash
cd /opt/rustdeskinstaller
git pull
```

### 3. Configure Environment Variables

Create a `.env` file:
```bash
cp .env.example .env
nano .env  # or use vim, vi, etc.
```

Set these values:
```env
GHUSER=sgpromantis
GHBEARER=your_github_token_here
REPONAME=rustdeskinstaller
SECRET_KEY=generate-a-long-random-string-here
GENURL=https://rustdesk.promantis.de
PROTOCOL=https
```

Generate a secure SECRET_KEY:
```bash
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 4. Adjust Traefik Network (if needed)

Check your Traefik network name:
```bash
docker network ls | grep traefik
```

If it's not called `traefik-network`, edit `docker-compose.yml`:
```yaml
networks:
  traefik-network:
    external: true
    name: your-actual-network-name
```

### 5. Adjust RustDesk Server Priority (Important!)

Your existing RustDesk server container might be catching all traffic to rustdesk.promantis.de. 

Edit your RustDesk server's docker-compose.yml or labels to:
1. Set a lower priority (e.g., priority=50)
2. OR use specific port routing instead of PathPrefix

Example for RustDesk server:
```yaml
labels:
  - "traefik.http.routers.rustdesk.priority=50"  # Lower than Django's 100
```

### 6. Build and Start the Django App

```bash
docker-compose up -d --build
```

Check logs:
```bash
docker-compose logs -f rustdesk-generator
```

### 7. Verify Deployment

Test the endpoints:
```bash
# Test the generator UI
curl -k https://rustdesk.promantis.de/generator

# Test the status callback endpoint
curl -k -X POST https://rustdesk.promantis.de/updategh \
  -H "Content-Type: application/json" \
  -d '{"uuid": "test", "status": "testing"}'
```

You should get responses (not 404).

### 8. Run Database Migrations

If needed, run migrations manually:
```bash
docker-compose exec rustdesk-generator python manage.py migrate
```

### 9. Create Directories for Uploads

Ensure directories exist with proper permissions:
```bash
mkdir -p exe png media
chmod 755 exe png media
```

## Traefik Configuration Reference

The Django app is configured with these Traefik labels:

```yaml
- "traefik.enable=true"
- "traefik.http.routers.rustdesk-gen.rule=Host(`rustdesk.promantis.de`) && (PathPrefix(`/generator`) || PathPrefix(`/updategh`) || ...)"
- "traefik.http.routers.rustdesk-gen.priority=100"  # Higher priority than RustDesk server
```

## Troubleshooting

### 404 Errors on /updategh

1. Check if Django container is running: `docker ps | grep rustdesk-generator`
2. Check Traefik dashboard to see if route is registered
3. Verify priority is higher than RustDesk server router
4. Check logs: `docker-compose logs rustdesk-generator`

### SSL Certificate Issues

The Docker setup uses your existing Traefik TLS/Let's Encrypt configuration. No additional SSL setup needed.

### GitHub Actions Still Failing

1. Verify GENURL secret is set to: `https://rustdesk.promantis.de`
2. Verify `rdgen=true` in trigger_builds.py
3. Check Django logs during a build
4. Test endpoint manually as shown in step 7

## Maintenance

### Update the App

```bash
cd /opt/rustdeskinstaller
git pull
docker-compose up -d --build
```

### View Logs

```bash
docker-compose logs -f rustdesk-generator
```

### Restart the App

```bash
docker-compose restart rustdesk-generator
```

### Backup Database

```bash
cp db.sqlite3 db.sqlite3.backup.$(date +%Y%m%d)
```

## Integration with Existing Setup

This setup should work alongside your existing RustDesk server containers. The key is:

1. **Traefik routes by path**: Django handles `/generator`, `/updategh`, etc.
2. **RustDesk protocol ports**: Your hbbs/hbbr continue to handle ports 21115-21119
3. **Priority routing**: Django router has priority=100, ensure RustDesk server has lower priority

## Next Steps

After deployment:
1. Test the generator UI: https://rustdesk.promantis.de/generator
2. Restart GitHub Actions builds from your local machine
3. Watch the builds complete successfully
4. Download artifacts from GitHub Actions

## Support

If you encounter issues:
- Check Traefik dashboard for route configuration
- Check container logs: `docker-compose logs rustdesk-generator`
- Verify environment variables: `docker-compose config`
- Test endpoints with curl as shown above
