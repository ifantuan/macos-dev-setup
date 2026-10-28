#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${PROFILE:-all}"
SHOW_DIFF="${SHOW_DIFF:-1}"
STRICT="${STRICT:-0}"

differences=0

usage() {
  cat <<'EOF'
用法：scripts/audit-environment.sh [选项]

选项：
  --profile <name>  检查 Brewfile 范围：core、full、work-example、personal-example 或 all，默认 all
  --no-diff         只输出文件是否一致，不输出统一 diff
  --strict          发现差异、缺失命令或缺失依赖时返回非零退出码
  -h, --help        显示帮助

环境变量：
  PROFILE=all
  SHOW_DIFF=1
  STRICT=0
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      if [[ $# -lt 2 ]]; then
        echo "--profile 需要参数：core、full、work-example、personal-example 或 all" >&2
        exit 1
      fi
      PROFILE="$2"
      shift 2
      ;;
    --no-diff)
      SHOW_DIFF=0
      shift
      ;;
    --strict)
      STRICT=1
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
  core|full|work-example|personal-example|all) ;;
  *)
    echo "未知 profile：$PROFILE。可选值：core, full, work-example, personal-example, all" >&2
    exit 1
    ;;
esac

section() {
  printf '\n## %s\n' "$1"
}

mark_difference() {
  differences=$((differences + 1))
}

command_version() {
  local command_name="$1"

  case "$command_name" in
    brew) brew --version | head -n 1 ;;
    git) git --version ;;
    gh) gh --version | head -n 1 ;;
    zsh) zsh --version ;;
    tmux) tmux -V ;;
    starship) starship --version | head -n 1 ;;
    fnm) fnm --version ;;
    pyenv) pyenv --version ;;
    uv) uv --version ;;
    pnpm) pnpm --version ;;
    bun) bun --version ;;
    node) node -v ;;
    python3) python3 --version ;;
    java) java -version 2>&1 | head -n 1 ;;
    mvn) mvn -v | head -n 1 ;;
    docker) docker --version ;;
    orb) orb --version 2>&1 | head -n 1 ;;
    ghostty) ghostty +version | head -n 1 ;;
    codex) codex --version 2>/dev/null | head -n 1 || codex -V 2>/dev/null | head -n 1 ;;
    claude) claude --version 2>/dev/null | head -n 1 || claude -v 2>/dev/null | head -n 1 ;;
    *) "$command_name" --version 2>/dev/null | head -n 1 ;;
  esac
}

audit_system() {
  section "系统概览"

  if command -v sw_vers >/dev/null 2>&1; then
    sw_vers
  else
    uname -a
  fi

  printf '架构：%s\n' "$(uname -m)"
  printf 'Shell：%s\n' "${SHELL:-未知}"
  printf '仓库：%s\n' "$REPO_ROOT"
}

audit_commands() {
  section "关键命令"

  local commands=(
    brew git gh zsh tmux starship
    fnm node pnpm bun
    pyenv uv python3
    java mvn
    docker orb
    ghostty codex claude
  )

  printf '%-12s %-8s %s\n' "命令" "状态" "版本"
  printf '%-12s %-8s %s\n' "----" "----" "----"

  local command_name
  for command_name in "${commands[@]}"; do
    if command -v "$command_name" >/dev/null 2>&1; then
      local version
      local version_status
      set +e
      version="$(command_version "$command_name")"
      version_status=$?
      set -e
      if [[ "$version_status" -eq 0 ]]; then
        if [[ -n "$version" ]]; then
          printf '%-12s %-8s %s\n' "$command_name" "ok" "$version"
        else
          printf '%-12s %-8s %s\n' "$command_name" "ok" "已安装，版本未知"
        fi
      else
        if [[ -z "$version" ]]; then
          version="版本探测失败"
        fi
        printf '%-12s %-8s %s\n' "$command_name" "version-error" "$version"
        mark_difference
      fi
    else
      printf '%-12s %-8s %s\n' "$command_name" "missing" "-"
      mark_difference
    fi
  done
}

