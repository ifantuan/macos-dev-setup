# 支持范围与环境矩阵

本仓库首先服务 Apple Silicon Mac 的个人开发工作站。作为公开模板使用时，先确认当前机器是否落在以下范围内。

## 当前支持

| 项目 | 状态 | 说明 |
|------|------|------|
| Apple Silicon | 支持 | 默认 Homebrew 前缀为 `/opt/homebrew`，是当前主路径 |
| Intel Mac | 本仓库未验证 | Homebrew 7 为 Tier 3；文档保留 `/usr/local` 初始化示例，不承诺完整恢复 |
| macOS 15 | 支持 | 当前半恢复演练基于 macOS 15.7.7 |
| macOS 14 | 本仓库未验证 | Homebrew 7 为 Tier 3，不能视作默认受支持路径 |
| macOS 26 / 27 | 本仓库未验证 | 上游支持等级不等于本仓库已完成恢复演练 |
| Homebrew 7 | 当前适配基线 | 已核对 7.0.11 的 Bundle 参数、清理交互及信任语义 |
| Bash 3.2 / 现代 Bash | 回归测试覆盖 | 本机默认使用 `/bin/bash`，CI 同时运行 Homebrew Bash |
| macOS 13 及更早 | 未验证 | Homebrew、cask、系统 defaults 可能有差异 |
| Linux / Windows / WSL | 不支持 | 本仓库不是跨平台 dotfiles |

## 关键假设

上游等级以 [Homebrew 官方支持矩阵](https://docs.brew.sh/Support-Tiers)为准；上述本仓库验证状态与上游承诺分别记录。

- 用户 Shell 为 zsh。
- Homebrew 已由用户先安装。
- Xcode Command Line Tools 已安装。
- 默认使用 `/opt/homebrew`，Intel Mac 需要人工确认 `/usr/local` 路径。
- 公司 VPN、证书、MDM、内网 registry 和登录态不由本仓库自动化。

## 验证要求

新增支持范围前，至少补齐：

1. 运行 `make record-drill`，并在 [recovery-drills](recovery-drills/) 中保留一条真实或半真实演练记录。
2. `make dry-run`、`make drill-clean`、`make drill-idempotency`、`./scripts/doctor.sh` 的结果。
3. 如果涉及 Intel Mac，补充 `/usr/local` Homebrew 路径验证。
4. 如果涉及旧 macOS，补充 defaults 写入和 GUI cask 差异记录。
