#!/bin/bash
set -e

echo "====================================="
echo "启动 aria2-with-aria2ng 容器"
echo "下载目录挂载: /Downloads:/downloads"
echo "====================================="

# 停止删除旧容器
docker compose down

# 使用已构建镜像后台启动
docker compose up -d

echo ""
echo "✅容器已启动"
docker compose ps

echo ""
echo "访问地址：http://$(hostname -I | awk '{print $1}'):8080"
if [ -n "$RPC_SECRET" ]; then
    echo "RPC密钥：$RPC_SECRET"
else
    echo "RPC密钥：未启用（未设置 RPC_SECRET，AriaNg 密钥留空）"
fi
