# Homelab Butler

一个基于 Gin 框架的主机管理 API 服务，用于管理家庭实验室中的主机信息。

## 功能特性

- 🚀 基于 Gin 高性能 Web 框架
- 🗄️ 使用 GORM 进行 MySQL 数据库操作
- 📋 提供完整的主机信息 CRUD 操作
- 🔧 支持配置文件管理
- 🌐 内置 CORS 支持
- 📊 健康检查接口

## 项目结构

```
homelab-butler/
├── main.go              # 主程序入口
├── config.yml           # 配置文件
├── go.mod              # Go 模块定义
├── models/             # 数据模型
│   └── host.go         # 主机信息模型
├── database/           # 数据库相关
│   └── db.go          # 数据库连接和配置
└── handlers/          # HTTP 处理函数
    └── host.go        # 主机相关接口
```

## 快速开始

### 1. 环境要求

- Go 1.21+
- MySQL 5.7+ 或 8.0+

### 2. 安装依赖

```bash
go mod tidy
```

### 3. 配置数据库

编辑 `config.yml` 文件，配置您的数据库连接信息：

```yaml
database:
  host: localhost
  port: 3306
  username: your_username
  password: your_password
  database: homelab
  charset: utf8mb4

server:
  port: 8080
```

### 4. 创建数据库

在 MySQL 中创建数据库：

```sql
CREATE DATABASE homelab CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 5. 运行项目

```bash
go run main.go
```

程序会自动创建数据表并启动在配置的端口上（默认 8080）。

## API 接口

### 基础路径

- 基础 API: `http://localhost:8080/api/v1`
- 兼容路径: `http://localhost:8080/hosts`

### 主机管理接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/hosts` | 获取所有主机列表 |
| GET | `/api/v1/hosts` | 获取所有主机列表 |
| GET | `/api/v1/hosts/{id}` | 根据ID获取主机信息 |
| POST | `/api/v1/hosts` | 创建新主机记录 |
| PUT | `/api/v1/hosts/{id}` | 更新主机信息 |
| DELETE | `/api/v1/hosts/{id}` | 删除主机记录 |

### 系统接口

| 方法 | 路径 | 描述 |
|------|------|------|
| GET | `/health` | 健康检查 |

## 数据模型

### Host 主机信息

```json
{
  "id": 1,
  "name": "web-server-01",
  "ip_address": "192.168.1.100",
  "mac_address": "00:11:22:33:44:55",
  "os_type": "Ubuntu",
  "os_version": "22.04 LTS",
  "status": "online",
  "description": "Web服务器",
  "created_at": "2024-01-01T12:00:00Z",
  "updated_at": "2024-01-01T12:00:00Z"
}
```

### 字段说明

- `id`: 主机唯一标识符
- `name`: 主机名称
- `ip_address`: IP地址（必填，唯一）
- `mac_address`: MAC地址
- `os_type`: 操作系统类型
- `os_version`: 操作系统版本
- `status`: 主机状态（online/offline/unknown）
- `description`: 主机描述
- `created_at`: 创建时间
- `updated_at`: 更新时间

## 使用示例

### 获取所有主机

```bash
curl http://localhost:8080/hosts
```

### 创建新主机

```bash
curl -X POST http://localhost:8080/api/v1/hosts \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-server-01",
    "ip_address": "192.168.1.100",
    "mac_address": "00:11:22:33:44:55",
    "os_type": "Ubuntu",
    "os_version": "22.04 LTS",
    "status": "online",
    "description": "Web服务器"
  }'
```

### 获取指定主机

```bash
curl http://localhost:8080/api/v1/hosts/1
```

### 更新主机信息

```bash
curl -X PUT http://localhost:8080/api/v1/hosts/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "web-server-01-updated",
    "status": "offline"
  }'
```

### 删除主机

```bash
curl -X DELETE http://localhost:8080/api/v1/hosts/1
```

## 开发说明

### 添加新功能

1. 在 `models/` 目录下定义数据模型
2. 在 `handlers/` 目录下实现业务逻辑
3. 在 `main.go` 中注册路由

### 数据库迁移

项目使用 GORM 的自动迁移功能，在启动时会自动创建和更新数据表结构。

## 许可证

MIT License 