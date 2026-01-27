# Kantoku iOS 環境配置完成報告

**日期**: 2026-01-27  
**狀態**: ✅ 所有環境配置已完成

---

## 📋 完成項目總覽

| 配置項目 | 狀態 | 完成時間 |
|----------|------|----------|
| Xcode Supabase Swift SDK | ✅ | 2026-01-27 |
| Supabase Storage (submissions bucket) | ✅ | 2026-01-27 |
| Supabase Storage RLS Policies | ✅ | 2026-01-27 |
| n8n Webhook 端點確認 | ✅ | 2026-01-27 |
| Git 安全配置 | ✅ | 2026-01-27 |

---

## 1️⃣ Xcode Swift Package Manager 配置

### 已添加的依賴
- **Package URL**: `https://github.com/supabase/supabase-swift.git`
- **Version**: 2.0.0+
- **Products**: 
  - Supabase (主要 SDK)
  - 包含: Auth, Storage, PostgREST, Realtime, Functions

### 配置位置
```
File > Add Package Dependencies...
在 Xcode 中已成功添加並解析
```

---

## 2️⃣ Supabase Storage 配置

### Bucket 創建
- **Bucket 名稱**: `submissions`
- **類型**: Private (需要認證才能存取)
- **檔案大小限制**: 50MB
- **允許的 MIME 類型**:
  - `image/jpeg`
  - `image/png`
  - `image/heic`
  - `audio/m4a`
  - `audio/mpeg`
  - `audio/wav`

### RLS (Row Level Security) Policies

#### Policy 1: Insert - "Users can upload their own submissions"
```sql
-- 允許用戶上傳到自己的資料夾
(bucket_id = 'submissions' AND (storage.foldername(name))[1] = auth.uid()::text)
```
- **Operation**: INSERT
- **Target roles**: authenticated
- **用途**: 用戶只能上傳檔案到 `{user_id}/` 路徑下

#### Policy 2: Select - "Users can view their own submissions"
```sql
-- 允許用戶讀取自己的檔案
(bucket_id = 'submissions' AND (storage.foldername(name))[1] = auth.uid()::text)
```
- **Operation**: SELECT
- **Target roles**: authenticated
- **用途**: 用戶只能讀取自己的檔案

#### Policy 3: Delete - "Users can delete their own submissions"
```sql
-- 允許用戶刪除自己的檔案
(bucket_id = 'submissions' AND (storage.foldername(name))[1] = auth.uid()::text)
```
- **Operation**: DELETE
- **Target roles**: authenticated
- **用途**: 用戶只能刪除自己的檔案

#### Policy 4: Service Role Access (可選)
```sql
-- Service role 完全存取
true
```
- **Operation**: ALL
- **Target roles**: service_role
- **用途**: n8n webhook 可用 service_role key 存取所有檔案

### 檔案路徑格式
```
{user_id}/{filename}

範例:
ebc3cd0d-dc42-42c1-920a-87328627fe35/recording_1738022400.m4a
ebc3cd0d-dc42-42c1-920a-87328627fe35/image_1738022500.jpg
```

---

## 3️⃣ n8n Workflow 端點

### 已實作並測試的 Webhooks

#### generate-tasks (已完成 ✅)
- **URL**: `http://localhost:5678/webhook/generate-tasks`
- **Method**: POST
- **用途**: 生成每日學習任務
- **Request Body**:
```json
{
  "user_id": "uuid",
  "daily_goal_minutes": 30
}
```
- **測試狀態**: ✅ 已測試通過

#### review-submission (已完成 ✅)
- **URL**: `http://localhost:5678/webhook/review-submission`
- **Method**: POST
- **用途**: AI 審核使用者提交
- **支援類型**:
  - `text` - 文字輸入審核
  - `direct_confirm` - 直接確認完成
- **Request Body**:
```json
{
  "task_id": "uuid",
  "submission_type": "text",  // 或 "direct_confirm"
  "content": "使用者答案"      // text 類型時必填
}
```
- **Response**:
```json
{
  "success": true,
  "passed": true,
  "score": 95,
  "feedback": "AI 回饋內容",
  "correct_answer": "正確答案（如果錯誤）",
  "message": "通過！繼續加油！"
}
```
- **測試狀態**: ✅ 已測試通過

### 待實作的 Webhooks

#### generate-test (設計完成)
- **URL**: `http://localhost:5678/webhook/generate-test`
- **狀態**: 📝 設計完成，待實作

#### grade-test (設計完成)
- **URL**: `http://localhost:5678/webhook/grade-test`
- **狀態**: 📝 設計完成，待實作

---

## 4️⃣ Git 安全配置

### .gitignore 更新
已添加以下規則排除敏感配置檔：
```gitignore
# Local config with secrets
*.local.xcconfig
Config.local.xcconfig
```

### 配置檔案結構
```
ios/kantoku/Resources/
├── Config.xcconfig           # 模板（追蹤到 git）✅
├── Config.local.xcconfig     # 真實密鑰（不追蹤）✅
└── Info.plist               # 權限配置 ✅
```

### Config.xcconfig (模板)
```xcconfig
// Configuration settings file format documentation
// https://help.apple.com/xcode/#/dev745c5c974

// Import local config if exists (secrets)
#include? "Config.local.xcconfig"

// Default values (placeholders)
SUPABASE_URL = YOUR_SUPABASE_URL
SUPABASE_ANON_KEY = YOUR_SUPABASE_ANON_KEY
N8N_BASE_URL = http:/$()/localhost:5678
```

### Config.local.xcconfig (本地 - 不追蹤)
```xcconfig
// Local secrets - DO NOT COMMIT
SUPABASE_URL = https://xxxxx.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
N8N_BASE_URL = http://localhost:5678
```

