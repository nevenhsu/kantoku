# Workflow 1: 任務生成（generate-tasks）實作紀錄

**實作日期**: 2026-01-23  
**狀態**: ✅ 已完成並測試通過  
**實作時間**: ~1.5 小時

---

## 基本資訊

| 項目 | 內容 |
|-----|------|
| **Workflow 名稱** | generate-tasks |
| **Webhook Path** | `/webhook/generate-tasks` |
| **HTTP Method** | POST |
| **節點數量** | 13 個 |
| **測試使用者** | `ebc3cd0d-dc42-42c1-920a-87328627fe35` |

---

## 完整節點列表

```
[Webhook] 
    ↓
[Query - User Progress] (Supabase)
    ↓
[Query - Learning Stage] (Supabase)
    ↓
[Query - Learned Kana] (Supabase)
    ↓
[Query - Review Items] (Supabase)
    ↓
[IF - Has Review Items] (IF)
    ├─ true  → [Code - Prepare Review Kana] (Code)
    │              ↓
    └─ false → [Code - Select New Kana] (Code)
                   ↓
         [Code - Build Tasks] (Code)
                   ↓
         [Loop - Insert Tasks] (Loop Over Items)
                   ↓
         [Insert - Task] (Supabase) ⟳ 迴圈
                   ↓
         [Code - Format Response] (Code)
                   ↓
         [Respond to Webhook]
```

---

## 節點詳細設定

### 1. Webhook
| 設定項目 | 值 |
|---------|---|
| HTTP Method | POST |
| Path | `generate-tasks` |
| Respond | Using 'Respond to Webhook' Node |

---

### 2. Query - User Progress (Supabase)
| 設定項目 | 值 |
|---------|---|
| Credential | Supabase - Kantoku |
| Resource | Row |
| Operation | Get Many |
| Table | `user_progress` |
| Filters | `user_id=eq.{{ $json.body.user_id }}` |

**輸出範例**:
```json
{
  "user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35",
  "current_stage_id": 1,
  "last_activity_at": "2026-01-23T06:29:10.373065+00:00"
}
```

---

### 3. Query - Learning Stage (Supabase)
| 設定項目 | 值 |
|---------|---|
| Resource | Row |
| Operation | Get Many |
| Table | `learning_stages` |
| Filters | `id=eq.{{ $json.current_stage_id }}` |

**輸出範例**:
```json
{
  "id": 1,
  "name": "あ行",
  "category": "hiragana_seion",
  "kana_chars": ["あ", "い", "う", "え", "お"],
  "description": "平假名第一行"
}
```

---

### 4. Query - Learned Kana (Supabase)
| 設定項目 | 值 |
|---------|---|
| Table | `kana_progress` |
| Filters | `user_id=eq.{{ $('Webhook').item.json.body.user_id }}&status=in.(learning,reviewing,mastered)` |

**說明**: 新使用者會回傳 `[{}]`（空）

---

### 5. Query - Review Items (Supabase)
| 設定項目 | 值 |
|---------|---|
| Table | `kana_progress` |
| Filters | `user_id=eq.{{ $('Webhook').item.json.body.user_id }}&next_review=lte.{{ new Date().toISOString() }}` |
| Limit | 5 |

**說明**: 新使用者會回傳 `[{}]`（空）

---

### 6. IF - Has Review Items (IF)
| 設定項目 | 值 |
|---------|---|
| Condition Type | Is Not Empty |
| Value 1 | `{{ $json.id }}` |

**邏輯**:
- **True**: 有待複習項目 → 走複習路徑
- **False**: 無待複習項目 → 走新學習路徑

---

### 7. Code - Select New Kana (Code) - False Branch

**Mode**: Run Once for All Items

**程式碼**:
```javascript
// 取得當前階段的假名
const stage = $('Query - Learning Stage').first().json;
const kanaChars = stage.kana_chars || [];

// 假名對應的羅馬拼音（Stage 1-5）
const romajiMap = {
  'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
  'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
  'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
  'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
  'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no'
};

// 建立任務清單
const tasks = kanaChars.map(kana => ({
  json: {
    kana: kana,
    romaji: romajiMap[kana] || kana,
    task_type: 'kana_learn',
    kana_type: 'hiragana'
  }
}));

return tasks;
```

**輸出範例**:
```json
[
  {"kana": "あ", "romaji": "a", "task_type": "kana_learn", "kana_type": "hiragana"},
  {"kana": "い", "romaji": "i", "task_type": "kana_learn", "kana_type": "hiragana"},
  ...
]
```

---

### 8. Code - Prepare Review Kana (Code) - True Branch

**Mode**: Run Once for All Items

**程式碼**:
```javascript
// 取得待複習的假名
const reviewItems = $('Query - Review Items').all();

return reviewItems
  .filter(item => item.json.id) // 過濾空物件
  .map(item => ({
    json: {
      kana: item.json.kana,
      romaji: item.json.romaji,
      task_type: 'kana_review',
      kana_type: item.json.kana_type
    }
  }));
```

