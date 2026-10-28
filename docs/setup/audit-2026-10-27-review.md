# 审计报告复核

> 复核日期：2026-10-27。复核对象：[audit-2026-10-27.md](audit-2026-10-27.md)。代码基线：`9b373db`。复核环境：macOS 15.7.7、arm64、系统 Bash 3.2.57、Homebrew 7.0.11。
>
> 复核方式：对照仓库代码和本机 Homebrew 源码逐条核对；只做只读检查和临时目录运行，未修改仓库或本机环境。

## 结论

**报告可信，可以作为修复依据。** 6 项 P1 均在 Homebrew 7.0.11 源码或系统 Bash 3.2 上得到证实，计数和行号均一致。未发现事实错误，仅有一处表述建议收紧（见 A13）。

## P1 逐项结果

| 编号 | 结论 | 依据 |
|------|------|------|
| A01 清理预演可能真的卸载软件 | 属实 | 不带 `--force` 时，`bundle/subcommand/cleanup.rb:87` 默认询问确认；终端中按 `y` 即进入 `cleanup(force: true)` 实际卸载（`cleanup.rb:230-232`）。`ask.rb` 仅在标准输入、输出均为终端时弹出确认 |
| A02 符号链接的备份失效 | 属实 | `bootstrap.sh:114` 使用 `cp -R` 备份，在 macOS 上复制链接本身；随后 `:137` 的 `cp` 穿过链接改写其指向的原文件 |
| A03 系统 Bash 3.2 下 quickstart 中断 | 属实 | `/bin/bash` 3.2.57 在 `set -u` 下展开空数组，实测报 `a[@]: unbound variable` |
| A04 `homebrew/bundle` tap 阻断干净机器安装 | 属实 | `official_taps.rb` 的 `DEPRECATED_OFFICIAL_TAPS` 包含 `bundle`，`Tap#install` 遇到时直接 `odie`（`tap.rb:680`）；Bundle 代码中无特殊处理 |
| A05 `--describe` 参数已停用 | 属实 | 实测 `brew bundle dump --describe` 输出 `Calling the --describe switch is disabled!` 并返回 1；源码标注 `odisabled: true` |
| A06 第三方 tap 的信任与清理 | 源码层面属实 | 带 `--force` 的清理执行 `Trust.replace!`（`cleanup.rb:158`）；`bundle/trust.rb` 只信任 Brewfile 中显式声明 `trusted:` 的条目，且 brew/cask 条目只认完整名称，短名称不会被信任。报告注明未实际执行，表述恰当 |

## P2 及其他抽查

- **A08、A09、A12** 与代码一致。补充：`backup-configs.sh` 开启了 `set -euo pipefail`，A05、A08 的失败会使整个脚本当场退出，末尾 `:605` 的失败汇总不会输出，影响比报告描述更大。
- **A13** 结论正确，但“首次加载仍不生效”偏轻。镜像变量在 `zshrc` 第 33 行读取，`.zshrc.local` 在第 112 行才加载，因此每个新开终端都不生效，只有从已设置该变量的 shell 启动的子 shell 才生效。代理变量在 `proxy_on` 函数调用时才读取，不受影响。
- **数量统计**：core 3 tap / 30 formula / 9 cask，full 5 tap / 61 formula / 61 cask，跟踪文件 73 个，均与报告一致。
- **其他小项**属实：Ghostty 配置注释写“+15%”而实际值为 `2`；`package-managers.md:59` 仍含 `--describe`；`logging.sh:21` 使用 `mktemp -u`；`zshrc` 定义 `grep=rg`、`find=fd` 别名；SDKMAN 安装脚本使用固定 `/tmp` 路径。

## 未复核范围

以下内容未重新验证，采信前需自行判断：

- A06 中短名称 cask 在干净机器上加载失败的实际报错。
- A14 的版本事实（Python 3.12.16、Node 25 起不再随包分发 Corepack）。
- formulae.brew.sh 上的元数据（如 `codex-app` 已弃用）。
- 报告中描述的各组隔离复现。

## 建议

- 将 A13 中的“首次加载”改为“新开终端均”。
- 同意报告的实施顺序，A01 最优先：给预演命令的标准输入接 `/dev/null`，一行即可消除误删风险。

## 修复复核（2026-10-27）

复核对象：[audit-fixes-2026-10-27.md](audit-fixes-2026-10-27.md) 描述的工作区改动。

**结论：A01–A14 修复基本到位。** 27 项隔离测试和 doctor 均通过；`brew trust --json=v1`、`brew bundle check --no-upgrade`、`brew bundle list --all` 均在 Homebrew 7.0.11 上存在；修复后的 `--cleanup-preview` 在本机实测无确认、无删除、返回非零。

复核发现并已修复的问题：

