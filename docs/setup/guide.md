# macOS 生产力环境初始化与自动化部署规范指南

> 适用设备：新购 MacBook Pro，Apple Silicon 优先，Intel Mac 兼容  
> 主要场景：Java、Python、前端开发、AI 编码代理、本地大模型、移动端与小程序开发  
> 核心目标：可复现、可迁移、少污染、易验证

## 目录

1. [初始化原则](#1-初始化原则)
2. [新机首轮系统设置](#2-新机首轮系统设置)
3. [基础工具链安装](#3-基础工具链安装)
4. [Homebrew 声明式部署](#4-homebrew-声明式部署)
5. [终端与 Shell 配置](#5-终端与-shell-配置)
6. [开发者配置迁移](#6-开发者配置迁移)
7. [Java 开发环境](#7-java-开发环境)
8. [Python 开发环境](#8-python-开发环境)
9. [前端开发环境](#9-前端开发环境)
10. [Rust 与容器补充运行时](#10-rust-与容器补充运行时)
11. [环境验收清单](#11-环境验收清单)
12. [维护规范](#12-维护规范)
13. [一键执行顺序摘要](#13-一键执行顺序摘要)
14. [可选扩展清单](#14-可选扩展清单)

## 文档索引

如果目标是半小时内先进入开发工作，优先执行 [30 分钟快速启动路径](quickstart-30min.md)。本文用于完整恢复和长期维护，不要求一次做完。

| 文档 | 内容 |
|------|------|
| [setup/quickstart-30min.md](quickstart-30min.md) | 30 分钟快速启动路径 |
| [terminal/shell.md](../terminal/shell.md) | Shell、Starship、tmux、fzf、zoxide、Yazi |
| [runtimes/package-managers.md](../runtimes/package-managers.md) | Homebrew、SDKMAN、pyenv、uv、fnm、pnpm、bun |
| [runtimes/development-runtimes.md](../runtimes/development-runtimes.md) | Java、Python、前端、Rust |
| [ai/overview.md](../ai/overview.md) | AI 编码工具和本地模型 |
| [ai/codex.md](../ai/codex.md) | Codex CLI / App 使用、审查、MCP、排障 |
| [ai/claude-code.md](../ai/claude-code.md) | Claude Code 使用、权限、MCP、排障 |
| [runtimes/containers.md](../runtimes/containers.md) | OrbStack、Docker Compose、本地数据库 |
| [apps/ide.md](../apps/ide.md) | IDE 与编辑器 |
| [terminal/ghostty.md](../terminal/ghostty.md) | Ghostty 配置与操作 |
| [setup/maintenance.md](maintenance.md) | 维护、迁移、验收 |
| [apps/gui-apps.md](../apps/gui-apps.md) | GUI 应用用途清单 |

## 1. 初始化原则

新机初始化不要依赖「凭记忆逐个安装」。推荐把环境分为四层：

| 层级 | 内容 | 推荐方式 |
|------|------|----------|
| 系统层 | macOS 设置、权限、触控板、显示器、电池 | 少量手动设置 + `defaults` 命令 |
| 软件层 | Homebrew Formulae、Casks、字体、浏览器、IDE | `Brewfile` 声明式安装 |
| 运行时层 | JDK、Python、Node.js、Bun、pnpm | `sdkman`、`pyenv`、`fnm` 隔离管理 |
| 配置层 | Zsh、Ghostty、Starship、Git、SSH、Maven、pip | dotfiles 文件化迁移 |

建议优先使用以下版本管理器：

- Java：`sdkman`
- Python：`pyenv`
- Node.js：`fnm`
- 包管理：`pnpm`、`bun`
- 终端：`Ghostty`
- Shell：`zsh` + `starship` + `zinit`

## 2. 新机首轮系统设置

### 2.1 必做的手动设置

开机完成 iCloud、Apple ID、指纹和 FileVault 后，先完成这些系统设置：

| 设置项 | 建议值 |
|--------|--------|
| 系统设置 -> 键盘 -> 按键重复速度 | 最快 |
| 系统设置 -> 键盘 -> 重复前延迟 | 最短 |
| 系统设置 -> 触控板 | 开启「轻点来点按」 |
| 系统设置 -> 辅助功能 -> 指针控制 -> 触控板选项 | 开启「三指拖移」 |
| 系统设置 -> 显示器 | 选择「更多空间」 |
| 系统设置 -> 桌面与程序坞 | 按个人习惯关闭多余动画 |
| 系统设置 -> 隐私与安全性 -> 辅助功能 | 后续给 Ghostty、Karabiner、Manico 等工具授权 |

如果长期插电使用 MacBook Pro，安装 `AlDente` 后建议把充电上限设置为 80%。

### 2.2 系统默认行为调整

推荐使用仓库脚本集中写入，执行前可预演：

```bash
./scripts/apply-macos-defaults.sh --dry-run
./scripts/apply-macos-defaults.sh --restart-apps
```

脚本会在写入前导出相关 defaults 域到 `~/.macos-dev-setup-backup/<时间戳>/macos-defaults/`。当前覆盖范围包括 Finder、Dock、键盘重复速度、自动替换、截图格式和网络盘 `.DS_Store` 行为。

如果只想手动应用最小集合，可在系统自带 Terminal 执行：

```bash
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
killall Finder
```

### 2.3 安全与备份基线

新机完成系统初始化后，先确认这些安全项，再安装大量开发工具：

| 项目 | 建议 |
|------|------|
| FileVault | 开启，恢复密钥保存到 1Password 或安全位置 |
| 防火墙 | 开启，按需允许本地开发服务 |
| 系统更新 | 保持自动检查，关键安全更新自动安装 |
| 1Password | 先登录，再恢复 SSH、GitHub、npm、Maven 私服等凭证 |
| Time Machine | 至少配置一个外置盘或 NAS 备份目标 |
| 查找我的 Mac | 开启，方便丢失后定位和远程锁定 |

建议不要把 token、私钥、私服密码写入本文或 dotfiles 仓库。本文只记录路径、命令和流程，凭证统一交给 1Password、系统钥匙串或对应工具自己的安全存储。

## 3. 基础工具链安装

### 3.1 安装 Xcode Command Line Tools

```bash
xcode-select --install
```

如果系统提示已经安装，可继续下一步。验证方式：

```bash
xcode-select -p
git --version
clang --version
```

### 3.2 安装 Homebrew

官方安装：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Apple Silicon 写入环境：

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Intel Mac 使用：

```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

### 3.3 配置 Homebrew 镜像

国内网络环境可启用中科大镜像：

```bash
cat >> ~/.zprofile <<'EOF'

# Homebrew 镜像
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
EOF

source ~/.zprofile
```

验证：

```bash
brew update
brew doctor
```

## 4. Homebrew 声明式部署

### 4.0 第三方 Tap 说明

默认 core/full 清单只使用官方 `homebrew/core` 和 `homebrew/cask`。Bundle 已内置，不再声明 `homebrew/bundle`；`bun` 和 `opencode` 直接使用官方 formula。

ZedG 与 Rebased 已移到 `Brewfile.personal.example` 的注释示例。其上游安装定义含移除 macOS 隔离属性的步骤，默认路径不安装、不授权。确需使用时先审查源码，再在私有清单中用完整包名按包声明信任，避免信任整个 tap。具体出处见示例中的链接。

### 4.1 使用仓库清单

当前仓库直接维护两个 Homebrew 清单：

| 文件 | 用途 |
|------|------|
| `Brewfile.core` | 半小时快速启动所需的核心工具、字体和少量 GUI |
| `Brewfile` | 完整个人工作站恢复清单 |

先检查清单是否可读：

```bash
brew bundle list --file Brewfile.core --all
brew bundle list --file Brewfile --all
```

### 4.2 执行安装

核心安装使用：

```bash
./scripts/bootstrap.sh --profile core
```

完整安装使用：

```bash
./scripts/bootstrap.sh --profile full
```

如果只想安装 Homebrew 清单，不复制配置：

```bash
./scripts/brew-maintenance.sh --profile core --install
./scripts/brew-maintenance.sh --profile full --install
```

默认安装会带 `--no-upgrade`，避免恢复清单时顺手升级已有依赖。需要明确升级时再执行：

```bash
./scripts/brew-maintenance.sh --profile full --install --upgrade
```

### 4.3 导出当前机器清单

需要把本机 Homebrew 快照同步回仓库时，先预演并审查差异：

```bash
./scripts/sync-back.sh --dry-run --include-brew
./scripts/sync-back.sh --include-brew
git diff Brewfile
```

不要直接提交未经审查的完整快照。公司内部工具、一次性工具、个人偏好和可能暴露账号或地区信息的应用应先移除，或放到私有清单中。

## 5. 终端与 Shell 配置

### 5.1 文件落位规范

本仓库已经把配置文件拆分到 `configs/` 目录。新机上通过 `scripts/bootstrap.sh` 自动安装，也可以手动复制。

手动复制配置：

```bash
cp configs/zsh/zshrc ~/.zshrc
mkdir -p ~/.config/ghostty
cp configs/ghostty/config ~/.config/ghostty/config
cp configs/starship/starship.toml ~/.config/starship.toml
cp configs/tmux/tmux.conf ~/.tmux.conf
```

### 5.2 Zsh 插件与补全

当前 `configs/zsh/zshrc` 配置已包含：

- Oh My Zsh
- 可选 Homebrew bottle 镜像入口
- 可选代理函数
- SDKMAN
- fnm
- pyenv
- bun
- rustup
- opencode
- Antigravity
- Starship
- Zinit

这份配置采用“稳妥优化版”：

- 保留 Oh My Zsh，但关闭 Oh My Zsh 主题，避免和 Starship 提示符冲突。
- 不在文件开头手动执行 `compinit`，避免和 Oh My Zsh 内部补全初始化重复。
- `fnm`、`pyenv`、`rustup`、`starship`、`zinit` 等全部条件加载，新机未安装时不会报错。
- 代理和 Homebrew 镜像默认不写死，按需在 `~/.zshrc.local` 中设置 `MACOS_DEV_SETUP_HTTP_PROXY`、`MACOS_DEV_SETUP_ALL_PROXY` 或 `MACOS_DEV_SETUP_HOMEBREW_BOTTLE_DOMAIN`。
- 本地工具路径使用 `$HOME`，减少用户名变化导致的迁移问题。

首次使用前，确保 Oh My Zsh 已安装：

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

然后重载：

```bash
source ~/.zshrc
```

### 5.3 Ghostty 校验

安装后执行：

```bash
ghostty +validate-config
ghostty +show-config
```

如果全局下拉终端快捷键无法生效，到：

```text
系统设置 -> 隐私与安全性 -> 辅助功能
```

给 Ghostty 授权。

### 5.4 tmux 基础建议

`tmux` 用于承载长时间运行的 AI 代理、后端服务和构建任务。建议至少准备：

```bash
cat > ~/.tmux.conf <<'EOF'
set -g mouse on
set -g history-limit 50000
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:RGB"
setw -g mode-keys vi
EOF
```

常用命令：

```bash
tmux new -s dev
tmux attach -t dev
tmux ls
```

## 6. 开发者配置迁移

旧机器迁移时，优先备份这些目录和文件：

| 类型 | 旧机器路径 | 新机器路径 | 注意事项 |
|------|------------|------------|----------|
| SSH 密钥 | `~/.ssh/` | `~/.ssh/` | 权限必须正确 |
| Git 配置 | `~/.gitconfig` | `configs/git/gitconfig.example` 可作模板 | 真实用户名、邮箱、别名、签名需自行审查 |
| GPG 配置 | `~/.gnupg/` | `~/.gnupg/` | 提交签名需要 |
| Maven 配置 | `~/.m2/settings.xml` | `configs/maven/settings.xml.example` 可作模板 | 私服凭证不要提交到仓库 |
| Gradle 配置 | `~/.gradle/gradle.properties` | `~/.gradle/gradle.properties` | 代理和 JVM 参数 |
| pip 配置 | `~/.pip/pip.conf` | `configs/pip/pip.conf.example` 可作模板 | PyPI 镜像 |
| npm 配置 | `~/.npmrc` | `configs/npm/npmrc.example` 可作模板 | 私有源 token 注意保护 |
| pnpm 配置 | `~/Library/pnpm/` | `~/Library/pnpm/` | 全局包可重装，不强制迁移 |
| Cargo 配置 | `~/.cargo/config.toml` | `~/.cargo/config.toml` | Rust 镜像源 |
| JetBrains 配置 | `~/Library/Application Support/JetBrains/` | 同路径 | 可优先用 JetBrains 账号同步 |
| VS Code 配置 | `~/Library/Application Support/Code/User/` | `configs/vscode/settings.json.example` 可作模板 | 可优先用 Settings Sync |

SSH 权限修复：

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub
```

Git 基础配置示例：

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
git config --global init.defaultBranch main
git config --global pull.rebase false
```

### 6.1 SSH 与 GitHub 登录

如果从旧机器迁移 SSH 密钥，先修复权限，再测试：

```bash
ssh -T git@github.com
```

如果新机重新生成密钥：

```bash
ssh-keygen -t ed25519 -C "你的邮箱"
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
pbcopy < ~/.ssh/id_ed25519.pub
```

然后把公钥添加到 GitHub：

```text
GitHub -> Settings -> SSH and GPG keys -> New SSH key
```

GitHub CLI 登录：

```bash
gh auth login
gh auth status
```

### 6.2 开发凭证与敏感配置

建议明确区分“可提交配置”和“不可提交凭证”：

| 类型 | 处理方式 |
|------|----------|
| Git 用户名、默认分支、别名 | 可写入 dotfiles |
| SSH 私钥、GPG 私钥 | 只放本机和密码管理器备份 |
| npm token、Maven 私服密码、PyPI token | 放工具配置或环境变量，不提交 |
| OpenAI、Anthropic、数据库密码 | 放 1Password、系统钥匙串或项目 `.env.local` |
| 项目 `.env` | 只提交 `.env.example` |

推荐每个项目提供：

```text
.env.example
README.md
```

并在 `.gitignore` 中忽略：

```text
.env
.env.local
.venv/
node_modules/
```
## 7. Java 开发环境

### 7.1 安装 SDKMAN

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

### 7.2 安装 JDK 与构建工具

默认安装 Zulu JDK 8，17 / 21 按项目需要再补充：

```bash
sdk install java 8.0.492-zulu
sdk default java 8.0.492-zulu

sdk install maven
sdk install gradle
```

如果版本不存在，先查看可用版本：

```bash
sdk list java
```

### 7.3 Maven 配置迁移

需要从旧机器迁移：

```text
~/.m2/settings.xml
~/.m2/toolchains.xml
```

常见内容包括：

- 私服认证
- 镜像仓库
- GPG 签名配置
- 多 JDK toolchain

验证：

```bash
java -version
mvn -v
gradle -v
```

## 8. Python 开发环境

### 8.1 安装构建依赖

```bash
brew install openssl@3 readline sqlite3 xz zlib tcl-tk
```

### 8.2 配置 pyenv 编译参数

Apple Silicon 上通过 `pyenv` 编译 Python 时，建议显式带上 Homebrew 依赖路径，避免 `ssl`、`readline`、`sqlite3`、`tkinter` 缺失。

```bash
export LDFLAGS="-L$(brew --prefix openssl@3)/lib -L$(brew --prefix readline)/lib -L$(brew --prefix sqlite)/lib -L$(brew --prefix zlib)/lib"
export CPPFLAGS="-I$(brew --prefix openssl@3)/include -I$(brew --prefix readline)/include -I$(brew --prefix sqlite)/include -I$(brew --prefix zlib)/include"
export PKG_CONFIG_PATH="$(brew --prefix openssl@3)/lib/pkgconfig:$(brew --prefix readline)/lib/pkgconfig:$(brew --prefix sqlite)/lib/pkgconfig:$(brew --prefix zlib)/lib/pkgconfig"
```

### 8.3 使用 pyenv 安装 Python

```bash
pyenv install 3.11.8
pyenv install 3.12.16
pyenv global 3.12.16
```

如果需要旧项目兼容，可额外安装 `3.10.x`：

```bash
pyenv install 3.10.13
```

### 8.4 uv、pipx 与 pip 基础配置

建议分清三类 Python 工具：

| 工具 | 用途 |
|------|------|
| `pyenv` | 管理 Python 解释器版本 |
| `uv` | 项目依赖、虚拟环境和高速包安装 |
| `pipx` | 安装全局 Python CLI，避免污染全局 site-packages |

初始化 `pipx`：

```bash
pipx ensurepath
```

`uv` 常用方式：

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

可从旧机器迁移：

```text
~/.pip/pip.conf
```

也可新建：

```bash
mkdir -p ~/.pip
cat > ~/.pip/pip.conf <<'EOF'
[global]
timeout = 60
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF
```

建议每个项目使用独立虚拟环境：

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install -U pip setuptools wheel
```

验证：

```bash
pyenv versions
python --version
pip --version
uv --version
pipx --version
```
## 9. 前端开发环境

### 9.1 使用 fnm 管理 Node.js

```bash
eval "$(fnm env --use-on-cd --shell zsh)"
fnm install --lts
fnm default lts-latest
fnm use lts-latest
```

如项目需要固定版本，在项目根目录创建 `.node-version`：

```bash
node -v > .node-version
```

### 9.2 启用 pnpm 与 bun

pnpm 统一由 Homebrew 安装，脚本不启用 Corepack。Node 25 起不随包分发 Corepack，重新打开终端不能解决其缺失。已有项目若明确依赖 Corepack，应按项目规范单独选择管理方式，避免它的代理与 Homebrew pnpm 相互覆盖。

```bash
brew install pnpm
pnpm --version
bun -v
```

### 9.3 配置前端包管理目录

首次使用 `pnpm` 前建议执行：

```bash
pnpm setup
source ~/.zshrc
```

如果所在网络访问 npm registry 不稳定，可临时切换镜像：

```bash
npm config set registry https://registry.npmmirror.com
pnpm config set registry https://registry.npmmirror.com
```

恢复官方源：

```bash
npm config set registry https://registry.npmjs.org
pnpm config set registry https://registry.npmjs.org
```

如果需要 npm 全局工具，优先使用 `pnpm`：

```bash
pnpm add -g npm-check-updates
```

验证：

```bash
node -v
npm -v
pnpm -v
bun -v
```
## 10. Rust 与容器补充运行时

附录 A 的 `~/.zshrc` 会条件加载 `~/.cargo/env`。如果你需要 Rust 开发，建议在导出 `.zshrc` 前先安装 Rustup：

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
rustup default stable
```

验证：

```bash
rustc --version
cargo --version
```

如果你暂时不做 Rust 开发，可以跳过安装。附录 A 已使用条件加载：

```bash
[[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
```

### 10.1 容器与本地数据库

后端和全栈开发通常需要容器、数据库和缓存。本文默认使用 OrbStack 承载 Docker 运行时。

首次启动 OrbStack 后验证：

```bash
orb --version
docker version
docker compose version
docker run --rm hello-world
```

常用本地服务建议优先用 Docker Compose 管理，不直接污染宿主机：

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

保存为项目内 `compose.yml` 后启动：

```bash
docker compose up -d
docker compose ps
docker compose down
```

只有需要长期本机常驻服务时，才用 Homebrew services 安装数据库，例如：

```bash
brew install postgresql@16 redis
brew services start postgresql@16
brew services start redis
```
## 11. 环境验收清单

### 11.1 基础命令验收

```bash
brew --version
brew doctor
git --version
gh --version
curl --version
wget --version
rg --version
tmux -V
starship --version
```

### 11.2 语言运行时验收

```bash
java -version
mvn -v
gradle -v

pyenv --version
python --version
pip --version

fnm --version
node -v
npm -v
pnpm -v
bun -v
```

### 11.3 桌面工具验收

```bash
open -a Ghostty
open -a "Visual Studio Code"
open -a "Google Chrome"
open -a OrbStack
open -a "JetBrains Toolbox"
```

OrbStack 验证：

```bash
orb --version
docker version
docker run --rm hello-world
```

GitHub CLI 验证：

```bash
gh auth login
gh auth status
```
## 12. 维护规范

### 12.1 每周维护

```bash
brew update
brew upgrade
brew cleanup
```

### 12.2 每月快照

```bash
./scripts/audit-environment.sh --profile core
./scripts/sync-back.sh --dry-run
./scripts/sync-back.sh
```

需要刷新完整 Homebrew 清单时：

```bash
./scripts/sync-back.sh --dry-run --include-brew
./scripts/sync-back.sh --include-brew
git diff Brewfile
```

同步后先审查 `git diff`，确认没有把 token、私有路径、公司内网地址或临时工具带入仓库。

### 12.4 版本升级策略

| 生态 | 策略 |
|------|------|
| JDK | 项目优先，默认使用脚本中的 Zulu 8，17 / 21 按项目需要补充 |
| Python | 项目虚拟环境隔离，全局只作为默认工具链 |
| Node.js | 项目用 `.node-version` 固定 |
| pnpm | 由 Homebrew 安装，按项目声明选择版本 |
| IDE | JetBrains Toolbox / Homebrew Cask 更新 |
| AI 工具 | 单独升级，避免在关键项目交付期集中更新 |

### 12.5 新项目约定

Java 项目：

```text
.sdkmanrc
pom.xml 或 build.gradle
```

Python 项目：

```text
.python-version
pyproject.toml
.venv/
```

前端项目：

```text
.node-version
package.json
pnpm-lock.yaml
```

推荐所有项目都包含：

```text
README.md
.gitignore
.editorconfig
```

## 13. 一键执行顺序摘要

新机上最短执行路径使用核心清单：

```bash
xcode-select --install

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

git clone https://github.com/<your-name>/macos-dev-setup.git
cd macos-dev-setup

make quickstart
```

如果没有 `make`：

```bash
./scripts/quickstart.sh
```

完整恢复路径放到核心环境可用之后：

```bash
gh auth login
./scripts/bootstrap.sh --profile full
```

完成后按第 11 节逐项验收。

## 14. 可选扩展清单

以下内容不是当前主链路必需，但如果你的项目需要，可以在新机稳定后单独补充。

| 类别 | 可选工具 | 说明 |
|------|----------|------|
| App Store 应用 | `mas` | 默认不进入自动安装路径，策略见 [../apps/app-store.md](../apps/app-store.md) |
| 云服务 CLI | `awscli`、`azure-cli`、`google-cloud-sdk` | 按实际云厂商选择，避免无关凭证和配置污染 |
| Kubernetes | `kubectl`、`helm`、`k9s`、`kind` | 只有需要本地集群或云原生开发时安装 |
| 数据库客户端 | DBeaver、TablePlus、DataGrip | 当前以 JetBrains Toolbox 和 Docker Compose 为主 |
| 移动端开发 | Xcode、Android Studio | iOS 原生开发必须从 App Store 或开发者网站安装 Xcode |
| 目录环境变量 | `direnv` | 多项目自动加载 `.envrc` 时很有用，但需要团队约定 |
| GPG/YubiKey | `gnupg`、YubiKey Manager | 需要强制签名提交或硬件密钥时配置 |
| dotfiles 仓库 | GitHub 私有仓库 | 私有多机器差异、加密模板和工作机器清单适合放私有仓库 |
