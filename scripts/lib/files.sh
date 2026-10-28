#!/usr/bin/env bash

# 先在目标目录生成新内容；写入失败时保留旧文件及链接。
# 写入函数最后一个参数为临时文件，函数内部必须显式传递失败。
write_file_atomically() {
  local target="$1"
  shift
  local temporary status
  if [[ -d "$target" ]]; then
    echo "拒绝用文件覆盖目录：$target" >&2
    return 1
  fi
  mkdir -p "$(dirname "$target")" || return
  temporary="$(mktemp "$(dirname "$target")/.macos-dev-setup.XXXXXX")" || return
  if "$@" "$temporary" && keep_file_mode "$target" "$temporary"; then
    if mv -f "$temporary" "$target"; then
      return 0
    else
      status=$?
    fi
  else
    status=$?
  fi
  rm -f "$temporary"
  return "$status"
}

# 替换普通文件时沿用其原权限，避免把用户收紧的权限放宽；链接和新文件采用写入内容的权限。
keep_file_mode() {
  [[ -f "$1" && ! -L "$1" ]] || return 0
  chmod "$(stat -f %Lp "$1")" "$2"
}

copy_file_contents() {
  cp -pL "$1" "$2"
}

export_brewfile_contents() {
  env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file "$1" --force || return
  env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --file "$1" --all >/dev/null
}

export_extension_contents() {
  "$1" --list-extensions | LC_ALL=C sort > "$2"
}
