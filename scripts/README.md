# 脚本目录说明

本目录存放新机初始化和仓库自检脚本。脚本默认面向 macOS 和 zsh 使用场景，但脚本本身使用 bash 执行，便于 CI 和新机环境运行。

## 脚本职责

| 脚本 | 用途 | 是否会写入本机 |
|------|------|----------------|
| `quickstart.sh` | 半小时快速启动入口，串联核心安装、运行时和自检 | 是 |
| `bootstrap.sh` | 安装 Brewfile，并复制公开安全的 `configs/` 到家目录 | 是 |
| `apply-macos-defaults.sh` | 写入 Finder、Dock、键盘、截图等可审计的 macOS 默认设置 | 是 |
| `audit-environment.sh` | 检查本机命令、Brewfile、配置文件和 macOS defaults，并输出与仓库的差异 | 否 |
| `install-runtimes.sh` | 安装 Node.js、Python、Java、Maven | 是 |
| `sync-back.sh` | 将本机 zsh、Ghostty、Starship、tmux 配置同步回仓库，可选导出 Brewfile | 是 |
| `brew-maintenance.sh` | 检查、安装和预演清理 Homebrew 清单 | 可选 |
| `drill-clean-home.sh` | 用临时 `HOME` 验证恢复路径 | 是，仅写入临时目录 |
| `drill-idempotency.sh` | 用临时 `HOME` 验证 `bootstrap.sh` 可重复执行 | 是，仅写入临时目录 |
| `record-recovery-drill.sh` | 生成恢复演练报告，便于真实新机或 VM 记录证据 | 否，除非加 `--run-quickstart` |
| `doctor.sh` | 检查脚本语法、Markdown、Brewfile 和配置 | 否 |

所有会写入本机的脚本都支持 `--dry-run` 或可通过 `make dry-run` 预演。

`doctor.sh` 默认做仓库级低风险检查，不要求当前机器已经安装完整核心清单。如果要把缺失 Homebrew 依赖、字体和完整安装状态也视为失败，使用：

```bash
CHECK_BREW_INSTALLED=1 ./scripts/doctor.sh
```

如果在干净临时 `HOME` 或无网络环境中只想验证脚本、Markdown 和配置模板，可跳过 Brewfile 读取：

```bash
CHECK_BREW_READABLE=0 ./scripts/doctor.sh
```

CI 或提交前需要把可选检查也视为硬性要求时，启用严格开关：

```bash
REQUIRE_SHELLCHECK=1 \
REQUIRE_GITLEAKS=1 \
REQUIRE_GHOSTTY_VALIDATE=1 \
./scripts/doctor.sh
```

这些开关会在缺少 `shellcheck`、`gitleaks` 或 `ghostty` 时直接失败，而不是跳过对应检查。

示例 profile 只允许预演，用于检查公开的工作/个人差异清单：

```bash
./scripts/bootstrap.sh --profile work-example --dry-run
./scripts/bootstrap.sh --profile personal-example --dry-run
```

需要在提交前跑一组接近恢复流程的检查时，使用：

```bash
make drill
make drill-clean
make drill-idempotency
make record-drill
```

正式执行写入型脚本时，输出会归档到：

```text
~/.macos-dev-setup-logs/
```

可用 `MACOS_DEV_SETUP_LOG_DIR=/path/to/logs` 覆盖日志目录。`--dry-run` 不写日志。

## Homebrew 生命周期

恢复安装和日常升级分开处理。默认安装清单时不主动升级已有依赖：

```bash
./scripts/brew-maintenance.sh --profile full --install
```

需要显式升级时：

```bash
./scripts/brew-maintenance.sh --profile full --install --upgrade
```

预演清理不在清单中的依赖：

```bash
./scripts/brew-maintenance.sh --profile full --cleanup-preview
```

真正删除前必须先看清预演输出，再执行。脚本会要求输入 `cleanup` 二次确认：

```bash
./scripts/brew-maintenance.sh --profile full --cleanup-force
```

非交互环境必须显式加 `--yes` 或设置 `CONFIRM_CLEANUP=1`。

## 恢复演练记录

真实新机、迁移设备或干净 VM 上建议先生成恢复演练报告：

```bash
make record-drill
```

报告会写入 `docs/setup/recovery-drills/`。默认只执行 dry-run、clean HOME 演练、幂等演练、doctor 和审计，不会真实安装软件。需要纳入真实快速启动时：

```bash
./scripts/record-recovery-drill.sh --run-quickstart
```

## 环境差异审计

`audit-environment.sh` 是只读脚本，用于回答“当前机器和仓库声明差在哪里”：

