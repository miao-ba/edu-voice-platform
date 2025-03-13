#!/bin/bash

# 重置資料庫的腳本
# 警告：此腳本會刪除所有資料！

echo "警告：此操作將刪除所有資料庫資料！"
read -p "確定要繼續嗎？ (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "操作已取消"
    exit 1
fi

echo "重置資料庫中..."

# 停止所有容器
docker-compose down

# 刪除資料卷
docker volume rm edu-voice-platform_postgres_data
docker volume rm edu-voice-platform_pgvector_data
docker volume rm edu-voice-platform_redis_data
docker volume rm edu-voice-platform_kafka_data

# 重新啟動容器
docker-compose up -d postgres pgvector redis kafka

# 等待資料庫就緒
echo "等待資料庫就緒..."
sleep 10

# 執行初始化腳本
echo "執行初始化腳本..."
docker-compose exec postgres psql -U eduvoice -d eduvoice -f /scripts/db/init-postgres.sql
docker-compose exec postgres psql -U eduvoice -d eduvoice -f /scripts/db/init-default-data.sql

# 啟動其他服務
docker-compose up -d

echo "資料庫已重置！"