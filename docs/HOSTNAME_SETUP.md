# 使用 Mac Hostname 配置指南

**Mac Hostname**: `neven.local`  
**優勢**: 比 IP 地址更穩定，不受 DHCP 影響

---

## ✅ 為什麼用 Hostname 比 IP 好？

### IP 地址的問題

```
今天: http://192.168.0.40:5678  ✅ 可以連接
明天: DHCP 改變 IP...
     http://192.168.0.40:5678  ❌ 連接失敗
     新 IP 是 192.168.0.45      😱 需要重新配置
```

### Hostname 的優勢

```
永遠: http://neven.local:5678  ✅ 永遠可以連接
```

- ✅ **不會改變**: hostname 是固定的
- ✅ **易記**: `neven.local` 比 `192.168.0.40` 好記
- ✅ **跨設備**: iOS 模擬器、真實 iPhone 都能用
- ✅ **自動解析**: 通過 Bonjour/mDNS 自動找到 Mac

---

## 🔧 當前配置

### iOS App (`Config.development.xcconfig`)

```xcconfig
N8N_BASE_URL = http://$()/neven.local:5678
```

### Docker Compose (`docker-compose.yml`)

```yaml
environment:
  - N8N_HOST=neven.local
  - WEBHOOK_URL=http://neven.local:5678/
```

### Environment Variables (`.env`)

```bash
N8N_URL=http://neven.local:5678
```

---

## 🧪 測試連接

### 1. 從 Mac 測試

```bash
curl http://neven.local:5678
```

應該看到 n8n 的回應。

### 2. 從 iOS 模擬器測試

1. 在 Xcode 運行 app
2. 點擊「開始測試」
3. 檢查 n8n 測試結果

### 3. 從真實 iPhone 測試

1. 確保 iPhone 和 Mac 在**同一個 Wi-Fi**
2. 在 Safari 打開：`http://neven.local:5678`
3. 應該能看到 n8n 登入畫面

---

## 🔍 Hostname 是如何工作的？

### Bonjour/mDNS

```
iOS 設備問：「neven.local 在哪裡？」
     ↓
Bonjour/mDNS 自動廣播查詢
     ↓
Mac 回答：「我在這裡！IP 是 192.168.0.40」
     ↓
iOS 設備連接到 192.168.0.40:5678
```

這一切都是**自動的**，不需要手動配置 DNS。

---

## 🛠️ 如何查看/修改你的 Mac Hostname

### 查看當前 Hostname

```bash
# 方法 1: scutil
scutil --get LocalHostName

# 方法 2: hostname
hostname

# 方法 3: 完整的 .local 名稱
dns-sd -G v4 $(scutil --get LocalHostName).local
```

### 修改 Hostname（如果需要）

**系統偏好設定**:
1. **系統偏好設定** → **共享**
2. 看到「電腦名稱」→ 例如：`neven`
3. 自動生成 hostname：`neven.local`

**終端機**:
```bash
# 設定本地 hostname
sudo scutil --set LocalHostName neven

# 設定電腦名稱
sudo scutil --set ComputerName "Neven's Mac"

# 設定 Bonjour 名稱
sudo scutil --set HostName neven.local
```

修改後重啟網路：
```bash
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

---

## 🚀 重新啟動 n8n（使用新配置）

```bash
# 停止舊的 n8n
docker-compose down

# 使用新配置啟動
docker-compose up -d

# 查看日誌
docker-compose logs -f n8n
```

---

## 📱 iOS App 連接流程

```
1. iOS App 讀取配置
   N8N_BASE_URL = http://neven.local:5678

2. iOS 系統解析 hostname
   neven.local → 192.168.0.40 (透過 mDNS)

3. App 連接到 Mac
   http://192.168.0.40:5678

