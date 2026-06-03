.PHONY: help quickstart core full defaults audit sync-back runtimes doctor check dry-run drill drill-clean drill-idempotency record-drill brew-check brew-install brew-cleanup-preview

help:
	@printf '%s\n' '常用命令：'
	@printf '  %-18s %s\n' 'make quickstart' '安装核心工具、运行时并自检'
	@printf '  %-18s %s\n' 'make core' '只安装核心 Homebrew 清单和配置'
	@printf '  %-18s %s\n' 'make full' '安装完整 Homebrew 清单和配置'
	@printf '  %-18s %s\n' 'make defaults' '应用可审计的 macOS 默认设置'
	@printf '  %-18s %s\n' 'make audit' '检查本机环境并输出和仓库的差异'
	@printf '  %-18s %s\n' 'make sync-back' '同步本机配置回仓库'
	@printf '  %-18s %s\n' 'make runtimes' '初始化 Java / Python / Node.js'
	@printf '  %-18s %s\n' 'make doctor' '运行仓库自检'
	@printf '  %-18s %s\n' 'make dry-run' '预演快速启动路径'
	@printf '  %-18s %s\n' 'make drill' '运行半恢复演练检查'
	@printf '  %-18s %s\n' 'make drill-clean' '用临时 HOME 运行恢复演练'
	@printf '  %-18s %s\n' 'make drill-idempotency' '验证 bootstrap 可重复执行'
	@printf '  %-18s %s\n' 'make record-drill' '生成恢复演练记录'
	@printf '  %-18s %s\n' 'make brew-check' '检查完整 Homebrew 清单'
	@printf '  %-18s %s\n' 'make brew-install' '按完整清单安装，默认不升级'
	@printf '  %-18s %s\n' 'make brew-cleanup-preview' '预演清理清单外依赖'

quickstart:
	./scripts/quickstart.sh

core:
	./scripts/bootstrap.sh --profile core

full:
	./scripts/bootstrap.sh --profile full

defaults:
	./scripts/apply-macos-defaults.sh

audit:
	./scripts/audit-environment.sh

sync-back:
	./scripts/sync-back.sh

runtimes:
	./scripts/install-runtimes.sh

doctor:
	./scripts/doctor.sh

check: doctor

dry-run:
	./scripts/quickstart.sh --dry-run

drill:
	./scripts/quickstart.sh --dry-run
	./scripts/bootstrap.sh --dry-run --skip-brew
	./scripts/apply-macos-defaults.sh --dry-run
	./scripts/doctor.sh
	./scripts/audit-environment.sh --profile core --no-diff

drill-clean:
	./scripts/drill-clean-home.sh

drill-idempotency:
	./scripts/drill-idempotency.sh

record-drill:
	./scripts/record-recovery-drill.sh

brew-check:
	./scripts/brew-maintenance.sh --profile full --check

brew-install:
	./scripts/brew-maintenance.sh --profile full --install

brew-cleanup-preview:
	./scripts/brew-maintenance.sh --profile full --cleanup-preview
