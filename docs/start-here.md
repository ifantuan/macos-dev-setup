# 从这里开始

本页用于解决“我现在该看哪篇文档”的问题。日常配置、排障和快捷键优先查本仓库，官方资料只作为版本变化或深度参数的补充。

## 按目标查阅

| 目标 | 优先阅读 | 然后阅读 |
|------|----------|----------|
| 新 Mac 半小时进入开发 | [setup/quickstart-30min.md](setup/quickstart-30min.md) | [reference/cheatsheet.md](reference/cheatsheet.md) |
| 完整恢复个人工作站 | [setup/guide.md](setup/guide.md) | [setup/maintenance.md](setup/maintenance.md) |
| 看懂仓库结构 | [setup/repository-design.md](setup/repository-design.md) | [README.md](../README.md) |
| 对比外部优秀指南 | [setup/benchmark.md](setup/benchmark.md) | [setup/repository-design.md](setup/repository-design.md) |
| 区分工作/个人机器 | [setup/profiles.md](setup/profiles.md) | [setup/maintenance.md](setup/maintenance.md) |
| 终端、Shell、tmux | [terminal/shell.md](terminal/shell.md) | [terminal/ghostty.md](terminal/ghostty.md) |
| Java / Python / 前端运行时 | [runtimes/development-runtimes.md](runtimes/development-runtimes.md) | [runtimes/package-managers.md](runtimes/package-managers.md) |
| Docker / 本地数据库 | [runtimes/containers.md](runtimes/containers.md) | [reference/troubleshooting.md](reference/troubleshooting.md) |
| Codex / Claude Code | [ai/overview.md](ai/overview.md) | [ai/codex.md](ai/codex.md)、[ai/claude-code.md](ai/claude-code.md) |
| IDE 与编辑器 | [apps/ide.md](apps/ide.md) | [reference/cheatsheet.md](reference/cheatsheet.md) |
| App Store 应用 | [apps/app-store.md](apps/app-store.md) | [apps/gui-apps.md](apps/gui-apps.md) |
| 命令或快捷键忘了 | [reference/cheatsheet.md](reference/cheatsheet.md) | 对应专题手册 |
| 安装或命令失败 | [reference/troubleshooting.md](reference/troubleshooting.md) | 对应专题手册 |

## 按时间查阅

### 5 分钟

只看三处：

1. [README.md](../README.md)
2. [setup/quickstart-30min.md](setup/quickstart-30min.md)
3. [reference/cheatsheet.md](reference/cheatsheet.md)

### 30 分钟

按顺序执行：

1. 安装 Xcode Command Line Tools。
2. 安装 Homebrew。
3. 克隆仓库。
4. 运行 `make quickstart`。
5. 按 [reference/troubleshooting.md](reference/troubleshooting.md) 处理失败项。

### 1 小时以上

在核心开发环境可用后，再看：

1. [setup/guide.md](setup/guide.md)
2. [apps/ide.md](apps/ide.md)
3. [apps/gui-apps.md](apps/gui-apps.md)
4. [reference/official-links.md](reference/official-links.md)

## 什么情况下才去官方文档

优先不需要。只有以下情况建议去官方文档：

- 本仓库命令和当前安装版本不一致。
- 工具更新后新增或废弃了参数。
- 需要完整配置项参考，例如 Ghostty 所有 keybind、Codex 或 Claude Code 的最新权限模式。
- 遇到本仓库 [reference/troubleshooting.md](reference/troubleshooting.md) 没覆盖的问题。

官方链接集中放在 [reference/official-links.md](reference/official-links.md)，不建议在普通文档中分散搜索。
