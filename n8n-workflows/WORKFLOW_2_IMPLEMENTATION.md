# Workflow 2: 提交審核（review-submission）實作紀錄

**實作日期**: 2026-01-24  
**狀態**: ✅ 已完成並測試通過  
**實作時間**: ~3 小時

---

## 基本資訊

| 項目 | 內容 |
|-----|------|
| **Workflow 名稱** | review-submission |
| **Webhook Path** | `/webhook/review-submission` |
| **HTTP Method** | POST |
| **節點數量** | 17 個 |
| **測試使用者** | `ebc3cd0d-dc42-42c1-920a-87328627fe35` |

---

## 完整節點列表

```
[Webhook] 
    ↓
[Query Task] (Postgres)
    ↓
[Switch: submission_type] (Switch)
    ├─ direct_confirm → [Code: Direct Confirm] ─┐
    └─ text → [Gemini AI Review] → [Parse AI]  ─┤
                                                  ↓
                                              [Merge] (Merge)
                                                  ↓
                                    [Postgres: Update Task Status] (Postgres)
                                                  ↓
                                    [Code: Prepare Data] (Code)
                                                  ↓
                                         [IF: Passed?] (IF)
                                    ├─ true → [Postgres: Upsert Progress] (Postgres)
                                    └─ false → [Postgres: Update Progress] (Postgres)
                                                  ↓
                                         [Merge Progress Result] (Merge)
                                                  ↓
                                    [Postgres: Insert Submission] (Postgres)
                                                  ↓
                                    [Code: Format Response] (Code)
                                                  ↓
                                    [Respond to Webhook]
```

---

## 關鍵技術細節

### 1. Supabase Node vs Postgres Node
- **發現**: n8n 的 Supabase Node 不支援 `UPSERT` (Insert on conflict update) 操作。
- **解決方案**: 對於 `kana_progress` 和 `vocabulary_progress` 的更新，改用 **Postgres Node** 執行原生 SQL。
- **SQL 範例**:
  ```sql
  INSERT INTO kana_progress (user_id, kana, kana_type, status, correct_count, last_reviewed, next_review, mastery_score)
  VALUES ($1, $2, $3, $4, 1, NOW(), NOW() + INTERVAL '1 day', 20)
  ON CONFLICT (user_id, kana, kana_type)
  DO UPDATE SET
    correct_count = kana_progress.correct_count + 1,
    last_reviewed = NOW(),
    next_review = NOW() + INTERVAL '1 day' * CASE ... END,
    mastery_score = LEAST(100, (kana_progress.correct_count + 1) * 20),
    updated_at = NOW();
  ```

### 2. Switch 分支合併
- **挑戰**: Switch 節點分流後，資料流變為兩條獨立路徑，需要合併才能繼續後續的資料庫寫入。
- **解決方案**: 使用 **Merge Node**，並將 `Mode` 設定為 **"Append"**。
- **關鍵設定**: 必須開啟 **"Include Any Unpaired Items"**，確保無論走哪條分支，資料都能順利傳遞到下游。

### 3. 間隔重複演算法 (Spaced Repetition)
- **邏輯**: 根據 `correct_count` 計算下一次複習時間。
- **間隔**:
  - 初次正確 (0→1): +1 天
  - 1 次正確 (1→2): +3 天
  - 2 次正確 (2→3): +7 天
  - 3 次正確 (3→4): +14 天
  - 4 次以上: +30 天

### 4. AI 審核
- **模型**: Google Gemini 1.5 Flash (gemini-2.5-flash)
- **Prompt**:
  > 你是日文學習審核 AI。請審核以下答案是否正確...
  > 請以 JSON 格式回答：{ "passed": boolean, "score": number, "feedback": string, "correct_answer": string }

---

## 測試記錄

### 測試環境
- **n8n URL**: `http://localhost:5678`
- **測試模式 URL**: `http://localhost:5678/webhook-test/review-submission`

### 測試案例 1: 文字輸入 - 正確答案
- **輸入**: `{"task_id": "...", "submission_type": "text", "content": "a"}` (題目: あ)
- **結果**:
  - `passed`: `true`
  - `score`: `100`
  - `kana_progress`: `correct_count` 增加，`next_review` 更新為 1 天後。
  - `tasks`: status 更新為 `passed`。

### 測試案例 2: 文字輸入 - 錯誤答案
- **輸入**: `{"task_id": "...", "submission_type": "text", "content": "ka"}` (題目: あ)
- **結果**:
  - `passed`: `false`
  - `score`: `0`
  - `feedback`: 指出錯誤並提供正確答案。
  - `kana_progress`: `incorrect_count` 增加。
  - `tasks`: status 更新為 `failed`。

### 測試案例 3: 直接確認
- **輸入**: `{"submission_type": "direct_confirm"}`
- **結果**:
  - `passed`: `true`
  - `score`: `100`
  - 直接通過，不經過 AI 審核。

---

## 下一步

1. **開發 Workflow 3: 測驗生成 (generate-test)**
   - 監聽進度里程碑 (10%, 20%...)
   - 生成 10 題測驗題

2. **開發 Workflow 4: 測驗批改 (grade-test)**
   - 批改測驗卷
   - 計算分數與識別弱項

---

**參考文件**:
- [WORKFLOW_DESIGN.md](./WORKFLOW_DESIGN.md)
- [PLAN.md](../PLAN.md)
