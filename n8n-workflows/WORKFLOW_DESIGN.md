# Kantoku n8n Workflow 設計文件

本文件詳細描述四個核心 Workflow 的邏輯、節點配置與實作步驟。

---

## 🔧 環境設定

### Supabase Credentials 設定
在 n8n Settings → Credentials 中新增：

**Credential Type**: Postgres
- Host: `db.xxxxxx.supabase.co`
- Database: `postgres`
- User: `postgres`
- Password: `[您的 Supabase Database Password]`
- SSL: `allow`
- Port: `5432`


### Gemini AI Credentials
在 n8n Settings → Credentials 中新增：

**Credential Type**: Google Gemini
- API Key: `[您的 Gemini API Key]`

⚠️ **注意**: 請使用 **Google Gemini Chat Model** 節點，該節點會自動處理 API 端點與認證，無需手動設定 Endpoint。

---

## 📋 Workflow 1: 任務生成（generate-tasks）✅ 已實作

> **實作日期**: 2026-01-23  
> **狀態**: ✅ 已完成並測試通過  
> **Webhook URL**: `http://localhost:5678/webhook/generate-tasks`  
> **測試使用者**: `ebc3cd0d-dc42-42c1-920a-87328627fe35`

### 目的
根據使用者當前進度、間隔重複演算法、弱項分析，自動生成今日學習任務。

### Webhook 配置
- **Method**: POST
- **Path**: `/webhook/generate-tasks`
- **Request Body**:
```json
{
  "user_id": "uuid",
  "daily_goal_minutes": 30
}
```

### 流程設計

```
[Webhook] 
  ↓
[1. 查詢使用者進度]
  ├─ user_progress (當前階段)
  ├─ kana_progress (已學假名、待複習項目)
  └─ learning_stats (整體進度)
  ↓
[2. 判斷學習階段] (IF 節點)
  ├─ 新學習階段？→ [3a. 選擇下一階段假名]
  └─ 複習階段？→ [3b. 查詢待複習假名]
  ↓
[4. 查詢可學單字]
  - WHERE required_kana ⊆ 已學假名
  - ORDER BY frequency_rank, min_stage_id
  - LIMIT 3-5
  ↓
[5. 組合任務清單] (Code 節點)
  - 60% 假名學習/複習
  - 40% 單字學習
  ↓
[6. 插入任務到 tasks 表]
  - Batch Insert
  ↓
[7. 回傳結果]
  - 今日任務清單
  - 預估完成時間
```

### 實際實作節點

| 設計節點 | 實作節點名稱 | n8n 節點類型 | 狀態 |
|---------|-------------|-------------|------|
| Webhook | Webhook | Webhook | ✅ |
| 查詢使用者進度 | Query - User Progress | Supabase | ✅ |
| 查詢學習階段 | Query - Learning Stage | Supabase | ✅ |
| 查詢已學假名 | Query - Learned Kana | Supabase | ✅ |
| 查詢待複習項目 | Query - Review Items | Supabase | ✅ |
| 判斷學習策略 | IF - Has Review Items | IF | ✅ |
| 選擇新假名 | Code - Select New Kana | Code | ✅ |
| 準備複習假名 | Code - Prepare Review Kana | Code | ✅ |
| 組合任務 | Code - Build Tasks | Code | ✅ |
| 批次插入 | Loop - Insert Tasks | Loop Over Items | ✅ |
| 插入任務 | Insert - Task | Supabase | ✅ |
| 格式化回應 | Code - Format Response | Code | ✅ |
| 回傳結果 | Respond to Webhook | Respond to Webhook | ✅ |

**總計**: 13 個節點

### 測試結果

**測試指令**:
```bash
# 測試有複習任務的用戶
curl -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35"}'

# 測試無複習任務的新用戶
curl -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "5d3f4e09-647f-4194-8411-19283e37115a"}'

# 格式化輸出（使用 jq）
curl -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35"}' | jq '.'
```

