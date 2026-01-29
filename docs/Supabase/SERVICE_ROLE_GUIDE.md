# Supabase Service Role vs Authenticated Users

**Purpose**: Understand the difference between service_role and authenticated user access

---

## 🔑 Role Types in Supabase

### 1. `service_role` (Backend/Admin)

**What it is**:
- The **highest privilege role** in Supabase
- Uses the **service_role key** (secret, never expose to clients)
- **Bypasses all RLS policies** by default

**When to use**:
- Backend services (n8n workflows, cron jobs)
- Admin operations (batch updates, data migration)
- Server-side API endpoints
- Automated tasks that need full access

**Where the key lives**:
- Environment variables on your server
- n8n workflow credentials
- **NEVER** in client-side code (iOS app, web frontend)

**Example Use Cases**:
```
✅ n8n workflow deleting old submissions
✅ Admin script updating all user progress
✅ Backend service processing AI reviews
✅ Batch job organizing storage files
```

### 2. `authenticated` (Regular Users)

**What it is**:
- Users who have logged in with email/password or OAuth
- Uses the **anon key** + **user JWT token**
- **Subject to RLS policies** (row-level security)

**When to use**:
- iOS app requests
- Web frontend requests
- Any user-initiated action
- Client-side operations

**Where the key lives**:
- iOS app configuration (Config.local.xcconfig)
- Web app environment variables
- Safe to expose (it's called "anon key" for a reason)

**Example Use Cases**:
```
✅ User uploading their own submission
✅ User viewing their progress
✅ User updating their profile
✅ User deleting their own files
```

### 3. `anon` (Anonymous/Public)

**What it is**:
- Unauthenticated users (not logged in)
- Most restricted access
- Usually only for public data

**When to use** (in kantoku):
- Not used much in kantoku (learning app requires login)
- Maybe for public landing page data

---

## 🛡️ Storage Policy Examples

### Service Role: Full Access

```sql
-- Service role can do ANYTHING in storage
CREATE POLICY "Service role has full access"
ON storage.objects FOR ALL
TO service_role
USING (true)      -- Can read/update/delete anything
WITH CHECK (true); -- Can insert anything
```

**What this allows**:
- ✅ Read any file in any bucket
- ✅ Upload files to any bucket
- ✅ Modify any file (even other users' files)
- ✅ Delete any file (cleanup, moderation)
- ✅ List all buckets

**Security**: This is safe because service_role key is **only on the server**, never exposed to users.

### Authenticated Users: Restricted Access

```sql
-- Authenticated users can only read files in submissions bucket
CREATE POLICY "Allow authenticated users to read files"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'submissions');

-- Authenticated users can only modify their OWN files
CREATE POLICY "Allow users to update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'submissions' 
  AND (storage.foldername(name))[1] = auth.uid()::text
);
```

**What this allows**:
- ✅ Read files in `submissions` bucket
- ✅ Upload files to `submissions` bucket
- ✅ Modify/delete only files in `submissions/{their_user_id}/`
- ❌ Cannot touch files in other users' folders
- ❌ Cannot access other buckets (unless policies allow)

---

## 🔐 Security Best Practices

### ✅ DO

1. **Use service_role for**:
   - n8n workflows that process user submissions
   - Admin dashboards (server-side)
   - Scheduled cleanup jobs
   - Batch operations

2. **Use authenticated for**:
   - iOS app operations
   - Web app user actions
   - Any client-side code

3. **Keep service_role key secret**:
   - Store in `.env` files (gitignored)
   - Store in n8n credentials (encrypted)
   - Never log it or expose in errors
   - Rotate it if compromised

### ❌ DON'T

1. **Never expose service_role key**:
   - ❌ Don't put in iOS app config
   - ❌ Don't commit to git
   - ❌ Don't send to client-side
   - ❌ Don't log in console

2. **Don't give authenticated users too much power**:
   - ❌ Don't allow users to delete other users' data
   - ❌ Don't allow users to access admin tables
   - ❌ Don't trust client-side validation only

---

## 📋 kantoku Access Matrix

| Operation | service_role | authenticated | anon |
|-----------|--------------|---------------|------|
| **List all buckets** | ✅ Yes | ❌ No (requires policy) | ❌ No |
| **Read files in submissions** | ✅ Yes | ✅ Yes (via policy) | ❌ No |
| **Upload to submissions** | ✅ Yes | ✅ Yes (via policy) | ❌ No |
| **Update own files** | ✅ Yes | ✅ Yes (via policy) | ❌ No |
| **Update other users' files** | ✅ Yes | ❌ No | ❌ No |
| **Delete any file** | ✅ Yes | ❌ No (only own files) | ❌ No |
| **Access tasks table** | ✅ Yes | ✅ Yes (own tasks via RLS) | ❌ No |
| **Modify profiles table** | ✅ Yes | ✅ Yes (own profile via RLS) | ❌ No |

---

## 🔧 How to Use Service Role

### In n8n Workflows

```javascript
// n8n HTTP Request node configuration
{
  "url": "https://your-project.supabase.co/storage/v1/object/submissions/...",
  "authentication": "Generic Credential Type",
  "headers": {
    "Authorization": "Bearer {{ $credentials.serviceRoleKey }}",
    "apikey": "{{ $credentials.serviceRoleKey }}"
  }
}
```

### In Backend API (Node.js example)

```javascript
import { createClient } from '@supabase/supabase-js'

// Service role client (backend only!)
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY, // Secret key
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false
    }
  }
)

// This bypasses RLS and can access everything
const { data, error } = await supabaseAdmin
  .from('tasks')
  .select('*')  // Gets ALL tasks from ALL users
```

### In iOS App (Authenticated User)

```swift
// iOS app uses anon key + user session
let supabase = SupabaseClient(
  supabaseURL: URL(string: Constants.Environment.supabaseURL)!,
  supabaseKey: Constants.Environment.supabaseAnonKey  // Public anon key
)

// User logs in
let session = try await supabase.auth.signIn(
  email: "user@example.com",
  password: "password"
)

// This respects RLS and only gets user's own tasks
let response = try await supabase
  .from("tasks")
  .select()
  .execute()  // Only returns tasks where user_id matches current user
```

---

## 🎯 When Each Role is Used in kantoku

### service_role Usage

1. **n8n: Generate Tasks Workflow**
   - Creates tasks for users
   - Needs to insert into `tasks` table
   - Uses service_role to bypass RLS

2. **n8n: Review Submission Workflow**
   - Reads submission files from storage
   - Updates task status
   - Uses service_role for full access

3. **n8n: Cleanup Old Files Workflow** (future)
   - Deletes submissions older than 30 days
   - Needs to access all users' files
   - Uses service_role

### authenticated Usage

1. **iOS App: User Login**
   - User authenticates with email/password
   - Gets JWT token
   - All subsequent requests use this token

2. **iOS App: Upload Submission**
   - User uploads audio/image
   - Saves to `submissions/{user_id}/...`
   - Authenticated access with user's JWT

3. **iOS App: View Progress**
   - User views their own progress
   - Queries `kana_progress` table
   - RLS ensures they only see their own data

---

## 🔍 How to Check Which Role You're Using

### In Supabase SQL Editor

```sql
-- Check current role
SELECT current_role;

-- Check if RLS is bypassed
SELECT current_setting('request.jwt.claim.role', true);

-- List all policies on a table
SELECT * FROM pg_policies WHERE tablename = 'objects';
```

### In Application Logs

```sql
-- See which role accessed what (in Supabase logs)
-- Go to: Supabase Dashboard → Database → Logs
-- Look for: "role": "service_role" or "role": "authenticated"
```

---

## 📚 Related Documentation

- [STORAGE_SETUP.md](./STORAGE_SETUP.md) - Storage bucket configuration
- [storage_policies.sql](./storage_policies.sql) - All storage policies
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)

---

## ✅ Quick Checklist

**For Backend/n8n**:
- [ ] Use service_role key
- [ ] Store key in secure environment variables
- [ ] Never expose key to client-side
- [ ] Use for admin operations only

**For iOS App**:
- [ ] Use anon key (public)
- [ ] User must sign in (get JWT)
- [ ] All requests use user's JWT token
- [ ] RLS policies protect data

---

**Last Updated**: 2026-01-29
