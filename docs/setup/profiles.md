# 环境分层与机器 Profile

本页解决“同一个仓库如何同时服务个人机器、工作机器、轻量备用机器”的问题。默认不把公司凭证、内网地址和个人 App Store 登录态写进仓库。

## Profile 分层

| Profile | 目标 | 自动化范围 | 不自动化内容 |
|---------|------|------------|--------------|
| `core` | 30 分钟内进入开发 | `Brewfile.core`、dotfiles、运行时、自检 | 大量 GUI、移动端模拟器、本地模型 |
| `full` | 恢复完整个人工作站 | `make full` 只安装 `Brewfile` 和 dotfiles；`quickstart.sh --profile full` 另执行运行时、自检 | 登录态、私钥、token、公司内网配置 |
| `work` | 公司机器差异层 | 公司允许公开记录的工具名和流程 | VPN、证书、代理账号、内网地址 |
| `personal` | 个人偏好差异层 | 娱乐、媒体、个人效率工具说明 | Apple ID、购买记录、私有云盘路径 |

当前仓库实际提供 `core` 和 `full` 两个可执行 profile。`work` 和 `personal` 暂不做自动安装脚本，避免把敏感差异混进公共配置。

默认 core/full 均只使用官方 Homebrew 源。`Brewfile.personal.example` 中的第三方示例不自动启用；选择前应审查来源、安装步骤及信任范围，尤其是移除 macOS 隔离属性的行为。

## 推荐目录策略

如果未来确实需要多机器差异层，优先维护这些示例和私有文件，而不是直接修改核心路径：

```text
Brewfile.work.example
Brewfile.personal.example
configs/zsh/zshrc.work.example
configs/zsh/zshrc.personal.example
docs/setup/work-machine.md
docs/setup/personal-machine.md
```

当前仓库已经提供 `Brewfile.work.example` 和 `Brewfile.personal.example`，用于记录可公开的差异工具名。它们默认不被 `make quickstart`、`make core` 或 `make full` 执行。

可以用 dry-run 检查示例清单会做什么：

```bash
./scripts/bootstrap.sh --profile work-example --dry-run
./scripts/bootstrap.sh --profile personal-example --dry-run
./scripts/audit-environment.sh --profile work-example
./scripts/audit-environment.sh --profile personal-example
```

原则：

- `*.example` 只放占位和工具名，不放真实凭证。
- 真实 `Brewfile.work`、`.env.work`、代理地址和证书路径留在本机或私有仓库。
- `make quickstart` 继续只走 `core`，不要引入机器差异。
- `scripts/doctor.sh` 只检查公开文件；私有文件用人工验收。

## 私有配置加载建议

Shell 配置可以保留一个私有扩展点：

```zsh
if [[ -f "$HOME/.zshrc.local" ]]; then
  source "$HOME/.zshrc.local"
fi
```

`configs/zsh/zshrc` 已适合公开提交。真实代理、公司内网环境变量、私有 token 和别名应放在 `~/.zshrc.local`，并由 1Password、钥匙串或公司设备管理工具维护。

当前仓库已经在 `configs/zsh/zshrc` 中加载 `~/.zshrc.local`。该文件属于本机私有配置，不应提交。

如果确实需要本机 Homebrew 差异，优先保留为本机私有文件，例如：

```text
~/Brewfile.local
```

然后人工执行：

```bash
brew bundle --file ~/Brewfile.local --verbose --no-upgrade
```

公共仓库只维护 `Brewfile.core`、`Brewfile` 和 `*.example`。

## 工作机器边界

工作机器上不建议自动化：

- VPN、证书、MDM、设备管理配置。
- 公司代理账号、内网域名、私有 registry 地址。
- 私服 token、Maven settings 密码、npm token。
- 绕过公司安全策略的命令。

可以公开记录：

- 需要安装的软件名称。
- 哪些步骤必须交给 IT 或公司文档。
- 自检命令和排障思路。
- 不含敏感值的配置模板。

## App Store 应用边界

App Store 应用建议默认手动安装。只有当它们成为新机恢复主路径，才引入 `mas`：

```bash
brew install mas
mas signin
mas list
```

导出后不要直接提交未经审查的完整列表。先确认：

- 应用是否与开发环境恢复相关。
- 应用 ID 是否稳定。
- 是否暴露个人购买偏好或公司内部应用。

如果需要纳入仓库，优先新建 `docs/apps/app-store.md` 记录用途，再考虑单独的 `Masfile.example`。
