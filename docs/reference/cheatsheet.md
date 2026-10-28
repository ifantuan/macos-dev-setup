# 常用命令与快捷键速查

本页用于日常快速查阅。更完整的解释见对应专题手册。

## 仓库入口

| 命令 | 用途 |
|------|------|
| `make quickstart` | 核心安装、运行时初始化、自检 |
| `make dry-run` | 预演快速启动路径 |
| `make doctor` | 运行仓库自检 |
| `make core` | 安装核心 Homebrew 清单和配置 |
| `make full` | 安装完整 Homebrew 清单和配置 |
| `make defaults` | 应用 Finder、Dock、键盘、截图等系统默认设置 |
| `make audit` | 检查本机环境并输出和仓库的差异 |
| `make drill` | 运行半恢复演练检查 |
| `make drill-clean` | 使用临时 HOME 运行半恢复演练 |
| `make drill-idempotency` | 验证 bootstrap 可重复执行 |
| `make record-drill` | 生成恢复演练报告 |
| `make brew-check` | 检查完整 Homebrew 清单 |
| `make brew-install` | 按完整清单安装，默认不升级 |
| `make brew-cleanup-preview` | 预演清理清单外依赖 |
| `make sync-back` | 同步本机配置回仓库 |
| `./scripts/bootstrap.sh --profile core` | 核心软件和配置 |
| `./scripts/bootstrap.sh --profile full` | 完整软件和配置 |
| `./scripts/apply-macos-defaults.sh --dry-run` | 预演 macOS defaults 写入 |
| `./scripts/apply-macos-defaults.sh --restart-apps` | 写入系统默认设置并重启相关系统进程 |
| `./scripts/audit-environment.sh --profile core` | 只审计核心清单和配置差异 |
| `./scripts/audit-environment.sh --no-diff` | 只输出差异摘要，不展开配置文件 diff |
| `./scripts/install-runtimes.sh` | 初始化 Java / Python / Node.js |
| `./scripts/sync-back.sh --dry-run` | 预演配置同步回仓库 |
| `./scripts/sync-back.sh --include-brew` | 同步配置并刷新完整 Brewfile |
| `./scripts/doctor.sh` | 检查脚本、Markdown、Brewfile、配置 |

## Homebrew

| 命令 | 用途 |
|------|------|
| `brew bundle --file Brewfile.core --verbose --no-upgrade` | 安装核心清单 |
| `brew bundle --file Brewfile --verbose --no-upgrade` | 安装完整清单 |
| `./scripts/brew-maintenance.sh --profile full --install --upgrade` | 明确升级完整清单 |
| `brew bundle check --file Brewfile.core --no-upgrade` | 检查核心清单缺失项 |
| `./scripts/brew-maintenance.sh --profile full --cleanup-preview` | 只预演，非零退出码需阅读诊断 |
| `./scripts/brew-maintenance.sh --profile full --cleanup-force --acknowledge-trust-reset` | 二次确认后清理清单外依赖 |
| `brew update && brew upgrade` | 更新软件 |
| `brew cleanup` | 清理旧版本缓存 |
| `brew doctor` | 检查 Homebrew 环境 |

## Shell 与终端

| 命令 / 快捷键 | 用途 |
|---------------|------|
| `proxy_on` | 开启本地代理环境变量 |
| `proxy_off` | 关闭代理环境变量 |
| `proxy_status` | 查看代理环境变量 |
| `ll` | 详细列表，带 Git 状态和图标 |
| `la` | 显示隐藏文件 |
| `z <keyword>` | 跳转常用目录 |
| `Ctrl-r` | fzf 搜索历史命令 |
| `Ctrl-t` | fzf 搜索文件并插入命令行 |
| `source ~/.zshrc` | 重载 Shell 配置 |

## tmux

默认前缀键是 `Ctrl-b`。

| 快捷键 | 用途 |
|--------|------|
| `Ctrl-b c` | 新建窗口 |
| `Ctrl-b n` | 下一个窗口 |
| `Ctrl-b p` | 上一个窗口 |
| `Ctrl-b %` | 左右分屏 |
| `Ctrl-b "` | 上下分屏 |
| `Ctrl-b o` | 切换面板 |
| `Ctrl-b x` | 关闭面板 |
| `Ctrl-b [` | 进入复制模式 |
| `tmux new -s <name>` | 新建会话 |
| `tmux attach -t <name>` | 进入会话 |
| `tmux ls` | 查看会话 |

## Ghostty

