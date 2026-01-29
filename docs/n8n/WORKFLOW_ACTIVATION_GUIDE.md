# n8n Workflow 啟動指南

**問題**: generate-tasks webhook 返回原始請求數據而不是任務列表  
**原因**: Workflow 未啟動或執行出錯  
**解決**: 啟動 workflow 並檢查執行狀態

---

## ❌ 當前錯誤

### iOS 測試顯示

```
❌ generate-tasks webhook
   Workflow 未正確執行
   0.07s
   詳細資訊: 收到原始請求數據而不是任務列表
```

### curl 測試返回

```json
[{
  "headers": {...},
  "params": {},
  "query": {},
  "body": {
    "user_id": "...",
    "daily_goal_minutes": 30
  },
  "webhookUrl": "http://localhost:5678/webhook/generate-tasks",
  "executionMode": "production"
}]
```

**這是 n8n 的預設回應**，表示 webhook 收到請求但 workflow 沒有正確執行。

---

## ✅ 解決步驟

### Step 1: 打開 n8n UI

```bash
# 在瀏覽器打開
http://localhost:5678

# 登入
用戶名: admin
密碼: kantoku2024
```

### Step 2: 檢查 Workflow 狀態

1. 在左側選單點擊 "Workflows"
2. 找到 "Workflow 1: Generate Tasks"
3. 查看右上角的開關狀態：

```
⭕ Inactive  →  需要啟動！
✅ Active    →  已啟動，檢查執行錯誤
```

### Step 3: 啟動 Workflow

**如果狀態是 Inactive**:

1. 點擊右上角的開關
2. 從 `⭕ Inactive` 切換到 `✅ Active`
3. 應該看到提示 "Workflow activated"

**重要**: 
- 必須啟動 workflow，生產 webhook 才能工作
- 測試 webhook (`/webhook-test/`) 不需要啟動
- 生產 webhook (`/webhook/`) 需要 workflow Active

### Step 4: 測試 Webhook

在終端機執行：

```bash
curl -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "daily_goal_minutes": 30
  }'
```

**成功的回應** (應該看到任務列表):

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

**失敗的回應** (還是原始數據):

```json
[{
  "headers": {...},
  "body": {...}
}]
```

→ 如果還是失敗，繼續 Step 5

### Step 5: 檢查執行歷史（如果還是失敗）

1. **n8n UI** → 左側選單 → **"Executions"**
2. 查看最近的執行記錄
3. 找到剛才的 webhook 呼叫

**可能的狀態**:

#### A. 沒有執行記錄
→ Workflow 沒有啟動，回到 Step 3

#### B. 執行失敗 (紅色 ❌)
點擊查看錯誤訊息，常見錯誤：

**錯誤 1: Supabase 連接失敗**
```
Error: Invalid Supabase credentials
```
**解決**: 檢查 n8n credentials → Supabase account → 確認 URL 和 key

**錯誤 2: Gemini AI 錯誤**
```
Error: Invalid API key
```
**解決**: 檢查 n8n credentials → Gemini API → 確認 API key

**錯誤 3: 資料庫查詢錯誤**
```
Error: relation "user_progress" does not exist
```
**解決**: 檢查 Supabase 資料庫 schema 是否完整

#### C. 執行成功但回應錯誤 (綠色 ✅ 但結果不對)
→ Workflow 邏輯問題，檢查 "Respond to Webhook" 節點

---

## 🔍 深入排查

### 檢查 Workflow 配置

1. **打開 Workflow**:
   - Workflows → "Workflow 1: Generate Tasks" → Edit

2. **檢查 Webhook 節點**:
   - 點擊第一個節點 "Webhook"
   - 確認設定：
     ```
     HTTP Method: POST
     Path: generate-tasks
     Response Mode: Using 'Respond to Webhook' Node
     ```

3. **檢查 Respond to Webhook 節點**:
   - 滾動到最後一個節點 "Respond to Webhook"
   - 確認設定：
     ```
     Respond With: All Incoming Items
     或
     Respond With: Using Fields Below (配置 tasks 欄位)
     ```

4. **測試執行**:
   - 點擊 "Test workflow"
   - 點擊 "Listen for Test Event"
   - 在另一個終端執行 curl 測試
   - 查看每個節點的輸出

### 檢查 Credentials

1. **n8n UI** → 左側選單 → **"Credentials"**

