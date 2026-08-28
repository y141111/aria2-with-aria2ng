# aria2-with-aria2ng

一个基于 Docker 的一体化下载器：**aria2 + AriaNg Web 管理界面 + nginx + supervisord**。构建后即可得到一个带 Web UI 的 aria2 下载服务，开箱即用。

## 功能特性

- **aria2** 多协议下载：HTTP/HTTPS、FTP、BT/磁力链接、Metalink
- **AriaNg** 现代化 Web 管理界面，无需任何浏览器插件
- **supervisord** 统一管理 aria2 与 nginx 进程，崩溃自动重启
- 内置国内镜像源（清华 tuna + 阿里云 aliyun），并带自动重试，构建稳定
- 已配置常用 BT 优化参数（DHT、LPD、PEX、tracker 列表等）

## 目录结构

```
.
├── Dockerfile          # 构建镜像（alpine:3.20 + aria2 + nginx + supervisor）
├── docker-compose.yml  # 容器编排配置
├── aria2.conf          # aria2 配置（含 RPC、BT、下载路径）
├── supervisord.conf    # supervisord 进程管理配置
├── aria2ng/            # AriaNg 前端文件
├── ariang.zip          # AriaNg 安装包备份（构建时未使用）
├── start.sh            # 启动容器脚本
└── build-image.sh      # 构建镜像脚本
```

## 快速开始

### 前置条件

- 已安装 Docker Engine 和 Docker Compose 插件（`docker compose version` 可用）
- 宿主机准备一个下载目录，例如 `/Downloads`

### 1. 构建镜像

```bash
sudo ./build-image.sh
```

脚本会先 `docker compose down` 清理旧容器，再执行 `docker compose build`。

### 2. 启动容器

```bash
sudo ./start.sh
```

启动完成后访问：`http://<宿主机IP>:8080`

> `start.sh` 中下载目录写死为 `/Downloads`，如需修改请编辑 `docker-compose.yml` 中的 `volumes` 挂载。

## 使用说明

### 连接 RPC

Web 界面默认会连接 **浏览器本机** 的 `localhost:6800`，所以在服务器上访问时，需要把 RPC 地址改成服务器地址：

1. 打开 `http://<宿主机IP>:8080`
2. 左侧 **AriaNg 设置** → **RPC** → **Aria2 RPC 地址** 改为：

   ```
   ws://<宿主机IP>:6800/jsonrpc
   ```

3. **Aria2 RPC 密钥** 填：

   ```
   MyStrongSecret123
   ```

4. 保存即可，右上角出现绿色状态即为连接成功。

> 密钥可在 `aria2.conf` 的 `rpc-secret` 项修改（改后需重新构建镜像）。

### 下载目录

容器内下载目录为 `/downloads`，默认映射到宿主机 `/Downloads`，两者内容互通。

### BT 监听端口

`19101`（TCP + UDP）用于 BT/DHT 数据交换，已在 `docker-compose.yml` 中映射，勿在防火墙中屏蔽。

## 端口说明

| 端口 | 用途 |
| --- | --- |
| `8080`（宿主机）→ `80`（容器） | AriaNg Web 界面（nginx） |
| `6800` | aria2 JSON-RPC |
| `19101` (TCP/UDP) | BT/DHT 下载监听 |

## 常用命令

```bash
# 构建镜像
sudo ./build-image.sh

# 启动（前台）与查看状态
docker compose up
docker compose ps

# 查看日志
docker compose logs -f aria2-with-aria2ng

# 重启容器
docker compose restart

# 停止并删除容器
docker compose down
```

## 常见问题

### 构建失败：`temporary error (try again later)`

多发生在 `apk update && apk add` 步骤，是构建容器访问镜像源网络波动所致。当前方案已内置多源（tuna + aliyun）和 5 次重试，一般重跑一次即可；若持续失败，手动验证源连通性后调整 `Dockerfile` 中的镜像源地址。

### 页面样式/图标显示异常

确认没有改动过 `Dockerfile` 中 `include /etc/nginx/mime.types;` 一行，缺少它会导致 nginx 按流式返回静态文件。

### 下载文件无法保存

检查目标目录是否存在且有写权限，并确认 `docker-compose.yml` 的 `volumes` 挂载路径正确。

### 如何修改 RPC 密钥

编辑 `aria2.conf` 的 `rpc-secret`，然后重新构建镜像：

```bash
sudo docker compose down && sudo docker compose build && sudo docker compose up -d
```

## 技术栈

| 组件 | 说明 |
| --- | --- |
| 基础镜像 | `alpine:3.20` |
| aria2 | 下载引擎，以 daemon 由 supervisord 拉起 |
| nginx | 托管 AriaNg 静态页面 |
| supervisord | 进程管理（aria2c + nginx） |
| 前端 | AriaNg（aria-ng） |

## 配置参考

- `aria2.conf` 主要基于 P3TERX 的 aria2 配置模板修改，BT tracker 与下载参数均已调优
- `supervisord.conf` 将 aria2 与 nginx 日志重定向到 stdout/stderr，方便 `docker compose logs` 查看

## 第三方声明

本项目的 Web 前端 **AriaNg** 来源于 [mayswind/AriaNg](https://github.com/mayswind/AriaNg)，版本 **v1.3.14**，使用 MIT 许可证（见 `aria2ng/LICENSE`）。