#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-$REPO_ROOT/docs/setup/recovery-drills}"
PROFILE="${PROFILE:-core}"
RUN_QUICKSTART="${RUN_QUICKSTART:-0}"
REPORT=""
failures=0

usage() {
  cat <<'EOF'
用法：scripts/record-recovery-drill.sh [选项]

选项：
  --profile <name>       记录目标 profile，默认 core
  --output-dir <path>    覆盖报告目录，默认 docs/setup/recovery-drills
  --run-quickstart       真实执行 make quickstart；默认只执行 make dry-run
  -h, --help             显示帮助

环境变量：
  PROFILE=core
  OUTPUT_DIR=docs/setup/recovery-drills
  RUN_QUICKSTART=0
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      if [[ $# -lt 2 ]]; then
        echo "--profile 需要参数" >&2
        exit 1
      fi
      PROFILE="$2"
      shift 2
      ;;
    --output-dir)
      if [[ $# -lt 2 ]]; then
        echo "--output-dir 需要参数" >&2
        exit 1
      fi
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --run-quickstart)
      RUN_QUICKSTART=1
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

timestamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTPUT_DIR"
REPORT="$OUTPUT_DIR/${timestamp}-${PROFILE}.md"

append() {
  printf '%s\n' "$*" >> "$REPORT"
}

append_command() {
  local title="$1"
  shift

  append "### $title"
  append
  append '```text'
  append "$ $*"
  set +e
  "$@" >> "$REPORT" 2>&1
  local status=$?
  set -e
  append
  append "退出码：$status"
  append '```'
  append
  if [[ "$status" -ne 0 ]]; then
    failures=$((failures + 1))
  fi
}

append "# 恢复演练记录"
append
append "| 项目 | 值 |"
append "|------|----|"
append "| 日期 | $(date '+%Y-%m-%d %H:%M:%S %z') |"
append "| 目标 profile | $PROFILE |"
append "| 仓库 | $REPO_ROOT |"
append "| Git 提交 | $(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo 未知) |"

if command -v sw_vers >/dev/null 2>&1; then
  append "| macOS | $(sw_vers -productVersion) |"
else
  append "| 系统 | $(uname -s) $(uname -r) |"
fi

append "| 架构 | $(uname -m) |"
append "| Shell | ${SHELL:-未知} |"
append
append "## 自动采集"
append

append_command "系统信息" uname -a

if command -v xcode-select >/dev/null 2>&1; then
  append_command "Xcode Command Line Tools" xcode-select -p
else
  append "### Xcode Command Line Tools"
  append
  append "未检测到 xcode-select。"
  append
fi

if command -v brew >/dev/null 2>&1; then
  append_command "Homebrew 版本" brew --version
else
  append "### Homebrew 版本"
  append
  append "未检测到 brew。"
  append
fi

append_command "快速路径预演" make -C "$REPO_ROOT" dry-run

if [[ "$RUN_QUICKSTART" == "1" ]]; then
  append_command "真实 quickstart" make -C "$REPO_ROOT" quickstart
else
  append "### 真实 quickstart"
  append
  append "未执行。需要真实安装时加 \`--run-quickstart\`。"
  append
fi

append_command "clean HOME 演练" make -C "$REPO_ROOT" drill-clean
append_command "幂等演练" make -C "$REPO_ROOT" drill-idempotency
append_command "仓库自检" "$REPO_ROOT/scripts/doctor.sh"
append_command "核心环境审计" "$REPO_ROOT/scripts/audit-environment.sh" --profile core --no-diff

append "## 人工记录"
append
append "失败点："
append
append "-"
append
append "人工步骤："
append
append "-"
append
append "最终结果："
append
append "- 通过 / 未通过"
append
append "后续改进："
append
append "-"

echo "==> 已生成恢复演练报告：$REPORT"
if [[ "$failures" -gt 0 ]]; then
  echo "==> $failures 项采集命令失败，请查看报告后补充人工记录。" >&2
  exit 1
fi
