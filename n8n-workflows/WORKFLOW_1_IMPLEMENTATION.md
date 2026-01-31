# Workflow 1: Generate Tasks - 實作文件

**Last Updated**: 2026-01-31

## 概述

此 workflow 負責生成每日學習任務,包括學習新假名和複習已學假名。

## 邏輯流程

```
[Webhook] - 接收 user_id
    ↓
[Check Existing Tasks] - 查詢今日是否已有任務
    ↓
[IF - Has Existing Tasks]
    ├── TRUE → [Format Existing Tasks] → [Respond] ✅ 直接返回現有任務
    └── FALSE → 生成新任務流程
        ↓
    [Query - User Progress] - 獲取用戶當前學習階段
        ↓
    並行執行:
        ├─→ [Query - Next Stage] → [Code - Select New Kana]
        │                                ↓
        │                           [Code - Build Progress Records]
        │                                ↓
        │                           [Insert Kana Progress] ✅ 新增學習記錄
        │
        └─→ [Query - Review Items] → [Code - Prepare Review]
                                           ↓
                                      [Update Review Timestamps] ✅ 更新複習時間戳

    兩個分支合併到:
        ↓
    [Code - Build Tasks] - 合併生成練習和複習任務
        ↓
    [Insert Tasks] - 插入任務到資料庫
        ↓
    [Query All Tasks] - 重新查詢所有今日任務
        ↓
    [Format Final Response] - 格式化回應
        ↓
    [Respond to Webhook] ✅ 返回任務列表
```

## 關鍵特性

### 1. 檢查已存在任務

**目的**: 避免重複生成,直接返回已生成的任務

**實作**:
```sql
SELECT * FROM tasks
WHERE user_id = '{{ $json.body.user_id }}'
  AND DATE(created_at) = CURRENT_DATE
ORDER BY created_at ASC;
```

### 2. 並行處理練習與複習

**原理**: 練習任務和複習任務是獨立的邏輯,應該並行處理

**優勢**:
- 提高執行效率
- 邏輯清晰,易於維護
- 兩者互不影響

### 3. 練習任務生成邏輯

**Query - Next Stage**:
根據 `user_progress.current_stage_id` 直接查詢下一階段的所有假名:

```sql
SELECT ls.id, ls.name, ls.kana_data
FROM learning_stages ls
JOIN user_progress up ON ls.id = up.current_stage_id + 1
WHERE up.user_id = '{{ $('Webhook').item.json.body.user_id }}'
  AND ls.id <= 10
LIMIT 1;
```

**限制條件**:
- `ls.id <= 10`: 限制階段範圍為 1~10
- `up.current_stage_id + 1`: 自動選擇下一階段
- 如果已完成所有階段 (current_stage_id = 10),查詢結果為空

**Code - Select New Kana**:
```javascript
const stageData = $input.first()?.json;

// 如果沒有下一階段數據 (已完成所有階段)
if (!stageData || !stageData.kana_data) {
  return {
    json: {
      newKana: [],
      hasNewKana: false,
      message: '已完成所有學習階段'
    }
  };
}

// 下一階段的所有假名
const allKana = stageData.kana_data || [];

return {
  json: {
    newKana: allKana,
    hasNewKana: allKana.length > 0,
    stageName: stageData.name
  }
};
```

**邏輯簡化**:
- ✅ 不再查詢已學假名
- ✅ 不再過濾未學假名
- ✅ 直接選取下一階段的**所有假名**
- ✅ 一次性學完整個階段 (例如: あ行 5 個假名)

**Code - Build Progress Records**:
為新學習的假名創建 `kana_progress` 記錄,用於後續複習追蹤。

### 4. 複習任務生成邏輯

**Query - Review Items**:
```sql
SELECT kp.kana, kp.romaji, kp.mastery_score, kp.last_reviewed
FROM kana_progress kp
WHERE kp.user_id = '{{ $('Webhook').item.json.body.user_id }}'
  AND kp.next_review <= NOW()
  AND kp.status IN ('learning', 'reviewing')
ORDER BY kp.last_reviewed ASC NULLS FIRST
LIMIT 10;
```

**選擇標準**:
- `next_review <= NOW()`: 到了複習時間
- 狀態為 `learning` 或 `reviewing`
- 按 `last_reviewed` 升序排序 (最久未複習的優先)
- 限制最多 10 個

**Update Review Timestamps**:
更新被選中進行複習的假名,將 `next_review` 設為 3 天後,避免下次重複選中。

### 5. 任務格式統一

