# UI Flow 07 - 個人設定

## 1. 個人資料頁面 (Profile)

### 整體架構
- NavigationStack，標題："個人設定"
- ScrollView + VStack (spacing: 24pt)

### ProfileCard
- 頭像（100x100，圓形，藍色邊框 3pt）
  * 右下角編輯按鈕（"camera.fill"，藍色圓形背景）
- 顯示名稱：Title2, Bold
- Email：Subheadline，次要色
- "編輯個人資料" 按鈕（Bordered，Small）
- 漸層背景（藍色 0.1 → 0.05），圓角 16pt

### StreakAchievements
- 標題："學習成就" - Headline
- HStack 3 個成就卡片：
  * 連續學習（橘色火焰，"flame.fill"）
  * 本月學習（藍色日曆，"calendar.circle.fill"）
  * 完成任務（綠色勾選，"checkmark.circle.fill"）
- 每個顯示：圖標 + 數值+單位 + 標籤
- 白色背景，圓角 12pt，shadow

### SettingsList
- 多個 Section，每個包含標題 + 設定項列表

**學習設定：**
- 每日目標時間（"clock.fill"，藍色）→ 子頁面
- 提醒時間（"bell.fill"，橘色）→ 子頁面
- 自動生成任務（"sparkles"，紫色）→ Toggle

**通知設定：**
- 任務提醒（"bell.badge.fill"，紅色）→ Toggle
- 審核完成通知（"checkmark.circle.fill"，綠色）→ Toggle
- 每日進度報告（"chart.bar.fill"，藍色）→ Toggle
- 測驗解鎖通知（"trophy.fill"，黃色）→ Toggle

**顯示設定：**
- 深色模式（"moon.fill"，靛藍色）→ 子頁面
- 字體大小（"textformat.size"，灰色）→ 子頁面
- 顯示羅馬拼音（"character.textbox"，紫色）→ Toggle

**資料管理：**
- 匯出學習資料（"square.and.arrow.down"，藍色）
  * 匯出格式：JSON 檔案（包含進度、統計、測驗記錄）
- 清除快取（"trash.fill"，橘色）→ 確認

**關於：**
- 版本資訊（"info.circle.fill"，藍色）→ 點擊檢查更新
- 使用條款（"doc.text.fill"，灰色）→ 開啟 Safari
- 隱私政策（"hand.raised.fill"，灰色）→ 開啟 Safari
- 聯絡我們（"envelope.fill"，綠色）

**帳號：**
- 登出（"rectangle.portrait.and.arrow.right"，紅色文字）
- 刪除帳號（"person.crop.circle.badge.xmark"，紅色文字）

### SettingRow 樣式
- HStack: 圖標（28pt 寬）+ 標題 + Spacer + 值 + 箭頭
- Padding，白色背景
- 項目間 Divider（左側縮排 52pt）

### SettingToggle 樣式
- HStack: 圖標 + 標題 + Spacer + Toggle
- Padding

---

## 2. 每日目標設定 (Daily Goal Settings)

### 整體架構
- NavigationStack，標題："每日目標"，inline 模式
- VStack (spacing: 24pt)

### 內容
- 說明（Headline + Subheadline，次要色）
- 分鐘數顯示（48pt, Bold，藍色，藍色背景 0.1，圓角 16pt）
- Slider（10-120 分鐘，步進 5）
- 預設選項按鈕（15/30/45/60 分鐘，HStack）
- 預覽說明："約等於 X 個任務"
- 建議區（橘色背景 0.1，圓角 12pt）：
  * 新手建議：15-30 分鐘
  * 穩定學習：30-45 分鐘
  * 密集學習：60 分鐘以上
- "儲存" 按鈕（Bordered Prominent，Large）

---

## 3. 提醒時間設定 (Reminder Settings)

### 整體架構
- NavigationStack，標題："學習提醒"
- Form 表單樣式

### Section 1: 提醒時間
- DatePicker（時間選擇，hourAndMinute）

### Section 2: 提醒天數
- Picker："頻率" - 每日/週間/自訂
- 若自訂：7 個 Toggle（週一~週日）

### Section 3: 提醒訊息預覽
- 預覽框（淺色背景，圓角 8pt）
- 說明文字（Caption，次要色）

### Section 4: 測試
- "發送測試通知" 按鈕

### 工具列
- 右上角："儲存" 按鈕

---

## 4. 編輯個人資料 (Edit Profile)

### 整體架構
- NavigationStack，標題："編輯個人資料"
- Form 表單樣式

### Section: 頭像
- 頭像圖片（120x120，圓形，置中）
- 編輯按鈕（右下角，相機圖標）
  * 點擊顯示 ActionSheet: "拍照" | "從相簿選擇"
- 透明背景

### Section: 基本資料
- 顯示名稱 TextField
- Email（只讀，HStack 顯示）

### Section: 學習偏好
- 學習目標 Picker（興趣/旅遊/工作/考試）
- 當前程度 Picker（新手/略懂/基礎會話）

### 工具列
- 左上角："取消" 按鈕
- 右上角："儲存" 按鈕（名稱為空時禁用）

---

## 5. 確認對話框

### 登出確認
- ConfirmationDialog
- 標題："確定要登出嗎？"
- 按鈕："登出"（destructive）| "取消"

### 刪除帳號確認
- Alert："刪除帳號"
- 訊息："刪除帳號後，所有學習資料將永久刪除且無法恢復。"
- TextField："請輸入「DELETE」以確認"
- 按鈕："確定刪除"（destructive，需輸入匹配）| "取消"

### 清除快取確認
- ConfirmationDialog
- 標題："清除快取"
- 訊息："將清除 X MB 的快取資料。"
- 按鈕："清除快取"（destructive）| "取消"

---

## 6. 其他設定頁面

### 外觀設定
- Form
- Picker（Inline 樣式）："跟隨系統" | "淺色模式" | "深色模式"

### 字體大小設定
- VStack
- 預覽文字（動態字體大小）
- Slider（12-24pt，步進 2）
- 大小標示："小" ← → "大"
- "重設為預設" 按鈕

### 關於頁面
- ScrollView + VStack
- App Icon（120x120，圓角 24pt）
- App Name："Kantoku" - Title, Bold
- 版本號 - Subheadline，次要色
- Slogan - Body，次要色
- 資訊列表（開發者、最後更新、Build）
- 特別感謝（VStack，左對齊）

---

## 設計注意事項

### 設定分組
- 清晰的 Section 分類
- 使用圖標增強識別
- 顏色一致性

### 危險操作
- 紅色文字標示
- 二次確認
- 清晰的後果說明

### 表單體驗
- Toggle 即時儲存
- 子頁面需明確儲存
- 錯誤驗證清晰
