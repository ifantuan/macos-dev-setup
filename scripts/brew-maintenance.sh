#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${PROFILE:-full}"
ACTION="${ACTION:-check}"
BREW_NO_UPGRADE="${BREW_NO_UPGRADE:-1}"
CONFIRM_CLEANUP="${CONFIRM_CLEANUP:-0}"
ACKNOWLEDGE_TRUST_RESET=0

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
  --acknowledge-trust-reset
                        确认清理会按选中清单重置全局信任；执行前保存信任快照
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
    --acknowledge-trust-reset)
      ACKNOWLEDGE_TRUST_RESET=1
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
    env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "$BREWFILE" --no-upgrade
    ;;
  install)
    brew_args=(bundle install --file "$BREWFILE" --verbose)
    if [[ "$BREW_NO_UPGRADE" == "1" ]]; then
      brew_args+=(--no-upgrade)
    else
      brew_args+=(--upgrade)
    fi
    brew "${brew_args[@]}"
    ;;
  cleanup-preview)
    # Homebrew 7 默认可交互清理，必须断开输入以保证预演无删除。
    if env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle cleanup --file "$BREWFILE" </dev/null; then
      echo "==> 预演完成，未删除任何依赖，也未修改信任记录。"
    else
      status=$?
      echo "==> 预演返回 $status：可能存在待清理项，也可能发生错误。请检查上述输出；未执行删除。" >&2
      exit "$status"
    fi
    ;;
  cleanup-force)
    if [[ "$ACKNOWLEDGE_TRUST_RESET" != "1" ]]; then
      echo "清理会按选中 Brewfile 重置全局信任，移除其他清单或手工授予的信任。" >&2
      echo "审查软件清单及信任范围后，必须显式加 --acknowledge-trust-reset；--yes 不能替代此确认。" >&2
      exit 1
    fi
    if ! command -v python3 >/dev/null 2>&1; then
      echo "缺少 python3，无法校验信任快照，已取消清理。" >&2
      exit 1
    fi
    # 清单保留的第三方 formula 和 cask 若失去信任，后续加载来源定义可能失败，必须先处理。
    # 由 Homebrew Bundle 解析清单，不用文本匹配，避免漏判缩进、单引号等写法或误判正则字符。
    if ! shadowed="$(env HOMEBREW_NO_AUTO_UPDATE=1 brew ruby "$REPO_ROOT/scripts/lib/find-shadowed-packages.rb" "$BREWFILE")"; then
      echo "无法核对已安装包的来源，已取消清理。" >&2
      exit 1
    fi
    if [[ -n "$shadowed" ]]; then
      echo "以下清单保留的已安装包来自第三方 tap，但清单没有为其来源保留信任：" >&2
      # 输出可直接复制的命令；单引号转义可读性优于 Bash 3.2 对非 ASCII 路径的 %q 结果。
      shell_quote() {
        if [[ "$1" =~ ^[A-Za-z0-9_./+@:-]+$ ]]; then
          printf '%s' "$1"
        else
          printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
        fi
      }
      migrate_formulae=""
      migrate_casks=""
      while IFS=$'\t' read -r type full_name; do
        printf '    %s: %s\n' "${type/brew/formula}" "$full_name" >&2
        if [[ "$type" == "cask" ]]; then
          migrate_casks="$migrate_casks $(shell_quote "$full_name")"
        else
          migrate_formulae="$migrate_formulae $(shell_quote "$full_name")"
        fi
      done <<< "$shadowed"
      echo "如需迁移，请先确认清单声明目标来源，再按以下命令重装（cask 不使用 --zap）：" >&2
      [[ -z "$migrate_formulae" ]] || echo "    brew uninstall --formula$migrate_formulae" >&2
      [[ -z "$migrate_casks" ]] || echo "    brew uninstall --cask$migrate_casks" >&2
      printf '    brew bundle install --file %s --no-upgrade\n' "$(shell_quote "$BREWFILE")" >&2
      echo "如需保留第三方来源，在私有清单中按完整名称声明并设置 trusted: true，或显式授权对应 tap。" >&2
      exit 1
    fi
    echo "==> 将移除不在 $(basename "$BREWFILE") 中的 Homebrew 依赖"
    echo "==> 同时重置全局显式信任；官方源清单不声明第三方信任。"
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
    # 只在明确确认后创建独立快照；读取失败时禁止进入删除分支。
    trust_root="${BACKUP_DIR:-$HOME/.macos-dev-setup-backup}"
    mkdir -p "$trust_root"
    trust_backup="$(mktemp -d "$trust_root/trust-$(date +%Y%m%d-%H%M%S).XXXXXX")"
    if ! env HOMEBREW_NO_AUTO_UPDATE=1 brew trust --json=v1 > "$trust_backup/trust.json"; then
      rm -f "$trust_backup/trust.json"
      rmdir "$trust_backup"
      echo "信任快照失败，已取消清理。" >&2
      exit 1
    fi
    chmod 600 "$trust_backup/trust.json"
    if ! python3 - "$trust_backup/trust.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as source:
    snapshot = json.load(source)
if not isinstance(snapshot, dict) or not all(
    isinstance(entries, list) and all(isinstance(entry, str) for entry in entries)
    for entries in snapshot.values()
):
    raise SystemExit("信任快照格式无效，已取消清理。")
PY
    then
      echo "信任快照未通过校验，已取消清理；保留文件供排查。" >&2
      exit 1
    fi
    echo "==> 清理前的信任快照：$trust_backup/trust.json"
    brew bundle cleanup --file "$BREWFILE" --force
    ;;
  *)
    echo "未知动作：$ACTION" >&2
    exit 1
    ;;
esac
