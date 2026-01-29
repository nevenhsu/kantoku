# Quick Test Commands for n8n Workflows

## 🚀 Generate Tasks Workflow

### Bash Test Script
```bash
./test_generate_tasks.sh
```

### Python Test Script
```bash
python3 test_n8n.py
```

### Direct curl Command
```bash
curl -X POST http://localhost:5678/webhook-test/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35",
    "daily_goal_minutes": 30
  }'
```

### Pretty Print with jq
```bash
curl -s -X POST http://localhost:5678/webhook-test/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35", "daily_goal_minutes": 30}' | jq .
```

---

## 📝 Review Submission Workflow

```bash
curl -X POST http://localhost:5678/webhook-test/review-submission \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "YOUR_TASK_ID_HERE",
    "submission_type": "text",
    "content": "a"
  }'
```

---

## 🧪 Generate Test Workflow

```bash
curl -X POST http://localhost:5678/webhook-test/generate-test \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35",
    "category": "hiragana",
    "progress_milestone": 10
  }'
```

---

## 📊 Grade Test Workflow

```bash
curl -X POST http://localhost:5678/webhook-test/grade-test \
  -H "Content-Type: application/json" \
  -d '{
    "test_id": "YOUR_TEST_ID_HERE",
    "answers": {
      "0": "a",
      "1": "i",
      "2": "u"
    }
  }'
```

---

## 🔄 Production URLs

For production mode (when workflow is Active), change `/webhook-test/` to `/webhook/`:

```bash
# Production Generate Tasks
curl -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35", "daily_goal_minutes": 30}'
```

---

## 📦 Environment Variables

You can set these in your `.zshrc` or `.bashrc`:

```bash
export N8N_URL="http://localhost:5678"
export TEST_USER_ID="ebc3cd0d-dc42-42c1-920a-87328627fe35"
```

Then use:
```bash
curl -X POST "$N8N_URL/webhook-test/generate-tasks" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\": \"$TEST_USER_ID\", \"daily_goal_minutes\": 30}"
```

---

## 🛠️ Troubleshooting

### Check if n8n is running
```bash
curl http://localhost:5678/healthz
```

### Check workflow status
Visit: http://localhost:5678

### View n8n logs
```bash
# If running with Docker
docker logs n8n

# If running with npm
# Check terminal where n8n is running
```

---

**Last Updated**: 2026-01-29
