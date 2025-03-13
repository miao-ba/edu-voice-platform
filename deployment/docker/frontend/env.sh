#!/bin/sh

# 替換環境變數到前端構建的 JavaScript 文件中
# 這個腳本會在容器啟動時運行

# 定義環境變數配置文件
ENV_CONFIG_FILE="/usr/share/nginx/html/env-config.js"

# 創建環境變數配置文件
echo "window.ENV = {" > $ENV_CONFIG_FILE
echo "  API_URL: '${API_URL:-http://localhost:8000}'," >> $ENV_CONFIG_FILE
echo "  WEBSOCKET_URL: '${WEBSOCKET_URL:-ws://localhost:8000/ws}'," >> $ENV_CONFIG_FILE
echo "  ENV: '${NODE_ENV:-production}'," >> $ENV_CONFIG_FILE
echo "  VERSION: '${VERSION:-0.1.0}'," >> $ENV_CONFIG_FILE
echo "};" >> $ENV_CONFIG_FILE

echo "Environment variables injected to $ENV_CONFIG_FILE"