**成功回應（有複習任務）**:
```json
{
  "success": true,
  "tasks_generated": 1,
  "tasks": [
    {
      "id": "b23438c9-cdb7-4a5c-b743-347259601df6",
      "user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35",
      "task_type": "kana_review",
      "content": "{\"review_kana\":[{\"kana\":\"き\",\"romaji\":\"ki\"},{\"kana\":\"き\",\"romaji\":\"ki\"},...],\"kana_type\":\"hiragana\"}",
      "status": "pending",
      "due_date": "2026-01-31",
      "skipped": false,
      "created_at": "2026-01-31T04:03:38.487819+00:00",
      "updated_at": "2026-01-31T04:03:38.487819+00:00"
    }
  ],
  "estimated_minutes": 3,
  "message": "今日任務已生成"
}
```

**成功回應（無複習任務 - 學習新假名）**:
```json
{
  "success": true,
  "tasks_generated": 1,
  "tasks": [
    {
      "id": "952f6168-ea27-4f85-b025-3ca21661513d",
      "user_id": "5d3f4e09-647f-4194-8411-19283e37115a",
      "task_type": "kana_learn",
      "content": "{\"kana_list\":[{\"kana\":\"あ\",\"romaji\":\"a\"},{\"kana\":\"い\",\"romaji\":\"i\"},{\"kana\":\"う\",\"romaji\":\"u\"},{\"kana\":\"え\",\"romaji\":\"e\"},{\"kana\":\"お\",\"romaji\":\"o\"}],\"kana_type\":\"hiragana\"}",
      "status": "pending",
      "due_date": "2026-01-31",
      "skipped": false,
      "created_at": "2026-01-31T04:04:23.989109+00:00",
      "updated_at": "2026-01-31T04:04:23.989109+00:00"
    }
  ],
  "estimated_minutes": 3,
  "message": "今日任務已生成"
}
```

### API 回應結構

| 欄位 | 類型 | 說明 |
|------|------|------|
| `success` | boolean | 任務生成是否成功 |
| `tasks_generated` | number | 生成的任務數量 |
| `tasks` | array | 任務列表 |
| `tasks[].id` | uuid | 任務 ID |
| `tasks[].user_id` | uuid | 使用者 ID |
| `tasks[].task_type` | string | `kana_review` 或 `kana_learn` |
| `tasks[].content` | string (JSON) | 任務內容（需解析 JSON） |
| `tasks[].status` | string | 任務狀態：`pending` |
| `tasks[].due_date` | date | 截止日期 |
| `tasks[].skipped` | boolean | 是否已跳過 |
| `tasks[].created_at` | timestamp | 建立時間 |
| `tasks[].updated_at` | timestamp | 更新時間 |
| `estimated_minutes` | number | 預估完成時間（分鐘） |
| `message` | string | 回應訊息 |

### Content 結構說明

`content` 欄位為 JSON 字串，需解析後使用：

**kana_review 類型**:
```json
{
  "review_kana": [
    {"kana": "き", "romaji": "ki"},
    {"kana": "き", "romaji": "ki"}
  ],
  "kana_type": "hiragana"
}
```

**kana_learn 類型**:
```json
{
  "kana_list": [
    {"kana": "あ", "romaji": "a"},
    {"kana": "い", "romaji": "i"},
    {"kana": "う", "romaji": "u"},
    {"kana": "え", "romaji": "e"},
    {"kana": "お", "romaji": "o"}
  ],
  "kana_type": "hiragana"
}
```

**驗證項目**:
- ✅ 有複習任務時生成 `kana_review` 類型任務
- ✅ 無複習任務時生成 `kana_learn` 類型任務
- ✅ 成功查詢當前階段（Stage 1: あ行）
- ✅ Content 格式統一為 JSON 字串
- ✅ 成功插入 tasks 表
- ✅ 回傳格式正確，包含完整時間戳記

---

### 節點詳細配置（設計參考）

#### 節點 1: 查詢使用者進度（Postgres Node）
**Operation**: Execute Query

