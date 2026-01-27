# Kantoku iOS 測試指南

**日期**: 2026-01-27  
**狀態**: ✅ 測試配置完成

---

## 📋 測試概覽

本指南將幫助你在 Xcode 中 build 並測試 Supabase 和 n8n 的連接。

### 完成的測試工具
- ✅ **ConnectionTestService.swift** - 連接測試服務
- ✅ **TestConnectionView.swift** - 測試界面視圖

---

## 🚀 快速開始

### 步驟 1: 打開 Xcode 項目

```bash
cd /Users/neven/Documents/projects/kantoku
open ios/kantoku.xcodeproj
```

### 步驟 2: 確認環境配置

1. 在 Xcode 左側導航欄中，選擇項目根節點 `kantoku`
2. 在中間面板選擇 `kantoku` target
3. 切換到 `Build Settings` 標籤
4. 搜索 "SUPABASE"，確認以下變數已設定：
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `N8N_BASE_URL`

如果這些變數顯示為預設值（YOUR_SUPABASE_URL），請確認：
- `Config.local.xcconfig` 檔案存在於 `Resources/` 資料夾
- 該檔案包含正確的 Supabase 和 n8n 配置

### 步驟 3: 確認 Supabase SDK

1. 在 Xcode 左側導航欄，選擇項目根節點
2. 切換到 `Package Dependencies` 標籤
3. 確認看到 `supabase-swift` 套件（版本 2.0.0+）

如果沒有看到，請添加：
1. 點擊 `File` > `Add Package Dependencies...`
2. 輸入 URL: `https://github.com/supabase/supabase-swift.git`
3. 選擇 `Up to Next Major Version`，輸入 `2.0.0`
4. 點擊 `Add Package`
5. 在產品選擇中，勾選 `Supabase`
6. 點擊 `Add Package`

### 步驟 4: 添加測試視圖到應用

編輯 `ios/kantoku/App/kantokuApp.swift`，添加測試入口：

```swift
import SwiftUI

@main
struct kantokuApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // 開發模式：顯示測試視圖
    @AppStorage("isDevelopmentMode") private var isDevelopmentMode = true
    
    var body: some Scene {
        WindowGroup {
            if isDevelopmentMode {
                // 開發模式：顯示測試視圖
                TestConnectionView()
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(authViewModel)
            } else if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
```

或者，你可以直接在 `MainTabView` 中添加測試標籤（推薦用於測試）：

編輯 `ios/kantoku/Views/MainTabView.swift`：

```swift
struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
            
            TasksView()
                .tabItem {
                    Label("任務", systemImage: "checkmark.circle.fill")
                }
            
            ProgressView()
                .tabItem {
                    Label("進度", systemImage: "chart.bar.fill")
                }
            
            TestsView()
                .tabItem {
                    Label("測驗", systemImage: "doc.text.fill")
                }
            
            // 添加測試標籤（僅開發環境）
            TestConnectionView()
                .tabItem {
                    Label("測試", systemImage: "network")
                }
            
            ProfileView()
                .tabItem {
                    Label("設定", systemImage: "person.fill")
                }
        }
    }
}
```

### 步驟 5: Build 並運行

1. 選擇模擬器或真實裝置
   - 建議：`iPhone 15 Pro` 模擬器
   - iOS 版本：16.0+

2. 點擊 Xcode 左上角的 ▶️ 按鈕（或按 `Cmd + R`）

3. 等待 build 完成

