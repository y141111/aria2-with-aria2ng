#!/bin/bash
set -e

echo "====================================="
echo "开始构建 aria2-with-aria2ng 镜像"
echo "项目目录: $(pwd)"
echo "====================================="

# 清理旧容器
docker compose down

# 构建镜像，不启动
docker compose build

echo ""
echo "✅镜像构建完成"
docker images | grep aria2-with-aria2ng
