#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${DRY_RUN:-0}"
INCLUDE_SENSITIVE="${INCLUDE_SENSITIVE:-0}"
ALLOW_SENSITIVE_CONTENT="${ALLOW_SENSITIVE_CONTENT:-0}"
INTERACTIVE="${INTERACTIVE:-0}"
SELECT_ALL=0
SELECT_SAFE=0
SHOW_LIST=0
selection_errors=0
copied=0
skipped=0
failures=0

SELECTED_ITEMS=()
EXCLUDED_ITEMS=()

# 配置项格式：
#   名称|风险级别|备份类型|本机源路径|仓库目标路径|说明
# 字段说明：
#   名称：命令行 --items 使用的唯一标识。
#   风险级别：normal 表示默认可备份；sensitive 表示需显式加 --include-sensitive。
#   备份类型：file、dir、zsh-file、json-file、xml-file、brew、vscode-extensions。
#   本机源路径：普通文件或目录的来源；无需源路径的导出型配置用 _ 占位。
#   仓库目标路径：备份后写入仓库的位置。
#   说明：--list 输出给用户看的简短描述。
CATALOG_ENTRIES=(
  "zsh|normal|zsh-file|$HOME/.zshrc|$REPO_ROOT/configs/zsh/zshrc|zsh 主配置"
  "ghostty|normal|file|$HOME/.config/ghostty/config|$REPO_ROOT/configs/ghostty/config|Ghostty 终端配置"
  "starship|normal|file|$HOME/.config/starship.toml|$REPO_ROOT/configs/starship/starship.toml|Starship 提示符配置"
  "tmux|normal|file|$HOME/.tmux.conf|$REPO_ROOT/configs/tmux/tmux.conf|tmux 配置"
  "vscode-settings|normal|json-file|$HOME/Library/Application Support/Code/User/settings.json|$REPO_ROOT/configs/vscode/settings.json.example|VS Code 用户设置模板"
  "vscode-extensions|normal|vscode-extensions|_|$REPO_ROOT/configs/vscode/extensions.txt.example|VS Code 扩展清单"
  "brew|normal|brew|_|$REPO_ROOT/Brewfile|Homebrew 完整清单"
  "git|sensitive|file|$HOME/.gitconfig|$REPO_ROOT/configs/git/gitconfig.example|Git 用户配置模板"
  "ssh|sensitive|file|$HOME/.ssh/config|$REPO_ROOT/configs/ssh/config.example|SSH 客户端配置模板"
  "npm|sensitive|file|$HOME/.npmrc|$REPO_ROOT/configs/npm/npmrc.example|npm 配置模板"
  "pip|sensitive|file|$HOME/.pip/pip.conf|$REPO_ROOT/configs/pip/pip.conf.example|pip 配置模板"
  "maven|sensitive|xml-file|$HOME/.m2/settings.xml|$REPO_ROOT/configs/maven/settings.xml.example|Maven settings 模板"
  "squirrel-app|sensitive|dir|$HOME/Library/Rime|$REPO_ROOT/configs/squirrel/rime|Squirrel/Rime 输入法配置目录"
)

usage() {
  cat <<'EOF'
用法：scripts/backup-configs.sh [选项]

选项：
  --list                       列出可备份的软件配置项
  --items <names>              备份指定项，多个名称用逗号或空格分隔
  --safe                       备份默认安全项，不包含敏感配置
  --all                        备份全部普通项；敏感项需额外加 --include-sensitive
  --exclude <names>            从已选择项中排除指定项
  --include-sensitive          允许备份 Git、SSH、npm、pip、Maven、Squirrel 等敏感配置项
  --allow-sensitive-content    关闭敏感字段提示；仍建议提交前审查 git diff
  --interactive                交互式选择要备份的配置项
  --dry-run                    只打印将执行的操作，不写入仓库
  -h, --help                   显示帮助

示例：
  ./scripts/backup-configs.sh --list
  ./scripts/backup-configs.sh --items zsh,ghostty,tmux
  ./scripts/backup-configs.sh --safe --dry-run
  ./scripts/backup-configs.sh --items git,ssh --include-sensitive

环境变量：
  DRY_RUN=1
  INCLUDE_SENSITIVE=1
  ALLOW_SENSITIVE_CONTENT=1
  INTERACTIVE=1
EOF
}