- 检查关键命令是否存在并输出版本。
- 用 `brew bundle check` 对比 `Brewfile.core` 和 `Brewfile`。
- 对比 `~/.zshrc`、`~/.config/ghostty/config`、`~/.config/starship.toml`、`~/.tmux.conf` 和仓库配置。
- 对比 `apply-macos-defaults.sh` 中声明的 macOS defaults 期望值。

运行：

```bash
./scripts/audit-environment.sh
```

只看核心清单：

```bash
./scripts/audit-environment.sh --profile core
```

不输出配置文件 diff：

```bash
./scripts/audit-environment.sh --no-diff
```

需要发现差异时返回非零退出码：

```bash
./scripts/audit-environment.sh --strict
```

这个脚本不会写入本机，也不会自动同步配置。确认差异需要写回仓库时，先执行 `./scripts/sync-back.sh --dry-run`。

注意：默认会输出配置文件 diff，可能包含本机路径、代理地址或误写入配置的 token。公开粘贴报告前先审查，必要时使用 `--no-diff`。

## 系统默认值

`apply-macos-defaults.sh` 用于把常见的新机系统偏好变成可审计脚本，包括：

- 显示扩展名、隐藏文件、Finder 路径栏和状态栏。
- 调整按键重复速度，关闭开发时容易误触的自动替换。
- 隐藏 Dock 最近使用应用，固定 Dock 尺寸。
- 截图使用 PNG，禁用窗口阴影。
- 避免网络盘和 USB 盘生成 `.DS_Store`。

建议先预演：

```bash
./scripts/apply-macos-defaults.sh --dry-run
```

确认后再执行：

```bash
./scripts/apply-macos-defaults.sh --restart-apps
```

脚本执行前会导出相关 `defaults` 域到 `~/.macos-dev-setup-backup/<时间戳>/macos-defaults/`，便于事后对比和手动恢复。

## 同步回仓库

日常在家目录里调整配置后，可以预演同步：

```bash
./scripts/sync-back.sh --dry-run
```

确认后执行：

```bash
./scripts/sync-back.sh
```

需要同时刷新完整 Homebrew 清单时：

```bash
./scripts/sync-back.sh --include-brew
```

同步后必须检查 `git diff`。不要把私钥、token、公司内网地址或临时本地路径带进提交。

## 扩展方式

### 增加新的配置文件

1. 将配置放到 `configs/<工具名>/`。
2. 在 `bootstrap.sh` 中增加备份和复制逻辑。
3. 在 `configs/README.md` 中增加映射说明。
4. 在 `doctor.sh` 中增加语法或格式检查。
5. 如会写入本机，补充 `drill-clean-home.sh` 或 `drill-idempotency.sh` 的验证。

凭证相关配置只提交 `*.example`。不要让 `bootstrap.sh` 自动复制 SSH、npm、Maven、公司代理等可能包含私密值的真实文件。

编辑器扩展清单使用 `configs/vscode/extensions.txt.example`，只放可公开扩展 ID；真实账号同步和私有扩展留给编辑器本身或私有仓库。

### 增加新的运行时

1. 在 `install-runtimes.sh` 中增加开关参数。
2. 保持默认路径足够轻量，不要把耗时大的工具放进半小时路径。
3. 在 [../docs/runtimes/development-runtimes.md](../docs/runtimes/development-runtimes.md) 记录使用方式。
4. 在 [../docs/reference/cheatsheet.md](../docs/reference/cheatsheet.md) 增加常用命令。

### 增加新的 macOS 默认设置

1. 先确认设置可以通过 `defaults read` 验证。
2. 在 `apply-macos-defaults.sh` 中增加 `write_default` 调用。
3. 在 `audit-environment.sh` 中增加对应 `audit_default_value` 检查。
4. 如涉及新 defaults 域，先增加 `backup_domain`。
5. 在 [../docs/setup/guide.md](../docs/setup/guide.md) 或 [../docs/setup/maintenance.md](../docs/setup/maintenance.md) 说明影响。
6. 在 `doctor.sh` 中保留脚本语法检查。

### 增加新的检查项

1. 优先放进 `doctor.sh`。
2. 检查失败要返回非零退出码。
3. 输出使用简体中文。
4. 避免在普通自检里做耗时安装。

## 安全约束

- 不在脚本中写死真实 token、私钥、cookie。
- 不默认执行删除数据、重置仓库、清空目录等破坏性命令。
- 涉及覆盖用户文件时必须先备份，或只在 `--dry-run` 中展示。
- 新增脚本后同步更新 `.github/workflows/ci.yml` 和 `doctor.sh`。
