# 完整修復指南：任務生成問題

## 問題總結

1. **只生成複習任務，缺少練習任務** - n8n workflow 使用 IF 二選一邏輯
2. **生成多個重複任務** - 每個假名一個任務，而不是一個任務包含多個假名
3. **learning_stages 缺少羅馬拼音** - 只有假名字符，沒有對應的羅馬拼音

## 修復方案

### 方案 A: 修改數據庫結構（推薦）

#### 優點
- 數據完整，包含羅馬拼音
- Workflow 邏輯簡單，直接讀取即可
- 易於維護和擴展

#### 缺點
- 需要修改現有表結構
- 需要遷移數據

#### 實施步驟

**Step 1: 修改 learning_stages 表結構**

```sql
-- 1. 添加新欄位 kana_data (JSONB 類型)
ALTER TABLE learning_stages
ADD COLUMN kana_data JSONB;

-- 2. 更新數據 - あ行
UPDATE learning_stages
SET kana_data = '[
  {"kana": "あ", "romaji": "a"},
  {"kana": "い", "romaji": "i"},
  {"kana": "う", "romaji": "u"},
  {"kana": "え", "romaji": "e"},
  {"kana": "お", "romaji": "o"}
]'::jsonb
WHERE id = 1;

-- 3. 更新數據 - か行
UPDATE learning_stages
SET kana_data = '[
  {"kana": "か", "romaji": "ka"},
  {"kana": "き", "romaji": "ki"},
  {"kana": "く", "romaji": "ku"},
  {"kana": "け", "romaji": "ke"},
  {"kana": "こ", "romaji": "ko"}
]'::jsonb
WHERE id = 2;

-- 4. 更新數據 - さ行
UPDATE learning_stages
SET kana_data = '[
  {"kana": "さ", "romaji": "sa"},
  {"kana": "し", "romaji": "shi"},
  {"kana": "す", "romaji": "su"},
  {"kana": "せ", "romaji": "se"},
  {"kana": "そ", "romaji": "so"}
]'::jsonb
WHERE id = 3;

-- 5. 更新數據 - た行
UPDATE learning_stages
SET kana_data = '[
  {"kana": "た", "romaji": "ta"},
  {"kana": "ち", "romaji": "chi"},
  {"kana": "つ", "romaji": "tsu"},
  {"kana": "て", "romaji": "te"},
  {"kana": "と", "romaji": "to"}
]'::jsonb
WHERE id = 4;

-- 6. 更新數據 - な行
UPDATE learning_stages
SET kana_data = '[
  {"kana": "な", "romaji": "na"},
  {"kana": "に", "romaji": "ni"},
  {"kana": "ぬ", "romaji": "nu"},
  {"kana": "ね", "romaji": "ne"},
  {"kana": "の", "romaji": "no"}
]'::jsonb
WHERE id = 5;

-- 7. 驗證數據
SELECT id, name, kana_chars, kana_data
FROM learning_stages
WHERE id <= 5
ORDER BY id;
```

**Step 2: 更新 n8n Workflow**

使用新的 `kana_data` 欄位：

```javascript
// Code - Select New Kana 節點
const stageData = $('Query - Learning Stage').first().json;
const learnedKanaData = $input.all();

// 使用新的 kana_data 欄位 (包含 romaji)
const currentStageKana = stageData.kana_data || [];

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

### 方案 B: 使用硬編碼對照表（快速方案）

#### 優點
- 不需要修改數據庫
- 快速實施

#### 缺點
- Workflow 代碼較複雜
- 維護困難

#### 實施步驟

在 n8n "Code - Select New Kana" 節點中添加羅馬拼音對照表：

```javascript
// 羅馬拼音對照表
const romajiMap = {
  'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
  'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
  'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
  'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
  'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
  'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
  'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
  'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
  'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
  'わ': 'wa', 'を': 'wo', 'ん': 'n'
};

const stageData = $('Query - Learning Stage').first().json;
const learnedKanaData = $input.all();