| 级别 | 问题 | 处理 |
|------|------|------|
| 中 | 清单改用短名称后，本机已从第三方 tap 安装的 `oven-sh/bun/bun`、`anomalyco/tap/opencode` 仍能通过 `brew bundle check`；强制清理会按清单清空信任并尝试 untap，可能留下无法加载的已安装包 | `--cleanup-force` 在保存信任快照前检测这类包，拒绝执行并输出迁移命令；新增回归测试；本机实测检测出这两个包 |
| 低 | `install_java` 导出的 `sdkman_auto_answer=true` 会被 `sdk` 每次调用时重读的用户配置覆盖（`sdkman-main.sh:87-88`），已有其他 Java 时仍会询问是否设为默认 | `sdk install` 改为断开标准输入，按默认答案执行；新增回归测试；更正修复记录表述 |

| 低 | `~/.config` 等父目录为符号链接时，bootstrap 在安装软件前即整体退出，使用 dotfiles 管理工具的用户无法运行 quickstart | 改为只跳过受影响的配置并在结尾汇总，不写穿链接；父路径为悬空链接或普通文件时仍在写入前拒绝；新增两项测试 |
| 低 | 原子替换采用仓库文件的权限，原配置的自定义权限（如 600）会被放宽 | `write_file_atomically` 替换已有普通文件时沿用原权限；新增测试 |

修复后验证：系统 Bash 3.2 下 31 项测试全部通过，doctor 返回 0。本机未安装 Homebrew Bash 和 ShellCheck，未执行这两项；“首批 19 项测试修复前均失败”未回退复核。

## Codex 追加复核的处理（2026-10-27）

复核对象：[audit-2026-10-27-claude-followup-review.md](audit-2026-10-27-claude-followup-review.md)。三项发现均属实，已修复：

| 级别 | 问题 | 处理 |
|------|------|------|
| P2 | 第三方 formula 检测用 `grep -E` 匹配固定文本格式，漏判缩进、单引号、含 `+` 的名称，误判含 `.` 的名称 | 改为 `brew ruby scripts/lib/find-shadowed-packages.rb`：由 Bundle 解析清单，按类型和名称字面比较；清单保留第三方包时还须有对应信任，完整名称本身不构成授权 |
| P2 | 未检查第三方同名 cask | 同一脚本读取 `Cask::Caskroom.casks` 的完整名称。`brew list --cask --full-name` 不显示第三方来源，不能用于此判断。本机实测 full 清单命中 `farion1231/ccswitch/cc-switch`，官方 `homebrew/cask/cc-switch` 存在 |
| P3 | 迁移命令未转义 Brewfile 路径 | 参数按需单引号转义后输出；未用 `printf %q`，因为 Bash 3.2 会把中文路径转成 `$'\345...'` 形式，难以阅读 |

最初新增或改写测试覆盖空格和中文路径、来源核对失败及真实 Bundle 解析，三个快照相关测试的桩命令由 `list` 改为 `ruby`。该版本记录为系统 Bash 下 33 项通过，并曾对本机清单做只读核验。

本轮进一步补齐隔离测试至 39 项，移除了依赖本机安装状态、没有冲突样本的真实 Homebrew 用例。检测脚本在临时 HOME 下结合 Homebrew 接口桩实际执行，覆盖名称和语法、cask、显式信任、错误来源、类型隔离及失败路径；迁移命令还经过 Bash 和 zsh 执行到命令桩验证。恢复旧正则、移除 cask 枚举或删除路径转义，均能使对应测试失败。

最终验证：39 项全部通过；临时 HOME、brew 桩及 `CHECK_BREW_READABLE=0` 下 doctor 返回 0；临时 ShellCheck 0.11.0、空 HOME 演练和幂等演练通过。真实 Bundle 解析与信任接口另以临时 HOME 和安装状态桩验证 5 个场景。Homebrew Bash 未安装，Gitleaks、Ghostty 和云端 CI 本轮未执行。所有修改保留在工作区，未提交。

## Codex 第二轮修改的复核（2026-10-27）

Codex 将检测依据改为“清单保留的已安装第三方包，清单没有为其来源保留信任”，比原先的短名称遮蔽判断更贴近清理时的信任重置效果，结论为可以保留。用真实 Homebrew 7.0.11 只读验证 9 个场景：短名称或完整名称无信任、授权错误 tap 均命中；tap 授权、按包授权、带远端的 tap 授权、完整名称加 `trusted: true`、cask 完整名称授权及 cask 短名称加 tap 授权均放行。

另处理两项建议：

| 问题 | 处理 |
|------|------|
| 测试只用接口桩，发现不了 Homebrew 内部接口变化 | 新增只读的 `test_finder_against_real_homebrew_api`，有 Homebrew 时运行；在临时副本中让信任判断恒为放行后，该测试失败 |
| doctor、CI、测试依赖系统 Ruby 2.6，与 `brew ruby` 实际使用的 portable Ruby（本机 4.0.9）版本不一致 | doctor、CI 改用 `brew ruby -- -c`，doctor 在缺少 brew 时退回系统 `ruby`，都没有则跳过；测试优先使用 portable Ruby，可用 `TEST_RUBY` 覆盖 |

验证：系统 Bash 3.2 下 40 项测试全部通过；`TEST_RUBY=/usr/bin/ruby` 下同样通过；doctor 返回 0。
