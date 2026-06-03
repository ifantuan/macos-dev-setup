# App Store 应用与 mas 策略

本仓库默认不把 App Store 应用纳入自动安装路径。原因是 App Store 依赖 Apple ID 登录态、购买记录、地区和公司设备管理策略，不适合放进半小时快速启动。

## 什么时候使用 mas

只有满足以下条件时才考虑 `mas`：

- App Store 应用是开发环境恢复的必要组成部分。
- 应用 ID 稳定，且不会暴露个人购买偏好。
- 机器已经登录正确 Apple ID。
- 你愿意在每次迁移时处理 App Store 的授权和地区差异。

安装和查看：

```bash
brew install mas
mas list
```

安装单个应用：

```bash
mas install <app-id>
```

## 不建议提交完整 mas list

`mas list` 会暴露你安装过的 App Store 应用，通常包含个人偏好、公司应用或地区特定应用。公开仓库只建议记录：

| 内容 | 是否提交 |
|------|----------|
| 应用用途说明 | 可以 |
| 稳定的公开 App ID | 按需 |
| 个人完整 `mas list` | 不建议 |
| 公司内部 App | 不提交 |
| Apple ID、购买信息 | 不提交 |

## 推荐记录格式

如果未来需要记录 App Store 应用，使用这种格式：

```text
应用名称：Xcode
用途：iOS / macOS 原生开发
安装方式：App Store 或 Apple Developer 下载
是否进入快速启动：否
备注：体积大，建议核心环境可用后再安装
```

## 当前仓库策略

- `Brewfile.core` 不包含 `mas`，保证半小时路径轻量。
- `Brewfile` 暂不包含 `mas`，避免隐含 Apple ID 前置条件。
- 移动端开发相关内容放在 [../setup/guide.md](../setup/guide.md) 和 [ide.md](ide.md) 中说明。
- 如果某个 App Store 应用成为强依赖，先更新本文，再决定是否新增 `Masfile.example`。
