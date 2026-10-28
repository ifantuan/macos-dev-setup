# 仓库设计说明

## 目标

这个仓库不是简单的 dotfiles 备份，而是一个可复用的 macOS 开发环境模板。

目标：

- 新机可快速部署。
- 配置可审计、可回滚。
- 文档能解释每个工具的边界。
- 可以长期用 Git 维护。

## 设计原则

| 原则 | 说明 |
|------|------|
| 声明式 | 软件安装集中在 `Brewfile` |
| 快速启动 | `Brewfile.core` 只保留进入开发必需工具 |
| 可回滚 | bootstrap 覆盖前备份原配置 |
| 系统设置可审计 | macOS defaults 通过脚本集中写入，执行前可 dry-run |
| 可验证 | `scripts/doctor.sh` 做基础检查 |
| 可对比 | `scripts/audit-environment.sh` 输出本机和仓库声明差异 |
| 可追踪 | 写入型脚本正式执行时归档日志 |
| 可重复 | clean HOME 和幂等演练验证恢复路径 |
| 可持续集成 | GitHub Actions 在推送和 PR 时运行自检 |
| 少凭证 | 仓库只放模板，不放真实密钥 |
| 可拆分 | 配置、脚本、文档分目录管理 |

## 关键目录

```text
configs/    可复制到家目录的配置，目录说明见 configs/README.md
docs/       手册和运行规范，目录说明见 docs/README.md
scripts/    安装和校验脚本，目录说明见 scripts/README.md
scripts/lib/ 脚本共享辅助逻辑
tests/      隔离回归测试，使用临时目录和命令桩覆盖实际控制流
Makefile    常用入口命令，降低新用户使用成本
Brewfile.core 30 分钟核心安装清单
Brewfile    Homebrew 声明式清单
```

运行时默认版本集中在 `configs/runtimes/versions.sh`；core/full 默认只使用官方 Homebrew 源。第三方软件按包列在个人示例中，由用户审查后放入私有清单。文件替换复用 `scripts/lib/files.sh`，避免各入口重复实现先截断再导出的危险操作。

目录级 `README.md` 是扩展契约：新增配置、脚本或专题文档时，先更新对应目录说明，再更新根 README 的结构树。

## 外部标杆对齐

[benchmark.md](benchmark.md) 记录本仓库和 thoughtbot Laptop、Mathias Bynens dotfiles、Homebrew Bundle 官方实践、mac.install.guide 等参考对象的对比。

新增外部实践时，先回答三件事：

1. 它解决的是快速启动、完整恢复、系统设置、运行时、排障还是长期维护问题。
2. 它能否 dry-run、备份或被明确验证。
3. 它是否会拖慢 `make quickstart` 的半小时路径。

## 为什么不用一键全自动

macOS 新机初始化涉及：

- Apple ID 和系统权限。
- 安全设置。
- 私钥和 token。
- GUI App 登录态。
- 公司或个人网络代理。

这些步骤不适合完全自动化。仓库只自动化可审计、可重复、低风险的部分。

## 推荐 fork 后修改

必改：

- `README.md` 中的 GitHub 地址。
- `Brewfile` 中自己不用的软件。
- `configs/zsh/zshrc` 中 `EDITOR` 和代理端口。

可选：

- 从 `configs/git/gitconfig.example`、`configs/ssh/config.example`、`configs/npm/npmrc.example`、`configs/pip/pip.conf.example`、`configs/maven/settings.xml.example`、`configs/vscode/settings.json.example` 复制私有配置。
- 按需参考 `configs/vscode/extensions.txt.example` 安装编辑器扩展。
- 在 `~/.zshrc.local` 维护不适合公开提交的 Shell 差异。
- 调整 `configs/starship/starship.toml`。
- 增加 `scripts/sync-back.sh`。
