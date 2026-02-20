#!/usr/bin/env python3
"""
RustDesk Build Trigger Script
Triggers GitHub Actions workflows to build custom RustDesk installers
for Windows, macOS, and Linux with your server configuration.
"""

import requests
import json
import base64
import uuid
import os
import sys
from datetime import datetime

# ========== Configuration ==========
# GitHub Configuration - Set these as environment variables or edit here
GITHUB_USERNAME = os.environ.get("GHUSER", "sgpromantis")  # Your GitHub username
GITHUB_TOKEN = os.environ.get("GHBEARER", "")  # Your GitHub Personal Access Token
REPO_NAME = os.environ.get("REPONAME", "rustdeskinstaller")  # Your repo name

# RustDesk Configuration
RUSTDESK_SERVER = "212.132.114.192"
RUSTDESK_KEY = "CctpHu85Bw1iuBwgZTATOjntfQkmqYc1yvs5m2pN+Vk="
API_SERVER = f"{RUSTDESK_SERVER}:21114"

# Build Configuration
APP_NAME = "Promantis Remote"
FILE_NAME = "promantis_remote"
COMPANY_NAME = "Promantis"
VERSION = "1.3.3"  # RustDesk version to build (1.3.3, 1.3.6, 1.3.7, 1.4.0, 1.4.1, 1.4.2, 1.4.3, or 'master')

# Logo Configuration
# Option 1: Use a URL to your logo (recommended for GitHub Actions)
LOGO_URL = "https://raw.githubusercontent.com/sgpromantis/rustdeskinstaller/master/promantis_logo_2048_white.png"
# Option 2: Use GitHub raw URL after committing logo to repo
# Example: "https://raw.githubusercontent.com/sgpromantis/rustdeskinstaller/master/prepared_images/promantis_logo.png"
ICON_URL = "https://raw.githubusercontent.com/sgpromantis/rustdeskinstaller/master/promantis_logo_2048_white.png"  # Using same logo for icon

# Build UUID (unique identifier for this build)
BUILD_UUID = str(uuid.uuid4())

# ========== Build Settings ==========
def create_custom_config():
    """Create the custom configuration JSON"""
    custom_config = {
        'app-name': APP_NAME,
        'enable-lan-discovery': 'Y',
        'direct-server': 'N',
        'allow-auto-disconnect': 'Y',
        'approve-mode': 'password',
        'default-settings': {
            'access-mode': 'full',
            'enable-keyboard': 'Y',
            'enable-clipboard': 'Y',
            'enable-file-transfer': 'Y',
            'enable-audio': 'Y',
            'enable-tunnel': 'Y',
            'enable-remote-restart': 'Y',
            'enable-record-session': 'N',
            'enable-block-input': 'N',
            'allow-remote-config-modification': 'Y',
        }
    }
    
    # Encode to base64
    custom_json = json.dumps(custom_config)
    custom_bytes = custom_json.encode("ascii")
    custom_base64 = base64.b64encode(custom_bytes).decode("ascii")
    
    return custom_base64


def create_extras():
    """Create the extras configuration JSON"""
    extras = {
        'version': VERSION,
        'rdgen': 'true',  # Set to true to avoid callback URL issues
        'genurl': 'https://github.com',  # Dummy URL to prevent errors
        'compname': COMPANY_NAME,
        'slogan': 'professionell. progressiv. proaktiv.',  # Promantis tagline
        'delayFix': 'false',
        'cycleMonitor': 'false',
        'xOffline': 'false',
        'hidecm': 'false',
        'statussort': 'false',
        'removeNewVersionNotif': 'false',
        'urlLink': 'https://promantis.com',
        'downloadLink': 'https://promantis.com'
    }
    
    return json.dumps(extras)


