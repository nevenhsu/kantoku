# Workflow 3: 測驗生成 (generate-test) 開發進度

**狀態**: 🚀 啟動中
**目標**: 當使用者進度達到 10%, 20%... 時，自動生成階段性測驗。

---

## 📅 開發階段

### Phase 1: 基礎設置
- [ ] 建立 Webhook (`POST /webhook/generate-test`)
- [ ] 建立測試資料 (假造 Request Body)
- [ ] 驗證 Webhook 接收

### Phase 2: 資料查詢 (Read)
- [ ] 查詢是否已存在該階段測驗 (Postgres)
- [ ] IF: 測驗已存在且通過 → 直接回傳
- [ ] 查詢已學假名與單字 (Postgres)
  - 條件: `mastery_score >= 70` (或 `mastered`)
  - 限制: 隨機取 50 個候選項目

### Phase 3: AI 生成 (Google Gemini Chat Model)
- [ ] 設定 **Google Gemini Chat Model** 節點
- [ ] 設計 Prompt (生成 10 題 JSON 格式選擇題)
- [ ] 測試 AI 回應格式與穩定性
- [ ] Parse AI Response (Code Node)

### Phase 4: 資料寫入 (Write)
- [ ] 插入測驗記錄到 `tests` 表 (Postgres)
- [ ] 取得新建立的 `test_id`

### Phase 5: 回傳與測試
- [ ] 格式化回傳結果 (Code Node)
- [ ] Respond to Webhook
- [ ] 完整流程測試 (New Test -> Return New; Existing Test -> Return Existing)

---

## 🛠 技術筆記

### 1. Webhook Body
```json
{
  "user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35",
  "category": "hiragana",
  "progress_milestone": 10
}
```

### 2. 資料庫查詢
- **檢查測驗**: `SELECT id, passed, questions FROM tests WHERE ...`
- **查詢已學**: `SELECT kana, romaji FROM kana_progress WHERE ...`

### 3. Gemini Prompt
```text
你是日文測驗出題老師。請根據以下已學內容出 10 題選擇題...
(詳細規則待定)
```

---

## 🧪 測試記錄
(尚未開始)
