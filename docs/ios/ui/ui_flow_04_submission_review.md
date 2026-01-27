# UI Flow 04 - 提交與審核

## MVP 範圍說明
- **文字提交**：完整 AI 審核 ✅ (P0)
- **直接確認**：完整支援 ✅ (P0)
- **音訊提交**：P1 功能（目前使用直接確認模式，或模擬審核）
- **圖片提交**：P2 功能（暫不實作）

---

## 1. 文字提交 (Text Submission)

### 整體架構
- NavigationStack
- VStack (spacing: 0)
  * QuestionHeader（題目顯示區）
  * ScrollView（輸入區）
  * BottomButtonBar（底部按鈕區）
- 導覽標題："提交答案"（inline 模式）

### QuestionHeader
- 淺色背景 #FAFAFA，padding
- "練習題" - Caption，次要色
- 題目內容 - Headline，可換行
- 參考資料（如有）- Subheadline，藍色，藍色背景 0.1，圓角 8pt

### TextInputArea
- TextEditor（最小高度 200pt，padding 12pt）
- 白色背景，圓角 8pt
- 外框：Focus 時藍色，否則灰色 0.3 opacity
- 字數統計：右下角，Caption，次要色
- Placeholder："請輸入你的答案..."（淺色，position 定位）

### BottomButtonBar
- Divider 分隔線
- HStack (spacing: 12pt)
  * "儲存草稿" - Bordered，"square.and.arrow.down" 圖標（禁用當輸入為空）
  * "提交審核" - Bordered Prominent，"paperplane.fill" 圖標（禁用當輸入為空）
- 背景色，padding

### 提交確認對話框
- ConfirmationDialog
- 標題："確定要提交嗎？"
- 訊息："提交後將由 AI 監督者審核，請確認答案無誤。"
- 按鈕："確定提交" | "再檢查一下"（取消）

### 提交流程
1. 顯示 Loading
2. 創建 Submission 記錄（Supabase）
3. 觸發 n8n webhook 審核
4. 顯示成功 Toast
5. 轉場至審核等待頁面
6. 錯誤處理：顯示錯誤訊息

---

## 2. 音訊提交 (Audio Submission)

### 整體架構
- VStack (spacing: 0)
  * QuestionHeader
  * ScrollView（錄音區）
  * BottomButtonBar

### ReferenceAudio（參考發音區）
- 標題："參考發音" - Headline
- HStack：
  * 需要唸的文字 - 32pt, Medium
  * 播放按鈕 - "play.circle.fill"/"pause.circle.fill"（44pt）
- 藍色背景 0.1，圓角 12pt，padding

### RecordingArea（錄音區）
- 標題："你的發音" - Headline
- 中央大型圓形區域：
  * 背景圓（200x200，錄音時紅色 0.1，否則藍色 0.1）
  * 錄音按鈕（80x80 圓形）
    - 錄音中：紅色背景 + "stop.fill" 圖標
    - 待錄音：藍色背景 + "mic.fill" 圖標
    - Scale 動畫（錄音時 1.1，重複）
  * 波形動畫（錄音時顯示，20 個跳動的條）
- 計時器（錄音時）- Title2，等寬數字
  * **最大時長：60 秒**（自動停止）
- 音量指示器（錄音時）- 4pt 高度
- 說明文字："點擊停止錄音" / "長按開始錄音" - Caption，次要色
- **格式**：M4A (AAC)，採樣率 44.1kHz，單聲道

### RecordingsList（錄音列表）
- 標題："錄音列表"（有錄音時顯示）
- 每個錄音卡片：
  * 選擇指示器（圓形，選中時填滿藍色）
  * 播放按鈕（"play.circle.fill"/"pause.circle.fill"）
  * 錄音資訊（VStack）：
    - "錄音 1" - Subheadline, Bold
    - 時長 - Caption，次要色
  * 刪除按鈕（"trash" 圖標，紅色）
- 卡片背景：選中時藍色 0.1，否則淺灰
- 圓角 12pt，padding

### 錄音權限請求
- Alert："需要麥克風權限"
- 訊息："請在設定中允許 Kantoku 使用麥克風以錄製發音。"
- 按鈕："前往設定" | "取消"

### 提交流程
1. 上傳音訊檔案至 Supabase Storage
2. 取得公開 URL
3. 創建 Submission 記錄（content 為 URL）
4. 觸發 n8n 審核
5. 轉場至審核等待頁面

---

## 3. 圖片提交 (Image Submission)

### 整體架構
- VStack (spacing: 0)
  * QuestionHeader
  * ScrollView（圖片選擇/預覽區）
  * BottomButtonBar

### ImagePickerButtons（初始狀態）
- VStack (spacing: 16pt)
- 拍照按鈕：
  * "camera.fill" 圖標（48pt）
  * "拍照" 文字
  * Bordered 樣式，藍色，高度 150pt
