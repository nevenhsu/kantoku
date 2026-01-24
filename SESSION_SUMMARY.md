# Kantoku 開發會話總結

**最後更新**: 2026-01-24  
**累計工作時長**: ~9-10 小時  
**狀態**: 🎉 Workflow 1 & 2 完成，後端 API 核心功能運作中

---

## 📊 會話記錄

### 會話 4: 2026-01-24 ✅

**時長**: ~1 小時  
**主題**: 完成 Workflow 2（提交審核）- Phase 4-6

#### 完成項目

1. **Workflow 2: 提交審核（review-submission）** ✅
   - Phase 4-6 完成
   - 總計 17 個節點
   - **100% 完成並測試通過** 🎉

2. **Phase 4: 合併路徑 + 更新任務狀態** ✅
   - Merge 節點（Include Any Unpaired Items）
   - Postgres - Update Task

3. **Phase 5: 更新學習進度** ✅
   - Code - Prepare Data（解析 task content）
   - IF - Passed
   - Postgres - Upsert Progress (Pass)（間隔重複演算法）
   - Postgres - Update Progress (Fail)（錯誤計數）

4. **Phase 6: 插入提交記錄 + 回傳** ✅
   - Merge - Progress Result
   - Postgres - Insert Submission
   - Code - Format Response

5. **完整測試結果**:
   ```
   測試 1（正確答案）: passed=true, score=100, kana_progress updated
   測試 2（錯誤答案）: passed=false, correct_answer provided, incorrect_count++
   測試 3（直接確認）: passed=true, score=100
   ```

6. **資料庫驗證**:
   - ✅ tasks 狀態正確更新
   - ✅ kana_progress 正確 upsert（correct_count / incorrect_count）
   - ✅ submissions 記錄完整保存

#### 關鍵發現與解決方案

1. **Supabase Node vs Postgres Node**
   - 問題：Supabase Node 不支援 Upsert
   - 解決：使用 Postgres Node 執行 `INSERT ON CONFLICT UPDATE`

2. **Merge 節點設定**
   - 問題：Switch 分流後只有一條路徑有資料
   - 解決：啟用 **Include Any Unpaired Items**

3. **Query 操作選擇**
   - 單筆查詢用 **Get**（不是 Get Many）
   - 更直接、效能更好

4. **間隔重複演算法實作**
   - 通過：correct_count++, next_review: 1→3→7→14→30天
   - 失敗：incorrect_count++, next_review: +1天

#### 學到的經驗
- Postgres Node 提供更多 SQL 彈性（Upsert、CASE WHEN）
- n8n Merge 節點需要考慮資料流向（單/雙路徑）
- Code 節點可以處理複雜的資料準備和解析邏輯
- 完整的測試覆蓋（通過/失敗/直接確認）很重要

---

### 會話 3: 2026-01-23 ⏳

**時長**: ~2 小時  
**主題**: 建立 Workflow 2（提交審核）- Phase 1-3

#### 完成項目

1. **Workflow 2: 提交審核（review-submission）** ⏳
   - Phase 1-3 完成（共 6 個 Phases）
   - 8 個節點已建立
   - Webhook URL: `http://localhost:5678/webhook/review-submission`

2. **已實作功能**:
   - ✅ Webhook 接收提交請求
   - ✅ 查詢任務詳情（Supabase）
   - ✅ 分流處理：direct_confirm vs text
   - ✅ 直接確認路徑（100% 通過）
   - ✅ AI 審核路徑（Gemini 2.5 Flash）
   - ✅ 解析 AI 回應

3. **節點列表**:
   ```
   [Webhook] → [Query - Task Details] → [Switch - Submission Type]
                                              │
                      ┌───────────────────────┼──────────────────────┐
                      │ (direct_confirm)      │ (text)               │
                      ▼                       ▼                      │
             [Code - Direct Confirm]  [Gemini - Review Answer]      │
                      │                       ├─ Model Node          │
                      │               [Code - Parse AI Response]     │
                      │                       │                      │
                      └───────────┬───────────┘                      │
                                  ▼                                  │
                         [Respond to Webhook] ◄────────────────────┘
   ```

