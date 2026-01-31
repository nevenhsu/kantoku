# 快速修復指南

## 問題
iOS 首頁只顯示複習任務，缺少練習任務。

## 根本原因
n8n workflow 使用 IF 節點二選一，只生成複習**或**練習任務，而不是同時生成兩者。

## 修復步驟（總共 5 步驟）

### Step 1: 清理測試用戶的今日任務

在 Supabase SQL Editor 執行：

```sql
DELETE FROM tasks
WHERE user_id = 'ebc3cd0d-dc42-42c1-920a-87328627fe35'
  AND created_at::date = CURRENT_DATE;
```

### Step 2: 添加 kana_data 欄位到 learning_stages 表

在 Supabase SQL Editor 執行整個文件：
```
supabase/migrations/add_kana_data.sql
```

或手動執行：
```sql
ALTER TABLE learning_stages ADD COLUMN IF NOT EXISTS kana_data JSONB;

UPDATE learning_stages SET kana_data = '[
  {"kana": "あ", "romaji": "a"},
  {"kana": "い", "romaji": "i"},
  {"kana": "う", "romaji": "u"},
  {"kana": "え", "romaji": "e"},
  {"kana": "お", "romaji": "o"}
]'::jsonb WHERE id = 1;

-- 繼續執行其他階段...
```

### Step 3: 更新 n8n Workflow 節點

打開 n8n UI: `http://neven.local:5678`

找到 Workflow 1: generate-tasks

#### 3.1 修改 "Code - Select New Kana" 節點

**選項 A: 使用新的 kana_data 欄位（推薦）**

```javascript
const stageData = $('Query - Learning Stage').first().json;
const learnedKanaData = $input.all();

// 使用新的 kana_data 欄位
const currentStageKana = stageData.kana_data || [];

// 已學過的假名
const learnedKana = learnedKanaData.map(item => item.json.kana);

// 找出未學的假名
const newKana = currentStageKana.filter(kanaObj =>
  !learnedKana.includes(kanaObj.kana)
);

// 每次選擇 5 個
const kanaToLearn = newKana.slice(0, 5);

return {
  json: {
    newKana: kanaToLearn,
    hasNewKana: kanaToLearn.length > 0
  }
};
```

**選項 B: 使用羅馬拼音對照表（快速方案）**

```javascript
// 羅馬拼音對照表
const romajiMap = {
  'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
  'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
  'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
  'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
  'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no'
};

const stageData = $('Query - Learning Stage').first().json;
const learnedKanaData = $input.all();

const currentStageKanaChars = stageData.kana_chars || [];
const learnedKana = learnedKanaData.map(item => item.json.kana);

const newKana = currentStageKanaChars
  .filter(kana => !learnedKana.includes(kana))
  .map(kana => ({
    kana: kana,
    romaji: romajiMap[kana] || ''
  }))
  .slice(0, 5);

return {
  json: {
    newKana: newKana,
    hasNewKana: newKana.length > 0
  }
};
```

#### 3.2 修改 "Code - Prepare Review Kana" 節點

```javascript
const reviewItems = $input.all();

if (!reviewItems || reviewItems.length === 0) {
  return { json: { reviewKana: [], hasReview: false } };
}

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

#### 3.3 修改 "Code - Build Tasks" 節點

```javascript
const reviewData = $('Code - Prepare Review Kana').first().json;
const learnData = $('Code - Select New Kana').first().json;
const userId = $('Webhook').first().json.body.user_id;
const dueDate = new Date().toISOString().split('T')[0];

const tasks = [];

// 生成複習任務
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
}

// 生成學習任務
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
}

if (tasks.length === 0) {
  return [{ json: { error: 'no_tasks_needed' } }];
}

return tasks.map(task => ({ json: task }));
```

### Step 4: 測試 n8n Workflow

```bash
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35"}'
```

**預期回應：**
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
      "content": "{\"kana_list\":[{\"kana\":\"あ\",\"romaji\":\"a\"},...],\"kana_type\":\"hiragana\"}"
    }
  ]
}
```

### Step 5: 測試 iOS App

1. 打開 iOS app
2. 下拉刷新首頁
3. 驗證顯示:
   - ✅ 今日練習: 5 個假名 (あ い う え お)
   - ✅ 今日複習: 1 個假名 (き)

## 檢查清單

- [ ] Step 1: 清理今日任務
- [ ] Step 2: 添加 kana_data 欄位
- [ ] Step 3.1: 更新 "Code - Select New Kana"
- [ ] Step 3.2: 更新 "Code - Prepare Review Kana"
- [ ] Step 3.3: 更新 "Code - Build Tasks"
- [ ] Step 4: 測試 workflow 回應正確
- [ ] Step 5: iOS app 顯示正確

## 常見問題

**Q: 如果只顯示練習任務，沒有複習任務？**
A: 這是正常的，表示當前沒有需要複習的假名。

**Q: 如果只顯示複習任務，沒有練習任務？**
A: 檢查 "Code - Select New Kana" 節點是否正確執行。

**Q: 如果顯示多個重複的任務？**
A: 檢查 "Code - Build Tasks" 節點，確保是創建一個任務包含多個假名，而不是每個假名一個任務。

## 更多詳細信息

請參閱:
- `COMPLETE_FIX_GUIDE.md` - 完整修復指南
- `N8N_WORKFLOW_FIX.md` - n8n workflow 詳細設計
- `supabase/migrations/add_kana_data.sql` - SQL 遷移腳本
