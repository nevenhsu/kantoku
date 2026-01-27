# UI Flow 03 - Dashboard 與任務

## 1. Dashboard (首頁)

### 整體架構
- NavigationStack 包裹
- ScrollView 可滾動內容
- VStack 垂直排列區塊（spacing: 20pt）
- 左右 padding: 16pt
- 導覽標題："Kantoku"，inline 模式（或自訂 Header）

### 區塊組成
1. Header Section（上方區塊）
2. Today's Tasks Section（今日任務區塊）
3. Quick Stats Section（快速統計區塊）
4. Recommendations Section（學習建議區塊）

---

### 1.1 上方區塊 (Header Section)

**佈局：** HStack，對齊頂部，spacing 16pt

**左側：**
- 頭像：56x56 pt，圓形
- 顯示名稱：Headline 字體
- 當前階段："あ行學習中" - Caption，次要色

**右側：**
- Streak 火焰圖標 + 天數
- 文字："7 天" - Title3, Bold，橘色
- 說明："連續學習" - Caption，次要色

**背景：**
- 漸層背景（藍色 opacity 0.1 → 0.05）
- 圓角 16pt
- 整體 padding

**今日學習時間進度條：**
- 標題："今日學習時間" + "15/30 分鐘"
- ProgressView（綠色），高度 8pt，圓角 4pt
- 白色背景卡片，圓角 12pt，shadow

---

### 1.2 今日任務區塊 (Today's Tasks Section)

**標題列：**
- "今日任務" - Title2, Bold
- 跳過次數標籤："2/2" - 橘色背景，圓角 8pt

**任務卡片列表：**
- 最多顯示 3 個任務
- 每個卡片包含：
  * 左側彩色邊條（4pt 寬，根據狀態）
    - Pending: 藍色
    - Passed: 綠色
    - Failed: 紅色
  * 任務圖標（44x44 pt，圓角 8pt，狀態色背景）
  * 任務內容：
    - 標題（Headline）
    - 簡述（Subheadline，次要色，最多 2 行）
  * 狀態標籤（右側）
  * 右箭頭圖標（次要色）

**任務類型圖標：**
- kana_learn: "text.book.closed"
- kana_review: "arrow.clockwise"
- vocabulary: "book.fill"
- external_resource: "play.rectangle.fill"

**狀態標籤樣式：**
- Pending: "待完成" - 藍色背景 0.1 opacity + 藍色文字
- Submitted: "審核中" - 橘色
- Passed: "已通過" - 綠色
- Failed: "需改進" - 紅色
- Caption 字體，padding 8pt x 4pt，圓角 6pt

**卡片樣式：**
- 白色背景，圓角 12pt
- Shadow（radius: 4）
- Padding: 16pt
- 間距: 12pt

**互動：**
- 點擊卡片 → 進入任務詳情
- 長按顯示 Context Menu → "跳過任務"（需確認對話框）

**空狀態：**
- 綠色勾選圖標（60pt）
- "今日任務已完成！" - Headline
- "休息一下或前往進度查看學習成果" - Subheadline，次要色，置中
- 垂直 padding 40pt

---

### 1.3 快速統計區塊 (Quick Stats Section)

**佈局：** HStack，3 個等寬卡片

**卡片 1 - 平假名進度：**
- 圖標/文字："あ" - 32pt
- 進度環（40x40，藍色，線寬 6pt）
- 數值："42/46 已掌握" - Headline
- 標題："平假名" - Caption，次要色

**卡片 2 - 片假名進度：**
- 圖標/文字："ア" - 32pt
- 進度環（40x40，紫色，線寬 6pt）
- 數值："12/46 已掌握"
- 標題："片假名"

**卡片 3 - 單字量：**
- 圖標："📚" - 32pt
- 數值："85 個單字" - Headline
- 趨勢箭頭：↗（綠色/紅色）
- 標題："單字量"

**卡片樣式：**
- 淺色背景 #FAFAFA
- 圓角 12pt
- Padding
- 等寬分布（maxWidth: .infinity）

---

### 1.4 學習建議區塊 (Recommendations Section)

**標題：** "為你推薦" - Title2, Bold