### 安全確認清單
- ✅ `Config.local.xcconfig` 已從 git 追蹤中移除
- ✅ `.gitignore` 規則已生效
- ✅ 真實密鑰不會被 commit
- ✅ 團隊成員可以創建自己的 `Config.local.xcconfig`

---

## 5️⃣ 環境變數配置

### 已設定的環境變數
| 變數名稱 | 用途 | 範例值 |
|----------|------|--------|
| `SUPABASE_URL` | Supabase 專案 URL | `https://xxxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | Supabase 公開金鑰 | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` |
| `N8N_BASE_URL` | n8n Webhook 基礎 URL | `http://localhost:5678` |

### 在 Info.plist 中的使用
```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
<key>N8N_BASE_URL</key>
<string>$(N8N_BASE_URL)</string>
```

### 在 Swift 中的讀取
```swift
// SupabaseService.swift
guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
      let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
      let url = URL(string: supabaseURL) else {
    fatalError("Supabase configuration not found in Info.plist")
}
```

---

## 📝 使用指南

### Supabase Storage 使用範例

#### 上傳音訊檔案
```swift
import Supabase

let supabase = SupabaseService.shared.client
let userId = try await supabase.auth.session.user.id
let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
let filePath = "\(userId)/\(fileName)"

// 上傳檔案
try await supabase.storage
    .from("submissions")
    .upload(
        path: filePath,
        file: audioData,
        options: FileOptions(contentType: "audio/m4a")
    )

// 獲取公開 URL
let publicURL = try supabase.storage
    .from("submissions")
    .getPublicURL(path: filePath)
```

#### 上傳圖片檔案
```swift
let fileName = "image_\(Date().timeIntervalSince1970).jpg"
let filePath = "\(userId)/\(fileName)"

// 壓縮圖片
guard let compressedData = image.jpegData(compressionQuality: 0.7) else {
    throw StorageError.compressionFailed
}

// 上傳
try await supabase.storage
    .from("submissions")
    .upload(
        path: filePath,
        file: compressedData,
        options: FileOptions(contentType: "image/jpeg")
    )
```

#### 刪除檔案
```swift
try await supabase.storage
    .from("submissions")
    .remove(paths: [filePath])
```

### n8n Webhook 使用範例

#### 調用 review-submission (文字審核)
```swift
import Foundation

let apiService = APIService.shared
let response = try await apiService.post(
    endpoint: "/webhook/review-submission",
    body: [
        "task_id": taskId,
        "submission_type": "text",
        "content": "sakana"
    ]
)

if let passed = response["passed"] as? Bool, passed {
    print("審核通過！")
}
```

#### 調用 review-submission (直接確認)
```swift
let response = try await apiService.post(
    endpoint: "/webhook/review-submission",
    body: [
        "task_id": taskId,
        "submission_type": "direct_confirm"
    ]
)
```

#### 調用 generate-tasks
```swift
let response = try await apiService.post(
    endpoint: "/webhook/generate-tasks",
    body: [
        "user_id": userId,
        "daily_goal_minutes": 30
    ]
)

if let tasks = response["tasks"] as? [[String: Any]] {
    print("生成了 \(tasks.count) 個任務")
}
```

---

## 🧪 測試驗證

### Supabase Storage 測試
```bash
# 使用 curl 測試上傳（需要 access token）
curl -X POST 'https://xxxxx.supabase.co/storage/v1/object/submissions/user-id/test.txt' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: text/plain' \
  --data-binary 'Test content'
```

### n8n Webhook 測試
```bash
# 測試 review-submission
curl -X POST http://localhost:5678/webhook/review-submission \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "test-task-uuid",
    "submission_type": "text",
    "content": "a"
  }'

# 測試 generate-tasks
curl -X POST http://localhost:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user-uuid",
    "daily_goal_minutes": 30
  }'
```

---

## 🎯 下一步建議

### 立即可進行的開發任務
1. **完善 SubmissionViewModel**
   - 整合 Supabase Storage 上傳
   - 實作上傳進度追蹤
   - 錯誤處理與重試機制

2. **測試完整提交流程**
   - 錄音 → 上傳到 Storage → 調用 review webhook → 顯示結果
   - 圖片上傳 → Storage → webhook → 結果

3. **實作 Phase 6: Progress & Statistics**
   - 整合 Swift Charts
   - 假名進度網格視圖
   - 統計圖表視覺化

4. **實作 Phase 7: Testing & Quizzes**
   - 完成 generate-test 和 grade-test webhooks
   - 測驗生成與批改流程

### 待處理項目
- [ ] 在 Xcode 中驗證 build 成功
- [ ] 測試真實裝置上的 Supabase 連接
- [ ] 測試音訊/圖片上傳到 Storage
- [ ] 測試 RLS policies 是否正確運作
- [ ] 實作錯誤處理與用戶提示
- [ ] 添加單元測試與整合測試

---

## 📚 相關文檔

- [DEVELOPMENT_PROGRESS.md](./DEVELOPMENT_PROGRESS.md) - 總體開發進度
- [iOS_PLAN.md](./iOS_PLAN.md) - 開發路線圖
- [../Supabase/SCHEMA.md](../Supabase/SCHEMA.md) - 資料庫結構
- [../../n8n-workflows/WORKFLOW_DESIGN.md](../../n8n-workflows/WORKFLOW_DESIGN.md) - n8n Workflow 設計
- [../../n8n-workflows/BEST_PRACTICES.md](../../n8n-workflows/BEST_PRACTICES.md) - n8n 最佳實踐

---

**總結**: 所有環境配置已完成，iOS 專案可以開始正式開發核心功能了！🚀