| 快捷键 | 用途 |
|--------|------|
| `Command-t` | 新建标签 |
| `Command-w` | 关闭当前标签或窗口 |
| `Command-d` | 左右分屏 |
| `Command-Shift-d` | 上下分屏 |
| `Command-Shift-←` / `Command-Shift-→` | 切换标签页 |
| `Command-Option-方向键` | 切换分屏焦点 |
| `Command-+` / `Command--` | 调整字号 |
| `Command-0` | 恢复字号 |
| `Shift-Enter` | 插入字面换行，适合 Codex / Claude Code 多行输入 |

以实际 [terminal/ghostty.md](../terminal/ghostty.md) 和 [configs/ghostty/config](../../configs/ghostty/config) 为准。

## Java

| 命令 | 用途 |
|------|------|
| `sdk list java` | 查看可安装 JDK |
| `sdk install java 8.0.492-zulu` | 安装 Zulu JDK 8 |
| `sdk default java 8.0.492-zulu` | 设置默认 JDK 8 |
| `sdk install maven` | 安装 Maven |
| `java -version` | 查看 Java 版本 |
| `mvn -v` | 查看 Maven 环境 |
| `mvn test` | 运行 Maven 测试 |

## Python

| 命令 | 用途 |
|------|------|
| `pyenv install 3.12.16` | 安装推荐 Python |
| `pyenv global 3.12.16` | 设置全局 Python |
| `pyenv local 3.12.16` | 项目固定 Python 版本 |
| `uv venv` | 创建虚拟环境 |
| `source .venv/bin/activate` | 激活虚拟环境 |
| `uv pip install -r requirements.txt` | 安装依赖 |
| `uv python install 3.12.16 --default` | 按需快速安装预编译 Python |
| `uv python list --only-installed` | 查看 uv 安装的 Python |
| `pipx install <tool>` | 安装全局 Python CLI |

## 前端

| 命令 | 用途 |
|------|------|
| `fnm install --lts` | 安装 Node LTS |
| `fnm default lts-latest` | 设置默认 Node |
| `node -v` | 查看 Node 版本 |
| `brew install pnpm` | 安装 Homebrew 管理的 pnpm |
| `pnpm --version` | 验证 pnpm 版本 |
| `pnpm install` | 安装依赖 |
| `pnpm dev` | 启动开发服务 |
| `pnpm test` | 运行测试 |
| `bun install` | Bun 安装依赖 |
| `bun run <script>` | Bun 运行脚本 |

## Docker / OrbStack

| 命令 | 用途 |
|------|------|
| `orb --version` | 查看 OrbStack 版本 |
| `docker version` | 查看 Docker 运行时 |
| `docker compose version` | 查看 Compose |
| `docker compose up -d` | 后台启动服务 |
| `docker compose ps` | 查看服务状态 |
| `docker compose logs -f` | 查看日志 |
| `docker compose down` | 停止服务 |
| `docker compose down -v` | 停止并删除数据卷 |
| `docker system prune` | 清理无用资源 |

## Codex

| 命令 | 用途 |
|------|------|
| `codex` | 启动交互式 TUI |
| `codex "<任务>"` | 带初始 prompt 启动交互式会话 |
| `codex --no-alt-screen` | 保留终端滚动历史 |
| `codex exec "<任务>"` | 非交互执行任务 |
| `codex exec --json "<任务>"` | 以 JSONL 输出非交互事件 |
| `codex exec --output-schema schema.json "<任务>"` | 按 JSON Schema 约束最终输出 |
| `codex exec resume --last "<任务>"` | 继续最近一次非交互会话 |
| `codex review --uncommitted` | 审查未提交改动 |
| `codex review --base main` | 审查相对指定分支的改动 |
| `codex resume` | 恢复历史会话 |
| `codex resume --last` | 直接恢复最近会话 |
| `codex resume --all` | 显示当前目录外的历史会话 |
| `codex fork --last` | 从最近会话分叉新会话 |
| `codex apply <task-id>` | 应用指定任务生成的 diff |
| `codex cloud exec "<任务>"` | 提交 Codex Cloud 任务 |
| `codex cloud list --json` | 以 JSON 输出最近 Cloud 任务 |
| `codex cloud diff <task-id>` | 查看 Cloud 任务 diff |
| `codex cloud apply <task-id>` | 应用 Cloud 任务 diff |
| `codex completion zsh` | 生成 zsh 补全脚本 |
| `codex features list` | 查看 feature flags |
| `codex login` / `codex logout` | 登录或移除 Codex 认证 |
| `codex login status` | 查看 Codex 登录状态 |
| `codex doctor` | 诊断 Codex 环境 |
| `codex mcp --help` | 查看 MCP 管理命令 |
| `codex plugin --help` | 查看插件管理命令 |
| `codex plugin marketplace list` | 查看已配置插件市场 |
| `codex app` | 启动 Codex 桌面 App |
| `codex update` | 更新 Codex CLI |
| `codex --search` | 启用 Web 搜索工具 |
| `codex -C <dir>` | 指定工作目录 |
| `codex --add-dir <dir>` | 授权额外目录可写 |
| `codex -m <model>` | 指定模型 |
| `codex -i <image>` | 附加图片输入 |
| `codex -s workspace-write` | 以工作区可写沙箱启动 |
| `codex -a on-request` | 允许按需请求审批 |
| `codex --enable <feature>` | 临时启用 feature flag |

