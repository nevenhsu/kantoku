#!/bin/bash

# n8n 連接測試腳本
# 測試從不同方式連接到 n8n

echo "🧪 測試 n8n 連接..."
echo "================================"
echo ""

# 顏色定義
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 測試函數
test_connection() {
    local url=$1
    local name=$2
    
    echo -n "Testing $name... "
    
    # 嘗試連接（-s 靜默模式，-o /dev/null 不輸出內容，-w 只顯示 HTTP 狀態碼）
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "$url" 2>/dev/null)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "401" ]; then
        echo -e "${GREEN}✅ OK${NC} (HTTP $http_code)"
        return 0
    else
        echo -e "${RED}❌ FAILED${NC} (HTTP $http_code)"
        return 1
    fi
}

# 測試 1: localhost
echo "1️⃣  localhost (僅 Mac 本身)"
test_connection "http://localhost:5678" "localhost:5678"
echo ""

# 測試 2: hostname
echo "2️⃣  Hostname (推薦用於 iOS)"
test_connection "http://neven.local:5678" "neven.local:5678"
echo ""

# 測試 3: IP 地址
IP=$(ipconfig getifaddr en0 2>/dev/null)
if [ -n "$IP" ]; then
    echo "3️⃣  IP 地址 (備用方案)"
    test_connection "http://$IP:5678" "$IP:5678"
    echo ""
else
    echo -e "${YELLOW}⚠️  無法獲取 IP 地址（可能未連接 Wi-Fi）${NC}"
    echo ""
fi

# 總結
echo "================================"
echo "📋 總結："
echo ""
echo "如果返回 401 (Unauthorized)，這是正常的！"
echo "代表 n8n 正在運行，需要登入驗證。"
echo ""
echo "如果返回 200 (OK)，代表 n8n 可以訪問。"
echo ""
echo "如果 FAILED，請檢查："
echo "  1. n8n 是否運行：docker ps | grep n8n"
echo "  2. 防火牆設定"
echo "  3. 網路連接"
echo ""
echo "================================"
echo ""
echo "💡 iOS App 應該使用："
echo -e "${GREEN}http://neven.local:5678${NC}"
echo ""
