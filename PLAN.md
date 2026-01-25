# Kantoku - 實作計劃 (Simplified)

## 專案概述
**Kantoku（監督）** 是一款日文學習 iOS 應用，扮演使用者的「嚴格專案經理」角色。
詳細學習模式請參考 [LEARNING_MODEL.md](./LEARNING_MODEL.md)。

## 技術棧
- **Frontend**: iOS Swift + SwiftUI (iOS 16.0+)
- **Backend Logic**: n8n Workflow (Local Docker)
- **Database**: Supabase (PostgreSQL + Auth + Storage) - 詳細 Schema 請參考 [SCHEMA.md](./SCHEMA.md)
- **AI**: Gemini 2.5 Flash

## 架構圖
```
[iOS App] --(HTTP)--> [n8n Webhooks] --(SDK)--> [Supabase]
                          |
                      [Gemini AI]
```

## iOS App 結構
請參考 `Kantoku/` 目錄結構。

## 核心功能
1. **使用者系統**: 每日目標、Streak
2. **任務系統**: AI 自動生成、跳過機制
3. **提交審核**: 文字/音訊/圖片、AI 審核
4. **學習追蹤**: Spaced Repetition、弱項加強
5. **外部資源**: YouTube/NHK 整合

## n8n Workflows
1. **任務生成**: 查詢進度 -> AI 生成 -> 插入 DB
2. **提交審核**: 接收提交 -> AI 判斷 -> 更新結果
3. **測驗生成**: 階段性回顧 -> AI 出題
4. **測驗批改**: AI 評分 -> 弱項分析

## 資料庫 (Supabase)
完整 SQL 定義請見 [SCHEMA.md](./SCHEMA.md)。主要包含 `tasks`, `submissions`, `kana_progress`, `vocabulary` 等表。

## 實作階段 Roadmap

### Phase 0: 環境準備 (Done)
- [x] Docker, n8n, Supabase Project, Gemini Key

### Phase 1-2: iOS 基礎 (Pending)
- [ ] Xcode Project, Supabase SDK Setup

### Phase 3: n8n Workflows (Partial)
- [x] Task Gen & Review Workflows
- [x] Test Gen & Grading Workflows

### Phase 4-13: App 開發
- Auth, Data Prep, Dashboard, Task UI, Audio/Camera, Progress, Tests, Polish.

## 開始前檢查清單
- [x] Docker/n8n Running
- [x] Credentials Ready
