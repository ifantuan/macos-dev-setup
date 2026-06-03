#!/usr/bin/env bash
set -euo pipefail

INSTALL_JAVA="${INSTALL_JAVA:-1}"
INSTALL_PYTHON="${INSTALL_PYTHON:-1}"
INSTALL_NODE="${INSTALL_NODE:-1}"
DRY_RUN="${DRY_RUN:-0}"
JAVA_VERSION="${JAVA_VERSION:-8.0.492-zulu}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12.2}"
PYTHON_PROVIDER="${PYTHON_PROVIDER:-pyenv}"

usage() {
  cat <<'EOF'
用法：scripts/install-runtimes.sh [选项]

选项：
  --no-java      跳过 Java / Maven
  --no-python    跳过 Python
  --no-node      跳过 Node.js / pnpm
  --python-provider <name>
                 Python 安装方式：pyenv 或 uv，默认 pyenv
  --dry-run      只打印将执行的操作，不安装运行时
  -h, --help     显示帮助

环境变量：
  JAVA_VERSION=8.0.492-zulu
  PYTHON_VERSION=3.12.2
  PYTHON_PROVIDER=pyenv
  DRY_RUN=1
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-java)
      INSTALL_JAVA=0
      shift
      ;;
    --no-python)
      INSTALL_PYTHON=0
      shift
      ;;
    --no-node)
      INSTALL_NODE=0
      shift
      ;;
    --python-provider)
      if [[ $# -lt 2 ]]; then
        echo "--python-provider 需要参数：uv 或 pyenv" >&2
        exit 1
      fi
      PYTHON_PROVIDER="$2"
      shift 2
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

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "$REPO_ROOT/scripts/lib/logging.sh"
setup_script_logging "install-runtimes"

case "$PYTHON_PROVIDER" in
  pyenv|uv)
    ;;
  *)
    echo "未知 Python 安装方式：$PYTHON_PROVIDER。可选值：pyenv, uv" >&2
    exit 1
    ;;
esac

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run]'
    printf ' %s' "$@"
    printf '\n'
  else
    "$@"
  fi
}

require_command() {
  local name="$1"
  if [[ "$DRY_RUN" == "1" ]]; then
    return 0
  fi
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "缺少命令：${name}。请先运行 ./scripts/bootstrap.sh --profile core" >&2
    return 1
  fi
}

# SDKMAN 默认会在安装同名版本时询问确认，快速启动路径需要关闭交互。
set_sdkman_config() {
  local key="$1"
  local value="$2"
  local file="$SDKMAN_DIR/etc/config"
  local tmp

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] 设置 SDKMAN 配置：${key}=${value}"
    return 0
  fi

  [[ -f "$file" ]] || return 0
  tmp="$(mktemp)"
  if grep -q "^${key}=" "$file"; then
    awk -F= -v key="$key" -v value="$value" 'BEGIN { OFS = "=" } $1 == key { $0 = key "=" value } { print }' "$file" > "$tmp"
  else
    cp "$file" "$tmp"
    printf '\n%s=%s\n' "$key" "$value" >> "$tmp"
  fi
  mv "$tmp" "$file"
}

if [[ "$INSTALL_NODE" == "1" ]]; then
  if require_command fnm; then
    echo "==> 安装 Node.js LTS 和 pnpm"
    if [[ "$DRY_RUN" != "1" ]]; then
      eval "$(fnm env --use-on-cd --shell bash)"
    fi
    run fnm install --lts
    run fnm default lts-latest
    run fnm use lts-latest
    if [[ "$DRY_RUN" != "1" ]]; then
      eval "$(fnm env --use-on-cd --shell bash)"
    fi
    if command -v corepack >/dev/null 2>&1 || [[ "$DRY_RUN" == "1" ]]; then
      run corepack enable
      run corepack prepare pnpm@latest --activate
    else
      echo "跳过 pnpm 激活：未找到 corepack，请重新打开终端后执行 corepack enable" >&2
    fi
  fi
fi

if [[ "$INSTALL_PYTHON" == "1" ]]; then
  case "$PYTHON_PROVIDER" in
    pyenv)
      if require_command pyenv; then
        echo "==> 使用 pyenv 安装 Python $PYTHON_VERSION"
        run pyenv install -s "$PYTHON_VERSION"
        run pyenv global "$PYTHON_VERSION"
      fi
      ;;
    uv)
      if require_command uv; then
        echo "==> 使用 uv 安装 Python $PYTHON_VERSION"
        # uv 保留给需要预编译解释器或项目依赖管理的场景。
        run uv python install "$PYTHON_VERSION" --default
        if [[ "$DRY_RUN" != "1" ]]; then
          uv python list --only-installed || true
        fi
      fi
      ;;
  esac
fi

if [[ "$INSTALL_JAVA" == "1" ]]; then
  export SDKMAN_DIR="$HOME/.sdkman"
  if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    echo "==> 安装 SDKMAN"
    run curl -fsSL "https://get.sdkman.io?ci=true&rcupdate=false" -o /tmp/macos-dev-setup-sdkman-install.sh
    run bash /tmp/macos-dev-setup-sdkman-install.sh
  fi
  set_sdkman_config sdkman_auto_answer true
  set_sdkman_config sdkman_colour_enable false

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] source $SDKMAN_DIR/bin/sdkman-init.sh"
    echo "[dry-run] sdk install java $JAVA_VERSION"
    echo "[dry-run] sdk default java $JAVA_VERSION"
    echo "[dry-run] sdk install maven"
  else
    # shellcheck disable=SC1091
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    echo "==> 安装 Java $JAVA_VERSION 和 Maven"
    sdk install java "$JAVA_VERSION"
    sdk default java "$JAVA_VERSION"
    sdk install maven || true
  fi
fi

echo "==> 运行时初始化完成"
