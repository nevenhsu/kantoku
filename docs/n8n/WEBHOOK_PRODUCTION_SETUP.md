# n8n Webhook 生產模式設置指南

**問題**: 目前 webhook 使用測試模式（`/webhook-test/`），需要手動點擊「監聽」才能呼叫  
**解決**: 切換到生產模式（`/webhook/`），隨時可以呼叫

---

## 📋 測試模式 vs 生產模式

### 測試模式 (`/webhook-test/`)

**URL 格式**:
```
http://neven.local:5678/webhook-test/generate-tasks
```

**特點**:
- ❌ 需要在 n8n UI 中手動點擊「監聽」
- ❌ 停止監聽後就無法呼叫
- ❌ workflow 未啟動時無法使用
- ✅ 適合開發測試
- ✅ 可以看到即時的執行結果

**用途**: 開發和調試 workflow

### 生產模式 (`/webhook/`)

**URL 格式**:
```
http://neven.local:5678/webhook/generate-tasks
```

**特點**:
- ✅ **隨時可以呼叫**（只要 workflow 啟動）
- ✅ 不需要手動監聽
- ✅ 背景執行，不影響 UI
- ✅ 適合生產環境
- ❌ 看不到即時執行過程（需查看執行歷史）

**用途**: iOS App 正式使用

---

## 🔧 如何啟用生產模式

### 方法 1: 在 n8n UI 中設置（推薦）

#### Step 1: 打開 Workflow

1. 訪問 n8n: `http://localhost:5678`
2. 登入（admin / kantoku2024）
3. 打開你的 workflow，例如：「Workflow 1: Generate Tasks」

#### Step 2: 啟動 Workflow

在右上角找到開關：

```
Inactive ⭕ → Active ✅
```

**點擊切換開關，將 workflow 啟動**

#### Step 3: 確認生產 Webhook URL

1. 點擊 Webhook 節點
2. 在右側面板找到「Production URL」
3. 應該顯示：
   ```
   http://neven.local:5678/webhook/generate-tasks
   ```

#### Step 4: 測試生產 Webhook

```bash
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-123",
    "daily_goal_minutes": 30
  }'
```

如果返回結果，代表成功！

---

## 📝 需要啟動的 Workflows

根據你的 iOS App 配置，需要啟動以下 workflows：

### 1. Workflow 1: Generate Tasks ✅

**Webhook Path**: `generate-tasks`

**生產 URL**:
```
http://neven.local:5678/webhook/generate-tasks
```

**用途**: 生成每日學習任務

**需要啟動**: ✅ 是

### 2. Workflow 2: Review Submission ✅

**Webhook Path**: `review-submission`

**生產 URL**:
```
http://neven.local:5678/webhook/review-submission
```

**用途**: AI 審核用戶提交

**需要啟動**: ✅ 是

### 3. Workflow 3: Generate Test

**Webhook Path**: `generate-test`

**生產 URL**:
```
http://neven.local:5678/webhook/generate-test
```

**用途**: 生成階段性測驗

**需要啟動**: ⏳ 待開發（Phase 7）

### 4. Workflow 4: Grade Test

**Webhook Path**: `grade-test`

**生產 URL**:
```
http://neven.local:5678/webhook/grade-test
```

**用途**: 批改測驗

**需要啟動**: ⏳ 待開發（Phase 7）

---

## 🚀 快速設置清單

### 立即需要做的（Phase 5 完成）

- [ ] 打開 n8n UI (`http://localhost:5678`)
- [ ] 啟動「Workflow 1: Generate Tasks」（切換為 Active）
- [ ] 啟動「Workflow 2: Review Submission」（切換為 Active）
- [ ] 測試生產 webhook（見下方測試指令）
- [ ] 更新 iOS App 配置（如果有使用 `/webhook-test/`）

### 未來需要做的（Phase 7）

- [ ] 啟動「Workflow 3: Generate Test」
- [ ] 啟動「Workflow 4: Grade Test」

---

## 🧪 測試指令

