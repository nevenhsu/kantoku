# Test Account Configuration Guide

**Purpose**: Configure test account credentials for iOS connection testing

---

## 📋 Overview

The iOS app uses a dedicated test account to verify Supabase authentication during connection tests. This account is configured in `Config.local.xcconfig` to keep credentials secure and separate from production code.

---

## 🔧 Configuration Files

### 1. Config.local.xcconfig

**Location**: `ios/kantoku/Resources/Config.local.xcconfig`

```xcconfig
// Local secrets - DO NOT COMMIT
SUPABASE_URL = https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY = YOUR_ANON_KEY

N8N_BASE_URL = http://localhost:5678

// Test account credentials (for connection testing)
TEST_EMAIL = test@kantoku.local
TEST_PASSWORD = Test123456!
```

**Note**: This file is gitignored and never committed to version control.

### 2. Config.local.xcconfig.template

**Location**: `ios/kantoku/Resources/Config.local.xcconfig.template`

A template file for other developers. Copy this to `Config.local.xcconfig` and fill in your values.

---

## 🚀 Setup Instructions

### Step 1: Create Test User in Supabase

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Navigate to Authentication**
   - Click on "Authentication" in the left sidebar
   - Click on "Users" tab

3. **Create Test User**
   - Click "Add user" or "Create new user"
   - Fill in:
     - **Email**: `test@kantoku.local`
     - **Password**: `Test123456!`
     - **Auto Confirm User**: ✅ Enable this

4. **Verify User Created**
   - The user should appear in the users list
   - Status should show as "Confirmed"

### Step 2: Configure iOS App

The credentials are already configured in `Config.local.xcconfig`. If you need to change them:

1. **Open Config File**
   ```bash
   open ios/kantoku/Resources/Config.local.xcconfig
   ```

2. **Update Credentials** (if needed)
   ```xcconfig
   TEST_EMAIL = your-test-email@example.com
   TEST_PASSWORD = YourTestPassword123!
   ```

3. **Clean Build** (if you changed values)
   - In Xcode: `Cmd + Shift + K` (Clean Build Folder)
   - Then: `Cmd + B` (Build)

---

## 🧪 How It Works

### Connection Flow

```
1. App reads credentials from Constants.Environment
   ↓
2. Constants.Environment reads from Info.plist
   ↓
3. Info.plist gets values from Config.local.xcconfig
   ↓
4. ConnectionTestService uses these credentials to test auth
```

### Code Structure

**Constants.swift** (`ios/kantoku/Utils/Constants.swift:200-206`)
```swift
enum Environment {
    static let testEmail = Bundle.main.object(forInfoDictionaryKey: "TEST_EMAIL") as? String ?? ""
    static let testPassword = Bundle.main.object(forInfoDictionaryKey: "TEST_PASSWORD") as? String ?? ""
}
```

**ConnectionTestService.swift** (`ios/kantoku/Services/ConnectionTestService.swift:72-127`)
```swift
func testSupabaseAuth() async -> TestResult {
    let testEmail = Constants.Environment.testEmail
    let testPassword = Constants.Environment.testPassword
    
    let session = try await supabase.auth.signIn(
        email: testEmail,
        password: testPassword
    )
    // ...
}
```

---

## ✅ Testing

### Run Connection Tests

1. **Open Xcode**
   ```bash
   open ios/kantoku.xcodeproj
   ```

2. **Run App** (`Cmd + R`)

3. **Click "開始測試"**

4. **Verify Auth Test**
   - Should show: ✅ Supabase Auth - 認證成功
   - Details: Test user ID: xxxxxxxx...

### Expected Results

#### ✅ Success
```
✅ Supabase Auth
   認證成功
   0.25s
   Test user ID: abc12345...
```

#### ❌ Common Errors

**Invalid login credentials**
```
❌ Supabase Auth
   測試帳號登入失敗
   請確認測試帳號已創建：test@kantoku.local
```
**Solution**: Create the test user in Supabase Dashboard (see Step 1 above)

**Email not confirmed**
```
❌ Supabase Auth
   Email 未驗證
   請在 Supabase Dashboard 驗證測試帳號
```
**Solution**: In Supabase Dashboard → Authentication → Users → Find user → Confirm email

**Missing credentials in config**
```
❌ Supabase Auth
   Auth 服務錯誤
   Invalid email or password format
```
**Solution**: Check `Config.local.xcconfig` has TEST_EMAIL and TEST_PASSWORD filled in

---

## 🔒 Security Considerations

### ✅ Safe Practices

1. **Never commit** `Config.local.xcconfig`
   - Already in `.gitignore`
   - Contains sensitive credentials

2. **Use dedicated test account**
   - Don't use real user credentials
   - `test@kantoku.local` is a non-deliverable email domain

3. **Keep test data isolated**
   - Test account only used for connection testing
   - Automatically signs out after test completes

### ⚠️ Important Notes

- The test account is **only for local development**
- Don't use production user credentials for testing
- The session is **automatically cleaned up** after the auth test

---

## 🔄 Session Cleanup

The test service automatically signs out after the auth test to prevent interference with other tests:

```swift
func runAllTests() async -> [TestResult] {
    results.append(await testSupabaseConnection())
    results.append(await testSupabaseAuth())
    
    // Clean up - sign out test user
    try? await supabase.auth.signOut()
    
    results.append(await testSupabaseDatabase())
    // ... continue with other tests
}
```

---

## 🛠️ Troubleshooting

### Problem: Test user not working after Supabase reset

**Solution**: Recreate the test user in Supabase Dashboard

### Problem: Credentials not updating after changing Config.local.xcconfig

**Solution**: 
1. Clean Build Folder (`Cmd + Shift + K`)
2. Restart Xcode
3. Build again (`Cmd + B`)

### Problem: "Bundle.main.object returns nil"

**Solution**: 
1. Check `Project-Info.plist` has TEST_EMAIL and TEST_PASSWORD keys
2. Check Xcode project settings include `Config.local.xcconfig`

### Problem: Need different test credentials per environment

**Solution**: Create multiple config files:
- `Config.local.xcconfig` (local development)
- `Config.staging.xcconfig` (staging environment)
- Use Xcode build configurations to switch between them

---

## 📚 Related Documentation

- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - Complete testing guide
- [QUICK_TEST_GUIDE.md](./QUICK_TEST_GUIDE.md) - 5-minute quick start
- [TEST_SETUP_COMPLETE.md](./TEST_SETUP_COMPLETE.md) - Setup completion report
- [CONFIGURATION_COMPLETE.md](./CONFIGURATION_COMPLETE.md) - Environment configuration

---

## 📝 Summary

**What You Need**:
1. Test user created in Supabase: `test@kantoku.local`
2. Credentials in `Config.local.xcconfig`
3. Clean build after any config changes

**What It Does**:
- Verifies Supabase authentication works
- Tests with dedicated test account
- Automatically cleans up session after test
- Keeps credentials secure (not in source code)

---

**Last Updated**: 2026-01-29
