# macos-dev-setup

一套面向 Java、Python、前端和 AI 编码工作流的 macOS 开发环境配置仓库。目标是把新 MacBook Pro 从空系统快速恢复成可用、可维护、可审计的开发工作站。

## 特性

- 提供 `make quickstart` / `scripts/quickstart.sh`，面向 30 分钟内进入开发工作的最短路径。
- 使用 `Brewfile` 声明式安装命令行工具、GUI 应用、字体和开发工具。
- 使用 [Brewfile.core](Brewfile.core) 和 [Brewfile](Brewfile) 分离核心安装与完整恢复。
- 提供可直接落地的 `zsh`、Ghostty、tmux 配置。
- 提供可审计、可备份、可 dry-run 的 macOS defaults 系统设置脚本。
- 内置 Java、Python、Node.js、Bun、Rust、Docker/OrbStack 的初始化规范。
- 覆盖 Codex、Claude Code、OpenCode、LM Studio 等 AI 编码工具工作流。
- `bootstrap.sh` 默认备份旧配置，降低误覆盖风险。
- `doctor.sh` 提供基础自检，适合提交前和新机部署后运行。
- 提供 `audit-environment.sh`，只读检查本机环境和仓库声明的差异。
- 提供 `backup-configs.sh`，可按软件选择把本机配置备份回仓库。
- 提供 `sync-back.sh`，把本机配置变更同步回仓库并保留人工 diff 审查。
- 正式执行写入型脚本时归档日志到 `~/.macos-dev-setup-logs/`，便于恢复失败后排障。
- 记录 core、full、work、personal 的环境分层边界，防止工作机器敏感配置污染公开仓库。
- 提供 clean HOME 和幂等恢复演练，降低路径、备份和重复执行问题。
- 内置外部标杆对比和后续改进路线，避免指南停留在个人备份层面。

## 适用人群

- Java / Python / 前端开发者。
- 需要经常重装或迁移 macOS 开发环境的人。
- 想把个人 dotfiles 和软件清单用 Git 管理的人。
- 使用 Codex、Claude Code、OpenCode 等 AI 编码代理的人。

## 快速开始

先安装 Xcode Command Line Tools 和 Homebrew：

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

克隆并执行：

```bash
git clone git@github.com:<your-name>/macos-dev-setup.git
cd macos-dev-setup
make quickstart
```

如果系统没有 `make`，可直接执行：

```bash
./scripts/quickstart.sh
```

这条路径使用 [Brewfile.core](Brewfile.core)，会安装核心软件、写入配置、初始化 Java / Python / Node.js 并运行自检。目标是在 30 分钟内进入开发工作。

完整 GUI 套件可后续执行：

```bash
./scripts/bootstrap.sh --profile full
```

默认安装 Homebrew 清单时不会主动升级已有依赖。需要恢复完整清单可执行：

```bash
make brew-install
```

需要明确升级时：

```bash
./scripts/brew-maintenance.sh --profile full --install --upgrade
```

只查看将执行什么，不写入文件：

```bash
make dry-run
```

只复制配置，不安装 Homebrew 软件：

```bash
./scripts/bootstrap.sh --skip-brew
```

应用 Finder、Dock、键盘、截图等系统默认设置前，建议先预演：

```bash
./scripts/apply-macos-defaults.sh --dry-run
./scripts/apply-macos-defaults.sh --restart-apps
```

运行自检：

```bash
./scripts/doctor.sh
```

检查 Brewfile 中所有依赖是否已安装：

```bash
CHECK_BREW_INSTALLED=1 ./scripts/doctor.sh
```

## 仓库结构

```text
Brewfile / Brewfile.core        Homebrew 完整清单和核心清单
Brewfile.*.example              工作/个人机器差异示例
configs/                        可复制到家目录的公开安全配置
docs/                           新机部署、运行时、终端、AI、应用和参考手册
docs/setup/recovery-drills/     真实或半真实恢复演练报告目录
scripts/                        初始化、审计、维护、自检和恢复演练脚本
scripts/lib/                    脚本共享辅助逻辑
.github/                        CI、Issue 模板和 PR 模板
```

需要完整文件清单时可运行：

```bash
find . -path './.git' -prune -o -print
```

## 文档索引

完整目录见 [docs/README.md](docs/README.md)。

