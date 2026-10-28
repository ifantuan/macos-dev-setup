#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="${BACKUP_DIR:-$HOME/.macos-dev-setup-backup}"
BACKUP_BATCH=""
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
  BACKUP_DIR    覆盖备份根目录，每次执行在其中创建独立批次
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
# shellcheck source=scripts/lib/files.sh
source "$REPO_ROOT/scripts/lib/files.sh"
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

# 在所有写入前检查目标：异常路径直接拒绝（返回 1）；父目录为链接时多由 dotfiles 工具管理，
# 跳过该项（返回 2），既不写穿链接，也不阻断软件安装和其他配置。
validate_target() {
  local target="$1"
  local parent
  if [[ -d "$target" || ( -e "$target" && ! -f "$target" ) ]]; then
    echo "配置目标不是普通文件：$target" >&2
    return 1
  fi
  parent="$(dirname "$target")"
  while [[ "$parent" != "$HOME" && "$parent" != "/" ]]; do
    if [[ -L "$parent" && -d "$parent" ]]; then
      echo "==> 将跳过 $target：父目录 $parent 是指向 $(readlink "$parent") 的链接，可能由其他工具管理。如需由本仓库接管，先将其替换为普通目录。" >&2
      return 2
    fi
    if [[ -L "$parent" || ( -e "$parent" && ! -d "$parent" ) ]]; then
      echo "配置父路径不是可用目录，请先人工处理：$parent" >&2
      return 1
    fi
    parent="$(dirname "$parent")"
  done
}

# 同一根目录可重复使用，每次备份都保留独立的文件和链接内容快照。
backup_file() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ -z "$BACKUP_BATCH" ]]; then
      if [[ "$DRY_RUN" == "1" ]]; then
        BACKUP_BATCH="$BACKUP_ROOT/<独立批次>"
      else
        mkdir -p "$BACKUP_ROOT"
        BACKUP_BATCH="$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S).XXXXXX")"
      fi
    fi
    local relative="${target#"$HOME"/}"
    local backup_target="$BACKUP_BATCH/$relative"
    echo "==> 备份 $target -> $backup_target"
    run mkdir -p "$(dirname "$backup_target")"
    run cp -PR "$target" "$backup_target"
    if [[ -L "$target" && -f "$target" ]]; then
      run mkdir -p "$(dirname "$BACKUP_BATCH/link-targets/$relative")"
      run cp -pL "$target" "$BACKUP_BATCH/link-targets/$relative"
    fi
  fi
}

install_config() {
  local source="$1"
  local target="$2"
  if [[ "$SKIPPED_TARGETS" == *"|$target|"* ]]; then
    echo "==> 跳过 $target：父目录为链接"
    return 0
  fi
  backup_file "$target"
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] 原子替换 %s -> %s\n' "$source" "$target"
  else
    write_file_atomically "$target" copy_file_contents "$source"
  fi
}

SKIPPED_TARGETS=""
skipped_count=0
for target in "$HOME/.zshrc" "$HOME/.config/ghostty/config" "$HOME/.config/starship.toml" "$HOME/.tmux.conf"; do
  status=0
  validate_target "$target" || status=$?
  if [[ "$status" -eq 2 ]]; then
    SKIPPED_TARGETS="$SKIPPED_TARGETS|$target|"
    skipped_count=$((skipped_count + 1))
  elif [[ "$status" -ne 0 ]]; then
    exit 1
  fi
done

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
  else
    brew_args+=(--upgrade)
  fi
  run brew "${brew_args[@]}"
else
  echo "==> 跳过 Homebrew 软件安装"
fi

echo "==> 写入 zsh 配置"
install_config "$REPO_ROOT/configs/zsh/zshrc" "$HOME/.zshrc"

echo "==> 写入 Ghostty 配置"
install_config "$REPO_ROOT/configs/ghostty/config" "$HOME/.config/ghostty/config"

echo "==> 写入 Starship 配置"
install_config "$REPO_ROOT/configs/starship/starship.toml" "$HOME/.config/starship.toml"

echo "==> 写入 tmux 配置"
install_config "$REPO_ROOT/configs/tmux/tmux.conf" "$HOME/.tmux.conf"

if [[ "$skipped_count" -gt 0 ]]; then
  echo "==> 已跳过 $skipped_count 项父目录为链接的配置，请在对应的 dotfiles 管理工具中维护。"
fi
echo "==> 完成。重新打开终端，或执行：source ~/.zshrc"