def trigger_workflow(platform):
    """Trigger GitHub Actions workflow for a specific platform"""
    
    # Use workflow IDs (more reliable than filenames)
    # To get IDs: gh api /repos/{owner}/{repo}/actions/workflows
    workflow_ids = {
        'windows': '236678191',  # generator-windows.yml
        'linux': '236678174',    # generator-linux.yml
        'macos': '236678184',    # generator-macos.yml
        'macos-x86': '236678180' # generator-macos-x86.yml
    }
    
    if platform not in workflow_ids:
        print(f"❌ Unknown platform: {platform}")
        return False
    
    workflow_id = workflow_ids[platform]
    url = f"https://api.github.com/repos/{GITHUB_USERNAME}/{REPO_NAME}/actions/workflows/{workflow_id}/dispatches"
    
    # Prepare workflow inputs
    custom_config = create_custom_config()
    extras = create_extras()
    
    data = {
        "ref": "master",
        "inputs": {
            "server": RUSTDESK_SERVER,
            "key": RUSTDESK_KEY,
            "apiServer": API_SERVER,
            "custom": custom_config,
            "uuid": BUILD_UUID,
            "iconlink": ICON_URL if ICON_URL else "false",
            "logolink": LOGO_URL if LOGO_URL else "false",
            "appname": APP_NAME,
            "filename": FILE_NAME,
            "extras": extras
        }
    }
    
    headers = {
        'Accept': 'application/vnd.github+json',
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {GITHUB_TOKEN}',
        'X-GitHub-Api-Version': '2022-11-28'
    }
    
    print(f"\n🚀 Triggering {platform.upper()} build...")
    print(f"   Repository: {GITHUB_USERNAME}/{REPO_NAME}")
    print(f"   Workflow ID: {workflow_id}")
    print(f"   Server: {RUSTDESK_SERVER}")
    print(f"   Version: {VERSION}")
    
    try:
        response = requests.post(url, json=data, headers=headers)
        
        if response.status_code == 204:
            print(f"✅ {platform.upper()} build triggered successfully!")
            print(f"   Check status: https://github.com/{GITHUB_USERNAME}/{REPO_NAME}/actions")
            return True
        else:
            print(f"❌ Failed to trigger {platform.upper()} build")
            print(f"   Status Code: {response.status_code}")
            if response.text:
                error_detail = response.json() if response.text else {"message": "Unknown error"}
                print(f"   Error: {json.dumps(error_detail, indent=2)}")
            return False
            
    except Exception as e:
        print(f"❌ Exception while triggering {platform.upper()} build: {e}")
        return False


def main():
    """Main function to trigger all builds"""
    
    print("=" * 60)
    print("RustDesk Custom Build Trigger")
    print("=" * 60)
    print(f"Build UUID: {BUILD_UUID}")
    print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"\nConfiguration:")
    print(f"  Server: {RUSTDESK_SERVER}")
    print(f"  Key: {RUSTDESK_KEY}")
    print(f"  App Name: {APP_NAME}")
    print(f"  Version: {VERSION}")
    print("=" * 60)
    
    # Check if GitHub token is set
    if not GITHUB_TOKEN:
        print("\n❌ ERROR: GitHub token not set!")
        print("\nPlease set your GitHub Personal Access Token:")
        print("  1. As environment variable: set GHBEARER=your_token_here")
        print("  2. Or edit this script and set GITHUB_TOKEN variable")
        print("\nTo create a token:")
        print("  1. Go to: https://github.com/settings/tokens")
        print("  2. Generate new token (fine-grained)")
        print("  3. Give it 'Actions' read/write permission")
        sys.exit(1)
    
    # Trigger builds for all platforms
    platforms = ['windows', 'macos', 'linux']
    
    results = {}
    for platform in platforms:
        results[platform] = trigger_workflow(platform)
    
    # Summary
    print("\n" + "=" * 60)
    print("Build Trigger Summary")
    print("=" * 60)
    
    success_count = sum(1 for success in results.values() if success)
    
    for platform, success in results.items():
        status = "✅ SUCCESS" if success else "❌ FAILED"
        print(f"{platform.upper():12} {status}")
    
    print("=" * 60)
    print(f"\nTotal: {success_count}/{len(platforms)} builds triggered successfully")
    
    if success_count > 0:
        print(f"\n📊 Monitor builds at:")
        print(f"   https://github.com/{GITHUB_USERNAME}/{REPO_NAME}/actions")
        print(f"\n⏱️  Builds typically take 15-30 minutes to complete")
        print(f"\n📦 Build artifacts will be available in the Actions tab")
    
    print("\n" + "=" * 60)
    
    return success_count == len(platforms)


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