| 文档 | 内容 |
|------|------|
| [docs/start-here.md](docs/start-here.md) | 按目标和时间选择阅读路径 |
| [configs/README.md](configs/README.md) | 配置文件映射和扩展方式 |
| [scripts/README.md](scripts/README.md) | 脚本职责和扩展方式 |
| [docs/setup/quickstart-30min.md](docs/setup/quickstart-30min.md) | 30 分钟快速启动路径 |
| [docs/setup/benchmark.md](docs/setup/benchmark.md) | 外部标杆对比、当前差距和改进路线 |
| [docs/setup/profiles.md](docs/setup/profiles.md) | core、full、work、personal 的环境分层策略 |
| [docs/setup/recovery-drill.md](docs/setup/recovery-drill.md) | 新机恢复演练记录 |
| [docs/setup/gap-closure.md](docs/setup/gap-closure.md) | 外部对比后主要缺口的修复记录 |
| [docs/setup/support-matrix.md](docs/setup/support-matrix.md) | 支持范围、架构和 macOS 版本边界 |
| [docs/reference/cheatsheet.md](docs/reference/cheatsheet.md) | 常用命令与快捷键速查 |
| [docs/reference/troubleshooting.md](docs/reference/troubleshooting.md) | 常见问题排障 |
| [docs/setup/guide.md](docs/setup/guide.md) | 新机初始化主流程 |
| [docs/terminal/shell.md](docs/terminal/shell.md) | zsh、Starship、tmux、fzf、zoxide、Yazi |
| [docs/runtimes/package-managers.md](docs/runtimes/package-managers.md) | Homebrew、SDKMAN、pyenv、uv、fnm、pnpm、bun |
| [docs/runtimes/development-runtimes.md](docs/runtimes/development-runtimes.md) | Java、Python、前端、Rust 运行时 |
| [docs/ai/overview.md](docs/ai/overview.md) | AI 编码工具总览 |
| [docs/ai/codex.md](docs/ai/codex.md) | Codex CLI / App 使用、审查、MCP、排障 |
| [docs/ai/claude-code.md](docs/ai/claude-code.md) | Claude Code 使用、权限、MCP、排障 |
| [docs/runtimes/containers.md](docs/runtimes/containers.md) | OrbStack、Docker Compose、Postgres、Redis |
| [docs/apps/ide.md](docs/apps/ide.md) | JetBrains、VS Code、Cursor、Zed |
| [docs/apps/app-store.md](docs/apps/app-store.md) | App Store 应用与 mas 策略 |
| [docs/terminal/ghostty.md](docs/terminal/ghostty.md) | Ghostty 配置与操作 |
| [docs/setup/maintenance.md](docs/setup/maintenance.md) | 更新、快照、迁移、验收 |
| [docs/apps/gui-apps.md](docs/apps/gui-apps.md) | 普通 GUI 应用用途清单 |
| [docs/setup/repository-design.md](docs/setup/repository-design.md) | 仓库设计原则和扩展方式 |
| [docs/reference/official-links.md](docs/reference/official-links.md) | 官方文档与参考链接总表 |

## 常用命令

最短初始化：

```bash
make quickstart
make dry-run
make defaults
make audit
make backup-configs
make sync-back
make doctor
make drill
make drill-clean
make drill-idempotency
make record-drill
```

安装 Brewfile：

```bash
brew bundle --file Brewfile.core --verbose
brew bundle --file Brewfile --verbose
```

手动复制配置：

```bash
cp configs/zsh/zshrc ~/.zshrc
mkdir -p ~/.config/ghostty
cp configs/ghostty/config ~/.config/ghostty/config
cp configs/starship/starship.toml ~/.config/starship.toml
cp configs/tmux/tmux.conf ~/.tmux.conf
source ~/.zshrc
```

更新仓库快照：

```bash
./scripts/audit-environment.sh --profile core
./scripts/backup-configs.sh --list
./scripts/backup-configs.sh --safe --dry-run
./scripts/backup-configs.sh --items zsh,ghostty,tmux
./scripts/sync-back.sh --dry-run
./scripts/sync-back.sh
./scripts/sync-back.sh --include-brew
./scripts/doctor.sh
```

检查本机环境与仓库声明差异：

```bash
./scripts/audit-environment.sh
./scripts/audit-environment.sh --profile core --no-diff
```

应用系统默认设置：

```bash
./scripts/apply-macos-defaults.sh --dry-run
./scripts/apply-macos-defaults.sh --restart-apps
```

## 安全说明

不要提交以下内容：

- SSH 私钥、GPG 私钥。
- `.env`、`.env.local`。
- npm、Maven、PyPI、OpenAI、Anthropic、云厂商 token。
- 任何包含个人账号、访问密钥、内网地址的配置。

详见 [SECURITY.md](SECURITY.md)。

## 自定义建议

这个仓库可以直接 fork，但建议至少修改：

- `Brewfile`：删除不用的软件，增加自己的必备工具。
- `configs/zsh/zshrc`：调整 `EDITOR`、代理环境变量入口、别名。
- `configs/ghostty/config`：调整字体、主题、窗口大小。
- `configs/starship/starship.toml`：调整提示符模块和显示格式。
- `*.example`：按需复制到私有配置，不要直接写入真实凭证。
- `docs/apps/gui-apps.md`：记录自己的 GUI 应用用途。

## 推送到 GitHub

```bash
git remote add origin git@github.com:<your-name>/macos-dev-setup.git
git push -u origin main
```

## 贡献

欢迎提交 issue 或 PR。请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

本仓库使用 MIT License，见 [LICENSE](LICENSE)。
