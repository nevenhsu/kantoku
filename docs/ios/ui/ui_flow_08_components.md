# UI Flow 08 - 通用元件

## 1. 導覽列 (Navigation Bar)

### 標準導覽列
- NavigationStack 包裹
- 標題設定：.navigationTitle("標題")
- 顯示模式：.large（大標題）或 .inline（小標題）

### 工具列按鈕
- Leading: 左上角（返回/取消）
- Trailing: 右上角（操作按鈕）
- 使用 .toolbar + ToolbarItem

### 自訂返回按鈕
- .navigationBarBackButtonHidden(true)
- 自訂 Leading ToolbarItem
- HStack: 箭頭圖標 + "返回" 文字

---

## 2. 按鈕樣式 (Button Styles)

### Primary Button
- 背景：主色調藍色
- 文字：白色，Headline
- 圓角：12pt，高度：50pt (保持一致性)
- 點擊效果：Scale 0.95
- 使用：登入、提交等主要操作

### Secondary Button
- 背景：透明
- 外框：藍色 2pt
- 文字：藍色，Headline
- 圓角：12pt，高度：50pt
- 點擊效果：Scale 0.95
- 使用：次要操作

### Tertiary Button
- 背景：透明
- 文字：次要文字色
- 無外框
- 點擊效果：Opacity 0.6
- 使用：輔助性連結

### Danger Button
- 背景：紅色
- 文字：白色，Headline
- 圓角：12pt，高度：50pt
- 使用：刪除、登出等危險操作

### Icon Button
- 圖標：Title2
- 框架：44x44（圓形）
- 背景：主色 0.1
- 使用：單一圖標操作

---

## 3. 輸入框樣式 (Text Field Styles)

### 標準輸入框
- Label：Subheadline，次要色
- TextField + 圖標（可選）
- 背景：白色
- 外框：灰色 1pt（Focus 時藍色）
- 圓角：8pt，高度：48pt
- Padding：12pt

### 帶驗證的輸入框
- 即時驗證
- 錯誤時：紅色外框
- 錯誤訊息：Caption，紅色，驚嘆號圖標

### 密碼輸入框
- SecureField / TextField 切換
- 鎖頭圖標（左側）
- 眼睛圖標按鈕（右側，切換顯示）

### 多行文字輸入框
- TextEditor（最小高度 120pt）
- Placeholder（ZStack 定位）
- 字數統計（右下角）
- 圓角 8pt，外框 1pt

### 搜尋框
- HStack: 放大鏡圖標 + TextField + 清除按鈕
- 背景：淺灰色
- 圓角：10pt
- Padding：10pt

---

## 4. 卡片樣式 (Card Styles)

### 標準卡片
- 背景：白色
- 圓角：12pt
- Shadow：radius 4, y 2, opacity 0.1
- Padding：16pt
- 間距：12pt

### 小型卡片
- 圓角：8pt
- Shadow：radius 2, y 1
- Padding：12pt

### 強調卡片
- 漸層背景
- 白色文字
- 較大 Shadow：radius 8, y 4, opacity 0.15

### 可點擊卡片
- Button 包裹
- 點擊效果：Scale 0.98
- 使用：任務卡片、推薦卡片等

---

## 5. 載入狀態 (Loading States)

### 小型載入指示器
- ProgressView（CircularProgressViewStyle）
- 預設樣式

### 頁面載入覆蓋層
- ZStack 全螢幕
- 背景：黑色 0.4 opacity
- 中央：Spinner + 訊息文字
- VStack，淺灰色背景，圓角 16pt

### AI 審核中動畫
- "person.fill.badge.sparkles" 圖標（60pt）
- Scale 動畫（1.0 ← → 1.2，重複）
- "監督者審核中..." 文字
- ProgressView

### Skeleton Screen
- 矩形填充（漸層：灰色 0.3 → 0.1 → 0.3）
- 左右移動動畫：`gradient.frame(width: skeletonWidth * 2)`，相對位移
- 圓角 8pt
- 用於：卡片、列表項目

