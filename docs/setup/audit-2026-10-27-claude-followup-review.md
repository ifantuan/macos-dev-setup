# Claude 追加修复复核报告

> 复核日期：2026-10-27。复核者：Codex。仓库：`/Users/wuu/Github/macos-dev-setup`。基线提交：`9b373dbe150bf9e244d2f6a47cb91bff7fb9689e`。复核对象为当时尚未提交的工作区，以下行号以复核时文件为准。

**结论：Claude 的追加修改可以部分保留；SDKMAN、链接父目录跳过和权限保留已通过复核，第三方包检查需修复下面 2 项 P2 和 1 项 P3，不能整批直接通过。**

后续状态：以下复核结论和行号作为修复前证据保留；三项问题已按用户要求修复并补齐验证，处理结果见文末“复核后修复结果”。

## 复核范围

仅复核 [审计报告复核](audit-2026-10-27-review.md)末尾“修复复核”记录的 Claude 追加修改，不重新审计 Codex 此前完成的 A01–A14 修复。此前修复背景见 [审计问题修复记录](audit-fixes-2026-10-27.md)。

本轮覆盖第三方同名包检测、SDKMAN 标准输入处理、链接父目录跳过、原子替换权限保留、对应测试及文档。运行环境为 macOS 15.7.7、arm64、系统 Bash 3.2.57、Homebrew 7.0.11、SDKMAN 5.20.0；本机 Homebrew 提交为 `c6069d2a943b71b0a90d91fc1ac93cb9c1634dcc`。

## 问题列表

### P2 第三方 formula 检测依赖正则和固定文本格式

位置：[`scripts/brew-maintenance.sh:144`](../../scripts/brew-maintenance.sh)。

当前代码将包名直接插入扩展正则，并要求行首为 `brew`、名称使用双引号：

```bash
grep -Eq "^brew \"${full_name##*/}\"" "$BREWFILE"
```

临时仓库、临时 HOME 与 brew 桩验证结果如下。表中的“进入清理”仅指到达命令桩，没有真实清理行为。

| 场景 | 实际结果 |
|------|----------|
| 已安装第三方 `bun`，清单为 `brew "bun"` | 正确拒绝，仅调用枚举桩 |
| 双引号声明后带 `args:` 选项 | 正确拒绝 |
| 已安装第三方 `libsigc++`，清单声明同名包 | 漏判，进入清理桩 |
| `brew "bun"` 前有缩进 | 漏判，进入清理桩 |
| 清单使用 `brew 'bun'` | 漏判，进入清理桩 |
| 第三方包名为 `foo.bar`，清单声明 `fooxbar` | 误判为同名，错误拒绝 |

漏判会绕过本次新增的来源保护；误判会阻断正常操作并给出不对应清单的迁移建议。

建议使用 Homebrew Bundle 解析后的条目，并进行字面全行比较。例如，本机 Homebrew 7 的 `bundle/subcommand/list.rb:25` 确认支持 `brew bundle list --formula`。仅转义包名中的正则元字符仍不能处理缩进、单引号、条件声明等合法 Ruby 写法。应将上述场景补充为回归测试。

### P2 第三方同名 cask 未被检查

位置：[`scripts/brew-maintenance.sh:137`](../../scripts/brew-maintenance.sh)。

新增逻辑只执行 `brew list --formula --full-name`，没有核验 cask 来源。清单为 `cask "firefox"`、已安装来源为 `fake/tap/firefox` 的隔离桩场景通过检查，随后到达信任快照和清理桩。

本机 Homebrew 7.0.11 源码说明 cask 存在同类来源问题：

- `bundle/cask.rb:163-164` 用 `casks.map(&:to_s)` 表示已安装 cask，`cask/cask.rb:563` 的 `to_s` 返回短 token。
- `bundle/subcommand/cleanup.rb:264`、`:317` 按短 token 保留清单中的 cask。
- 同文件 `:158` 重置全局信任；`:372-378` 根据清单来源计算待移除 tap，短名称没有保留相应第三方 tap。
- `trust.rb:243-252` 会阻止加载未获信任的第三方 cask 定义。