### 測試 Workflow 1: Generate Tasks

```bash
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "daily_goal_minutes": 30
  }'
```

**預期回應**:
```json
{
  "tasks": [
    {
      "id": "...",
      "task_type": "kana_learn",
      "content": {...}
    }
  ]
}
```

### 測試 Workflow 2: Review Submission

```bash
curl -X POST http://neven.local:5678/webhook/review-submission \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "550e8400-e29b-41d4-a716-446655440001",
    "submission_type": "text",
    "content": "あ"
  }'
```

**預期回應**:
```json
{
  "success": true,
  "feedback": {...}
}
```

---

## 🔍 如何檢查 Workflow 是否啟動

### 方法 1: n8n UI

1. 打開 n8n
2. 查看 Workflows 列表
3. 確認狀態：
   ```
   ✅ Active   → 已啟動，生產 webhook 可用
   ⭕ Inactive → 未啟動，只能用測試 webhook
   ```

### 方法 2: 直接呼叫 Production Webhook

```bash
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","daily_goal_minutes":30}'
```

**成功**: 返回 JSON 結果  
**失敗**: 返回 404 或無回應 → workflow 未啟動

---

## ⚙️ iOS App 配置

### 確認 APIService 使用正確的 URL

**文件**: `ios/kantoku/Services/APIService.swift`

**正確的配置**:
```swift
enum API {
    static let generateTasks = "/webhook/generate-tasks"      // ✅ 生產
    static let reviewSubmission = "/webhook/review-submission" // ✅ 生產
    static let generateTest = "/webhook/generate-test"         // ✅ 生產
    static let gradeTest = "/webhook/grade-test"               // ✅ 生產
}
```

**錯誤的配置**:
```swift
// ❌ 不要用測試 URL
static let generateTasks = "/webhook-test/generate-tasks"
```

### 檢查 Constants.swift

**文件**: `ios/kantoku/Utils/Constants.swift`

**確認**:
```swift
enum API {
    static let generateTasks = "/webhook/generate-tasks"
    static let reviewSubmission = "/webhook/review-submission"
    static let generateTest = "/webhook/generate-test"
    static let gradeTest = "/webhook/grade-test"
}
```

---

## 🛠️ 故障排除

### 問題 1: 呼叫 webhook 返回 404

**原因**: Workflow 未啟動

**解決**:
1. 打開 n8n UI
2. 找到對應的 workflow
3. 點擊右上角切換開關（Inactive → Active）

### 問題 2: Workflow 啟動但還是 404

**原因**: Webhook path 配置錯誤

**檢查**:
1. 在 n8n 中打開 Webhook 節點
2. 確認「Path」設定：
   - Generate Tasks: `generate-tasks`
   - Review Submission: `review-submission`
3. 確認沒有多餘的斜線（`/`）

### 問題 3: 呼叫成功但沒有結果

**原因**: Workflow 執行失敗

**檢查**:
1. n8n UI → 「Executions」（執行歷史）
2. 查看最近的執行記錄
3. 檢查錯誤訊息

**常見錯誤**:
- Supabase 認證失敗 → 檢查 credentials
- Gemini API 錯誤 → 檢查 API key
- 資料格式錯誤 → 檢查傳入的 JSON

### 問題 4: iOS App 還是呼叫不到

**檢查清單**:
- [ ] n8n 正在運行（`docker ps | grep n8n`）
- [ ] Workflow 已啟動（n8n UI 顯示 Active）
- [ ] iOS App 使用正確的 URL（`/webhook/` 不是 `/webhook-test/`）
- [ ] Mac 和模擬器可以連接（`./test-n8n-connection.sh`）

---

## 📊 URL 對照表