4. 如果出現錯誤，請參考下方的 [常見問題](#常見問題) 區段

### 步驟 6: 執行測試

1. 應用啟動後，你會看到 **連接測試** 界面

2. 點擊 **「開始測試」** 按鈕

3. 等待測試完成（通常 5-10 秒）

4. 查看測試結果：
   - ✅ 綠色勾號 = 測試通過
   - ❌ 紅色叉號 = 測試失敗

5. 點擊任一測試項目展開詳細資訊

---

## 🧪 測試項目說明

### Supabase 測試

#### 1. Supabase 基礎連接
- **測試內容**: 測試是否能連接到 Supabase 伺服器
- **預期結果**: 連接成功
- **失敗原因**:
  - `SUPABASE_URL` 配置錯誤
  - 網路連接問題
  - Supabase 伺服器故障

#### 2. Supabase Auth
- **測試內容**: 測試認證服務是否正常運作
- **預期結果**: 
  - 如果已登入：顯示用戶 ID
  - 如果未登入：顯示「未登入（正常狀態）」
- **失敗原因**:
  - Auth 服務配置錯誤
  - JWT token 無效

#### 3. Supabase Database
- **測試內容**: 測試資料庫查詢功能
- **預期結果**: 
  - 如果已登入：查詢成功
  - 如果未登入：顯示「資料庫可用（需要登入）」
- **失敗原因**:
  - `tasks` 表不存在
  - RLS 政策配置錯誤
  - 資料庫權限問題

#### 4. Supabase Storage
- **測試內容**: 測試檔案存儲服務
- **預期結果**: 找到 `submissions` bucket
- **失敗原因**:
  - `submissions` bucket 未創建
  - Storage 服務未啟用
  - 權限配置錯誤

### n8n 測試

#### 5. n8n 基礎連接
- **測試內容**: 測試是否能連接到 n8n 伺服器
- **預期結果**: 連接成功（即使端點不存在）
- **失敗原因**:
  - n8n 伺服器未啟動
  - `N8N_BASE_URL` 配置錯誤
  - 網路連接問題

#### 6. generate-tasks webhook
- **測試內容**: 測試任務生成 API
- **預期結果**: 成功生成測試任務
- **失敗原因**:
  - Webhook 未啟用或配置錯誤
  - n8n workflow 未啟動
  - API 回應格式錯誤

#### 7. review-submission webhook
- **測試內容**: 測試提交審核 API
- **預期結果**: 成功完成審核測試
- **失敗原因**:
  - Webhook 未啟用或配置錯誤
  - n8n workflow 未啟動
  - API 回應格式錯誤

---

## ✅ 預期測試結果

### 理想情況（所有服務正常）

```
測試結果摘要: 7 / 7 項測試通過 ✅

✅ Supabase 基礎連接 - 連接成功 (0.15s)
✅ Supabase Auth - 未登入（正常狀態） (0.08s)
✅ Supabase Database - 資料庫可用（需要登入） (0.12s)
✅ Supabase Storage - Storage 可用 (0.20s)
✅ n8n 基礎連接 - 連接成功 (0.05s)
✅ generate-tasks webhook - Webhook 正常運作 (0.85s)
✅ review-submission webhook - Webhook 正常運作 (0.65s)
```

### n8n 未啟動（部分服務可用）

```
測試結果摘要: 4 / 7 項測試通過 ⚠️

✅ Supabase 基礎連接 - 連接成功
✅ Supabase Auth - 未登入（正常狀態）
✅ Supabase Database - 資料庫可用（需要登入）
✅ Supabase Storage - Storage 可用
❌ n8n 基礎連接 - 連接失敗
❌ generate-tasks webhook - Webhook 調用失敗
❌ review-submission webhook - Webhook 調用失敗
```

**解決方法**: 啟動 n8n 伺服器
```bash
cd /Users/neven/Documents/projects/kantoku
docker-compose up -d
# 或
npm run n8n:start
```

### Supabase 配置錯誤

```
測試結果摘要: 0 / 7 項測試通過 ❌

❌ Supabase 基礎連接 - 連接失敗
❌ Supabase Auth - Auth 服務錯誤
❌ Supabase Database - 資料庫查詢失敗
❌ Supabase Storage - Storage 服務錯誤
...
```

**解決方法**: 檢查 `Config.local.xcconfig` 配置
1. 確認 `SUPABASE_URL` 正確
2. 確認 `SUPABASE_ANON_KEY` 正確
3. 在 Xcode 中 Clean Build Folder (`Cmd + Shift + K`)
4. 重新 Build (`Cmd + B`)

---

## 🔧 常見問題

### 問題 1: Build 失敗 - "No such module 'Supabase'"

**原因**: Supabase Swift SDK 未正確安裝

**解決方法**:
1. 在 Xcode 中，選擇 `File` > `Add Package Dependencies...`
2. 輸入 URL: `https://github.com/supabase/supabase-swift.git`
3. 版本選擇 `2.0.0` 或更高
4. 確保在 Target 中勾選了 `Supabase` 產品
5. Clean Build Folder (`Cmd + Shift + K`)
6. 重新 Build (`Cmd + B`)

### 問題 2: 環境變數讀取失敗

**錯誤訊息**: "Supabase configuration not found in Info.plist"

**解決方法**:
1. 確認 `Config.local.xcconfig` 存在
2. 確認檔案內容格式正確：
   ```xcconfig
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   N8N_BASE_URL = http://localhost:5678
   ```
3. 在 Xcode 中，選擇 Project > Info 標籤
4. 在 Configurations 區段，確認：
   - Debug 使用 `Config`
   - Release 使用 `Config`
5. Clean Build Folder 並重新 Build

### 問題 3: 所有 Supabase 測試失敗

**可能原因**:
1. Supabase 專案未啟用或已暫停
2. API Key 過期或無效
3. 網路連接問題

**解決方法**:
1. 登入 Supabase Dashboard: https://app.supabase.com
2. 確認專案狀態為 "Active"
3. 檢查 API Keys 是否正確
4. 測試網路連接：
   ```bash
   curl https://your-project.supabase.co
   ```

### 問題 4: 所有 n8n 測試失敗

**可能原因**:
1. n8n 伺服器未啟動
2. Webhook 端點未配置
3. 防火牆阻擋本地連接

**解決方法**:
1. 啟動 n8n:
   ```bash
   docker-compose up -d
   ```
2. 檢查 n8n 是否運行:
   ```bash
   curl http://localhost:5678
   ```
3. 在瀏覽器中打開 http://localhost:5678
4. 確認 webhooks 已啟用

### 問題 5: Storage 測試失敗 - "submissions bucket 不存在"

**解決方法**:
1. 登入 Supabase Dashboard
2. 進入 Storage 區段
3. 創建名為 `submissions` 的 bucket
4. 設定為 Private
5. 配置 RLS Policies（參考 [CONFIGURATION_COMPLETE.md](./CONFIGURATION_COMPLETE.md)）

### 問題 6: 模擬器無法連接到 localhost

**原因**: iOS 模擬器無法直接訪問 `localhost`

**解決方法**:

選項 1: 使用 `127.0.0.1` 替代 `localhost`
```xcconfig
N8N_BASE_URL = http://127.0.0.1:5678
```

選項 2: 使用真實 IP 地址
```bash
# 查看本機 IP
ifconfig | grep "inet "
```
然後在 `Config.local.xcconfig` 中使用該 IP：
```xcconfig
N8N_BASE_URL = http://192.168.1.100:5678
```

選項 3: 使用 ngrok 暴露本地服務
```bash
ngrok http 5678
```
然後使用 ngrok 提供的 URL。

---

## 📊 進階測試

### 測試認證流程

1. 在應用中註冊新帳號
2. 查看 `Supabase Auth` 測試結果
3. 應該顯示用戶 ID

### 測試資料庫查詢

1. 登入帳號後
2. 重新執行測試
3. `Supabase Database` 測試應該能成功查詢 tasks 表

### 測試 Storage 上傳

可以使用 `StorageService` 進行測試：

```swift
// 在測試視圖中添加上傳測試按鈕
Button("測試上傳") {
    Task {
        let testData = "Hello, Supabase!".data(using: .utf8)!
        let userId = try await SupabaseService.shared.currentUserId ?? UUID()
        let fileName = "test_\(Date().timeIntervalSince1970).txt"
        
        let url = try await StorageService.shared.uploadFile(
            data: testData,
            fileName: fileName,
            userId: userId,
            contentType: "text/plain"
        )
        
        print("上傳成功: \(url)")
    }
}
```

---

## 🎯 下一步

測試通過後，你可以：

1. **開發 Phase 6**: Progress & Statistics
   - 整合 Swift Charts
   - 實作假名進度追蹤
   - 統計圖表視覺化

2. **開發 Phase 7**: Testing & Quizzes
   - 實作測驗生成界面
   - 整合 AI 批改功能

3. **完善現有功能**
   - 添加錯誤處理
   - 優化用戶體驗
   - 增加單元測試

4. **真機測試**
   - 在 iPhone 上安裝並測試
   - 測試相機、麥克風權限
   - 測試錄音和圖片上傳功能

---

## 📚 相關文檔

- [DEVELOPMENT_PROGRESS.md](./DEVELOPMENT_PROGRESS.md) - 開發進度總覽
- [CONFIGURATION_COMPLETE.md](./CONFIGURATION_COMPLETE.md) - 環境配置詳情
- [iOS_PLAN.md](./iOS_PLAN.md) - 開發路線圖
- [../Supabase/SCHEMA.md](../Supabase/SCHEMA.md) - 資料庫結構
- [../../n8n-workflows/WORKFLOW_DESIGN.md](../../n8n-workflows/WORKFLOW_DESIGN.md) - n8n Workflow 設計

---

## 💡 提示

- 測試視圖可以在開發環境中隨時訪問，方便調試
- 建議在每次修改 Supabase 或 n8n 配置後執行測試
- 測試結果會顯示執行時間，幫助識別性能問題
- 展開詳細資訊可以查看完整的錯誤訊息，便於調試

---

**祝測試順利！** 🚀

如有問題，請參考 [常見問題](#常見問題) 或查看相關文檔。