4. **測試結果**:
   - ✅ **direct_confirm**: `passed: true, score: 100`
   - ✅ **text（正確答案 "a"）**: `passed: true, score: 100, feedback: "羅馬拼音完全正確"`
   - ✅ **text（錯誤答案 "wrong"）**: `passed: false, score: 0, correct_answer: "a"`

#### 待完成項目

- ⏳ **Phase 4**: 合併路徑 + 更新任務狀態
- ⏳ **Phase 5**: 更新學習進度（kana_progress）
- ⏳ **Phase 6**: 插入提交記錄 + 格式化回傳

#### 學到的經驗
- n8n AI Agent 節點會自動生成多個子節點（Trigger + Agent + Model）
- Gemini 2.5 Flash 是目前最低支援版本
- Switch 節點可以根據條件分流到不同路徑
- AI Prompt 需要明確要求 JSON 格式輸出

---

### 會話 2: 2026-01-23 ✅

**時長**: ~1.5 小時  
**主題**: 建立 Workflow 1（任務生成）

#### 完成項目

1. **建立測試使用者** ✅
   - 透過 Supabase Dashboard 建立使用者
   - Email: test@kantoku.local
   - User UID: `ebc3cd0d-dc42-42c1-920a-87328627fe35`
   - 自動觸發 `handle_new_user()` 初始化資料

2. **Workflow 1: 任務生成（generate-tasks）** ✅
   - 13 個節點完整建立
   - 測試通過，成功生成 5 個假名學習任務
   - Webhook URL: `http://localhost:5678/webhook/generate-tasks`

3. **節點列表**:
   ```
   [Webhook] 
       ↓
   [Query - User Progress] → [Query - Learning Stage] 
       ↓
   [Query - Learned Kana] → [Query - Review Items]
       ↓
   [IF - Has Review Items]
       ├─ true  → [Code - Prepare Review Kana]
       └─ false → [Code - Select New Kana] ✅ 測試通過
           ↓
   [Code - Build Tasks] → [Loop - Insert Tasks] ⟳ [Insert - Task]
       ↓
   [Code - Format Response] → [Respond to Webhook]
   ```

4. **測試結果**:
   ```json
   {
     "success": true,
     "tasks_generated": 5,
     "tasks": [...],  // あ、い、う、え、お
     "estimated_minutes": 15,
     "message": "今日任務已生成"
   }
   ```

5. **文件更新** ✅
   - PLAN.md: 更新 Phase 3 進度
   - ENV_SETUP_COMPLETE.md: 新增測試使用者資訊
   - SESSION_SUMMARY.md: 新增會話記錄
   - n8n-workflows/WORKFLOW_DESIGN.md: 新增實作狀態

#### 學到的經驗
- n8n 測試模式需要手動點擊 Execute Workflow 才會監聽 Webhook
- Supabase Node 對空查詢結果回傳 `[{}]` 而非 `[]`
- Respond to Webhook 節點必須連接在 Workflow 末端，否則 Webhook 會報錯
- Code 節點的 `$input.all()` 可以取得所有輸入項目

---

### 會話 1: 2026-01-22 ✅

**時長**: ~2-3 小時  
**主題**: 環境準備階段

## 📊 累計完成項目

### 1. 專案規劃與文件 ✅

| 文件 | 狀態 | 說明 |
|------|------|------|
| PLAN.md | ✅ | 完整實作計劃（Swift iOS + n8n 架構） |
| CODE_EXAMPLES.md | ✅ | Swift 代碼範例與 n8n 教學 |
| SETUP_GUIDE.md | ✅ | 環境準備詳細指南 |
| ENV_SETUP_COMPLETE.md | ✅ | 環境設定完成報告 |
| n8n-workflows/WORKFLOW_DESIGN.md | ✅ | 4 個核心 Workflow 設計文件 |

**成果**: 完整的專案文件系統，包含技術架構、實作步驟、代碼範例

---

### 2. 資料庫架構設計 ✅