audit_brewfile() {
  section "Homebrew 清单差异"

  if ! command -v brew >/dev/null 2>&1; then
    echo "未检测到 brew，无法和 Brewfile 对比。"
    mark_difference
    return
  fi

  local brewfiles=()
  case "$PROFILE" in
    core)
      brewfiles=("$REPO_ROOT/Brewfile.core")
      ;;
    full)
      brewfiles=("$REPO_ROOT/Brewfile")
      ;;
    work-example)
      brewfiles=("$REPO_ROOT/Brewfile.work.example")
      ;;
    personal-example)
      brewfiles=("$REPO_ROOT/Brewfile.personal.example")
      ;;
    all)
      brewfiles=("$REPO_ROOT/Brewfile.core" "$REPO_ROOT/Brewfile")
      ;;
  esac

  local brewfile
  for brewfile in "${brewfiles[@]}"; do
    printf '\n### %s\n' "$(basename "$brewfile")"
    if [[ "$brewfile" == *.example ]]; then
      if env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --file "$brewfile" --all >/dev/null 2>&1; then
        echo "示例清单可读取。示例 profile 不检查本机安装状态。"
      else
        echo "示例清单无法读取："
        env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --file "$brewfile" --all || true
        mark_difference
      fi
      continue
    fi

    if env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "$brewfile" --no-upgrade >/dev/null 2>&1; then
      echo "已满足仓库清单。"
    else
      echo "发现缺失的 Homebrew 依赖或清单检查错误："
      env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --verbose --file "$brewfile" --no-upgrade || true
      mark_difference
    fi
  done
}

audit_config_file() {
  local title="$1"
  local repo_file="$2"
  local local_file="$3"

  printf '\n### %s\n' "$title"
  printf '仓库文件：%s\n' "$repo_file"
  printf '本机文件：%s\n' "$local_file"

  if [[ ! -f "$repo_file" ]]; then
    echo "仓库文件不存在。"
    mark_difference
    return
  fi

  if [[ ! -f "$local_file" ]]; then
    echo "本机文件不存在。"
    mark_difference
    return
  fi

  if cmp -s "$repo_file" "$local_file"; then
    echo "一致。"
    return
  fi

  echo "存在差异。"
  mark_difference

  if [[ "$SHOW_DIFF" == "1" ]]; then
    diff -u \
      --label "仓库:$repo_file" \
      --label "本机:$local_file" \
      "$repo_file" \
      "$local_file" || true
  fi
}

audit_configs() {
  section "配置文件差异"

  audit_config_file "zsh" "$REPO_ROOT/configs/zsh/zshrc" "$HOME/.zshrc"
  audit_config_file "Ghostty" "$REPO_ROOT/configs/ghostty/config" "$HOME/.config/ghostty/config"
  audit_config_file "Starship" "$REPO_ROOT/configs/starship/starship.toml" "$HOME/.config/starship.toml"
  audit_config_file "tmux" "$REPO_ROOT/configs/tmux/tmux.conf" "$HOME/.tmux.conf"
}

read_default_value() {
  local domain="$1"
  local key="$2"
  defaults read "$domain" "$key" 2>/dev/null || true
}

normalize_default_value() {
  local type="$1"
  local value="$2"

  if [[ -z "$value" ]]; then
    echo "<未设置>"
    return
  fi

  case "$type" in
    bool)
      case "$value" in
        1|true|TRUE|YES|yes) echo "true" ;;
        0|false|FALSE|NO|no) echo "false" ;;
        *) echo "$value" ;;
      esac
      ;;
    *)
      echo "$value"
      ;;
  esac
}

audit_default_value() {
  local domain="$1"
  local key="$2"
  local type="$3"
  local expected="$4"
  local description="$5"
  local current

  current="$(normalize_default_value "$type" "$(read_default_value "$domain" "$key")")"
  if [[ "$current" == "$expected" ]]; then
    printf '%-8s %-34s %-42s 当前=%-10s 期望=%-10s %s\n' "ok" "$domain" "$key" "$current" "$expected" "$description"
  else
    printf '%-8s %-34s %-42s 当前=%-10s 期望=%-10s %s\n' "diff" "$domain" "$key" "$current" "$expected" "$description"
    mark_difference
  fi
}