---

## 6. 錯誤狀態 (Error States)

### 錯誤訊息橫幅
- HStack: 警告圖標 + 訊息 + 關閉按鈕
- 背景：紅色
- 文字：白色
- 圓角：12pt，shadow
- 動畫：從上方滑入，3 秒後自動消失

### 錯誤頁面
- VStack: 警告圖標（60pt，紅色）+ "發生錯誤" + 錯誤描述 + "重試" 按鈕
- 置中顯示

### 網路錯誤提示
- "wifi.slash" 圖標（50pt，橘色）
- "網路連線異常" + "請檢查網路設定後重試"
- "重試" 按鈕

---

## 7. 空狀態 (Empty States)

### 標準空狀態
- VStack: 圖標（60pt，灰色）+ 標題 + 描述 + 操作按鈕（可選）
- 置中顯示

### ContentUnavailableView (iOS 17+)
- 系統元件
- 圖標 + 標題 + 描述 + 操作按鈕
- **iOS 16 相容**：自訂 `EmptyStateView` 元件
  * VStack: Image/Icon + Title + Description + Button
- 使用：無任務、無單字等

---

## 8. 對話框 (Alerts & Modals)

### Alert 確認對話框
- .alert() modifier
- 標題 + 訊息
- 按鈕：確認（可選 destructive）+ 取消

### ConfirmationDialog 操作列表
- .confirmationDialog() modifier
- 標題 + 訊息（可選）
- 多個操作按鈕 + 取消按鈕 (role: .cancel)
- 從底部彈出

### Sheet 全螢幕 Modal
- .sheet() modifier
- NavigationStack 包裹
- 工具列：右上角關閉按鈕
- 可設定 .presentationDetents（medium, large）

### FullScreenCover
- .fullScreenCover() modifier
- 全螢幕覆蓋
- 用於：Onboarding

---

## 9. Toast 提示

### Toast 元件
- HStack: 圖標 + 訊息
- 背景：根據類型（成功：綠色，錯誤：紅色，資訊：藍色）
- 文字：白色
- 圓角：12pt，shadow
- 動畫：從上方滑入（距離 Safe Area Top + 10pt），3 秒後消失（長訊息 4 秒）

### 類型
- Success: "checkmark.circle.fill"，綠色
- Error: "xmark.circle.fill"，紅色
- Info: "info.circle.fill"，藍色

---

## 10. 標籤與徽章 (Tags & Badges)

### 標籤
- Text，Caption
- Padding：10pt x 4pt
- 背景：顏色 0.2
- 文字：顏色
- 圓角：8pt

### 徽章
- Text，Caption2, Bold
- 圓形背景（最小 20x20）
- 背景：紅色
- 文字：白色
- 用於：通知數量

### 狀態徽章
- Text + 背景色（根據狀態）
- Padding：8pt x 4pt
- 圓角：6pt
- 用於：任務狀態、學習狀態等

---

## 11. 其他通用元件

### ProgressRing (進度環)
- 用於：分數、階段進度
- 參數：progress (0-1), lineWidth, color
- ZStack: 
  * 背景圓 (opacity 0.2)
  * 前景圓 (trim 0...progress, rotation -90)

### KanaCard (假名卡片)
- 用於：學習、列表展示
- 參數：kana, romaji, type, action
- 樣式：大字 + 羅馬拼音 + 發音按鈕

---

## 設計注意事項

### 一致性
- 統一的圓角（8pt/12pt/16pt）
- 統一的 Padding（12pt/16pt）
- 統一的 Shadow 效果

### 觸控目標
- 最小 44x44 pt
- 按鈕間距 ≥ 8pt

### 反饋
- 點擊有視覺反饋（Scale/Opacity）
- Loading 狀態明確
- 錯誤訊息清晰
