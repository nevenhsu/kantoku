# Kantoku 環境準備指南

本指南協助您完成 Kantoku 專案所需的環境設定。

---

## ✅ 檢查清單

- [x] Docker Desktop 已安裝
- [x] n8n 已啟動
- [ ] Xcode 已安裝
- [ ] Supabase 專案已建立
- [ ] Gemini API Key 已取得

---

## 1️⃣ 安裝 Xcode

### 方法 1: App Store（推薦）

1. 打開 **App Store**
2. 搜尋 **Xcode**
3. 點擊 **取得/安裝**（約 10-15 GB，需時 30-60 分鐘）
4. 安裝完成後，打開 Xcode
5. 接受授權條款
6. 安裝額外元件（Command Line Tools）

### 方法 2: 直接下載

1. 前往 https://developer.apple.com/xcode/
2. 下載 Xcode 15+
3. 拖曳到 Applications 資料夾

### 驗證安裝

```bash
xcode-select --version
xcode-select -p
```

**預期輸出**:
```
xcode-select version 2396.
/Applications/Xcode.app/Contents/Developer
```

---

## 2️⃣ 建立 Supabase 專案

### 步驟 1: 註冊/登入 Supabase

1. 前往 https://supabase.com
2. 點擊 **Start your project**
3. 使用 GitHub 或 Email 註冊/登入

### 步驟 2: 建立新專案

1. 點擊 **New Project**
2. 填寫專案資訊：
   - **Name**: `kantoku`
   - **Database Password**: 設定一個強密碼（記下來！）
   - **Region**: 選擇 `Northeast Asia (Tokyo)` 或 `Southeast Asia (Singapore)`
   - **Pricing Plan**: Free（適合開發）
3. 點擊 **Create new project**（約需 1-2 分鐘）

### 步驟 3: 取得 API Keys

專案建立完成後，前往 **Settings** → **API**：

1. **Project URL**: `https://xxxxxx.supabase.co`
2. **anon public key**: `eyJhbGc...`（用於前端）
3. **service_role key**: `eyJhbGc...`（用於 n8n，僅後端使用）

**⚠️ 注意**: `service_role key` 具有完整權限，切勿暴露在前端！

### 步驟 4: 執行資料庫 Schema

1. 前往 **SQL Editor**（左側選單）
2. 點擊 **New query**
3. 複製 `supabase/schema.sql` 的內容
4. 貼上並點擊 **Run**
5. 確認所有表格建立成功

**驗證**:
- 前往 **Table Editor**
- 應該看到以下表格：
  - `profiles`
  - `learning_stages`
  - `kana_progress`
  - `vocabulary`
  - `vocabulary_progress`
  - `user_progress`
  - `learning_stats`
  - `tasks`
  - `submissions`
  - `tests`
  - `external_resources`

### 步驟 5: 設定 Storage（選用，音訊功能時需要）

1. 前往 **Storage**
2. 點擊 **Create a new bucket**
3. **Name**: `audio-submissions`
4. **Public bucket**: 否
5. 設定 Policy（允許使用者上傳自己的音訊）

---

## 3️⃣ 取得 Gemini API Key

### 步驟 1: 前往 Google AI Studio

1. 前往 https://aistudio.google.com
2. 使用 Google 帳號登入

### 步驟 2: 建立 API Key

1. 點擊 **Get API key**
2. 選擇 **Create API key in new project**
3. 複製 API Key（格式：`AIzaSy...`）

### 步驟 3: 測試 API Key

```bash
curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{
      "parts": [{"text": "Hello"}]
    }]
  }'
```

**預期輸出**: JSON 回應包含 AI 生成的文字

---

## 4️⃣ 設定 n8n Credentials

### 步驟 1: 登入 n8n

1. 確保 n8n 正在運行：
```bash
cd /Users/neven/Documents/projects/kantoku
docker-compose ps
```

2. 前往 http://localhost:5678
3. 帳號: `admin`，密碼: `kantoku2024`

### 步驟 2: 新增 Supabase Credentials

1. 點擊右上角 **Settings** → **Credentials**
2. 點擊 **Add Credential**
3. 搜尋並選擇 **HTTP Request**（用於 Supabase REST API）

**設定 Credential: Supabase REST API**
- **Credential Name**: `Supabase - Kantoku`
- **Authentication**: `Generic Credential Type`
- **Generic Auth Type**: `Header Auth`
- **Name**: `apikey`
- **Value**: `[您的 Supabase anon key]`

**新增第二個 Header**（點擊 Add Field → Header）:
- **Name**: `Authorization`
- **Value**: `Bearer [您的 Supabase service_role key]`

點擊 **Save**

### 步驟 3: 新增 Gemini AI Credentials

**使用 n8n 內建的 Google Gemini 節點（推薦）**

