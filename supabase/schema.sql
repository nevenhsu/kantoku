-- Kantoku Database Schema
-- 執行順序：從上到下依序執行
-- 注意：需要在 Supabase Dashboard 的 SQL Editor 中執行

-- ============================================
-- 1. 使用者相關表
-- ============================================

-- profiles（使用者資料）
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  daily_goal_minutes INT DEFAULT 30 CHECK (daily_goal_minutes > 0),
  streak_days INT DEFAULT 0 CHECK (streak_days >= 0),
  skip_remaining INT DEFAULT 2 CHECK (skip_remaining >= 0),
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- profiles RLS 政策
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ============================================
-- 2. 學習階段定義
-- ============================================

-- learning_stages（學習階段定義）
CREATE TABLE learning_stages (
  id INT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('hiragana_seion', 'hiragana_dakuten', 'hiragana_youon', 'katakana_seion', 'katakana_dakuten', 'katakana_youon')),
  kana_chars TEXT[] NOT NULL,
  total_vocab_count INT DEFAULT 0 CHECK (total_vocab_count >= 0),
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- learning_stages 初始資料（平假名清音）
INSERT INTO learning_stages (id, name, category, kana_chars, description) VALUES
  (1, 'あ行', 'hiragana_seion', ARRAY['あ', 'い', 'う', 'え', 'お'], '平假名第一行'),
  (2, 'か行', 'hiragana_seion', ARRAY['か', 'き', 'く', 'け', 'こ'], '平假名第二行'),
  (3, 'さ行', 'hiragana_seion', ARRAY['さ', 'し', 'す', 'せ', 'そ'], '平假名第三行'),
  (4, 'た行', 'hiragana_seion', ARRAY['た', 'ち', 'つ', 'て', 'と'], '平假名第四行'),
  (5, 'な行', 'hiragana_seion', ARRAY['な', 'に', 'ぬ', 'ね', 'の'], '平假名第五行'),
  (6, 'は行', 'hiragana_seion', ARRAY['は', 'ひ', 'ふ', 'へ', 'ほ'], '平假名第六行'),
  (7, 'ま行', 'hiragana_seion', ARRAY['ま', 'み', 'む', 'め', 'も'], '平假名第七行'),
  (8, 'や行', 'hiragana_seion', ARRAY['や', 'ゆ', 'よ'], '平假名第八行'),
  (9, 'ら行', 'hiragana_seion', ARRAY['ら', 'り', 'る', 'れ', 'ろ'], '平假名第九行'),
  (10, 'わ行', 'hiragana_seion', ARRAY['わ', 'を', 'ん'], '平假名第十行');

-- ============================================
-- 3. 學習進度追蹤
-- ============================================

-- kana_progress（50音進度）
CREATE TABLE kana_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  kana TEXT NOT NULL,
  kana_type TEXT NOT NULL CHECK (kana_type IN ('hiragana', 'katakana')),
  romaji TEXT NOT NULL,
  status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'learning', 'reviewing', 'mastered')),
  correct_count INT DEFAULT 0 CHECK (correct_count >= 0),
  incorrect_count INT DEFAULT 0 CHECK (incorrect_count >= 0),
  mastery_score INT DEFAULT 0 CHECK (mastery_score >= 0 AND mastery_score <= 100),
  last_reviewed TIMESTAMPTZ,
  next_review TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, kana, kana_type)
);

CREATE INDEX idx_kana_progress_user_next_review ON kana_progress(user_id, next_review);
CREATE INDEX idx_kana_progress_user_status ON kana_progress(user_id, status);

-- kana_progress RLS
ALTER TABLE kana_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own kana progress"
  ON kana_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own kana progress"
  ON kana_progress FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- 4. 詞彙資料庫
-- ============================================

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
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(word, word_kanji)
);

CREATE INDEX idx_vocabulary_min_stage ON vocabulary(min_stage_id);
CREATE INDEX idx_vocabulary_level ON vocabulary(level);
CREATE INDEX idx_vocabulary_frequency ON vocabulary(frequency_rank);

-- ============================================
-- 5. 詞彙學習進度
-- ============================================

-- vocabulary_progress（詞彙進度）
CREATE TABLE vocabulary_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  word_id UUID REFERENCES vocabulary(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'not_started' CHECK (status IN ('not_started', 'learning', 'mastered')),
  correct_count INT DEFAULT 0 CHECK (correct_count >= 0),
  incorrect_count INT DEFAULT 0 CHECK (incorrect_count >= 0),
  last_reviewed TIMESTAMPTZ,
  next_review TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, word_id)
);

CREATE INDEX idx_vocab_progress_user_next_review ON vocabulary_progress(user_id, next_review);
CREATE INDEX idx_vocab_progress_user_status ON vocabulary_progress(user_id, status);

