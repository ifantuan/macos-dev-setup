# 运行时文档目录说明

本目录记录 Java、Python、前端、Rust、容器和包管理器。

| 文件 | 用途 |
|------|------|
| `development-runtimes.md` | 各语言运行时策略和验证方式 |
| `package-managers.md` | Homebrew、SDKMAN、pyenv、uv、fnm、pnpm、bun |
| `containers.md` | OrbStack、Docker Compose、本地数据库 |

## 编写原则

- 默认版本必须和 `scripts/install-runtimes.sh` 保持一致。
- 新增命令后，同步更新 [../reference/cheatsheet.md](../reference/cheatsheet.md)。
- 排障内容优先集中到 [../reference/troubleshooting.md](../reference/troubleshooting.md)。
