# Supabase Storage Setup Guide

**Purpose**: Configure the `submissions` bucket with proper policies for the iOS app

---

## 📋 Current Issue

The `submissions` bucket exists but the iOS app cannot access it due to missing storage policies.

**Error**: 
```
❌ Supabase Storage
   submissions bucket 不存在
   未找到任何 buckets（可能需要認證或權限）
```

---

## 🔧 Solution: Configure Storage Policies

### Step 1: Verify Bucket Exists

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Navigate to Storage**
   - Click "Storage" in left sidebar
   - Verify you see `submissions` bucket

3. **Check Bucket Settings**
   - Click on `submissions` bucket
   - Note if it's **Public** or **Private**

### Step 2: Create Storage Policies

The bucket exists but has no policies, so authenticated users cannot access it.

#### Option A: Using Supabase Dashboard UI

1. **Go to Storage Policies**
   - Storage → Policies (top tab)
   - Or: Storage → submissions → Policies

2. **Create Policy for SELECT (Read)**
   - Click "New Policy"
   - Choose "For SELECT operations"
   - Policy name: `Allow authenticated users to read files`
   - Target roles: `authenticated`
   - USING expression:
     ```sql
     (auth.role() = 'authenticated')
     ```
   - Click "Review" then "Save policy"

3. **Create Policy for INSERT (Upload)**
   - Click "New Policy"
   - Choose "For INSERT operations"
   - Policy name: `Allow authenticated users to upload files`
   - Target roles: `authenticated`
   - WITH CHECK expression:
     ```sql
     (auth.role() = 'authenticated')
     ```
   - Click "Review" then "Save policy"

4. **Create Policy for UPDATE**
   - Click "New Policy"
   - Choose "For UPDATE operations"
   - Policy name: `Allow users to update own files`
   - Target roles: `authenticated`
   - USING expression:
     ```sql
     (auth.uid()::text = (storage.foldername(name))[1])
     ```
   - Click "Review" then "Save policy"

5. **Create Policy for DELETE**
   - Click "New Policy"
   - Choose "For DELETE operations"
   - Policy name: `Allow users to delete own files`
   - Target roles: `authenticated`
   - USING expression:
     ```sql
     (auth.uid()::text = (storage.foldername(name))[1])
     ```
   - Click "Review" then "Save policy"

#### Option B: Using SQL (Recommended for consistency)

Run this SQL in **SQL Editor**:

```sql
-- Enable RLS on storage.objects for submissions bucket
-- (This might already be enabled)

-- Policy 0: Allow service_role full access to all buckets (for backend/admin operations)
CREATE POLICY "Service role has full access"
ON storage.objects FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- Policy 1: Allow authenticated users to read/list files
CREATE POLICY "Allow authenticated users to read files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'submissions');

-- Policy 2: Allow authenticated users to upload files
CREATE POLICY "Allow authenticated users to upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'submissions');

-- Policy 3: Allow users to update their own files
CREATE POLICY "Allow users to update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'submissions' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Policy 4: Allow users to delete their own files
CREATE POLICY "Allow users to delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'submissions' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

### Step 3: Verify Policies

1. **Check Policies List**
   - Go to Storage → Policies
   - You should see 5 policies for storage.objects:
     - ✅ ALL: Service role has full access (for backend/admin)
     - ✅ SELECT: Allow authenticated users to read files
     - ✅ INSERT: Allow authenticated users to upload files
     - ✅ UPDATE: Allow users to update own files
     - ✅ DELETE: Allow users to delete own files

---

## 🧪 Test the Configuration

### In iOS App

1. **Run the connection tests**
   - Open Xcode: `open ios/kantoku.xcodeproj`
   - Run app: `Cmd + R`
   - Click "開始測試"

2. **Expected Result**
   ```
   ✅ Supabase Storage
      Storage 可用
      成功訪問 submissions bucket
   ```

### Using Supabase Dashboard

1. **Try uploading a test file**
   - Go to Storage → submissions
   - Click "Upload file"
   - Upload any test file
   - Should succeed if policies are correct

---

## 📁 File Organization Structure

The policies above organize files by user ID:

```
submissions/
├── {user_id_1}/
│   ├── task_123_audio.m4a
│   ├── task_456_image.jpg
│   └── task_789_text.txt
├── {user_id_2}/
│   ├── task_abc_audio.m4a
│   └── task_def_image.jpg
└── ...
```

This structure ensures:
- ✅ Users can only modify/delete their own files
- ✅ All authenticated users can read all submissions (for admin review)
- ✅ Organized by user for easy management

---

## 🔒 Security Considerations

### Current Setup (Recommended for Development)

**Pros**:
- ✅ All authenticated users can upload
- ✅ Users can only modify/delete their own files
- ✅ Simple and secure for learning app

**Cons**:
- ⚠️ Users can read other users' submissions

### Alternative: More Restrictive (For Production)

If you want users to ONLY see their own files:

```sql
-- Replace the SELECT policy with this:
DROP POLICY "Allow authenticated users to read files" ON storage.objects;

CREATE POLICY "Allow users to read own files"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'submissions' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

**Note**: This will prevent admin users from seeing all submissions unless you add a separate admin policy.

---

## 🛠️ Troubleshooting

### Problem: "Policy already exists" error

**Solution**: The policies might already exist. Check Storage → Policies first.

### Problem: Still getting permission errors after creating policies

**Solution**: 
1. Verify the user is authenticated (Auth test passes)
2. Check the policy expressions match exactly
3. Try signing out and signing back in
4. Clear browser cache / restart app

### Problem: Can upload but cannot list files

**Solution**: Make sure you have the SELECT policy enabled.

### Problem: Test passes but actual upload fails

**Solution**: 
1. Check file size limits in bucket settings
2. Verify file path format: `{user_id}/{filename}`
3. Check bucket is not full (storage quota)

---

## 📊 Policy Summary Table

| Operation | Who Can Access | Condition |
|-----------|---------------|-----------|
| **ALL** (Full Access) | service_role | Always allowed (for backend operations) |
| **SELECT** (Read/List) | All authenticated users | bucket_id = 'submissions' |
| **INSERT** (Upload) | All authenticated users | bucket_id = 'submissions' |
| **UPDATE** (Modify) | File owner only | bucket_id = 'submissions' AND owner matches |
| **DELETE** (Remove) | File owner only | bucket_id = 'submissions' AND owner matches |

---

## 📚 Related Documentation

- [Supabase Storage Policies](https://supabase.com/docs/guides/storage/security/access-control)
- [SCHEMA.md](./SCHEMA.md) - Database schema
- [TEST_ACCOUNT_SETUP.md](../ios/TEST_ACCOUNT_SETUP.md) - Test account setup

---

## ✅ Quick Checklist

Before running the iOS test:

- [ ] `submissions` bucket exists in Storage
- [ ] SELECT policy created (read access)
- [ ] INSERT policy created (upload access)
- [ ] UPDATE policy created (modify own files)
- [ ] DELETE policy created (delete own files)
- [ ] Test user is authenticated (Auth test passes)
- [ ] Run Storage test in iOS app

---

**Last Updated**: 2026-01-29