audit_macos_defaults() {
  section "macOS defaults 差异"

  if ! command -v defaults >/dev/null 2>&1; then
    echo "当前系统没有 defaults 命令，跳过。"
    return
  fi

  audit_default_value "NSGlobalDomain" "AppleShowAllExtensions" "bool" "true" "显示所有扩展名"
  audit_default_value "NSGlobalDomain" "ApplePressAndHoldEnabled" "bool" "false" "按键长按不弹出重音菜单"
  audit_default_value "NSGlobalDomain" "KeyRepeat" "int" "2" "按键重复速度"
  audit_default_value "NSGlobalDomain" "InitialKeyRepeat" "int" "15" "按键重复前延迟"
  audit_default_value "NSGlobalDomain" "NSAutomaticCapitalizationEnabled" "bool" "false" "关闭自动大写"
  audit_default_value "NSGlobalDomain" "NSAutomaticDashSubstitutionEnabled" "bool" "false" "关闭破折号替换"
  audit_default_value "NSGlobalDomain" "NSAutomaticPeriodSubstitutionEnabled" "bool" "false" "关闭句号替换"
  audit_default_value "NSGlobalDomain" "NSAutomaticQuoteSubstitutionEnabled" "bool" "false" "关闭智能引号"
  audit_default_value "NSGlobalDomain" "NSAutomaticSpellingCorrectionEnabled" "bool" "false" "关闭拼写自动纠正"
  audit_default_value "NSGlobalDomain" "NSDocumentSaveNewDocumentsToCloud" "bool" "false" "默认不保存到 iCloud"
  audit_default_value "NSGlobalDomain" "NSWindowResizeTime" "float" "0.001" "窗口缩放动画"
  audit_default_value "com.apple.finder" "AppleShowAllFiles" "bool" "true" "Finder 显示隐藏文件"
  audit_default_value "com.apple.finder" "FXDefaultSearchScope" "string" "SCcf" "Finder 搜索当前目录"
  audit_default_value "com.apple.finder" "FXEnableExtensionChangeWarning" "bool" "false" "关闭扩展名修改警告"
  audit_default_value "com.apple.finder" "ShowPathbar" "bool" "true" "显示路径栏"
  audit_default_value "com.apple.finder" "ShowStatusBar" "bool" "true" "显示状态栏"
  audit_default_value "com.apple.finder" "_FXSortFoldersFirst" "bool" "true" "文件夹优先排序"
  audit_default_value "com.apple.finder" "_FXSortFoldersFirstOnDesktop" "bool" "true" "桌面文件夹优先排序"
  audit_default_value "com.apple.dock" "autohide" "bool" "true" "自动隐藏 Dock"
  audit_default_value "com.apple.dock" "show-recents" "bool" "false" "不显示最近应用"
  audit_default_value "com.apple.dock" "tilesize" "int" "44" "Dock 图标尺寸"
  audit_default_value "com.apple.dock" "mru-spaces" "bool" "false" "不按最近使用重排 Spaces"
  audit_default_value "com.apple.screencapture" "disable-shadow" "bool" "true" "截图禁用窗口阴影"
  audit_default_value "com.apple.screencapture" "type" "string" "png" "截图格式"
  audit_default_value "com.apple.desktopservices" "DSDontWriteNetworkStores" "bool" "true" "网络盘不写 .DS_Store"
  audit_default_value "com.apple.desktopservices" "DSDontWriteUSBStores" "bool" "true" "USB 盘不写 .DS_Store"
}

main() {
  audit_system
  audit_commands
  audit_brewfile
  audit_configs
  audit_macos_defaults

  section "汇总"
  if [[ "$differences" -eq 0 ]]; then
    echo "未发现本机环境和仓库声明之间的差异。"
  else
    echo "发现 $differences 处差异或缺失。"
    echo "这不一定表示错误：如果是有意的本机差异，可保留；如果要同步到仓库，可先运行 ./scripts/sync-back.sh --dry-run。"
    echo "安全提示：配置文件 diff 可能包含本机路径、代理或 token，公开粘贴前请先审查。"
  fi

  if [[ "$STRICT" == "1" && "$differences" -gt 0 ]]; then
    exit 1
  fi
}

main