1. 點擊右上角 **Settings** → **Credentials**
2. 點擊 **Add Credential**
3. 搜尋並選擇 **Google Gemini**
4. **Credential Name**: `Google Gemini - Kantoku`
5. **API Key**: `[您的 Gemini API Key]`
6. 點擊 **Save**

⚠️ **重要**: 在 Workflow 中請始終使用 **Google Gemini Chat Model** 節點，而不是 HTTP Request 節點。內建節點會自動處理 API 端點與認證。

### 步驟 4: 新增 Postgres Credentials（選用）

如果要直接連接 Supabase PostgreSQL：

1. 新增 Credential → **Postgres**
2. **Host**: `db.xxxxxx.supabase.co`（從 Supabase Settings → Database → Connection string 取得）
3. **Database**: `postgres`
4. **User**: `postgres`
5. **Password**: `[您的 Database Password]`
6. **Port**: `5432`
7. **SSL**: `allow`

點擊 **Test** 驗證連線

---

## 5️⃣ 建立第一個 Workflow

### 步驟 1: 建立 Workflow 1（任務生成）

1. 點擊 **Workflows** → **Add workflow**
2. 點擊 **+** → 搜尋 **Webhook**
3. 配置 Webhook:
   - **HTTP Method**: POST
   - **Path**: `generate-tasks`
4. 點擊 **Listen for test event**
5. 在終端機測試：

```bash
curl -X POST http://localhost:5678/webhook-test/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test-123", "daily_goal_minutes": 30}'
```

6. 在 n8n 中應該看到測試資料
7. 依照 `n8n-workflows/WORKFLOW_DESIGN.md` 繼續建立節點

### 步驟 2: 儲存並啟動 Workflow

1. 點擊右上角 **Save**
2. 輸入名稱: `1. Generate Tasks`
3. 點擊 **Active** 開關啟動

---

## 6️⃣ 環境變數整理

建立 `.env` 檔案（不要提交到 Git）：

```env
# Supabase
SUPABASE_URL=https://xxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...
SUPABASE_DB_PASSWORD=your_password

# Gemini AI
GEMINI_API_KEY=AIzaSy...

# n8n
N8N_URL=http://localhost:5678
N8N_AUTH_USER=admin
N8N_AUTH_PASSWORD=kantoku2024
```

---

## 7️⃣ 驗證完整設定

### 測試 Checklist

- [ ] Xcode 可以開啟並建立新專案
- [ ] Supabase 專案可以訪問，表格已建立
- [ ] Gemini API Key 可以正常呼叫
- [ ] n8n 可以訪問，Credentials 設定完成
- [ ] Webhook 測試成功回應

### 完整整合測試

1. **測試資料庫連接**:
```bash
curl -X GET "https://xxxxxx.supabase.co/rest/v1/learning_stages?select=*" \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

預期結果: 回傳 10 個 learning_stages

2. **測試 Gemini AI**:
在 n8n 中建立一個簡單的 Workflow，包含 **AI Agent** 節點連接 **Google Gemini Chat Model** 節點，點擊 **Test Step** 驗證是否能收到回應。

3. **測試 n8n Workflow**:
   - 參考 `n8n-workflows/WORKFLOW_DESIGN.md` 的測試計劃

---

## 🆘 常見問題

### Q1: Xcode 安裝太慢
**A**: Xcode 非常大（約 15 GB），建議使用穩定的網路環境，或選擇夜間下載。

### Q2: Supabase 免費方案限制？
**A**: 
- 500 MB 資料庫空間
- 50,000 月度活躍使用者
- 1 GB 檔案儲存
- 適合 MVP 開發

### Q3: Gemini API 免費嗎？
**A**: 
- Gemini 1.5 Flash 有免費額度
- 每分鐘 15 次請求
- 每天 1,500 次請求
- 足夠開發與測試

### Q4: n8n Workflow 無法連接 Supabase
**A**: 
1. 檢查 Credentials 是否正確
2. 確認 service_role key（不是 anon key）
3. 檢查 Supabase 專案是否啟動
4. 測試用 curl 直接呼叫 Supabase REST API

### Q5: 如何備份 n8n Workflows？
**A**: 
1. 在 n8n 中開啟 Workflow
2. 點擊右上角 **⋯** → **Download**
3. 儲存 JSON 檔案到 `n8n-workflows/` 資料夾

---

## 📌 下一步

環境設定完成後：

1. ✅ 建立 Supabase 專案並執行 Schema
2. ✅ 在 n8n 中設定 Credentials
3. 🔄 依照 `n8n-workflows/WORKFLOW_DESIGN.md` 建立四個 Workflows
4. 🔄 測試 Workflows
5. ⏳ 開始開發 iOS App（Phase 1-2）

---

**需要協助？** 參考專案文件：
- `PLAN.md` - 完整實作計劃
- `CODE_EXAMPLES.md` - 程式碼範例
- `n8n-workflows/WORKFLOW_DESIGN.md` - Workflow 設計文件