- 從相簿選擇按鈕：
  * "photo.on.rectangle" 圖標
  * "從相簿選擇" 文字
  * Bordered 樣式，綠色，高度 150pt

### ImagePreview（有圖片時）
- 大圖預覽（最大高度 400pt，圓角 12pt）
- 右上角刪除按鈕（"xmark.circle.fill"，白色，半透明黑色背景）
- 編輯工具 HStack (spacing: 20pt)：
  * "裁切" - "crop" 圖標
  * "旋轉" - "rotate.right" 圖標
  * "重拍" - "camera" 圖標

### ThumbnailGrid（多張圖片）
- LazyVGrid（3 列）
- **限制：最多 3 張圖片**
- **壓縮：JPEG, 0.8 quality, 長邊 max 1920px**
- 每個縮圖：
  * 100x100，圓角 8pt
  * 右上角刪除按鈕
  * 點擊放大查看

### 相機權限處理
- 檢查授權狀態
- 未授權：顯示 Alert 引導至設定
- 授權類型：.video

### 提交流程
1. 壓縮圖片（JPEG, 0.8 quality, max 1920px）
2. 上傳至 Supabase Storage
3. 取得所有 URL（逗號分隔）
4. 創建 Submission 記錄
5. 觸發審核
6. 轉場至審核等待頁面

---

## 4. 審核結果顯示 (Review Result)

### 整體架構
- ScrollView
- VStack (spacing: 24pt)
  * ResultHeader
  * ScoreDisplay
  * AIFeedback
  * DetailedAnalysis（可選）
  * ActionButtons
- 導覽標題："審核結果"
- 隱藏返回按鈕

### ResultHeader
- 結果圖標（80pt）：
  * 通過："checkmark.circle.fill" - 綠色
  * 失敗："xmark.circle.fill" - 紅色
- 結果文字（36pt, Bold）：
  * 通過："通過！" - 綠色
  * 失敗："需要改進" - 紅色
- 垂直 padding 20pt

### ScoreDisplay
- 進度環（200x200）：
  * 背景圓（灰色 0.2，線寬 20pt）
  * 進度圓（分數顏色，線寬 20pt，-90度起始，Spring 動畫）
  * 中央分數："85" - 56pt, Bold
  * 分母："/100" - Title3，次要色
- 分數說明 - Subheadline，次要色
- 分數顏色與閾值：
  * **通過 (≥70)**: 綠色
  * 接近 (60-69): 橘色
  * 失敗 (<60): 紅色

### AIFeedback
- 標題："監督者的評語" - Title3, Bold
  * "person.fill.badge.sparkles" 圖標，藍色
- 反饋區：
  * 做得好的地方（綠色）
  * 需要改進（橘色）
  * 學習建議（黃色）
- 每個分區：
  * Section 標題（Headline，圖標 + 顏色）
  * 項目列表（圓點 + 文字，Subheadline）
- 淺色背景，圓角 12pt，padding

### DetailedAnalysis（可選）
- 錯誤部分標記
- 正確答案對照
- 相關知識點連結

### ActionButtons
- VStack (spacing: 12pt)
- 通過時：
  * "下一個任務" - Bordered Prominent，"arrow.right.circle.fill" 圖標
- 未通過時：
  * "重新提交" - Bordered Prominent（橘色），"arrow.clockwise.circle.fill" 圖標
- 共通：
  * "查看詳細解析" - Bordered，"doc.text.magnifyingglass" 圖標
  * "返回任務列表" - Bordered

### Confetti 動畫（通過時）
- Overlay 覆蓋層
- **50 個**彩色圓形（10pt）
- 從上方飄落，旋轉
- 顏色：紅/藍/綠/黃/橘/紫
- 3 秒後消失
- 震動反饋（Success）

---

## 設計注意事項

### 提交體驗
- 明確的 Loading 狀態
- 清晰的成功/失敗反饋
- 允許儲存草稿（文字）
- 允許重試（音訊/圖片）

### 審核等待
- 可考慮輪詢：**初始 2 秒，之後遞增到 5 秒，最長 60 秒**
- 或使用 Supabase Realtime 監聽
- 顯示等待動畫："監督者審核中..."

### 任務重新提交流程 (Re-submission)
**限制與規則：**
- 無次數限制，可重複提交直到通過
- 每次提交都會創建新的 submission 記錄
- 採用最後一次提交的分數

**流程：**
1. 從審核結果頁點擊「重新提交」
2. 返回提交畫面，保留原題目資訊
3. 重新輸入/錄音/拍照
4. 提交審核

**UI 表現：**
- 審核結果頁顯示歷史提交記錄列表（可選）
- 最新分數高亮顯示

### 錯誤處理
- 網路錯誤：提示檢查網路
- 上傳失敗：允許重試
- 審核超時：提供重新整理選項

### 無障礙
- 錄音按鈕：Accessibility Label "開始錄音" / "停止錄音"
- 播放按鈕：Accessibility Hint "播放參考發音"
- 圖片：Alternative Text
