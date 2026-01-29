#!/bin/bash

# Configuration
# Use /webhook-test/ for "Test Workflow" mode in n8n UI
# Use /webhook/ for "Active" production mode
BASE_URL="http://localhost:5678/webhook-test"
USER_ID="ebc3cd0d-dc42-42c1-920a-87328627fe35"

echo "🚀 Testing Generate Tasks Workflow..."
echo "URL: $BASE_URL/generate-tasks"
echo "User ID: $USER_ID"
echo "------------------------------------"

curl -X POST "$BASE_URL/generate-tasks" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"daily_goal_minutes\": 30
  }"

echo -e "\n------------------------------------"
echo "✅ Test Complete"
