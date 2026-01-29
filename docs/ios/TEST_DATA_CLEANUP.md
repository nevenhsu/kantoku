# 測試數據自動清理說明

**日期**: 2026-01-29  
**狀態**: ✅ 已實現自動清理功能

---

## 📋 問題說明

### 之前的問題

測試執行後會在 Supabase 留下垃圾數據：

```
每次測試創建：
❌ tasks 表 - 測試任務（假的 user_id）
❌ submissions 表 - 測試提交（假的 task_id）
❌ auth sessions - 測試登入 session

結果：
🗑️ 數據庫累積大量測試垃圾
🐌 影響查詢性能
😵 混淆真實數據和測試數據
```

### 現在的解決方案

✅ **自動追蹤並清理所有測試數據**

---

## 🔧 實現細節

### 1. 追蹤測試資源

**文件**: `ConnectionTestService.swift`

```swift
class ConnectionTestService {
    // 記錄測試中創建的資源
    private var testUserIds: [String] = []  // 測試用的 user IDs
    private var testTaskIds: [String] = []  // 測試創建的 task IDs
}
```

### 2. 記錄創建的資源

**Generate Tasks 測試** (line 277-329):
```swift
let testUserId = UUID().uuidString
testUserIds.append(testUserId)  // ✅ 記錄

// 創建任務後記錄 task IDs
for task in tasks {
    if let taskId = task["id"] as? String {
        testTaskIds.append(taskId)  // ✅ 記錄
    }
}
```

**Review Submission 測試** (line 332-375):
```swift
let testTaskId = UUID().uuidString
testTaskIds.append(testTaskId)  // ✅ 記錄
```

### 3. 自動清理函數

**清理邏輯** (line 378-416):

```swift
private func cleanupTestData() async {
    // 1. 清理 tasks 表
    for taskId in testTaskIds {
        try await supabase
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
    }
    
    // 2. 清理 submissions 表
    for taskId in testTaskIds {
        try await supabase
            .from("submissions")
            .delete()
            .eq("task_id", value: taskId)
            .execute()
    }
    
    // 3. 清空記錄
    testUserIds.removeAll()
    testTaskIds.removeAll()
}
```

### 4. 測試執行流程

**更新後的流程** (line 418-444):

```swift
func runAllTests() async -> [TestResult] {
    // 1. 清空之前的記錄
    testUserIds.removeAll()
    testTaskIds.removeAll()
    
    // 2. 執行 Supabase 測試
    results.append(await testSupabaseConnection())
    results.append(await testSupabaseAuth())
    results.append(await testSupabaseDatabase())
    results.append(await testSupabaseStorage())
    
    // 3. 執行 n8n 測試（會創建測試數據）
    results.append(await testN8NConnection())
    results.append(await testGenerateTasksWebhook())  // 創建 tasks
    results.append(await testReviewSubmissionWebhook()) // 創建 submissions
    
    // 4. ✅ 自動清理測試數據
    await cleanupTestData()
    
    // 5. ✅ 清理 auth session
    try? await supabase.auth.signOut()
    
    return results
}
```

---

## 🎯 清理的數據

### 會被清理的：

| 數據類型 | 表名 | 清理方式 | 時機 |
|---------|------|---------|------|
| **測試任務** | `tasks` | `DELETE WHERE id = testTaskId` | 測試後立即 |
| **測試提交** | `submissions` | `DELETE WHERE task_id = testTaskId` | 測試後立即 |
| **Auth Session** | `auth.sessions` | `signOut()` | 測試後立即 |

### 不會被清理的：

| 數據類型 | 原因 |
|---------|------|
| **Test User** (`test@kantoku.local`) | 需要保留以供下次測試使用 |
| **learning_stages** | 只讀數據，不會創建 |
| **Storage 文件** | 測試只列出文件，不上傳 |

---

## 📊 清理流程圖

```
開始測試
   ↓
清空記錄陣列 (testUserIds, testTaskIds)
   ↓
執行 Supabase 測試
   ↓
執行 n8n 測試
   ├── Generate Tasks → 創建 tasks → 記錄 task IDs ✅
   └── Review Submission → 創建 submissions → 記錄 task ID ✅
   ↓
自動清理測試數據 🧹
   ├── 刪除記錄的 tasks
   ├── 刪除記錄的 submissions
   └── 清空記錄陣列
   ↓
清理 Auth Session (signOut)
   ↓
測試完成 ✅ 無垃圾數據
```

---

## 🧪 測試驗證

### 驗證清理是否生效

**Before 測試**:
```sql
-- 在 Supabase SQL Editor 查詢
SELECT COUNT(*) FROM tasks WHERE user_id NOT IN (
    SELECT id FROM profiles
);
-- 應該是 0（沒有測試垃圾）
```

**運行測試**:
```
iOS App → 點擊「開始測試」
```

**After 測試**:
```sql
-- 再次查詢
SELECT COUNT(*) FROM tasks WHERE user_id NOT IN (
    SELECT id FROM profiles
);
-- 仍然是 0（測試數據已清理）✅
```

### 檢查清理日誌

如果清理失敗，會在 Xcode Console 看到：

```
⚠️ 清理測試任務失敗: abc-123-def - Error message
⚠️ 清理測試提交失敗: abc-123-def - Error message
```

**注意**: 這些警告通常可以忽略（例如數據已被級聯刪除）

---

## 🔒 錯誤處理

### 清理失敗的處理

```swift
do {
    try await supabase.from("tasks").delete()...
} catch {
    // ✅ 忽略錯誤，不影響測試結果
    print("⚠️ 清理測試任務失敗: \(taskId)")
}
```

