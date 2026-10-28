"""在隔离目录验证审计问题，不调用真实安装器或修改用户配置。"""

import os
import json
from pathlib import Path
import pty
import re
import shlex
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASH = os.environ.get("TEST_BASH", "/bin/bash")


def find_real_brew():
    return shutil.which("brew") or shutil.which("brew", path="/opt/homebrew/bin:/usr/local/bin")


def find_ruby(brew):
    """优先使用 brew ruby 实际运行检测脚本的 Homebrew 自带 Ruby，避免系统 Ruby 版本差异。"""
    if os.environ.get("TEST_RUBY"):
        return os.environ["TEST_RUBY"]
    if brew:
        repository = subprocess.run([brew, "--repository"], stdout=subprocess.PIPE,
                                    stderr=subprocess.DEVNULL, text=True).stdout.strip()
        portable = Path(repository) / "Library/Homebrew/vendor/portable-ruby/current/bin/ruby"
        if repository and os.access(portable, os.X_OK):
            return str(portable)
    return shutil.which("ruby")


REAL_BREW = find_real_brew()
RUBY = find_ruby(REAL_BREW)


class RegressionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="macos-setup-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / "有空格的仓库"
        self.user = self.base / "用户目录"
        self.bin = self.base / "bin"
        self.user.mkdir()
        self.bin.mkdir()
        for directory in ("scripts", "configs"):
            shutil.copytree(ROOT / directory, self.repo / directory)
        for path in ROOT.glob("Brewfile*"):
            shutil.copy(path, self.repo / path.name)
        shutil.copy(ROOT / "Makefile", self.repo / "Makefile")
        (self.bin / "bash").symlink_to(BASH)
        self.trace = self.base / "命令记录"
        self.effect = self.base / "禁止的副作用"
        self.env = {
            "HOME": str(self.user),
            "PATH": f"{self.bin}:/usr/bin:/bin:/usr/sbin:/sbin",
            "SHELL": "/bin/zsh",
            "TMPDIR": str(self.base),
            "MACOS_DEV_SETUP_LOGGING_ACTIVE": "1",
            "TEST_TRACE": str(self.trace),
            "TEST_EFFECT": str(self.effect),
        }

    def stub(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def stub_script(self, name, body="exit 0"):
        path = self.repo / "scripts" / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def run_script(self, name, *args, env=None):
        return subprocess.run(
            [BASH, str(self.repo / "scripts" / name), *args],
            env={**self.env, **(env or {})}, cwd=self.repo,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=20,
        )

    def assert_ok(self, result):
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_cleanup_preview_never_accepts_terminal_input(self):
        """A01：即使调用者有终端，预演子进程也不能交互删除。"""
        self.stub("brew", 'if [[ -t 0 && -t 1 ]]; then touch "$TEST_EFFECT"; fi')
        master, slave = pty.openpty()
        try:
            result = subprocess.run(
                [BASH, str(self.repo / "scripts/brew-maintenance.sh"), "--cleanup-preview"],
                env=self.env, stdin=slave, stdout=slave, stderr=slave, timeout=10,
            )
            self.assertEqual(result.returncode, 0)
            self.assertFalse(self.effect.exists(), "预演向 Homebrew 暴露了交互终端")
        finally:
            os.close(slave)
            os.close(master)

    def test_symlink_backup_preserves_target_and_link(self):
        """A02：替换链接配置时，原目标、链接和内容快照都得到保留。"""
        original = self.user / "原配置"
        original.write_text("原有内容\n")
        (self.user / ".zshrc").symlink_to("原配置")
        result = self.run_script("bootstrap.sh", "--skip-brew")
        self.assert_ok(result)
        self.assertEqual(original.read_text(), "原有内容\n")
        self.assertFalse((self.user / ".zshrc").is_symlink())
        backups = [batch / ".zshrc" for batch in (self.user / ".macos-dev-setup-backup").iterdir()
                   if (batch / ".zshrc").is_symlink()]
        self.assertEqual(len(backups), 1)
        self.assertEqual(os.readlink(backups[0]), "原配置")
        self.assertEqual((backups[0].parent / "link-targets/.zshrc").read_text(), "原有内容\n")

    def test_dangling_link_can_be_replaced(self):
        """A02：悬空链接可备份并安全替换。"""
        (self.user / ".zshrc").symlink_to("不存在")
        self.assert_ok(self.run_script("bootstrap.sh", "--skip-brew"))
        self.assertFalse((self.user / ".zshrc").is_symlink())
        self.assertFalse((self.user / "不存在").exists())

    def test_parent_symlink_is_skipped_without_writing_through(self):
        """A02：父目录为链接时跳过受影响配置，不写穿链接，也不阻断其他配置。"""
        external = self.base / "外部配置"
        external.mkdir()
        (external / "starship.toml").write_text("外部管理")
        (self.user / ".config").symlink_to(external)
        (self.user / ".zshrc").write_text("旧配置")
        result = self.run_script("bootstrap.sh", "--skip-brew")
        self.assert_ok(result)
        self.assertIn("已跳过 2 项", result.stdout)
        self.assertEqual(sorted(p.name for p in external.iterdir()), ["starship.toml"])
        self.assertEqual((external / "starship.toml").read_text(), "外部管理")
        self.assertEqual((self.user / ".zshrc").read_text(),
                         (self.repo / "configs/zsh/zshrc").read_text())

    def test_broken_parent_is_rejected_before_writes(self):
        """A02：父路径为悬空链接或普通文件时，在改写任何配置前拒绝执行。"""
        for make_parent in (lambda p: p.symlink_to("不存在"), lambda p: p.write_text("文件")):
            with self.subTest(make_parent=make_parent):
                parent = self.user / ".config"
                if parent.is_symlink() or parent.exists():
                    parent.unlink()
                make_parent(parent)
                (self.user / ".zshrc").write_text("旧配置")
                self.assertNotEqual(self.run_script("bootstrap.sh", "--skip-brew").returncode, 0)
                self.assertEqual((self.user / ".zshrc").read_text(), "旧配置")

    def test_replaced_config_keeps_restricted_mode(self):
        """原子替换普通文件时保留用户收紧的权限。"""
        zshrc = self.user / ".zshrc"
        zshrc.write_text("旧配置")
        zshrc.chmod(0o600)
        self.assert_ok(self.run_script("bootstrap.sh", "--skip-brew"))
        self.assertEqual(zshrc.read_text(), (self.repo / "configs/zsh/zshrc").read_text())
        self.assertEqual(zshrc.stat().st_mode & 0o777, 0o600)

    def test_quickstart_real_control_flow(self):
        """A03：正式启动在系统 Bash 下执行全部三个阶段。"""
        for name in ("bootstrap.sh", "install-runtimes.sh", "doctor.sh"):
            self.stub_script(name, f'echo {name} >> "$TEST_TRACE"')
        self.assert_ok(self.run_script("quickstart.sh"))
        self.assertEqual(self.trace.read_text().splitlines(),
                         ["bootstrap.sh", "install-runtimes.sh", "doctor.sh"])

    def test_manifest_sources_and_subset(self):
        """A04、A06：默认清单仅用官方源，可选包保留完整来源说明。"""
        for path in self.repo.glob("Brewfile*"):
            self.assertNotIn('tap "homebrew/bundle"', path.read_text())
        full = (self.repo / "Brewfile").read_text()
        optional = (self.repo / "Brewfile.personal.example").read_text()
        self.assertNotRegex(full, r'(?m)^tap ')
        self.assertNotIn('cask "zedg"', full)
        self.assertNotIn('cask "rebased"', full)
        for name in ("x6nux/zedg/zedg", "detachhead/tap/rebased"):
            self.assertRegex(optional, rf'# cask "{name}", trusted: true')
        core = (self.repo / "Brewfile.core").read_text()
        entries = lambda text: set(re.findall(r'^(brew|cask) "([^"]+)"', text, re.M))
        self.assertLessEqual(entries(core), entries(full))

    def brew_export_stub(self, fail=False):
        self.stub("brew", '''
printf '%s ' "$@" >> "$TEST_TRACE"
printf '\\n' >> "$TEST_TRACE"
[[ "$*" != *--describe* ]] || exit 8
if [[ "$1 $2" == "bundle dump" ]]; then
  while [[ $# -gt 0 ]]; do
    if [[ "$1" == "--file" ]]; then target="$2"; break; fi
    shift
  done
  printf 'brew "git"\\n' > "$target"
  exit ''' + ("9" if fail else "0") + '\nfi\nexit 0')

    def test_brew_exports_do_not_use_disabled_flags(self):
        """A05：两条导出路径兼容 Homebrew 7。"""
        self.brew_export_stub()
        self.assert_ok(self.run_script("backup-configs.sh", "--items", "brew"))
        self.assert_ok(self.run_script("sync-back.sh", "--include-brew"))
        self.assertEqual((self.repo / "Brewfile").read_text(), 'brew "git"\n')

    def test_brew_export_failure_preserves_file_and_reports(self):
        """A05：导出失败保留旧清单并输出失败汇总。"""
        old = (self.repo / "Brewfile").read_text()
        self.brew_export_stub(fail=True)
        result = self.run_script("backup-configs.sh", "--items", "brew")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.repo / "Brewfile").read_text(), old)
        self.assertIn("汇总", result.stdout)

    def test_force_cleanup_requires_trust_reset_acknowledgement(self):
        """A06：旧的 --yes 不能默许重置全局信任。"""
        self.stub("brew", 'touch "$TEST_EFFECT"')
        result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.effect.exists())

    def test_acknowledged_cleanup_saves_trust_before_removal(self):
        """A06：明确确认后，必须先保存有效快照，再执行清理。"""
        self.stub("brew", '''
if [[ "$1" == trust ]]; then
  printf '{"taps":["private/example"],"formulae":[],"casks":[],"commands":[]}\\n'
elif [[ "$1" == ruby ]]; then
  :
else
  [[ -n "$(find "$HOME/.macos-dev-setup-backup" -name trust.json -type f)" ]] || exit 8
  touch "$TEST_EFFECT"
fi
''')
        result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                 "--acknowledge-trust-reset")
        self.assert_ok(result)
        self.assertTrue(self.effect.exists())
        snapshots = list((self.user / ".macos-dev-setup-backup").glob("*/trust.json"))
        self.assertEqual(len(snapshots), 1)
        self.assertEqual(json.loads(snapshots[0].read_text())["taps"], ["private/example"])
        self.assertEqual(snapshots[0].stat().st_mode & 0o777, 0o600)

    def test_cleanup_blocks_third_party_packages_shadowing_manifest(self):
        """A06：第三方同名 formula 或 cask 可能失去来源信任，必须在快照和清理前拒绝。"""
        spaced = self.base / "带 空格 的仓库"
        shutil.move(str(self.repo), str(spaced))
        self.repo = spaced
        self.stub("brew", '''
if [[ "$1" == ruby ]]; then
  [[ "$2" == */scripts/lib/find-shadowed-packages.rb && -f "$3" ]] || exit 7
  printf 'brew\\toven-sh/bun/bun\\ncask\\tdetachhead/tap/rebased\\n'
else
  touch "$TEST_EFFECT"
fi
''')
        result = self.run_script("brew-maintenance.sh", "--cleanup-force",
                                 "--yes", "--acknowledge-trust-reset")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.effect.exists())
        self.assertFalse((self.user / ".macos-dev-setup-backup").exists())
        commands = [shlex.split(line) for line in result.stdout.splitlines()
                    if line.strip().startswith("brew ")]
        self.assertIn(["brew", "uninstall", "--formula", "oven-sh/bun/bun"], commands)
        self.assertIn(["brew", "uninstall", "--cask", "detachhead/tap/rebased"], commands)
        self.assertIn(["brew", "bundle", "install", "--file", str(spaced / "Brewfile"),
                       "--no-upgrade"], commands)

    def test_cleanup_stops_when_package_sources_cannot_be_checked(self):
        """A06：来源核对失败时不能继续保存快照或清理。"""
        self.stub("brew", '[[ "$1" != ruby ]] || exit 3\ntouch "$TEST_EFFECT"')
        result = self.run_script("brew-maintenance.sh", "--cleanup-force",
                                 "--yes", "--acknowledge-trust-reset")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("无法核对已安装包的来源", result.stdout)
        self.assertFalse(self.effect.exists())
        self.assertFalse((self.user / ".macos-dev-setup-backup").exists())

    def stub_package_sources(self, manifest, formulae=(), casks=()):
        if not RUBY:
            self.skipTest("未找到 Ruby 解释器")
        (self.repo / "Brewfile").write_text(manifest)
        fixtures = self.base / "Homebrew接口桩"
        if not fixtures.exists():
            shutil.copytree(ROOT / "tests/fixtures/homebrew", fixtures)
        self.env.update({
            "RUBYLIB": str(fixtures),
            "TEST_RUBY": RUBY,
            "TEST_FORMULAE": json.dumps(formulae),
            "TEST_CASKS": json.dumps(casks),
        })
        self.stub("brew", '''
printf '%s\\n' "$1" >> "$TEST_TRACE"
case "$1" in
  ruby) shift; exec "$TEST_RUBY" "$@" ;;
  list)
    "$TEST_RUBY" -rjson -e 'puts JSON.parse(ENV.fetch("TEST_FORMULAE"))'
    ;;
  trust) printf '{"taps":[],"formulae":[],"casks":[],"commands":[]}\\n' ;;
  bundle) touch "$TEST_EFFECT" ;;
  *) exit 9 ;;
esac
''')

    @unittest.skipUnless(REAL_BREW, "未安装 Homebrew")
    def test_finder_against_real_homebrew_api(self):
        """接口桩无法发现 Homebrew 内部接口变化；有 Homebrew 时用真实接口只读运行检测脚本。"""
        env = {**os.environ, "HOMEBREW_NO_AUTO_UPDATE": "1"}
        brewfile = self.base / "Brewfile.real"

        def find(manifest):
            brewfile.write_text(manifest)
            result = subprocess.run(
                [REAL_BREW, "ruby", str(ROOT / "scripts/lib/find-shadowed-packages.rb"),
                 str(brewfile)],
                env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=180,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            return result.stdout

        # 合法写法与各种信任声明都能被真实 Bundle 解析，未安装的名称不误报。
        self.assertEqual(find(
            "  brew 'macos-dev-setup-not-installed'\n"
            'brew "macos-dev-setup-not-installed++", args: ["HEAD"]\n'
            'tap "example/tap", trusted: { formulae: ["macos-dev-setup-not-installed"] }\n'
            'cask "example/tap/macos-dev-setup-not-installed", trusted: true\n'
            "if true\n  cask 'macos-dev-setup-not-installed'\nend\n"), "")

        # 本机装有第三方包时，再验证真实信任规则的命中与放行；结果不依赖具体包名。
        listing = subprocess.run(
            [REAL_BREW, "ruby", "-e",
             'require "cask/caskroom"; '
             '(Formula.installed.map { |f| "brew\\t#{f.full_name}" } + '
             'Cask::Caskroom.casks.map { |c| "cask\\t#{c.full_name}" }).each { |l| puts l }'],
            env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=180,
        )
        self.assertEqual(listing.returncode, 0, listing.stderr)
        third_party = [line.split("\t") for line in listing.stdout.splitlines()
                       if "/" in line.partition("\t")[2]]
        if not third_party:
            return
        kind, full_name = third_party[0]
        tap, _, token = full_name.rpartition("/")
        with self.subTest(package=full_name):
            self.assertEqual(find(f'{kind} "{token}"\n'), f"{kind}\t{full_name}\n")
            self.assertEqual(find(f'{kind} "{full_name}"\n'), f"{kind}\t{full_name}\n")
            self.assertEqual(find(f'tap "{tap}", trusted: true\n{kind} "{token}"\n'), "")
            self.assertEqual(find(f'{kind} "{full_name}", trusted: true\n'), "")

    def test_cleanup_matches_literal_names_and_ruby_syntax(self):
        """P2：执行真实检测脚本，缩进、引号、选项、条件和特殊名称都能正确拦截。"""
        cases = (
            ('brew "libsigc++"\n', "private/tools/libsigc++"),
            ('brew "foo.bar"\n', "private/tools/foo.bar"),
            ('  brew "bun"\n', "oven-sh/bun/bun"),
            ("brew 'bun'\n", "oven-sh/bun/bun"),
            ('brew "bun", args: ["HEAD"]\n', "oven-sh/bun/bun"),
            ("if true\n  brew 'bun'\nend\n", "oven-sh/bun/bun"),
        )
        for manifest, full_name in cases:
            with self.subTest(manifest=manifest):
                self.stub_package_sources(manifest, formulae=[full_name])
                result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                         "--acknowledge-trust-reset")
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(full_name, result.stdout)
                self.assertFalse(self.effect.exists())
                self.assertFalse((self.user / ".macos-dev-setup-backup").exists())

    def test_cleanup_blocks_casks_without_surviving_trust(self):
        """P2：短名、无授权完整名和错误来源的授权都不能保留实际第三方 cask 的信任。"""
        full_name = "private/apps/firefox"
        manifests = (
            'cask "firefox"\n',
            "  cask 'firefox', args: { language: 'zh-CN' }\n",
            'cask "private/apps/firefox"\n',
            'cask "private/apps/firefox", trusted: false\n',
            'cask "firefox", trusted: true\n',
            'cask "other/apps/firefox", trusted: true\n',
            'brew "private/apps/firefox", trusted: true\ncask "firefox"\n',
            'tap "private/apps", trusted: { formulae: ["firefox"] }\ncask "firefox"\n',
        )
        for manifest in manifests:
            with self.subTest(manifest=manifest):
                self.stub_package_sources(manifest, casks=[full_name])
                self.effect.unlink(missing_ok=True)
                self.trace.unlink(missing_ok=True)
                result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                         "--acknowledge-trust-reset")
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertIn(full_name, result.stdout)
                self.assertFalse(self.effect.exists())
                self.assertEqual(self.trace.read_text().splitlines(), ["ruby"])

    def test_cleanup_does_not_confuse_names_types_or_inactive_entries(self):
        """P2：名称按字面和类型匹配，注释及未执行的条件不触发来源冲突。"""
        self.stub_package_sources(
            'brew "fooxbar"\n'
            'brew "firefox"\n'
            '# brew "bun"\n'
            'brew "bun" if false\n'
            'cask "official-app"\n',
            formulae=["private/tools/foo.bar", "oven-sh/bun/bun", "git"],
            casks=["private/apps/firefox", "official-app"],
        )
        self.assert_ok(self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                       "--acknowledge-trust-reset"))
        self.assertEqual(self.trace.read_text().splitlines(), ["ruby", "trust", "bundle"])
        self.assertTrue(self.effect.exists())

    def test_cleanup_allows_explicit_package_and_tap_trust(self):
        """P2：完整来源及按包或按 tap 保留的信任不会被误拦，授权不能串到另一种类型。"""
        manifests = (
            'brew "private/tools/bun", trusted: true\n'
            'cask "private/apps/firefox", trusted: true\n',
            'tap "private/tools", trusted: true\nbrew "bun"\n'
            'tap "private/apps", trusted: true\ncask "firefox"\n',
            'tap "private/tools", trusted: { formulae: ["bun"] }\nbrew "bun"\n'
            'tap "private/apps", trusted: { casks: ["firefox"] }\ncask "firefox"\n',
        )
        for manifest in manifests:
            with self.subTest(manifest=manifest):
                self.stub_package_sources(manifest, formulae=["private/tools/bun"],
                                          casks=["private/apps/firefox"])
                self.trace.unlink(missing_ok=True)
                self.assert_ok(self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                               "--acknowledge-trust-reset"))
                self.assertEqual(self.trace.read_text().splitlines(), ["ruby", "trust", "bundle"])

    def test_cleanup_rejects_untrusted_full_formula_name(self):
        """P2：完整名称本身不是信任授权，清单重置后仍可能丢失来源信任。"""
        self.stub_package_sources('brew "private/tools/bun"\n', formulae=["private/tools/bun"])
        result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                 "--acknowledge-trust-reset")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("private/tools/bun", result.stdout)
        self.assertEqual(self.trace.read_text().splitlines(), ["ruby"])

    def test_cleanup_rejects_invalid_manifest_before_snapshot(self):
        """P2：清单解析失败必须在保存快照和清理之前退出。"""
        self.stub_package_sources('brew "bun"\nif\n', formulae=["oven-sh/bun/bun"])
        result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                 "--acknowledge-trust-reset")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("无法核对已安装包的来源", result.stdout)
        self.assertEqual(self.trace.read_text().splitlines(), ["ruby"])
        self.assertFalse((self.user / ".macos-dev-setup-backup").exists())

    def test_cleanup_migration_commands_preserve_shell_arguments(self):
        """P3：生成的命令在 Bash 和 zsh 下保留特殊路径，不执行路径中的命令替换。"""
        special = self.base / "带 空格 '单引号' \"双引号\" $(touch 不应出现) `touch 也不应出现` ; *"
        shutil.move(str(self.repo), str(special))
        self.repo = special
        self.stub_package_sources('brew "bun"\ncask "firefox"\n',
                                  formulae=["private/tools/bun"], casks=["private/apps/firefox"])
        result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                 "--acknowledge-trust-reset")
        self.assertNotEqual(result.returncode, 0)
        commands = [line.strip() for line in result.stdout.splitlines()
                    if line.strip().startswith("brew ")]
        self.assertEqual(len(commands), 3, result.stdout)
        expected = [
            ["uninstall", "--formula", "private/tools/bun"],
            ["uninstall", "--cask", "private/apps/firefox"],
            ["bundle", "install", "--file", str(self.repo / "Brewfile"), "--no-upgrade"],
        ]
        self.stub("brew", '''exec python3 -c 'import json, sys; print(json.dumps(sys.argv[1:]))' "$@"''')
        for shell in (BASH, "/bin/zsh"):
            for command, arguments in zip(commands, expected):
                with self.subTest(shell=shell, command=command):
                    parsed = subprocess.run([shell, "-f", "-c", command], env=self.env, cwd=self.base,
                                            capture_output=True, text=True, errors="replace", timeout=10)
                    self.assert_ok(parsed)
                    self.assertEqual(parsed.stdout.strip(), json.dumps(arguments))
        self.assertFalse((self.base / "不应出现").exists())
        self.assertFalse((self.base / "也不应出现").exists())

    def test_failed_or_invalid_trust_snapshot_blocks_cleanup(self):
        """A06：快照命令失败或格式无效时都不得执行清理。"""
        for body in ('echo broken; exit 4', 'echo invalid-json; exit 0'):
            with self.subTest(body=body):
                self.stub("brew", '[[ "$1" != ruby ]] || exit 0\n'
                          'if [[ "$1" == trust ]]; then ' + body +
                          '; fi\ntouch "$TEST_EFFECT"')
                result = self.run_script("brew-maintenance.sh", "--cleanup-force", "--yes",
                                         "--acknowledge-trust-reset")
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.effect.exists())

    def test_repeated_backup_keeps_original(self):
        """A07：显式复用备份根目录时，旧批次仍保留原内容。"""
        (self.user / ".zshrc").write_text("最初配置\n")
        backup_root = self.base / "备份目录"
        for _ in range(2):
            self.assert_ok(self.run_script("bootstrap.sh", "--skip-brew",
                                          env={"BACKUP_DIR": str(backup_root)}))
        copies = list(backup_root.glob("*/.zshrc"))
        self.assertEqual(len(copies), 2)
        self.assertIn("最初配置\n", [p.read_text() for p in copies])

    def test_failed_extension_export_keeps_old_file_and_continues(self):
        """A08：扩展导出失败不破坏旧文件，后续项和失败汇总正常执行。"""
        target = self.repo / "configs/vscode/extensions.txt.example"
        old = target.read_text()
        (self.user / ".tmux.conf").write_text("新 tmux 配置\n")
        self.stub("code", 'echo partial.output\nexit 7')
        result = self.run_script("backup-configs.sh", "--items", "vscode-extensions,tmux")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_text(), old)
        self.assertEqual((self.repo / "configs/tmux/tmux.conf").read_text(), "新 tmux 配置\n")
        self.assertIn("汇总", result.stdout)

    def test_missing_runtime_dependencies_fail(self):
        """A09：缺少运行时管理器不能报告成功。"""
        result = self.run_script("install-runtimes.sh", "--no-java")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("运行时初始化完成", result.stdout)

    def test_maven_failure_is_not_swallowed(self):
        """A09：SDKMAN 的 Maven 安装失败必须传递。"""
        sdk = self.user / ".sdkman/bin/sdkman-init.sh"
        sdk.parent.mkdir(parents=True)
        sdk.write_text('sdk() { [[ "$1 $2" != "install maven" ]]; }\n')
        result = self.run_script("install-runtimes.sh", "--no-node", "--no-python")
        self.assertNotEqual(result.returncode, 0)

    def test_runtime_failure_stops_stage_but_runs_other_stages(self):
        """A09：Node 安装失败不能继续设置默认版本，Python 仍独立执行。"""
        self.stub("fnm", '''
echo "fnm $*" >> "$TEST_TRACE"
[[ "$1" != install ]] || exit 9
''')
        self.stub("pnpm", 'exit 0')
        self.stub("pyenv", 'echo "pyenv $*" >> "$TEST_TRACE"')
        result = self.run_script("install-runtimes.sh", "--no-java")
        self.assertNotEqual(result.returncode, 0)
        trace = self.trace.read_text()
        self.assertNotIn("fnm default", trace)
        self.assertIn("pyenv install", trace)
        self.assertIn("pyenv exec python --version", trace)

    def test_node_works_without_corepack(self):
        """A14：Homebrew pnpm 路径不依赖 Corepack，也不会调用它。"""
        self.stub("fnm", 'echo "fnm $*" >> "$TEST_TRACE"')
        self.stub("node", 'echo v24.0.0')
        self.stub("pnpm", 'echo 10.0.0')
        self.stub("corepack", 'touch "$TEST_EFFECT"; exit 5')
        self.assert_ok(self.run_script("install-runtimes.sh", "--no-java", "--no-python"))
        self.assertFalse(self.effect.exists())

    def test_existing_java_and_maven_are_not_reinstalled(self):
        """A09：重复运行跳过已存在的 SDKMAN 版本，仍验证实际命令。"""
        sdk = self.user / ".sdkman/bin/sdkman-init.sh"
        sdk.parent.mkdir(parents=True)
        sdk.write_text('sdk() { echo "sdk $*" >> "$TEST_TRACE"; [[ "$1" != install ]]; }\n')
        for relative in ("java/8.0.492-zulu/bin/java", "maven/current/bin/mvn"):
            target = self.user / ".sdkman/candidates" / relative
            target.parent.mkdir(parents=True)
            target.write_text('#!/bin/bash\necho "版本验证" >> "$TEST_TRACE"\n')
            target.chmod(0o755)
        self.assert_ok(self.run_script("install-runtimes.sh", "--no-node", "--no-python"))
        self.assertNotIn("sdk install", self.trace.read_text())
        self.assertEqual(self.trace.read_text().count("版本验证"), 2)

    def test_sdkman_install_cannot_read_terminal_input(self):
        """SDKMAN 每次调用都重读用户配置，安装询问只能通过断开输入避免。"""
        sdk = self.user / ".sdkman/bin/sdkman-init.sh"
        sdk.parent.mkdir(parents=True)
        sdk.write_text('''sdk() {
  if [[ "$1" == install ]]; then
    read -r answer && { touch "$TEST_EFFECT"; return 9; }
    target="$SDKMAN_DIR/candidates/$2/${3:-current}/bin"
    mkdir -p "$target"
    printf '#!/bin/bash\\n' > "$target/${2/maven/mvn}"
    chmod +x "$target/${2/maven/mvn}"
    [[ "$2" != java ]] || { mkdir -p "$SDKMAN_DIR/candidates/maven"; }
  fi
}
''')
        result = subprocess.run(
            [BASH, str(self.repo / "scripts/install-runtimes.sh"), "--no-node", "--no-python"],
            env=self.env, cwd=self.repo, input="n\n" * 4,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=20,
        )
        self.assert_ok(result)
        self.assertFalse(self.effect.exists())

    def test_sdkman_download_failure_cleans_temporary_directory(self):
        """安装器下载失败不能继续执行，私有临时目录必须清理。"""
        self.stub("curl", 'exit 6')
        result = self.run_script("install-runtimes.sh", "--no-node", "--no-python")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.base.glob("macos-dev-setup-sdkman.*")), [])

    def test_cleanup_error_remains_failure(self):
        """A10：Homebrew 返回 1 不能被包装成成功。"""
        self.stub("brew", 'echo "模拟解析失败" >&2\nexit 1')
        result = self.run_script("brew-maintenance.sh", "--cleanup-preview")
        self.assertEqual(result.returncode, 1)
        self.assertIn("模拟解析失败", result.stdout)
        self.assertNotIn("确认后再执行", result.stdout)

    def test_upgrade_overrides_environment(self):
        """A11：显式升级参数能覆盖 Homebrew 的不升级环境变量。"""
        self.stub("brew", 'printf "%s\\n" "$*" >> "$TEST_TRACE"')
        for script in ("bootstrap.sh", "brew-maintenance.sh"):
            args = ("--upgrade",) if script == "bootstrap.sh" else ("--install", "--upgrade")
            self.assert_ok(self.run_script(script, *args, env={"HOMEBREW_BUNDLE_NO_UPGRADE": "1"}))
        self.assertTrue(all("--upgrade" in line for line in self.trace.read_text().splitlines()))

    def test_full_profile_reaches_actual_steps(self):
        """A12：报告里的 full 必须传递给安装预演、正式安装和严格验收。"""
        for name in ("quickstart.sh", "audit-environment.sh", "doctor.sh"):
            self.stub_script(name, f'echo "{name} $*" >> "$TEST_TRACE"')
        self.stub("make", 'exit 0')
        self.stub("brew", 'echo "Homebrew 7.0.11"')
        self.stub("xcode-select", 'exit 0')
        self.assert_ok(self.run_script("record-recovery-drill.sh", "--profile", "full",
                                       "--run-quickstart", "--output-dir", str(self.base / "报告")))
        trace = self.trace.read_text()
        self.assertIn("quickstart.sh --profile full --dry-run", trace)
        self.assertIn("quickstart.sh --profile full\n", trace)
        self.assertRegex(trace, r'audit-environment.sh .*--profile full.*--strict')

    def test_invalid_report_profile_writes_nothing(self):
        """A12：无效 profile 在生成报告之前被拒绝。"""
        dest = self.base / "报告"
        self.assertNotEqual(self.run_script("record-recovery-drill.sh", "--profile", "wrong",
                                            "--output-dir", str(dest)).returncode, 0)
        self.assertFalse(dest.exists())

    def test_quickstart_full_and_failure_propagation(self):
        """A12：完整启动传递 profile；运行时失败时不能进入成功自检。"""
        self.stub_script("bootstrap.sh", 'echo "$*" >> "$TEST_TRACE"')
        self.stub_script("install-runtimes.sh", 'exit 8')
        self.stub_script("doctor.sh", 'touch "$TEST_EFFECT"')
        result = self.run_script("quickstart.sh", "--profile", "full")
        self.assertEqual(result.returncode, 8)
        self.assertIn("--profile full", self.trace.read_text())
        self.assertFalse(self.effect.exists())

    def test_dry_run_has_no_writes(self):
        """预演既不执行外部安装，也不写家目录或仓库。"""
        self.stub("brew", 'touch "$TEST_EFFECT"; exit 5')
        before = {str(p.relative_to(self.repo)): p.read_bytes()
                  for p in self.repo.rglob("*") if p.is_file()}
        for script, args in (("quickstart.sh", ()), ("backup-configs.sh", ("--safe",)),
                             ("sync-back.sh", ("--include-brew",))):
            self.assert_ok(self.run_script(script, "--dry-run", *args,
                                           env={"MACOS_DEV_SETUP_LOGGING_ACTIVE": "0"}))
        self.assertFalse(self.effect.exists())
        self.assertEqual(list(self.user.iterdir()), [])
        after = {str(p.relative_to(self.repo)): p.read_bytes()
                 for p in self.repo.rglob("*") if p.is_file()}
        self.assertEqual(before, after)

    def test_local_mirror_available_on_first_source(self):
        """A13：新 Shell 首次加载即可使用本地镜像变量。"""
        (self.user / ".zshrc.local").write_text(
            'export MACOS_DEV_SETUP_HOMEBREW_BOTTLE_DOMAIN="https://example.invalid/bottles"\n')
        config = self.repo / "configs/zsh/zshrc"
        # 隔离本机第三方插件，保留变量加载的完整顺序。
        config.write_text(config.read_text().replace('source "/opt/homebrew/opt/zinit/zinit.zsh"', ':'))
        result = subprocess.run(
            ["/bin/zsh", "-f", "-c", 'source "$1"; print -r -- "${HOMEBREW_BOTTLE_DOMAIN:-未设置}"',
             "zsh", str(config)], env=self.env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, timeout=10,
        )
        self.assertEqual(result.stdout.strip(), "https://example.invalid/bottles")

    def test_runtime_baseline_and_override(self):
        """A14：Python 使用新补丁基线，并允许项目覆盖。"""
        result = self.run_script("install-runtimes.sh", "--dry-run", "--no-java", "--no-node")
        self.assert_ok(result)
        self.assertIn("3.12.16", result.stdout)
        result = self.run_script("install-runtimes.sh", "--dry-run", "--no-java", "--no-node",
                                 env={"PYTHON_VERSION": "3.11.14"})
        self.assertIn("3.11.14", result.stdout)


if __name__ == "__main__":
    unittest.main(verbosity=2)
