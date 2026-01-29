#!/usr/bin/env python3
"""
Test script for n8n Generate Tasks workflow
"""
import requests
import json
import sys

def test_generate_tasks(url, user_id):
    """Test the Generate Tasks workflow"""
    payload = {
        "user_id": user_id,
        "daily_goal_minutes": 30
    }
    headers = {"Content-Type": "application/json"}
    
    print(f"📡 Sending request to: {url}")
    print(f"👤 User ID: {user_id}")
    print("-" * 50)
    
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        print(f"📊 Status Code: {response.status_code}")
        print("-" * 50)
        
        if response.status_code == 200:
            print("✨ Success! Response:")
            print(json.dumps(response.json(), indent=2, ensure_ascii=False))
            return True
        else:
            print("❌ Error Response:")
            print(response.text)
            return False
            
    except requests.exceptions.ConnectionError:
        print("💥 Connection Error: Could not connect to n8n server")
        print("   Make sure n8n is running on http://localhost:5678")
        return False
    except requests.exceptions.Timeout:
        print("⏱️  Timeout: Request took too long")
        return False
    except Exception as e:
        print(f"💥 Unexpected Error: {e}")
        return False

if __name__ == "__main__":
    # Configuration
    N8N_WEBHOOK_URL = "http://localhost:5678/webhook-test/generate-tasks"
    TEST_USER_ID = "ebc3cd0d-dc42-42c1-920a-87328627fe35"
    
    print("🚀 Testing n8n Generate Tasks Workflow")
    print("=" * 50)
    
    success = test_generate_tasks(N8N_WEBHOOK_URL, TEST_USER_ID)
    
    print("=" * 50)
    if success:
        print("✅ Test Passed")
        sys.exit(0)
    else:
        print("❌ Test Failed")
        sys.exit(1)
