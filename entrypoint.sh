#!/bin/sh
set -e

ARIA2_CONF=/etc/aria2/aria2.conf

if [ -n "$RPC_SECRET" ]; then
    echo "[entrypoint] RPC_SECRET 已设置，启用 RPC 密钥: ${RPC_SECRET}"
    sed -i "s#^rpc-secret=.*#rpc-secret=${RPC_SECRET}#" "$ARIA2_CONF"
    if ! grep -q "^rpc-secret=" "$ARIA2_CONF"; then
        echo "rpc-secret=${RPC_SECRET}" >> "$ARIA2_CONF"
    fi
else
    echo "[entrypoint] RPC_SECRET 未设置，禁用 RPC 密钥（AriaNg 密钥留空即可）"
    sed -i "/^rpc-secret=/d" "$ARIA2_CONF"
fi

echo "[entrypoint] aria2 RPC 监听端口: 6800 (容器内)"
echo "[entrypoint] nginx WebUI 监听端口: 80 (容器内)"
echo "[entrypoint] 宿主机映射: 8080 -> 80，Web 管理界面 http://<宿主机IP>:8080"

exec "$@"