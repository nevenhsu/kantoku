# Kantoku 快速啟動指南

**目標**: 3 分鐘內啟動開發環境並開始測試

---

## 🚀 3 步驟啟動

### Step 1: 啟動 n8n (30 秒)

```bash
cd ~/Documents/projects/kantoku
docker-compose up -d
```

**確認**:
```bash
docker ps | grep n8n
# 應該看到 kantoku-n8n running
```

### Step 2: 啟動 n8n Workflows (1 分鐘)

1. **打開 n8n UI**:
   - 瀏覽器訪問: `http://localhost:5678`
   - 登入: `admin` / `kantoku2024`

2. **啟動 Workflows**（重要！）:
   
   **Workflow 1: Generate Tasks**
   - 找到「Workflow 1: Generate Tasks」
   - 點擊右上角開關：`Inactive ⭕` → `Active ✅`
   
   **Workflow 2: Review Submission**
   - 找到「Workflow 2: Review Submission」
   - 點擊右上角開關：`Inactive ⭕` → `Active ✅`

**為什麼要啟動？**
- ❌ 未啟動：只能用 `/webhook-test/`（需手動監聽）
- ✅ 已啟動：可以用 `/webhook/`（隨時呼叫）← iOS App 需要這個

### Step 3: 測試連接 (30 秒)

```bash
# 測試 n8n 連接
./test-n8n-connection.sh

# 測試 workflow
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","daily_goal_minutes":30}'
```

**成功**: 返回 JSON 任務列表  
**失敗**: 返回 404 → Workflow 未啟動（回到 Step 2）

---

## 📱 iOS App 測試 (1 分鐘)

```bash
# 打開 Xcode
open ios/kantoku.xcodeproj

# 運行（Cmd + R）
# 點擊「開始測試」
```

**預期結果**:
```
✅ 7 / 7 項測試通過
✅ Supabase 基礎連接
✅ Supabase Auth
✅ Supabase Database
✅ Supabase Storage
✅ n8n 基礎連接
✅ generate-tasks webhook
✅ review-submission webhook
```

---

## ⚠️ 常見問題

### Q1: n8n webhook 測試失敗（❌）

**原因**: Workflow 未啟動

**解決**:
1. 打開 `http://localhost:5678`
2. 確認 workflows 右上角顯示 `Active ✅`
3. 如果顯示 `Inactive ⭕`，點擊切換為 Active

### Q2: Supabase Storage 測試失敗

**原因**: Storage policies 未配置

**解決**:
```bash
# 在 Supabase SQL Editor 執行
# 見 docs/Supabase/storage_policies.sql
```

### Q3: iOS 模擬器無法連接 n8n

**原因**: 使用了 `localhost` 而不是 `neven.local`

**檢查**:
```bash
# 查看配置
cat ios/kantoku/Resources/Config.local.xcconfig
# 應該是: N8N_BASE_URL = http://$()/neven.local:5678
```

---

## 🎯 檢查清單

**環境準備**:
- [ ] Docker 已安裝並運行
- [ ] Xcode 已安裝
- [ ] 網路連接正常

**啟動檢查**:
- [ ] n8n 容器運行中（`docker ps`）
- [ ] Workflow 1 已啟動（Active ✅）
- [ ] Workflow 2 已啟動（Active ✅）
- [ ] 測試腳本通過（`./test-n8n-connection.sh`）

**iOS App 檢查**:
- [ ] 可以 Build（`Cmd + B`）
- [ ] 可以 Run（`Cmd + R`）
- [ ] 連接測試全部通過（7/7）

---

## 📊 系統架構

```
iOS App (neven.local:5678)
    ↓
n8n Workflows (Active)
    ├── /webhook/generate-tasks → Gemini AI → Supabase
    └── /webhook/review-submission → Gemini AI → Supabase
    ↓
Supabase (Cloud)
    ├── Database (tasks, submissions, etc.)
    └── Storage (submissions bucket)
```

---

## 📚 詳細文檔

- **n8n Webhooks**: [docs/n8n/WEBHOOK_PRODUCTION_SETUP.md](docs/n8n/WEBHOOK_PRODUCTION_SETUP.md)
- **環境配置**: [docs/ENVIRONMENT_COMPLETE.md](docs/ENVIRONMENT_COMPLETE.md)
- **Hostname 設置**: [docs/HOSTNAME_SETUP.md](docs/HOSTNAME_SETUP.md)
- **Storage 配置**: [docs/Supabase/STORAGE_SETUP.md](docs/Supabase/STORAGE_SETUP.md)
- **測試指南**: [docs/ios/TESTING_GUIDE.md](docs/ios/TESTING_GUIDE.md)

---

## 💡 開發流程

### 每天開始開發

```bash
# 1. 啟動 n8n
docker-compose up -d

# 2. 測試連接
./test-n8n-connection.sh

# 3. 打開 Xcode
open ios/kantoku.xcodeproj
```

### 修改 n8n Workflow

1. 在 n8n UI 中編輯 workflow
2. 保存後**自動生效**（如果是 Active 狀態）
3. 在 iOS App 中測試

### 關閉開發環境

```bash
# 停止 n8n（保留數據）
docker-compose stop

# 或完全關閉（刪除容器）
docker-compose down
```

---

## 🔧 快速指令

```bash
# 查看 n8n 日誌
docker-compose logs -f n8n

# 重啟 n8n
docker-compose restart n8n

# 測試 webhook
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","daily_goal_minutes":30}'

# iOS Clean Build
# 在 Xcode: Cmd + Shift + K

# 查看 Mac IP
ipconfig getifaddr en0
```

---

**準備好了嗎？開始開發吧！** 🚀

---

**最後更新**: 2026-01-29
