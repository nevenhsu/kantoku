# Workflow 2: 提交審核（review-submission）進度記錄

**開始日期**: 2026-01-23  
**完成日期**: 2026-01-24  
**狀態**: ✅ 完成（100%）  
**實際完成時間**: 約 3 小時

---

## 📊 總體進度

| Phase | 內容 | 節點數 | 狀態 | 完成日期 |
|-------|------|--------|------|---------|
| Phase 1 | Webhook + 基礎架構 | 2 | ✅ 完成 | 2026-01-23 |
| Phase 2 | 查詢任務詳情 | 1 | ✅ 完成 | 2026-01-23 |
| Phase 3 | 分流處理（Switch + AI 審核） | 5 | ✅ 完成 | 2026-01-23 |
| Phase 4 | 合併路徑 + 更新任務狀態 | 2 | ✅ 完成 | 2026-01-24 |
| Phase 5 | 更新學習進度 | 4 | ✅ 完成 | 2026-01-24 |
| Phase 6 | 插入提交記錄 + 回傳 | 3 | ✅ 完成 | 2026-01-24 |

**總進度**: 100%（6/6 Phases）✅ **全部完成**

---

## ✅ 已完成項目

### Phase 1: Webhook + 基礎架構

**完成時間**: ~10 分鐘

| 節點 | 類型 | 狀態 |
|-----|------|------|
| Webhook | Webhook | ✅ |
| Respond to Webhook | Respond | ✅ |

**測試結果**: ✅ 成功接收 POST 請求

---

### Phase 2: 查詢任務詳情

**完成時間**: ~10 分鐘

| 節點 | 類型 | 操作 | 狀態 |
|-----|------|-----|------|
| Query - Task Details | Supabase | Get (單筆查詢) | ✅ |

**配置**:
- Table: `tasks`
- Operation: Get
- ID: `{{ $json.body.task_id }}`

**測試結果**: ✅ 成功查詢任務詳情

```json
{
  "id": "d5439fb7-cf0d-4a77-b927-54c86ec595e6",
  "task_type": "kana_learn",
  "content": "{\"kana\":\"あ\",\"romaji\":\"a\",...}",
  "status": "pending"
}
```

---

### Phase 3: 分流處理（Switch + AI 審核）

**完成時間**: ~1.5 小時

#### 3.1 Switch 節點

| 節點 | 類型 | 狀態 |
|-----|------|------|
| Switch - Submission Type | Switch | ✅ |

**路由規則**:
- Route 0 (direct_confirm): `submission_type === 'direct_confirm'`
- Route 1 (text): `submission_type === 'text'`

#### 3.2 Direct Confirm 路徑

| 節點 | 類型 | 狀態 |
|-----|------|------|
| Code - Direct Confirm | Code | ✅ |

**輸出格式**:
```json
{
  "passed": true,
  "score": 100,
  "ai_feedback": {
    "message": "使用者確認已完成",
    "feedback": "直接確認通過",
    "type": "direct_confirm"
  }
}
```

**測試結果**: ✅ 通過

#### 3.3 AI 審核路徑

| 節點 | 類型 | 狀態 |
|-----|------|------|
| Gemini - Review Answer | AI Agent | ✅ |
| Gemini - Review Answer Model | LLM Model | ✅ |
| Code - Parse AI Response | Code | ✅ |

**AI 配置**:
- Model: **gemini-2.5-flash**
- Credential: Google Gemini - Kantoku
- Temperature: 0.1（預設）

**Prompt**:
```
你是日文學習審核 AI。請審核以下答案是否正確。

任務類型：{{ task_type }}
任務內容：{{ content }}
使用者答案：{{ user_answer }}

請以 JSON 格式回答（只回傳 JSON，不要其他文字）：
{
  "passed": true 或 false,
  "score": 0-100 的數字,
  "feedback": "詳細回饋",
  "correct_answer": "正確答案（如果錯誤才需要）"
}

審核標準：
- 假名學習：羅馬拼音完全正確即通過
- 大小寫不敏感
```

**測試結果**:

| 測試案例 | 輸入 | 輸出 | 狀態 |
|---------|------|------|------|
| 正確答案 | `content: "a"` | `passed: true, score: 100` | ✅ |
| 錯誤答案 | `content: "wrong"` | `passed: false, score: 0, correct_answer: "a"` | ✅ |

