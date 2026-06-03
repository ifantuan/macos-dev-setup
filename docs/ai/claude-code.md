# Claude Code 手册

## 定位

Claude Code 是 Anthropic 的终端编码代理，适合交互式开发、代码解释、跨文件修改、审查和自动化命令执行。

## 官方资料

| 内容 | 链接 |
|------|------|
| Claude Code 文档 | <https://docs.anthropic.com/en/docs/claude-code> |
| 交互模式 | <https://docs.anthropic.com/en/docs/claude-code/interactive-mode> |
| Slash commands | <https://code.claude.com/docs/en/commands> |
| 快捷键自定义 | <https://code.claude.com/docs/en/keybindings> |

本手册中的命令以本机 `claude -h` 和 `claude --version` 为准。

本仓库通过 Homebrew 安装：

```ruby
cask "claude-code@latest"
```

验证：

```bash
claude --version
claude -h
```

## 常用入口

| 命令 | 用途 |
|------|------|
| `claude` | 启动交互式会话 |
| `claude "prompt"` | 带初始 prompt 启动 |
| `claude -c` | 继续当前目录最近会话 |
| `claude -p` / `claude --print` | 非交互输出 |
| `claude --model <model>` | 指定模型或模型别名 |
| `claude --add-dir <dir>` | 允许访问额外目录 |
| `claude --debug` | 调试模式 |
| `claude --debug-file <path>` | 写入调试日志 |

## 快捷键与交互习惯

Claude Code 的交互界面会随版本更新。稳定的操作习惯是：

| 操作 | 建议 |
|------|------|
| 多行输入 | 在 Ghostty 中使用 `Shift+Enter` 插入字面换行 |
| 继续会话 | `claude -c` |
| 长任务 | 放进 tmux 会话 |
| 调试问题 | `claude --debug` 或 `--debug-file` |
| 机器可读输出 | `claude --print --output-format json` |

官方交互模式中常用快捷键：

| 操作 | 快捷键 |
|------|--------|
| 发送消息 | `Enter` |
| 插入换行 | `Option+Enter`，或本仓库 Ghostty 配置中的 `Shift+Enter` |
| 快速记忆 | 以 `#` 开头输入 |
| 唤起 slash commands | `/` |
| 退出 | `Ctrl-C` |

常用启动方式：

```bash
claude
claude -c
claude --print "总结当前项目"
```

## 推荐工作流

### 交互式开发

```bash
cd /path/to/project
tmux new -s claude
claude
```

继续最近会话：

```bash
claude -c
```

带任务启动：

```bash
claude "阅读当前项目结构，并总结启动方式"
```

### 非交互输出

```bash
claude --print "总结当前目录的 README"
```

JSON 输出：

```bash
claude --print --output-format json "输出当前项目的技术栈摘要"
```

流式 JSON：

```bash
claude --print --output-format stream-json "运行一次代码审查"
```

## 权限与工具控制

限制允许工具：

```bash
claude --allowedTools "Bash(git *)" "Edit"
```

拒绝工具：

```bash
claude --disallowedTools "Bash(rm *)"
```

指定权限模式：

```bash
claude --permission-mode <mode>
```

危险参数：

```bash
claude --dangerously-skip-permissions
```

建议：

- 真实主机上不要默认跳过权限检查。
- 长任务放 tmux。
- 涉及删除、迁移、批量改文件前先提交或备份。

## 模型与预算

指定模型：

```bash
claude --model sonnet
claude --model opus
```

非交互模式可设置预算：

```bash
claude --print --max-budget-usd 2 "分析当前仓库风险"
```

自动 fallback：

```bash
claude --print --fallback-model sonnet "执行一次代码审查"
```

## MCP 与上下文

加载 MCP 配置：

```bash
claude --mcp-config ./mcp.json
```

添加额外目录：

```bash
claude --add-dir ../shared ../docs
```

建议：

- MCP 配置模板可以提交。
- MCP token 和私密环境变量不要提交。
- 多仓库任务显式使用 `--add-dir`，避免代理误以为不可访问。

## Bare 模式

`--bare` 会跳过 hooks、LSP、插件同步、keychain 读取、自动发现 `CLAUDE.md` 等行为。适合自动化、可复现脚本和隔离环境。

示例：

```bash
ANTHROPIC_API_KEY=... claude --bare --print "总结这个项目"
```

注意：不要把真实 API key 写进仓库或脚本。

## 调试

查看版本：

```bash
claude --version
```

开启调试：

```bash
claude --debug
```

写入日志：

```bash
claude --debug-file /tmp/claude-debug.log
```

常见问题：

| 问题 | 处理 |
|------|------|
| 无法访问文件 | 使用 `--add-dir` 或确认当前目录 |
| 命令被拒绝 | 检查权限模式和 allowed/disallowed tools |
| 输出需要脚本消费 | 使用 `--print --output-format json` |
| 会话上下文混乱 | 新开会话，或使用 `--continue` 明确恢复 |
| 代理网络异常 | 使用 `proxy_status`、`proxy_on` 检查代理 |

## 和 Codex 的分工

| 场景 | 建议 |
|------|------|
| 需要 Codex App 线程管理 | Codex |
| 非交互审查当前改动 | Codex `review` 或 Claude `--print` |
| 长时间交互式修改 | 两者都放 tmux |
| 需要 Claude 模型特定能力 | Claude Code |
| 需要 Codex MCP / plugin 管理 | Codex |
