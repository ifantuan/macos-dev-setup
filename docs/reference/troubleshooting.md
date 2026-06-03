# 常见问题排障

本页按“先定位、再处理”的顺序整理常见问题。执行破坏性命令前先看输出，不要直接复制删除命令。

## 快速定位

| 症状 | 先检查 | 常见处理 |
|------|--------|----------|
| 新机脚本中断 | `make dry-run`、查看 `~/.macos-dev-setup-logs/` | 重新运行 `make quickstart`，再按日志定位失败命令 |
| `brew: command not found` | `uname -m`、`ls /opt/homebrew /usr/local` | 按 Apple Silicon 或 Intel 路径写入 `~/.zprofile` |
| `brew bundle` 失败 | `brew bundle check --file Brewfile.core --verbose` | 先恢复 core，完整 GUI 清单延后 |
| Shell 启动报错 | `zsh -n ~/.zshrc`、`zsh -n configs/zsh/zshrc` | 检查 `~/.zshrc.local` 是否含私有错误配置 |
| Homebrew API 或下载异常 | `env | rg -i 'proxy|homebrew'` | 临时关闭代理或改用可用镜像后重试 |
| Java 安装失败 | `ls ~/.sdkman`、查看日志 | 重新执行 `./scripts/install-runtimes.sh --no-python --no-node` |
| Node / pnpm 不存在 | `command -v fnm corepack` | 重新打开终端后执行 `fnm use lts-latest` 和 `corepack enable` |
| 配置同步前不确定差异 | `./scripts/audit-environment.sh --profile core --no-diff` | 先 dry-run，再人工审查 `git diff` |

```bash
./scripts/doctor.sh
make dry-run
brew doctor
git status --short
```

如果是新机安装中断，优先重新运行：

```bash
make quickstart
```

脚本会重复执行可幂等步骤，并在覆盖配置前备份。

## macOS defaults

### 系统默认设置脚本执行前想确认影响

先预演：

```bash
./scripts/apply-macos-defaults.sh --dry-run
```

脚本会写入 Finder、Dock、键盘、截图和 `.DS_Store` 相关设置。正式执行前会导出相关 defaults 域到：

```text
~/.macos-dev-setup-backup/<时间戳>/macos-defaults/
```

### Finder 或 Dock 设置没有立即生效

执行时带上：

```bash
./scripts/apply-macos-defaults.sh --restart-apps
```

或重新登录 macOS。部分系统偏好只在相关进程重启后生效。

## Xcode Command Line Tools

### `xcode-select` 不存在或 Git 不可用

```bash
xcode-select --install
xcode-select -p
git --version
```

如果系统提示已安装但命令仍异常：

```bash
sudo xcode-select --reset
```

## Homebrew

### `brew: command not found`

Apple Silicon：

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Intel Mac：

```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

### `brew bundle` 部分软件失败

先看缺失项：

```bash
brew bundle check --file Brewfile.core --verbose
brew bundle check --file Brewfile --verbose
```

只重试核心清单：

```bash
brew bundle --file Brewfile.core --verbose
```

完整 GUI 清单失败时，不要阻塞开发，先完成核心路径：

```bash
make quickstart
```

## 同步回仓库

### 不确定本机配置和仓库差异在哪里

先运行只读审计：

```bash
./scripts/audit-environment.sh --profile core
```

如果配置文件 diff 太长，可只看摘要：

```bash
./scripts/audit-environment.sh --profile core --no-diff
```

确认差异需要写回仓库后，再运行：

```bash
./scripts/sync-back.sh --dry-run
```

### `sync-back.sh` 带入了不想提交的内容

先查看差异：

```bash
git diff
```

如果只是家目录配置里的临时改动，不要提交。重新编辑对应 `configs/` 文件，或从 Git 中恢复该文件。

如果是 `Brewfile` 中出现不想保留的软件，手动删除对应条目后运行：

```bash
./scripts/doctor.sh
```

## Shell 配置

### 新终端没有加载 Homebrew

检查 `~/.zprofile`：

```bash
sed -n '1,80p' ~/.zprofile
```

应包含：

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### `.zshrc` 报错

先检查语法：

```bash
zsh -n ~/.zshrc
zsh -n configs/zsh/zshrc
```

再确认工具是否存在：

```bash
command -v starship fnm pyenv zoxide
```

本仓库的 `configs/zsh/zshrc` 使用条件加载，正常情况下缺少工具不会导致 Shell 启动失败。

## GitHub 与 SSH

### `git clone git@github.com` 失败

先用 HTTPS 克隆：

```bash
git clone https://github.com/<your-name>/macos-dev-setup.git
```

进入开发后再配置 SSH：

```bash
ssh -T git@github.com
gh auth login
gh auth status
```

### Git 提交身份未配置

```bash
git config --global user.name "你的名字"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