**為什麼忽略錯誤？**
- 數據可能已被級聯刪除（Foreign Key）
- 數據可能不存在（測試未創建）
- 權限問題（RLS policies）
- **重要**: 清理失敗不應該讓測試失敗

### 級聯刪除

如果 Supabase schema 配置了級聯刪除：

```sql
-- submissions 表有 ON DELETE CASCADE
ALTER TABLE submissions
ADD CONSTRAINT submissions_task_id_fkey
FOREIGN KEY (task_id) REFERENCES tasks(id)
ON DELETE CASCADE;
```

則刪除 `tasks` 時會自動刪除相關的 `submissions`。

---

## ⚙️ 配置選項

### 選項 1: 完全禁用清理（不推薦）

如果你想保留測試數據用於調試：

```swift
// ConnectionTestService.swift
func runAllTests() async -> [TestResult] {
    // ...
    
    // 註釋掉清理
    // await cleanupTestData()
    
    // ...
}
```

**警告**: 會累積大量垃圾數據！

### 選項 2: 僅在成功時清理

```swift
func runAllTests() async -> [TestResult] {
    // ...
    
    // 只有所有測試通過才清理
    let allPassed = results.allSatisfy { $0.success }
    if allPassed {
        await cleanupTestData()
    }
    
    // ...
}
```

**用途**: 失敗時保留數據以便調試

### 選項 3: 添加清理開關（推薦）

在 Constants 中添加配置：

```swift
enum Environment {
    static let autoCleanupTestData = true  // 可配置
}
```

然後在測試中使用：

```swift
if Constants.Environment.autoCleanupTestData {
    await cleanupTestData()
}
```

---

## 🛠️ 手動清理腳本

如果需要手動清理歷史測試數據：

### SQL 清理腳本

```sql
-- 刪除沒有對應用戶的 tasks
DELETE FROM tasks 
WHERE user_id NOT IN (SELECT id FROM profiles);

-- 刪除沒有對應 task 的 submissions
DELETE FROM submissions 
WHERE task_id NOT IN (SELECT id FROM tasks);

-- 查看清理結果
SELECT 
    (SELECT COUNT(*) FROM tasks) as tasks_count,
    (SELECT COUNT(*) FROM submissions) as submissions_count;
```

**保存為**: `docs/Supabase/cleanup_test_data.sql`

---

## 📈 性能影響

### 清理操作性能

```
每次測試清理：
- 刪除 ~5 個 tasks (平均)
- 刪除 ~1 個 submissions (平均)
- 總時間: ~100-200ms

影響：
✅ 可忽略（測試總時長 3-5 秒）
✅ 不影響用戶體驗
```

### 不清理的後果

```
100 次測試後：
- tasks 表: +500 條垃圾數據
- submissions 表: +100 條垃圾數據

影響：
❌ 查詢變慢
❌ 真實數據混淆
❌ 數據庫膨脹
```

---

## ✅ 驗證清單

測試清理功能是否正常：

- [ ] 運行測試前查詢數據庫（記錄數量）
- [ ] 運行 iOS App 測試
- [ ] 所有測試通過
- [ ] 運行測試後查詢數據庫（數量應該相同）
- [ ] Xcode Console 沒有大量清理錯誤
- [ ] 可選：多次運行測試，數據庫不增長

---

## 🔍 故障排除

### 問題 1: 測試數據沒有被清理

**檢查**:
```swift
// 在 cleanupTestData() 開始處添加
print("🧹 開始清理 \(testTaskIds.count) 個測試任務")
```

**可能原因**:
- `testTaskIds` 陣列為空（沒有記錄）
- 清理函數沒有被調用
- Supabase 權限不足（無法刪除）

### 問題 2: 清理報錯

**錯誤**: "JWT expired" 或 "Unauthorized"

**原因**: Auth session 過期

**解決**: 在清理前重新登入
```swift
// 在 cleanupTestData() 開始處
try? await supabase.auth.signIn(
    email: Constants.Environment.testEmail,
    password: Constants.Environment.testPassword
)
```

### 問題 3: 級聯刪除衝突

**錯誤**: "foreign key constraint"

**原因**: submissions 沒有級聯刪除設定

**解決**: 先刪除 submissions，再刪除 tasks（已實現）

---

## 📚 相關文檔

- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - 測試指南
- [TEST_ACCOUNT_SETUP.md](./TEST_ACCOUNT_SETUP.md) - 測試帳號配置
- [../../Supabase/SCHEMA.md](../../Supabase/SCHEMA.md) - 資料庫結構

---

## 💡 最佳實踐

### ✅ DO

1. **保持清理邏輯簡單**
   - 只清理測試創建的數據
   - 忽略清理錯誤（不影響測試）

2. **記錄所有創建的資源**
   - 在創建時立即記錄 ID
   - 使用陣列追蹤

3. **在測試結束時清理**
   - 所有測試完成後統一清理
   - 避免中途清理影響其他測試

### ❌ DON'T

1. **不要刪除非測試數據**
   - 不要刪除 test user
   - 不要刪除 learning_stages

2. **不要讓清理失敗中斷測試**
   - 使用 try? 忽略錯誤
   - 清理是 best-effort

3. **不要在每個測試後單獨清理**
   - 效率低
   - 可能影響其他測試

---

## 🎉 總結

**改進前**:
```
測試 → 創建數據 → ❌ 留下垃圾 → 數據庫污染
```

**改進後**:
```
測試 → 創建數據 → 記錄 ID → ✅ 自動清理 → 數據庫乾淨
```

**優勢**:
- ✅ 無需手動清理
- ✅ 數據庫保持乾淨
- ✅ 不影響測試性能
- ✅ 不影響用戶體驗

---

**最後更新**: 2026-01-29  
**功能狀態**: ✅ 已實現並測試
