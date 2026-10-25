# --- 第一阶段：编译二进制文件 ---
FROM golang:1.23-alpine AS builder
WORKDIR /app

# 适配本地缓存与依赖
COPY go.mod go.sum ./
RUN go mod download

# 复制项目内所有源码
COPY . .

# 编译 anytls-go 官方提供的 cmd 目录下的可执行文件
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o anytls-server ./cmd/server

# --- 第二阶段：常驻运行环境 ---
FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/
COPY --from=builder /app/anytls-server .

# 关键：通过 ENV 将 Koyeb 注入的 PORT 转化为 anytls 启动时能识别的参数
# anytls 官方服务默认支持通过端口等配置或变量启动
CMD ["sh", "-c", "./anytls-server -addr :$PORT"]
