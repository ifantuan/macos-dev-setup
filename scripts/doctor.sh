#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK_BREW_INSTALLED="${CHECK_BREW_INSTALLED:-0}"
CHECK_BREW_READABLE="${CHECK_BREW_READABLE:-1}"
REQUIRE_SHELLCHECK="${REQUIRE_SHELLCHECK:-0}"
REQUIRE_GITLEAKS="${REQUIRE_GITLEAKS:-0}"
REQUIRE_GHOSTTY_VALIDATE="${REQUIRE_GHOSTTY_VALIDATE:-0}"
BREWFILES=("$REPO_ROOT/Brewfile.core" "$REPO_ROOT/Brewfile")
EXAMPLE_BREWFILES=("$REPO_ROOT/Brewfile.work.example" "$REPO_ROOT/Brewfile.personal.example")

failures=0
GHOSTTY_CMD=""

check() {
  local name="$1"
  shift
  printf '==> %s\n' "$name"
  if "$@"; then
    printf '    ok\n'
  else
    printf '    failed\n' >&2
    failures=$((failures + 1))
  fi
}

validate_ghostty_config() {
  local output
  local status

  set +e
  output="$("$GHOSTTY_CMD" +validate-config --config-file="$REPO_ROOT/configs/ghostty/config" 2>&1)"
  status=$?
  set -e

  if [[ -n "$output" ]]; then
    output="$(printf '%s\n' "$output" | sed '/^error: SentryInitFailed$/d')"
  fi

  if [[ "$status" -eq 0 ]]; then
    [[ -z "$output" ]] || printf '%s\n' "$output"
    return 0
  fi

  [[ -z "$output" ]] || printf '%s\n' "$output" >&2
  return "$status"
}

# 自检只做低风险检查，不安装软件、不修改用户配置。
check "bootstrap.sh 语法" bash -n "$REPO_ROOT/scripts/bootstrap.sh"
check "apply-macos-defaults.sh 语法" bash -n "$REPO_ROOT/scripts/apply-macos-defaults.sh"
check "audit-environment.sh 语法" bash -n "$REPO_ROOT/scripts/audit-environment.sh"
check "quickstart.sh 语法" bash -n "$REPO_ROOT/scripts/quickstart.sh"
check "brew-maintenance.sh 语法" bash -n "$REPO_ROOT/scripts/brew-maintenance.sh"
check "drill-clean-home.sh 语法" bash -n "$REPO_ROOT/scripts/drill-clean-home.sh"
check "drill-idempotency.sh 语法" bash -n "$REPO_ROOT/scripts/drill-idempotency.sh"
check "record-recovery-drill.sh 语法" bash -n "$REPO_ROOT/scripts/record-recovery-drill.sh"
check "install-runtimes.sh 语法" bash -n "$REPO_ROOT/scripts/install-runtimes.sh"
check "sync-back.sh 语法" bash -n "$REPO_ROOT/scripts/sync-back.sh"
check "logging.sh 语法" bash -n "$REPO_ROOT/scripts/lib/logging.sh"
check "zshrc 语法" zsh -n "$REPO_ROOT/configs/zsh/zshrc"
check "Starship 配置存在" test -f "$REPO_ROOT/configs/starship/starship.toml"
check "Git 配置模板存在" test -f "$REPO_ROOT/configs/git/gitconfig.example"
check "SSH 配置模板存在" test -f "$REPO_ROOT/configs/ssh/config.example"
check "npm 配置模板存在" test -f "$REPO_ROOT/configs/npm/npmrc.example"
check "pip 配置模板存在" test -f "$REPO_ROOT/configs/pip/pip.conf.example"
check "Maven 配置模板 XML" python3 - "$REPO_ROOT/configs/maven/settings.xml.example" <<'PY'
from pathlib import Path
import sys
import xml.etree.ElementTree as ET

ET.parse(Path(sys.argv[1]))
PY
check "VS Code 配置模板 JSON" python3 - "$REPO_ROOT/configs/vscode/settings.json.example" <<'PY'
from pathlib import Path
import json
import sys

