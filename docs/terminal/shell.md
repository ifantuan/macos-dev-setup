# Shell 与终端工具链手册

## 适用范围

本文覆盖 `zsh`、`.zprofile`、`.zshrc`、Oh My Zsh、Starship、Zinit、tmux、fzf、zoxide、eza、bat、ripgrep、fd、Yazi。

## 官方资料

| 工具 | 官方资料 |
|------|----------|
| Zsh | <https://zsh.sourceforge.io/Doc/> |
| Oh My Zsh | <https://ohmyz.sh/> |
| Starship | <https://starship.rs/> |
| Zinit | <https://github.com/zdharma-continuum/zinit> |
| tmux | `man tmux` |
| fzf | <https://github.com/junegunn/fzf> |
| zoxide | <https://github.com/ajeetdsouza/zoxide> |
| Yazi | <https://yazi-rs.github.io/> |
| eza | <https://eza.rocks/> |
| bat | <https://github.com/sharkdp/bat> |
| ripgrep | <https://github.com/BurntSushi/ripgrep> |
| fd | <https://github.com/sharkdp/fd> |

## 配置边界

| 文件 | 职责 |
|------|------|
| `~/.zprofile` | 登录 Shell 初始化，适合放 Homebrew `shellenv` 和全局镜像变量 |
| `~/.zshrc` | 交互式 Shell 初始化，适合放插件、别名、版本管理器、提示符 |
| `~/.tmux.conf` | tmux 会话、分屏、复制模式和状态栏 |
| `~/.config/ghostty/config` | 终端字体、主题、键位、窗口行为 |
| `~/.config/starship.toml` | Starship 提示符模块和显示格式 |

原则：路径和工具初始化放 `.zshrc`，Homebrew 根路径放 `.zprofile`，不要把凭证写进任何一个配置文件。

## zshrc 设计

当前 `configs/zsh/zshrc` 采用稳妥配置：

- 保留 Oh My Zsh，只启用 `git` 插件。
- 关闭 Oh My Zsh 主题，使用 Starship。
- `fnm`、`pyenv`、`rustup`、`starship`、`zinit` 均条件加载。
- 代理不默认开启，通过函数手动控制。
- 本地路径使用 `$HOME`，避免用户名变化导致迁移失败。

常用代理函数：

```zsh
proxy_on
proxy_off
proxy_status
```

`proxy_on` 不写死本机端口。需要代理时，先在 `~/.zshrc.local` 中设置 `MACOS_DEV_SETUP_HTTP_PROXY`、`MACOS_DEV_SETUP_HTTPS_PROXY` 或 `MACOS_DEV_SETUP_ALL_PROXY`。

## Starship

Starship 是提示符，不负责包管理或补全。仓库配置位于 `configs/starship/starship.toml`，由 `scripts/bootstrap.sh` 复制到 `~/.config/starship.toml`。

验证：

```bash
starship --version
```

如果提示符未生效：

```bash
command -v starship
tail -n 20 ~/.zshrc
```

## tmux

tmux 用于长时间运行任务，例如后端服务、AI 代理、远程会话。

常用命令：

```bash
tmux new -s dev
tmux attach -t dev
tmux ls
tmux kill-session -t dev
```

建议：

- AI 代理和长构建任务放进 tmux。
- 临时命令使用 Ghostty 标签页或分屏。
- 不要在 tmux 里反复嵌套 tmux。

### tmux 快捷键速查

当前 `configs/tmux/tmux.conf` 使用默认前缀 `Ctrl-b`。如果后续改成 `Ctrl-a`，这里的 `prefix` 也随之变化。

| 操作 | 快捷键 |
|------|--------|
| 新建窗口 | `prefix c` |
| 下一个窗口 | `prefix n` |
| 上一个窗口 | `prefix p` |
| 关闭当前 pane | `prefix x` |
| 分离会话 | `prefix d` |
| 进入复制模式 | `prefix [` |
| 粘贴缓冲区 | `prefix ]` |
| 缩放当前 pane | `prefix z` |
| 重载配置 | `tmux source-file ~/.tmux.conf` |

## fzf / zoxide / Yazi

| 工具 | 用途 |
|------|------|
| `fzf` | 模糊查找，常用于历史、文件、分支、目录选择 |
| `zoxide` | 智能目录跳转 |
| `yazi` | 终端文件管理器 |

常用命令：

```bash
z project
zi
yazi
```

### fzf 默认快捷键

启用 `eval "$(fzf --zsh)"` 后常用：

| 操作 | 快捷键 |
|------|--------|
| 搜索命令历史 | `Ctrl-r` |
| 搜索文件并插入路径 | `Ctrl-t` |
| 搜索目录并进入 | `Alt-c` |

### zoxide 命令速查

| 命令 | 用途 |
|------|------|
| `z name` | 跳到匹配目录 |
| `zi` | 交互式选择目录 |
| `z -` | 返回上一个目录 |
| `zoxide query name` | 查询匹配路径 |
| `zoxide add /path` | 手动加入目录 |
| `zoxide remove /path` | 删除目录记录 |

### Yazi 快捷键速查

| 操作 | 快捷键 |
|------|--------|
| 打开文件/进入目录 | `Enter` |
| 返回上级 | `Backspace` 或 `h` |
| 进入目录 | `l` |
| 上下移动 | `k` / `j` |
| 复制 | `y` |
| 剪切 | `x` |
| 粘贴 | `p` |
| 重命名 | `r` |
| 删除到回收站 | `d` |
| 搜索 | `/` |
| 退出 | `q` |

## eza / bat / rg / fd

| 工具 | 替代 | 用途 |
|------|------|------|
| `eza` | `ls` | 更清晰的目录列表 |
| `bat` | `cat` | 带语法高亮的文件查看 |
| `rg` | `grep` | 高速文本搜索 |
| `fd` | `find` | 更易用的文件查找 |

示例：

```bash
rg "TODO" .
fd package.json
bat README.md
eza -la --git --icons
```

## 排障

Shell 启动慢：

```bash
time zsh -i -c exit
```

检查语法：

```bash
zsh -n ~/.zshrc
```

查看 PATH 顺序：

```bash
echo $PATH | tr ':' '\n'
```