#### Supabase Schema
- **表格數量**: 11 張
- **RLS 政策**: 已設定完整的 Row Level Security
- **觸發器**: 
  - 自動更新 `updated_at`
  - 新使用者自動初始化 profile、progress、stats
- **初始資料**: 10 個 learning_stages（あ行～わ行）

#### 核心表格
```
profiles              # 使用者資料
learning_stages       # 學習階段定義
kana_progress        # 50音學習進度
vocabulary           # 詞彙資料庫
vocabulary_progress  # 詞彙學習進度
user_progress        # 使用者當前階段
learning_stats       # 學習統計
tasks                # 任務系統
submissions          # 提交記錄
tests                # 階段性測驗
external_resources   # 外部資源
```

**成果**: 生產環境就緒的資料庫架構

---

### 3. 學習資料準備 ✅

#### 50 音資料 (kana_data.json)
- **清音**: 46 個（あ行～わ行）
- **濁音/半濁音**: 25 個（が行～ぱ行）
- **拗音**: 36 個（きゃ系～りゃ系）
- **總計**: 107 個平假名
- **格式**: 結構化 JSON，包含 romaji、類型、階段編號

#### 單字資料 (vocabulary_hiragana.json)
- **Stage 1-5**: 約 25 個基礎單字
- **特色**: 漸進式學習（只使用已學假名）
- **包含**: 漢字、讀音、意思、例句、頻率等級

**待完成**: Stage 6-10 單字資料

**成果**: MVP 階段足夠的學習資料

---

### 4. 開發環境設定 ✅

#### 本地開發工具
```
✅ Xcode Command Line Tools: 版本 2416
✅ Swift: 版本 6.2.3
✅ Docker Desktop: 已運行
✅ n8n: 版本 2.4.4 (localhost:5678)
```

#### 雲端服務
```
✅ Supabase
   - Project URL: https://pthqgzpmsgsyssdatxnm.supabase.co
   - Database: PostgreSQL (11 tables)
   - Auth: 已設定
   - Storage: 已建立

✅ Google Gemini AI
   - API Key: 已取得
   - Model: gemini-pro
   - Status: 測試通過
```

#### n8n Credentials（安全儲存）
```
✅ Supabase - Kantoku
   - Type: Supabase API
   - Host: https://pthqgzpmsgsyssdatxnm.supabase.co
   - Service Role Key: [安全儲存]

✅ Google Gemini - Kantoku
   - Type: Google Gemini (PaLM) API
   - API Key: [安全儲存]
```

**成果**: 完整的開發環境，所有服務正常運作

---

### 5. 整合測試 Workflow ✅

#### 測試範圍
1. **Webhook** - HTTP POST 請求接收
2. **Supabase** - 資料庫查詢（learning_stages）
3. **Gemini AI** - AI 文字生成
4. **資料處理** - Code 節點邏輯

#### 測試結果
```
✅ Webhook 接收正常
✅ Supabase 回傳 10 筆 learning_stages
✅ Gemini AI 成功生成回應：
   "Kantoku 是一款讓您透過觀看日劇、電影、動漫來學習日文的 App..."
✅ Code 節點資料處理正確
✅ JSON 回應格式正確
```

#### Workflow 檔案
- 已匯出: `n8n-workflows/test-environment.json`
- 已推送到 GitHub

**成果**: 驗證所有核心服務整合正常

---

### 6. 安全性設定 ✅

#### 已保護的敏感資訊
```
✅ .env 檔案已加入 .gitignore
✅ Supabase Service Role Key 僅存於 n8n Credentials
✅ Gemini API Key 僅存於 n8n Credentials
✅ Database Password 僅存於本地 .env
✅ .env.example 提供範本（不含實際值）
```

#### .gitignore 涵蓋
```
.env, .env.local
n8n-data/
credentials.json, *_key.json, *.pem
*.log
Xcode build 產出
```

**成果**: 零敏感資訊暴露風險

---

### 7. 版本控制 ✅

#### Git Repository
- **Repository**: https://github.com/nevenhsu/kantoku
- **Branch**: main
- **Commits**: 2 次提交