json.loads(Path(sys.argv[1]).read_text())
PY
check "VS Code 扩展示例清单" python3 - "$REPO_ROOT/configs/vscode/extensions.txt.example" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
pattern = re.compile(r"^[a-z0-9][a-z0-9-]*\.[a-z0-9][a-z0-9-]*$", re.IGNORECASE)
bad = []

for line_no, raw in enumerate(path.read_text().splitlines(), 1):
    line = raw.strip()
    if not line or line.startswith("#"):
        continue
    if not pattern.match(line):
        bad.append(f"{line_no}: {line}")

if bad:
    print("无效扩展 ID：")
    for item in bad:
        print(f"- {item}")
    raise SystemExit(1)
PY

if command -v shellcheck >/dev/null 2>&1; then
  check "ShellCheck" shellcheck "$REPO_ROOT"/scripts/*.sh "$REPO_ROOT"/scripts/lib/*.sh
elif [[ "$REQUIRE_SHELLCHECK" == "1" ]]; then
  printf '==> ShellCheck\n' >&2
  printf '    failed: shellcheck 未安装\n' >&2
  failures=$((failures + 1))
else
  printf '==> ShellCheck\n    skipped: shellcheck 未安装\n'
fi

if command -v gitleaks >/dev/null 2>&1; then
  check "密钥扫描" gitleaks detect --source "$REPO_ROOT" --no-git --redact --verbose
elif [[ "$REQUIRE_GITLEAKS" == "1" ]]; then
  printf '==> 密钥扫描\n' >&2
  printf '    failed: gitleaks 未安装\n' >&2
  failures=$((failures + 1))
else
  printf '==> 密钥扫描\n    skipped: gitleaks 未安装\n'
fi

if command -v ghostty >/dev/null 2>&1; then
  GHOSTTY_CMD="ghostty"
elif [[ -x "/Applications/Ghostty.app/Contents/MacOS/ghostty" ]]; then
  GHOSTTY_CMD="/Applications/Ghostty.app/Contents/MacOS/ghostty"
fi

if [[ -n "$GHOSTTY_CMD" ]]; then
  if [[ "$REQUIRE_GHOSTTY_VALIDATE" == "1" ]]; then
    if validate_ghostty_config; then
      printf '==> Ghostty 配置\n    ok\n'
    else
      printf '==> Ghostty 配置\n    failed\n' >&2
      failures=$((failures + 1))
    fi
  elif command -v brew >/dev/null 2>&1 && ! brew list --cask font-maple-mono-nf-cn >/dev/null 2>&1; then
    if [[ "$CHECK_BREW_INSTALLED" == "1" ]]; then
      printf '==> Ghostty 配置\n' >&2
      printf '    failed: 未检测到 font-maple-mono-nf-cn，请先运行 brew bundle --file Brewfile.core --verbose\n' >&2
      failures=$((failures + 1))
    else
      printf '==> Ghostty 配置\n    skipped: 未安装 font-maple-mono-nf-cn，设置 CHECK_BREW_INSTALLED=1 可将其视为失败\n'
    fi
  elif validate_ghostty_config; then
    printf '==> Ghostty 配置\n    ok\n'
  else
    printf '==> Ghostty 配置\n    failed\n' >&2
    failures=$((failures + 1))
  fi
elif [[ "$REQUIRE_GHOSTTY_VALIDATE" == "1" ]]; then
  printf '==> Ghostty 配置\n' >&2
  printf '    failed: ghostty 未安装\n' >&2
  failures=$((failures + 1))
else
  printf '==> Ghostty 配置\n    skipped: ghostty 未安装\n'
fi

check "Markdown 代码块闭合" python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
bad = []
for path in sorted(root.glob("**/*.md")):
    if ".git" in path.parts:
        continue
    text = path.read_text()
    if text.count("```") % 2:
        bad.append(str(path.relative_to(root)))

if bad:
    print("未闭合代码块：")
    for item in bad:
        print(f"- {item}")
    raise SystemExit(1)
