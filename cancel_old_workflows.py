#!/usr/bin/env python3
"""Cancel running GitHub Actions workflows"""
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

# Get running workflows
url = f"https://api.github.com/repos/{GITHUB_USERNAME}/{REPO_NAME}/actions/runs?status=in_progress"
response = requests.get(url, headers=headers)

if response.status_code == 200:
    runs = response.json()
    workflow_runs = runs.get('workflow_runs', [])
    
    if not workflow_runs:
        print("No running workflows to cancel.")
    else:
        print(f"Found {len(workflow_runs)} running workflow(s)")
        
        # Get the 3 most recent run IDs (these are the new ones we just started)
        new_run_ids = [run['id'] for run in workflow_runs[:3]]
        
        # Cancel older runs (skip the 3 newest)
        canceled_count = 0
        for run in workflow_runs[3:]:  # Skip first 3 (newest)
            run_id = run['id']
            run_name = run['name']
            created_at = run['created_at']
            
            print(f"\n🚫 Canceling: {run_name}")
            print(f"   Run ID: {run_id}")
            print(f"   Created: {created_at}")
            
            cancel_url = f"https://api.github.com/repos/{GITHUB_USERNAME}/{REPO_NAME}/actions/runs/{run_id}/cancel"
            cancel_response = requests.post(cancel_url, headers=headers)
            
            if cancel_response.status_code == 202:
                print(f"   ✅ Canceled successfully")
                canceled_count += 1
            else:
                print(f"   ❌ Failed to cancel: {cancel_response.status_code}")
        
        print(f"\n{'='*60}")
        print(f"Canceled {canceled_count} old workflow(s)")
        print(f"Keeping 3 newest workflows running (Promantis builds)")
        print(f"{'='*60}")
else:
    print(f"Failed to get workflows: {response.status_code}")
