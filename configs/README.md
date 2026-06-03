# 配置目录说明

本目录按软件和工具拆分配置文件。`scripts/bootstrap.sh` 会读取这里的文件并写入对应位置，写入前会备份用户原有配置。

## 文件映射

| 仓库文件 | 目标位置 | 用途 |
|----------|----------|------|
| `configs/zsh/zshrc` | `~/.zshrc` | zsh、代理函数、运行时初始化、别名、Starship |
| `configs/ghostty/config` | `~/.config/ghostty/config` | Ghostty 字体、主题、分屏、快捷键 |
| `configs/starship/starship.toml` | `~/.config/starship.toml` | Starship 提示符 |
| `configs/tmux/tmux.conf` | `~/.tmux.conf` | tmux 前缀键、窗口、面板、颜色 |
| `configs/git/gitconfig.example` | `~/.gitconfig` | Git 模板，需复制后填写真实身份 |
| `configs/ssh/config.example` | `~/.ssh/config` | SSH 模板，需复制后检查私钥路径 |
| `configs/npm/npmrc.example` | `~/.npmrc` | npm 模板，真实 token 通过环境变量或私有文件提供 |
| `configs/pip/pip.conf.example` | `~/.pip/pip.conf` | pip 模板，私有镜像需本机维护 |
| `configs/maven/settings.xml.example` | `~/.m2/settings.xml` | Maven 模板，真实账号通过环境变量或私有文件提供 |
| `configs/vscode/settings.json.example` | `~/Library/Application Support/Code/User/settings.json` | VS Code 设置模板，适合复制后按机器调整 |
| `configs/vscode/extensions.txt.example` | 手动执行 `code --install-extension` | VS Code / Cursor 推荐扩展示例 |

## 修改原则

- 只放可公开、可复用、无凭证的配置。
- 不提交 token、私钥、内网地址、公司代理账号。
- 本机差异优先用环境变量或单独私有文件处理，不直接写死到公共配置。
- `configs/zsh/zshrc` 会加载 `~/.zshrc.local`，该文件不要提交。
- 修改后运行 `./scripts/doctor.sh`。

## 常见扩展

| 需求 | 推荐做法 |
|------|----------|
| 增加 Git 配置 | 先扩展 `configs/git/gitconfig.example`，确认安全后再决定是否自动复制 |
| 增加 Starship 配置 | 修改 `configs/starship/starship.toml`，再运行 `./scripts/bootstrap.sh --dry-run --skip-brew` |
| 增加 SSH 配置模板 | 只提交 `configs/ssh/config.example`，不要提交真实私钥 |
| 增加编辑器配置模板 | 使用 `*.example`，避免覆盖用户已有同步配置 |
| 增加编辑器扩展清单 | 使用 `configs/vscode/extensions.txt.example`，只记录可公开扩展 ID |
| 增加私有环境变量 | 使用 `.env.example` 记录变量名，真实值保存在本机或 1Password |
| 增加本机 Shell 差异 | 写入 `~/.zshrc.local`，不要放入公共 `configs/zsh/zshrc` |
| 增加工作/个人机器差异 | 先阅读 [../docs/setup/profiles.md](../docs/setup/profiles.md)，优先使用 `*.example` 和私有本机文件 |

新增配置文件时，同步更新：

1. [../scripts/README.md](../scripts/README.md)
2. [../docs/setup/repository-design.md](../docs/setup/repository-design.md)
3. [../README.md](../README.md) 的仓库结构
