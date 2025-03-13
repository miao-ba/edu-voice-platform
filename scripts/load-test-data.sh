#!/bin/bash

# 載入測試資料的腳本

echo "載入測試資料..."

# 執行 SQL 腳本
docker-compose exec postgres psql -U eduvoice -d eduvoice -f /scripts/db/init-default-data.sql

# 或者使用 Django 的 loaddata 命令
docker-compose exec core python manage.py loaddata test_data

echo "測試資料載入完成！"