# n8n Workflow 1 修復指南

## 問題分析

### 當前錯誤邏輯
```
[IF - Has Review Items]
  ├─ TRUE → 只生成 kana_review 任務 ❌
  └─ FALSE → 只生成 kana_learn 任務 ❌
```

### 正確邏輯
```
每次調用都應該:
1. 檢查是否有待複習項目 → 如果有，生成 kana_review 任務
2. 檢查是否需要學習新假名 → 如果需要，生成 kana_learn 任務
3. 可能的結果:
   - 只有 kana_learn (新用戶，無複習)
   - 只有 kana_review (已學完所有階段，只需複習)
   - 同時有 kana_learn + kana_review ✅ (正常情況)
```

## 修復步驟

### Step 1: 重新設計 Workflow 流程

將 IF 節點改為**並行處理**：

```
[Webhook]
  ↓
[1. Query - User Progress]
  ↓
[2. Query - Learning Stage] (當前階段信息)
  ↓
├─────────────────┬─────────────────┐
│                 │                 │
[3a. Query       [3b. Query        │
 Review Items]    Learned Kana]    │
  ↓                ↓                │
[Code -          [Code -           │
 Prepare         Select            │
 Review]         New Kana]         │
  ↓                ↓                │
  └────────────────┴────────────────┘
                   ↓
          [Code - Build Tasks]
          (合併兩個來源的任務)
                   ↓
          [Loop - Insert Tasks]
                   ↓
          [Respond to Webhook]
```

### Step 2: 更新節點配置

#### 節點 3a: Query - Review Items (Supabase)
**保持不變** - 查詢需要複習的假名

```sql
SELECT kp.kana, kp.romaji, kp.mastery_score, kp.last_reviewed
FROM kana_progress kp
WHERE kp.user_id = '{{ $json.body.user_id }}'
  AND kp.next_review <= NOW()
  AND kp.status IN ('learning', 'reviewing')
ORDER BY kp.last_reviewed ASC NULLS FIRST
LIMIT 10;
```

#### 節點 3b: Query - Learned Kana (新增)
**目的**: 查詢已學假名，用於判斷當前階段是否還有未學的假名

```sql
SELECT kp.kana
FROM kana_progress kp
WHERE kp.user_id = '{{ $json.body.user_id }}'
  AND kp.status IN ('learning', 'reviewing', 'mastered')
ORDER BY kp.created_at;
```

#### 節點 4a: Code - Prepare Review Kana (更新)
**目的**: 準備複習假名數據

```javascript
// 獲取複習項目
const reviewItems = $input.all();

// 如果沒有複習項目，返回空數組
if (!reviewItems || reviewItems.length === 0) {
  return { json: { reviewKana: [] } };
}

// 提取假名信息
const reviewKana = reviewItems.map(item => ({
  kana: item.json.kana,
  romaji: item.json.romaji
}));

return {
  json: {
    reviewKana: reviewKana,
    hasReview: true
  }
};
```

#### 節點 4b: Code - Select New Kana (更新)
**目的**: 從當前階段選擇未學的新假名

```javascript
// 獲取當前階段信息
const stageData = $('Query - Learning Stage').first().json;
const learnedKanaData = $input.all();

// 當前階段的所有假名 (從 learning_stages.kana_chars)
const currentStageKana = stageData.kana_chars || [];

// 已學過的假名列表
const learnedKana = learnedKanaData.map(item => item.json.kana);

// 找出未學的假名
const newKana = currentStageKana.filter(kanaObj =>
  !learnedKana.includes(kanaObj.kana)
);

// 每次選擇 5 個新假名
const kanaToLearn = newKana.slice(0, 5);

return {
  json: {
    newKana: kanaToLearn,
    hasNewKana: kanaToLearn.length > 0
  }
};
```

#### 節點 5: Code - Build Tasks (重寫)
**目的**: 合併兩種任務類型

```javascript
// 獲取數據
const reviewData = $('Code - Prepare Review Kana').first().json;
const learnData = $('Code - Select New Kana').first().json;
const userId = $('Webhook').first().json.body.user_id;
const dueDate = new Date().toISOString().split('T')[0];

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
    skipped: false
  });
  console.log(`✅ 生成複習任務: ${reviewData.reviewKana.length} 個假名`);
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
    skipped: false
  });
  console.log(`✅ 生成學習任務: ${learnData.newKana.length} 個假名`);
}

// 如果沒有任何任務，返回空數組
if (tasks.length === 0) {
  console.log('⚠️ 沒有需要生成的任務');
}

return tasks.map(task => ({ json: task }));
```

