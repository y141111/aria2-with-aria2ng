#!/bin/sh
set -e

ARIA2_CONF=/etc/aria2/aria2.conf

if [ -n "$RPC_SECRET" ]; then
    echo "[entrypoint] 使用环境变量 RPC_SECRET 覆盖 rpc-secret"
    sed -i "s#^rpc-secret=.*#rpc-secret=${RPC_SECRET}#" "$ARIA2_CONF"
    if ! grep -q "^rpc-secret=" "$ARIA2_CONF"; then
        echo "rpc-secret=${RPC_SECRET}" >> "$ARIA2_CONF"
    fi
else
    echo "[entrypoint] 未设置 RPC_SECRET，使用 aria2.conf 中的默认密钥"
fi

exec "$@"