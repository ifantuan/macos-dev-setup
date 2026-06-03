#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${PROFILE:-full}"
ACTION="${ACTION:-check}"
BREW_NO_UPGRADE="${BREW_NO_UPGRADE:-1}"
CONFIRM_CLEANUP="${CONFIRM_CLEANUP:-0}"

usage() {
  cat <<'EOF'
用法：scripts/brew-maintenance.sh [选项]

选项：
  --profile <name>      选择清单：core 或 full，默认 full
  --check               检查清单是否已满足，默认动作
  --install             按清单安装；默认加 --no-upgrade
  --upgrade             与 --install 搭配使用，允许升级过期依赖
  --cleanup-preview     预演移除不在清单中的依赖，不会删除
  --cleanup-force       真正移除不在清单中的依赖，执行前必须人工确认
  --yes                 与 --cleanup-force 搭配使用，跳过交互确认
  -h, --help            显示帮助

环境变量：
  PROFILE=full
  ACTION=check
  BREW_NO_UPGRADE=1     安装时默认不主动升级已安装依赖
  CONFIRM_CLEANUP=1     跳过 cleanup-force 的交互确认
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      if [[ $# -lt 2 ]]; then
        echo "--profile 需要参数：core 或 full" >&2
        exit 1
      fi
      PROFILE="$2"
      shift 2
      ;;
    --check)
      ACTION="check"
      shift
      ;;
    --install)
      ACTION="install"
      shift
      ;;
    --upgrade)
      BREW_NO_UPGRADE=0
      shift
      ;;
    --cleanup-preview)
      ACTION="cleanup-preview"
      shift
      ;;
    --cleanup-force)
      ACTION="cleanup-force"
      shift
      ;;
    --yes)
      CONFIRM_CLEANUP=1
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
  core)
    BREWFILE="$REPO_ROOT/Brewfile.core"
    ;;
  full)
    BREWFILE="$REPO_ROOT/Brewfile"
    ;;
  *)
    echo "未知 profile：$PROFILE。可选值：core, full" >&2
    exit 1
    ;;
esac

if ! command -v brew >/dev/null 2>&1; then
  echo "未检测到 Homebrew。请先安装 Homebrew 后再运行本脚本。" >&2
  exit 1
fi

case "$ACTION" in
  check)
    env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "$BREWFILE"
    ;;
  install)
    brew_args=(bundle install --file "$BREWFILE" --verbose)
    if [[ "$BREW_NO_UPGRADE" == "1" ]]; then
      brew_args+=(--no-upgrade)
    fi
    brew "${brew_args[@]}"
    ;;
  cleanup-preview)
    set +e
    env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle cleanup --file "$BREWFILE"
    status=$?
    set -e
    if [[ "$status" -eq 0 ]]; then
      echo "==> 无需清理。"
    elif [[ "$status" -eq 1 ]]; then
      echo "==> 以上是清理预演，未删除任何依赖。确认后再执行："
      echo "    ./scripts/brew-maintenance.sh --profile $PROFILE --cleanup-force"
    else
      exit "$status"
    fi
    ;;
  cleanup-force)
    echo "==> 将移除不在 $(basename "$BREWFILE") 中的 Homebrew 依赖"
    if [[ "$CONFIRM_CLEANUP" != "1" ]]; then
      if [[ ! -t 0 ]]; then
        echo "非交互环境中必须设置 CONFIRM_CLEANUP=1 或加 --yes 才能执行强制清理。" >&2
        exit 1
      fi
      read -r -p "输入 cleanup 确认继续： " answer
      if [[ "$answer" != "cleanup" ]]; then
        echo "已取消清理。"
        exit 1
      fi
    fi
    brew bundle cleanup --file "$BREWFILE" --force
    ;;
  *)
    echo "未知动作：$ACTION" >&2
    exit 1
    ;;
esac
