-- ============================================
-- 清理測試數據腳本
-- ============================================
-- Purpose: 手動清理累積的測試垃圾數據
-- Run in: Supabase SQL Editor
-- Last Updated: 2026-01-29
-- ============================================

-- ============================================
-- 1. 查看當前狀態
-- ============================================

-- 查看沒有對應用戶的 tasks（測試垃圾）
SELECT COUNT(*) as orphan_tasks_count
FROM tasks 
WHERE user_id NOT IN (SELECT id FROM profiles);

-- 查看沒有對應 task 的 submissions（測試垃圾）
SELECT COUNT(*) as orphan_submissions_count
FROM submissions 
WHERE task_id NOT IN (SELECT id FROM tasks);

-- 查看最近創建的 tasks（可能是測試數據）
SELECT 
    id,
    user_id,
    task_type,
    created_at
FROM tasks
WHERE user_id NOT IN (SELECT id FROM profiles)
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- 2. 清理測試數據（謹慎使用！）
-- ============================================

-- 選項 A: 刪除沒有對應用戶的 tasks
-- 這會級聯刪除相關的 submissions（如果設置了 ON DELETE CASCADE）
DELETE FROM tasks 
WHERE user_id NOT IN (SELECT id FROM profiles);

-- 選項 B: 刪除沒有對應 task 的 submissions
-- 如果級聯刪除沒設置，需要手動清理
DELETE FROM submissions 
WHERE task_id NOT IN (SELECT id FROM tasks);

-- 選項 C: 刪除特定測試 user_id 的數據
-- 替換 'TEST_USER_ID' 為實際的測試 user_id
-- DELETE FROM tasks WHERE user_id = 'TEST_USER_ID';

-- ============================================
-- 3. 驗證清理結果
-- ============================================

-- 再次查看統計
SELECT 
    'tasks' as table_name,
    COUNT(*) as total_count,
    (SELECT COUNT(*) FROM tasks WHERE user_id NOT IN (SELECT id FROM profiles)) as orphan_count
FROM tasks
UNION ALL
SELECT 
    'submissions' as table_name,
    COUNT(*) as total_count,
    (SELECT COUNT(*) FROM submissions WHERE task_id NOT IN (SELECT id FROM tasks)) as orphan_count
FROM submissions;

-- ============================================
-- 4. 深度清理（如果需要）
-- ============================================

-- 刪除超過 7 天的測試數據
-- 注意：這會刪除所有沒有對應用戶的舊 tasks
DELETE FROM tasks 
WHERE user_id NOT IN (SELECT id FROM profiles)
  AND created_at < NOW() - INTERVAL '7 days';

-- 刪除 test@kantoku.local 創建的測試數據（如果需要）
-- 警告：這會刪除測試帳號的所有數據
-- DELETE FROM tasks 
-- WHERE user_id = (
--     SELECT id FROM auth.users WHERE email = 'test@kantoku.local'
-- );

-- ============================================
-- 5. 優化表（可選）
-- ============================================

-- 在大量刪除後，優化表以回收空間
VACUUM ANALYZE tasks;
VACUUM ANALYZE submissions;

-- ============================================
-- 6. 預防性檢查
-- ============================================

-- 查看是否有重複的測試數據
SELECT 
    user_id,
    COUNT(*) as task_count
FROM tasks
WHERE user_id NOT IN (SELECT id FROM profiles)
GROUP BY user_id
HAVING COUNT(*) > 10
ORDER BY task_count DESC;

-- ============================================
-- 常用查詢
-- ============================================

-- 查看最近 1 小時的測試活動
SELECT 
    t.id,
    t.user_id,
    t.task_type,
    t.status,
    t.created_at,
    CASE 
        WHEN t.user_id IN (SELECT id FROM profiles) THEN '真實用戶'
        ELSE '測試數據'
    END as data_type
FROM tasks t
WHERE t.created_at > NOW() - INTERVAL '1 hour'
ORDER BY t.created_at DESC;

-- 查看數據庫整體統計
SELECT 
    (SELECT COUNT(*) FROM profiles) as users_count,
    (SELECT COUNT(*) FROM tasks) as tasks_count,
    (SELECT COUNT(*) FROM submissions) as submissions_count,
    (SELECT COUNT(*) FROM tasks WHERE user_id NOT IN (SELECT id FROM profiles)) as test_tasks_count;

-- ============================================
-- 安全提醒
-- ============================================

-- ⚠️ 執行刪除操作前請：
-- 1. 確認你在正確的環境（開發/正式）
-- 2. 備份重要數據
-- 3. 先用 SELECT 查詢確認要刪除的數據
-- 4. 在測試環境先試運行

-- ✅ 推薦做法：
-- 1. 先運行查看查詢（第 1 節）
-- 2. 確認要刪除的數據
-- 3. 使用事務（如果需要回滾）：
--    BEGIN;
--    DELETE FROM tasks WHERE ...;
--    -- 檢查結果
--    COMMIT; -- 或 ROLLBACK;

-- ============================================
-- 自動化建議
-- ============================================

-- 如果需要定期清理，可以創建 Supabase Edge Function：
-- 
-- CREATE OR REPLACE FUNCTION cleanup_test_data()
-- RETURNS void AS $$
-- BEGIN
--     DELETE FROM tasks 
--     WHERE user_id NOT IN (SELECT id FROM profiles)
--       AND created_at < NOW() - INTERVAL '7 days';
-- END;
-- $$ LANGUAGE plpgsql SECURITY DEFINER;
--
-- 然後使用 pg_cron 定期執行（需要 Supabase Pro）

-- ============================================