PY

check "Markdown 内部链接" python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])
bad = []
targets = [path for path in sorted(root.glob("**/*.md")) if ".git" not in path.parts]

for path in targets:
    if not path.exists():
        continue
    inside_code = False
    for line_no, line in enumerate(path.read_text().splitlines(), 1):
        if line.startswith("```"):
            inside_code = not inside_code
            continue
        if inside_code:
            continue
        for match in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", line):
            target = match.group(1)
            if target.startswith(("http://", "https://", "mailto:", "#")) or "<" in target:
                continue
            target = target.split("#", 1)[0]
            if not target:
                continue
            full = (path.parent / target).resolve()
            if not full.exists():
                bad.append(f"{path.relative_to(root)}:{line_no} -> {target}")

if bad:
    print("失效内部链接：")
    for item in bad:
        print(f"- {item}")
    raise SystemExit(1)
PY

check "GitHub Actions 工作流" python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
workflow = root / ".github" / "workflows" / "ci.yml"
text = workflow.read_text()

required = [
    "name: CI",
    "runs-on: macos-latest",
    "./scripts/doctor.sh",
]

missing = [item for item in required if item not in text]
if missing:
    print("CI 工作流缺少关键内容：")
    for item in missing:
        print(f"- {item}")
    raise SystemExit(1)
PY

check "目录 README 索引" python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
bad = []

for directory in sorted([root / "docs", *[p for p in (root / "docs").glob("*") if p.is_dir()]]):
    readme = directory / "README.md"
    if not readme.exists():
        continue
    text = readme.read_text()
    for path in sorted(directory.glob("*.md")):
        if path.name == "README.md":
            continue
        if path.name not in text:
            bad.append(f"{readme.relative_to(root)} 缺少 {path.name}")

if bad:
    print("目录 README 未索引以下文档：")
    for item in bad:
        print(f"- {item}")
    raise SystemExit(1)
PY

check "旧配置路径残留" python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])
patterns = [
    "configs/" + "zshrc",
    "configs/" + "tmux.conf",
    "configs/" + ".zshrc",
    "configs/" + "ghostty.config",
    "configs/" + "gitconfig",
    "configs/" + "starship.toml",
]
bad = []
for path in sorted(root.rglob("*")):
    if ".git" in path.parts or not path.is_file():
        continue
    try:
        text = path.read_text()
    except UnicodeDecodeError:
        continue
    for pattern in patterns:
        if pattern in text:
            bad.append(f"{path.relative_to(root)} -> {pattern}")

if bad:
    print("发现旧配置路径残留：")
    for item in bad:
        print(f"- {item}")
    raise SystemExit(1)
PY

if [[ "$CHECK_BREW_READABLE" != "1" ]]; then
  printf '==> Brewfile 可读取\n    skipped: 设置 CHECK_BREW_READABLE=1 可启用 Brewfile 读取检查\n'
elif command -v brew >/dev/null 2>&1; then
  for brewfile in "${BREWFILES[@]}"; do
    check "$(basename "$brewfile") 可读取" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --file "$brewfile" --all
  done
  for brewfile in "${EXAMPLE_BREWFILES[@]}"; do
    check "$(basename "$brewfile") 示例可读取" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle list --file "$brewfile" --all
  done
  if [[ "$CHECK_BREW_INSTALLED" == "1" ]]; then
    check "Brewfile.core 依赖已安装" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "$REPO_ROOT/Brewfile.core"
    check "Brewfile 依赖已安装" env HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --file "$REPO_ROOT/Brewfile"
  else
    printf '==> Brewfile 依赖已安装\n    skipped: 设置 CHECK_BREW_INSTALLED=1 可启用完整安装状态检查\n'
  fi
else
  printf '==> Brewfile 可读取\n    skipped: brew 未安装\n'
fi

if [[ "$failures" -gt 0 ]]; then
  printf '\n%s 项检查失败\n' "$failures" >&2
  exit 1
fi

printf '\n所有检查通过\n'
