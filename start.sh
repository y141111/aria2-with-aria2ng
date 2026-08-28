#!/bin/bash
set -e

echo "====================================="
echo "启动 aria2-with-aria2ng 容器"
echo "下载目录挂载: /home/wangyu/localdata:/downloads"
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
echo "RPC密钥：MyStrongSecret123"