```sql
-- 查詢 1: 當前階段
SELECT 
  up.current_stage_id,
  ls.name as stage_name,
  ls.kana_chars
FROM user_progress up
JOIN learning_stages ls ON up.current_stage_id = ls.id
WHERE up.user_id = $1;

-- 查詢 2: 已學假名（mastery_score > 50）
SELECT kana, mastery_score, next_review
FROM kana_progress
WHERE user_id = $1 
  AND status IN ('learning', 'reviewing', 'mastered')
ORDER BY mastery_score ASC;

-- 查詢 3: 待複習假名（next_review <= NOW）
SELECT kana, romaji, mastery_score
FROM kana_progress
WHERE user_id = $1 
  AND next_review <= NOW()
  AND status IN ('learning', 'reviewing')
ORDER BY mastery_score ASC
LIMIT 5;

-- 查詢 4: 整體統計
SELECT category, progress_percent
FROM learning_stats
WHERE user_id = $1;
```

#### 節點 2: 判斷學習策略（IF Node）

**Condition 1**: 有待複習項目
- `{{ $json.review_items.length > 0 }}`
- TRUE → 複習路徑
- FALSE → 新學習路徑

#### 節點 3a: 選擇下一階段假名（Code Node）

```javascript
// 從當前階段選擇未學習的假名
const currentStage = $input.item.json.current_stage;
const learnedKana = $input.item.json.learned_kana || [];
const stageKana = currentStage.kana_chars;

// 找出尚未學習的假名
const newKana = stageKana.filter(k => !learnedKana.includes(k));

// 每次選擇 3-5 個新假名
const kanaToLearn = newKana.slice(0, 5);

return {
  kana_list: kanaToLearn,
  task_type: 'kana_learn'
};
```

#### 節點 3b: 準備複習假名（Code Node）

```javascript
const reviewItems = $input.item.json.review_items;

return {
  kana_list: reviewItems.map(item => item.kana),
  task_type: 'kana_review'
};
```

#### 節點 4: 查詢可學單字（Postgres Node）

```sql
-- 查詢可學單字
WITH learned_kana AS (
  SELECT ARRAY_AGG(kana) as kana_list
  FROM kana_progress
  WHERE user_id = $1 
    AND mastery_score > 50
)
SELECT 
  v.id,
  v.word,
  v.word_kanji,
  v.reading,
  v.meaning,
  v.example_sentence,
  v.required_kana,
  v.frequency_rank
FROM vocabulary v, learned_kana lk
WHERE v.required_kana <@ lk.kana_list  -- 所有需要的假名都已學會
  AND v.level = 'N5'
  AND NOT EXISTS (  -- 尚未學過
    SELECT 1 FROM vocabulary_progress vp
    WHERE vp.word_id = v.id 
      AND vp.user_id = $1
      AND vp.status = 'mastered'
  )
ORDER BY 
  v.frequency_rank ASC,
  v.min_stage_id ASC
LIMIT 5;
```

#### 節點 5: 組合任務清單（Code Node）

```javascript
const kanaList = $input.item.json.kana_list || [];
const vocabList = $input.item.json.vocab_list || [];
const userId = $('Webhook').item.json.body.user_id;
const taskType = $input.item.json.task_type;

const tasks = [];

// 假名學習/複習任務
kanaList.forEach(kana => {
  tasks.push({
    user_id: userId,
    task_type: taskType, // 'kana_learn' 或 'kana_review'
    content: {
      kana: kana,
      type: 'hiragana',
      description: taskType === 'kana_learn' 
        ? `學習平假名「${kana}」` 
        : `複習平假名「${kana}」`,
      prompt: `請唸出「${kana}」的發音，或輸入羅馬拼音`,
      expected_romaji: kana // 從 kana_data.json 查詢
    },
    status: 'pending',
    due_date: new Date().toISOString().split('T')[0]
  });
});

// 單字學習任務
vocabList.forEach(vocab => {
  tasks.push({
    user_id: userId,
    task_type: 'vocabulary',
    content: {
      word_id: vocab.id,
      word: vocab.word,
      word_kanji: vocab.word_kanji,
      meaning: vocab.meaning,
      reading: vocab.reading,
      example_sentence: vocab.example_sentence,
      description: `學習單字「${vocab.word_kanji || vocab.word}」`,
      prompt: `請輸入「${vocab.meaning}」的平假名`
    },
    status: 'pending',
    due_date: new Date().toISOString().split('T')[0]
  });
});

return tasks.map(task => ({ json: task }));
```

