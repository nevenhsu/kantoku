# Supabase Database Schema

## 使用者相關

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

## 學習進度

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

## 任務系統

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

## 學習資料

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
