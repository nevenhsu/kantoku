# UI Flow 06 - 測驗系統

## 1. 測驗列表 (Test List)

### 整體架構
- NavigationStack，標題："階段測驗"
- Category Picker: "平假名" | "片假名" | "N5單字"
- ScrollView + LazyVStack

### TestMilestoneCard
- 每 10% 一個測驗卡片（10%, 20%...100%）
- **里程碑定義**：10%, 20%, 30%, 40%, 50%, 60%, 70%, 80%, 90%, 100%
- HStack: 百分比標籤 + 狀態圖標
- 測驗名稱：Headline
- 解鎖條件（若未解鎖）
- 歷史成績（若有，顯示最近 3 次）
- 操作按鈕（根據狀態）

### 測驗狀態
- Locked: 灰色，"lock.fill"，灰色背景 0.05
- Available: 藍色，"pencil.circle.fill"，"開始測驗" 按鈕
- Passed: 綠色，"checkmark.seal.fill"，"查看報告" + "重新測驗"
- Failed: 紅色，"xmark.circle.fill"，"重新測驗" 按鈕（橘色）

### 卡片樣式
- Padding，狀態色背景 0.05
- 圓角 12pt，狀態色邊框 2pt

---

## 2. 測驗說明頁面 (Test Instructions)

### TestHeader
- 大型測驗圖標（60pt，"doc.text.fill"，藍色）
- 測驗名稱：Title2, Bold
- 藍色背景 0.1，圓角 16pt

### TestInfo
- 標題："測驗資訊" - Headline
- Info Rows:
  * 題目數量：20 題（"number.circle.fill"）
  * 測驗時間：15 分鐘（"clock.fill"）
  * 通過標準：80 分（"checkmark.circle.fill"）
- 題型分布（VStack，圓點列表）
- 白色背景，圓角 12pt，shadow

### PreparationTips
- 標題："準備建議"（橘色，"lightbulb.fill"）
- 提示列表（勾選圖標，橘色）
- 橘色背景 0.1，圓角 12pt

### StartButton
- "開始測驗" 按鈕（Primary，Large，"play.fill"）
- 確認對話框："準備好了嗎？測驗開始後將無法暫停或返回。"

---

## 3. 測驗進行頁面 (Test Taking)

### 頂部固定區
- HStack: 進度 "5/20" + 倒數計時器 "12:34"
- ProgressView（藍色）
- 右上角："放棄" 按鈕（需確認）
  * 確認對話框：「確定要放棄測驗嗎？本次進度將不會保存。」
  * 確認後：返回測驗列表，不計入歷史
- 計時器狀態：
  * > 2分鐘：黑色/白色
  * < 2分鐘：橘色
  * < 1分鐘：紅色 + 輕微震動
- 背景色，padding，shadow

### 題目區
- 題號："第 5 題" - Title3, Bold
- 題型標籤（Caption，藍色背景 0.1，圓角）
- 題目內容（根據題型）：
  * 聽音選字：播放按鈕（大型，60pt）
  * 拼音輸入：大型假名（80pt）
  * 單字認讀：假名+漢字 + 發音按鈕

### 答題區
- 選擇題：4 個選項按鈕
  * Padding，背景色，圓角 12pt
  * 選中時藍色邊框 2pt
- 輸入題：TextField + 假名鍵盤（若需要）

### 底部導覽
- HStack:
  * "上一題" - Bordered（第 1 題時禁用）
  * 題目快速導覽（"list.bullet" + "已答/總數"）
    - 點擊顯示 QuestionOverview Sheet
  * "下一題" / "提交測驗" - Bordered Prominent
- 背景色，padding，shadow

### QuestionOverview Sheet
- NavigationStack
- LazyVGrid（5 列）
- 每個題號格子（50x50）：
  * 題號
  * 已答：綠色背景 0.2
  * 當前：藍色邊框 2pt
  * 未答：灰色背景 0.1
- 點擊跳轉題目

### 提交確認
- ConfirmationDialog
- 若有未答題："還有 X 題未作答，確定要提交嗎？"

---

## 4. 測驗報告頁面 (Test Report)

### ResultHeader
- 結果圖標（80pt）
- 結果文字（32pt, Bold）
- 鼓勵文字（Body，次要色，置中）
- 結果色背景 0.1，圓角 16pt

### ScoreAnalysis
- 大型分數進度環（200x200）
- 統計摘要（HStack 3 列）：
  * 正確率（綠色，"checkmark.circle.fill"）
  * 錯誤率（紅色，"xmark.circle.fill"）
  * 用時（藍色，"clock.fill"）
- 排名："你的表現優於平均"（若有足夠數據）
- 白色背景，圓角 12pt，shadow

### QuestionTypeAnalysis
- 標題："題型表現" - Headline
- 每個題型：
  * 題型名 + 正確數/總數
  * 橫向進度條（顏色根據表現）
  * 表現圖標（優秀/良好/需改進）
- 白色背景，圓角 12pt，shadow

### WeaknessAnalysis
- 標題："弱項分析"（橘色，"exclamationmark.triangle.fill"）
- 需加強的假名（Grid，顯示錯誤次數徽章）
- 易錯單字列表
- "生成針對性複習任務" 按鈕（Bordered Prominent，橘色）
- 橘色背景 0.1，圓角 12pt

### WrongAnswersReview
- DisclosureGroup："錯題回顧 (X)"
- 每個錯題卡片：
  * 題號 - Headline
  * 題目 - Body
  * 你的答案（紅色背景 0.1，叉叉圖標）
  * 正確答案（綠色背景 0.1，勾選圖標）
  * 解析（藍色背景 0.05，燈泡圖標）
  * **"加入複習" 按鈕**（將相關內容標記為待複習）
- 淺色背景，圓角 12pt

### ActionButtons
- VStack (spacing: 12pt)
- 通過："返回測驗列表"
- 未通過："重新測驗"（橘色）
- 共通："分享成績"（"square.and.arrow.up"）

### 動畫效果
- 分數計數動畫（1.5 秒滾動）
- 進度環填充（Spring 動畫）
- 通過時 Confetti

---

## 設計注意事項

### 測驗體驗
- 無法暫停，確保專注
- 明確的時間提示
- 可回頭檢查答案
- 題目導覽方便跳轉

### 報告清晰
- 視覺化表現
- 具體的改進建議
- 錯題詳細解析

### 動機激勵
- 排名顯示
- 成績分享
- 弱項分析 → 複習任務
