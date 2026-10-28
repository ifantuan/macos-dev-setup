# 贡献指南

感谢你愿意改进这个 macOS 开发环境仓库。

## 贡献方向

欢迎贡献：

- 更稳妥的新机初始化流程。
- 常见工具的排障经验。
- Brewfile 分类优化。
- 文档结构和可读性改进。
- 脚本安全性和幂等性改进。

不建议贡献：

- 个人私有 token、私钥、内网地址。
- 与开发环境无关的大量 GUI 应用推荐。
- 未验证的破坏性命令。

## 本地检查

提交前运行：

```bash
./scripts/doctor.sh
make test
make drill-clean
make drill-idempotency
```

如果你要验证本机是否已完整安装 `Brewfile` 中的全部依赖：

```bash
CHECK_BREW_INSTALLED=1 ./scripts/doctor.sh
```

回归测试仅使用临时家目录、仓库副本和桩命令，不安装或卸载软件。默认通过 `/bin/bash` 验证 macOS 自带 Bash 3.2；现代 Bash 可用 `TEST_BASH="$(brew --prefix bash)/bin/bash" make test` 验证。新增失败路径时，应先确认测试在旧实现上失败，再验证修复。

脚本语法至少确认：

```bash
bash -n scripts/bootstrap.sh
bash -n scripts/apply-macos-defaults.sh
bash -n scripts/audit-environment.sh
bash -n scripts/brew-maintenance.sh
bash -n scripts/doctor.sh
bash -n scripts/drill-clean-home.sh
bash -n scripts/drill-idempotency.sh
bash -n scripts/quickstart.sh
bash -n scripts/install-runtimes.sh
bash -n scripts/sync-back.sh
ruby -c scripts/lib/find-shadowed-packages.rb
zsh -n configs/zsh/zshrc
```

## 文档规范

- 用户可见文档使用简体中文。
- 命令块必须可复制执行。
- 涉及危险操作时说明前置条件和回滚方式。
- 不写未经验证的 CLI 参数。
- 普通 GUI 应用只放用途说明，不写长篇手册。

## 提交信息

使用简体中文，建议格式：

```text
补充 Codex 排障说明
优化 bootstrap 备份逻辑
更新 Brewfile 软件清单
```

## Pull Request 建议

PR 描述建议包含：

- 改了什么。
- 为什么改。
- 如何验证。
- 是否会覆盖用户本机配置。
