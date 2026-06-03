# Codex 手册

## 定位

Codex 是终端与桌面端结合的编码代理，适合代码修改、代码审查、自动化排障、跨文件重构和长期任务管理。

## 官方资料

| 内容 | 链接 |
|------|------|
| Codex CLI 仓库 | <https://github.com/openai/codex> |
| Codex CLI Getting Started | <https://help.openai.com/en/articles/11096431> |
| Codex 产品页 | <https://openai.com/codex> |

本手册中的命令以本机 `codex --help`、`codex exec --help`、`codex review --help` 为准。

本仓库通过 Homebrew 安装：

```ruby
cask "codex"
cask "codex-app"
```

验证：

```bash
codex --version
codex doctor
```

## 常用入口

| 命令 | 用途 |
|------|------|
| `codex` | 启动交互式 TUI |
| `codex exec` | 非交互执行任务 |
| `codex review` | 非交互代码审查 |
| `codex login` | 登录管理 |
| `codex logout` | 移除认证 |
| `codex doctor` | 诊断安装、配置、认证、运行环境 |
| `codex app` | 启动 Codex 桌面 App |
| `codex resume` | 恢复历史会话 |
| `codex apply` | 应用最近一次代理生成的 diff |
| `codex mcp` | 管理 MCP 服务器 |
| `codex plugin` | 管理 Codex 插件 |

## 快捷键与交互习惯

Codex 的交互界面会随版本更新。稳定的操作习惯是：

| 操作 | 建议 |
|------|------|
| 多行输入 | 在 Ghostty 中使用 `Shift+Enter` 插入字面换行 |
| 长任务 | 放进 tmux 会话 |
| 保留滚动历史 | 启动时使用 `--no-alt-screen` |
| 恢复任务 | 使用 `codex resume` |
| 应用补丁 | 使用 `codex apply` 前先看 `git diff` |

常用启动方式：

```bash
codex --no-alt-screen
codex resume
codex app
```

查看当前版本支持的命令：

```bash
codex --help
codex exec --help
codex review --help
```

## 推荐工作流

### 交互式开发

```bash
cd /path/to/project
tmux new -s codex
codex
```

长任务建议始终放在 tmux 中，避免终端关闭导致上下文丢失。

### 非交互任务

```bash
codex exec "检查当前仓库的测试失败原因，并给出修复建议"
```

指定工作目录：

```bash
codex exec -C /path/to/project "运行测试并修复失败"
```

从标准输入传入任务：

```bash
cat prompt.md | codex exec -
```

### 代码审查

审查未提交改动：

```bash
codex review --uncommitted
```

审查相对分支：

```bash
codex review --base main
```

审查指定提交：

```bash
codex review --commit <sha>
```

## 沙箱与审批

常用参数：

```bash
codex -s workspace-write
codex -s read-only
codex -a on-request
codex -a never
```

建议：

- 日常交互使用 `workspace-write`。
- 审查和理解代码使用 `read-only`。
- 不要在真实主机上随意使用 `--dangerously-bypass-approvals-and-sandbox`。
- 只有外部已有强隔离环境时，才考虑跳过审批和沙箱。

## 配置与状态

常见位置：

```text
~/.codex/config.toml
~/.codex/auth.json
~/.codex/log/
```

临时覆盖配置：

```bash
codex -c model='"gpt-5.5"'
codex -c shell_environment_policy.inherit=all
```

严格检查配置：

```bash
codex --strict-config
```

## MCP 与插件

查看 MCP：

```bash
codex mcp --help
```

查看插件：

```bash
codex plugin --help
```

建议：

- MCP 环境变量不要写入仓库。
- MCP 服务器配置可以记录模板，真实 token 放 1Password 或本机环境。
- 插件变更后运行 `codex doctor`。

## 本地模型

Codex 支持本地 provider 参数。使用 LM Studio 时：

```bash
codex --oss --local-provider lmstudio
```

前提：

- LM Studio 已启动本地服务。
- 模型已下载并加载。
- 任务不涉及必须联网检索的内容。

## 排障

基础诊断：

```bash
codex doctor
```

常见问题：

| 问题 | 处理 |
|------|------|
| `TERM=dumb` | 在真实终端中运行，或设置 `TERM=xterm-256color` |
| MCP 服务器不可用 | 检查命令是否在 `PATH`，检查缺失环境变量 |
| 网络超时 | 使用 `proxy_status`、`proxy_on` 检查代理 |
| Git 仓库检测失败 | 确认在仓库根目录，或使用 `-C` 指定路径 |
| 输出需要保留 | 使用 `--no-alt-screen` 保留终端滚动历史 |

更新：

```bash
codex update
```

如果是 Homebrew 安装，也可以：

```bash
brew upgrade --cask codex codex-app
```
