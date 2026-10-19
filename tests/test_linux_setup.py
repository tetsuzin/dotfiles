"""Nix とネットワークを使わず、一時ホームで Linux の配置処理を検証する。"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
MISE = os.environ.get("TEST_MISE_BIN") or shutil.which("mise")


class LinuxSetupTest(unittest.TestCase):
  def setUp(self):
    self.tmp = tempfile.TemporaryDirectory(prefix="dotfiles-test-")
    self.addCleanup(self.tmp.cleanup)
    self.home = Path(self.tmp.name)
    self.env = {
      k: v for k, v in os.environ.items()
      if not k.startswith(("MISE_", "__MISE", "DOTNET", "XDG_"))
    }
    self.env.update({
      "HOME": str(self.home),
      "PATH": "/usr/bin:/bin",
      "XDG_CONFIG_HOME": str(self.home / ".config"),
      "XDG_DATA_HOME": str(self.home / ".local/share"),
      "XDG_CACHE_HOME": str(self.home / ".cache"),
      "XDG_STATE_HOME": str(self.home / ".local/state"),
      "MISE_TRUSTED_CONFIG_PATHS": f"{ROOT}:{self.home}",
      "MISE_OFFLINE": "true",
    })
    theme = self.home / ".local/share/dotfiles/eza-themes/themes/tokyonight.yml"
    theme.parent.mkdir(parents=True)
    theme.write_text("colors: {}\n")
    (self.home / ".local/share/dotfiles/lazyvim-starter").mkdir()

  def run_cmd(self, args, *, check=True, cwd=ROOT):
    result = subprocess.run(args, cwd=cwd, env=self.env, text=True,
                capture_output=True, timeout=60)
    if check:
      self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
    return result

  def mise(self, *args, profile=None):
    environment = ["-E", profile] if profile else []
    return self.run_cmd([MISE, "-C", str(ROOT / "linux"), *environment, *args])

  def test_dotfiles_are_idempotent_and_tools_are_global(self):
    self.mise("dotfiles", "apply", "--yes")
    self.mise("dotfiles", "apply", "--yes")
    self.mise("dotfiles", "status", "--missing")
    self.assertEqual((self.home / ".bashrc").resolve(),
            ROOT / "linux/dotfiles/HOME/.bashrc")
    self.assertFalse((self.home / ".config/mise/conf.d/wsl.toml").exists())
    configs = self.run_cmd([MISE, "config", "ls", "--json"], cwd=self.home)
    self.assertIn("conf.d/linux.toml", configs.stdout)
    self.assertIn("config.toml", configs.stdout)

  def test_conflicting_files_require_force(self):
    target = self.home / ".bashrc"
    target.write_text("# keep my settings\n")
    result = self.run_cmd([MISE, "-C", str(ROOT / "linux"),
               "dotfiles", "apply", "--yes"], check=False)
    self.assertNotEqual(result.returncode, 0)
    self.assertEqual(target.read_text(), "# keep my settings\n")
    self.mise("dotfiles", "apply", "--yes", "--force")
    self.assertTrue(target.is_symlink())

  def test_wsl_tools_are_deployed_only_for_wsl(self):
    self.mise("dotfiles", "apply", "--yes", profile="wsl")
    self.assertEqual((self.home / ".config/mise/conf.d/wsl.toml").resolve(),
            ROOT / "linux/wsl-tools.toml")
    tools = self.run_cmd([MISE, "ls", "--current", "--json"], cwd=self.home)
    self.assertIn("github:mame/wsl2-ssh-agent", json.loads(tools.stdout))

  def test_ubuntu_packages(self):
    result = self.mise("bootstrap", "packages", "status", "--json")
    self.assertIn("libicu78", result.stdout)

  def test_dry_run_does_not_deploy_files(self):
    self.mise("bootstrap", "--only", "dotfiles", "--dry-run")
    self.assertFalse((self.home / ".bashrc").exists())
    self.assertFalse((self.home / ".config/mise/config.toml").exists())

  def test_setup_entrypoint_without_nix(self):
    bin_dir = self.home / ".local/bin"
    bin_dir.mkdir(parents=True)
    (bin_dir / "mise").symlink_to(Path(MISE).resolve())
    self.run_cmd(["bash", "setup.sh", "bootstrap", "--link-only", "--dry-run"])
    self.assertFalse((self.home / ".bashrc").exists())

  def test_interactive_bash_has_mise_and_krew_path(self):
    self.mise("dotfiles", "apply", "--yes")
    bin_dir = self.home / ".local/bin"
    bin_dir.mkdir(parents=True)
    stub = bin_dir / "mise"
    stub.write_text('#!/bin/bash\necho "export TEST_MISE_ACTIVATED=yes"\n')
    stub.chmod(0o755)
    self.run_cmd(["bash", "--noprofile", "--rcfile", str(self.home / ".bashrc"),
           "-ic", '[[ "$TEST_MISE_ACTIVATED" == yes && ":$PATH:" == *":$HOME/.krew/bin:"* ]]'])

  def test_bootstrap_rejects_incompatible_flags(self):
    for flags in [["--update", "--dry-run"], ["--update", "--link-only"],
           ["--update-only"], ["--unknown"]]:
      result = self.run_cmd(["bash", "setup.sh", "bootstrap", *flags], check=False)
      self.assertNotEqual(result.returncode, 0)
      self.assertNotIn("Nix が見つかりません", result.stderr)

  def test_krew_and_wsl_links_are_idempotent(self):
    bin_dir = self.home / "bin"
    bin_dir.mkdir()
    scripts = {
      "krew": '#!/bin/bash\nif [[ "$1" == list ]]; then cat "$HOME/plugins" 2>/dev/null; else echo "$2" >> "$HOME/plugins"; fi\n',
      "grep": '#!/bin/bash\nif [[ "${*: -1}" == /proc/version ]]; then exit 0; fi\nexec /usr/bin/grep "$@"\n',
    }
    for name, content in scripts.items():
      p = bin_dir / name
      p.write_text(content)
      p.chmod(0o755)
    windows_home = self.home / "windows"
    for name in [".aws/credentials", ".kube/config"]:
      source = windows_home / name
      source.parent.mkdir(parents=True, exist_ok=True)
      source.write_text("test\n")
    self.env.update(PATH=f"{bin_dir}:/usr/bin:/bin", DOTFILES_WINDOWS_HOME=str(windows_home))
    for _ in range(2):
      self.run_cmd(["bash", "linux/scripts/post-bootstrap.sh"])
    self.assertEqual(len((self.home / "plugins").read_text().splitlines()), 9)
    self.assertEqual((self.home / ".aws/credentials").resolve(), windows_home / ".aws/credentials")
    target = self.home / ".kube/config"
    target.unlink()
    target.write_text("private config\n")
    result = self.run_cmd(["bash", "linux/scripts/post-bootstrap.sh"], check=False)
    self.assertNotEqual(result.returncode, 0)
    self.assertEqual(target.read_text(), "private config\n")


if __name__ == "__main__":
  if not MISE:
    raise SystemExit("mise 2026.10.14 以上、または TEST_MISE_BIN の指定が必要です")
  unittest.main()