2. **Supabase account**:
   ```
   Host: pthqgzpmsgsyssdatxnm.supabase.co
   Service Role Secret: eyJhbGci... (service_role key)
   ```

3. **Gemini API**:
   ```
   API Key: AIzaSyA-... (你的 Gemini API key)
   ```

### 手動測試每個步驟

在 Workflow 編輯模式：

1. 點擊 "Execute Workflow"
2. 輸入測試數據：
   ```json
   {
     "user_id": "550e8400-e29b-41d4-a716-446655440000",
     "daily_goal_minutes": 30
   }
   ```
3. 查看每個節點的輸出
4. 找出哪個節點失敗

---

## 📊 Workflow 啟動檢查清單

### 必須完成的設定

- [ ] n8n 容器運行中 (`docker ps | grep n8n`)
- [ ] n8n UI 可訪問 (`http://localhost:5678`)
- [ ] Workflow 存在（"Workflow 1: Generate Tasks"）
- [ ] Workflow 已啟動（右上角 `✅ Active`）
- [ ] Supabase credentials 已配置
- [ ] Gemini API credentials 已配置
- [ ] Supabase 資料庫 tables 已創建
- [ ] learning_stages 表有數據

### 測試驗證

- [ ] curl 測試返回 `{"tasks": [...]}`
- [ ] iOS App 測試顯示 "✅ generate-tasks webhook"
- [ ] n8n Executions 顯示成功執行

---

## 🛠️ 快速修復腳本

### 重啟 n8n

```bash
cd ~/Documents/projects/kantoku
docker-compose restart n8n

# 等待 n8n 啟動（約 10 秒）
sleep 10

# 測試
curl http://localhost:5678
```

### 檢查 Workflow 狀態

```bash
# 方法 1: 通過 UI
open http://localhost:5678

# 方法 2: 通過 API (需要 API key)
# curl http://localhost:5678/api/v1/workflows \
#   -H "X-N8N-API-KEY: your-api-key"
```

### 測試完整流程

```bash
#!/bin/bash

echo "🧪 測試 generate-tasks workflow..."

RESPONSE=$(curl -s -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "daily_goal_minutes": 30
  }')

echo "回應:"
echo "$RESPONSE" | jq .

# 檢查是否包含 "tasks" 欄位
if echo "$RESPONSE" | grep -q '"tasks"'; then
    echo "✅ Workflow 正常工作！"
else
    echo "❌ Workflow 未正確執行"
    echo "請檢查："
    echo "1. n8n UI → Workflows → 確認 Active"
    echo "2. n8n UI → Executions → 查看錯誤"
fi
```

---

## 📚 相關資源

### n8n 官方文檔
- [Webhook Node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/)
- [Production Webhooks](https://docs.n8n.io/hosting/configuration/environment-variables/#webhook-url)
- [Troubleshooting](https://docs.n8n.io/hosting/troubleshooting/)

### Kantoku 文檔
- [WEBHOOK_PRODUCTION_SETUP.md](./WEBHOOK_PRODUCTION_SETUP.md) - Webhook 設置
- [WORKFLOW_DESIGN.md](../../n8n-workflows/WORKFLOW_DESIGN.md) - Workflow 設計
- [QUICK_START.md](../../QUICK_START.md) - 快速開始

---

## 💡 常見問題

### Q: 為什麼測試 webhook 可以用，生產 webhook 不行？

**A**: 
- 測試 webhook (`/webhook-test/`) 不需要 workflow active
- 生產 webhook (`/webhook/`) 需要 workflow active
- 測試時手動點擊 "Listen"，生產時自動監聽

### Q: Workflow 顯示 Active 但還是不工作？

**A**: 
1. 檢查 Executions 是否有錯誤
2. 可能是 credentials 失效
3. 可能是資料庫 schema 不匹配
4. 嘗試重新保存並啟動 workflow

### Q: 怎麼知道 workflow 是否正在執行？

**A**:
- n8n UI → Executions → 查看最近執行
- 執行中：藍色轉圈
- 成功：綠色 ✅
- 失敗：紅色 ❌

---

## ✅ 成功標準

當以下都顯示成功，表示配置完成：

```
✅ n8n 容器運行
✅ Workflow Active
✅ curl 測試返回任務列表
✅ iOS App 測試通過
✅ n8n Executions 沒有錯誤
```

---

**下一步**: 啟動 workflow 後，重新運行 iOS App 測試！

**最後更新**: 2026-01-29
