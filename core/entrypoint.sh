#!/bin/bash
set -e

# 等待 PostgreSQL 就緒
echo "Waiting for PostgreSQL to be available..."
timeout 60s bash -c '
until nc -z $DB_HOST $DB_PORT; do
    echo "Waiting for PostgreSQL to be available..."
    sleep 1
done
'

# 等待 Redis 就緒
echo "Waiting for Redis to be available..."
timeout 60s bash -c '
until nc -z $REDIS_HOST $REDIS_PORT; do
    echo "Waiting for Redis to be available..."
    sleep 1
done
'

# 等待 Kafka 就緒
echo "Waiting for Kafka to be available..."
timeout 60s bash -c '
until nc -z $KAFKA_BOOTSTRAP_SERVERS 9092; do
    echo "Waiting for Kafka to be available..."
    sleep 1
done
'

# 輸出環境變數 (僅供調試使用)
echo "Environment:"
echo "DJANGO_SETTINGS_MODULE=$DJANGO_SETTINGS_MODULE"
echo "DATABASE_URL=$DATABASE_URL"

# 執行資料庫遷移
echo "Running database migrations..."
python manage.py migrate

# 收集靜態文件
echo "Collecting static files..."
python manage.py collectstatic --noinput

# 創建超級用戶 (如果未指定密碼，則會使用環境變數中的密碼)
if [ -n "$DJANGO_SUPERUSER_EMAIL" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "Creating superuser..."
    python manage.py createsuperuser --noinput || echo "Superuser already exists."
fi

# 啟動 Celery Worker (背景執行)
if [ "${CELERY_WORKER_ENABLED:-true}" = "true" ]; then
    echo "Starting Celery worker..."
    celery -A core_project worker --loglevel=info --concurrency=4 &
fi

# 啟動 Celery Beat (背景執行)
if [ "${CELERY_BEAT_ENABLED:-true}" = "true" ]; then
    echo "Starting Celery beat..."
    celery -A core_project beat --loglevel=info &
fi

# 執行指定的命令
exec "$@"