| 交互操作 | 用途 |
|----------|------|
| `/` | 唤起 slash commands |
| `/permissions` | 调整当前会话权限 |
| `/model` / `/fast` | 切换模型或 Fast 模式 |
| `/plan` | 切换到计划模式 |
| `/goal` | 设置、查看、暂停或清除任务目标 |
| `/memories` | 控制当前线程是否使用或生成记忆 |
| `/skills` | 浏览和使用 skills |
| `/plugins` | 浏览和管理插件 |
| `/mcp` | 查看当前 MCP 工具 |
| `/mention` | 附加指定文件或目录到对话 |
| `/diff` | 查看 Git diff |
| `/review` | 请求审查当前工作区改动 |
| `/status` | 查看模型、权限、上下文和会话状态 |
| `/clear` / `/new` | 清空上下文并开始新对话 |
| `/compact` | 压缩长会话上下文 |
| `/fork` / `/resume` | 分叉或恢复会话 |
| `/side` / `/btw` | 发起不打断主线的临时问题 |
| `/raw` | 切换原始滚屏模式 |
| `/keymap` / `/theme` | 配置快捷键或主题 |
| `/init` | 生成 `AGENTS.md` 初始文件 |
| `@` | 在输入框中补全并插入工作区文件路径 |
| `$` | 提及并显式调用 skill |
| `Tab` | 任务运行中排队下一轮文本或 slash command |
| `Ctrl+R` | 搜索 prompt 历史 |
| `Ctrl+O` | 复制最近一次完成的 Codex 输出 |
| `Ctrl+L` | 只清屏，不开启新对话 |
| `Shift-Enter` | 本仓库 Ghostty 配置下插入字面换行 |
| `Ctrl+C` / `/exit` | 中断当前输出或退出 |
| `codex --help` | 查看当前版本支持的外层命令 |

## Claude Code

| 命令 | 用途 |
|------|------|
| `claude` | 启动交互式会话 |
| `claude "<任务>"` | 带初始 prompt 启动 |
| `claude -p "<任务>"` | 非交互输出后退出 |
| `cat file \| claude -p "<任务>"` | 处理管道输入内容 |
| `claude -c` | 继续当前目录最近会话 |
| `claude --continue` | `claude -c` 的长参数形式 |
| `claude -c -p "<任务>"` | 非交互继续最近会话 |
| `claude --resume` | 打开会话选择器 |
| `claude -r <session> "<任务>"` | 按 ID 或名称恢复会话 |
| `claude --from-pr <number>` | 恢复关联指定 PR 的会话 |
| `claude --continue --fork-session` | 从最近会话分叉新会话 |
| `claude -n <name>` | 为会话设置名称 |
| `claude -p --output-format json "<任务>"` | 非交互 JSON 输出 |
| `claude -p --output-format stream-json "<任务>"` | 非交互流式 JSON 输出 |
| `claude -p --input-format stream-json` | 使用流式 JSON 输入 |
| `claude -p --max-turns 3 "<任务>"` | 限制非交互 agent 轮次 |
| `claude -p --json-schema '{"type":"object"}' "<任务>"` | 约束最终 JSON 输出结构 |
| `claude --model sonnet` | 指定模型或模型别名 |
| `claude --effort high` | 指定当前会话推理强度 |
| `claude --fallback-model sonnet -p "<任务>"` | 非交互模式设置 fallback 模型 |
| `claude --add-dir <dir>` | 授权访问额外目录 |
| `claude --permission-mode plan` | 以指定权限模式启动 |
| `claude --ide` | 启动时自动连接可用 IDE |
| `claude --allowedTools "Bash(git *)" "Edit"` | 为匹配工具调用免确认 |
| `claude --disallowedTools "Bash(rm *)"` | 拒绝匹配的工具调用 |
| `claude --tools "Bash,Edit,Read"` | 限制可用内置工具集合 |
| `claude --mcp-config ./mcp.json` | 加载 MCP 配置 |
| `claude --strict-mcp-config --mcp-config ./mcp.json` | 只使用指定 MCP 配置 |
| `claude --settings ./settings.json` | 为本次会话加载设置覆盖 |
| `claude mcp` | 管理 MCP 服务器 |
| `claude plugin` | 管理 Claude Code 插件 |
| `claude --plugin-dir ./plugin` | 临时加载本地插件 |
| `claude agents --json` | 查看后台 agent 会话 |
| `claude -w <name> --tmux` | 在隔离 worktree 中启动并创建 tmux 会话 |
| `claude --bare -p "<任务>"` | 最小模式非交互执行 |
| `claude --debug` | 调试模式 |
| `claude --debug-file <path>` | 写入指定调试日志文件 |
| `claude auth status` | 查看认证状态 |
| `claude setup-token` | 生成用于 CI 或脚本的长效 token |
| `claude project purge --dry-run` | 预演清理项目本地状态 |
| `claude ultrareview <target> --json` | 云端多 agent 深度审查并输出 JSON |
| `claude update` | 更新 Claude Code |
| `claude install stable` | 安装或重装稳定版 native binary |

