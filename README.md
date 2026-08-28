# aria2-with-aria2ng

一个基于 Docker 的一体化下载器：**aria2 + AriaNg Web 管理界面 + nginx + supervisord**，开箱即用，部署即得一个带 Web UI 的下载服务。

## 功能特性

- **aria2** 多协议下载：HTTP/HTTPS、FTP、BT/磁力链接、Metalink
- **AriaNg** 现代化 Web 管理界面，无需任何浏览器插件
- **supervisord** 统一管理 aria2 与 nginx 进程，崩溃自动重启
- 已配置常用 BT 优化参数（DHT、LPD、PEX、tracker 列表等）
- 镜像已发布到 GitHub Container Registry，无需本地编译即可部署

## 目录结构

```
.
├── Dockerfile          # 构建镜像（alpine:3.20 + aria2 + nginx + supervisor）
├── docker-compose.yml  # 本机构建/启动编排配置
├── aria2.conf          # aria2 配置（含 RPC、BT、下载路径）
├── supervisord.conf    # supervisord 进程管理配置
├── aria2ng/            # AriaNg 前端文件（v1.3.14）
├── ariang.zip          # AriaNg 安装包备份（构建时未使用）
├── start.sh            # 本机构建后启动容器脚本
└── build-image.sh      # 本机构建镜像脚本
```

---

## 一、快速部署（推荐：直接用现成镜像）

无需自己构建，直接拉取 GitHub Actions 自动构建好的镜像：

```
ghcr.io/y141111/aria2-with-aria2ng:latest
```

### 前置条件

- 已安装 Docker Engine 和 Docker Compose 插件（`docker compose version` 可用）
- 创建宿主机下载目录：`mkdir -p /Downloads`

### 方式 A：docker compose（推荐）

在任意目录创建 `docker-compose.yml`：

```yaml
services:
  aria2-with-aria2ng:
    image: ghcr.io/y141111/aria2-with-aria2ng:latest
    container_name: aria2-with-aria2ng
    restart: always
    ports:
      - "8080:80"
      - "6800:6800"
      - "19101:19101"
      - "19101:19101/udp"
    environment:
      RPC_SECRET: MyStrongSecret123   # 自定义 RPC 密钥，可修改
    volumes:
      - /Downloads:/downloads
```

启动：

```bash
mkdir -p /Downloads
docker compose up -d
docker compose ps
```

### 方式 B：docker run

```bash
mkdir -p /Downloads
docker run -d \
  --name aria2-with-aria2ng \
  --restart always \
  -p 8080:80 \
  -p 6800:6800 \
  -p 19101:19101 \
  -p 19101:19101/udp \
  -e RPC_SECRET=MyStrongSecret123 \
  -v /Downloads:/downloads \
  ghcr.io/y141111/aria2-with-aria2ng:latest
```

### 配置 RPC 连接

1. 浏览器打开 `http://<宿主机IP>:8080`
2. 左侧 **AriaNg 设置** → **RPC** → **Aria2 RPC 地址** 改为：

   ```
   ws://<宿主机IP>:6800/jsonrpc
   ```

3. **Aria2 RPC 密钥** 填部署时通过 `RPC_SECRET` 环境变量指定的值，默认：

   ```
   MyStrongSecret123
   ```

4. 保存后，右上角出现绿色状态即为连接成功。

> 若拉取受网络限流影响，可先执行 `docker login ghcr.io` 登录一次。

---

## 二、本机构建（从源码编译）

当你需要修改 `aria2.conf`、`Dockerfile` 等配置后自己构建镜像时，使用本仓库的自带脚本。

### 前置条件

- 已安装 Docker Engine 和 Docker Compose 插件
- 已安装 `git`

### 1. 获取源码

```bash
git clone https://github.com/y141111/aria2-with-aria2ng.git
cd aria2-with-aria2ng
```

### 2. 构建镜像

```bash
sudo ./build-image.sh
```

脚本会先 `docker compose down` 清理旧容器，再执行 `docker compose build`。

