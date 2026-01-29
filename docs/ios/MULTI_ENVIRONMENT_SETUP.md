# 多環境配置指南

**目的**: 在開發和正式環境之間輕鬆切換

---

## 📋 為什麼 iOS 模擬器不能用 localhost？

### 問題說明

當你在 iOS 模擬器中使用 `localhost` 或 `127.0.0.1` 時：

```
iOS Simulator 中的 localhost ≠ Mac 的 localhost
```

- **在 Mac 上**: `localhost` 指向 Mac 本身 ✅
- **在 iOS 模擬器中**: `localhost` 指向**模擬器自己** ❌

所以如果 n8n 運行在 Mac 上（`localhost:5678`），iOS 模擬器無法通過 `localhost:5678` 連接。

### 解決方案

使用 **Mac 的區域網路 IP 地址**：

```
http://192.168.0.40:5678
```

這樣：
- ✅ iOS 模擬器可以連接
- ✅ 真實 iPhone（同一 Wi-Fi）也可以連接
- ✅ 更接近真實的網路環境

---

## 🗂️ 配置文件結構

```
ios/kantoku/Resources/
├── Config.local.xcconfig          # 你的本地配置（gitignored）
├── Config.development.xcconfig    # 開發環境範本
├── Config.production.xcconfig     # 正式環境範本
└── Config.local.xcconfig.template # 給其他開發者的範本
```

### Config.local.xcconfig

**你的本地設定** - 透過 `#include` 引入環境配置：

```xcconfig
#include "Config.development.xcconfig"

// 可以在這裡覆蓋特定的值
// 例如，如果你的 Mac IP 改變了：
// N8N_BASE_URL = http://$()/192.168.0.XXX:5678
```

### Config.development.xcconfig

**開發環境** - 使用 Mac 本地的 n8n：

```xcconfig
SUPABASE_URL = https://$()/pthqgzpmsgsyssdatxnm.supabase.co
SUPABASE_ANON_KEY = your_anon_key

# 推薦：使用 hostname（穩定，不會因 IP 改變而失效）
N8N_BASE_URL = http://$()/neven.local:5678

# 備用：如果 hostname 不工作，改用 IP
# N8N_BASE_URL = http://$()/192.168.0.40:5678

TEST_EMAIL = test@kantoku.local
TEST_PASSWORD = Test123456!

ENVIRONMENT = development
```

### Config.production.xcconfig

**正式環境** - 使用正式伺服器的 n8n：

```xcconfig
SUPABASE_URL = https://$()/pthqgzpmsgsyssdatxnm.supabase.co
SUPABASE_ANON_KEY = your_anon_key

N8N_BASE_URL = https://$()/n8n.yourdomain.com

TEST_EMAIL = test-prod@kantoku.local
TEST_PASSWORD = ProductionPass123!

ENVIRONMENT = production
```

---

## 🔄 如何切換環境

### 方法 1: 修改 Config.local.xcconfig（推薦）

**切換到開發環境**:
```xcconfig
#include "Config.development.xcconfig"
```

**切換到正式環境**:
```xcconfig
#include "Config.production.xcconfig"
```

### 方法 2: 直接覆蓋值

在 `Config.local.xcconfig` 中：

```xcconfig
#include "Config.development.xcconfig"

// 暫時測試正式環境的 n8n
N8N_BASE_URL = https://$()/n8n.yourdomain.com
```

---

## 🖥️ 推薦：使用 Mac Hostname（更穩定）

### 你的 Mac Hostname

```
neven.local
```

**優勢**:
- ✅ **不會改變**: 即使 IP 地址改變，hostname 保持不變
- ✅ **易記**: `neven.local` 比 `192.168.0.40` 好記
- ✅ **自動解析**: 透過 Bonjour/mDNS 自動找到 Mac

### 查看你的 Hostname

```bash
scutil --get LocalHostName
# 輸出: neven

# 完整的 .local 名稱
echo "$(scutil --get LocalHostName).local"
# 輸出: neven.local
```

### 如何找到你的 Mac IP 地址（備用方案）

如果 hostname 不工作，可以使用 IP 地址：

**方法 1: 終端機**
```bash
ipconfig getifaddr en0  # Wi-Fi
```

**方法 2: 系統偏好設定**
1. **系統偏好設定** → **網路**
2. 查看當前連接的 IP 地址

**當前 IP**: `192.168.0.40` （可能會變）

---

## 📱 測試連接

### 1. 確認 n8n 正在運行

```bash
# 在 Mac 上啟動 n8n
docker-compose up -d

# 檢查狀態
docker ps | grep n8n
```

### 2. 測試從 Mac 連接

```bash
curl http://localhost:5678
```

應該看到 n8n 的回應。

### 3. 測試從同一網路連接

在另一台設備或終端機：

```bash
curl http://192.168.0.40:5678
```

如果成功，iOS 模擬器也能連接。

### 4. 在 iOS 模擬器中測試