**實際回應範例**（正確答案）:
```json
{
  "passed": true,
  "score": 100,
  "ai_feedback": {
    "feedback": "羅馬拼音完全正確，非常棒！",
    "correct_answer": null,
    "type": "ai_review"
  }
}
```

**實際回應範例**（錯誤答案）:
```json
{
  "passed": false,
  "score": 0,
  "ai_feedback": {
    "feedback": "您的答案「wrong」不正確。平假名「あ」的羅馬拼音是「a」。",
    "correct_answer": "a",
    "type": "ai_review"
  }
}
```

---

## 🔜 待完成項目

### Phase 4: 合併路徑 + 更新任務狀態

**預估時間**: ~15 分鐘

| 節點 | 類型 | 說明 |
|-----|------|------|
| Merge | Merge | 合併 direct_confirm 和 text 兩條路徑 |
| Supabase - Update Task | Supabase | 更新 `tasks.status` 為 passed/failed |

**SQL 邏輯**:
```sql
UPDATE tasks
SET 
  status = CASE WHEN passed THEN 'passed' ELSE 'failed' END,
  updated_at = NOW()
WHERE id = task_id
RETURNING id, status;
```

---

### Phase 5: 更新學習進度

**預估時間**: ~20 分鐘

| 節點 | 類型 | 說明 |
|-----|------|------|
| IF - Passed | IF | 判斷 `passed === true` |
| Supabase - Upsert Kana Progress | Supabase | 更新/插入 `kana_progress` |

**邏輯重點**:
- 新假名：INSERT 新記錄（correct_count=1, status='learning'）
- 已有假名：UPDATE correct_count++, 計算 next_review
- 間隔重複演算法：1 → 3 → 7 → 14 → 30 天
- 計算 mastery_score: `(correct_count + 1) * 20`（最高 100）

**Supabase 操作**:
- Operation: **Upsert**（INSERT ON CONFLICT UPDATE）
- Conflict Key: `(user_id, kana, kana_type)`

---

### Phase 6: 插入提交記錄 + 回傳

**預估時間**: ~10 分鐘

| 節點 | 類型 | 說明 |
|-----|------|------|
| Supabase - Insert Submission | Supabase | 插入 `submissions` 表 |
| Code - Format Response | Code | 格式化最終回應 |

**最終回應格式**:
```json
{
  "success": true,
  "passed": true,
  "score": 100,
  "feedback": "正確！",
  "correct_answer": null,
  "message": "通過！繼續加油！"
}
```

---

## 🧪 完整測試計劃

待 Phase 4-6 完成後執行：

### 測試 1: 直接確認 + 完整流程
```bash
curl -X POST http://localhost:5678/webhook-test/review-submission \
  -H "Content-Type: application/json" \
  -d '{"task_id": "xxx", "submission_type": "direct_confirm"}'
```

**驗證項目**:
- ✅ 任務狀態更新為 `passed`
- ✅ kana_progress 記錄新增/更新
- ✅ submissions 記錄插入
- ✅ 回傳正確格式

### 測試 2: 文字提交（正確答案）+ 完整流程
```bash
curl -X POST http://localhost:5678/webhook-test/review-submission \
  -H "Content-Type: application/json" \
  -d '{"task_id": "xxx", "submission_type": "text", "content": "a"}'
```

### 測試 3: 文字提交（錯誤答案）+ 完整流程
```bash
curl -X POST http://localhost:5678/webhook-test/review-submission \
  -H "Content-Type: application/json" \
  -d '{"task_id": "xxx", "submission_type": "text", "content": "wrong"}'
```

**驗證項目**:
- ✅ 任務狀態更新為 `failed`
- ✅ kana_progress **不更新**
- ✅ submissions 記錄插入
- ✅ 回傳錯誤提示和正確答案

---

## 📝 技術筆記

### n8n AI Agent 節點結構

當使用 **Google Gemini Chat Model** 時，n8n 會自動建立：
1. **Trigger 節點**（我們不需要，已刪除）
2. **AI Agent 主節點**（處理邏輯）
3. **LLM Model 節點**（提供 AI 能力）

節點之間有**虛線連接**（AI 模型連接），這是正常的。