**Code - Build Tasks**:
```javascript
const reviewData = $('Code - Prepare Review').first().json;
const learnData = $('Code - Select New Kana').first().json;
const userId = $('Webhook').first().json.body.user_id;
const dueDate = new Date().toISOString().split('T')[0];
const now = new Date().toISOString();

const tasks = [];

// 1. 生成複習任務 (如果有待複習項目)
if (reviewData.hasReview && reviewData.reviewKana.length > 0) {
  tasks.push({
    user_id: userId,
    task_type: 'kana_review',
    content: JSON.stringify({
      review_kana: reviewData.reviewKana,
      kana_type: 'hiragana'
    }),
    status: 'pending',
    due_date: dueDate,
    skipped: false,
    created_at: now,
    updated_at: now
  });
}

// 2. 生成學習任務 (如果有新假名)
if (learnData.hasNewKana && learnData.newKana.length > 0) {
  tasks.push({
    user_id: userId,
    task_type: 'kana_learn',
    content: JSON.stringify({
      kana_list: learnData.newKana,
      kana_type: 'hiragana'
    }),
    status: 'pending',
    due_date: dueDate,
    skipped: false,
    created_at: now,
    updated_at: now
  });
}

return tasks.map(task => ({ json: task }));
```

**格式要求**:
- 練習任務和複習任務的格式**完全一致**
- 都包含 `created_at`, `updated_at` 時間戳
- 都包含 `skipped` 標記

### 6. 回應格式統一

不論是返回已存在的任務還是新生成的任務,回應格式都是:

```json
{
  "success": true,
  "tasks_generated": 2,
  "tasks": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "task_type": "kana_review",
      "content": "{\"review_kana\":[...],\"kana_type\":\"hiragana\"}",
      "status": "pending",
      "due_date": "2026-01-31",
      "skipped": false,
      "created_at": "2026-01-31T05:00:00.000Z",
      "updated_at": "2026-01-31T05:00:00.000Z"
    },
    {
      "id": "uuid",
      "user_id": "uuid",
      "task_type": "kana_learn",
      "content": "{\"kana_list\":[...],\"kana_type\":\"hiragana\"}",
      "status": "pending",
      "due_date": "2026-01-31",
      "skipped": false,
      "created_at": "2026-01-31T05:00:00.000Z",
      "updated_at": "2026-01-31T05:00:00.000Z"
    }
  ],
  "estimated_minutes": 6,
  "message": "今日任務已生成"
}
```

## 重要配置

### Always Output Data

以下節點必須啟用 `alwaysOutputData`:
- **Check Existing Tasks**: 即使今日無任務也要輸出,才能進入 IF 判斷
- **Query - User Progress**: 確保後續節點能執行

### Credentials

所有節點使用同一套憑證:
- **Postgres**: `hynLF0TmxXH71HPT`
- **Supabase**: `RculhUeb6L26Iaph`

## 測試

### 測試環境

```bash
# 清理今日任務
DELETE FROM tasks
WHERE user_id = 'ebc3cd0d-dc42-42c1-920a-87328627fe35'
  AND DATE(created_at) = CURRENT_DATE;

# 調用 Workflow
curl -X POST http://neven.local:5678/webhook-test/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35"}'

# 驗證結果
SELECT task_type, status, created_at
FROM tasks
WHERE user_id = 'ebc3cd0d-dc42-42c1-920a-87328627fe35'
  AND DATE(created_at) = CURRENT_DATE;
```

### 預期結果

第一次調用:
- 生成 1~2 個任務 (可能同時有練習和複習)
- 創建 `kana_progress` 記錄
- 更新複習時間戳

第二次調用:
- 直接返回已生成的任務
- 不執行任何資料庫寫入操作

## 常見問題

### Q1: 為什麼有時只有練習任務,沒有複習任務?

**A**: 正常情況。複習任務只在以下條件同時滿足時才生成:
- 有已學習的假名 (`kana_progress` 存在記錄)
- `next_review <= NOW()` (到了複習時間)
- 狀態為 `learning` 或 `reviewing`

新用戶或剛開始學習時,沒有滿足條件的複習項目。

### Q2: 為什麼複習任務最多只有 10 個假名?

**A**: 設計決策。避免一次複習太多假名,影響學習效果。可以在 `Query - Review Items` 節點調整 `LIMIT` 值。

### Q3: 練習任務每次學多少個新假名?

**A**: 一次學完整個階段的所有假名。例如:
- あ行: 5 個假名 (あ、い、う、え、お)
- や行: 3 個假名 (や、ゆ、よ)

每個階段的假名數量由 `learning_stages.kana_data` 決定,範圍為 3~5 個假名。

### Q4: 如何改變複習間隔?

**A**: 在 `Update Review Timestamps` 節點修改:
```sql
next_review = NOW() + INTERVAL '3 days'  -- 改為其他天數
```

## 版本歷史

| 日期 | 版本 | 更新內容 |
|------|------|----------|
| 2026-01-31 | v2.1 | 簡化練習任務邏輯:直接選取下一階段所有假名,移除已學過濾 |
| 2026-01-31 | v2.0 | 重構邏輯:檢查已存在任務 + 並行處理練習與複習 |
| 2026-01-24 | v1.0 | 初始版本:基本任務生成功能 |
