# UI Flow 09 - 動畫、響應式與無障礙

## 1. 動畫與轉場效果

### 頁面轉場
- **Push/Pop**: 預設橫向滑動（NavigationLink）
- **Modal Present**: 由下往上（.sheet）
- **Tab 切換**: 淡入淡出（.animation）
- **測驗完成**: 放大淡入 + Confetti

### 互動動畫
- **按鈕點擊**: Scale 0.95，duration 0.1
- **卡片點擊**: Scale 1.02 + Shadow 加深
- **Toggle**: 系統預設滑動動畫
- **進度條**: Spring 填充動畫
- **分數計數**: 數字滾動動畫（1.5 秒）

### 微互動
- **完成任務**: ✓ 符號描繪動畫（trim 0→1）
- **Streak 增加**: 火焰跳動（scale 1.0 ← → 1.2）
- **解鎖成就**: 徽章閃爍（opacity）+ 彈跳（spring）+ 震動反饋
- **錯誤**: 搖晃動畫（translationX sin 函數）

### Confetti 動畫
- 100 個彩色圓形（10pt）
- 隨機 X 位置，Y 從 -50 開始
- 顏色：紅/藍/綠/黃/橘/紫
- 動畫：Y 到底部 + 旋轉 360 度
- 延遲：0-0.3 秒隨機
- 時長：1.5-2.5 秒隨機

---

## 2. 響應式設計

### 裝置支援
- **iPhone SE**: 最小 320pt 寬 → 緊湊佈局
- **iPhone 14/15**: 標準佈局
- **iPhone Pro Max**: 430pt 寬 → 更多內容
- **iPad**: 暫不支援 (MVP 階段鎖定 iPhone)

### 適配策略
- **GeometryReader**: 獲取螢幕尺寸，動態調整
- **條件佈局**: 針對不同螢幕寬度微調 Spacing 和 Padding

### 字體縮放 (Dynamic Type)
- 支援系統動態字體大小
- 範圍：Small → xxxLarge
- **限制最大尺寸**：
  * 假名顯示 (Kana Display): .largeTitle (避免破版)
  * 分數顯示 (Score Ring): .largeTitle
  * Tab Bar 標籤: .caption
- 使用 .font(.body) 等系統字體自動適配

### 橫向支援
- **主要畫面**: 支援橫向（Dashboard, Tasks, Progress）
- **學習/測驗頁面**: 鎖定直向（更專注）
- **橫向優化**: VerticalSizeClass == .compact 時使用 HStack

---

## 3. 無障礙設計

### VoiceOver 支援
- **Accessibility Label**: 所有互動元件標記
  * 圖標按鈕："播放發音"、"刪除"
  * 圖片："假名 あ 的筆順動畫"
- **Accessibility Hint**: 重要操作提供提示
  * "點擊提交你的答案進行審核"
- **Accessibility Value**: 動態值
  * Streak: "連續學習天數，7 天"
- **組合元素**: .accessibilityElement(children: .combine)
- **忽略裝飾**: .accessibilityHidden(true) 背景圖
- **自訂順序**: .accessibilitySortPriority

### 色彩對比
- **WCAG AA 標準**: 
  * 文字對比度 ≥ 4.5:1
  * 按鈕對比度 ≥ 3:1
- **高對比模式**: @Environment(\.accessibilityReduceTransparency)
- **色盲友善**: 不只靠顏色，加上圖標/形狀

### 觸控目標
- **最小面積**: 44x44 pt
- **按鈕間距**: ≥ 8pt
- **避免過密**: 重要操作留足空間

### 動作減弱
- **@Environment(\.accessibilityReduceMotion)**
- 若開啟：移除裝飾性動畫
- 保留必要的狀態轉換

---

## 4. 效能考量

### 圖片處理
- **LazyVStack/LazyHStack**: 延遲載入，只渲染可見項目
- **AsyncImage**: 自動下載與快取
- **縮圖**: 預先產生 100x100 縮圖
- **壓縮**: JPEG 0.8 quality

### 資料載入
- **分頁載入**: 每頁 20 筆
- **Skeleton Screen**: 載入時顯示，提升感知速度
- **下拉刷新**: .refreshable
- **無限滾動**: onAppear 檢測最後一項

### 離線支援
- **本地快取**: UserDefaults (使用者設定) / Core Data (學習記錄)
- **NetworkMonitor**: NWPathMonitor 監聽網路狀態
- **提交佇列**: P2 功能，MVP 顯示「需要連線」
- **快取策略**: 
  * 基礎資料（假名、單字）快取
  * 進度資料即時同步
  * 圖片/音訊延遲上傳

### 離線狀態 UI 流程
**1. 頂部橫幅**
- 固定顯示：「目前離線，部分功能暫時無法使用」
- 圖標：wifi.slash (橘色)
- 背景：灰色 0.1

**2. 任務列表**
- 顯示已快取的任務
- 新任務無法生成（顯示 Empty State + 離線提示）
- 顯示說明：「連線後自動更新任務」

**3. 提交功能**
- 顯示提示：「需要網路連線才能提交」
- 提交按鈕禁用

**4. 恢復連線時**
- 自動刷新資料
- 顯示 Toast：「已恢復連線」
- 移除離線橫幅

---

## 5. 觸覺反饋 (Haptic Feedback)

### 反饋類型
- **成功**: UINotificationFeedbackGenerator, .success
  * 使用時機：提交成功、測驗通過
- **錯誤**: UINotificationFeedbackGenerator, .error
  * 使用時機：提交失敗、答案錯誤
- **警告**: UINotificationFeedbackGenerator, .warning
  * 使用時機：跳過任務、刪除確認
- **選擇**: UISelectionFeedbackGenerator, .selectionChanged
  * 使用時機：Segment 切換、選項選擇
- **影響**: UIImpactFeedbackGenerator, .medium
  * 使用時機：按鈕點擊、卡片點擊

### 使用原則
- 配合視覺反饋
- 不過度使用（避免麻木）
- 重要操作才使用

---

## 6. 動畫效能優化

### 最佳實踐
- **限制複雜度**: Confetti 最多 100 個粒子
- **使用 Spring**: 自然且高效
- **避免巢狀動畫**: 減少重繪
- **條件動畫**: .animation(reduceMotion ? nil : .spring())

### 動畫參數
- **快速互動**: duration 0.1-0.2
- **狀態轉換**: duration 0.3-0.5
- **頁面轉場**: 系統預設
- **Spring**: response 0.5-0.8, dampingFraction 0.6-0.8

---

## 設計注意事項

### 一致性
- 統一的動畫時長
- 統一的緩動曲線（easeInOut, spring）
- 統一的反饋機制

### 性能
- 避免同時多個重動畫
- 大型列表使用 Lazy 載入
- 圖片壓縮與快取

### 無障礙優先
- 所有互動都有替代方式
- 不依賴單一感官（視覺、聽覺）
- 尊重使用者偏好設定
