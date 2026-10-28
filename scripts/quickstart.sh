#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"
SKIP_RUNTIMES="${SKIP_RUNTIMES:-0}"
SKIP_DOCTOR="${SKIP_DOCTOR:-0}"
PROFILE="${PROFILE:-core}"

usage() {
  cat <<'EOF'
用法：scripts/quickstart.sh [选项]

选项：
  --profile <name>  选择 core 或 full，默认 core；两者均执行运行时和自检
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
    --profile)
      [[ $# -ge 2 ]] || { echo "--profile 需要参数：core 或 full" >&2; exit 1; }
      PROFILE="$2"
      shift 2
      ;;
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

case "$PROFILE" in
  core|full) ;;
  *) echo "未知 profile：$PROFILE。可选值：core, full" >&2; exit 1 ;;
esac

# shellcheck source=scripts/lib/logging.sh
source "$REPO_ROOT/scripts/lib/logging.sh"
setup_script_logging "quickstart"

# 默认走核心路径；显式选择 full 时仍保留完整的运行时和自检链路。
echo "==> 安装 $PROFILE 工具和配置"
bootstrap_args=(--profile "$PROFILE")
if [[ "$DRY_RUN" == "1" ]]; then
  bootstrap_args+=(--dry-run)
fi
"$REPO_ROOT/scripts/bootstrap.sh" "${bootstrap_args[@]}"

if [[ "$SKIP_RUNTIMES" != "1" ]]; then
  echo "==> 初始化开发运行时"
  if [[ "$DRY_RUN" == "1" ]]; then
    "$REPO_ROOT/scripts/install-runtimes.sh" --dry-run
  else
    "$REPO_ROOT/scripts/install-runtimes.sh"
  fi
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