4. 測試成功！✅
```

---

## ⚠️ 注意事項

### ✅ 可以運作的情況

- ✅ iOS 模擬器連接 Mac
- ✅ 真實 iPhone（同 Wi-Fi）連接 Mac
- ✅ Mac 連接自己（localhost 或 neven.local 都行）
- ✅ 其他 Mac/電腦（同 Wi-Fi）連接

### ❌ 不能運作的情況

- ❌ 不同 Wi-Fi 網路
- ❌ 沒有 mDNS 支援的系統（很少見）
- ❌ 防火牆阻擋 mDNS（port 5353）

---

## 🔧 故障排除

### 問題 1: `neven.local` 無法解析

**檢查**:
```bash
# 檢查 mDNS 服務是否運行
sudo launchctl list | grep mDNSResponder

# 測試解析
ping -c 1 neven.local
```

**解決**:
```bash
# 重啟 mDNS 服務
sudo killall -HUP mDNSResponder
```

### 問題 2: iOS 模擬器找不到 hostname

**原因**: 可能是 Xcode 版本問題

**解決**: 使用 IP 地址作為備用：
```xcconfig
# Config.local.xcconfig
N8N_BASE_URL = http://$()/192.168.0.40:5678
```

### 問題 3: 真實 iPhone 無法連接

**檢查清單**:
- [ ] iPhone 和 Mac 在同一個 Wi-Fi？
- [ ] Mac 防火牆允許連接？
- [ ] n8n 正在運行？（`docker ps`）

**測試**:
```bash
# 在 iPhone Safari 測試
http://neven.local:5678
```

---

## 📊 配置對照表

| 環境 | n8n URL | 何時使用 |
|-----|---------|---------|
| **開發（推薦）** | `http://neven.local:5678` | 本地開發，穩定的 hostname |
| **開發（備用）** | `http://192.168.0.40:5678` | hostname 不工作時 |
| **正式** | `https://n8n.yourdomain.com` | 未來部署到雲端 |

---

## 🎯 快速測試腳本

創建一個測試腳本 `test-n8n.sh`：

```bash
#!/bin/bash

echo "🧪 測試 n8n 連接..."
echo ""

# 測試 1: 本地連接
echo "1️⃣ 測試 localhost:5678"
curl -s -o /dev/null -w "%{http_code}" http://localhost:5678
echo ""

# 測試 2: Hostname 連接
echo "2️⃣ 測試 neven.local:5678"
curl -s -o /dev/null -w "%{http_code}" http://neven.local:5678
echo ""

# 測試 3: IP 連接
IP=$(ipconfig getifaddr en0)
echo "3️⃣ 測試 ${IP}:5678"
curl -s -o /dev/null -w "%{http_code}" http://${IP}:5678
echo ""

echo "✅ 測試完成！"
echo ""
echo "如果都返回 200 或 401，代表 n8n 可以連接"
echo "401 是正常的（需要登入）"
```

使用：
```bash
chmod +x test-n8n.sh
./test-n8n.sh
```

---

## 📚 相關文檔

- [MULTI_ENVIRONMENT_SETUP.md](./ios/MULTI_ENVIRONMENT_SETUP.md) - 多環境配置
- [TEST_ACCOUNT_SETUP.md](./ios/TEST_ACCOUNT_SETUP.md) - 測試帳號配置
- [TESTING_GUIDE.md](./ios/TESTING_GUIDE.md) - 測試指南

---

## ✅ 配置總結

**已完成**:
- ✅ iOS App 配置：`http://neven.local:5678`
- ✅ Docker Compose 配置：使用 `neven.local`
- ✅ 環境變數配置：使用 `neven.local`

**優勢**:
- ✅ 不用擔心 IP 改變
- ✅ 更容易記憶和維護
- ✅ 適用於所有設備（同 Wi-Fi）

**下一步**:
1. 重啟 n8n：`docker-compose restart`
2. Clean Build iOS App：`Cmd + Shift + K`
3. 運行測試：檢查 n8n 連接

---

**最後更新**: 2026-01-29  
**Mac Hostname**: neven.local  
**Mac IP**: 192.168.0.40