// 從 kana_chars 陣列取得假名
const currentStageKanaChars = stageData.kana_chars || [];

// 已學過的假名
const learnedKana = learnedKanaData.map(item => item.json.kana);

// 找出未學的假名並添加羅馬拼音
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

## 推薦實施順序

### 第一階段：立即修復（方案 B）

1. **清理現有數據**
```sql
DELETE FROM tasks
WHERE user_id = 'ebc3cd0d-dc42-42c1-920a-87328627fe35'
  AND created_at::date = CURRENT_DATE;
```

2. **更新 n8n Workflow**
   - 修改 "Code - Select New Kana" 節點（使用羅馬拼音對照表）
   - 修改 "Code - Prepare Review Kana" 節點（處理複習數據）
   - 修改 "Code - Build Tasks" 節點（合併生成兩種任務）
   - 移除或修改 "IF - Has Review Items" 節點（改為並行處理）

3. **測試**
```bash
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35"}'
```

### 第二階段：優化數據庫（方案 A）

1. 執行 SQL 更新 learning_stages 表
2. 簡化 n8n Workflow 代碼
3. 完整測試所有學習階段

## n8n Workflow 完整代碼

### 1. Code - Prepare Review Kana

```javascript
// 獲取複習項目
const reviewItems = $input.all();

// 如果沒有複習項目，返回空數組
if (!reviewItems || reviewItems.length === 0) {
  return { json: { reviewKana: [], hasReview: false } };
}

// 提取假名信息
const reviewKana = reviewItems.map(item => ({
  kana: item.json.kana,
  romaji: item.json.romaji
}));

console.log(`✅ 準備複習: ${reviewKana.length} 個假名`);

return {
  json: {
    reviewKana: reviewKana,
    hasReview: true
  }
};
```

### 2. Code - Select New Kana (使用對照表)

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

// 從 kana_chars 取得假名
const currentStageKanaChars = stageData.kana_chars || [];

// 已學過的假名
const learnedKana = learnedKanaData.map(item => item.json.kana);

// 找出未學的假名並添加羅馬拼音
const newKana = currentStageKanaChars
  .filter(kana => !learnedKana.includes(kana))
  .map(kana => ({
    kana: kana,
    romaji: romajiMap[kana] || ''
  }))
  .slice(0, 5);

console.log(`✅ 選擇新假名: ${newKana.length} 個`);

return {
  json: {
    newKana: newKana,
    hasNewKana: newKana.length > 0
  }
};
```

### 3. Code - Build Tasks

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

// 如果沒有任何任務
if (tasks.length === 0) {
  console.log('⚠️ 沒有需要生成的任務');
  return [{
    json: {
      error: 'no_tasks_needed',
      message: '當前沒有需要生成的任務'
    }
  }];
}

console.log(`✅ 總共生成 ${tasks.length} 個任務`);
return tasks.map(task => ({ json: task }));
```

## 測試檢查清單

- [ ] 清理今日任務
- [ ] n8n workflow 節點更新完成
- [ ] 調用 webhook 成功
- [ ] 回應包含 2 個任務 (learn + review)
- [ ] learn 任務包含 5 個假名
- [ ] review 任務包含 1 個假名
- [ ] iOS app 顯示正確
- [ ] 今日練習顯示 5 個假名
- [ ] 今日複習顯示 1 個假名
- [ ] 無重複內容

## 預期結果

### n8n 回應
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
      "content": "{\"kana_list\":[{\"kana\":\"あ\",\"romaji\":\"a\"},{\"kana\":\"い\",\"romaji\":\"i\"},{\"kana\":\"う\",\"romaji\":\"u\"},{\"kana\":\"え\",\"romaji\":\"e\"},{\"kana\":\"お\",\"romaji\":\"o\"}],\"kana_type\":\"hiragana\"}"
    }
  ]
}
```

### iOS 顯示
```
今日練習
學習新的假名
あ い う え お (5個假名)

今日複習
複習已學假名
き (1個假名)
```
