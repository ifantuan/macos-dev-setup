# 维护与迁移手册

## 每周维护

```bash
brew update
brew upgrade
brew cleanup
```

如果只是恢复清单，不希望顺手升级已有依赖，使用：

```bash
./scripts/brew-maintenance.sh --profile full --install
```

需要明确升级时再加：

```bash
./scripts/brew-maintenance.sh --profile full --install --upgrade
```

预演清理清单外依赖：

```bash
./scripts/brew-maintenance.sh --profile full --cleanup-preview
```

只有确认预演输出无误后，才执行强制清理。脚本会要求输入 `cleanup` 二次确认：

```bash
./scripts/brew-maintenance.sh --profile full --cleanup-force
```

## 每月快照

```bash
./scripts/audit-environment.sh --profile core
./scripts/sync-back.sh --dry-run
./scripts/sync-back.sh
```

如果本月安装或卸载了 Homebrew 软件，再刷新完整清单：

```bash
./scripts/sync-back.sh --include-brew
```

刷新后不要直接提交，先审查：

- 新增 `brew` 是否属于开发恢复路径。
- 新增 `cask` 是否会拖慢 `core` 路径。
- 是否把一次性工具、公司内部工具或个人娱乐软件带入了公共清单。
- `Brewfile.core` 是否仍只保留半小时内进入开发所需工具。

然后检查差异并运行自检：

```bash
git diff
./scripts/doctor.sh
```

## 新机迁移顺序

1. 登录 Apple ID、开启 FileVault 和查找。
2. 安装 Xcode Command Line Tools。
3. 安装 Homebrew。
4. 克隆本仓库。
5. 按 [profiles.md](profiles.md) 确认当前机器走 `core`、`full` 还是只做私有差异层。
6. 运行 `make quickstart`。
7. 预演并应用 macOS 默认设置。
8. 登录 GitHub CLI。
9. 恢复 SSH、GPG、Maven、npm、pip 等凭证配置。
10. 按需运行 `scripts/bootstrap.sh --profile full`。
11. 运行 `scripts/audit-environment.sh --profile core` 对比本机和仓库声明。
12. 跑环境验收命令。

系统默认设置建议先预演：

```bash
./scripts/apply-macos-defaults.sh --dry-run
./scripts/apply-macos-defaults.sh --restart-apps
```

## GitHub 推送

```bash
git add .
git commit -m "更新 macOS 环境配置"
git push
```

首次推送：

```bash
git remote add origin git@github.com:<your-name>/macos-dev-setup.git
git push -u origin main
```

仓库包含 `.github/workflows/ci.yml`。推送到 GitHub 后，GitHub Actions 会在 `push` 和 `pull_request` 上运行 `./scripts/doctor.sh`。

## 不应提交的内容

```text
.env
.env.local
SSH 私钥
GPG 私钥
npm token
Maven 私服密码
云厂商凭证
```

## 验收命令

```bash
./scripts/doctor.sh
./scripts/audit-environment.sh --profile core
./scripts/apply-macos-defaults.sh --dry-run
brew doctor
git --version
gh auth status
java -version
python --version
node -v
pnpm -v
docker version
ghostty +validate-config
```

如果要确认 `Brewfile` 中的软件是否全部安装：

```bash
CHECK_BREW_INSTALLED=1 ./scripts/doctor.sh
```

## 恢复演练

显著修改 `Brewfile.core`、`configs/` 或 `scripts/` 后，按 [recovery-drill.md](recovery-drill.md) 做一次半恢复演练。真实新机或干净测试账号上完成的演练，应记录耗时、失败点、人工步骤和最终验收结果。

```bash
make drill
make drill-clean
make drill-idempotency
```

## 核心安装与完整安装

核心安装用于快速进入开发：

```bash
make quickstart
```

完整安装用于恢复全部 GUI 和个人工具：

```bash
./scripts/bootstrap.sh --profile full
```

更新核心清单时，优先保证 `Brewfile.core` 足够小，只保留半小时内进入开发所必需的工具。

## 工作/个人机器差异

多机器差异先按 [profiles.md](profiles.md) 管理。不要把公司 VPN、代理、证书、私服地址、内网域名或 token 写进公开仓库。

建议：

- 公共仓库只维护 `core` 和 `full`。
- 工作机器差异记录为 `Brewfile.work.example`、`*.example`、公司文档链接或人工验收步骤。
- 个人机器差异记录为 `Brewfile.personal.example` 或私有仓库。
- 私有值放在 `~/.zshrc.local`、1Password、钥匙串或公司设备管理工具中。

## App Store 应用

App Store 应用不进入默认恢复路径。需要时按 [../apps/app-store.md](../apps/app-store.md) 评估是否引入 `mas` 或 `Masfile.example`。