**推薦卡片：**
- 1-2 個推薦項目
- 每個卡片包含：
  * 圖標（50x50，圓角 10pt，顏色背景）
  * 標題："加強練習：さ行假名" - Subheadline, Bold
  * 描述："你在 さ、す 的發音還需要加強" - Caption，次要色，最多 2 行
  * 右箭頭

**推薦類型：**
- 練習建議：橘色，"waveform" 圖標
- 新單字推薦：黃色，"sun.max.fill" 圖標
- 外部資源：藍色，"play.rectangle.fill" 圖標

**卡片樣式：**
- 白色背景，圓角 12pt，shadow

---

## 2. Tasks (任務列表)

### 整體架構
- NavigationStack
- VStack（spacing: 0）
  * 頂部過濾器（固定）
  * 任務列表（可滾動）
- 導覽標題："任務"

---

### 2.1 頂部過濾器

**Segment Control：**
- 3 個選項："今日" | "待完成" | "已完成"
- 預設樣式
- Padding

**日期選擇器（可選）：**
- Calendar 圖標按鈕
- 點擊展開 DatePicker（graphical 樣式）

---

### 2.2 任務列表 (Task List)

**分組顯示：**
- 今日任務（section）
- 逾期任務（紅色標記，section）
- 已完成任務（僅在"已完成"過濾時顯示）

**Section Header：**
- 標題 - Headline
- 逾期顯示驚嘆號圖標（紅色）
- 任務數量 - Caption，次要色

**任務卡片：**
- 類型圖標 + 標題（Headline）
- 內容預覽（Subheadline，次要色，最多 2 行）
- 底部列：
  * 截止日期（Calendar 圖標 + 日期，Caption）
  * 操作按鈕（根據狀態）

**操作按鈕樣式：**
- Pending: "開始練習" - Bordered Prominent
- Submitted: "審核中..." - Bordered（禁用）
- Passed: "查看反饋" - Bordered
- Failed: "重新提交" - Bordered Prominent（橘色）

**Swipe Actions：**
- Pending 狀態：左滑顯示 "跳過"（紅色，需確認）

**互動：**
- 點擊卡片 → 進入任務詳情
- 下拉刷新列表
- 左滑操作選單

**空狀態：**
- ContentUnavailableView
- 圖標："checklist"
- 標題："暫無任務"
- 描述："系統將每日生成新任務"

---

## 3. 任務詳情畫面

### 3.1 Kana Learn (50 音學習)

**導覽列：** "學習 さ行"（inline 模式）

**假名展示區：**
- 每個假名一個卡片：
  * 大型假名顯示：72pt, Medium
  * 羅馬拼音：Title3，次要色
  * 發音按鈕：Bordered，"speaker.wave.2.fill" 圖標
  * 筆順動畫（可選，200pt 高）
- 淺色背景 #FAFAFA，圓角 16pt，padding

**練習區：**
- 標題："練習方式" - Headline
- 3 個練習按鈕：
  * "聽寫練習" - "ear" 圖標，"聽發音，寫出假名"
  * "拼寫練習" - "character.cursor.ibeam" 圖標，"看假名，輸入羅馬拼音"
  * "發音練習" - "waveform" 圖標，"錄製你的發音"

**相關單字列表：**
- 標題："相關單字"
- 使用此假名的單字列表（顯示最多 5 個，更多可展開）
- 點擊展開單字詳情

---

### 3.2 Kana Review (複習)

**導覽列：** "複習 あ行-さ行"

**頂部進度條：**
- "複習 あ行-さ行" + "3/10"（Headline + Subheadline）
- ProgressView（藍色）
- 背景色，padding，shadow

**題目區：**
- 題型 1（顯示假名 → 輸入羅馬拼音）：
  * 大型假名："あ" - 80pt
  * 說明："這個假名的羅馬拼音是？" - Subheadline
  
- 題型 2（播放發音 → 選擇假名）：
  * 播放按鈕（Bordered Prominent，大型）
  * 4 個選項按鈕
  
- 題型 3（顯示羅馬拼音 → 寫出假名）：
  * "sa" - Title
  * 說明："請寫出對應的假名"

**答題區：**
- 輸入框（Title3，rounded border）
- 或 4 個選項按鈕（圓角 12pt，選中時藍色邊框）

**底部按鈕：**
- "提交答案" - Primary Button
- "跳過" - Secondary Button

**互動：**
- 即時驗證
- 顯示正確/錯誤反饋（綠色勾選/紅色叉叉）
- 累積分數
- 完成後顯示總結

