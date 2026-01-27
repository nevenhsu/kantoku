# Kantoku iOS App UI 規劃 - 總覽

## 專案概述
Kantoku（監督）是一款日文學習 iOS 應用，扮演使用者的「嚴格專案經理」角色，透過漸進式學習系統幫助使用者學習 50 音與日文單字。

## 技術需求
- **最低 iOS 版本**: iOS 16.0
- **目標設備**: iPhone（優先），iPad 暫不支援
- **主要框架**: SwiftUI, Combine
- **後端服務**: Supabase (Auth, Database, Storage)
- **依賴套件**: 
  - Supabase Swift SDK
  - Swift Charts (iOS 16.0+)
- **網路請求**: async/await
- **資料同步策略**: 輪詢 (Polling)，每 2-5 秒檢查一次審核結果

## 設計原則
- **簡潔直觀**：減少學習曲線，專注於學習本身
- **嚴格但友善**：作為「監督者」角色，提供清晰的目標與即時反饋
- **進度可視化**：隨時展示學習進度與成就
- **沉浸式學習**：減少干擾，專注於當前任務

## 色彩系統

### Light Mode
```
主色調 (Primary):
- 深藍色 #1A237E (代表專業與學習)
- 輔助色 #3F51B5 (按鈕與重點)

次要色 (Secondary):
- 橘色 #FF6F00 (警告與提示)
- 綠色 #2E7D32 (成功與完成)
- 紅色 #C62828 (錯誤與失敗)

背景色 (Background):
- 淺灰 #F5F5F5 (主背景)
- 白色 #FFFFFF (卡片背景)

文字色:
- 主文字 #212121
- 次要文字 #757575
- 禁用文字 #BDBDBD
```

### Dark Mode
```
主色調 (Primary):
- 淺藍色 #5C6BC0 (提高對比度)
- 輔助色 #7986CB (按鈕與重點)

次要色 (Secondary):
- 橘色 #FF9800 (警告與提示)
- 綠色 #66BB6A (成功與完成)
- 紅色 #EF5350 (錯誤與失敗)

背景色 (Background):
- 深灰 #121212 (主背景)
- 卡片背景 #1E1E1E (卡片背景)
- 深藍灰 #263238 (強調背景)

文字色:
- 主文字 #FFFFFF
- 次要文字 #B0B0B0
- 禁用文字 #6E6E6E
```

## 字體系統
```
標題: SF Pro Display
- H1: 28pt, Bold
- H2: 24pt, Semibold
- H3: 20pt, Semibold

內文: SF Pro Text
- Body: 17pt, Regular
- Caption: 14pt, Regular
- Small: 12pt, Regular

假名/日文: 字體回退順序
- 優先: Hiragino Sans (系統內建)
- 次要: Noto Sans JP (若需額外下載)
- 回退: System Default
- 50音顯示: 48pt, Medium
- 單字顯示: 32pt, Regular
```

## 主要畫面架構

### Tab Bar 結構
```
5 個 Tabs:
1. Dashboard (首頁圖標) - 今日任務與進度概覽
2. Tasks (任務圖標) - 任務列表與詳情
3. Progress (圖表圖標) - 學習進度追蹤
4. Tests (測驗圖標) - 階段性測驗
5. Profile (個人圖標) - 個人設定
```

## 文件索引

本 UI 規劃文件分為以下幾個部分：

1. **ui_flow_01_overview.md** (本文件)
   - 專案概述
   - 設計原則
   - 色彩與字體系統
   - 主要畫面架構

2. **ui_flow_02_auth_onboarding.md**
   - 啟動畫面
   - 登入/註冊流程
   - 引導流程

3. **ui_flow_03_dashboard_tasks.md**
   - Dashboard 首頁設計
   - 任務列表
   - 任務詳情（50音學習、複習、單字、外部資源）

4. **ui_flow_04_submission_review.md**
   - 文字提交
   - 音訊提交
   - 圖片提交
   - AI 審核結果顯示

5. **ui_flow_05_progress.md**
   - 進度總覽
   - 50音進度網格
   - 單字進度列表
   - 學習統計圖表

6. **ui_flow_06_tests.md**
   - 測驗列表
   - 測驗說明
   - 測驗進行
   - 測驗報告

7. **ui_flow_07_profile.md**
   - 個人資料頁面
   - 學習設定
   - 通知設定
   - 其他設定選項

8. **ui_flow_08_components.md**
   - 通用元件庫
   - 按鈕樣式
   - 輸入框樣式
   - 卡片樣式
   - 載入/錯誤/空狀態

9. **ui_flow_09_animations_responsive.md**
   - 動畫與轉場效果
   - 響應式設計
   - 無障礙設計
   - 效能考量

10. **ui_flow_10_implementation.md**
    - 實作優先順序
    - 設計資源
    - 下一步建議

## 設計理念

### 學習專注
- 減少不必要的視覺干擾
- 清晰的視覺層級
- 重要資訊突出顯示

### 進度可視化
- 使用進度環、進度條等視覺元素
- 清晰的狀態標示（學習中、已掌握等）
- 成就感回饋（Streak、徽章、Confetti）

### 監督者角色
- 專業的藍色調
- 嚴格但不冷酷的 AI 反饋用語
- 明確的目標與期望設定
- 即時的審核反饋

### 漸進式引導
- Onboarding 說明核心概念
- 首次使用提示
- 上下文相關的幫助訊息
- 清晰的錯誤訊息與操作建議

## 技術考量

### SwiftUI 元件
- 充分利用 iOS 16+ 的 SwiftUI 特性
- 使用系統元件為主（NavigationStack, TabView 等）
- 自訂元件保持一致性

### 資料綁定
- 使用 @State, @ObservedObject, @EnvironmentObject
- Combine 處理非同步資料流
- 資料同步策略：輪詢 (Polling) 為主
  * 審核結果：初始 2 秒輪詢，遞增至 5 秒，最長 60 秒
  * 任務列表：下拉刷新或頁面重新進入時更新
  * 進度資料：完成任務後立即更新
- Supabase Realtime（未來優化選項，目前 Swift SDK 支援有限）

### 效能優化
- LazyVStack/LazyHStack 延遲載入
- 圖片快取策略
- 分頁載入大量資料
- Skeleton Screen 提升感知速度

---

**下一步：** 請參考各個子文件了解詳細的畫面設計規劃。
