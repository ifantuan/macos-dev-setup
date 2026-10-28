#!/usr/bin/env bash
set -euo pipefail

INSTALL_JAVA="${INSTALL_JAVA:-1}"
INSTALL_PYTHON="${INSTALL_PYTHON:-1}"
INSTALL_NODE="${INSTALL_NODE:-1}"
DRY_RUN="${DRY_RUN:-0}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=configs/runtimes/versions.sh
source "$REPO_ROOT/configs/runtimes/versions.sh"
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
  PYTHON_VERSION=3.12.16
  NODE_VERSION=lts-latest
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

# 各阶段显式传递失败，避免在条件调用函数时依赖 set -e 的隐式行为。
install_node() {
  require_command fnm || return
  require_command pnpm || return
  echo "==> 安装 Node.js $NODE_VERSION；pnpm 由 Homebrew 管理"
  local environment
  if [[ "$DRY_RUN" != "1" ]]; then
    environment="$(fnm env --use-on-cd --shell bash)" || return
    eval "$environment" || return
  fi
  if [[ "$NODE_VERSION" == "lts-latest" ]]; then
    run fnm install --lts || return
  else
    run fnm install "$NODE_VERSION" || return
  fi
  run fnm default "$NODE_VERSION" || return
  run fnm use "$NODE_VERSION" || return
  run node --version || return
  run pnpm --version
}

install_python() {
  require_command "$PYTHON_PROVIDER" || return
  echo "==> 使用 $PYTHON_PROVIDER 安装 Python $PYTHON_VERSION"
  if [[ "$PYTHON_PROVIDER" == "pyenv" ]]; then
    run pyenv install -s "$PYTHON_VERSION" || return
    run pyenv global "$PYTHON_VERSION" || return
    run env PYENV_VERSION="$PYTHON_VERSION" pyenv exec python --version
  else
    run uv python install "$PYTHON_VERSION" --default || return
    run uv run --no-project --python "$PYTHON_VERSION" python --version
  fi
}

install_java() (
  # SDKMAN 的 Shell 函数不保证兼容 nounset；仅在本阶段子 Shell 中关闭。
  set +u
  export SDKMAN_DIR="$HOME/.sdkman"
  if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    require_command curl || return
    echo "==> 安装 SDKMAN"
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[dry-run] 在私有临时目录下载并执行 SDKMAN 安装器，退出后清理"
    else
      installer_dir="$(mktemp -d "${TMPDIR:-/tmp}/macos-dev-setup-sdkman.XXXXXX")" || return
      trap 'rm -rf "$installer_dir"' EXIT
      curl -fsSL "https://get.sdkman.io?ci=true&rcupdate=false" -o "$installer_dir/install.sh" || return
      bash "$installer_dir/install.sh" || return
    fi
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] 加载 SDKMAN，安装并选择 Java $JAVA_VERSION，安装 Maven 并验证版本"
    return 0
  fi
  # shellcheck disable=SC1091
  source "$SDKMAN_DIR/bin/sdkman-init.sh" || return
  # sdk 每次调用都会重读用户配置，环境变量无法关闭询问；断开输入后按默认答案执行，且不改写配置文件。
  if [[ ! -d "$SDKMAN_DIR/candidates/java/$JAVA_VERSION" ]]; then
    sdk install java "$JAVA_VERSION" </dev/null || return
  fi
  sdk default java "$JAVA_VERSION" || return
  if [[ ! -x "$SDKMAN_DIR/candidates/maven/current/bin/mvn" ]]; then
    sdk install maven </dev/null || return
  fi
  "$SDKMAN_DIR/candidates/java/$JAVA_VERSION/bin/java" -version || return
  "$SDKMAN_DIR/candidates/maven/current/bin/mvn" -v
)

failures=0
run_stage() {
  local name="$1"
  shift
  if "$@"; then
    echo "==> $name 阶段通过"
  else
    local status=$?
    echo "==> $name 阶段失败，退出码：$status" >&2
    failures=$((failures + 1))
  fi
}

if [[ "$INSTALL_NODE" == "1" ]]; then
  run_stage "Node.js / pnpm" install_node
fi
if [[ "$INSTALL_PYTHON" == "1" ]]; then
  run_stage "Python" install_python
fi
if [[ "$INSTALL_JAVA" == "1" ]]; then
  run_stage "Java / Maven" install_java
fi

if [[ "$failures" -gt 0 ]]; then
  echo "==> 运行时初始化失败：$failures 个阶段未通过。" >&2
  exit 1
fi
echo "==> 运行时初始化完成"
