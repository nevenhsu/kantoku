# n8n Workflows 最佳實踐

**Last Updated**: 2026-01-24

本文件記錄在開發 Kantoku n8n workflows 過程中學到的重要經驗與注意事項。

---

## ⚠️ 重要注意事項

### 1. Google Gemini Chat Model 節點使用

**✅ 正確做法**:
始終使用 n8n 內建的 **Google Gemini Chat Model** 節點。這比使用 HTTP Request 節點更安全且更易於維護，因為它能直接整合 n8n 的 Credentials 系統。

**設定要點**:
- **Node 類型**: `Google Gemini Chat Model`
- **Credentials**: 使用 `Google Gemini` 類型的憑證（只需填入 API Key）。
- **Model**: 使用 `gemini-2.5-flash`。

**❌ 錯誤做法**:
- 使用 **HTTP Request** 節點手動呼叫 Google AI API。
- 在 Workflow 中硬編碼 (Hardcode) API Key。
- 使用已過時的模型版本（如 `gemini-1.5-flash`）。

**原因**: 內建節點提供更好的錯誤處理、重試機制，並且不需要手動處理 API 端點 (Endpoints) 與複雜的 JSON 結構格式。

**影響範圍**:
- Workflow 1: generate-tasks
- Workflow 2: review-submission
- Workflow 3: test-environment (如有使用 AI)

**更新方法**:
1. 開啟 workflow JSON 檔案
2. 改用 Google Gemini Chat Model Node：替換 Gemini 1.5/2.5 的呼叫方式為 Node 形式
3. 將相關引用的 API Key 放入 n8n Credentials，避免硬編碼

---

### 2. Merge Node 設定

**✅ 正確做法**:
```
Mode: Combine
Options:
  ☑ Include Any Unpaired Items
```

**❌ 錯誤做法**:
```
Options:
  ☐ Include Any Unpaired Items  # 未啟用會導致資料遺失
```

**原因**: 
- 若不啟用此選項，當兩個分支數據量不同時，未配對的項目會被丟棄
- 例如：分支 A 有 5 筆，分支 B 有 3 筆 → 只會保留 3 筆

**影響範圍**:
- 所有使用 Merge Node 的 workflows
- 特別是合併用戶進度與任務資料時

**檢查方法**:
1. 打開 Merge Node 設定
2. 點擊 "Options"
3. 確認 "Include Any Unpaired Items" 已勾選

---

### 3. Postgres vs Supabase Node

**使用原則**:

| 場景 | 使用 Node | 原因 |
|------|-----------|------|
| 簡單 SELECT/INSERT | Supabase Node | 方便、內建 Auth |
| 複雜 JOIN 查詢 | Postgres Node | 支援完整 SQL 語法 |
| 多表關聯查詢 | Postgres Node | 更好的效能與彈性 |
| 需要 RLS 檢查 | Supabase Node | 自動套用 Row Level Security |

**範例**:

✅ **Postgres Node** 適合:
```sql
-- 複雜 JOIN 與子查詢
SELECT t.*, COUNT(ts.*) as submission_count
FROM tasks t
LEFT JOIN task_submissions ts ON t.id = ts.task_id
WHERE t.user_id = $1
GROUP BY t.id
ORDER BY t.created_at DESC
LIMIT 10
```

✅ **Supabase Node** 適合:
```javascript
// 簡單查詢
table: "tasks"
operation: "Get Many"
filters: { user_id: {{ $json.user_id }} }
```

---

## 🔧 常見陷阱

### 1. Webhook 測試時記得開啟 Workflow
- ❌ Workflow 關閉狀態下測試 → 404 錯誤
- ✅ 先點擊 "Active" 開關 → 再發送請求

### 2. JSON 格式錯誤
- ❌ 單引號: `{ 'user_id': '123' }`
- ✅ 雙引號: `{ "user_id": "123" }`

### 3. 環境變數未設定
確保已在 n8n 設定中配置:
- Supabase Credentials (Postgres)
- Gemini AI API Key
- 各 Workflow 的 Webhook 路徑

---

## 📚 參考文件

- [WORKFLOW_DESIGN.md](./WORKFLOW_DESIGN.md) - 完整設計文件
- [WORKFLOW_1_IMPLEMENTATION.md](./WORKFLOW_1_IMPLEMENTATION.md) - Workflow 1 實作
- [WORKFLOW_2_IMPLEMENTATION.md](./WORKFLOW_2_IMPLEMENTATION.md) - Workflow 2 實作
- [WORKFLOW_3_PROGRESS.md](./WORKFLOW_3_PROGRESS.md) - Workflow 3 進度

---

## 🔄 版本歷史

| 日期 | 更新內容 |
|------|----------|
| 2026-01-24 | 初始版本：記錄 Gemini API、Merge Node、Postgres vs Supabase 經驗 |