### Gemini API 版本

- ✅ **gemini-2.5-flash**：目前支援版本
- ❌ ~~gemini-1.5-flash~~：已不建議使用

### Switch 節點路由

Switch 節點根據條件將資料流分流到不同路徑：
- 使用 Expression: `{{ $('Webhook').item.json.body.submission_type }}`
- 可以有多個路由規則
- 需要用 Merge 節點重新合併

### AI Prompt 設計要點

1. **明確角色**：「你是日文學習審核 AI」
2. **要求格式**：「請以 JSON 格式回答（只回傳 JSON）」
3. **提供上下文**：任務類型、任務內容、使用者答案
4. **明確標準**：羅馬拼音完全正確、大小寫不敏感
5. **結構化輸出**：定義 JSON Schema

---

## 💡 學到的經驗

### 成功的地方

1. ✅ **AI Agent 節點使用**：成功整合 Gemini 2.5 Flash
2. ✅ **Switch 分流**：正確處理不同提交類型
3. ✅ **Prompt 設計**：AI 能準確理解並回傳 JSON
4. ✅ **JSON 解析**：Code 節點成功從 AI 回應中提取結構化資料

### 遇到的問題

1. **節點命名引用錯誤**
   - 問題：Prompt 中引用的節點名稱不存在
   - 解決：確認實際節點名稱（n8n 顯示的名稱）
   - 教訓：在 Expression 中引用其他節點前，先確認節點名稱

2. **AI Agent 節點結構**
   - 問題：不清楚自動生成的多個節點如何連接
   - 解決：理解 Agent + Model 的架構，刪除不需要的 Trigger
   - 教訓：n8n AI 節點會建立完整的 Agent 架構

3. **Gemini 版本更新**
   - 問題：原設計使用的 gemini-1.5-flash 已不支援
   - 解決：更新為 gemini-2.5-flash
   - 教訓：API 版本會變更，需要保持更新

---

## 📊 節點清單

### 已建立節點（8 個）

| # | 節點名稱 | 節點類型 | 說明 |
|---|---------|---------|------|
| 1 | Webhook | Webhook | 接收 POST 請求 |
| 2 | Query - Task Details | Supabase | 查詢任務詳情 |
| 3 | Switch - Submission Type | Switch | 分流處理 |
| 4 | Code - Direct Confirm | Code | 直接確認結果 |
| 5 | Gemini - Review Answer | AI Agent | AI 審核主節點 |
| 6 | Gemini - Review Answer Model | LLM Model | Gemini 2.5 Flash |
| 7 | Code - Parse AI Response | Code | 解析 AI 回應 |
| 8 | Respond to Webhook | Respond | 回傳結果 |

### 待建立節點（約 6-7 個）

| # | 節點名稱 | 節點類型 | Phase |
|---|---------|---------|-------|
| 9 | Merge | Merge | Phase 4 |
| 10 | Supabase - Update Task | Supabase | Phase 4 |
| 11 | IF - Passed | IF | Phase 5 |
| 12 | Supabase - Upsert Kana Progress | Supabase | Phase 5 |
| 13 | Supabase - Insert Submission | Supabase | Phase 6 |
| 14 | Code - Format Response | Code | Phase 6 |

**預計總節點數**: 14-15 個

---

## 🚀 下次會話準備

### 前置檢查

1. ✅ n8n Workflow `review-submission` 已儲存
2. ⏳ 確認有可用的測試任務（使用 Workflow 1 生成）
3. ⏳ 測試用 task_id 準備好

### 會話目標

**主要目標**: 完成 Phase 4-6，讓 Workflow 2 完整運作

**時間分配**:
- Phase 4: ~15 分鐘
- Phase 5: ~20 分鐘
- Phase 6: ~10 分鐘
- 測試: ~10 分鐘
- 文件更新 + 匯出: ~10 分鐘

**總計**: ~60-75 分鐘

### 測試資料準備

執行以下指令生成新的測試任務：
```bash
curl -X POST http://localhost:5678/webhook-test/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35", "daily_goal_minutes": 30}'
```

複製回傳的 task_id 供下次測試使用。

---

## 📚 參考資源

