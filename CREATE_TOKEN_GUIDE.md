# Creating a GitHub Token for RustDesk Builds

## The Issue
Your current token lacks the necessary permissions. You need a token with workflow dispatch permissions.

## Solution: Create a Fine-Grained Personal Access Token

### Step 1: Go to Token Settings
Visit: https://github.com/settings/tokens?type=beta

### Step 2: Click "Generate new token"

### Step 3: Configure Token Settings

**Token name**: `RustDesk Build Trigger`

**Expiration**: Choose 90 days (or longer)

**Resource owner**: Select `onlinegill` (or your username)

### Step 4: Repository Access
- Select **"Only select repositories"**
- Choose **`onlinegill/rustdeskinstaller`**

### Step 5: Repository Permissions (CRITICAL)

Set these permissions:

| Permission | Access Level |
|------------|--------------|
| **Actions** | ✅ **Read and write** |
| **Contents** | ✅ **Read and write** |
| **Metadata** | ✅ **Read-only** (auto-selected) |
| **Workflows** | ✅ **Read and write** |

⚠️ **IMPORTANT**: Make sure both "Actions" and "Workflows" are set to "Read and write"

### Step 6: Generate Token
1. Scroll to bottom
2. Click "Generate token"
3. **COPY THE TOKEN IMMEDIATELY** - you won't see it again!

### Step 7: Use the Token

In PowerShell:
```powershell
$env:GHBEARER = "paste_your_new_token_here"
$env:GHUSER = "onlinegill"
python trigger_builds.py
```

---

## Alternative: Use Classic Personal Access Token

If fine-grained tokens don't work, use a classic token:

### Step 1: Go to Classic Tokens
Visit: https://github.com/settings/tokens

### Step 2: Generate New Token (Classic)
Click "Generate new token (classic)"

### Step 3: Select Scopes
Check these boxes:
- ✅ **workflow** (this includes everything needed)
- ✅ **repo** (optional, for full repository access)

### Step 4: Generate and Copy
1. Click "Generate token"
2. Copy the token immediately

### Step 5: Use It
```powershell
$env:GHBEARER = "ghp_your_new_classic_token_here"
python trigger_builds.py
```

---

## Verify Token Permissions

After creating your token, you can test it:

```powershell
$headers = @{
    "Authorization" = "Bearer $env:GHBEARER"
    "Accept" = "application/vnd.github+json"
}
Invoke-RestMethod -Uri "https://api.github.com/repos/onlinegill/rustdeskinstaller" -Headers $headers | Select-Object name,permissions
```

This should show the repository with your permissions.