| 交互操作 | 用途 |
|----------|------|
| `/` | 唤起 command、skill、plugin 和 MCP prompt 菜单 |
| `/init` | 生成项目 `CLAUDE.md` |
| `/memory` | 编辑 `CLAUDE.md`、控制 auto-memory、查看记忆 |
| `/mcp` | 查看或配置 MCP |
| `/permissions` | 管理 allow、ask、deny 权限规则 |
| `/plan` | 进入计划模式 |
| `/model` / `/effort` | 调整模型或推理强度 |
| `/config` | 打开设置界面 |
| `/context` / `/compact` | 查看上下文占用或压缩会话 |
| `/btw <问题>` | 提出不进入主历史的临时问题 |
| `/skills` | 查看可用 skills |
| `/agents` / `/tasks` | 管理 subagents 或后台任务 |
| `/background` | 将当前会话转入后台运行 |
| `/diff` | 查看当前 diff 和每轮改动 |
| `/code-review` / `/review` | 本地或深度代码审查 |
| `/security-review` | 审查当前分支待提交安全风险 |
| `/clear` | 开启新对话，保留上一会话可恢复 |
| `/resume` / `/branch` | 恢复或分叉会话 |
| `/rewind` | 回滚对话或代码到检查点 |
| `/doctor` / `/debug` | 诊断安装、配置或运行问题 |
| `/usage` / `/status` | 查看用量、版本、模型、账号和连接状态 |
| `/copy` | 复制最近一次 assistant 响应 |
| `/terminal-setup` | 配置终端快捷键 |
| `!` 开头输入 | 直接运行 shell 命令并加入上下文 |
| `@` | 唤起文件路径补全 |
| `Shift+Enter` | Ghostty 原生插入换行 |
| `Option+Enter` / `Ctrl+J` | 官方多行输入备选方式 |
| `\` + `Enter` | 所有终端可用的多行输入方式 |
| `Ctrl+C` | 中断运行；空闲时先清空输入，再按一次退出 |
| `Ctrl+D` | 退出 Claude Code |
| `Ctrl+R` | 反向搜索命令历史 |
| `Ctrl+B` | 将运行中的任务放到后台 |
| `Ctrl+T` | 显示或隐藏任务列表 |
| `Ctrl+O` | 打开 transcript viewer |
| `Shift+Tab` | 切换权限模式 |

## IDE

| 工具 | 常用快捷键 |
|------|------------|
| VS Code / Cursor | `Command-P` 打开文件，`Command-Shift-P` 命令面板，`Command-B` 侧栏，`Control-\`` 终端 |
| JetBrains | `Shift Shift` 全局搜索，`Command-E` 最近文件，`Command-B` 跳转声明，`Option-Enter` 快速修复 |
| Zed | `Command-P` 打开文件，`Command-Shift-P` 命令面板，`Command-\`` 终端面板 |

不同编辑器 keymap 可同步到账号，仓库只记录推荐习惯，不保存登录态和 token。