> `Dockerfile` 已内置国内镜像源（清华 tuna + 阿里云 aliyun）和重试机制，构建更稳定。

### 3. 启动容器

```bash
sudo ./start.sh
```

### 4. 使用

访问 `http://<宿主机IP>:8080`，并按上节「配置 RPC 连接」设置 RPC 地址与密钥。

> 说明：本项目配了 GitHub Actions（`.github/workflows/docker-build.yml`），每次推送到 `main` 分支都会自动构建并通过 CI 推送到 GHCR。因此日常使用不需要本地构建，直接用一章的方式部署即可。

---

## 使用说明

### 下载目录

容器内下载目录为 `/downloads`，默认映射到宿主机 `/Downloads`，内容互通。修改挂载请编辑 compose 文件中的 `volumes`。

### BT 监听端口

`19101`（TCP + UDP）用于 BT/DHT 数据交换，已在端口映射中放开，勿在防火墙中屏蔽。

### 修改 RPC 密钥

密钥通过容器环境变量 `RPC_SECRET` 指定，无需重新构建镜像。

快速部署模式（compose）：

```bash
# 方式一：compose 环境变量
RPC_SECRET=新的密钥 docker compose up -d

# 方式二：直接在 compose 文件的 environment.RPC_SECRET 中修改，然后重启
docker compose up -d
```

本机构建模式：`start.sh` 同样透传 `RPC_SECRET`：

```bash
RPC_SECRET=新的密钥 sudo ./start.sh
```

> 未设置 `RPC_SECRET` 时，默认取 `aria2.conf` 中的 `rpc-secret=MyStrongSecret123`。
> 严格模式：若想废弃配置文件里的默认值，可把 compose 的 `RPC_SECRET` 设为非空即生效。

## 端口说明

| 端口 | 用途 |
| --- | --- |
| `8080`（宿主机）→ `80`（容器） | AriaNg Web 界面（nginx） |
| `6800` | aria2 JSON-RPC |
| `19101` (TCP/UDP) | BT/DHT 下载监听 |

## 常用命令

```bash
# 查看运行状态
docker compose ps

# 查看日志
docker compose logs -f aria2-with-aria2ng

# 重启容器
docker compose restart

# 停止并删除容器
docker compose down

# 更新到最新镜像（快速部署模式）
docker compose pull && docker compose up -d
```

## 常见问题

### 构建失败：`temporary error (try again later)`

多发生在 `apk update && apk add` 步骤，是构建容器访问镜像源网络波动所致。`Dockerfile` 已内置多源（tuna + aliyun）和 5 次重试，重跑一次即可；若持续失败，手动验证源连通性后调整 `Dockerfile` 中的镜像源地址。

### `nginx: [emerg] "daemon" directive is duplicate`

旧版本镜像的 bug，已修复。请重新拉取 `latest`（`docker compose pull`）或重新构建镜像。

### 页面样式/图标显示异常

确认 `Dockerfile` 中保留了 `include /etc/nginx/mime.types;` 一行，缺少它会导致 nginx 按流式返回静态文件。

### 下载文件无法保存

检查宿主机挂载的下载目录是否存在且有写权限，并确认 compose 的 `volumes` 路径正确。

## 技术栈

| 组件 | 说明 |
| --- | --- |
| 基础镜像 | `alpine:3.20` |
| aria2 | 下载引擎，由 supervisord 拉起 |
| nginx | 托管 AriaNg 静态页面 |
| supervisord | 进程管理（aria2c + nginx） |
| 前端 | AriaNg v1.3.14 |
| CI/CD | GitHub Actions → GHCR |

## 配置参考

- `aria2.conf` 主要基于 P3TERX 的 aria2 配置模板修改，BT tracker 与下载参数均已调优
- `supervisord.conf` 将 aria2 与 nginx 日志重定向到 stdout/stderr，方便 `docker compose logs` 查看

## 第三方声明

本项目的 Web 前端 **AriaNg** 来源于 [mayswind/AriaNg](https://github.com/mayswind/AriaNg)，版本 **v1.3.14**，使用 MIT 许可证（见 `aria2ng/LICENSE`）。