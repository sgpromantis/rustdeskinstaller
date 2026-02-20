# Build and Push Docker Image to GHCR
# Run this script from the repository root directory

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Building and Pushing RustDesk Generator to GHCR" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Configuration
$IMAGE_NAME = "ghcr.io/sgpromantis/rustdeskinstaller"
$TAG_LATEST = "${IMAGE_NAME}:latest"

# Login to GHCR
Write-Host "`n[1/3] Logging in to GitHub Container Registry..." -ForegroundColor Yellow
echo "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" | docker login ghcr.io -u sgpromantis --password-stdin

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to login to GHCR" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Successfully logged in to GHCR" -ForegroundColor Green

# Build the Docker image
Write-Host "`n[2/3] Building Docker image..." -ForegroundColor Yellow
Write-Host "   Image: $TAG_LATEST" -ForegroundColor Gray

docker build -t $TAG_LATEST .

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker build failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Docker image built successfully" -ForegroundColor Green

# Push to GHCR
Write-Host "`n[3/3] Pushing image to GHCR..." -ForegroundColor Yellow

docker push $TAG_LATEST

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to push image to GHCR" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Successfully pushed image to GHCR" -ForegroundColor Green

# Summary
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "✅ SUCCESS!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Docker image pushed to: $TAG_LATEST" -ForegroundColor White
Write-Host ""
Write-Host "To deploy on your server, run:" -ForegroundColor Yellow
Write-Host "   docker pull $TAG_LATEST" -ForegroundColor Gray
Write-Host "   docker-compose up -d" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