---

### 9. Code - Build Tasks (Code)

**Mode**: Run Once for All Items

**程式碼**:
```javascript
const items = $input.all();
const userId = $('Webhook').first().json.body.user_id;
const today = new Date().toISOString().split('T')[0];

return items.map(item => ({
  json: {
    user_id: userId,
    task_type: item.json.task_type,
    content: JSON.stringify({
      kana: item.json.kana,
      romaji: item.json.romaji,
      type: item.json.kana_type,
      description: item.json.task_type === 'kana_learn' 
        ? `學習平假名「${item.json.kana}」` 
        : `複習平假名「${item.json.kana}」`,
      prompt: `請輸入「${item.json.kana}」的羅馬拼音`
    }),
    status: 'pending',
    due_date: today
  }
}));
```

**輸出範例**:
```json
{
  "user_id": "ebc3cd0d-...",
  "task_type": "kana_learn",
  "content": "{\"kana\":\"あ\",\"romaji\":\"a\",...}",
  "status": "pending",
  "due_date": "2026-01-23"
}
```

---

### 10. Loop - Insert Tasks (Loop Over Items)
| 設定項目 | 值 |
|---------|---|
| Batch Size | 1 |

**說明**: 將任務逐一插入資料庫

---

### 11. Insert - Task (Supabase)
| 設定項目 | 值 |
|---------|---|
| Resource | Row |
| Operation | Create |
| Table | `tasks` |

**Columns**:
| Column | Value |
|--------|-------|
| user_id | `{{ $json.user_id }}` |
| task_type | `{{ $json.task_type }}` |
| content | `{{ $json.content }}` |
| status | `{{ $json.status }}` |
| due_date | `{{ $json.due_date }}` |

**輸出**: 插入後的完整 task 記錄（含 id、created_at 等）

---

### 12. Code - Format Response (Code)

**Mode**: Run Once for All Items

**程式碼**:
```javascript
const tasks = $input.all().map(item => ({
  id: item.json.id,
  task_type: item.json.task_type,
  content: JSON.parse(item.json.content),
  status: item.json.status,
  due_date: item.json.due_date
}));

return [{
  json: {
    success: true,
    tasks_generated: tasks.length,
    tasks: tasks,
    estimated_minutes: tasks.length * 3,
    message: '今日任務已生成'
  }
}];
```

---

### 13. Respond to Webhook

**Respond With**: All Incoming Items

**說明**: 將格式化後的結果回傳給呼叫端

---

## 測試記錄

### 測試環境
- **n8n URL**: http://localhost:5678
- **測試模式 URL**: `http://localhost:5678/webhook-test/generate-tasks`
- **正式模式 URL**: `http://localhost:5678/webhook/generate-tasks`

### 測試指令

```bash
curl -X POST http://localhost:5678/webhook-test/generate-tasks \
  -H "Content-Type: application/json" \
  -d '{"user_id": "ebc3cd0d-dc42-42c1-920a-87328627fe35", "daily_goal_minutes": 30}'
```

### 測試結果

**狀態碼**: 200

**回應內容**:
```json
{
  "success": true,
  "tasks_generated": 5,
  "tasks": [
    {
      "id": "03b2d8d0-fe49-40ab-bd87-ddf99d8a7bd7",
      "task_type": "kana_learn",
      "content": {
        "kana": "あ",
        "romaji": "a",
        "type": "hiragana",
        "description": "學習平假名「あ」",
        "prompt": "請輸入「あ」的羅馬拼音"
      },
      "status": "pending",
      "due_date": "2026-01-23"
    },
    {
      "id": "17164ae6-b6a8-4fc0-9803-4448cdbb753e",
      "task_type": "kana_learn",
      "content": {
        "kana": "い",
        "romaji": "i",
        "type": "hiragana",
        "description": "學習平假名「い」",
        "prompt": "請輸入「い」的羅馬拼音"
      },
      "status": "pending",
      "due_date": "2026-01-23"
    },
    {
      "id": "3644eeff-2f41-4d3d-b20b-98e299b68013",
      "task_type": "kana_learn",
      "content": {
        "kana": "う",
        "romaji": "u",
        "type": "hiragana",
        "description": "學習平假名「う」",
        "prompt": "請輸入「う」的羅馬拼音"
      },
      "status": "pending",
      "due_date": "2026-01-23"
    },
    {
      "id": "8a507452-c7f5-4fc9-9916-ae3f0cedc54b",
      "task_type": "kana_learn",
      "content": {
        "kana": "え",
        "romaji": "e",
        "type": "hiragana",
        "description": "學習平假名「え」",
        "prompt": "請輸入「え」的羅馬拼音"
      },
      "status": "pending",
      "due_date": "2026-01-23"
    },
    {
      "id": "6f59817b-9a8d-4441-acd8-0ec8937437da",
      "task_type": "kana_learn",
      "content": {
        "kana": "お",
        "romaji": "o",
        "type": "hiragana",
        "description": "學習平假名「お」",
        "prompt": "請輸入「お」的羅馬拼音"
      },
      "status": "pending",
      "due_date": "2026-01-23"
    }
  ],
  "estimated_minutes": 15,
  "message": "今日任務已生成"
}
```

