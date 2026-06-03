# 支持范围与环境矩阵

本仓库首先服务 Apple Silicon Mac 的个人开发工作站。作为公开模板使用时，先确认当前机器是否落在以下范围内。

## 当前支持

| 项目 | 状态 | 说明 |
|------|------|------|
| Apple Silicon | 支持 | 默认 Homebrew 前缀为 `/opt/homebrew`，是当前主路径 |
| Intel Mac | 有限支持 | 文档提供 `/usr/local` Homebrew 初始化方式，但脚本和配置以 Apple Silicon 为主 |
| macOS 15 | 支持 | 当前半恢复演练基于 macOS 15.7.7 |
| macOS 14 | 应可用 | 未做本仓库真实恢复演练，遇到差异需记录到恢复演练 |
| macOS 13 及更早 | 未验证 | Homebrew、cask、系统 defaults 可能有差异 |
| Linux / Windows / WSL | 不支持 | 本仓库不是跨平台 dotfiles |

## 关键假设

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