- [WORKFLOW_DESIGN.md](./WORKFLOW_DESIGN.md) - 完整設計文件
- [WORKFLOW_1_IMPLEMENTATION.md](./WORKFLOW_1_IMPLEMENTATION.md) - Workflow 1 實作參考
- [Supabase Schema](../supabase/schema.sql) - 資料庫結構

---

**狀態**: ⏳ 進行中（50% 完成）  
**下次會話**: 完成 Phase 4-6  
**最後更新**: 2026-01-23

---

## ✅ Phase 4-6 完成記錄（2026-01-24）

### Phase 4: 合併路徑 + 更新任務狀態 ✅

**完成時間**: ~15 分鐘

#### 已建立節點

| 節點名稱 | 類型 | 關鍵設定 |
|---------|------|---------|
| Merge | Merge | Mode: Combine, **Include Any Unpaired Items: true** ⭐ |
| Postgres - Update Task | Postgres | UPDATE tasks SET status |

#### 關鍵發現

**問題**: Merge 節點顯示 "No output data returned"  
**原因**: Switch 分流後每次只有一條路徑有資料  
**解決**: 啟用 **Include Any Unpaired Items** 選項

**測試結果**: ✅ 任務狀態成功更新為 passed/failed

---

### Phase 5: 更新學習進度 ✅

**完成時間**: ~25 分鐘

#### 已建立節點

| 節點名稱 | 類型 | 說明 |
|---------|------|------|
| Code - Prepare Data | Code | 解析 task content，準備進度更新資料 |
| IF - Passed | IF | 判斷 passed === true |
| Postgres - Upsert Progress (Pass) | Postgres | INSERT ON CONFLICT UPDATE（通過時） |
| Postgres - Update Progress (Fail) | Postgres | INSERT ON CONFLICT UPDATE（失敗時） |

#### 關鍵發現

**重要**: Supabase Node **不支援 Upsert** 操作  
**解決**: 使用 **Postgres Node** 直接執行 SQL：`INSERT ON CONFLICT UPDATE`

#### 間隔重複演算法實作

**通過時**：
- correct_count++
- mastery_score = (correct_count + 1) * 20
- next_review: 1 → 3 → 7 → 14 → 30 天
- status: learning → reviewing → mastered

**失敗時**：
- incorrect_count++
- next_review = NOW() + 1 天

**測試結果**:
- ✅ 正確答案：correct_count=1, mastery_score=40, next_review=+3天
- ✅ 錯誤答案：incorrect_count=1, next_review=+1天

---

### Phase 6: 插入提交記錄 + 回傳 ✅

**完成時間**: ~15 分鐘

#### 已建立節點

| 節點名稱 | 類型 | 說明 |
|---------|------|------|
| Merge - Progress Result | Merge | 合併 Pass/Fail 路徑 |
| Postgres - Insert Submission | Postgres | INSERT submissions 記錄 |
| Code - Format Response | Code | 格式化最終回應 |

**測試結果**: ✅ 所有路徑測試通過

---

## 🧪 完整測試記錄（2026-01-24）

### 測試 1: 正確答案（text）

**輸入**:
```json
{
  "task_id": "6cdc566f-72d7-4c55-bd3b-bdf36547b16c",
  "submission_type": "text",
  "content": "e"
}
```

**輸出**:
```json
{
  "success": true,
  "passed": true,
  "score": 100,
  "feedback": "羅馬拼音完全正確！",
  "correct_answer": null,
  "message": "通過！繼續加油！",
  "submission_id": "f105e754-287c-4511-b613-2eb84e851c64"
}
```

**資料庫驗證**:
- ✅ tasks.status = 'passed'
- ✅ kana_progress created/updated
- ✅ submissions inserted

---

### 測試 2: 錯誤答案（text）

**輸入**:
```json
{
  "task_id": "44742696-8a10-471d-b5cd-a718e7180c7b",
  "submission_type": "text",
  "content": "wrong"
}
```

**輸出**:
```json
{
  "success": true,
  "passed": false,
  "score": 0,
  "feedback": "您的答案不正確，平假名「い」的羅馬拼音是「i」。",
  "correct_answer": "i",
  "message": "再試一次！",
  "submission_id": "c31b8dab-63c5-482b-ae9d-e963a62355e7"
}
```

