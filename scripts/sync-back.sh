#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"
INCLUDE_BREW="${INCLUDE_BREW:-0}"

usage() {
  cat <<'EOF'
用法：scripts/sync-back.sh [选项]

选项：
  --dry-run       只打印将同步的文件，不写入仓库
  --include-brew  同步当前机器的完整 Brewfile 快照
  -h, --help      显示帮助

环境变量：
  DRY_RUN=1
  INCLUDE_BREW=1
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --include-brew)
      INCLUDE_BREW=1
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
setup_script_logging "sync-back"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %s' "$@"
    printf '\n'
  else
    "$@"
  fi
}

sync_file() {
  local source="$1"
  local target="$2"

  if [[ ! -e "$source" ]]; then
    echo "==> 跳过：$source 不存在"
    return
  fi

  echo "==> 同步 $source -> $target"
  run mkdir -p "$(dirname "$target")"
  run cp "$source" "$target"
}

echo "==> 同步本机配置回仓库"

sync_file "$HOME/.zshrc" "$REPO_ROOT/configs/zsh/zshrc"
sync_file "$HOME/.config/ghostty/config" "$REPO_ROOT/configs/ghostty/config"
sync_file "$HOME/.config/starship.toml" "$REPO_ROOT/configs/starship/starship.toml"
sync_file "$HOME/.tmux.conf" "$REPO_ROOT/configs/tmux/tmux.conf"

if [[ "$INCLUDE_BREW" == "1" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "缺少 brew，无法导出 Brewfile" >&2
    exit 1
  fi
  echo "==> 导出完整 Brewfile"
  run brew bundle dump --file "$REPO_ROOT/Brewfile" --force --describe
else
  echo "==> 跳过 Brewfile 导出。需要同步软件清单时加 --include-brew。"
fi

echo "==> 同步完成。请检查 git diff 后再提交。"
