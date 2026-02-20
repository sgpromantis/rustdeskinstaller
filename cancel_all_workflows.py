#!/usr/bin/env python3
"""Cancel ALL running workflows"""
import requests
import os

GITHUB_TOKEN = os.environ.get("GHBEARER")
GITHUB_USERNAME = "sgpromantis"
REPO_NAME = "rustdeskinstaller"

headers = {
    'Accept': 'application/vnd.github+json',
    'Authorization': f'Bearer {GITHUB_TOKEN}',
    'X-GitHub-Api-Version': '2022-11-28'
}

# Get all running workflows
url = f"https://api.github.com/repos/{GITHUB_USERNAME}/{REPO_NAME}/actions/runs?status=in_progress"
response = requests.get(url, headers=headers)

if response.status_code == 200:
    runs = response.json()
    workflow_runs = runs.get('workflow_runs', [])
    
    if not workflow_runs:
        print("No running workflows to cancel.")
    else:
        print(f"Found {len(workflow_runs)} running workflow(s)")
        print("\nCanceling all running workflows...\n")
        
        canceled_count = 0
        for run in workflow_runs:
            run_id = run['id']
            run_name = run['name']
            created_at = run['created_at']
            
            print(f"🚫 Canceling: {run_name}")
            print(f"   Run ID: {run_id}")
            print(f"   Created: {created_at}")
            
            cancel_url = f"https://api.github.com/repos/{GITHUB_USERNAME}/{REPO_NAME}/actions/runs/{run_id}/cancel"
            cancel_response = requests.post(cancel_url, headers=headers)
            
            if cancel_response.status_code == 202:
                print(f"   ✅ Canceled successfully\n")
                canceled_count += 1
            else:
                print(f"   ❌ Failed to cancel: {cancel_response.status_code}\n")
        
        print(f"{'='*60}")
        print(f"Canceled {canceled_count} workflow(s)")
        print(f"{'='*60}")
else:
    print(f"Failed to get workflows: {response.status_code}")
