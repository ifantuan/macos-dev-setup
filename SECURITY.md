# 安全策略

## 敏感信息

请不要提交：

- SSH 私钥、GPG 私钥。
- `.env`、`.env.local`。
- API key、访问 token、cookie。
- Maven、npm、PyPI 私服凭证。
- 云厂商凭证。
- 公司内网地址、跳板机地址、私有仓库 token。

如需提供示例，使用 `.env.example` 或占位符。

## 本机安全建议

- 开启 FileVault。
- 开启查找我的 Mac。
- 使用 1Password 或 macOS 钥匙串保存凭证。
- 长期插电时使用电池管理工具。
- 运行第三方脚本前先阅读内容。

## bootstrap 安全行为

`scripts/bootstrap.sh` 会在覆盖配置前备份：

```text
~/.zshrc
~/.config/ghostty/config
~/.config/starship.toml
~/.tmux.conf
```

默认备份目录：

```text
~/.macos-dev-setup-backup/<时间戳>.<随机后缀>
```

`BACKUP_DIR` 指定备份根目录，每次执行都会新建独立批次。普通文件保存到原相对路径；符号链接本身同样保存，可读取的链接目标内容另存到批次的 `link-targets/`。安装时原子替换链接本身，不改写链接指向的文件。配置父目录为符号链接时会提前拒绝写入，需人工确定目录管理方式。

Homebrew 7 的实际 Bundle 清理会重置全局显式信任。`--cleanup-preview` 断开子进程标准输入，保证无法确认删除；`--cleanup-force` 必须另加 `--acknowledge-trust-reset`，并在删除前将有效信任快照保存到独立的 `trust-<时间戳>.<随机后缀>/trust.json`。`--yes` 只跳过文字确认，不能替代信任重置确认。信任快照不备份已卸载软件或应用数据。

可预演：

```bash
./scripts/quickstart.sh --dry-run
```

可跳过软件安装：

```bash
./scripts/bootstrap.sh --skip-brew
```

正式执行写入型脚本时，输出会归档到：

```text
~/.macos-dev-setup-logs/
```

`doctor.sh` 会在本机安装 `gitleaks` 时运行密钥扫描。扫描结果通过后也不能替代人工审查，提交前仍需检查 `git diff`。

## macOS defaults 安全行为

`scripts/apply-macos-defaults.sh` 会在写入系统默认设置前导出相关 defaults 域：

```text
~/.macos-dev-setup-backup/<时间戳>/macos-defaults/
```

正式执行前建议先预演：

```bash
./scripts/apply-macos-defaults.sh --dry-run
```

该脚本只写入当前用户的 Finder、Dock、键盘、截图和桌面服务偏好，不处理 Apple ID、FileVault、隐私授权、密码、证书或 token。

## 报告问题

如果你发现安全问题，请不要在公开 issue 中贴出密钥或真实凭证。请先脱敏，再描述复现步骤。
