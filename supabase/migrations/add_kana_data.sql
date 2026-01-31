-- Migration: Add kana_data column to learning_stages
-- Purpose: Include romaji data for each kana character
-- Date: 2026-01-31

-- Step 1: Add new column
ALTER TABLE learning_stages
ADD COLUMN IF NOT EXISTS kana_data JSONB;

-- Step 2: Populate kana_data for existing stages

-- あ行 (a-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "あ", "romaji": "a"},
  {"kana": "い", "romaji": "i"},
  {"kana": "う", "romaji": "u"},
  {"kana": "え", "romaji": "e"},
  {"kana": "お", "romaji": "o"}
]'::jsonb
WHERE id = 1;

-- か行 (ka-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "か", "romaji": "ka"},
  {"kana": "き", "romaji": "ki"},
  {"kana": "く", "romaji": "ku"},
  {"kana": "け", "romaji": "ke"},
  {"kana": "こ", "romaji": "ko"}
]'::jsonb
WHERE id = 2;

-- さ行 (sa-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "さ", "romaji": "sa"},
  {"kana": "し", "romaji": "shi"},
  {"kana": "す", "romaji": "su"},
  {"kana": "せ", "romaji": "se"},
  {"kana": "そ", "romaji": "so"}
]'::jsonb
WHERE id = 3;

-- た行 (ta-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "た", "romaji": "ta"},
  {"kana": "ち", "romaji": "chi"},
  {"kana": "つ", "romaji": "tsu"},
  {"kana": "て", "romaji": "te"},
  {"kana": "と", "romaji": "to"}
]'::jsonb
WHERE id = 4;

-- な行 (na-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "な", "romaji": "na"},
  {"kana": "に", "romaji": "ni"},
  {"kana": "ぬ", "romaji": "nu"},
  {"kana": "ね", "romaji": "ne"},
  {"kana": "の", "romaji": "no"}
]'::jsonb
WHERE id = 5;

-- は行 (ha-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "は", "romaji": "ha"},
  {"kana": "ひ", "romaji": "hi"},
  {"kana": "ふ", "romaji": "fu"},
  {"kana": "へ", "romaji": "he"},
  {"kana": "ほ", "romaji": "ho"}
]'::jsonb
WHERE id = 6;

-- ま行 (ma-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "ま", "romaji": "ma"},
  {"kana": "み", "romaji": "mi"},
  {"kana": "む", "romaji": "mu"},
  {"kana": "め", "romaji": "me"},
  {"kana": "も", "romaji": "mo"}
]'::jsonb
WHERE id = 7;

-- や行 (ya-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "や", "romaji": "ya"},
  {"kana": "ゆ", "romaji": "yu"},
  {"kana": "よ", "romaji": "yo"}
]'::jsonb
WHERE id = 8;

-- ら行 (ra-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "ら", "romaji": "ra"},
  {"kana": "り", "romaji": "ri"},
  {"kana": "る", "romaji": "ru"},
  {"kana": "れ", "romaji": "re"},
  {"kana": "ろ", "romaji": "ro"}
]'::jsonb
WHERE id = 9;

-- わ行 (wa-gyou)
UPDATE learning_stages
SET kana_data = '[
  {"kana": "わ", "romaji": "wa"},
  {"kana": "を", "romaji": "wo"},
  {"kana": "ん", "romaji": "n"}
]'::jsonb
WHERE id = 10;

-- Step 3: Verify the migration
SELECT
  id,
  name,
  category,
  array_length(kana_chars, 1) as kana_chars_count,
  jsonb_array_length(kana_data) as kana_data_count,
  kana_data
FROM learning_stages
WHERE id <= 10
ORDER BY id;
