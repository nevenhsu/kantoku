# Kantoku - 完整實作計劃（Swift iOS + n8n 架構）

## 專案概述

**Kantoku（監督）** 是一款日文學習 iOS 應用，扮演使用者的「嚴格專案經理」角色。AI 主導學習計劃，使用者必須完成指定任務並提交證明，AI 進行嚴格審核。

**為什麼選擇 iOS App？**
- 聽說讀寫需求：音訊錄製、播放更穩定
- 原生拍照/選圖功能
- 推播通知提醒學習
- 隨時隨地學習
- 更好的日文輸入體驗

---

## 技術棧

| 類別 | 選擇 | 說明 |
|------|------|------|
| **前端** | **Swift + SwiftUI** | **iOS 原生應用** |
| UI 框架 | SwiftUI | Apple 官方 UI 框架 |
| 後端邏輯 | n8n Workflow | 視覺化低代碼平台 |
| 資料庫 | Supabase (PostgreSQL + Auth + Storage) | 資料儲存 |
| AI | Gemini 1.5 Flash (透過 n8n) | AI 任務生成與審核 |
| 最低支援 | iOS 16.0+ | SwiftUI 完整功能 |
| n8n 部署 | 本地 Docker → 之後選擇正式環境 | Workflow 執行環境 |

---

## 架構圖

```
┌─────────────────────────────────────────┐
│            Swift iOS App                │
│         (使用者手機)                     │
└────────┬────────────────────────────────┘
         │
         │ HTTP (呼叫 n8n Webhooks)
         │ Supabase Swift SDK (Auth + DB + Storage)
         │
         ▼
┌─────────────────────────────────────────┐
│            n8n Workflows                │
│         (本地 Docker)                    │
│  ├── 任務生成 Workflow                  │
│  ├── 提交審核 Workflow                  │
│  ├── 測驗生成 Workflow                  │
│  └── 測驗批改 Workflow                  │
└────────┬────────────────────────────────┘
         │
    ┌────┴────────────────┐
    ▼                     ▼
┌──────────────┐    ┌──────────────┐
│   Supabase   │    │   Gemini AI  │
│  PostgreSQL  │    │  (審核/生成) │
│  Auth        │    └──────────────┘
│  Storage     │
└──────────────┘
```

---

## iOS App 結構

```
Kantoku/
├── KantokuApp.swift                 # App 入口
├── Models/                          # 資料模型
│   ├── User.swift
│   ├── Task.swift
│   ├── Submission.swift
│   ├── Test.swift
│   ├── KanaProgress.swift
│   └── VocabularyProgress.swift
├── Views/                           # SwiftUI Views
│   ├── Auth/
│   ├── Dashboard/
│   ├── Tasks/
│   ├── Progress/
│   ├── Test/
│   └── Settings/
├── Services/                        # 服務層
│   ├── AuthService.swift           # Supabase Auth
│   ├── APIService.swift            # n8n Webhook 呼叫
│   ├── DatabaseService.swift       # Supabase DB
│   ├── StorageService.swift        # Supabase Storage
│   ├── AudioService.swift          # 音訊錄製/播放
│   └── NotificationService.swift   # 推播通知
├── ViewModels/                      # MVVM ViewModels
└── Utilities/                       # 工具類
    ├── Constants.swift
    ├── Extensions.swift
    └── SpacedRepetition.swift      # 間隔重複演算法
```

---

## 核心功能

### 1. 使用者系統
- 註冊/登入（Supabase Auth）
- 使用者設定（每日學習目標時間）
- 學習進度追蹤

### 2. 任務系統
- **AI 任務分配**：根據進度自動生成每日任務
- **任務類型**：50音學習、基礎詞彙（N5）、外部資源學習
- **任務狀態**：待完成 → 待審核 → 通過/不合格
- **跳過機制**：每天 1-2 次跳過機會，會影響統計

### 3. 提交與審核
- **提交方式**：文字輸入、音訊錄製、拍照/選圖
- **審核標準**：音訊能辨識即通過、文字允許小錯誤、截圖驗證內容
- **失敗處理**：必須重做同一任務直到通過

### 4. 學習追蹤
- **間隔重複**：Spaced Repetition 演算法
- **弱項加強**：AI 自動對弱項分配更多任務
- **階段性測驗**：每增加 10% 進度觸發一次

