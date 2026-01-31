# 任務顯示問題診斷指南

## 問題描述
iOS app 顯示 23 個獨立的任務卡片（每個假名一個），而不是 1-2 個合併的任務卡片。

## 可能原因

### 1. 數據庫中有舊任務數據
**檢查方法：**
```bash
# 檢查當前登入用戶的所有任務
curl -X GET 'https://pthqgzpmsgsyssdatxnm.supabase.co/rest/v1/tasks?select=id,task_type,status,content,created_at&order=created_at.desc&limit=30' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY" | jq '.'
```

**解決方法：**
如果發現大量舊格式的任務（每個假名一個任務），需要清理：
```sql
-- 在 Supabase SQL Editor 中執行
DELETE FROM tasks WHERE created_at < '2026-01-31';
```

### 2. iOS app 使用了模擬數據
**檢查文件：** `ios/kantoku/ViewModels/TaskViewModel.swift`

查找 `generateMockTasks()` 函數，確認 app 是否在使用模擬數據而不是真實 API 數據。

### 3. Task 模型解析錯誤
**檢查文件：** `ios/kantoku/Models/Task.swift`

在 `TaskContent` 的 `init(from decoder:)` 中，可能錯誤地將單個任務拆分成多個。

### 4. DashboardView 渲染邏輯問題
**檢查文件：** `ios/kantoku/Views/DashboardView.swift` (line 155-199)

確認是否正確過濾和分組任務。

## 調試步驟

### Step 1: 檢查 iOS app 日誌
在 Xcode 中查看 console 輸出，尋找：
```
🔍 Loading today's tasks for user: ...
✅ Loaded X today's tasks
```

這會告訴你 iOS app 實際從 Supabase 獲取了多少個任務。

### Step 2: 添加調試輸出
在 `DashboardView.swift` 的 `todayTasksSection` 中添加：

```swift
} else {
    // 添加這行調試
    let _ = print("📊 Total tasks: \(viewModel.todayTasks.count)")
    let _ = viewModel.todayTasks.forEach { task in
        print("  - Task: \(task.taskType.displayName)")
        if case .kanaLearn(let content) = task.content {
            print("    Kana count: \(content.kanaList.count)")
        }
        if case .kanaReview(let content) = task.content {
            print("    Review count: \(content.reviewKana.count)")
        }
    }
    
    // 分別顯示練習任務和複習任務
    let learnTasks = viewModel.todayTasks.filter { $0.taskType == .kanaLearn }
    let reviewTasks = viewModel.todayTasks.filter { $0.taskType == .kanaReview }
    
    let _ = print("📚 Learn tasks: \(learnTasks.count), Review tasks: \(reviewTasks.count)")
```

### Step 3: 重新生成任務
1. 刪除當前用戶的所有任務：
```bash
curl -X DELETE 'https://pthqgzpmsgsyssdatxnm.supabase.co/rest/v1/tasks?user_id=eq.YOUR_USER_ID' \
  -H "apikey: YOUR_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
```

2. 調用 n8n workflow 重新生成：
```bash
curl -X POST http://neven.local:5678/webhook/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "YOUR_USER_ID"}'
```

3. 在 iOS app 中下拉刷新

### Step 4: 檢查 TaskCard 渲染
在 `TaskCard.swift` 的 `contentPreview` 函數中添加調試：

```swift
case .kanaLearn(let content):
    let _ = print("🃏 TaskCard rendering kanaLearn with \(content.kanaList.count) kana")
    let kanaString = content.kanaList.map { $0.kana }.joined(separator: " ")
    Text("假名: \(kanaString)")
```

## 預期正確行為

### API 回應（n8n workflow）
```json
{
  "success": true,
  "tasks_generated": 1,
  "tasks": [
    {
      "id": "...",
      "task_type": "kana_learn",
      "content": "{\"kana_list\":[{\"kana\":\"あ\",\"romaji\":\"a\"},{\"kana\":\"い\",\"romaji\":\"i\"},...],\"kana_type\":\"hiragana\"}"
    }
  ]
}
```

### iOS app 應該顯示
- **1 個練習任務卡片**，內容為：
  - 標題：假名學習
  - 描述：5 個假名（或任意數量）
  - 預覽：あ い う え お

### 數據庫應該有
```sql
SELECT COUNT(*) FROM tasks WHERE user_id = 'YOUR_USER_ID' AND status = 'pending';
-- 應該返回 1 或 2（複習 + 練習）
```

## 臨時解決方案

如果問題持續，可以暫時在 iOS app 中使用模擬數據測試 UI：

在 `DashboardView.swift` 的 `.task` 修飾符中：
```swift
.task {
    // 暫時使用模擬數據
    viewModel.todayTasks = [
        TaskModel(
            id: UUID(),
            userId: UUID(),
            taskType: .kanaLearn,
            content: .kanaLearn(KanaLearnContent(
                kanaList: [
                    KanaItem(kana: "あ", romaji: "a"),
                    KanaItem(kana: "い", romaji: "i"),
                    KanaItem(kana: "う", romaji: "u"),
                    KanaItem(kana: "え", romaji: "e"),
                    KanaItem(kana: "お", romaji: "o")
                ],
                kanaType: .hiragana
            )),
            status: .pending,
            dueDate: Date(),
            skipped: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    // await viewModel.loadDashboardData()
}
```

這樣可以先驗證 UI 顯示邏輯是否正確。
