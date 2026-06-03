#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.macos-dev-setup-backup/$(date +%Y%m%d-%H%M%S)}"
SKIP_BREW="${SKIP_BREW:-0}"
DRY_RUN="${DRY_RUN:-0}"
PROFILE="${PROFILE:-core}"
BREW_NO_UPGRADE="${BREW_NO_UPGRADE:-1}"
PROFILE_IS_EXAMPLE=0

usage() {
  cat <<'EOF'
用法：scripts/bootstrap.sh [选项]

选项：
  --profile <name>  选择安装清单：core、full、work-example 或 personal-example，默认 core
  --skip-brew   跳过 brew bundle，只写入配置文件
  --dry-run     只打印将执行的操作，不写入文件、不安装软件
  --upgrade     安装 Homebrew 清单时允许升级过期依赖
  -h, --help    显示帮助

环境变量：
  BACKUP_DIR    覆盖备份目录，默认 ~/.macos-dev-setup-backup/<时间戳>
  PROFILE=core   等同 --profile core
  SKIP_BREW=1   等同 --skip-brew
  DRY_RUN=1     等同 --dry-run
  BREW_NO_UPGRADE=1  默认不主动升级已安装依赖
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      if [[ $# -lt 2 ]]; then
        echo "--profile 需要参数：core、full、work-example 或 personal-example" >&2
        exit 1
      fi
      PROFILE="$2"
      shift 2
      ;;
    --skip-brew)
      SKIP_BREW=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --upgrade)
      BREW_NO_UPGRADE=0
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
setup_script_logging "bootstrap"

case "$PROFILE" in
  core)
    BREWFILE="$REPO_ROOT/Brewfile.core"
    ;;
  full)
    BREWFILE="$REPO_ROOT/Brewfile"
    ;;
  work-example)
    BREWFILE="$REPO_ROOT/Brewfile.work.example"
    PROFILE_IS_EXAMPLE=1
    ;;
  personal-example)
    BREWFILE="$REPO_ROOT/Brewfile.personal.example"
    PROFILE_IS_EXAMPLE=1
    ;;
  *)
    echo "未知 profile：$PROFILE。可选值：core, full, work-example, personal-example" >&2
    exit 1
    ;;
esac

if [[ "$PROFILE_IS_EXAMPLE" == "1" && "$DRY_RUN" != "1" ]]; then
  echo "profile $PROFILE 是公开示例，只允许 --dry-run。真实工作/个人差异请放在本机或私有仓库。" >&2
  exit 1
fi

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %s' "$@"
    printf '\n'
  else
    "$@"
  fi
}

# 覆盖用户配置前先按原路径备份，便于回滚到脚本执行前状态。
backup_file() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local relative="${target#$HOME/}"
    local backup_target="$BACKUP_DIR/$relative"
    echo "==> 备份 $target -> $backup_target"
    run mkdir -p "$(dirname "$backup_target")"
    run cp -R "$target" "$backup_target"
  fi
}

# bootstrap 只负责 Homebrew 清单和 dotfiles 落位，语言运行时交给 install-runtimes.sh。
if [[ "$SKIP_BREW" != "1" ]] && ! command -v brew >/dev/null 2>&1; then
  echo "未检测到 Homebrew。请先安装 Homebrew 后再运行本脚本。" >&2
  exit 1
fi

if [[ "$SKIP_BREW" != "1" ]]; then
  echo "==> 安装 Homebrew 软件清单：$PROFILE ($BREWFILE)"
  brew_args=(bundle --file "$BREWFILE" --verbose)
  if [[ "$BREW_NO_UPGRADE" == "1" ]]; then
    brew_args+=(--no-upgrade)
  fi
  run brew "${brew_args[@]}"
else
  echo "==> 跳过 Homebrew 软件安装"
fi

echo "==> 写入 zsh 配置"
backup_file "$HOME/.zshrc"
run cp "$REPO_ROOT/configs/zsh/zshrc" "$HOME/.zshrc"

echo "==> 写入 Ghostty 配置"
backup_file "$HOME/.config/ghostty/config"
run mkdir -p "$HOME/.config/ghostty"
run cp "$REPO_ROOT/configs/ghostty/config" "$HOME/.config/ghostty/config"

echo "==> 写入 Starship 配置"
backup_file "$HOME/.config/starship.toml"
run mkdir -p "$HOME/.config"
run cp "$REPO_ROOT/configs/starship/starship.toml" "$HOME/.config/starship.toml"

echo "==> 写入 tmux 配置"
backup_file "$HOME/.tmux.conf"
run cp "$REPO_ROOT/configs/tmux/tmux.conf" "$HOME/.tmux.conf"

echo "==> 完成。重新打开终端，或执行：source ~/.zshrc"
