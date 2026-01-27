# UI Flow 05 - 進度追蹤

## 1. Progress 總覽頁面

### 整體架構
- NavigationStack，標題："學習進度"
- Segment Control: "50音" | "單字" | "統計"
- TabView (page 樣式，無指示器)

---

## 2. 50音進度 (Kana Progress)

### 當前階段卡片
- 標題："當前階段"
- HStack: 進度環（100x100，藍色，12pt線寬）+ 階段資訊
- 階段名稱：Title3, Bold
- 掌握數："42/46 已掌握"
- "繼續學習" 按鈕（Small, Bordered Prominent）
- 漸層背景（藍色 0.1 → 0.05），圓角 16pt

### KanaTypePicker
- Segment Control: "平假名" | "片假名"

### StatsSummary
- HStack 3 個統計卡片：
  * 已掌握（綠色，"checkmark.circle.fill"）
  * 學習中（藍色，"book.circle.fill"）
  * 未開始（灰色，"lock.circle.fill"）
- 每個顯示：圖標 + 數值 + 標籤
- 淺色背景，圓角 12pt

### KanaGrid
- VStack 分組：清音、濁音/半濁音、拗音
- 每組可展開/收合（Chevron 圖標）
- **Grid 設定**：
  * 清音/濁音：LazyVGrid (5 列)
  * **拗音：LazyVGrid (3 列)** (避免過於擁擠)
- 每個假名格子（60x60）：
  * 假名字符（28pt）
  * 狀態圖標（Caption）
  * 背景色 + 邊框色（根據狀態）

### 狀態樣式
- Locked: 灰色，"lock.fill"
- Learning: 藍色，"book.fill"
- Reviewing: 橘色，"arrow.clockwise"
- Mastered: 綠色，"checkmark.circle.fill"

### KanaDetailSheet
- 點擊格子顯示 Sheet
- **導覽列**：右上角 "xmark.circle.fill" 關閉按鈕
- 大型假名（80pt）+ 羅馬拼音
- 播放發音按鈕
- 筆順動畫（200pt 高）
- 相關單字列表
- 練習記錄（正確/錯誤/熟練度）
- "開始練習" 按鈕

---

## 3. 單字進度 (Vocabulary Progress)

### FilterBar
- JLPT 等級篩選（橫向滑動 HStack）
- 學習狀態 Menu（"line.3.horizontal.decrease.circle"）
- 分類 Menu（"tag.circle"）
- 搜尋按鈕（"magnifyingglass"）

### VocabStats
- HStack 3 個統計卡片：
  * 總單字量（藍色，"book.fill"）
  * 本週新增（綠色，"plus.circle.fill"）
  * 需複習（橘色，"arrow.clockwise.circle.fill"）

### VocabularyList
- LazyVStack，每個單字卡片：
  * 假名 + 漢字（Title3/Body）
  * 中文意思（Subheadline，次要色）
  * 標籤（JLPT 等級 + 分類）
  * 狀態標籤 + 最後複習時間
- 白色背景，圓角 12pt，shadow
- 下拉刷新
- 空狀態：ContentUnavailableView (iOS 17+) 或自訂視圖
  * 標題："還沒有學習任何單字"
  * 按鈕："開始今日任務"

---

## 4. 學習統計 (Statistics)

### TimeRangePicker
- Segment Control: "週" | "月" | "年"

### StudyTimeChart
- 標題："學習時間"
- Swift Charts 長條圖/折線圖（200pt 高）
  * **需 iOS 16.0+**
  * Y 軸單位：分鐘
- 統計摘要：總時間 + 平均
- 白色背景，圓角 12pt，shadow

### StreakCalendar
- 標題："學習日曆" + Streak 顯示（火焰圖標 + 天數）
- 月曆視圖（300pt 高）
- 有學習的日期標記綠色
- 點擊顯示當日詳情

### TaskCompletionChart
- 標題："任務完成情況"
- HStack: 圓餅圖（120x120）+ 統計列表
- 通過/失敗/跳過 分布
- 總計數

### WeaknessAnalysis
- 標題："弱項分析"（橘色，"lightbulb.fill"）
- 需加強的假名（橫向滑動）
- 易錯單字 Top 5 列表
- "生成複習任務" 按鈕（Bordered Prominent，橘色）
- 橘色背景 0.1，圓角 12pt

### AchievementGrid
- 標題："成就徽章"
- LazyVGrid（3 列，或 adaptive(minimum: 80)）
- 每個徽章（60x60 圓形）：
  * 圖標 emoji（30pt）
  * 徽章名稱（Caption2，最多 2 行）
  * 未解鎖時灰階

---

## 設計注意事項

### 數據視覺化
- 使用 Swift Charts 框架
- 清晰的圖例與標籤
- 顏色一致性

### 進度激勵
- 突出顯示成就
- Streak 視覺化
- 進度環動畫

### 效能
- LazyVStack/LazyVGrid 延遲載入
- 圖表資料預處理
- 分頁載入單字列表

---

## 5. 階段進階流程 (Stage Progression)

### 觸發機制
- 監聽 `user_progress` 更新
- 當前階段所有假名掌握度達標且通過測驗

### UI 表現 (FullScreenCover)
1. **慶祝動畫**：全螢幕 Confetti + 煙火
2. **標題**："恭喜！你完成了 あ行 學習！"
3. **進度展示**：進度環從 99% 填滿至 100% (Spring 動畫)
4. **解鎖內容展示**：新階段「か行」卡片翻轉出現
5. **操作按鈕**："開始下一階段" (Primary Button)
6. **音效與震動**：Success Haptic + 音效
