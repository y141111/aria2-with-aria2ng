FROM alpine:3.20

# 国内镜像源：tuna 优先，aliyun 备用，单个源不可用时兜底
RUN printf '%s\n' \
    'https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main' \
    'https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community' \
    'https://mirrors.aliyun.com/alpine/v3.20/main' \
    'https://mirrors.aliyun.com/alpine/v3.20/community' \
    > /etc/apk/repositories

# 网络抖动时自动重试
RUN for i in $(seq 1 5); do \
        apk update && break; \
        echo "== apk update 失败(第 $i 次)，3 秒后重试 =="; \
        sleep 3; \
    done && apk add --no-cache aria2 nginx supervisor

RUN mkdir -p /etc/aria2
COPY aria2.conf /etc/aria2/aria2.conf
RUN touch /etc/aria2/aria2.session

COPY ./aria2ng /usr/share/nginx/html

RUN echo 'events { worker_connections 1024; }' > /etc/nginx/nginx.conf && \
    echo 'http {' >> /etc/nginx/nginx.conf && \
    echo '  include /etc/nginx/mime.types;' >> /etc/nginx/nginx.conf && \
    echo '  server {' >> /etc/nginx/nginx.conf && \
    echo '    listen 80;' >> /etc/nginx/nginx.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf && \
    echo '    index index.html;' >> /etc/nginx/nginx.conf && \
    echo '  }' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf

COPY supervisord.conf /etc/supervisord.conf

EXPOSE 80/tcp 6800/tcp 19101/tcp 19101/udp

WORKDIR /

CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]