parse_entry() {
  local entry="$1"
  IFS='|' read -r ENTRY_NAME ENTRY_RISK ENTRY_KIND ENTRY_SOURCE ENTRY_TARGET ENTRY_DESCRIPTION <<< "$entry"
}

entry_for_name() {
  local wanted="$1"
  local entry

  for entry in "${CATALOG_ENTRIES[@]}"; do
    parse_entry "$entry"
    if [[ "$ENTRY_NAME" == "$wanted" ]]; then
      printf '%s\n' "$entry"
      return 0
    fi
  done

  return 1
}

contains_item() {
  local wanted="$1"
  shift
  local item

  for item in "$@"; do
    if [[ "$item" == "$wanted" ]]; then
      return 0
    fi
  done

  return 1
}

selected_contains() {
  local wanted="$1"
  local index

  for ((index = 0; index < ${#SELECTED_ITEMS[@]}; index++)); do
    if [[ "${SELECTED_ITEMS[$index]}" == "$wanted" ]]; then
      return 0
    fi
  done

  return 1
}

excluded_contains() {
  local wanted="$1"
  local index

  for ((index = 0; index < ${#EXCLUDED_ITEMS[@]}; index++)); do
    if [[ "${EXCLUDED_ITEMS[$index]}" == "$wanted" ]]; then
      return 0
    fi
  done

  return 1
}

add_selected_item() {
  local item="$1"

  [[ -n "$item" ]] || return 0

  case "$item" in
    all)
      SELECT_ALL=1
      return 0
      ;;
    safe)
      SELECT_SAFE=1
      return 0
      ;;
  esac

  if ! entry_for_name "$item" >/dev/null; then
    echo "未知配置项：$item" >&2
    selection_errors=1
    return 0
  fi

  if ! selected_contains "$item"; then
    SELECTED_ITEMS+=("$item")
  fi
}

add_excluded_item() {
  local item="$1"

  [[ -n "$item" ]] || return 0

  if ! entry_for_name "$item" >/dev/null; then
    echo "未知排除项：$item" >&2
    selection_errors=1
    return 0
  fi

  if ! excluded_contains "$item"; then
    EXCLUDED_ITEMS+=("$item")
  fi
}

add_items_from_text() {
  local raw="${1//,/ }"
  local item

  for item in $raw; do
    add_selected_item "$item"
  done
}

add_excludes_from_text() {
  local raw="${1//,/ }"
  local item

  for item in $raw; do
    add_excluded_item "$item"
  done
}

list_entries() {
  local entry

  printf '%-20s %-10s %-52s %s\n' "名称" "风险" "写入仓库位置" "说明"
  printf '%-20s %-10s %-52s %s\n' "----" "----" "------------" "----"
  for entry in "${CATALOG_ENTRIES[@]}"; do
    parse_entry "$entry"
    printf '%-20s %-10s %-52s %s\n' "$ENTRY_NAME" "$ENTRY_RISK" "${ENTRY_TARGET#"$REPO_ROOT"/}" "$ENTRY_DESCRIPTION"
  done
}

select_safe_items() {
  local entry

  for entry in "${CATALOG_ENTRIES[@]}"; do
    parse_entry "$entry"
    if [[ "$ENTRY_RISK" == "normal" ]]; then
      add_selected_item "$ENTRY_NAME"
    fi
  done
}

select_all_items() {
  local entry

  for entry in "${CATALOG_ENTRIES[@]}"; do
    parse_entry "$entry"
    if [[ "$ENTRY_RISK" == "sensitive" && "$INCLUDE_SENSITIVE" != "1" ]]; then
      echo "==> 跳过敏感项 $ENTRY_NAME。需要备份时加 --include-sensitive。"
      continue
    fi
    add_selected_item "$ENTRY_NAME"
  done
}

filter_excluded_items() {
  local filtered=()
  local item
  local index

  for ((index = 0; index < ${#SELECTED_ITEMS[@]}; index++)); do
    item="${SELECTED_ITEMS[$index]}"
    if excluded_contains "$item"; then
      echo "==> 已排除：$item"
      continue
    fi
    filtered+=("$item")
  done

  SELECTED_ITEMS=()
  for ((index = 0; index < ${#filtered[@]}; index++)); do
    SELECTED_ITEMS+=("${filtered[$index]}")
  done
}

validate_sensitive_selection() {
  local item
  local entry
  local has_error=0
  local index

  for ((index = 0; index < ${#SELECTED_ITEMS[@]}; index++)); do
    item="${SELECTED_ITEMS[$index]}"
    entry="$(entry_for_name "$item")"
    parse_entry "$entry"
    if [[ "$ENTRY_RISK" == "sensitive" && "$INCLUDE_SENSITIVE" != "1" ]]; then
      echo "配置项 ${item} 可能包含账号、token、内网地址或私钥路径；如确认要备份，请加 --include-sensitive。" >&2
      has_error=1
    fi
  done

  if [[ "$has_error" == "1" ]]; then
    exit 1
  fi
}

run_mkdir_parent() {
  local target="$1"

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] mkdir -p %s\n' "$(dirname "$target")"
  else
    mkdir -p "$(dirname "$target")"
  fi
}

scan_sensitive_words() {
  local source="$1"

  if [[ "$ALLOW_SENSITIVE_CONTENT" == "1" || ! -f "$source" ]]; then
    return 0
  fi

  if LC_ALL=C grep -Eiq '(token|password|passwd|secret|api[_-]?key|access[_-]?key|_authToken|client_secret|credential|BEGIN[[:space:]][A-Z0-9[:space:]]*PRIVATE[[:space:]]KEY|https?://[^[:space:]]+:[^[:space:]@]+@)' "$source"; then
    echo "    warning: $source 可能包含敏感字段，请在提交前仔细审查 git diff。" >&2
  fi
}

scan_sensitive_dir() {
  local source="$1"
  local matched=""

  if [[ "$ALLOW_SENSITIVE_CONTENT" == "1" || ! -d "$source" ]]; then
    return 0
  fi

  set +e
  matched="$(LC_ALL=C grep -REil '(token|password|passwd|secret|api[_-]?key|access[_-]?key|_authToken|client_secret|credential|BEGIN[[:space:]][A-Z0-9[:space:]]*PRIVATE[[:space:]]KEY|https?://[^[:space:]]+:[^[:space:]@]+@)' "$source" 2>/dev/null | head -n 5)"
  set -e

  if [[ -n "$matched" ]]; then
    echo "    warning: $source 内部分文件可能包含敏感字段，请在提交前仔细审查 git diff。" >&2
    printf '%s\n' "$matched" >&2
  fi
}

validate_source_file() {
  local name="$1"
  local kind="$2"
  local source="$3"

  case "$kind" in
    zsh-file)
      if command -v zsh >/dev/null 2>&1; then
        if ! zsh -n "$source"; then
          echo "    failed: $name 源文件语法检查失败，已跳过。" >&2
          return 1
        fi
      fi
      ;;
    json-file)
      if ! command -v python3 >/dev/null 2>&1; then
        echo "    failed: 缺少 python3，无法验证 $name 是否为标准 JSON。" >&2
        return 1
      fi
      if ! python3 - "$source" <<'PY'
from pathlib import Path
import json
import sys

json.loads(Path(sys.argv[1]).read_text())
PY
      then
        echo "    failed: $name 不是标准 JSON。请先移除 JSONC 注释或尾逗号后再备份。" >&2
        return 1
      fi
      ;;
    xml-file)
      if ! command -v python3 >/dev/null 2>&1; then
        echo "    failed: 缺少 python3，无法验证 $name 是否为 XML。" >&2
        return 1
      fi
      if ! python3 - "$source" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ET.parse(Path(sys.argv[1]))
PY
      then
        echo "    failed: $name 不是有效 XML，已跳过。" >&2
        return 1
      fi
      ;;
  esac
}

backup_file_item() {
  local name="$1"
  local kind="$2"
  local source="$3"
  local target="$4"

  if [[ ! -e "$source" ]]; then
    echo "==> 跳过 ${name}：${source} 不存在"
    skipped=$((skipped + 1))
    return 0
  fi

  if [[ ! -f "$source" ]]; then
    echo "==> 失败 ${name}：${source} 不是普通文件" >&2
    failures=$((failures + 1))
    return 0
  fi

  if ! validate_source_file "$name" "$kind" "$source"; then
    failures=$((failures + 1))
    return 0
  fi

  scan_sensitive_words "$source"
  echo "==> 备份 ${name}：${source} -> ${target#"$REPO_ROOT"/}"
  run_mkdir_parent "$target"
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] cp %s %s\n' "$source" "$target"
  else
    if ! write_file_atomically "$target" copy_file_contents "$source"; then
      echo "==> 失败 ${name}：写入失败，已保留旧文件。" >&2
      failures=$((failures + 1))
      return 0
    fi
  fi
  copied=$((copied + 1))
}

backup_dir_item() {
  local name="$1"
  local source="$2"
  local target="$3"

  if [[ ! -e "$source" ]]; then
    echo "==> 跳过 ${name}：${source} 不存在"
    skipped=$((skipped + 1))
    return 0
  fi

  if [[ ! -d "$source" ]]; then
    echo "==> 失败 ${name}：${source} 不是目录" >&2
    failures=$((failures + 1))
    return 0
  fi

  scan_sensitive_dir "$source"
  echo "==> 备份 ${name}：${source} -> ${target#"$REPO_ROOT"/}"
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] mkdir -p %s\n' "$target"
    printf '[dry-run] cp -R %s/. %s\n' "$source" "$target"
  else
    mkdir -p "$target"
    cp -R "$source"/. "$target"
  fi
  copied=$((copied + 1))
}

backup_brew_item() {
  local target="$1"

  if [[ "$DRY_RUN" != "1" ]] && ! command -v brew >/dev/null 2>&1; then
    echo "==> 失败 brew：未检测到 Homebrew" >&2
    failures=$((failures + 1))
    return 0
  fi

  echo "==> 备份 brew：导出完整 Brewfile -> ${target#"$REPO_ROOT"/}"
  run_mkdir_parent "$target"
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] 导出并校验 Brewfile 后原子替换 %s\n' "$target"
  else
    if ! write_file_atomically "$target" export_brewfile_contents; then
      echo "==> 失败 brew：导出或校验失败，已保留旧清单。" >&2
      failures=$((failures + 1))
      return 0
    fi
  fi
  copied=$((copied + 1))
}

backup_vscode_extensions_item() {
  local target="$1"
  local code_cmd=""

  if command -v code >/dev/null 2>&1; then
    code_cmd="code"
  fi

  if [[ -z "$code_cmd" && "$DRY_RUN" != "1" ]]; then
    echo "==> 失败 vscode-extensions：未检测到 code 命令" >&2
    failures=$((failures + 1))
    return 0
  fi
  if [[ -z "$code_cmd" ]]; then
    code_cmd="code"
  fi

  echo "==> 备份 vscode-extensions：导出 VS Code 扩展清单 -> ${target#"$REPO_ROOT"/}"
  run_mkdir_parent "$target"
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] %s --list-extensions | sort > %s\n' "$code_cmd" "$target"
  else
    if ! write_file_atomically "$target" export_extension_contents "$code_cmd"; then
      echo "==> 失败 vscode-extensions：导出失败，已保留旧清单。" >&2
      failures=$((failures + 1))
      return 0
    fi
  fi
  copied=$((copied + 1))
}

backup_item() {
  local item="$1"
  local entry

  entry="$(entry_for_name "$item")"
  parse_entry "$entry"

  case "$ENTRY_KIND" in
    file|zsh-file|json-file|xml-file)
      backup_file_item "$ENTRY_NAME" "$ENTRY_KIND" "$ENTRY_SOURCE" "$ENTRY_TARGET"
      ;;
    dir)
      backup_dir_item "$ENTRY_NAME" "$ENTRY_SOURCE" "$ENTRY_TARGET"
      ;;
    brew)
      backup_brew_item "$ENTRY_TARGET"
      ;;
    vscode-extensions)
      backup_vscode_extensions_item "$ENTRY_TARGET"
      ;;
    *)
      echo "==> 失败 ${ENTRY_NAME}：未知备份类型 $ENTRY_KIND" >&2
      failures=$((failures + 1))
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)
      SHOW_LIST=1
      shift
      ;;
    --items)
      if [[ $# -lt 2 ]]; then
        echo "--items 需要参数" >&2
        exit 1
      fi
      add_items_from_text "$2"
      shift 2
      ;;
    --safe)
      SELECT_SAFE=1
      shift
      ;;
    --all)
      SELECT_ALL=1
      shift
      ;;
    --exclude)
      if [[ $# -lt 2 ]]; then
        echo "--exclude 需要参数" >&2
        exit 1
      fi
      add_excludes_from_text "$2"
      shift 2
      ;;
    --include-sensitive)
      INCLUDE_SENSITIVE=1
      shift
      ;;
    --allow-sensitive-content)
      ALLOW_SENSITIVE_CONTENT=1
      shift
      ;;
    --interactive)
      INTERACTIVE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
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

