# 建置階段
FROM node:18-alpine as build

WORKDIR /app

# 安裝依賴
COPY package*.json ./
RUN npm ci

# 複製源碼
COPY . .

# 構建應用
RUN npm run build

# 運行階段
FROM nginx:stable-alpine

# 複製 nginx 配置
COPY deployment/docker/frontend/nginx.conf /etc/nginx/conf.d/default.conf

# 從建置階段複製構建結果
COPY --from=build /app/dist /usr/share/nginx/html

# 設置環境變數替換腳本
COPY deployment/docker/frontend/env.sh /docker-entrypoint.d/40-env.sh
RUN chmod +x /docker-entrypoint.d/40-env.sh

# 暴露連接埠
EXPOSE 80

# 啟動 Nginx
CMD ["nginx", "-g", "daemon off;"]