# 包管理器手册

## 分工原则

| 工具 | 管理对象 |
|------|----------|
| Homebrew | macOS 命令行工具、GUI App、字体 |
| mas | App Store 应用，默认不进入自动安装路径 |
| SDKMAN | JDK、Maven、Gradle |
| pyenv | Python 解释器版本 |
| uv | Python 项目依赖和虚拟环境 |
| pipx | 全局 Python CLI |
| fnm | Node.js 版本 |
| pnpm | 前端包依赖 |
| bun | JS 运行时、脚本和部分项目依赖 |
| rustup | Rust 工具链 |

原则：不要用系统自带 Python、Node 或 Java 做项目开发。

## 官方资料

| 工具 | 官方资料 |
|------|----------|
| Homebrew | <https://brew.sh/> |
| Homebrew Bundle | <https://docs.brew.sh/Brew-Bundle-and-Brewfile> |
| mas | <https://github.com/mas-cli/mas> |
| SDKMAN | <https://sdkman.io/usage> |
| pyenv | <https://github.com/pyenv/pyenv> |
| uv | <https://docs.astral.sh/uv/> |
| pipx | <https://pipx.pypa.io/> |
| fnm | <https://github.com/Schniz/fnm> |
| pnpm | <https://pnpm.io/> |
| Bun | <https://bun.sh/docs> |
| rustup | <https://rustup.rs/> |

## Homebrew

支持基线为 Homebrew 7。默认清单仅使用官方源；Bundle 已内置，无需安装 `homebrew/bundle`。导出默认含说明注释，不再传已停用的 `--describe`。需要保留旧清单直到导出成功时，使用仓库的 `sync-back.sh --include-brew` 或 `backup-configs.sh --items brew`。

安装核心清单：

```bash
brew bundle --file Brewfile.core --verbose --no-upgrade
```

安装完整清单：

```bash
brew bundle --file Brewfile --verbose --no-upgrade
```

检查缺失：

```bash
brew bundle check --file Brewfile --no-upgrade
```

导出当前机器清单：

```bash
brew bundle dump --file Brewfile --force
```

App Store 应用不放入默认 Brewfile。确实需要时先阅读 [../apps/app-store.md](../apps/app-store.md)，再决定是否引入 `mas` 或 `Masfile.example`。

维护：

```bash
brew update
brew upgrade
brew cleanup
```

### Homebrew 命令速查

| 命令 | 用途 |
|------|------|
| `brew search name` | 搜索包 |
| `brew info name` | 查看包信息 |
| `brew install name` | 安装 formula |
| `brew install --cask name` | 安装 cask |
| `brew list` | 查看已安装 |
| `brew outdated` | 查看可升级项 |
| `brew upgrade` | 升级 |
| `brew cleanup` | 清理缓存 |
| `brew doctor` | 环境诊断 |

## SDKMAN

安装：

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

常用命令：

```bash
sdk list java
sdk install java 8.0.492-zulu
sdk default java 8.0.492-zulu
sdk install maven
sdk install gradle
```

项目级固定可使用 `.sdkmanrc`。

### SDKMAN 命令速查

| 命令 | 用途 |
|------|------|
| `sdk list java` | 查看 JDK 版本 |
| `sdk install java <version>` | 安装 JDK |
| `sdk use java <version>` | 当前 shell 使用某版本 |
| `sdk default java <version>` | 设置默认 JDK |
| `sdk current` | 查看当前版本 |
| `sdk env init` | 生成 `.sdkmanrc` |
| `sdk env` | 按 `.sdkmanrc` 切换 |

## pyenv / uv / pipx

默认用 `pyenv` 安装 Python 解释器，便于复用 `.python-version` 并统一项目版本：

```bash
pyenv install 3.12.16
pyenv global 3.12.16
pyenv versions
```

需要快速使用预编译解释器时，可临时改用 `uv`：

```bash
uv python install 3.12.16 --default
uv python list --only-installed
```

项目虚拟环境：

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

全局 CLI：

```bash
pipx install poetry
pipx list
```

### Python 工具速查

| 命令 | 用途 |
|------|------|
| `pyenv versions` | 查看已安装 Python |
| `pyenv install <version>` | 安装 Python |
| `pyenv global <version>` | 设置全局 Python |
| `pyenv local <version>` | 项目级固定版本 |
| `uv python install <version> --default` | 按需快速安装预编译 Python |
| `uv python list --only-installed` | 查看 uv 已安装 Python |
| `uv venv` | 创建虚拟环境 |
| `uv pip install -r requirements.txt` | 安装依赖 |
| `pipx install <tool>` | 安装全局 Python CLI |
| `pipx upgrade-all` | 升级 pipx 工具 |

## fnm / pnpm / bun

默认版本集中在 `configs/runtimes/versions.sh`，可用 `NODE_VERSION` 等环境变量覆盖。pnpm 只由 Homebrew 安装，运行时脚本检查它是否可用，不再运行 Corepack。项目确需 Corepack 时请另选对应管理方案；它从 Node 25 起不随 Node 分发，不能依赖重开终端自动出现。

Node.js：

```bash
fnm install --lts
fnm default lts-latest
fnm use lts-latest
```

pnpm：

```bash
brew install pnpm
pnpm --version
pnpm setup
```

Bun：

```bash
bun -v
bun install
bun run dev
```

项目级固定版本：

```bash
node -v > .node-version
```

### 前端工具速查

| 命令 | 用途 |
|------|------|
| `fnm install --lts` | 安装 Node LTS |
| `fnm use <version>` | 切换 Node |
| `fnm default <version>` | 设置默认 Node |
| `brew install pnpm` | 安装 Homebrew 管理的 pnpm |
| `pnpm install` | 安装依赖 |
| `pnpm add <pkg>` | 添加依赖 |
| `pnpm dlx <tool>` | 临时运行工具 |
| `bun install` | Bun 安装依赖 |
| `bun run <script>` | Bun 运行脚本 |

## 镜像策略

镜像源只作为网络优化，不应改变项目依赖声明。

临时切换 npm：

```bash
npm config set registry https://registry.npmmirror.com
pnpm config set registry https://registry.npmmirror.com
```

恢复官方：

```bash
npm config set registry https://registry.npmjs.org
pnpm config set registry https://registry.npmjs.org
```