1. 在 Xcode 中運行 app
2. 點擊「開始測試」
3. 檢查 n8n 連接測試結果

---

## ⚙️ Hostname vs IP 地址

### 🎯 推薦：使用 Hostname (neven.local)

**優點**:
- ✅ IP 改變也不影響（自動解析）
- ✅ 易於記憶和維護
- ✅ 跨設備都能用

**配置**:
```xcconfig
N8N_BASE_URL = http://$()/neven.local:5678
```

### 🔄 備用方案：使用 IP 地址

**當 hostname 不工作時**（很少發生）：

1. **找到當前 IP**:
   ```bash
   ipconfig getifaddr en0
   ```

2. **更新配置**:
   ```xcconfig
   N8N_BASE_URL = http://$()/192.168.0.40:5678
   ```

3. **Clean Build**:
   - Xcode: `Cmd + Shift + K`
   - 重新 Build: `Cmd + B`

### 設定靜態 IP（可選）

如果你選擇用 IP 而不是 hostname，建議設定靜態 IP 避免改變：

1. **系統偏好設定** → **網路**
2. 選擇你的連接方式
3. 點擊「進階」→「TCP/IP」
4. 配置 IPv4: **手動**
5. 設定固定 IP：`192.168.0.40`
6. 子網路遮罩：`255.255.255.0`
7. 路由器：`192.168.0.1`

---

## 🔒 安全考量

### localhost vs IP 地址

| 方式 | 可訪問範圍 | 安全性 |
|-----|----------|--------|
| `localhost:5678` | 僅 Mac 本身 | 🔒 最安全 |
| `192.168.0.40:5678` | 同一 Wi-Fi 網路 | ⚠️ 區域網路可見 |
| `0.0.0.0:5678` | 所有網路介面 | ⚠️ 可能暴露到外網 |

### 開發環境建議

✅ **使用 Mac IP** (`192.168.0.40`)：
- iOS 模擬器需要
- 可以測試真實 iPhone
- 只在區域網路可見

✅ **確保防火牆設定**：
- 只允許信任的網路
- 不要在公共 Wi-Fi 開發

---

## 🚀 進階設定

### 使用環境變數判斷

在 Swift 代碼中：

```swift
if Constants.Environment.isDevelopment {
    print("🧪 Development mode - using local n8n")
} else {
    print("🚀 Production mode - using production n8n")
}
```

### 顯示當前環境

在測試界面顯示：

```swift
Text("環境: \(Constants.Environment.environment)")
Text("n8n URL: \(Constants.Environment.n8nBaseURL)")
```

---

## 🛠️ 故障排除

### 問題 1: iOS 模擬器無法連接 n8n

**錯誤**: `Connection refused` 或 `Network error`

**解決方案**:
1. 檢查 n8n 是否運行：
   ```bash
   curl http://192.168.0.40:5678
   ```

2. 檢查 IP 地址是否正確：
   ```bash
   ipconfig getifaddr en0
   ```

3. 檢查防火牆設定（Mac）

### 問題 2: 真實 iPhone 無法連接

**條件**:
- iPhone 和 Mac 必須在**同一個 Wi-Fi 網路**

**解決方案**:
1. 確認兩個設備在同一 Wi-Fi
2. 在 iPhone Safari 測試：
   ```
   http://192.168.0.40:5678
   ```
3. 檢查路由器是否啟用 AP 隔離

### 問題 3: 配置改變後沒有生效

**解決方案**:
1. Clean Build Folder: `Cmd + Shift + K`
2. 刪除 DerivedData:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. 重新 Build: `Cmd + B`

---

## 📊 環境對照表

| 環境 | n8n URL | 用途 | 切換方式 |
|-----|---------|------|---------|
| **Development** | `http://192.168.0.40:5678` | 本地開發測試 | `#include "Config.development.xcconfig"` |
| **Production** | `https://n8n.yourdomain.com` | 正式部署 | `#include "Config.production.xcconfig"` |

---

## 📚 相關文檔

- [TEST_ACCOUNT_SETUP.md](./TEST_ACCOUNT_SETUP.md) - 測試帳號配置
- [TESTING_GUIDE.md](./TESTING_GUIDE.md) - 測試指南
- [QUICK_TEST_GUIDE.md](./QUICK_TEST_GUIDE.md) - 快速開始

---

## ✅ 快速檢查清單

開始開發前：

- [ ] n8n 正在運行（`docker ps`）
- [ ] 知道 Mac 的 IP 地址（`ipconfig getifaddr en0`）
- [ ] `Config.local.xcconfig` 引入了正確的環境配置
- [ ] IP 地址配置正確（`N8N_BASE_URL`）
- [ ] Clean Build 後重新測試

---

**最後更新**: 2026-01-29  
**你的 Mac Hostname**: neven.local  
**你的 Mac IP**: 192.168.0.40 (備用)

💡 **提示**: 建議使用 `neven.local` 而不是 IP 地址，更穩定！詳見 [HOSTNAME_SETUP.md](../HOSTNAME_SETUP.md)
