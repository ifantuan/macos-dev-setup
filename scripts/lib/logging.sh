#!/usr/bin/env bash

# 给入口脚本提供统一日志归档；dry-run 和子进程重复加载时不启用。
setup_script_logging() {
  if [[ "${DRY_RUN:-0}" == "1" || "${MACOS_DEV_SETUP_LOGGING_ACTIVE:-0}" == "1" ]]; then
    return 0
  fi

  if ! command -v tee >/dev/null 2>&1; then
    return 0
  fi

  local script_name="${1:-script}"
  local log_dir="${MACOS_DEV_SETUP_LOG_DIR:-$HOME/.macos-dev-setup-logs}"
  local timestamp
  timestamp="$(date +%Y%m%d-%H%M%S)"
  local log_file="$log_dir/${timestamp}-$$-${script_name}.log"
  local fifo
  local temporary_dir

  mkdir -p "$log_dir"
  temporary_dir="$(mktemp -d "${TMPDIR:-/tmp}/macos-dev-setup-log.XXXXXX")" || return
  fifo="$temporary_dir/output"
  if ! mkfifo "$fifo"; then
    rmdir "$temporary_dir"
    return 0
  fi

  tee -a "$log_file" < "$fifo" &
  export MACOS_DEV_SETUP_LOGGING_ACTIVE=1
  export MACOS_DEV_SETUP_LOG_FILE="$log_file"

  exec > "$fifo" 2>&1
  rm -f "$fifo"
  rmdir "$temporary_dir"
  printf '==> 日志归档：%s\n' "$log_file"
}