### Step 3: 更新 learning_stages 數據結構

確保 `learning_stages` 表的 `kana_chars` 欄位格式正確：

```sql
-- 檢查當前格式
SELECT id, name, kana_chars FROM learning_stages WHERE id = 1;

-- 正確格式應該是 JSONB 數組
-- [
--   {"kana": "あ", "romaji": "a"},
--   {"kana": "い", "romaji": "i"},
--   {"kana": "う", "romaji": "u"},
--   {"kana": "え", "romaji": "e"},
--   {"kana": "お", "romaji": "o"}
-- ]

-- 如果格式不對，更新為正確格式
UPDATE learning_stages
SET kana_chars = '[
  {"kana": "あ", "romaji": "a"},
  {"kana": "い", "romaji": "i"},
  {"kana": "う", "romaji": "u"},
  {"kana": "え", "romaji": "e"},
  {"kana": "お", "romaji": "o"}
]'::jsonb
WHERE id = 1 AND name = 'Stage 1: あ行';
```

### Step 4: 測試計劃

#### 測試 1: 清理當前數據
```sql
-- 刪除今日任務
DELETE FROM tasks
WHERE user_id = 'ebc3cd0d-dc42-42c1-920a-87328627fe35'
  AND created_at::date = CURRENT_DATE;
```

#### 測試 2: 調用 Workflow
```bash
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35"}'
```

#### 測試 3: 驗證結果
預期回應應該包含 **2 個任務**：

```json
{
  "success": true,
  "tasks_generated": 2,
  "tasks": [
    {
      "task_type": "kana_review",
      "content": "{\"review_kana\":[{\"kana\":\"き\",\"romaji\":\"ki\"}],\"kana_type\":\"hiragana\"}"
    },
    {
      "task_type": "kana_learn",
      "content": "{\"kana_list\":[{\"kana\":\"あ\",\"romaji\":\"a\"},{\"kana\":\"い\",\"romaji\":\"i\"},...],\"kana_type\":\"hiragana\"}"
    }
  ]
}
```

#### 測試 4: iOS App 驗證
1. 打開 iOS App
2. 下拉刷新
3. 驗證顯示:
   - ✅ 今日練習: 5 個假名
   - ✅ 今日複習: 1 個假名
   - ✅ 共 2 個任務分組

## 節點連接順序

### 正確的節點流程
```
1. Webhook
   ↓
2. Query - User Progress
   ↓
3. Query - Learning Stage
   ↓ (分支成兩條並行路徑)
   ├─→ 4a. Query - Review Items
   │    ↓
   │   5a. Code - Prepare Review Kana
   │    ↓
   │    └─→ 合併到 6
   │
   └─→ 4b. Query - Learned Kana
        ↓
       5b. Code - Select New Kana
        ↓
        └─→ 合併到 6

6. Code - Build Tasks (接收兩個分支)
   ↓
7. Loop - Insert Tasks
   ↓
8. Insert - Task (循環體)
   ↓
9. Code - Format Response
   ↓
10. Respond to Webhook
```

## 關鍵要點

1. **並行處理**: 複習和學習是獨立的邏輯，應該並行處理
2. **條件生成**: 在 "Build Tasks" 節點中判斷是否生成每種任務
3. **數據格式**: 每個任務的 content 應該包含**多個假名**，不是每個假名一個任務
4. **空處理**: 如果某種任務沒有數據，就不生成該任務，但不影響另一種任務的生成

## 常見錯誤

❌ **錯誤 1**: 使用 IF 節點二選一
```
IF (有複習) → 只生成複習 ← 錯誤！
ELSE → 只生成學習
```

✅ **正確**: 並行處理後合併
```
並行: 準備複習 + 選擇學習
合併: 都生成 (如果有數據)
```

❌ **錯誤 2**: 每個假名一個任務
```javascript
kanaList.forEach(kana => {
  tasks.push({ content: { kana: kana } })  // 錯誤！
})
```

✅ **正確**: 一個任務包含多個假名
```javascript
tasks.push({
  content: { kana_list: kanaList }  // 正確！
})
```