### 5. 外部資源
- YouTube 影片、NHK 文章
- 根據學習進度推薦相應程度的內容
- 答題驗證學習成果

### 6. iOS 特有功能
- 推播通知、離線模式、背景音訊、Widget

---

## 50 音漸進式學習系統

### 核心理念
**邊學假名，邊學相關單字**：使用者學會幾個假名後，立刻學習只用這些假名組成的單字。

### 學習順序
```
【階段 A：平假名清音】46 音
あ行 → か行 → さ行 → た行 → な行 → は行 → ま行 → や行 → ら行 → わ行

【階段 B：平假名濁音/半濁音】25 音
が行 → ざ行 → だ行 → ば行 → ぱ行

【階段 C：平假名拗音】36 音
きゃ系 → しゃ系 → ちゃ系 → にゃ系 → ひゃ系 → みゃ系 → りゃ系

【階段 D：片假名】（重複 A-B-C 的結構）
```

### 學習進度範例

| 階段 | 已學假名 | 可學單字範例 |
|------|----------|--------------|
| あ行 | あいうえお | あい(愛)、いえ(家)、うえ(上) |
| +か行 | +かきくけこ | あか(赤)、かお(顔)、いけ(池) |
| +さ行 | +さしすせそ | あさ(朝)、さけ(酒)、すし(寿司) |
| ... | ... | 單字選擇越來越豐富 |

---

## n8n Workflow 設計

### Workflow 1: 任務生成
```
Webhook → 查詢進度 → 查詢待複習項目 → Gemini AI 生成 → 插入任務 → 回傳
```

### Workflow 2: 提交審核
```
Webhook → 查詢任務 → 根據類型分流(文字/音訊/圖片) → AI 審核 → 更新狀態 → 回傳
```

### Workflow 3: 測驗生成
```
Webhook → 查詢已學項目 → Gemini AI 生成題目 → 插入測驗 → 回傳
```

### Workflow 4: 測驗批改
```
Webhook → 查詢題目 → AI 批改 → 計算分數/識別弱項 → 更新結果 → 回傳
```

---

## 資料庫架構（Supabase）

### 使用者相關

```sql
-- profiles（使用者資料）
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  daily_goal_minutes INT DEFAULT 30,
  streak_days INT DEFAULT 0,
  skip_remaining INT DEFAULT 2,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 學習進度

```sql
-- learning_stages（學習階段定義）
CREATE TABLE learning_stages (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  kana_chars TEXT[] NOT NULL,
  total_vocab_count INT DEFAULT 0,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- kana_progress（50音進度）
CREATE TABLE kana_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  kana TEXT NOT NULL,
  kana_type TEXT NOT NULL CHECK (kana_type IN ('hiragana', 'katakana')),
  status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'learning', 'reviewing', 'mastered')),
  correct_count INT DEFAULT 0,
  incorrect_count INT DEFAULT 0,
  mastery_score INT DEFAULT 0,
  last_reviewed TIMESTAMPTZ,
  next_review TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, kana, kana_type)
);

-- vocabulary_progress（詞彙進度）
CREATE TABLE vocabulary_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  word_id UUID REFERENCES vocabulary(id) ON DELETE CASCADE,
  status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'learning', 'mastered')),
  last_reviewed TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, word_id)
);

-- user_progress（使用者當前階段）
CREATE TABLE user_progress (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
  current_stage_id INT REFERENCES learning_stages(id) DEFAULT 1,
  last_activity_at TIMESTAMPTZ DEFAULT NOW()
);

-- learning_stats（學習統計）
CREATE TABLE learning_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('hiragana', 'katakana')),
  total_items INT DEFAULT 46,
  mastered_items INT DEFAULT 0,
  progress_percent INT DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category)
);
```

### 任務系統

```sql
-- tasks（任務）
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  task_type TEXT NOT NULL CHECK (task_type IN ('kana_learn', 'kana_review', 'vocabulary', 'external_resource')),
  content JSONB NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'passed', 'failed')),
  due_date DATE DEFAULT CURRENT_DATE,
  skipped BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- submissions（提交）
