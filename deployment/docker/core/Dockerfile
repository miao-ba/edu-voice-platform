FROM python:3.11-slim

WORKDIR /app

# 安裝系統依賴
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    gettext \
    netcat-traditional \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 設置 Python 環境
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 安裝 Python 依賴
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 創建必要目錄
RUN mkdir -p /app/static /app/media /app/logs
RUN chmod -R 755 /app/static /app/media /app/logs

# 複製專案檔案
COPY . .

# 設定入口點腳本
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]

# 預設命令
CMD ["gunicorn", "core_project.wsgi:application", "--bind", "0.0.0.0:8002", "--workers", "4", "--threads", "4", "--timeout", "60"]