结果是第三方 cask 可能继续被视为已安装，同时失去第三方信任或来源，影响后续维护。不能据此断言现有应用立即无法运行：`cask/caskroom.rb:255-259` 存在安装元数据回退路径。

建议补查已安装 cask 的来源，并核对清单解析后的完整名称和信任声明。单用 `bundle list --cask` 不足以保留这些信息，因为 DSL 会将完整来源存入 `options[:full_name]`，而条目名称变为短 token。应同时补充 cask 回归测试，并修正相关文档对“第三方同名包均会拦截”的宽泛描述。

上游依据：[Homebrew 7.0.11 清理源码](https://github.com/Homebrew/brew/blob/7.0.11/Library/Homebrew/bundle/subcommand/cleanup.rb)、[Bundle cask 源码](https://github.com/Homebrew/brew/blob/7.0.11/Library/Homebrew/bundle/cask.rb)。

### P3 输出的迁移命令没有转义 Brewfile 路径

位置：[`scripts/brew-maintenance.sh:152`](../../scripts/brew-maintenance.sh)。

当前输出将 `$BREWFILE` 直接拼接为命令文本。临时仓库路径包含 `brew migration dp_xn_ja` 时，输出中的 `--file` 路径被 Shell 拆为多个参数，无法直接复制执行。此项通过命令切词验证，没有执行真实安装。

建议使用 `printf '%q'` 分别输出各参数，并补充包含空格的仓库路径测试。使用 Shell 参数转义也能正确处理路径中的其他特殊字符。

## 已核验的其他行为

### Homebrew 迁移来源与检查顺序

已核验、无问题。在第三方版本成功卸载、官方同名包存在的前提下，保留第三方 tap 不会使其优先于 core。

本机 `formulary.rb:1239-1247` 的加载顺序将 API 加载器置于第三方名称搜索之前；`:932-948` 识别官方 API 条目；禁用 API 时，`:808-822` 也先检查本地 core，再于 `:825-828` 搜索第三方 tap。`bundle/brew.rb:735` 将包名传给实际安装入口。只读 `brew info` 已确认 `homebrew/core/bun` 和 `homebrew/core/opencode` 存在。

仍然安装第三方版本时，短名称 `brew info` 返回第三方来源属于已安装版本解析行为，不能据此推断卸载后的安装来源。上游依据：[Homebrew 7.0.11 名称解析源码](https://github.com/Homebrew/brew/blob/7.0.11/Library/Homebrew/formulary.rb)。

检查位于 `--acknowledge-trust-reset` 校验之后、交互确认之前合理。此时仅执行只读枚举，没有创建信任快照或执行删除。

### SDKMAN 标准输入与颜色

已核验、无问题。本机 `~/.sdkman/src/sdkman-install.sh:41` 的 `read USE` 在 EOF 后将变量置空，`:44-49` 将空值解释为设为默认。当前 `|| return` 和阶段条件调用链不会因该 `read` 返回非零而提前退出。

隔离源码函数与依赖桩验证了三个场景：新装遇到 EOF 后选择默认并返回 0；已安装版本直接返回 0、没有询问；模拟安装失败返回 1、不进入默认版本确认。源码中的网络、离线和校验失败路径没有额外终端读取，通用命令入口没有自动更新询问；另一处交互读取属于 `sdk upgrade` 路径。

删除 `sdkman_colour_enable=false` 后遵循用户配置，可能产生 ANSI 颜色输出，但不改变安装语义。正常配置原本也会在每次 `sdk` 调用时重读并覆盖导出的变量。

### 链接父目录与下游状态

已核验、无问题。系统 Bash 3.2 下，HOME 分别包含空格、竖线和通配符字符的测试均正确跳过两项配置。成员判断中被引号包围的目标按字面匹配；对当前四个固定目标，没有复现分隔符误判。

`validate_target "$target" || status=$?` 正确接收返回值 2，不被 `set -e` 中断。预演没有写入；实际运行保留外部目录不变，并正常安装其他配置。悬空链接和普通文件父路径仍在配置写入前被拒绝。

跳过后返回 0 符合此次有意调整的语义，且脚本明确输出跳过数量。需要准确理解下游结果：doctor 验证仓库，不验证用户配置全部落位。隔离场景中，外部 `.config` 为空、Ghostty 用户配置仍不存在时，quickstart 和 doctor 都可以返回 0；不能将该状态用作“全部配置已安装”的证据。

### 文件权限与写回仓库

已核验、无问题。`stat -f %Lp` 符合本仓库的 macOS 专用支持范围；CI 使用 `macos-latest`，没有承诺 Linux 支持而遗漏 GNU stat 兼容的问题。

| 隔离验证场景 | 最终权限 |
|--------------|----------|
| 已有目标 600，来源 644，原子替换 | 600 |
| 新建复制文件，来源 644 | 644 |
| 新建导出 Brewfile | 600 |
| 已有 Brewfile 644，再导出 | 644 |
| sync-back 来源 `.zshrc` 为 600，已有仓库目标为 644 | 644 |
| backup-configs 备份 SSH 配置，来源 600，已有仓库模板 644 | 644 |

新导出 Brewfile 的 600 来自 `mktemp`；本机 Homebrew `bundle/dumper.rb:92-93` 使用 `open("w")` 覆盖临时文件，不改变权限。这是新增 `keep_file_mode` 之前已经存在的行为。

备份和反向同步沿用已有仓库目标权限，与修复记录的描述一致。这不等于保留来源文件权限；若以后要求备份结果不得比来源宽松，应由调用方明确选择权限策略。

## 测试质量与文档核验

源码共有 31 个测试方法；本次新增四项、改写一项，从 27 项增加到 31 项的计数正确。系统 Bash 下 31 项测试和 doctor 返回 0 的结论已独立重现。

逐项回退全部在临时仓库副本中进行，每次只改变对应逻辑，并在验证后恢复：

| 测试 | 临时回退或变异 | 结果 |
|------|----------------|------|
| `test_cleanup_blocks_third_party_formula_shadowing_manifest` | 删除新增第三方检测 | 失败 |
| `test_sdkman_install_cannot_read_terminal_input` | 恢复环境变量导出，移除安装命令输入重定向 | 失败 |
| `test_parent_symlink_is_skipped_without_writing_through` | 恢复链接父目录整体拒绝行为 | 失败 |
| `test_replaced_config_keeps_restricted_mode` | 删除权限保留调用和辅助函数 | 失败 |
| `test_broken_parent_is_rejected_before_writes` | 撤回 Claude 的链接父目录跳过修改 | 仍通过 |
| 同上 | 额外移除原有失效父路径保护 | 悬空链接、普通文件两个子场景均失败 |
| `test_acknowledged_cleanup_saves_trust_before_removal` | 将清理调用提前到快照之前 | 失败 |
| `test_failed_or_invalid_trust_snapshot_blocks_cleanup` | 移除 JSON 校验 | 失败 |
| 上述五项新增或改写测试 | 恢复全部临时修改后重跑 | 5 项全部通过 |

失效父路径测试保护的是此前已有行为，不能算作“证明 Claude 修复前失败”的测试。两个旧快照测试新增 `list` 桩分支只是适配新的只读枚举；上述变异验证表明原有关键断言仍有效。

相关文档对 SDKMAN、父链接跳过和目标权限保留的描述基本一致；第三方包保护范围需要随 P2 修正。此前“首批 19 项测试修复前均失败”的历史结论不在本轮范围，未重新回退验证。此前 ShellCheck 和 Gitleaks 的执行记录与本轮验证应分别理解，不能把历史执行自动视为 Claude 追加后重新执行。

## 实际执行与未执行项目

以下为本轮复核实际执行的主要检查，而非保存本文时再次执行：

| 命令或检查 | 结果 |
|------------|------|
| `make test` | 系统 Bash 3.2，31 项全部通过，退出 0 |
| `./scripts/doctor.sh` | 退出 0，包含四份 Brewfile 的读取检查 |
| `./scripts/drill-clean-home.sh` | 退出 0 |
| `./scripts/drill-idempotency.sh` | 退出 0 |
| 临时 ShellCheck 0.11.0 检查 `scripts/*.sh scripts/lib/*.sh configs/runtimes/versions.sh` | 退出 0 |
| `brew info --json=v2 --formula bun opencode` | 只读检查当前安装来源 |
| `brew info --json=v2 --formula homebrew/core/bun homebrew/core/opencode` | 只读确认官方条目存在 |
| 读取本机 Homebrew 与 SDKMAN 源码，核对官方 Homebrew 7.0.11 源码 | 完成 |
| 临时 HOME、brew 桩、SDKMAN 源码函数桩、路径边界和逐项回退 | 完成，结果如上 |
| `git diff --stat`、完整 diff、暂存区、git status 和文件 SHA-256 比较 | 复核结束时均与开始时一致 |

ShellCheck 使用此前保留的临时工具，没有安装到系统目录，实际调用为：

```bash
/var/folders/2l/6lbfp_qx6q3b5h73_rq3_9vc0000gn/T/macos-dev-setup-validation-p71mcw2r/shellcheck scripts/*.sh scripts/lib/*.sh configs/runtimes/versions.sh
```

未执行项目及原因：

- Homebrew Bash 未安装，未执行 `TEST_BASH=...` 第二套回归测试。
- 本轮未重新运行 Gitleaks；普通 doctor 因 PATH 中没有该工具而跳过此项。
- doctor 的 Ghostty 校验因缺少声明字体而跳过。
- 未重做原 A01–A14 审计、首批 19 项历史回退验证或云端 CI。
- 按任务约束，没有执行真实 `brew bundle cleanup --force`、真实维护脚本强制清理、`brew uninstall`、`brew untap`、`brew trust` 或 `sdk install`；所有涉及这些分支的验证均使用临时副本、临时 HOME 和命令桩。

复核阶段未修改仓库或用户配置。结束时 `git diff --stat` 仍为 36 个文件、472 行新增、224 行删除；另对跟踪文件及非忽略的未跟踪文件逐项比较 SHA-256，确认内容未变。随后按用户要求保存本报告，并补充目录索引；这两项文档写入不属于上述复核阶段的一致性比较。

## 复核后修复结果

2026-10-27 按用户要求修复上述三项问题，暂不提交。保留已有工作区修改，在现有 Ruby 检测版本基础上补齐信任核对及隔离验证。

| 发现 | 最终处理 | 验证 |
|------|----------|------|
| P2 正则与清单格式 | 使用 Homebrew Bundle 解析条目，按名称及类型做字面比较，不再扫描原始文本 | 特殊名称、缩进、单双引号、选项、条件、注释及误匹配场景；恢复旧正则后测试失败 |
| P2 遗漏 cask | 枚举实际 cask 完整来源，按 Bundle 的短 token 保留语义检查，并核对清单重置后保留的信任 | 短名、未授权完整名、错误来源、错误包类型均拦截；正确按包、按 tap 授权放行；移除 cask 枚举后测试失败 |
| P3 路径未转义 | 保留按需单引号转义，分别输出 formula、cask 卸载及重装提示 | 在 Bash 和 zsh 中执行到 brew 桩，参数保持一致，路径中的命令替换不执行；删除转义后测试失败 |

信任核对使用 `Homebrew::Bundle::Trust.entries` 和 `Homebrew::Trust.target` 的只读接口，不直接读取判断或改写实际信任状态。仅声明完整名称仍不足以保留信任；解析或来源读取失败时，在交互确认、快照和清理之前停止。

测试不再读取真实本机安装状态。39 项回归使用临时 HOME、临时仓库和命令桩，来源检测用例执行真实仓库 Ruby 脚本；Homebrew 的外部接口由 fixture 提供。额外用真实 Bundle 解析器与信任规范化接口验证了 5 个场景，仍使用临时 HOME 和安装状态桩。

本轮结果：`make test` 的 39 项通过；临时 HOME 和 brew 桩下的 doctor、空 HOME 演练、幂等演练均退出 0；ShellCheck 0.11.0 通过。Ruby 语法检查已加入 doctor 和 CI。Homebrew Bash 未安装，Gitleaks、Ghostty 和云端 CI 本轮未执行。未执行真实安装、卸载、清理或信任变更，未修改用户配置，未创建提交。