-- vocabulary_progress RLS
ALTER TABLE vocabulary_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own vocabulary progress"
  ON vocabulary_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own vocabulary progress"
  ON vocabulary_progress FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- 6. 使用者當前進度
-- ============================================

-- user_progress（使用者當前階段）
CREATE TABLE user_progress (
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE PRIMARY KEY,
  current_stage_id INT REFERENCES learning_stages(id) DEFAULT 1,
  last_activity_at TIMESTAMPTZ DEFAULT NOW()
);

-- user_progress RLS
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
  ON user_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own progress"
  ON user_progress FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- 7. 學習統計
-- ============================================

-- learning_stats（學習統計）
CREATE TABLE learning_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('hiragana', 'katakana', 'vocabulary_n5')),
  total_items INT DEFAULT 46 CHECK (total_items > 0),
  mastered_items INT DEFAULT 0 CHECK (mastered_items >= 0),
  progress_percent INT DEFAULT 0 CHECK (progress_percent >= 0 AND progress_percent <= 100),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, category)
);

CREATE INDEX idx_learning_stats_user ON learning_stats(user_id);

-- learning_stats RLS
ALTER TABLE learning_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own stats"
  ON learning_stats FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own stats"
  ON learning_stats FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- 8. 任務系統
-- ============================================

-- tasks（任務）
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  task_type TEXT NOT NULL CHECK (task_type IN ('kana_learn', 'kana_review', 'vocabulary', 'external_resource')),
  content JSONB NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'submitted', 'passed', 'failed', 'skipped')),
  due_date DATE DEFAULT CURRENT_DATE,
  skipped BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_user_due_date ON tasks(user_id, due_date);

-- tasks RLS
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tasks"
  ON tasks FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own tasks"
  ON tasks FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- 9. 提交記錄
-- ============================================

-- submissions（提交）
CREATE TABLE submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  submission_type TEXT NOT NULL CHECK (submission_type IN ('text', 'audio', 'image', 'direct_confirm')),
  content TEXT,
  ai_feedback JSONB,
  score INT CHECK (score >= 0 AND score <= 100),
  passed BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_submissions_task ON submissions(task_id);

-- submissions RLS
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own submissions"
  ON submissions FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM tasks WHERE id = task_id));

CREATE POLICY "Users can create own submissions"
  ON submissions FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT user_id FROM tasks WHERE id = task_id));

-- ============================================
-- 10. 階段性測驗
-- ============================================

-- tests（階段性測驗）
CREATE TABLE tests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('hiragana', 'katakana', 'vocabulary_n5')),
  progress_milestone INT NOT NULL CHECK (progress_milestone IN (10, 20, 30, 40, 50, 60, 70, 80, 90, 100)),
  questions JSONB NOT NULL,
  answers JSONB,
  score INT CHECK (score >= 0 AND score <= 100),
  passed BOOLEAN,
  weakness_items JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE(user_id, category, progress_milestone)
);

CREATE INDEX idx_tests_user_category ON tests(user_id, category);

-- tests RLS
ALTER TABLE tests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own tests"
  ON tests FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own tests"
  ON tests FOR ALL
  USING (auth.uid() = user_id);

-- ============================================
-- 11. 外部資源
-- ============================================

-- external_resources（外部資源）
CREATE TABLE external_resources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource_type TEXT NOT NULL CHECK (resource_type IN ('youtube', 'nhk_article', 'other')),
  url TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  difficulty_level TEXT CHECK (difficulty_level IN ('N5', 'N4', 'N3', 'N2', 'N1')),
  topics JSONB DEFAULT '[]',
  duration_minutes INT CHECK (duration_minutes > 0),
  is_curated BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_external_resources_level ON external_resources(difficulty_level);
CREATE INDEX idx_external_resources_type ON external_resources(resource_type);

-- ============================================
-- 12. 自動更新 updated_at 的觸發器
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 為需要的表添加觸發器
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_kana_progress_updated_at
  BEFORE UPDATE ON kana_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vocabulary_progress_updated_at
  BEFORE UPDATE ON vocabulary_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at
  BEFORE UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learning_stats_updated_at
  BEFORE UPDATE ON learning_stats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 13. 自動建立 profile 的觸發器
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (NEW.id, NEW.email);
  
  INSERT INTO public.user_progress (user_id, current_stage_id)
  VALUES (NEW.id, 1);
  
  INSERT INTO public.learning_stats (user_id, category, total_items, mastered_items, progress_percent)
  VALUES 
    (NEW.id, 'hiragana', 107, 0, 0),
    (NEW.id, 'katakana', 107, 0, 0),
    (NEW.id, 'vocabulary_n5', 800, 0, 0);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- Schema 建立完成！
-- ============================================
