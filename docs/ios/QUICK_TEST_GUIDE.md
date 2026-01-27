# 快速測試指南

**目標**: 在 Xcode 中 Build 並測試 Supabase 連接

---

## ⚡ 5 分鐘快速開始

### 1️⃣ 打開項目
```bash
open ios/kantoku.xcodeproj
```

### 2️⃣ 確認配置
- 檢查 `Resources/Config.local.xcconfig` 存在
- 檢查 `Package Dependencies` 有 `supabase-swift`

### 3️⃣ Build & Run
- 選擇 iPhone 15 Pro 模擬器
- 點擊 ▶️ 或按 `Cmd + R`

### 4️⃣ 執行測試
- 應用啟動後會顯示測試視圖
- 點擊「開始測試」按鈕
- 查看測試結果

### 5️⃣ 關閉測試模式
- 點擊右上角「關閉測試」按鈕
- 或在代碼中設定 `showTestView = false`

---

## ✅ 預期結果

### 全部通過（理想情況）
```
7 / 7 項測試通過 ✅
- Supabase 基礎連接 ✅
- Supabase Auth ✅
- Supabase Database ✅
- Supabase Storage ✅
- n8n 基礎連接 ✅
- generate-tasks webhook ✅
- review-submission webhook ✅
```

### n8n 未啟動
```
4 / 7 項測試通過 ⚠️
- Supabase 測試全部通過 ✅
- n8n 測試失敗 ❌
```

**解決**: 啟動 n8n
```bash
docker-compose up -d
```

---

## 🔧 快速除錯

### Build 失敗: "No such module 'Supabase'"
1. `File` > `Add Package Dependencies...`
2. URL: `https://github.com/supabase/supabase-swift.git`
3. 版本: `2.0.0+`
4. `Cmd + Shift + K` (Clean)
5. `Cmd + B` (Build)

### 環境變數讀取失敗
1. 確認 `Config.local.xcconfig` 存在並包含：
   ```xcconfig
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = eyJhbGci...
   N8N_BASE_URL = http://localhost:5678
   ```
2. Clean Build Folder
3. 重新 Build

### Storage 測試失敗
1. 登入 Supabase Dashboard
2. 創建 `submissions` bucket
3. 設定為 Private
4. 配置 RLS Policies

---

## 📱 測試模式控制

### 方法 1: 應用內關閉
點擊測試視圖右上角的「關閉測試」按鈕

### 方法 2: 代碼控制
編輯 `kantokuApp.swift`:
```swift
@AppStorage("showTestView") private var showTestView = false // 改為 false
```

### 方法 3: 模擬器重置
在 Simulator 中刪除應用，重新安裝

---

## 📚 完整文檔

詳細說明請參考: [TESTING_GUIDE.md](./TESTING_GUIDE.md)

---

## 🎯 測試完成後

- [x] Supabase 連接正常
- [x] n8n Webhooks 正常
- [ ] 繼續開發 Phase 6: Progress & Statistics
- [ ] 繼續開發 Phase 7: Testing & Quizzes

---

**測試愉快！** 🚀
