#!/bin/bash
set -e

# 顯示歡迎訊息
echo "============================================="
echo "教學語音處理與摘要管理平台 - 開發環境啟動腳本"
echo "============================================="

# 檢查是否已設置環境
if [ ! -f ".env" ]; then
  echo "錯誤：找不到 .env 檔案，請先運行 ./scripts/setup-dev.sh"
  exit 1
fi

# 啟動服務
echo "啟動開發環境..."
docker-compose up -d

# 等待服務就緒
echo "等待服務就緒..."
sleep 5

# 顯示服務狀態
echo "服務狀態："
docker-compose ps

# 顯示訪問資訊
echo ""
echo "服務已啟動！您可以通過以下地址訪問："
echo "前端：http://localhost:3000"
echo "API 閘道：http://localhost:8000"
echo "Django 管理介面：http://localhost:8002/admin"
echo ""
echo "如需查看服務日誌，請運行：docker-compose logs -f [服務名稱]"
echo "如需停止服務，請運行：docker-compose down"