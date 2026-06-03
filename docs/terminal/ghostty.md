# Ghostty 配置与操作手册

> 适用平台：macOS（Apple Silicon / Intel 通用）
> 配套配置：`~/.config/ghostty/config`
> 集成范围：Zsh · tmux · Zoxide · Yazi · fzf · Starship
> 更新日期：2026-06-01

---

## 官方资料

| 内容 | 链接 |
|------|------|
| Ghostty 文档 | <https://ghostty.org/docs> |
| 配置参考 | <https://ghostty.org/docs/config/reference> |
| Keybind 参考 | <https://ghostty.org/docs/config/keybind/reference> |
| 安装说明 | <https://ghostty.org/docs/install/binary> |

## 目录

1. [Ghostty 配置详解](#1-ghostty-配置详解)
2. [Ghostty 操作速查](#2-ghostty-操作速查)
3. [Zsh 配置与插件](#3-zsh-配置与插件)
4. [tmux 集成](#4-tmux-集成)
5. [Zoxide：智能目录跳转](#5-zoxide智能目录跳转)
6. [Yazi：终端文件管理器](#6-yazi终端文件管理器)
7. [fzf 与组合工作流](#7-fzf-与组合工作流)
8. [AI 代理工作流配方](#8-ai-代理工作流配方)
9. [故障排查](#9-故障排查)

---

## 1. Ghostty 配置详解

### 1.1 配置基本规则

- **路径**：`~/.config/ghostty/config`（由 `scripts/bootstrap.sh` 从 `configs/ghostty/config` 复制；macOS 也读取 `~/Library/Application Support/com.mitchellh.ghostty/config`，建议只用前者，二选一避免歧义）
- **重载**：运行时按 `Cmd + Shift + ,`；少数项需重启（如 `background-opacity`、`macos-titlebar-style` 的某些变更）
- **语法**：`key = value`，`#` 注释，部分键可重复（如 `font-family`、`keybind`）

**铁律**：不要把 `ghostty +show-config --default` 整段抄进去——很多默认值之间互斥，显式写出反而冲突。**只写偏离默认的项**。

### 1.2 查询命令速查

| 命令 | 用途 |
|------|------|
| `ghostty +show-config --default --docs` | 查看所有选项含义 |
| `ghostty +list-themes` | 列出所有内置主题 |
| `ghostty +list-keybinds --default` | 列出默认键位 |
| `ghostty +list-fonts` | 列出系统识别的字体名（用这里的名字写配置） |
| `ghostty +show-config` | 输出你当前合并后的有效配置 |
| `ghostty +validate-config` | 检查配置语法错误 |

### 1.3 字体

```ini
font-family = "Maple Mono NF CN"
font-size = 14
adjust-cell-height = 2
```

- `font-family` 可重复写多行做回退（如再加一行 `font-family = "JetBrains Mono"`），缺字按顺序回退
- `adjust-cell-height` 既支持像素也支持百分比；百分比写法 `"15%"`，更稳——换字号比例自动跟上
- `font-thicken = true`（仅 macOS）：视网膜屏字体偏淡时再开；Maple Mono 默认就饱满，关掉更清晰
- 中英文混排断点：Ghostty 一律按 cell 渲染，中文字符默认占两格。Maple Mono NF CN 已处理好 NF 图标 + CJK，无需额外配置

### 1.4 主题（明暗自动切换）

```ini
theme = light:Kanagawa Lotus,dark:Kanagawa Wave
```

- 跟随系统外观自动切换
- 想要单一主题：`theme = Kanagawa Wave`
- 自定义主题：把同名 `.conf` 放到 `~/.config/ghostty/themes/`，再 `theme = my-theme` 引用

推荐组合（按场景）：

| 风格 | light | dark |
|------|-------|------|
| 和风内敛 | Kanagawa Lotus | Kanagawa Wave |
| 高对比 | GitHub Light | Tokyo Night |
| 暖色护眼 | Solarized Light | Solarized Dark |
| 现代极简 | Catppuccin Latte | Catppuccin Mocha |

### 1.5 窗口

```ini
window-padding-x = 14
window-padding-y = 10
window-padding-balance = true
macos-titlebar-style = transparent
window-width = 120
window-height = 36
window-save-state = always
```

- `macos-titlebar-style` 四个值：`transparent`（融入背景）/ `native`（原生 macOS）/ `tabs`（标签栏融入标题栏）/ `hidden`
- `window-save-state = always`：退出时记录位置、尺寸、标签页；下次启动还原
- `window-decoration = false` 可去掉窗口边框；想要"无边框沉浸"配合 `macos-titlebar-style = hidden`

### 1.6 关键 macOS 设置

```ini
macos-option-as-alt = left
```

**这一项极其重要**。默认 Option 用来输入特殊字符（如 `å`、`∆`），开启后左 Option 转为 Alt，tmux / Helix / Neovim 中的 `Alt+xxx` 键位才能生效。`right` 仍保留特殊字符输入，是一个折中。

其他可选：

```ini
macos-non-native-fullscreen = true    # 非原生全屏（无动画，更快）
macos-window-shadow = false           # 关掉窗口阴影（性能更好，多屏更利落）
```

### 1.7 Shell 集成

```ini
shell-integration-features = cursor,sudo,title,ssh-env,ssh-terminfo
```

子功能含义：

| 子功能 | 作用 |
|--------|------|
| `cursor` | 命令模式 / 编辑模式自动切换光标形状 |
| `sudo` | sudo 时保留 `TERMINFO` 环境变量（防止 sudo 后 `clear`、`tput` 等失效） |
| `title` | 标签标题自动改为"目录 — 命令"（区分多个跑 claude/codex 的标签时极有用） |
| `ssh-env` | SSH 时传递 `TERM_PROGRAM` 等终端环境变量到远端 |
| `ssh-terminfo` | SSH 时把 Ghostty 的 `terminfo` 自动安装到远端 |

注意：`shell-integration = detect` 是默认值（自动识别 zsh/bash/fish 并注入），不用显式写。

### 1.8 性能与回看

```ini
scrollback-limit = 25000000   # 25 MB，足够长 AI 代理输出
```

补充选项：

```ini
window-vsync = true             # 垂直同步，默认 true，省电
linux-cgroup = single-instance  # 仅 Linux，无视
```

### 1.9 下拉终端（Quake 风格）

```ini
quick-terminal-position = top
quick-terminal-screen = mouse
quick-terminal-animation-duration = 0.15
keybind = global:ctrl+`=toggle_quick_terminal
```

- `global:` 前缀让快捷键在 Ghostty 未聚焦时也生效
- 首次使用需到 **系统设置 → 隐私与安全性 → 辅助功能** 给 Ghostty 打钩
- 用于"随手抛一条命令"——查端口、跑 grep、瞄一眼 git status，不切换窗口

---

## 2. Ghostty 操作速查

### 2.1 标签页 / 分屏

| 操作 | 默认键位 | 你的自定义 |
|------|----------|-----------|
| 新窗口 | `Cmd + N` | — |
| 新标签 | `Cmd + T` | — |
| 关闭 surface | `Cmd + W` | — |
| 切下一个标签 | `Cmd + Shift + ]` | `Cmd + Shift + →` |
| 切上一个标签 | `Cmd + Shift + [` | `Cmd + Shift + ←` |
| 跳到第 N 个标签 | `Cmd + N`（数字） | — |
| 水平分屏 | `Cmd + D` | — |
| 垂直分屏 | `Cmd + Shift + D` | — |
| 跳到左/右/上/下分屏 | — | `Cmd + Opt + 方向键` |
| 关闭分屏 | `Cmd + W` | — |
| 切换分屏缩放 | `Cmd + Shift + Enter` | — |

### 2.2 字体大小

| 操作 | 键位 |
|------|------|
| 放大 | `Cmd + =` |
| 缩小 | `Cmd + -` |
| 重置 | `Cmd + 0` |

### 2.3 复制 / 粘贴 / 选择

| 操作 | 键位 |
|------|------|
| 复制 | `Cmd + C`（或选中即复制，已配置 `copy-on-select = clipboard`） |
| 粘贴 | `Cmd + V` |
| 粘贴防护对话框 | 包含换行/危险字符时自动弹出（默认开） |
| 全选当前屏 | `Cmd + A` |

### 2.4 输入字面换行（AI 代理用）

```ini
keybind = shift+enter=text:\n
```

在 Claude Code / Codex / Aider 这类 TUI 中，`Enter` 是"提交"，`Shift + Enter` 插入字面换行。**写多行 prompt 时不可或缺**。

### 2.5 其他常用 keybind 动作

想扩展时挑用：

```ini
keybind = cmd+shift+e=equalize_splits         # 均衡分屏大小
keybind = cmd+shift+f=toggle_split_zoom       # 当前分屏占满标签
keybind = cmd+shift+i=inspector:toggle        # 打开渲染检查器（调试用）
keybind = cmd+k=clear_screen                  # 清屏（默认就是这个，列出供参考）
keybind = cmd+ctrl+f=toggle_fullscreen        # 原生全屏切换
```

前缀修饰：
- `global:` 全局生效（仅 macOS，且需辅助功能权限）
- `all:` 所有 surface 都生效
- `unconsumed:` 触发后输入仍传给终端
- `performable:` 仅当动作真正可执行时消耗（如 `goto_split:up` 没有上分屏就不消耗）

---

## 3. Zsh 配置与插件

Ghostty 的 shell-integration 自动注入，你不用在 `~/.zshrc` 里写任何 Ghostty 相关代码。下面是一份精简但够用的 `~/.zshrc`。

### 3.1 推荐基础框架

不强求 Oh My Zsh——更轻量的做法是直接用 **zinit** 或干脆手动 source。这里给出 **zinit** 版（启动快、按需加载）：

```sh
## ~/.zshrc

## ---------- zinit 引导（首次自动安装） ----------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

## ---------- 历史 ----------
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt INC_APPEND_HISTORY      # 命令执行后立即写入
setopt SHARE_HISTORY           # 多窗口共享
setopt HIST_IGNORE_DUPS        # 连续重复不记
setopt HIST_IGNORE_SPACE       # 以空格开头不记（敲敏感命令时用）
setopt HIST_REDUCE_BLANKS

## ---------- 编辑模式 ----------
bindkey -e                     # emacs 风（zsh 默认就是这个；Ghostty cursor 集成只识别 emacs/vi）

## ---------- 补全 ----------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # 大小写不敏感

## ---------- 插件（按需加载） ----------
zinit light zsh-users/zsh-autosuggestions       # 灰色历史建议
zinit light zsh-users/zsh-syntax-highlighting   # 语法高亮（必须放在末尾附近）
zinit light Aloxaf/fzf-tab                      # 用 fzf 接管 Tab 补全
zinit light zsh-users/zsh-completions           # 补全集合

## ---------- 工具初始化 ----------
eval "$(starship init zsh)"                     # 提示符
eval "$(zoxide init zsh)"                       # 智能 cd
eval "$(fzf --zsh)"                             # fzf 键绑定（Ctrl+R, Ctrl+T, Alt+C）

## ---------- 别名 ----------
alias ls='eza --group-directories-first'
alias ll='eza -l --git --icons --group-directories-first'
alias la='eza -la --git --icons --group-directories-first'
alias tree='eza --tree --git-ignore'
alias cat='bat --paging=never'
alias grep='rg'
alias find='fd'
alias g='git'
alias lg='lazygit'
alias t='tmux'
alias ta='tmux attach -t'
alias tl='tmux ls'

## ---------- 环境 ----------
export EDITOR='hx'              # 或 nvim
export VISUAL=$EDITOR
export PAGER='less -R'
export LESS='-R -i -M'
```

### 3.2 一次性安装这些工具

```sh
brew install starship zoxide fzf eza bat ripgrep fd-find lazygit tmux yazi
brew install zsh-completions
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc
```

### 3.3 Starship 提示符

`~/.config/starship.toml` 极简版：

```toml
format = """
$directory\
$git_branch$git_status\
$python$nodejs$rust$golang\
$cmd_duration\
$line_break\
$character"""

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

[directory]
truncation_length = 3
truncate_to_repo = true
style = "bold cyan"

[git_branch]
format = "[$symbol$branch]($style) "
style = "purple"

[git_status]
style = "yellow"

[cmd_duration]
min_time = 2000
format = "[$duration]($style) "
style = "yellow"
```

### 3.4 关键 zsh 行为

- **Ghostty cursor 集成**依赖 zsh 的 `KEYMAP` 切换；`bindkey -e`（emacs）或 `bindkey -v`（vi）都支持。如果你自己改了 `zle-keymap-select`，不要全量覆盖，要 `add-zsh-hook` 追加。
- **`title` 集成**通过 OSC 序列设置标题，Ghostty 自动渲染到标签页。如果你的 prompt（如老版本 Pure）也写标题，会冲突——保留 Ghostty 的，关掉 prompt 自己的。

---

## 4. tmux 集成

### 4.1 为什么仍需要 tmux

Ghostty 已经支持分屏、标签、状态保存，所以经常有人问"还要 tmux 吗？"。答案是**要**：

| 能力 | Ghostty | tmux |
|------|---------|------|
| 进程持久（关窗口不死） | ✘ | ✔ |
| SSH 后断线重连 | ✘ | ✔ |
| 多设备 attach 同一会话 | ✘ | ✔ |
| 跨机器一致键位 | ✘ | ✔ |
| 启动渲染速度 | ✔ | 不如 Ghostty 原生 |

**经验法则**：本地短开短关用 Ghostty 标签/分屏；**长跑任务**（AI 代理、训练脚本、远程会话）一律 tmux。

### 4.2 当前仓库配置

当前 `configs/tmux/tmux.conf` 保持极简，使用 tmux 默认前缀 `Ctrl-b`：

```sh
set -g mouse on
set -g history-limit 50000
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:RGB"
setw -g mode-keys vi
```

常用键位以 [../reference/cheatsheet.md](../reference/cheatsheet.md) 中的 tmux 速查为准。

### 4.3 可选增强模板

如果你需要 `Ctrl-a` 前缀、TPM 插件、tmux-resurrect 或更强的 pane 导航，可以在本机私有配置中采用下面的增强模板；它不是当前仓库默认写入内容。

```sh
## ---------- 基础 ----------
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-ghostty:Tc"   # 真彩色
set -g escape-time 0                              # 减少 Esc 延迟（vim/helix 关键）
set -g history-limit 100000
set -g focus-events on
set -g mouse on

## ---------- 前缀键 ----------
unbind C-b
set -g prefix C-a
bind C-a send-prefix

## ---------- 索引从 1 开始 ----------
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

## ---------- 分屏（保留当前路径） ----------
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

## ---------- vim 风 pane 导航 ----------
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

## ---------- Alt+方向键直接切（不用前缀） ----------
bind -n M-Left  select-pane -L
bind -n M-Down  select-pane -D
bind -n M-Up    select-pane -U
bind -n M-Right select-pane -R

## ---------- 复制模式：vi 风 ----------
setw -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

## ---------- 重载配置 ----------
bind r source-file ~/.tmux.conf \; display "Reloaded ~/.tmux.conf"

## ---------- 状态栏（极简） ----------
set -g status-position top
set -g status-style "bg=default,fg=white"
set -g status-left "#[fg=cyan,bold]#S "
set -g status-right "#[fg=yellow]%H:%M "
set -g window-status-current-format "#[fg=green,bold]#I:#W"
set -g window-status-format "#[fg=white]#I:#W"

## ---------- 插件（TPM） ----------
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'      # prefix + Ctrl-s 保存 / Ctrl-r 恢复
set -g @plugin 'tmux-plugins/tmux-continuum'      # 自动每 15min 保存
set -g @plugin 'christoomey/vim-tmux-navigator'   # Ctrl-hjkl 在 vim/helix 和 pane 间无缝跳

set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'

run '~/.tmux/plugins/tpm/tpm'
```

### 4.4 安装与启用

```sh
## TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

## 启动 tmux 后按 prefix + I（大写）拉取插件
```

### 4.5 与 Ghostty 的协同关键点

1. **`escape-time 0`** 必须设。否则在 helix/neovim 中按 Esc 会有 500ms 延迟。
2. **`xterm-ghostty:Tc`** 让 tmux 知道 Ghostty 终端支持 24bit 色。`ssh-terminfo` 集成保证远端也有 `xterm-ghostty` 这个 terminfo 条目。
3. **`macos-option-as-alt = left`**（你已配置）让 `bind -n M-Left` 这类 Alt 绑定能触发。
4. **不要在 tmux 里再开 tmux**：当前仓库默认前缀是 `Ctrl-b`；如采用上面的增强模板，嵌套时用 `Ctrl-a Ctrl-a` 把前缀传给内层。

### 4.6 常用工作流

```sh
tmux new -s work             # 新建命名会话
tmux attach -t work          # 重连
tmux ls                      # 列会话
tmux kill-session -t work    # 杀会话
```

当前仓库默认前缀为 `Ctrl-b`。如果你采用增强模板改成 `Ctrl-a`，下面的 `prefix` 对应 `Ctrl-a`。

| 操作 | 键位 |
|------|------|
| 新窗口 | `prefix c` |
| 下/上一窗口 | `prefix n` / `prefix p` |
| 跳到窗口 N | `prefix 数字` |
| 重命名窗口 | `prefix ,` |
| 水平分屏 | `prefix |` |
| 垂直分屏 | `prefix -` |
| Pane 间切换 | `Alt + 方向键` 或 `prefix hjkl` |
| 缩放当前 pane | `prefix z` |
| 关闭 pane | `prefix x` |
| 复制模式 | `prefix [`，`v` 开选，`y` 复制 |
| 粘贴 tmux 缓冲 | `prefix ]` |
| 分离会话 | `prefix d` |
| 保存/恢复 | `prefix Ctrl-s` / `prefix Ctrl-r` |

---

## 5. Zoxide：智能目录跳转

### 5.1 原理

Zoxide 记录你 `cd` 过的所有目录的访问频率 × 最近度（frecency），让你用 `z 关键词` 跳到匹配的"高分目录"。

### 5.2 安装与启用

```sh
brew install zoxide
echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
```

### 5.3 常用命令

| 命令 | 作用 |
|------|------|
| `z foo` | 跳到匹配 "foo" 的最高分目录 |
| `z foo bar` | 路径中同时包含 "foo" 和 "bar" |
| `z ..` | `cd ..`（透传） |
| `z -` | 回上一个目录（替代 `cd -`） |
| `zi` | 交互式（fzf）从所有候选中选 |
| `zoxide query foo` | 只显示匹配结果不跳转 |
| `zoxide add /path` | 手动添加 |
| `zoxide remove /path` | 手动删除 |

### 5.4 替代 `cd` 的小心机

如果想让 `cd` 直接就是 zoxide：

```sh
eval "$(zoxide init zsh --cmd cd)"
```

之后 `cd foo` 也享受 frecency。**纯路径**（包含 `/`、`.` 或存在的目录名）仍按原 cd 行为。

### 5.5 与 fzf-tab 配合

`zi` 已经走 fzf。如果你想 `z <Tab>` 出 fzf 候选，配合 `Aloxaf/fzf-tab` 已经能用。

---

## 6. Yazi：终端文件管理器

### 6.1 安装

```sh
brew install yazi ffmpeg sevenzip jq poppler resvg imagemagick fd ripgrep fzf zoxide
## 预览依赖：ffmpeg/poppler/resvg/imagemagick；搜索依赖：fd/rg/fzf；跳转：zoxide
```

### 6.2 启动 + 关键键位

```sh
yazi            # 当前目录打开
yazi /some/dir  # 指定目录
```

| 键位 | 作用 |
|------|------|
| `h` / `j` / `k` / `l` | 上层 / 下 / 上 / 进入 |
| `Space` | 选中 |
| `v` | 进入可视选择模式 |
| `a` | 新建（文件/目录，末尾加 `/` 是目录） |
| `r` | 重命名 |
| `d` | 删除到回收站；`D` 永久删除 |
| `y` / `x` / `p` / `P` | 复制 / 剪切 / 粘贴 / 强制粘贴 |
| `o` / `O` | 用默认应用 / 选择应用打开 |
| `Enter` | 进入目录或按规则打开文件 |
| `/` | 搜索（fd） |
| `s` | 内容搜索（rg） |
| `z` | 用 zoxide 跳转 |
| `Z` | fzf 选 zoxide 候选 |
| `g g` / `G` | 顶 / 底 |
| `Tab` | 在两个 tab 间切（顶部多标签） |
| `t` | 新 tab |
| `;` | 输入 shell 命令 |
| `:` | 命令模式 |
| `q` | 退出 |

### 6.3 让 `q` 退出 yazi 后自动 cd 到目标目录

**强烈建议加入 `~/.zshrc`**——Yazi 真正出彩的用法：

```sh
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
```

之后敲 `y`，浏览，按 `q` 退出，shell 就站在你浏览的最后一个目录里。**这是 cd + 视觉化的最优解**。

### 6.4 配置

`~/.config/yazi/yazi.toml`（节选）：

```toml
[manager]
ratio          = [1, 3, 4]      # 父 / 当前 / 预览
sort_by        = "natural"
sort_dir_first = true
show_hidden    = false
show_symlink   = true

[preview]
max_width    = 600
max_height   = 900
image_filter = "triangle"
image_quality = 75

[opener]
edit = [
    { run = '${EDITOR:=hx} "$@"', block = true, for = "unix" },
]
play = [
    { run = 'mpv --force-window "$@"', orphan = true, for = "unix" },
]
```

### 6.5 关键集成

- **Ghostty 图像协议**：Yazi 优先用 Kitty Graphics Protocol，Ghostty 支持，所以预览图片/PDF/视频缩略图都是真彩位图，不是 sixel。
- **Zoxide 共享数据库**：Yazi 的 `z` 读的就是你 zsh 里 zoxide 的数据库，跳转记忆是统一的。

---

## 7. fzf 与组合工作流

### 7.1 fzf 默认键位（`eval "$(fzf --zsh)"` 后）

| 键位 | 作用 |
|------|------|
| `Ctrl + R` | 历史命令模糊搜索 |
| `Ctrl + T` | 当前路径下文件/目录模糊搜索（插入到命令行） |
| `Alt + C` | 当前路径下子目录模糊搜索，回车 cd |

### 7.2 让 fzf 用 fd + bat 预览（更快更美）

```sh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS="--height 60% --layout=reverse --border --preview 'bat --color=always --style=numbers --line-range=:300 {}'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
```

### 7.3 fzf-tab：用 fzf 接管 Tab 补全

`zinit light Aloxaf/fzf-tab` 后，效果：

- `cd <Tab>` → fzf 列目录预览
- `kill <Tab>` → fzf 列进程
- `git checkout <Tab>` → fzf 列分支

推荐配置：

```sh
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview 'git log --oneline --color=always $word | head -50'
zstyle ':fzf-tab:*' switch-group ',' '.'
```

---

## 8. AI 代理工作流配方

### 8.1 推荐布局

**单机本地 + AI 代理**：

```
Ghostty 窗口
└── Tab 1: tmux 会话 "agent"
    ├── pane 1: claude code（项目根目录）
    ├── pane 2: 跑测试 / 看日志
    └── pane 3: yazi / lazygit
└── Tab 2: 临时探索（不进 tmux）
└── Tab 3: 服务/数据库 shell
```

为什么这样：
- **代理一定挂 tmux**：本地崩了/睡眠/不小心关窗口，代理还在跑、可以重连
- **临时活儿不进 tmux**：减少嵌套，启动更快
- **下拉终端 (`Ctrl + ``) 留给"零碎查询"**：grep 一下、看个端口、跑个 `gh pr list`

### 8.2 多行 prompt 输入

`Shift + Enter` 在 Claude Code / Codex / Aider / Cursor TUI 中插入字面换行：

```
> 请重构以下函数：[Shift+Enter]
> [Shift+Enter]
> 1. 拆分单一职责[Shift+Enter]
> 2. 加类型注解[Shift+Enter]
> 3. 写 docstring[Enter]
```

### 8.3 复制大段输出

代理产出的长 diff / 报错堆栈：

1. **选中即复制**（你已开启 `copy-on-select`）——直接拖选
2. 大段用 `Cmd + A`（仅当前屏）；要全部 scrollback：进 tmux 复制模式 `prefix [`，搜索/选择/`y`

### 8.4 多机：本地 ↔ 远程协作

```sh
## 本地 tmux 内跑 claude，远端跑训练
local$  tmux new -s work
local$  claude         # pane 1

## 新 pane 跑远端
local$  ssh gpu-box
gpu$    tmux new -s train -d 'python train.py'

## 断开后
local$  tmux attach -t work    # 本地不丢
local$  ssh gpu-box -t 'tmux attach -t train'  # 远端不丢
```

`ssh-terminfo` 集成已经让远端识别 `xterm-ghostty`，不用 `TERM=xterm-256color` 兜底。

### 8.5 项目快速进入

`.zshrc` 加：

```sh
function p() {
    local dir
    dir=$(zoxide query -l | fzf --preview 'eza -1 --color=always {}') || return
    cd "$dir" || return
    # 自动进入项目 tmux 会话（如已存在则 attach）
    local name=$(basename "$dir" | tr '.' '_')
    tmux new -As "$name"
}
```

敲 `p`：fzf 选项目目录 → cd 进去 → 自动开/进同名 tmux 会话。

---

## 9. 故障排查

### 9.1 字体相关

**问题**：Maple Mono NF CN 显示为方框 / 系统字体
**排查**：
```sh
ghostty +list-fonts | grep -i maple
```
若没有，确认字体已安装到 `~/Library/Fonts/` 或 `/Library/Fonts/`；Nerd Font 版本要装 `NF` 而非 `NFM`/`Mono` 变体，否则字形宽度对不上 cell。

**问题**：图标显示为豆腐
**排查**：用的字体不是 Nerd Font 版本。Maple Mono **NF** CN 才有图标 patch；普通 Maple Mono CN 没有。

### 9.2 颜色相关

**问题**：tmux 里颜色发灰、不是真彩
**排查**：
```sh
echo $TERM            # 应为 xterm-ghostty（Ghostty 外）或 tmux-256color（tmux 内）
tmux info | grep Tc   # 应输出 Tc: true
```
修正：`~/.tmux.conf` 加 `set -ga terminal-overrides ",xterm-ghostty:Tc"`，重启 tmux 服务（`tmux kill-server`）。

### 9.3 SSH 远端 terminfo 缺失

**报错**：`tput: unknown terminal "xterm-ghostty"`
**原因**：远端没有 Ghostty 的 terminfo。
**修复**：你已开 `ssh-terminfo` 集成，正常会自动装；若失败，手动：
```sh
infocmp -x xterm-ghostty | ssh remote -- tic -x -
```
或临时降级：`TERM=xterm-256color ssh remote`。

### 9.4 Alt 键位不生效

**症状**：tmux `bind -n M-Left` 没反应。
**修复**：`macos-option-as-alt = left`（你已配）。若仍不行，确认按的是**左** Option；或改 `= true` 让两侧都生效。

### 9.5 下拉终端不响应

**症状**：`Ctrl + `` 在其他 App 中无反应。
**修复**：
1. `global:` 前缀必须有（你已有）
2. 系统设置 → 隐私与安全性 → 辅助功能 → 勾选 Ghostty
3. 重启 Ghostty

### 9.6 配置不生效

**排查**：
```sh
ghostty +validate-config              # 语法
ghostty +show-config                  # 实际生效值
```
注意：少数项（`background-opacity`、部分 `macos-*`）需完全退出 Ghostty 重启，光按 `Cmd+Shift+,` 不行。

### 9.7 Yazi 预览图片失败

**排查**：
- 确认 `imagemagick`、`poppler`（PDF）、`ffmpeg`（视频）已装
- Ghostty 必须开启 Kitty Graphics Protocol（默认开）
- 在 tmux 里嵌套时，tmux ≥ 3.4 才支持透传图像协议；旧版会"图像不显示但文件信息正常"

### 9.8 启动慢

**排查**：
```sh
zsh -i -c exit -x 2>&1 | head -50    # 看哪个插件慢
```
常见元凶：`compinit` 没缓存、Oh My Zsh 加载了几十个插件、`nvm` 同步加载。建议用 zinit 的 `wait` 模式延迟加载非关键插件：

```sh
zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions
```

---

## 附录 A：完整 zshrc 模板

参见 §3.1。

## 附录 B：完整 tmux.conf 模板

参见 §4.2。

## 附录 C：参考链接

- Ghostty 文档：<https://ghostty.org/docs>
- Ghostty 配置参考：<https://ghostty.org/docs/config/reference>
- Ghostty keybind 动作：<https://ghostty.org/docs/config/keybind/reference>
- Starship：<https://starship.rs>
- tmux 手册：`man tmux`
- Yazi 文档：<https://yazi-rs.github.io>
- Zoxide：<https://github.com/ajeetdsouza/zoxide>
- fzf：<https://github.com/junegunn/fzf>
- zinit：<https://github.com/zdharma-continuum/zinit>

---

*手册版本：v1.0 · 与你 2026-06 的 Ghostty 配置同步*