#### 節點 6: 插入任務（Postgres Node）

```sql
INSERT INTO tasks (user_id, task_type, content, status, due_date)
VALUES ($1, $2, $3::jsonb, $4, $5)
RETURNING id, task_type, content, status, due_date;
```

#### 節點 7: 回傳結果（Respond Node）

```json
{
  "success": true,
  "tasks_generated": "{{ $json.tasks.length }}",
  "tasks": "{{ $json.tasks }}",
  "estimated_minutes": "{{ $json.tasks.length * 3 }}",
  "message": "今日任務已生成"
}
```

---

## ✅ Workflow 2: 提交審核（review-submission）✅ 已實作

> **實作日期**: 2026-01-24  
> **狀態**: ✅ 已完成並測試通過  
> **Webhook URL**: `http://localhost:5678/webhook/review-submission`

### 目的
處理使用者提交的任務，支援**文字輸入**和**直接確認**兩種方式。

### Webhook 配置
- **Method**: POST
- **Path**: `/webhook/review-submission`
- **Request Body**:
```json
{
  "task_id": "uuid",
  "submission_type": "text",  // "text" 或 "direct_confirm"
  "content": "sakana"         // 文字提交時必填
}
```

### 流程設計

```
[Webhook]
  ↓
[1. 查詢任務詳情]
  ↓
[2. 判斷提交類型] (Switch 節點)
  ├─ direct_confirm → [3a. 直接標記為通過]
  └─ text → [3b. AI 審核文字答案]
  ↓
[4. 更新任務狀態]
  ├─ 通過 → status = 'passed'
  └─ 失敗 → status = 'failed'
  ↓
[5. 更新學習進度] (IF 通過)
  ├─ kana_progress (correct_count++, 計算 next_review)
  └─ vocabulary_progress
  ↓
[6. 插入 submission 記錄]
  ↓
[7. 回傳審核結果]
```

### 節點詳細配置

#### 節點 1: 查詢任務詳情（Postgres Node）

```sql
SELECT 
  t.id,
  t.user_id,
  t.task_type,
  t.content
FROM tasks t
WHERE t.id = $1;
```

#### 節點 2: 判斷提交類型（Switch Node）

**Route 0**: direct_confirm
- `{{ $json.body.submission_type === 'direct_confirm' }}`

**Route 1**: text
- `{{ $json.body.submission_type === 'text' }}`

#### 節點 3a: 直接確認（Set Node）

```javascript
return {
  passed: true,
  score: 100,
  ai_feedback: {
    message: '使用者確認已完成',
    type: 'direct_confirm'
  }
};
```

#### 節點 3b: Google Gemini Chat Model 文字審核（新節點）

節點類型: **Google Gemini Chat Model**

**設定要點**:
- **Credential**: 選擇已設定的 Google Gemini Credential
- **Model**: `gemini-2.5-flash`
- **Prompt**:
  > 你是日文學習審核 AI。請審核以下答案是否正確。
  > 
  > 任務類型：{{ $('Query Task').item.json.task_type }}
  > 任務內容：{{ $('Query Task').item.json.content }}
  > 使用者答案：{{ $('Webhook').item.json.body.content }}
  > 
  > 請以 JSON 格式回答：
  > {
  >   "passed": true/false,
  >   "score": 0-100,
  >   "feedback": "詳細回饋",
  >   "correct_answer": "正確答案（如果錯誤）"
  > }
  > 
  > 審核標準：
  > - 假名學習：羅馬拼音完全正確即通過
  > - 單字學習：允許小錯誤（如長音、促音），80% 相似度即通過