## Ghostty

### `doctor.sh` 跳过 Ghostty 配置校验

如果输出：

```text
skipped: 未安装 font-maple-mono-nf-cn
```

说明当前机器还没完整安装核心清单。先安装核心依赖：

```bash
brew bundle --file Brewfile.core --verbose
```

如果要把缺失字体视为失败，运行：

```bash
CHECK_BREW_INSTALLED=1 ./scripts/doctor.sh
```

如果要在 CI 或提交前强制执行 Ghostty 配置校验，运行：

```bash
REQUIRE_GHOSTTY_VALIDATE=1 ./scripts/doctor.sh
```

手动校验仓库配置时使用等号形式传参：

```bash
ghostty +validate-config --config-file=configs/ghostty/config
```

### 配置不生效

```bash
ghostty +validate-config --config-file=~/.config/ghostty/config
```

确认配置已复制：

```bash
ls -l ~/.config/ghostty/config
```

### 图标或中文显示异常

确认字体已安装：

```bash
brew list --cask font-maple-mono-nf-cn
```

重新打开 Ghostty。若仍异常，到 macOS 字体册中确认字体可见。

## Node.js / pnpm

### `node` 不存在

```bash
fnm install --lts
fnm default lts-latest
fnm use lts-latest
node -v
```

重新打开终端后再试。

### `pnpm` 不存在

```bash
corepack enable
corepack prepare pnpm@latest --activate
pnpm -v
```

如果项目固定 pnpm 版本，以项目 `packageManager` 字段为准。

## Python

### 快速启动后 `python` 版本不符合预期

先查看 uv 安装版本：

```bash
uv python list --only-installed
```

项目内使用：

```bash
uv venv
source .venv/bin/activate
python --version
```

### 项目要求 `.python-version`

```bash
./scripts/install-runtimes.sh --no-java --no-node
pyenv local 3.12.2
python --version
```

### `pyenv install` 编译失败

安装编译依赖：

```bash
brew install openssl@3 readline sqlite3 xz zlib tcl-tk
```

再重试：

```bash
pyenv install 3.12.2
```

## Java / Maven

### `sdk` 不存在

重新运行运行时初始化：

```bash
./scripts/install-runtimes.sh --no-python --no-node
```

或手动加载：

```bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk current
```

### 指定 JDK 版本不存在

先查可用版本：

```bash
sdk list java
```

然后覆盖环境变量安装：

```bash
JAVA_VERSION=<可用版本> ./scripts/install-runtimes.sh --no-python --no-node
```

### Maven 私服无法访问

检查本机私有配置，不要提交到仓库：

```bash
ls -l ~/.m2/settings.xml
mvn -v
```

## Docker / OrbStack

### `docker` 无法连接

先打开 OrbStack：

```bash
open -a OrbStack
docker version
```

如果仍失败，重启 OrbStack 后再试。

### 端口占用

```bash
lsof -nP -iTCP:<端口> -sTCP:LISTEN
```

停止对应服务，或修改 `compose.yml` 端口映射。

### 容器数据需要重建

```bash
docker compose down
docker compose down -v
docker compose up -d
```

`down -v` 会删除数据卷，只在确认数据可丢弃时使用。

## Codex / Claude Code

### 命令不存在

```bash
brew bundle --file Brewfile.core --verbose
command -v codex claude
```

### 登录或网络异常

```bash
proxy_status
proxy_on
codex doctor
claude --version
```

### 长任务中断

以后长任务放进 tmux：

```bash
tmux new -s ai
codex
# 或
claude
```

## 仍未解决

先收集这些信息，再查专题手册或官方资料：

```bash
sw_vers
uname -m
brew doctor
./scripts/doctor.sh
git status --short
```

官方资料统一见 [official-links.md](official-links.md)。
