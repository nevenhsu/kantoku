-- ============================================
-- Supabase Storage Policies for kantoku
-- ============================================
-- Purpose: Configure access policies for the submissions bucket
-- Run this in Supabase SQL Editor
-- Last Updated: 2026-01-29
-- ============================================

-- Policy 0: Allow service_role full access to all storage buckets
-- This is needed for backend operations (n8n workflows, admin tasks, etc.)
CREATE POLICY "Service role has full access"
ON storage.objects FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Policy 1: Allow authenticated users to read/list files in submissions bucket
-- All logged-in users can view submissions (useful for admin review, learning from others)
CREATE POLICY "Allow authenticated users to read files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'submissions');

-- Policy 2: Allow authenticated users to upload files to submissions bucket
-- Any logged-in user can submit their work
CREATE POLICY "Allow authenticated users to upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'submissions');

-- Policy 3: Allow users to update their own files only
-- Users can only modify files in their own folder: submissions/{user_id}/...
CREATE POLICY "Allow users to update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'submissions' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow users to delete their own files only
-- Users can only delete files in their own folder: submissions/{user_id}/...
CREATE POLICY "Allow users to delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'submissions' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- ============================================
-- Verification Queries
-- ============================================

-- Check if policies were created successfully
SELECT 
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
ORDER BY policyname;

-- ============================================
-- Expected File Structure
-- ============================================
-- submissions/
-- ├── {user_id_1}/
-- │   ├── task_123_audio.m4a
-- │   ├── task_456_image.jpg
-- │   └── task_789_text.txt
-- ├── {user_id_2}/
-- │   ├── task_abc_audio.m4a
-- │   └── task_def_image.jpg
-- └── ...
-- ============================================