**Parse AI Response (Code Node)**:
```javascript
const response = $input.item.json;
let content = '';
try {
  content = response?.candidates?.[0]?.content?.parts?.[0]?.text ||
            response?.candidates?.[0]?.content?.text ||
            response?.choices?.[0]?.message?.content || '';
} catch (e) {
  content = '';
}
const jsonMatch = content.match(/\{[\s\S]*\}/);
const result = jsonMatch ? JSON.parse(jsonMatch[0]) : { passed: false, score: 0, feedback: '', correct_answer: '' };

return {
  passed: result.passed,
  score: result.score,
  ai_feedback: {
    feedback: result.feedback,
    correct_answer: result.correct_answer,
    type: 'ai_review'
  }
};
```

#### 節點 4: 更新任務狀態（Postgres Node）

```sql
UPDATE tasks
SET 
  status = CASE WHEN $2 THEN 'passed' ELSE 'failed' END,
  updated_at = NOW()
WHERE id = $1
RETURNING id, status;
```

#### 節點 5: 更新學習進度（Postgres Node - 僅通過時執行）

**IF Condition**: `{{ $json.passed === true }}`

```sql
-- 假名進度更新
UPDATE kana_progress
SET 
  correct_count = correct_count + 1,
  last_reviewed = NOW(),
  next_review = NOW() + INTERVAL '1 day' * CASE 
    WHEN correct_count = 0 THEN 1
    WHEN correct_count = 1 THEN 3
    WHEN correct_count = 2 THEN 7
    WHEN correct_count = 3 THEN 14
    WHEN correct_count >= 4 THEN 30
  END,
  mastery_score = LEAST(100, (correct_count + 1) * 20),
  status = CASE 
    WHEN correct_count >= 4 THEN 'mastered'
    WHEN correct_count >= 1 THEN 'reviewing'
    ELSE 'learning'
  END,
  updated_at = NOW()
WHERE user_id = $1
  AND kana = $2
RETURNING id, mastery_score, next_review;

-- 單字進度更新
INSERT INTO vocabulary_progress (user_id, word_id, status, correct_count, last_reviewed)
VALUES ($1, $2, 'learning', 1, NOW())
ON CONFLICT (user_id, word_id) 
DO UPDATE SET 
  correct_count = vocabulary_progress.correct_count + 1,
  status = CASE 
    WHEN vocabulary_progress.correct_count >= 3 THEN 'mastered'
    ELSE 'learning'
  END,
  last_reviewed = NOW(),
  updated_at = NOW()
RETURNING id, status;
```

#### 節點 6: 插入提交記錄（Postgres Node）

```sql
INSERT INTO submissions (task_id, submission_type, content, ai_feedback, score, passed)
VALUES ($1, $2, $3, $4::jsonb, $5, $6)
RETURNING id, created_at;
```

#### 節點 7: 回傳結果（Respond Node）

```json
{
  "success": true,
  "passed": "{{ $json.passed }}",
  "score": "{{ $json.score }}",
  "feedback": "{{ $json.ai_feedback.feedback }}",
  "correct_answer": "{{ $json.ai_feedback.correct_answer }}",
  "message": "{{ $json.passed ? '通過！繼續加油！' : '再試一次！' }}"
}
```

---

## 📝 Workflow 3: 測驗生成（generate-test）

### 目的
當學習進度達到 10%, 20%, ..., 100% 時，自動生成階段性測驗。

### Webhook 配置
- **Method**: POST
- **Path**: `/webhook/generate-test`
- **Request Body**:
```json
{
  "user_id": "uuid",
  "category": "hiragana",
  "progress_milestone": 10
}
```

### 流程設計

