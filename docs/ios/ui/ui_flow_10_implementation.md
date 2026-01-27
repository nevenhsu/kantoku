# UI Flow 10 - 實作優先順序與建議

## 實作優先順序

### P0 (必要功能) - MVP

**1. 登入/註冊流程** (3-5 天)
- 啟動畫面、登入、註冊、Onboarding
- Supabase Auth 整合
- Email/Password 驗證
- Session 管理

**2. Dashboard 基礎架構** (4-6 天)
- Tab Bar Navigation
- Dashboard 首頁基本佈局
- Header + 今日任務 + 快速統計
- 使用者資料展示

**3. 任務列表與詳情** (5-7 天)
- 從 Supabase 拉取任務
- 任務卡片展示
- Kana Learn/Review/Vocabulary 詳情頁
- 假名/單字顯示
- 音訊播放

**4. 文字提交與審核** (4-6 天)
- 文字輸入與提交
- 呼叫 n8n webhook
- 輪詢/監聽審核結果
- 顯示 AI 反饋與分數

**5. 50 音進度追蹤** (4-5 天)
- Progress Tab 基礎
- 50音網格展示
- 狀態顏色標示
- 假名詳情 Modal

**總計 P0**: 25-35 天 (約 5-7 週)

---

### P1 (核心功能) - 完整體驗

**6. 音訊錄製與提交** (5-7 天)
- AVFoundation 錄音
- 音訊播放與管理
- 上傳至 Supabase Storage
- 波形動畫

**7. 圖片上傳與提交** (4-6 天)
- PhotosPicker / Camera 整合
- 圖片壓縮與編輯
- 上傳至 Supabase Storage

**8. 測驗系統基礎** (6-8 天)
- 測驗列表與說明
- 測驗進行頁面（計時、題目、答題）
- 測驗報告（簡化版）

**9. 個人設定頁面** (3-4 天)
- Profile 頁面
- 各項設定（目標、提醒、顯示）
- Toggle 設定儲存

**10. 通知系統** (3-4 天)
- 本地通知排程
- 通知權限請求
- 通知點擊處理

**總計 P1**: 21-29 天 (約 4-6 週)

---

### P2 (增強功能) - 體驗優化

**11. 學習統計圖表** (5-6 天)
- Swift Charts 整合
- 學習時間圖表
- Streak 日曆
- 任務完成統計

**12. 弱項分析與建議** (4-5 天)
- 統計錯誤率
- 分析弱項
- 生成複習任務建議

**13. 外部資源整合** (3-4 天)
- YouTube/NHK 連結顯示
- Safari View Controller
- 標記完成

**14. 成就系統** (4-5 天)
- 成就定義與檢查
- 解鎖動畫
- 徽章展示

**15. 社群分享** (2-3 天)
- 生成分享圖片
- ShareSheet 整合

**總計 P2**: 18-23 天 (約 4-5 週)

---

## 技術架構建議

### 專案結構
```
Kantoku/
├── App/
│   ├── KantokuApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Task.swift
│   ├── Submission.swift
│   ├── KanaProgress.swift
│   └── User.swift
├── Views/
│   ├── Auth/
│   ├── Dashboard/
│   ├── Tasks/
│   ├── Progress/
│   ├── Tests/
│   └── Profile/
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── TaskViewModel.swift
│   └── ProgressViewModel.swift
├── Services/
│   ├── SupabaseService.swift
│   ├── AuthService.swift
│   ├── TaskService.swift
│   └── AudioService.swift
├── Components/
│   ├── Common/          # 通用元件 (Loading, Error, Toast)
│   ├── Buttons/
│   ├── Cards/
│   └── TextFields/
├── Utils/
│   ├── Extensions/
│   └── Constants.swift
└── Tests/               # 測試目錄 (新增)
    ├── UnitTests/
    └── UITests/
```

### 依賴管理 (SPM)
- **Supabase**: `github.com/supabase/supabase-swift` (v2.x)
- **Swift Charts**: Apple 內建 (iOS 16+)
- **Testing**: XCTest (內建)

### 版本控制與發布
- **版本號規則**: `Major.Minor.Patch` (例: 1.0.0)
- **Build 號**: 遞增整數 (1, 2, 3...)
- **TestFlight**: 
  * Alpha: `0.x.x` (內部測試)
  * Beta: `1.0.0-beta.x` (外部測試)
  * Release: `1.0.0` (App Store)

### 狀態管理
- **MVVM 架構**
- **ObservableObject** + **@Published**
- **@StateObject** / **@ObservedObject**
- **@EnvironmentObject** 共享資料

### 網路請求
- **async/await** 語法
- **Supabase Swift SDK**
- 統一錯誤處理
- Loading 狀態管理

---

## 設計資源

### Icon 來源
- **SF Symbols**: iOS 系統圖示（免費）
  * 使用 SF Symbols App 瀏覽
  * 支援多種樣式與權重
  * 自動適配 Dynamic Type

### 插圖風格
- **扁平化設計** (Flat Design)
- **簡約線條** (Minimalist Line Art)
- **友善色彩**（柔和的藍、綠、橘）

### 免費資源
- **undraw.co** - 可自訂顏色的插圖
- **storyset.com** - Freepik 插圖
- **absurd.design** - 超現實風格

### 原型工具
- **Figma** (推薦)
  * 線上協作
  * 免費方案足夠
  * Plugin: Iconify, SwiftUI Inspector
- **SwiftUI Previews**
  * 快速迭代
  * 即時預覽
  * 多裝置測試

---

## 測試建議

### 單元測試
- ViewModel 邏輯測試
- Service 層測試
- XCTest 框架

### UI 測試
- 關鍵流程測試（登入、提交、測驗）
- XCUITest 框架
- 自動化截圖

---

## 部署與發布

### TestFlight (Beta 測試)
1. App Store Connect 建立 App
2. 上傳 Build
3. 建立測試群組
4. 邀請測試者
5. 收集反饋

### App Store 上架
1. App Icon (1024x1024)
2. 截圖（各種尺寸）
3. App 描述與關鍵字
4. 隱私政策
5. 提交審核

---

## 開發時程估算

### 單人開發
- **P0 功能**: 4-6 週
- **P1 功能**: 4-6 週
- **P2 功能**: 4-5 週
- **總計**: 約 3-4 個月完成完整功能

### 建議開發順序
1. 先完成 P0 MVP，確保核心流程可用
2. 測試與修正 P0 功能
3. 逐步實作 P1 核心功能
4. 根據使用者反饋優先實作 P2 功能

---

## 關鍵成功因素

### UI/UX
- ✅ 簡潔直觀的介面
- ✅ 流暢的動畫與轉場
- ✅ 清晰的學習進度視覺化

### 技術
- ✅ 穩定的 Supabase 整合
- ✅ 快速的 AI 審核反饋
- ✅ 可靠的離線支援

### 使用者體驗
- ✅ 即時的學習反饋
- ✅ 有效的弱項分析
- ✅ 持續的學習動機

---

## 下一步建議

1. **設計階段**
   - 根據 UI 規劃建立 Figma 原型
   - 確認視覺風格與互動細節
   - 準備所需的圖示與插圖

2. **開發準備**
   - 建立 Xcode 專案
   - 設定 Supabase 整合
   - 實作基礎元件庫

3. **迭代開發**
   - 按 P0 → P1 → P2 順序開發
   - 每個階段進行測試
   - 收集反饋並調整

4. **發布準備**
   - Beta 測試（TestFlight）
   - 修正 Bug 與優化
   - 準備上架資料

---

**祝開發順利！**
