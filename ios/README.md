# Kantoku iOS App

日文學習 iOS 應用程式 - 您的嚴格日語學習監督者

## 專案概述

Kantoku（監督）是一款採用 SwiftUI 開發的日文學習 iOS 應用，透過 AI 輔助和間隔重複系統幫助使用者掌握日語 50 音與基礎單字。

## 技術棧

- **iOS**: 16.0+
- **框架**: SwiftUI
- **架構**: MVVM
- **後端**: Supabase (Auth, Database, Storage)
- **AI 處理**: n8n Workflows
- **音訊**: AVFoundation

## 快速開始

### 1. 系統需求

- macOS 13.0+
- Xcode 15.0+
- iOS 16.0+ 模擬器或實體設備

### 2. 打開專案

```bash
cd /Users/neven/Documents/projects/kantoku/ios
open kantoku.xcodeproj
```

### 3. 安裝依賴

在 Xcode 中：

1. 點擊 **File > Add Package Dependencies...**
2. 輸入 Supabase Swift SDK URL:
   ```
   https://github.com/supabase/supabase-swift.git
   ```
3. 選擇版本 **2.0.0** 或更高
4. 點擊 **Add Package**

### 4. 配置環境變數

編輯 `kantoku/Resources/Config.xcconfig`:

```xcconfig
SUPABASE_URL = https://your-project.supabase.co
SUPABASE_ANON_KEY = your-anon-key-here
N8N_BASE_URL = http:/$()/localhost:5678
```

### 5. 重新組織文件結構（如果需要）

如果文件在 Xcode Project Navigator 中沒有正確分組：

1. 在 Project Navigator 中手動創建 Groups:
   - App
   - Models
   - Views
   - ViewModels
   - Services
   - Components
   - Utils
   - Resources

2. 將對應的文件拖拽到正確的 Group 中

### 6. 構建並運行

1. 選擇目標設備（模擬器或實體設備）
2. 點擊 **⌘R** 或 **Product > Run**

## 專案結構

```
ios/kantoku/
├── App/                    # 應用入口
│   └── kantokuApp.swift
├── Models/                 # 資料模型
│   ├── User.swift
│   ├── Task.swift
│   ├── Submission.swift
│   ├── Test.swift
│   └── KanaProgress.swift
├── Views/                  # UI 視圖
│   ├── MainTabView.swift
│   ├── DashboardView.swift
│   ├── TasksView.swift
│   ├── ProgressView.swift
│   ├── TestsView.swift
│   └── ProfileView.swift
├── ViewModels/             # 視圖模型（待開發）
├── Services/               # 服務層
│   ├── SupabaseService.swift
│   ├── AuthService.swift
│   ├── APIService.swift
│   └── AudioService.swift
├── Components/             # 可重用組件
│   ├── PrimaryButton.swift
│   ├── StatusBadge.swift
│   ├── InputField.swift
│   └── TaskCard.swift
├── Utils/                  # 工具類
│   └── Constants.swift
└── Resources/              # 資源文件
    ├── Config.xcconfig
    └── Info.plist
```

## 開發進度

- ✅ **Phase 1**: Infrastructure & Foundation
- ✅ **Phase 2**: Core Model & Component Library
- 🔜 **Phase 3**: Authentication & Onboarding
- ⏳ **Phase 4**: Dashboard & Task Management
- ⏳ **Phase 5**: Submission & AI Review
- ⏳ **Phase 6**: Progress & Statistics
- ⏳ **Phase 7**: Testing & Quizzes

詳細進度請參考 [DEVELOPMENT_PROGRESS.md](../docs/ios/DEVELOPMENT_PROGRESS.md)

## 設計系統

### 顏色

**Light Mode**
- Primary: `#1A237E` (深藍)
- Orange: `#FF6F00`
- Green: `#2E7D32`
- Red: `#C62828`

**Dark Mode**
- Primary: `#5C6BC0` (淺藍)
- Orange: `#FF9800`
- Green: `#66BB6A`
- Red: `#EF5350`

### 字體

- **標題**: SF Pro Display (28pt/24pt/20pt)
- **內文**: SF Pro Text (17pt/14pt/12pt)
- **日文**: Hiragino Sans (48pt/32pt)

### 間距

採用 8pt 網格系統: 8, 12, 16, 24, 32, 40

## 常見問題

### Q: 遇到 "No such module 'Supabase'" 錯誤？

**A**: 需要在 Xcode 中添加 Supabase Swift Package。參考上方「安裝依賴」步驟。

### Q: 遇到 "No such module 'UIKit'" 錯誤？

**A**: 這是 LSP 緩存問題，在 Xcode 中構建項目後會自動解決。

### Q: Preview 無法顯示？

**A**: 確保已選擇正確的 iOS 模擬器版本（16.0+），並且 Xcode 已完成索引。

## 相關文檔

- [開發計劃](../docs/ios/iOS_PLAN.md)
- [代碼範例](../docs/ios/iOS_CODE_EXAMPLES.md)
- [UI 設計規範](../docs/ios/ui/)
- [資料庫結構](../docs/Supabase/SCHEMA.md)

## 授權

MIT License

## 聯繫方式

如有問題請提交 Issue 或聯繫開發團隊。