### 驗證項目

| 項目 | 狀態 | 說明 |
|-----|------|------|
| Webhook 接收 | ✅ | 正確接收 POST 請求 |
| 查詢使用者進度 | ✅ | 取得 current_stage_id = 1 |
| 查詢學習階段 | ✅ | 取得 あ行 的 5 個假名 |
| 判斷學習策略 | ✅ | 新使用者走 false 分支 |
| 選擇新假名 | ✅ | 成功生成 5 個假名任務 |
| 組合任務格式 | ✅ | content 為 JSON 字串 |
| 插入資料庫 | ✅ | 5 個 tasks 成功插入 |
| 格式化回應 | ✅ | content 解析為 JSON 物件 |
| 回傳結果 | ✅ | 正確回傳 JSON 格式 |

---

## 資料庫驗證

### 查詢插入的任務

```sql
SELECT 
  id, 
  task_type, 
  content->>'kana' as kana,
  status, 
  due_date,
  created_at
FROM tasks
WHERE user_id = 'ebc3cd0d-dc42-42c1-920a-87328627fe35'
ORDER BY created_at DESC
LIMIT 10;
```

**結果**: 5 筆任務，依序為 あ、い、う、え、お

---

## 已知限制與待優化

### 已知限制

1. **複習路徑未完整連接**
   - `Code - Prepare Review Kana` 節點已建立
   - 需要連接到 `Code - Build Tasks`
   - 影響：有待複習項目時無法正確生成任務

2. **羅馬拼音對照表不完整**
   - 目前只有 Stage 1-5（あ行～な行）
   - 缺少：は行～わ行、濁音、拗音
   - 影響：使用者進度到 Stage 6+ 時會出錯

3. **單字學習功能未實作**
   - 目前只生成假名學習任務
   - 原設計：60% 假名 + 40% 單字
   - 影響：無法實現漸進式學習完整體驗

### 待優化項目

1. **錯誤處理**
   - 缺少 user_id 驗證
   - 缺少資料庫查詢失敗處理
   - 缺少空結果檢查

2. **性能優化**
   - 可以合併部分查詢減少節點
   - Loop 插入可以改為 Batch Insert

3. **日誌記錄**
   - 無法追蹤 Workflow 執行歷史
   - 建議：新增日誌節點記錄關鍵資訊

---

## 實作心得

### 做得好的地方

1. ✅ **測試驅動開發**
   - 每個階段都先測試再繼續
   - 問題能夠及時發現和修正

2. ✅ **清晰的節點命名**
   - 節點名稱明確表達功能
   - 方便理解和維護

3. ✅ **完整的資料流程**
   - Webhook → 查詢 → 判斷 → 處理 → 儲存 → 回傳
   - 流程清晰易懂

### 遇到的問題

1. **Respond to Webhook 位置**
   - 問題：移除後 Webhook 報錯
   - 解決：必須連接在流程末端

2. **Supabase 空查詢結果**
   - 問題：回傳 `[{}]` 而非 `[]`
   - 解決：在判斷時檢查 `$json.id` 是否存在

3. **測試模式需要手動啟動**
   - 問題：curl 呼叫前需要點擊 Execute
   - 解決：理解 n8n 測試模式的運作方式

---

## 下一步

### 立即執行

1. **連接複習路徑**
   - 將 `Code - Prepare Review Kana` 連接到 `Code - Build Tasks`
   - 測試有待複習項目的情境

2. **擴充羅馬拼音對照表**
   - 新增 Stage 6-10 的對照
   - 新增濁音、拗音的對照

### 後續計劃

1. **啟用 Workflow**
   - 從測試模式切換到正式模式
   - 測試正式 Webhook URL

2. **建立 Workflow 2**
   - 提交審核（review-submission）
   - 處理任務完成邏輯

3. **整合測試**
   - 完整的使用者學習流程測試
   - 從生成任務到提交審核

---

## 參考資源

- [WORKFLOW_DESIGN.md](./WORKFLOW_DESIGN.md) - 完整設計文件
- [generate-tasks.json](./generate-tasks.json) - Workflow JSON 備份
- [PLAN.md](../PLAN.md) - 專案計劃
- [ENV_SETUP_COMPLETE.md](../ENV_SETUP_COMPLETE.md) - 環境設定文件

---

**實作者**: Claude Code  
**文件版本**: 1.0  
**最後更新**: 2026-01-23
