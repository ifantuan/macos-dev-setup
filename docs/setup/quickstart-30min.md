# 30 分钟快速启动

目标：新 Mac 在半小时内完成核心工具安装，并能进入 Java、Python、前端或 AI 编码工作。

## 结论

如果网络正常、Xcode Command Line Tools 安装顺利，这个仓库现在可以走半小时路径：

```bash
git clone https://github.com/<your-name>/macos-dev-setup.git
cd macos-dev-setup
make quickstart
```

这条路径只追求“能开始开发”，不会一次装完整 GUI 软件套件。本地大模型、多个浏览器、JetBrains Toolbox、会议软件、网盘和娱乐应用建议放到后续完整安装。

## 适用范围

这条路径只安装核心工具：

- Homebrew 基础工具
- Git / GitHub CLI
- Ghostty / VS Code / Chrome
- zsh / tmux / Starship / ripgrep / fzf / zoxide
- SDKMAN / uv / pyenv / fnm / pnpm / bun
- OrbStack / Bruno
- Codex CLI / Claude Code
- 1Password

完整 GUI 应用、音乐、会议、网盘、多个浏览器、JetBrains Toolbox、LM Studio 等放到完整安装路径。

## 预计时间

| 阶段 | 目标时间 | 说明 |
|------|----------|------|
| Xcode Command Line Tools | 5-10 分钟 | macOS 首次安装可能更久 |
| Homebrew | 3-8 分钟 | 网络质量影响明显 |
| 核心 Brewfile | 10-20 分钟 | 只安装 `Brewfile.core` |
| 运行时初始化 | 5-10 分钟 | Python 默认用 `pyenv`，和项目 `.python-version` 保持一致 |
| 登录与验证 | 5 分钟 | GitHub、1Password、IDE、AI 工具 |

网络慢或首次安装 Xcode CLT 时可能超过 30 分钟。

## 步骤 1：安装基础工具

```bash
xcode-select --install
```

安装 Homebrew：

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

## 步骤 2：克隆仓库

```bash
git clone git@github.com:<your-name>/macos-dev-setup.git
cd macos-dev-setup
```

如果 SSH 还没配好，先用 HTTPS：

```bash
git clone https://github.com/<your-name>/macos-dev-setup.git
cd macos-dev-setup
```

## 步骤 3：核心安装

先预演：

```bash
make dry-run
```

执行核心安装：

```bash
make quickstart
```

如果只想复制配置，不安装软件：

```bash
./scripts/bootstrap.sh --skip-brew
```

## 步骤 4：登录与验证

登录 GitHub：

```bash
gh auth login
gh auth status
```

验证基础工具：

```bash
./scripts/doctor.sh
git --version
node -v || true
uv python list --only-installed || true
java -version || true
```

打开核心应用：

```bash
open -a Ghostty
open -a "Visual Studio Code"
open -a "Google Chrome"
open -a OrbStack
```

## 步骤 5：进入开发

前端项目：

```bash
pnpm install
pnpm dev
```

Python 项目：

```bash
uv venv
source .venv/bin/activate
uv pip install -r requirements.txt
```

`scripts/install-runtimes.sh` 默认已经通过 `pyenv` 安装全局 Python。进入项目后按需固定本项目版本：

```bash
pyenv local 3.12.2
```

Java 项目：

```bash
mvn test
```

AI 编码：

```bash
tmux new -s ai
codex
# 或
claude
```

## 完整安装

核心环境稳定后，再安装完整软件清单：

```bash
./scripts/bootstrap.sh --profile full
```

或者只安装完整 Brewfile：

```bash
brew bundle --file Brewfile --verbose
```

## 半小时边界

以下内容不计入半小时路径：

- JetBrains Toolbox、Cursor、Zed、Warp 等完整编辑器组合。
- LM Studio、本地大模型和模型下载。
- 微信、飞书、钉钉、腾讯会议等办公应用登录。
- Android Studio、Xcode、移动端模拟器。
- 公司 VPN、内网证书、私服账号、GPG/YubiKey。

这些内容建议在能运行项目之后再逐项恢复。