if [[ "$SHOW_LIST" == "1" ]]; then
  list_entries
  exit 0
fi

if [[ "$INTERACTIVE" == "1" ]]; then
  if [[ ! -t 0 ]]; then
    echo "--interactive 需要交互式终端。非交互环境请使用 --items、--safe 或 --all。" >&2
    exit 1
  fi
  list_entries
  printf '\n输入要备份的配置项名称，多个名称用逗号或空格分隔；也可输入 safe 或 all：'
  read -r answer
  add_items_from_text "$answer"
fi

if [[ "$SELECT_SAFE" == "1" ]]; then
  select_safe_items
fi

if [[ "$SELECT_ALL" == "1" ]]; then
  select_all_items
fi

if [[ "$selection_errors" == "1" ]]; then
  exit 1
fi

filter_excluded_items

if [[ "${#SELECTED_ITEMS[@]}" -eq 0 ]]; then
  echo "没有选择任何配置项。先运行 --list 查看可选项，或使用 --interactive 交互选择。" >&2
  usage >&2
  exit 1
fi

validate_sensitive_selection

# shellcheck source=scripts/lib/logging.sh
source "$REPO_ROOT/scripts/lib/logging.sh"
# shellcheck source=scripts/lib/files.sh
source "$REPO_ROOT/scripts/lib/files.sh"
setup_script_logging "backup-configs"

echo "==> 开始备份本机软件配置到仓库"
for ((index = 0; index < ${#SELECTED_ITEMS[@]}; index++)); do
  item="${SELECTED_ITEMS[$index]}"
  backup_item "$item"
done

echo "==> 汇总：已处理 $copied 项，跳过 $skipped 项，失败 $failures 项。"
echo "==> 请检查 git diff，确认没有 token、私钥、内网地址或本机隐私路径后再提交。"

if [[ "$failures" -gt 0 ]]; then
  exit 1
fi