```
[Webhook]
  ↓
[1. 檢查是否已有該測驗]
  ↓ (不存在)
[2. 查詢已學項目]
  ├─ kana_progress (mastered)
  └─ vocabulary_progress (mastered)
  ↓
[3. Google Gemini Chat Model 生成題目]
  - 10 題選擇題
  - 覆蓋已學內容
  ↓
[4. 插入測驗到 tests 表]
  ↓
[5. 回傳測驗內容]
```

### 節點詳細配置

#### 節點 1: 檢查測驗是否存在（Postgres Node）

```sql
SELECT id, passed
FROM tests
WHERE user_id = $1
  AND category = $2
  AND progress_milestone = $3;
```

**IF 節點**: 如果已存在且通過，直接回傳；否則繼續生成。

#### 節點 2: 查詢已學項目（Postgres Node）

```sql
-- 已掌握的假名
SELECT kana, romaji
FROM kana_progress
WHERE user_id = $1
  AND kana_type = 'hiragana'
  AND mastery_score >= 70
ORDER BY RANDOM()
LIMIT 50;
```

#### 節點 3: Google Gemini Chat Model 生成題目

節點類型: **Google Gemini Chat Model**

**設定要點**:
- **Credential**: 選擇已設定的 Google Gemini Credential
- **Model**: `gemini-2.5-flash`
- **Prompt**:
  > 你是日文測驗生成 AI。
  > 根據以下已學內容生成 10 題測驗，題型混合：假名→羅馬拼音、羅馬拼音→假名、單字辨識；輸出格式 JSON。
  > 已學內容：{{ $json.learned_items }}
  > 每題需包含 4 個選項，只有 1 個正確答案。

#### 節點 4: 插入測驗（Postgres Node）

```sql
INSERT INTO tests (user_id, category, progress_milestone, questions)
VALUES ($1, $2, $3, $4::jsonb)
RETURNING id, questions;
```

#### 節點 5: 回傳測驗（Respond Node）

```json
{
  "success": true,
  "test_id": "{{ $json.id }}",
  "questions": "{{ $json.questions }}",
  "total_questions": 10,
  "message": "測驗已生成，請開始作答"
}
```

---

## 📊 Workflow 4: 測驗批改（grade-test）

### 目的
批改使用者提交的測驗答案，計算分數，識別弱項。

### Webhook 配置
- **Method**: POST
- **Path**: `/webhook/grade-test`
- **Request Body**:
```json
{
  "test_id": "uuid",
  "answers": {
    "0": "a",
    "1": "ka",
    ...
  }
}
```

### 流程設計

```
[Webhook]
  ↓
[1. 查詢測驗題目]
  ↓
[2. 批改答案] (Code 節點)
  - 計算分數
  - 識別錯誤項目
  ↓
[3. 更新測驗結果]
  - answers, score, passed, weakness_items
  ↓
[4. 更新學習統計] (IF passed)
  ↓
[5. 調整弱項的 next_review] (IF 有弱項)
  ↓
[6. 回傳批改結果]
```

### 節點詳細配置

#### 節點 1: 查詢測驗（Postgres Node）

```sql
SELECT 
  t.id,
  t.user_id,
  t.questions,
  t.category
FROM tests t
WHERE t.id = $1;
```

#### 節點 2: 批改答案（Code Node）

```javascript
const test = $('Query Test').item.json;
const answers = $('Webhook').item.json.body.answers;
const questions = test.questions.questions;

let correctCount = 0;
const weaknessItems = [];

questions.forEach((q, index) => {
  const userAnswer = answers[index.toString()];
  const correctAnswer = q.correct_answer;
  
  if (userAnswer === correctAnswer) {
    correctCount++;
  } else {
    weaknessItems.push({
      question: q.question,
      user_answer: userAnswer,
      correct_answer: correctAnswer,
      kana: q.kana || null
    });
  }
});

const score = Math.round((correctCount / questions.length) * 100);
const passed = score >= 80;

return {
  answers: answers,
  score: score,
  passed: passed,
  weakness_items: weaknessItems,
  correct_count: correctCount,
  total_questions: questions.length
};
```

