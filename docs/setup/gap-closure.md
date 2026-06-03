# 主要缺口修复记录

本页记录外部标杆对比后的主要缺口，以及当前仓库已经落地的修复方式。它用于避免后续维护时重复讨论同一类问题。

## 已机制化的缺口

| 缺口 | 当前处理 |
|------|----------|
| 本机私有配置扩展点 | `configs/zsh/zshrc` 会加载 `~/.zshrc.local`，真实代理、token、公司别名放在本机私有文件 |
| 安装过程日志 | 写入型入口会把正式执行输出归档到 `~/.macos-dev-setup-logs/`，便于排障 |
| 干净 HOME 恢复检查 | `make drill-clean` 使用临时 `HOME` 真实写入核心配置并校验文件内容 |
| 重复执行安全性 | `make drill-idempotency` 在临时 `HOME` 连续执行两次 `bootstrap.sh --skip-brew` 并比较结果 |
| Homebrew 生命周期 | `scripts/brew-maintenance.sh` 区分 check、install、cleanup 预演和强制清理；安装默认 `--no-upgrade` |
| 脚本质量检查 | `doctor.sh` 在安装 `shellcheck` 时自动运行 ShellCheck；CI 中通过严格开关强制执行 |
| 密钥扫描 | `doctor.sh` 在安装 `gitleaks` 时自动运行密钥扫描；CI 中通过严格开关强制执行 |
| CI 恢复验证 | GitHub Actions 安装校验工具后运行 dry-run、clean HOME drill、幂等演练和严格 `doctor.sh` |
| GUI / 编辑器偏好 | VS Code 设置和扩展提供公开模板，真实账号同步不进入仓库 |
| 真实恢复记录采集 | `scripts/record-recovery-drill.sh` 生成可提交的演练报告 |

## 仍需真实环境证明的缺口

真实干净新机恢复不能只靠当前工作区证明。下一次重装、迁移设备或使用干净 VM 时，应先运行 `make record-drill` 生成报告，再补充人工记录。报告至少包含：

- 机器型号、芯片架构、macOS 版本、网络环境。
- `make dry-run`、`make quickstart`、`make drill-clean`、`make drill-idempotency` 的结果。
- Homebrew、Java、Python、Node.js、pnpm、Docker、Ghostty 的验收命令。
- 失败点、人工步骤、总耗时和后续修复项。

## 取舍

暂不引入 chezmoi、yadm、Mackup 或 Ansible。当前仓库仍以轻量 Bash、Brewfile 和 Markdown 为主；当私有多机器差异、加密模板或更多 GUI 应用偏好同步成为主需求时，再评估这些工具。
