# n8n Filter String Bug Fix

**Date**: 2026-01-29  
**Status**: ✅ Fixed  
**Workflow**: Workflow 1: Generate Tasks

---

## 🐛 Problem

The workflow was throwing this error:

```
Bad request - please check your parameters: 
invalid input syntax for type timestamp with time zone: 
"2026-01-29T09:04:26.064Z?user_id=eq.EBC3CD0D-DC42-42C1-920A-87328627FE35"
```

### Root Cause

The Supabase node's `filterString` parameter had **leading equals signs** (`=`) which are not valid in PostgREST query syntax. This caused the query parameters to be malformed.

**Example of incorrect syntax:**
```
=user_id=eq.{{ $json.user_id }}&next_review=lte.{{ new Date().toISOString() }}
```

The leading `=` caused PostgREST to interpret the entire string incorrectly, resulting in the timestamp being concatenated with the next parameter.

---

## ✅ Solution

Removed the leading `=` from all `filterString` parameters in the workflow.

### Changes Made

#### 1. Query - User Progress (Line 40)
**Before:**
```json
"filterString": "=user_id=eq.{{ $json.body.user_id }}"
```
**After:**
```json
"filterString": "user_id=eq.{{ $json.body.user_id }}"
```

#### 2. Query - Learning Stage (Line 62)
**Before:**
```json
"filterString": "=id=eq.{{ $json.current_stage_id }}"
```
**After:**
```json
"filterString": "id=eq.{{ $json.current_stage_id }}"
```

#### 3. Query - Learned Kana (Line 84)
**Before:**
```json
"filterString": "=user_id=eq.{{ $('Webhook').item.json.body.user_id }}&status=in.(learning,reviewing,mastered)"
```
**After:**
```json
"filterString": "user_id=eq.{{ $('Webhook').item.json.body.user_id }}&status=in.(learning,reviewing,mastered)"
```

#### 4. Query - Review Items (Line 108)
**Before:**
```json
"filterString": "=user_id=eq.{{ $('Webhook').item.json.body.user_id }}&next_review=lte.{{ new Date().toISOString() }}"
```
**After:**
```json
"filterString": "user_id=eq.{{ $('Webhook').item.json.body.user_id }}&next_review=lte.{{ $now.toISOString() }}"
```

**Additional improvement**: Changed `new Date().toISOString()` to `$now.toISOString()` which is the n8n-native way to get the current timestamp.

---

## 🧪 Testing

### Test Scripts Created

Two test scripts have been created in the project root:

1. **Bash Script**: `test_generate_tasks.sh`
2. **Python Script**: `test_n8n.py`

### How to Test

#### Option 1: Using Bash
```bash
cd /Users/neven/Documents/projects/kantoku
./test_generate_tasks.sh
```

#### Option 2: Using Python
```bash
cd /Users/neven/Documents/projects/kantoku
python3 test_n8n.py
```

#### Option 3: Using curl directly
```bash
curl -X POST http://localhost:5678/webhook-test/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35",
    "daily_goal_minutes": 30
  }'
```

### Expected Success Response
```json
{
  "success": true,
  "tasks_generated": 5,
  "tasks": [
    {"id": "...", "task_type": "kana_learn", "content": {...}},
    ...
  ],
  "estimated_minutes": 15,
  "message": "今日任務已生成"
}
```

---

## 📋 Deployment Steps

### 1. Re-import Workflow to n8n

Since the JSON file has been updated, you need to re-import it into n8n:

1. Open n8n: `http://localhost:5678`
2. Go to **Workflows**
3. Find **"Workflow 1: Generate Tasks"**
4. Click the **three dots (⋮)** menu
5. Select **"Delete"** (backup first if needed)
6. Click **"Import from File"**
7. Select: `/Users/neven/Documents/projects/kantoku/n8n-workflows/Workflow 1_ Generate Tasks.json`
8. Click **"Import"**
9. **Activate** the workflow

### 2. Alternative: Manual Edit in n8n UI

If you prefer not to re-import, manually edit each node:

1. Open **"Workflow 1: Generate Tasks"** in n8n
2. Click on **"Query - User Progress"** node
3. Update the **Filter String** field (remove leading `=`)
4. Repeat for all four query nodes mentioned above
5. Click **"Save"**

---

## 🔍 PostgREST Filter Syntax Reference

### Correct Syntax

```
column_name=operator.value
```

### Examples

| Filter | Syntax |
|--------|--------|
| Equals | `id=eq.123` |
| Greater than | `age=gt.18` |
| Less than or equal | `price=lte.100` |
| In list | `status=in.(active,pending)` |
| Multiple filters | `user_id=eq.123&status=eq.active` |

### Common Mistakes

❌ `=user_id=eq.123` (leading equals)  
❌ `user_id=eq.123?status=eq.active` (wrong separator, should use `&`)  
✅ `user_id=eq.123&status=eq.active` (correct)

---

## 📚 Related Documentation

- [PostgREST API Documentation](https://postgrest.org/en/stable/api.html#horizontal-filtering-rows)
- [Supabase JS Client Filters](https://supabase.com/docs/reference/javascript/select)
- [n8n Supabase Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.supabase/)

---

## ✅ Verification Checklist

After applying the fix:

- [ ] JSON file updated with correct filter strings
- [ ] Workflow re-imported to n8n (or manually edited)
- [ ] Workflow is **Active** in n8n
- [ ] Test script runs successfully: `./test_generate_tasks.sh`
- [ ] Response returns `"success": true`
- [ ] Tasks are created in Supabase `tasks` table

---

## 🔄 Other Workflows to Check

The following workflows should also be checked for the same issue:

- ✅ **Workflow 1: Generate Tasks** - Fixed
- ⚠️ **Workflow 2: Review Submission** - Check needed
- ⚠️ **Workflow 3: Generate Test** - Check needed
- ⚠️ **Workflow 4: Grade Test** - Check needed

---

**Last Updated**: 2026-01-29  
**Fixed By**: Claude Code  
**Status**: ✅ Ready for Testing
