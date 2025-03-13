#!/bin/bash
set -e

# 顯示歡迎訊息
echo "============================================="
echo "教學語音處理與摘要管理平台 - 開發環境設置腳本"
echo "============================================="

# 檢查必要工具
echo "檢查必要工具..."
command -v docker >/dev/null 2>&1 || { echo "需要安裝 Docker，請參考：https://docs.docker.com/get-docker/"; exit 1; }
command -v docker-compose >/dev/null 2>&1 || { echo "需要安裝 Docker Compose，請參考：https://docs.docker.com/compose/install/"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "需要安裝 Git，請參考：https://git-scm.com/downloads"; exit 1; }

# 創建環境檔案
echo "創建環境檔案..."
if [ ! -f ".env" ]; then
  echo "創建根目錄 .env 檔案..."
  cp ".env.example" ".env"
  echo ".env 已創建"
else
  echo ".env 已存在，跳過"
fi

for service in core api-gateway audio-service ai-service content-service auth-service; do
  if [ ! -f "$service/.env" ]; then
    echo "創建 $service/.env 檔案..."
    cp "$service/.env.example" "$service/.env"
    echo "$service/.env 已創建"
  else
    echo "$service/.env 已存在，跳過"
  fi
done

# 創建必要目錄
echo "創建必要目錄..."
mkdir -p media static logs

# 設置目錄權限
echo "設置目錄權限..."
chmod -R 755 media static logs

# 拉取最新代碼
echo "拉取最新代碼..."
git pull

# 建立 Docker 網絡
echo "建立 Docker 網絡..."
docker network create eduvoice-network 2>/dev/null || true

echo "環境設置完成！"
echo "您現在可以運行 './scripts/start-dev.sh' 來啟動開發環境。"