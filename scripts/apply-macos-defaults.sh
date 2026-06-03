#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"
RESTART_APPS="${RESTART_APPS:-0}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.macos-dev-setup-backup/$(date +%Y%m%d-%H%M%S)}"

usage() {
  cat <<'EOF'
用法：scripts/apply-macos-defaults.sh [选项]

选项：
  --dry-run       只打印将执行的操作，不写入系统设置
  --restart-apps  写入后重启 Finder / Dock / SystemUIServer 使部分设置立即生效
  -h, --help      显示帮助

环境变量：
  DRY_RUN=1
  RESTART_APPS=1
  BACKUP_DIR      覆盖备份目录，默认 ~/.macos-dev-setup-backup/<时间戳>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --restart-apps)
      RESTART_APPS=1
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
setup_script_logging "apply-macos-defaults"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %s' "$@"
    printf '\n'
  else
    "$@"
  fi
}

backup_domain() {
  local domain="$1"
  local name="$2"
  local backup_file="$BACKUP_DIR/macos-defaults/$name.plist"

  echo "==> 备份 defaults 域：$domain"
  run mkdir -p "$(dirname "$backup_file")"

  if defaults export "$domain" - >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[dry-run] defaults export $domain $backup_file"
    else
      defaults export "$domain" "$backup_file"
    fi
  else
    echo "    skipped: 当前用户没有 $domain 的可导出设置"
  fi
}

write_default() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local value="$4"

  echo "==> $domain $key = $value"
  case "$type" in
    bool)
      run defaults write "$domain" "$key" -bool "$value"
      ;;
    int)
      run defaults write "$domain" "$key" -int "$value"
      ;;
    float)
      run defaults write "$domain" "$key" -float "$value"
      ;;
    string)
      run defaults write "$domain" "$key" -string "$value"
      ;;
    *)
      echo "未知 defaults 类型：$type" >&2
      exit 1
      ;;
  esac
}

echo "==> 应用可审计的 macOS 默认设置"
echo "==> 备份目录：$BACKUP_DIR"

backup_domain "NSGlobalDomain" "NSGlobalDomain"
backup_domain "com.apple.finder" "com.apple.finder"
backup_domain "com.apple.dock" "com.apple.dock"
backup_domain "com.apple.screencapture" "com.apple.screencapture"
backup_domain "com.apple.desktopservices" "com.apple.desktopservices"

echo "==> 全局行为"
write_default "NSGlobalDomain" "AppleShowAllExtensions" "bool" "true"
write_default "NSGlobalDomain" "ApplePressAndHoldEnabled" "bool" "false"
write_default "NSGlobalDomain" "KeyRepeat" "int" "2"
write_default "NSGlobalDomain" "InitialKeyRepeat" "int" "15"
write_default "NSGlobalDomain" "NSAutomaticCapitalizationEnabled" "bool" "false"
write_default "NSGlobalDomain" "NSAutomaticDashSubstitutionEnabled" "bool" "false"
write_default "NSGlobalDomain" "NSAutomaticPeriodSubstitutionEnabled" "bool" "false"
write_default "NSGlobalDomain" "NSAutomaticQuoteSubstitutionEnabled" "bool" "false"
write_default "NSGlobalDomain" "NSAutomaticSpellingCorrectionEnabled" "bool" "false"
write_default "NSGlobalDomain" "NSDocumentSaveNewDocumentsToCloud" "bool" "false"
write_default "NSGlobalDomain" "NSWindowResizeTime" "float" "0.001"

echo "==> Finder"
write_default "com.apple.finder" "AppleShowAllFiles" "bool" "true"
write_default "com.apple.finder" "FXDefaultSearchScope" "string" "SCcf"
write_default "com.apple.finder" "FXEnableExtensionChangeWarning" "bool" "false"
write_default "com.apple.finder" "ShowPathbar" "bool" "true"
write_default "com.apple.finder" "ShowStatusBar" "bool" "true"
write_default "com.apple.finder" "_FXSortFoldersFirst" "bool" "true"
write_default "com.apple.finder" "_FXSortFoldersFirstOnDesktop" "bool" "true"

echo "==> Dock"
write_default "com.apple.dock" "autohide" "bool" "true"
write_default "com.apple.dock" "show-recents" "bool" "false"
write_default "com.apple.dock" "tilesize" "int" "44"
write_default "com.apple.dock" "mru-spaces" "bool" "false"

echo "==> 截图与桌面服务"
write_default "com.apple.screencapture" "disable-shadow" "bool" "true"
write_default "com.apple.screencapture" "type" "string" "png"
write_default "com.apple.desktopservices" "DSDontWriteNetworkStores" "bool" "true"
write_default "com.apple.desktopservices" "DSDontWriteUSBStores" "bool" "true"

if [[ "$RESTART_APPS" == "1" ]]; then
  echo "==> 重启相关系统进程"
  run killall Finder
  run killall Dock
  run killall SystemUIServer
else
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "==> 预演完成。确认无误后去掉 --dry-run，或加 --restart-apps 立即重启相关系统进程。"
  else
    echo "==> 已写入。重新登录，或使用 --restart-apps 重启 Finder / Dock / SystemUIServer。"
  fi
fi