---

### 3.3 Vocabulary (單字學習)

**佈局：** TabView（page 樣式）左右滑動

**單字卡片：**
- 假名 + 漢字（48pt/36pt，Medium）
- 羅馬拼音（Title3，次要色）
- 發音按鈕（圓形，Bordered Prominent）
- 中文意思（Title3，藍色背景 0.1，圓角 12pt，padding）
- 例句區（淺色背景，圓角 12pt）：
  * 日文例句 - Body
  * 中文翻譯 - Caption，次要色
- 記憶提示（可選）

**學習工具（底部）：**
- HStack 3 個按鈕：
  * "加入複習" - "bookmark" 圖標
  * "聽寫練習" - "pencil" 圖標
  * "造句練習" - "text.bubble" 圖標

**互動：**
- 左右滑動切換單字
- 播放發音
- 標記熟悉度

---

### 3.4 External Resource (外部資源)

**導覽列：** "推薦資源"

**封面圖：**
- AsyncImage，200pt 高，圓角 12pt
- Placeholder: 灰色

**資訊區：**
- 標題：Title2, Bold
- 標籤 HStack：
  * 難度："N5" - 藍色
  * 時長："15 分鐘" - 灰色
  * 主題標籤 - 綠色
- 描述：Body，次要色

**操作按鈕：**
- "開啟連結" - Bordered Prominent，"link" 圖標
- "標記為已完成" - Bordered，"checkmark.circle" 圖標

**互動：**
- 開啟外部連結（Safari View Controller）
- 標記完成
- 提交學習筆記（可選）

---

## 設計注意事項

### 卡片一致性
- 所有卡片使用統一圓角（12pt）
- 統一 shadow 效果
- 統一 padding（16pt）

### 狀態視覺化
- 使用顏色 + 圖標雙重標示
- 避免只靠顏色區分（色盲友善）

### 互動反饋
- 點擊有 scale 動畫（0.95）
- Loading 狀態明確
- 錯誤訊息清晰

### 效能
- 使用 LazyVStack 延遲載入
- 圖片快取
- 音訊預載

---

## 4. 關鍵機制說明

### 4.1 Streak 機制

**計算邏輯：**
- 每日 00:00 UTC 檢查前一天是否有學習活動
- 學習活動定義：完成至少 1 個任務（passed 或 submitted）

**更新時機：**
- 首次登入當天時更新（檢查昨日）
- 完成任務時更新 last_activity_at

**中斷條件：**
- 連續 24 小時無任何學習活動
- 次日首次登入時發現前日無活動 → streak_days = 0

**UI 表現：**
- Streak 中斷時顯示 Toast：「你的連續學習中斷了！重新開始吧！」
- 新 Streak 從 1 開始計算

### 4.2 跳過任務流程

**跳過限制：**
- 每日可跳過 2 次（skip_remaining 預設為 2）
- 每日 00:00 UTC 重置

**跳過操作：**
1. 長按任務卡片 → Context Menu → "跳過任務"
2. 顯示確認對話框：「確定要跳過嗎？今日剩餘 X 次跳過機會。」
3. 確認後：
   - 任務 status 設為 'skipped'
   - skip_remaining -= 1
   - 顯示 Toast：「任務已跳過」

**跳過後果：**
- 跳過的任務不計入當日完成
- 不影響 Streak（只要有完成其他任務）
- 跳過的假名/單字會在下次任務生成時重新出現

**無跳過次數時：**
- 跳過按鈕顯示為禁用狀態
- 點擊顯示 Toast：「今日跳過次數已用完」

### 4.3 階段進階流程

**進階條件：**
- 當前階段所有假名 mastery_score >= 70
- 該階段里程碑測驗已通過

**進階判斷時機：**
- 每次完成假名學習任務後檢查
- 每次測驗通過後檢查

**進階 UI 表現：**
1. 顯示全螢幕慶祝動畫
2. 標題：「恭喜！你完成了 あ行 學習！」
3. 進度環動畫填滿
4. Confetti 動畫
5. 按鈕：「開始 か行 學習」
6. 震動反饋（Success）

**進階後：**
- user_progress.current_stage_id += 1
- 任務生成開始包含新階段假名
- Dashboard 顯示新階段名稱