**資料庫驗證**:
- ✅ tasks.status = 'failed'
- ✅ kana_progress.incorrect_count++
- ✅ submissions inserted

---

### 測試 3: 直接確認（direct_confirm）

**輸入**:
```json
{
  "task_id": "44742696-8a10-471d-b5cd-a718e7180c7b",
  "submission_type": "direct_confirm"
}
```

**輸出**:
```json
{
  "success": true,
  "passed": true,
  "score": 100,
  "feedback": "直接確認通過",
  "correct_answer": null,
  "message": "通過！繼續加油！",
  "submission_id": "81c0d21b-a02d-4e49-b98e-e61b1d9395d3"
}
```

**資料庫驗證**:
- ✅ tasks.status = 'passed'
- ✅ kana_progress updated
- ✅ submissions inserted with type='direct_confirm'

---

## 📝 關鍵技術要點總結

### n8n 節點設定要點

1. **Supabase Get 操作**  
   - 單筆查詢用 **Get**（不是 Get Many）✅
   - 更直接，效能更好

2. **Merge 節點**  
   - Switch 分流後需啟用 **Include Any Unpaired Items**
   - 否則會顯示 "No output data returned"

3. **Postgres vs Supabase Node**  
   - **Supabase Node**: 基本 CRUD 操作
   - **Postgres Node**: 複雜 SQL（Upsert、CASE WHEN 等）
   - Upsert 必須用 Postgres Node ⭐

4. **Gemini API 版本**  
   - 最低支援: **gemini-2.5-flash**
   - ~~gemini-1.5-flash~~ 已不支援

### SQL 技巧

**Upsert 語法**:
```sql
INSERT INTO kana_progress (...)
VALUES (...)
ON CONFLICT (user_id, kana, kana_type)
DO UPDATE SET
  correct_count = kana_progress.correct_count + 1,
  ...
```

**動態間隔計算**:
```sql
CASE 
  WHEN correct_count = 0 THEN 1
  WHEN correct_count = 1 THEN 3
  WHEN correct_count = 2 THEN 7
  ...
END
```

### Code 節點技巧

**解析 JSON 字串**:
```javascript
let content;
try {
  content = JSON.parse(taskDetails.content);
} catch (e) {
  content = taskDetails.content;
}
```

**引用其他節點資料**:
```javascript
$('Query - Task Details').first().json
$('Webhook').item.json.body
$('Merge').first().json
```

---

## 🎯 最終節點清單（17 個）

| # | 節點名稱 | 類型 | Phase |
|---|---------|------|-------|
| 1 | Webhook | Webhook | 1 |
| 2 | Query - Task Details | Supabase | 2 |
| 3 | Switch - Submission Type | Switch | 3 |
| 4 | Code - Direct Confirm | Code | 3 |
| 5 | Gemini - Review Answer | AI Agent | 3 |
| 6 | Gemini - Review Answer Model | LLM Model | 3 |
| 7 | Code - Parse AI Response | Code | 3 |
| 8 | Merge | Merge | 4 |
| 9 | Postgres - Update Task | Postgres | 4 |
| 10 | Code - Prepare Data | Code | 5 |
| 11 | IF - Passed | IF | 5 |
| 12 | Postgres - Upsert Progress (Pass) | Postgres | 5 |
| 13 | Postgres - Update Progress (Fail) | Postgres | 5 |
| 14 | Merge - Progress Result | Merge | 6 |
| 15 | Postgres - Insert Submission | Postgres | 6 |
| 16 | Code - Format Response | Code | 6 |
| 17 | Respond to Webhook | Respond | 6 |

---

## 🎉 完成總結

**狀態**: ✅ **100% 完成**  
**總節點數**: 17 個  
**總開發時間**: ~3 小時（2 個會話）  
**測試狀態**: 全部通過

**核心功能**:
- ✅ 文字答案 AI 審核（Gemini 2.5 Flash）
- ✅ 直接確認通過
- ✅ 任務狀態更新
- ✅ 學習進度追蹤（間隔重複演算法）
- ✅ 提交記錄保存
- ✅ 錯誤計數追蹤

**下一步**: 
- Workflow 3: 測驗生成
- Workflow 4: 測驗批改

---

**最後更新**: 2026-01-24  
**Workflow JSON**: `review-submission.json` (已匯出)
