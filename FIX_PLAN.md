# iOS Task Display Issue - Fix Plan

## Problem Summary
- **Symptom**: iOS displays 4 duplicate review tasks instead of 1 practice + 1 review task
- **Expected**: 1 practice task (5 kana) + 1 review task (1-5 kana)
- **Actual**: 4 review tasks each with 1 kana (き)

## Root Cause Analysis

### 1. n8n Workflow Issue
The "Code - Build Tasks" node in workflow 1 is creating multiple task records instead of one consolidated task.

**Current Logic (WRONG)**:
```javascript
// Creating one task per kana item
reviewKana.forEach(kana => {
  tasks.push({
    task_type: 'kana_review',
    content: {
      review_kana: [kana],  // Single kana
      kana_type: 'hiragana'
    }
  })
})
```

**Correct Logic**:
```javascript
// Create ONE task with ALL review kana
if (reviewKana.length > 0) {
  tasks.push({
    task_type: 'kana_review',
    content: {
      review_kana: reviewKana,  // Array of ALL kana
      kana_type: 'hiragana'
    }
  })
}
```

### 2. Database Has Duplicate Records
Multiple task records exist with the same content, created by previous workflow runs.

## Fix Steps

### Step 1: Fix n8n Workflow
Open n8n workflow 1 and update the "Code - Build Tasks" node:

```javascript
const reviewKana = $('Code - Prepare Review Kana')?.first()?.json?.reviewKana || [];
const newKana = $('Code - Select New Kana')?.first()?.json?.newKana || [];
const userId = $('Webhook').first().json.body.user_id;
const dueDate = new Date().toISOString().split('T')[0];

const tasks = [];

// Create ONE review task with ALL review kana (if any)
if (reviewKana.length > 0) {
  tasks.push({
    user_id: userId,
    task_type: 'kana_review',
    content: JSON.stringify({
      review_kana: reviewKana.map(item => ({
        kana: item.kana,
        romaji: item.romaji
      })),
      kana_type: 'hiragana'
    }),
    status: 'pending',
    due_date: dueDate,
    skipped: false
  });
}

// Create ONE learn task with ALL new kana (if any)
if (newKana.length > 0) {
  tasks.push({
    user_id: userId,
    task_type: 'kana_learn',
    content: JSON.stringify({
      kana_list: newKana.map(item => ({
        kana: item.kana,
        romaji: item.romaji
      })),
      kana_type: 'hiragana'
    }),
    status: 'pending',
    due_date: dueDate,
    skipped: false
  });
}

return tasks.map(task => ({ json: task }));
```

### Step 2: Clean Database
Execute via Supabase SQL Editor:

```sql
-- Delete duplicate tasks for test user created today
DELETE FROM tasks
WHERE user_id = 'ebc3cd0d-dc42-42c1-920a-87328627fe35'
  AND created_at::date = CURRENT_DATE;
```

### Step 3: Test n8n Workflow
```bash
# Generate new tasks
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35"}' | python3 -m json.tool

# Expected response:
# {
#   "success": true,
#   "tasks_generated": 1 or 2,  # 1 review OR 1 learn OR both
#   "tasks": [
#     {
#       "task_type": "kana_learn",
#       "content": "{\"kana_list\":[{\"kana\":\"あ\",\"romaji\":\"a\"},...],\"kana_type\":\"hiragana\"}"
#     }
#   ]
# }
```

### Step 4: Test iOS App
1. Open iOS app
2. Pull to refresh dashboard
3. Verify:
   - ✅ Displays 1-2 task groups
   - ✅ Practice group shows 5 kana
   - ✅ Review group shows 1+ kana
   - ✅ No duplicate content

## Verification Checklist
- [ ] n8n workflow "Code - Build Tasks" node updated
- [ ] Test workflow returns 1-2 tasks (not 4)
- [ ] Database cleaned of duplicates
- [ ] iOS displays correct number of tasks
- [ ] Task content shows multiple kana per task
- [ ] No duplicate kana displayed

## Related Files
- n8n workflow: Check `Code - Build Tasks` node
- iOS: `ios/kantoku/ViewModels/TaskViewModel.swift:206-223` (grouping logic is correct)
- iOS: `ios/kantoku/Models/Task.swift:189-236` (content decoding is correct)
