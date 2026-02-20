#!/usr/bin/env python3
"""Quick test to trigger Windows build"""
import requests
import json
import base64
import uuid
import os

# Configuration
GITHUB_TOKEN = os.environ.get("GHBEARER")
BUILD_UUID = str(uuid.uuid4())

# Custom config
custom_config = {
    'app-name': 'RustDesk',
    'enable-lan-discovery': 'Y'
}
custom_json = json.dumps(custom_config)
custom_base64 = base64.b64encode(custom_json.encode("ascii")).decode("ascii")

# Extras
extras = json.dumps({
    'version': '1.3.3',
    'rdgen': 'false',
    'compname': 'Purslane Ltd',
    'slogan': 'Developed By RustDesk',
    'delayFix': 'false',
    'cycleMonitor': 'false',
    'xOffline': 'false',
    'hidecm': 'false',
    'statussort': 'false',
    'removeNewVersionNotif': 'false'
})

# Using workflow ID
url = "https://api.github.com/repos/sgpromantis/rustdeskinstaller/actions/workflows/236678191/dispatches"

data = {
    "ref": "master",
    "inputs": {
        "server": "212.132.114.192",
        "key": "CctpHu85Bw1iuBwgZTATOjntfQkmqYc1yvs5m2pN+Vk=",
        "apiServer": "212.132.114.192:21114",
        "custom": custom_base64,
        "uuid": BUILD_UUID,
        "iconlink": "false",
        "logolink": "false",
        "appname": "RustDesk",
        "filename": "rustdesk",
        "extras": extras
    }
}

headers = {
    'Accept': 'application/vnd.github+json',
    'Content-Type': 'application/json',
    'Authorization': f'Bearer {GITHUB_TOKEN}',
    'X-GitHub-Api-Version': '2022-11-28'
}

print(f"Testing Windows build trigger...")
print(f"URL: {url}")
print(f"UUID: {BUILD_UUID}")

response = requests.post(url, json=data, headers=headers)
print(f"Status: {response.status_code}")
if response.text:
    print(f"Response: {response.text}")

if response.status_code == 204:
    print("✅ SUCCESS! Build triggered.")
    print(f"Check: https://github.com/sgpromantis/rustdeskinstaller/actions")
else:
    print(f"❌ FAILED with status {response.status_code}")
