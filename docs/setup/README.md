# 初始化文档目录说明

本目录记录新机部署、仓库设计和维护流程。

| 文件 | 用途 |
|------|------|
| `quickstart-30min.md` | 半小时进入开发工作的最短路径 |
| `guide.md` | 完整 macOS 生产力环境初始化指南 |
| `maintenance.md` | 日常更新、迁移、验收 |
| `recovery-drill.md` | 新机恢复演练记录 |
| `recovery-drills/` | 真实或半真实恢复演练报告 |
| `gap-closure.md` | 外部对比后主要缺口的修复记录 |
| [audit-2026-10-27.md](audit-2026-10-27.md) | 全面审计、Homebrew 7 兼容性、问题复现与优化顺序 |
| [audit-2026-10-27-review.md](audit-2026-10-27-review.md) | 上述审计报告的逐条复核结果 |
| [audit-fixes-2026-10-27.md](audit-fixes-2026-10-27.md) | A01–A14 修复结果、行为变化与回归验证 |
| [audit-2026-10-27-claude-followup-review.md](audit-2026-10-27-claude-followup-review.md) | Claude 追加修复的独立复核、问题证据与回退验证 |
| `support-matrix.md` | 支持范围、架构和 macOS 版本边界 |
| `repository-design.md` | 仓库结构、边界和扩展原则 |
| `benchmark.md` | 外部标杆对比、当前差距和改进路线 |
| `profiles.md` | core、full、work、personal 的环境分层策略 |

## 阅读建议

新用户先读 `quickstart-30min.md`。需要完整恢复个人工作站时，再读 `guide.md`。

## 扩展建议

- 新增部署步骤时，先判断是否属于半小时路径。
- 半小时路径只放“能开始开发”的必要内容。
- 完整 GUI 软件、登录态、模型下载、移动端环境放到 `guide.md` 或专题手册。
- 外部优秀实践先写入 `benchmark.md` 做取舍，再落到脚本、清单或专题文档。
- 工作机器和个人机器差异先写入 `profiles.md`，不要直接污染 `core` 路径。
