#!/bin/bash

# 創建超級用戶的腳本
# 使用方式：./scripts/create-superuser.sh <用戶名> <電子郵件> <密碼>

if [ "$#" -ne 3 ]; then
    echo "用法: $0 <用戶名> <電子郵件> <密碼>"
    exit 1
fi

USERNAME=$1
EMAIL=$2
PASSWORD=$3

# 使用 Docker Compose 執行命令
echo "創建超級用戶: $USERNAME ($EMAIL)..."
docker-compose exec core python manage.py shell -c "
from django.contrib.auth import get_user_model;
User = get_user_model();
if not User.objects.filter(username='$USERNAME').exists():
    User.objects.create_superuser('$USERNAME', '$EMAIL', '$PASSWORD');
    print('超級用戶創建成功！');
else:
    print('用戶名已存在！');
"