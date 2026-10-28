# 新机恢复演练记录

本页用于记录真实或半真实的新机恢复演练。它不是安装手册，而是验证仓库是否真的能把一台干净 macOS 恢复到可开发状态。

## 演练流程

1. 记录机器型号、芯片架构、macOS 版本和网络环境。
2. 安装 Xcode Command Line Tools 与 Homebrew。
3. 克隆仓库并运行 `make dry-run`。
4. 运行 `make quickstart`。
5. 运行 `./scripts/apply-macos-defaults.sh --dry-run`，确认默认设置写入范围。
6. 登录 GitHub CLI、1Password、IDE 和 AI 编码工具。
7. 运行 `./scripts/audit-environment.sh --profile core --no-diff`。
8. 记录失败点、人工步骤、总耗时和最终验收结果。

## 验收标准

| 项目 | 验收命令 |
|------|----------|
| 仓库自检 | `./scripts/doctor.sh` |
| 隔离回归测试 | `make test` |
| 核心软件清单 | `brew bundle check --file Brewfile.core --no-upgrade` |
| Shell 启动 | `zsh -n ~/.zshrc` |
| Git | `git --version` |
| GitHub CLI | `gh auth status` |
| Java | `java -version` |
| Python | `python3 --version` |
| Node.js | `node -v` |
| pnpm | `pnpm -v` |
| 容器运行时 | `docker version` |
| Ghostty | `ghostty +validate-config` |
| 临时 HOME 恢复 | `make drill-clean` |
| 重复执行安全性 | `make drill-idempotency` |

## 演练记录模板

```text
日期：
机器：
macOS：
网络：
目标 profile：core / full

开始时间：
结束时间：
总耗时：

执行命令：
- make dry-run
- make quickstart
- make drill-clean
- make drill-idempotency
- ./scripts/doctor.sh
- ./scripts/audit-environment.sh --profile core --no-diff

失败点：
-

人工步骤：
-

最终结果：
- 通过 / 未通过

后续改进：
-
```

## 当前基线

在日常维护中，每次显著修改 `Brewfile.core`、`configs/` 或 `scripts/` 后，至少执行一次半恢复演练：

```bash
make drill
make drill-clean
make drill-idempotency
```

`make drill` 会基于当前用户环境做预演和审计；`make drill-clean` 会创建临时 `HOME`，真实写入 zsh、Ghostty、Starship、tmux 配置并校验文件内容，同时验证写入型脚本 dry-run、示例 profile 和自检；`make drill-idempotency` 会在临时 `HOME` 连续执行两次 bootstrap 并比较结果。这仍不能完全替代真实新机演练，但能提前发现路径、语法、清单读取、空 HOME 和重复执行行为问题。

真实重装、迁移设备或干净 VM 上建议生成可提交报告：

```bash
make record-drill
```

报告会写入 `docs/setup/recovery-drills/`，默认只执行 `make dry-run`，不会真实安装软件。需要把真实 `make quickstart` 也纳入证据时：

```bash
./scripts/record-recovery-drill.sh --run-quickstart
```

完整 profile 使用 `./scripts/record-recovery-drill.sh --profile full --run-quickstart`。预演、真实安装与最终环境审计使用同一 profile；审计启用 `--strict`，差异会使记录命令返回非零。即使生成了报告，也必须按其中的退出码与人工记录判断恢复是否成功。

## 已记录演练

### 2026-06-02 半恢复演练

```text
日期：2026-06-02
机器：本机工作区
macOS：15.7.7
网络：现有开发环境
目标 profile：core

执行命令：
- make drill
- make drill-clean
- make drill-idempotency
- ./scripts/bootstrap.sh --profile work-example --dry-run
- ./scripts/bootstrap.sh --profile personal-example --dry-run
- ./scripts/audit-environment.sh --profile work-example --no-diff
- ./scripts/audit-environment.sh --profile personal-example --no-diff

结果：
- 通过。quickstart dry-run、bootstrap dry-run、macOS defaults dry-run、clean HOME drill、idempotency drill、doctor 和 audit 均可执行。
- doctor 已验证脚本语法、Markdown、内部链接、示例 Brewfile、配置模板 XML/JSON 和旧配置路径残留。
- audit 能读取 Starship 新路径和 work/personal 示例清单。
- clean HOME drill 已验证空 `HOME` 下的 zsh、Ghostty、Starship、tmux 配置真实落位，以及写入型脚本预演。
- idempotency drill 已验证临时 `HOME` 下连续执行两次 bootstrap 后配置仍与仓库一致。

已知差异：
- 这是半恢复演练，不是干净新机演练。
- 本机缺少部分 Brewfile.core 依赖，audit 会按预期报告差异。
- 本机 Ghostty、tmux、Starship 与仓库配置不完全一致或缺失，audit 会按预期报告差异。

后续改进：
- 下一次真实重装或迁移设备时补充干净新机演练记录。
```
