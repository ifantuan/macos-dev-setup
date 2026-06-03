#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP_HOME="${KEEP_HOME:-0}"
TMP_HOME=""

usage() {
  cat <<'EOF'
用法：scripts/drill-clean-home.sh [选项]

选项：
  --keep-home  保留临时 HOME，便于人工检查
  -h, --help   显示帮助

环境变量：
  KEEP_HOME=1  等同 --keep-home
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-home)
      KEEP_HOME=1
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

cleanup() {
  if [[ -n "$TMP_HOME" && "$KEEP_HOME" != "1" ]]; then
    rm -rf "$TMP_HOME"
  elif [[ -n "$TMP_HOME" ]]; then
    echo "==> 保留临时 HOME：$TMP_HOME"
  fi
}

trap cleanup EXIT

TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/macos-dev-setup-home.XXXXXX")"
export HOME="$TMP_HOME"

echo "==> 使用临时 HOME：$HOME"
mkdir -p "$HOME"

assert_matches() {
  local repo_file="$1"
  local target_file="$2"

  if [[ ! -f "$target_file" ]]; then
    echo "缺少目标文件：$target_file" >&2
    exit 1
  fi

  if ! cmp -s "$repo_file" "$target_file"; then
    echo "目标文件和仓库配置不一致：$target_file" >&2
    diff -u "$repo_file" "$target_file" || true
    exit 1
  fi
}

echo "==> 写入核心配置到临时 HOME"
"$REPO_ROOT/scripts/bootstrap.sh" --skip-brew
assert_matches "$REPO_ROOT/configs/zsh/zshrc" "$HOME/.zshrc"
assert_matches "$REPO_ROOT/configs/ghostty/config" "$HOME/.config/ghostty/config"
assert_matches "$REPO_ROOT/configs/starship/starship.toml" "$HOME/.config/starship.toml"
assert_matches "$REPO_ROOT/configs/tmux/tmux.conf" "$HOME/.tmux.conf"

echo "==> 检查写入型脚本在空 HOME 下的预演"
"$REPO_ROOT/scripts/apply-macos-defaults.sh" --dry-run
"$REPO_ROOT/scripts/sync-back.sh" --dry-run

echo "==> 检查示例 profile 预演"
"$REPO_ROOT/scripts/bootstrap.sh" --profile work-example --dry-run
"$REPO_ROOT/scripts/bootstrap.sh" --profile personal-example --dry-run

echo "==> 检查仓库自检"
CHECK_BREW_READABLE=0 "$REPO_ROOT/scripts/doctor.sh"

echo "==> 干净 HOME 半恢复演练通过"