CREATE TABLE submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  submission_type TEXT NOT NULL CHECK (submission_type IN ('text', 'audio', 'image')),
  content TEXT NOT NULL,
  ai_feedback JSONB,
  score INT,
  passed BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- tests（階段性測驗）
CREATE TABLE tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL CHECK (category IN ('hiragana', 'katakana', 'vocabulary_n5')),
  progress_milestone INT NOT NULL CHECK (progress_milestone IN (10, 20, 30, 40, 50, 60, 70, 80, 90, 100)),
  questions JSONB NOT NULL,
  answers JSONB,
  score INT,
  passed BOOLEAN,
  weakness_items JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category, progress_milestone)
);
```

### 學習資料

```sql
-- vocabulary（詞彙資料庫）
CREATE TABLE vocabulary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  word TEXT NOT NULL,
  word_kanji TEXT,
  reading TEXT NOT NULL,
  meaning TEXT NOT NULL,
  level TEXT DEFAULT 'N5' CHECK (level IN ('N5', 'N4', 'N3', 'N2', 'N1')),
  category TEXT,
  required_kana TEXT[] NOT NULL,
  required_kana_types TEXT[] DEFAULT ARRAY['hiragana'],
  min_stage_id INT REFERENCES learning_stages(id),
  has_dakuten BOOLEAN DEFAULT FALSE,
  has_youon BOOLEAN DEFAULT FALSE,
  example_sentence TEXT,
  example_sentence_meaning TEXT,
  audio_url TEXT,
  frequency_rank INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- external_resources（外部資源）
CREATE TABLE external_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_type TEXT NOT NULL CHECK (resource_type IN ('youtube', 'nhk_article')),
  url TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  difficulty_level TEXT CHECK (difficulty_level IN ('N5', 'N4', 'N3', 'N2', 'N1')),
  topics JSONB DEFAULT '[]',
  duration_minutes INT,
  is_curated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 實作階段

### Phase 0：環境準備（0.5 天）
- [x] 安裝 Docker Desktop
- [x] 啟動 n8n（本地 Docker）
- [ ] 安裝 Xcode
- [ ] 建立 Supabase 專案
- [ ] 取得 Gemini API Key

### Phase 1-2：iOS 專案 + Supabase（2 天）
- [ ] 建立 Xcode 專案
- [ ] 設定專案結構與依賴
- [ ] 在 Supabase 建立資料表
- [ ] 設定 RLS 與 Storage

### Phase 3：n8n Workflows（2 天）
- [x] Workflow 1: 任務生成（generate-tasks）✅ 2026-01-23
- [~] Workflow 2: 提交審核（review-submission）⏳ 進行中（Phase 1-3 完成）
- [ ] Workflow 3: 測驗生成（generate-test）
- [ ] Workflow 4: 測驗批改（grade-test）
- [ ] 測試所有 Webhook

### Phase 4-5：認證 + 資料（2-3 天）
- [ ] 建立 AuthService
- [ ] Login/Register UI
- [ ] 50音與詞彙資料準備

### Phase 6-7：Dashboard + 任務（3-4 天）
- [ ] Dashboard UI
- [ ] 任務詳情與提交

### Phase 8-9：音訊 + 圖片（3 天）
- [ ] AudioService 實作
- [ ] Camera + PhotoPicker

### Phase 10-11：進度 + 測驗（2-4 天）
- [ ] 進度追蹤 UI
- [ ] 測驗系統

### Phase 12-13：特色功能 + 優化（2-3 天）
- [ ] 推播、Widget
- [ ] 優化與完善

**總計：約 3-4 週**

---

## 開發工具

- **Xcode 15+**：iOS 開發
- **Docker Desktop**：已安裝 ✅
- **n8n**：已啟動 ✅

### Swift Package Manager 依賴
- supabase-swift（2.0.0+）

---

## 環境設定

詳細代碼範例請參考 [CODE_EXAMPLES.md](./CODE_EXAMPLES.md)

---

## 開始前檢查清單

- [x] Docker Desktop 已安裝並運行
- [x] n8n 已啟動 (http://localhost:5678)
- [x] Xcode Command Line Tools 已安裝
- [x] Supabase 專案已建立
- [x] Gemini API Key 已取得
- [x] 測試使用者已建立（ebc3cd0d-dc42-42c1-920a-87328627fe35）