| Workflow | 測試 URL | 生產 URL | 狀態 |
|----------|---------|---------|------|
| **Generate Tasks** | `/webhook-test/generate-tasks` | `/webhook/generate-tasks` | ✅ 需要啟動 |
| **Review Submission** | `/webhook-test/review-submission` | `/webhook/review-submission` | ✅ 需要啟動 |
| **Generate Test** | `/webhook-test/generate-test` | `/webhook/generate-test` | ⏳ 待開發 |
| **Grade Test** | `/webhook-test/grade-test` | `/webhook/grade-test` | ⏳ 待開發 |

---

## 🔐 安全性考量

### 生產環境建議

目前在本地開發，不需要特別的安全措施。但未來部署到雲端時：

1. **添加認證**:
   ```javascript
   // 在 workflow 中驗證請求
   if ($json.headers['authorization'] !== 'Bearer YOUR_SECRET_KEY') {
     return { error: 'Unauthorized' };
   }
   ```

2. **限制 IP 白名單**:
   - 只允許 iOS App 的 IP 訪問

3. **使用 HTTPS**:
   - 正式環境必須使用 HTTPS

4. **Rate Limiting**:
   - 防止 API 濫用

---

## 💡 最佳實踐

### ✅ DO

1. **開發時用測試 webhook**:
   - 方便調試和查看執行過程

2. **部署後用生產 webhook**:
   - iOS App 使用生產 URL
   - 確保 workflow 已啟動

3. **定期檢查執行歷史**:
   - n8n UI → Executions
   - 監控錯誤和性能

4. **保持 workflow 簡潔**:
   - 添加錯誤處理
   - 記錄關鍵步驟

### ❌ DON'T

1. **不要在生產環境使用測試 URL**:
   - iOS App 不應該用 `/webhook-test/`

2. **不要忘記啟動 workflow**:
   - 啟動後才能使用生產 webhook

3. **不要在 workflow 中硬編碼敏感資訊**:
   - 使用 n8n credentials 管理

---

## 🚀 一鍵啟動腳本

創建 `activate-workflows.sh`：

```bash
#!/bin/bash

echo "🚀 啟動 n8n Workflows..."
echo ""

echo "請在 n8n UI 中手動啟動以下 workflows："
echo ""
echo "1. Workflow 1: Generate Tasks"
echo "   URL: http://localhost:5678"
echo "   操作: 點擊右上角開關（Inactive → Active）"
echo ""
echo "2. Workflow 2: Review Submission"
echo "   URL: http://localhost:5678"
echo "   操作: 點擊右上角開關（Inactive → Active）"
echo ""
echo "啟動完成後，執行測試："
echo ""
echo "curl -X POST http://neven.local:5678/webhook/generate-tasks \\"
echo "  -H 'Content-Type: application/json' \\"
echo "  -d '{\"user_id\":\"test\",\"daily_goal_minutes\":30}'"
echo ""
```

---

## ✅ 完成檢查清單

啟動生產 webhooks 前：

- [ ] n8n 正在運行（`docker-compose up -d`）
- [ ] 可以訪問 n8n UI（`http://localhost:5678`）
- [ ] Supabase credentials 已配置
- [ ] Gemini API key 已配置

啟動 workflows：

- [ ] 「Workflow 1: Generate Tasks」已啟動（Active ✅）
- [ ] 「Workflow 2: Review Submission」已啟動（Active ✅）
- [ ] 測試生產 webhooks（使用上方的 curl 指令）

iOS App 配置：

- [ ] API endpoints 使用 `/webhook/` 而不是 `/webhook-test/`
- [ ] 已測試從 iOS App 呼叫 webhooks
- [ ] ConnectionTestService 測試通過

---

## 📚 相關文檔

- [WORKFLOW_DESIGN.md](../../n8n-workflows/WORKFLOW_DESIGN.md) - Workflow 設計文件
- [HOSTNAME_SETUP.md](../HOSTNAME_SETUP.md) - Hostname 設置
- [MULTI_ENVIRONMENT_SETUP.md](../ios/MULTI_ENVIRONMENT_SETUP.md) - 多環境配置

---

**最後更新**: 2026-01-29

**下一步**: 在 n8n UI 中啟動 workflows，讓 iOS App 可以直接呼叫！
