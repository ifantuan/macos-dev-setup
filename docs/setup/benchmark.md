# 外部标杆对比与改进路线

本页记录本仓库和优秀 macOS 配置指南、dotfiles 仓库的对比结果。用途不是追逐每个工具，而是把外部成熟实践转化成可维护的仓库标准。

## 参考对象

| 参考对象 | 主要启发 | 本仓库吸收方式 |
|----------|----------|----------------|
| [thoughtbot Laptop](https://github.com/thoughtbot/laptop) | 新机脚本应可重复执行，并在执行前明确说明会改变什么 | 保留 `make dry-run`，所有写入型脚本继续支持预演 |
| [Mathias Bynens dotfiles](https://github.com/mathiasbynens/dotfiles) | macOS defaults 可以脚本化，Finder、Dock、键盘、截图等设置应可审计 | 新增 `scripts/apply-macos-defaults.sh`，并纳入文档和自检 |
| [Homebrew Bundle 官方实践](https://docs.brew.sh/Brew-Bundle-and-Brewfile) | 软件清单用 Brewfile 声明，安装、检查、导出分别使用 `brew bundle install/check/dump` | 继续维护 `Brewfile.core` 和 `Brewfile` 双清单 |
| [mac.install.guide](https://mac.install.guide/) | 新手路径要先讲顺序和验证，不应一开始给过多可选项 | 保留 `docs/start-here.md` 和 `docs/setup/quickstart-30min.md` |
| [chezmoi](https://www.chezmoi.io/) / [Mackup](https://github.com/lra/mackup) 类工具 | 长期 dotfiles 需要关注同步、diff、回滚和跨机器差异 | 当前采用轻量脚本备份；未来多机器同步再评估引入专用工具 |
| macOS Ansible / playbook 类仓库 | 复杂环境通常需要按机器用途拆分变量和任务 | 新增 `docs/setup/profiles.md`，先明确 `core`、`full`、`work`、`personal` 边界 |

## 顶级 macOS 配置指南标准

一个顶级指南至少应满足以下标准：

| 标准 | 当前状态 | 证据 |
|------|----------|------|
| 快速路径 | 已具备 | `make quickstart`、`Brewfile.core`、`docs/setup/quickstart-30min.md` |
| 完整恢复路径 | 已具备 | `scripts/bootstrap.sh --profile full`、`Brewfile` |
| 可预演 | 已具备 | `make dry-run`、写入型脚本的 `--dry-run` |
| 覆盖前备份 | 已具备 | `bootstrap.sh`、`apply-macos-defaults.sh` |
| 可验证 | 已具备 | `scripts/doctor.sh`、Markdown 链接检查、Brewfile 和示例模板检查 |
| 系统默认值自动化 | 已补齐 | `scripts/apply-macos-defaults.sh` |
| 分层文档 | 已具备 | `docs/start-here.md`、专题目录 |
| 安全边界 | 已具备 | `SECURITY.md`、`.env.example`、脚本安全约束 |
| 外部参考可追溯 | 已补齐 | 本文和 `docs/reference/official-links.md` |
| 长期维护手册 | 已具备 | `docs/setup/maintenance.md`、`scripts/sync-back.sh`、`scripts/brew-maintenance.sh` |
| CI 自检 | 已补齐 | `.github/workflows/ci.yml` 调用 dry-run、恢复演练和严格 `scripts/doctor.sh` |
| 多机器边界 | 已补齐 | `docs/setup/profiles.md`、`Brewfile.work.example`、`Brewfile.personal.example` |
| 私有配置模板 | 已补齐基础层 | `configs/git`、`configs/ssh`、`configs/npm`、`configs/pip`、`configs/maven`、`configs/vscode` |
| 恢复演练 | 已补齐半恢复验证 | `docs/setup/recovery-drill.md`、`scripts/drill-clean-home.sh`、`scripts/drill-idempotency.sh` |
| 恢复记录采集 | 已补齐 | `scripts/record-recovery-drill.sh`、`docs/setup/recovery-drills/` |
| 安装日志 | 已补齐 | `scripts/lib/logging.sh` 写入 `~/.macos-dev-setup-logs/` |
| 密钥扫描 | 已补齐 | `doctor.sh` 在安装 `gitleaks` 时运行扫描，CI 中强制执行 |
| 支持范围 | 已补齐 | `docs/setup/support-matrix.md` |
| GUI / 编辑器偏好 | 已补齐基础模板 | `configs/vscode/settings.json.example`、`configs/vscode/extensions.txt.example` |
| App Store 边界 | 已补齐 | `docs/apps/app-store.md` |

## 与标杆仓库的差异判断

### 已经优于普通 dotfiles 的部分

- 不只是备份配置文件，而是把快速启动、完整恢复、运行时、AI 编码工具和排障拆成手册。
- 有 `Brewfile.core` / `Brewfile` 双清单，避免新机首次安装被大量 GUI 应用拖慢。
- 覆盖前备份用户原配置，降低 fork 后直接执行的风险。
- `doctor.sh` 会检查脚本语法、Markdown 代码块、内部链接、Brewfile 和 Ghostty 配置。
- CI 安装 ShellCheck、gitleaks 和 Ghostty 后运行严格 `doctor.sh`，减少关键检查被跳过的风险。
- 提供 Git、SSH、npm、pip、Maven、VS Code 的无凭证模板，以及 Starship 的可落地配置。
- 面向 Java、Python、前端、AI 编码代理和本地模型工作流，而不是泛泛的软件推荐。

### 仍需持续改进的部分

- `work` 和 `personal` 仍是示例层，不会自动安装真实私有差异。这样能避免敏感配置进入公共仓库；如果未来需要自动化，应放到私有仓库或引入带模板/加密能力的专用工具。
- 还没有真实干净新机的恢复演练记录。当前已经有 clean HOME 和幂等演练，下一次重装或新设备迁移时应补第一份实际结果。

## 采纳原则

外部实践进入本仓库前，必须满足：

1. 能解释为什么适合 Java / Python / 前端 / AI 编码工作站。
2. 不把私钥、token、公司内网信息写入仓库。
3. 有 dry-run、备份或清晰回滚方式。
4. 能被 `doctor.sh` 或明确的人工验收步骤验证。
5. 不显著拖慢 `make quickstart` 的半小时路径。

## 后续路线

| 优先级 | 改进项 | 触发条件 |
|--------|--------|----------|
| 中 | 增加真实新机恢复演练记录 | 下一次重装或迁移设备时 |
| 中 | 扩展 GUI App 偏好恢复 | Karabiner、JetBrains 等偏好成为恢复瓶颈后 |
| 低 | 引入 `Masfile.example` | App Store 应用成为恢复主路径后 |
| 低 | 评估 chezmoi / Mackup | 需要加密模板、跨平台和多主机差异层后 |
