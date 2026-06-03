# 容器与本地服务手册

## 默认选择

本仓库默认使用 OrbStack 提供 Docker 运行时。

验证：

```bash
orb --version
docker version
docker compose version
docker run --rm hello-world
```

## 服务管理原则

优先级：

1. 项目内 `compose.yml`
2. 临时 `docker run`
3. Homebrew services

只有长期常驻、跨项目共享的服务才建议用 `brew services`。

## PostgreSQL + Redis 示例

```yaml
services:
  postgres:
    image: postgres:16
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: dev
      POSTGRES_PASSWORD: dev
      POSTGRES_DB: app
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "6379:6379"

volumes:
  postgres-data:
```

启动：

```bash
docker compose up -d
docker compose ps
```

停止：

```bash
docker compose down
```

删除数据卷：

```bash
docker compose down -v
```

## 常用排障

端口占用：

```bash
lsof -nP -iTCP:5432 -sTCP:LISTEN
```

查看日志：

```bash
docker compose logs -f
```

进入容器：

```bash
docker compose exec postgres bash
```

清理无用资源：

```bash
docker system prune
```

