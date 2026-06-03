# AI 工具手册

## 工具分工

| 工具 | 用途 |
|------|------|
| Codex CLI | 终端内编码代理 |
| Codex App | 桌面端线程与任务管理 |
| Claude Code | 终端内编码代理 |
| OpenCode | 终端和桌面 AI 编码工具 |
| LM Studio | 本地模型下载、运行和 OpenAI 兼容服务 |
| Cherry Studio | 多模型客户端 |
| cc-switch | AI 编码工具配置切换 |

## 深度手册

| 文档 | 内容 |
|------|------|
| [codex.md](codex.md) | Codex CLI / App、`exec`、`review`、MCP、插件、排障 |
| [claude-code.md](claude-code.md) | Claude Code 交互、`--print`、权限、MCP、调试 |

## 基本原则

- 长任务放进 tmux。
- 凭证放 1Password、系统钥匙串或工具自身登录态。
- 不把 API key 写进仓库。
- 项目内只提交 `.env.example`。

## tmux 工作流

```bash
tmux new -s ai
codex
```

断开：

```bash
tmux detach
```

恢复：

```bash
tmux attach -t ai
```

## LM Studio

LM Studio 适合：

- 本地模型测试。
- OpenAI 兼容接口调试。
- 离线或低敏感任务。

常见路径：

```text
~/.lmstudio/bin
```

当前 `configs/zsh/zshrc` 会条件加入此路径。

## 凭证管理

建议存放：

```text
1Password
macOS 钥匙串
工具自身登录态
```

不建议：

```text
README.md
.zshrc
Brewfile
Git 仓库中的 .env
```

## 排障

检查代理：

```bash
proxy_status
proxy_on
proxy_off
```

检查终端是否在 tmux：

```bash
echo $TMUX
```

检查工具位置：

```bash
command -v codex
command -v claude
command -v opencode
```