#### 節點 3: 更新測驗結果（Postgres Node）

```sql
UPDATE tests
SET 
  answers = $2::jsonb,
  score = $3,
  passed = $4,
  weakness_items = $5::jsonb,
  completed_at = NOW()
WHERE id = $1
RETURNING id, score, passed;
```

#### 節點 4: 更新學習統計（Postgres Node - 僅通過時）

**IF**: `{{ $json.passed === true }}`

```sql
-- 重新計算進度百分比
WITH progress_calc AS (
  SELECT 
    COUNT(*) FILTER (WHERE mastery_score >= 70) as mastered,
    COUNT(*) as total
  FROM kana_progress
  WHERE user_id = $1
    AND kana_type = 'hiragana'
)
UPDATE learning_stats
SET 
  mastered_items = (SELECT mastered FROM progress_calc),
  progress_percent = ROUND((SELECT mastered::float / total * 100 FROM progress_calc)),
  updated_at = NOW()
WHERE user_id = $1
  AND category = 'hiragana'
RETURNING progress_percent;
```

#### 節點 5: 調整弱項複習（Postgres Node）

**IF**: `{{ $json.weakness_items.length > 0 }}`

```javascript
// 提取弱項假名
const weaknessKana = $input.item.json.weakness_items
  .map(item => item.kana)
  .filter(k => k !== null);

return weaknessKana.map(kana => ({ kana }));
```

```sql
-- 將弱項的 next_review 提前到明天
UPDATE kana_progress
SET 
  next_review = NOW() + INTERVAL '1 day',
  status = 'reviewing',
  updated_at = NOW()
WHERE user_id = $1
  AND kana = $2;
```

#### 節點 6: 回傳結果（Respond Node）

```json
{
  "success": true,
  "score": "{{ $json.score }}",
  "passed": "{{ $json.passed }}",
  "correct_count": "{{ $json.correct_count }}",
  "total_questions": "{{ $json.total_questions }}",
  "weakness_items": "{{ $json.weakness_items }}",
  "message": "{{ $json.passed ? '恭喜通過測驗！' : '繼續努力！建議加強弱項。' }}"
}
```

---

## 🧪 測試計劃

### 1. Workflow 1 測試

**測試 1: 新使用者生成任務**
```bash
curl -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-uuid",
    "daily_goal_minutes": 30
  }'
```

**預期結果**: 
- 生成 5-8 個任務
- 包含 あ行 假名學習任務
- 包含 2-3 個基礎單字

### 2. Workflow 2 測試

**測試 2a: 文字提交**
```bash
curl -X POST http://localhost:5678/webhook/review-submission \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "task-uuid",
    "submission_type": "text",
    "content": "a"
  }'
```

**測試 2b: 直接確認**
```bash
curl -X POST http://localhost:5678/webhook/review-submission \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "task-uuid",
    "submission_type": "direct_confirm"
  }'
```

### 3. Workflow 3 測試

```bash
curl -X POST http://localhost:5678/webhook/generate-test \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-uuid",
    "category": "hiragana",
    "progress_milestone": 10
  }'
```

### 4. Workflow 4 測試

```bash
curl -X POST http://localhost:5678/webhook/grade-test \
  -H "Content-Type: application/json" \
  -d '{
    "test_id": "test-uuid",
    "answers": {
      "0": "a",
      "1": "ka",
      ...
    }
  }'
```

---

## 📌 下一步

1. **在 n8n UI 中建立 Workflows**
   - 登入 http://localhost:5678
   - 依照本文件逐一建立四個 Workflow

2. **測試 Webhooks**
   - 使用上述 curl 指令測試

3. **調整與優化**
   - 根據測試結果調整邏輯
   - 優化 AI Prompt
   - 調整間隔重複演算法參數

4. **匯出 Workflows**
   - 匯出為 JSON 存入 `n8n-workflows/` 資料夾
