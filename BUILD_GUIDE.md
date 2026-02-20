# Building RustDesk Installers - Quick Start Guide

## Important: This is a GitHub Actions-Based Generator

The RustDesk installers are **NOT built locally** on your machine. Instead, this project triggers **GitHub Actions workflows** that build the installers on GitHub's servers. 

## Your Configuration

Your RustDesk installers will be built with:
- **Server**: 212.132.114.192
- **Key**: CctpHu85Bw1iuBwgZTATOjntfQkmqYc1yvs5m2pN+Vk=

## Prerequisites

### 1. GitHub Setup (REQUIRED)

You need a GitHub account with this repository forked and properly configured:

#### Step 1: Verify Your Fork
- This should already be your fork: https://github.com/onlinegill/rustdeskinstaller
- Make sure all the workflow files are present in `.github/workflows/`

#### Step 2: Create a GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click "Generate new token" → "Fine-grained token"
3. Configure the token:
   - **Token name**: RustDesk Generator
   - **Expiration**: 90 days (or your preference)
   - **Repository access**: Only select repositories → Choose `rustdeskinstaller`
   - **Permissions**:
     - Actions: **Read and write**
     - Workflows: **Read and write**
     - Contents: **Read only**
4. Click "Generate token"
5. **IMPORTANT**: Copy the token immediately - you won't see it again!

#### Step 3: Set Environment Variable

**Windows (PowerShell):**
```powershell
$env:GHBEARER = "your_token_here"
```

Or create a `.env` file in the project root:
```bash
GHUSER=onlinegill
GHBEARER=your_token_here
REPONAME=rustdeskinstaller
```

## Option 1: Quick Build (Recommended)

Use the automated build script I've created:

### Run the Build Script

```powershell
cd c:\Users\SebastianGorr\GitHub\rustdeskinstaller
python trigger_builds.py
```

This will trigger builds for:
- ✅ Windows (x64)
- ✅ macOS (Intel and ARM)
- ✅ Linux (DEB, RPM, etc.)

### Monitor Progress

1. Go to: https://github.com/onlinegill/rustdeskinstaller/actions
2. You'll see three workflow runs starting
3. Each build takes 15-30 minutes
4. Download completed builds from the "Artifacts" section of each workflow run

## Option 2: Manual Workflow Trigger

You can also manually trigger builds from GitHub:

1. Go to: https://github.com/onlinegill/rustdeskinstaller/actions
2. Select a workflow (e.g., "Custom Windows Client Generator")
3. Click "Run workflow"
4. Fill in the parameters:
   - **Rendezvous Server**: `212.132.114.192`
   - **Public Key**: `CctpHu85Bw1iuBwgZTATOjntfQkmqYc1yvs5m2pN+Vk=`
   - **API Server**: `212.132.114.192:21114`
   - Leave other fields as default
5. Click "Run workflow"

## Option 3: Web Interface (Advanced)

Run the web-based generator locally:

### Setup

```powershell
# Set environment variables
$env:GHUSER = "onlinegill"
$env:GHBEARER = "your_token_here"
$env:GENURL = "http://localhost:8000"

# Start the server
python manage.py runserver 8000
```

### Use

1. Open: http://localhost:8000
2. Fill in the form with your configuration
3. Select platform (Windows/macOS/Linux)
4. Click "Generate"

## Expected Build Outputs

### Windows
- `rustdesk-{version}-windows-x64.exe` (Installer)
- `rustdesk-{version}-windows-x64-portable.exe` (Portable)

### macOS
- `rustdesk-{version}-macos.dmg` (Universal or Intel)
- `rustdesk-{version}-macos-arm64.dmg` (Apple Silicon)

### Linux
- `rustdesk-{version}-linux-x64.deb` (Debian/Ubuntu)
- `rustdesk-{version}-linux-x64.rpm` (RedHat/Fedora)
- `rustdesk-{version}-linux-x64.pkg` (Arch)

## Troubleshooting

### "Failed to trigger build - 401 Unauthorized"
- Your GitHub token is invalid or expired
- Make sure the token has the correct permissions
- Verify the token is set in the environment variable

### "Failed to trigger build - 404 Not Found"
- The workflow file doesn't exist in your repository
- Check that you have the correct repository name
- Verify the workflows exist in `.github/workflows/`

### "Build failed in GitHub Actions"
- Check the workflow logs on GitHub
- Common issues:
  - Invalid server address format
  - Invalid public key format
  - Missing dependencies (rare - usually auto-fixed)

### "Build is taking too long"
- Normal build time is 15-30 minutes per platform
- Windows builds are typically fastest (~15 minutes)
- macOS builds can take 25-30 minutes
- Check the workflow logs for progress

## Next Steps

1. Set your GitHub token: `$env:GHBEARER = "your_token_here"`
2. Run: `python trigger_builds.py`
3. Monitor builds at: https://github.com/onlinegill/rustdeskinstaller/actions
4. Download completed builds from the Artifacts section

## Notes

- The builds use your server (212.132.114.192) and key automatically
- All builds are configured with the same server settings
- You can customize app name, icon, and other settings in `trigger_builds.py`
- Builds are independent - if one fails, others continue