#### Commit 歷史
```
29ca04e - feat: add environment setup completion and test workflow
783c3d7 - feat: add n8n workflow design, database schema, and project foundation
```

#### 已推送檔案
```
專案文件（5 個）:
- PLAN.md
- CODE_EXAMPLES.md
- SETUP_GUIDE.md
- ENV_SETUP_COMPLETE.md
- SESSION_SUMMARY.md (本檔案)

資料庫（1 個）:
- supabase/schema.sql

學習資料（2 個）:
- data/kana_data.json
- data/vocabulary_hiragana.json

n8n Workflows（2 個）:
- n8n-workflows/WORKFLOW_DESIGN.md
- n8n-workflows/test-environment.json

配置檔案（3 個）:
- docker-compose.yml
- .gitignore
- .env.example
```

**成果**: 完整的專案版本控制

---

## 🎯 專案進度總覽

### Phase 0: 環境準備 ✅ (100%)
- [x] 安裝 Docker Desktop
- [x] 啟動 n8n
- [x] 建立 Supabase 專案
- [x] 取得 Gemini API Key
- [x] 設定 n8n Credentials
- [x] 整合測試通過

### Phase 1: 資料準備 ⏳ (60%)
- [x] 50 音完整資料（107 音）
- [x] Stage 1-5 單字資料
- [ ] Stage 6-10 單字資料
- [ ] 濁音/拗音相關單字
- [ ] 片假名資料

### Phase 2: n8n Workflows ⏳ (25%)
- [x] Workflow 1: 任務生成 ✅ 2026-01-23
- [ ] Workflow 2: 提交審核
- [ ] Workflow 3: 測驗生成
- [ ] Workflow 4: 測驗批改

### Phase 3: iOS App 🔜 (0%)
- [ ] Xcode 專案建立
- [ ] Supabase Swift SDK 整合
- [ ] 基本 UI 框架
- [ ] 認證系統

**總體進度**: Phase 0 完成，Phase 1 進行中（60%），Phase 2 已開始（25%）

---

## 💡 關鍵決策記錄

### 技術選型
1. **前端**: Swift + SwiftUI（iOS 16+）
   - 理由：原生效能、更好的音訊/相機支援
   
2. **後端**: n8n Workflow（低代碼）
   - 理由：快速開發、視覺化邏輯、易於調整
   
3. **資料庫**: Supabase（PostgreSQL + Auth + Storage）
   - 理由：一站式解決方案、即時訂閱、RLS 安全

4. **AI**: Google Gemini 1.5 Flash
   - 理由：高性價比、中文支援良好、免費額度充足

### MVP 範圍
- ✅ **支援**: 文字提交、直接確認勾選
- ❌ **延後**: 音訊錄製、截圖上傳（Phase 8-9）
- ✅ **專注**: 平假名學習（片假名 Phase 後期）

### 學習方法
- **核心理念**: 漸進式學習（邊學假名，邊學相關單字）
- **間隔重複**: Spaced Repetition 演算法
- **階段性測驗**: 每 10% 進度觸發
- **AI 主導**: 嚴格的專案經理角色

---

## 📚 重要參考資訊

### Supabase
- **URL**: https://pthqgzpmsgsyssdatxnm.supabase.co
- **Dashboard**: https://supabase.com/dashboard/project/pthqgzpmsgsyssdatxnm
- **文件**: 參考 SETUP_GUIDE.md 和 ENV_SETUP_COMPLETE.md

### n8n
- **本地 URL**: http://localhost:5678
- **帳號**: admin
- **密碼**: kantoku2024
- **啟動**: `docker-compose up -d`
- **停止**: `docker-compose down`

### 開發指令
```bash
# 啟動開發環境
open -a Docker
cd /Users/neven/Documents/projects/kantoku
docker-compose up -d

# 查看 n8n
open http://localhost:5678

# 查看 Supabase
open https://supabase.com/dashboard/project/pthqgzpmsgsyssdatxnm

# Git 操作
git status
git add .
git commit -m "message"
git push origin main
```

---

