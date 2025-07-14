# 第一阶段：构建阶段
FROM golang:1.21-alpine AS builder

# 安装必要的构建工具
RUN apk add --no-cache git ca-certificates tzdata

# 设置工作目录
WORKDIR /build

# 复制 go mod 文件并下载依赖（利用 Docker 缓存层）
COPY go.mod go.sum ./
RUN go mod download

# 复制源代码
COPY . .

# 构建应用程序
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o homelab-butler .

# 第二阶段：运行阶段
FROM alpine:latest

# 安装ca-certificates和时区数据
RUN apk --no-cache add ca-certificates tzdata && \
    addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# 设置时区
ENV TZ=Asia/Shanghai

# 创建应用目录
WORKDIR /app

# 从构建阶段复制二进制文件
COPY --from=builder /build/homelab-butler .

# 创建配置文件目录（用于外部挂载）
RUN mkdir -p /app/config

# 创建一个示例配置文件（可选，作为模板）
COPY --from=builder /build/config.yml /app/config/config.yml.example

# 修改文件权限
RUN chown -R appuser:appgroup /app

# 切换到非特权用户
USER appuser

# 暴露端口（默认 8080，可以通过配置文件调整）
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# 启动命令
CMD ["./homelab-butler"]
