#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"
SKIP_RUNTIMES="${SKIP_RUNTIMES:-0}"
SKIP_DOCTOR="${SKIP_DOCTOR:-0}"

usage() {
  cat <<'EOF'
用法：scripts/quickstart.sh [选项]

选项：
  --dry-run        只打印将执行的操作，不写入文件、不安装软件
  --skip-runtimes  跳过 Java / Python / Node.js 初始化
  --skip-doctor    跳过最终自检
  -h, --help       显示帮助

环境变量：
  DRY_RUN=1
  SKIP_RUNTIMES=1
  SKIP_DOCTOR=1
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --skip-runtimes)
      SKIP_RUNTIMES=1
      shift
      ;;
    --skip-doctor)
      SKIP_DOCTOR=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数：$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# shellcheck source=scripts/lib/logging.sh
source "$REPO_ROOT/scripts/lib/logging.sh"
setup_script_logging "quickstart"

# 快速启动只串联核心路径；完整 GUI 恢复留给 bootstrap.sh --profile full。
echo "==> 安装核心工具和配置"
bootstrap_args=(--profile core)
if [[ "$DRY_RUN" == "1" ]]; then
  bootstrap_args+=(--dry-run)
fi
"$REPO_ROOT/scripts/bootstrap.sh" "${bootstrap_args[@]}"

if [[ "$SKIP_RUNTIMES" != "1" ]]; then
  echo "==> 初始化开发运行时"
  runtime_args=()
  if [[ "$DRY_RUN" == "1" ]]; then
    runtime_args+=(--dry-run)
  fi
  "$REPO_ROOT/scripts/install-runtimes.sh" "${runtime_args[@]}"
else
  echo "==> 跳过开发运行时初始化"
fi

if [[ "$SKIP_DOCTOR" != "1" ]]; then
  echo "==> 运行仓库自检"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] $REPO_ROOT/scripts/doctor.sh"
  else
    "$REPO_ROOT/scripts/doctor.sh"
  fi
else
  echo "==> 跳过仓库自检"
fi

echo "==> 快速启动完成。重新打开终端后登录 GitHub、1Password、IDE 和 AI 工具。"