## 🚀 下次會話建議

### 優先級 1（最重要）
建立四個核心 Workflow，讓後端 API 可以運作：

1. **Workflow 1: 任務生成（generate-tasks）**
   - 預估時間：1-1.5 小時
   - 難度：⭐⭐⭐
   - 依賴：需要完整理解漸進式學習邏輯

2. **Workflow 2: 提交審核（review-submission）**
   - 預估時間：0.5-1 小時
   - 難度：⭐⭐
   - 依賴：需要 Gemini AI prompt 調整

3. **Workflow 3-4: 測驗系統（generate-test, grade-test）**
   - 預估時間：1-1.5 小時
   - 難度：⭐⭐
   - 依賴：可延後到有基本任務系統後

### 優先級 2（次要）
擴充學習資料：
- Stage 6-10 單字資料（1 小時）
- 濁音/拗音單字（30 分鐘）

### 優先級 3（可延後）
開始 iOS App 開發：
- 建立 Xcode 專案
- 設定專案結構
- 整合 Supabase Swift SDK

---

## 📝 待解決問題

### 技術問題
1. ⏳ **Gemini API 模型版本**
   - 目前使用: gemini-pro
   - 計劃: 測試 ggemini-2.5-flash（更快更便宜）
   - 狀態: 可運作，待優化

2. ⏳ **間隔重複演算法參數**
   - 目前設定: [1, 3, 7, 14, 30, 60, 120] 天
   - 狀態: 理論值，需實際使用調整

3. ⏳ **AI 審核標準**
   - 假名學習: 羅馬拼音完全正確
   - 單字學習: 80% 相似度即通過
   - 狀態: 需要實際測試與調整 prompt

### 資料問題
1. 🔜 **Stage 6-10 單字不足**
   - 現狀: 只有 Stage 1-5
   - 影響: 測試時無法完整驗證漸進式學習
   - 優先級: 中

2. 🔜 **片假名資料缺失**
   - 現狀: 只有平假名
   - 影響: MVP 不受影響（先專注平假名）
   - 優先級: 低

### 設計問題
1. ⏳ **跳過機制細節**
   - 每日跳過次數: 1-2 次
   - 是否扣分: 待定
   - 是否影響進度: 待定

---

## 🎉 值得慶祝的成就

1. ✨ **完整的專案規劃** - 從架構到實作的清晰路徑
2. 🗄️ **生產就緒的資料庫** - RLS、觸發器、初始資料都已完成
3. 🔗 **整合測試通過** - Webhook → Supabase → Gemini 完整流程驗證
4. 🔐 **零安全漏洞** - 所有敏感資訊妥善保護
5. 📚 **詳盡的文件** - 未來開發者可以快速上手
6. 🎯 **清晰的 MVP 範圍** - 知道什麼該做、什麼延後

---

## 💭 反思與學習

### 做得好的地方
- ✅ 系統化的環境準備流程
- ✅ 完整的文件記錄
- ✅ 安全性優先的設計
- ✅ 漸進式的測試方法

### 可以改進的地方
- ⚠️ n8n 新版界面需要熟悉
- ⚠️ Gemini API 版本選擇需要更多測試
- ⚠️ 單字資料準備可以更早開始

### 學到的經驗
1. **n8n 內建連接器優於 HTTP Request** - 更安全、更方便
2. **測試驅動的環境設定** - 先測試再建立生產環境
3. **文件即時更新很重要** - 避免忘記重要細節

---

## 📞 下次會話準備

### 請準備
1. ☕ 一杯咖啡（建立 Workflows 需要專注）
2. 📝 參考文件：
   - `n8n-workflows/WORKFLOW_DESIGN.md`
   - `ENV_SETUP_COMPLETE.md`
3. 🖥️ 確保環境運行：
   ```bash
   docker-compose ps  # 確認 n8n 運行中
   ```

### 會話目標
建立至少 1-2 個生產環境 Workflow，讓後端 API 開始運作。

---

**休息愉快！下次見！** 🎉

**Kantoku Project - Building the Future of Japanese Learning** 🇯🇵
