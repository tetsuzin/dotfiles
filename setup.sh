#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/_functions"

function usage() {
  cat <<'EOF'
Usage: ./setup.sh <command> [args...]

Commands:
  prepare    ホストの準備 (mise 本体。macOS は Homebrew、Windows は scoop も)
  bootstrap  環境の適用と dotfiles の配置

必要環境: Linux は mise 2026.10.14 以上、Windows は Git Bash と mise 2026.10.12 以上、
macOS は Apple Silicon と mise 2026.11.2 以上
Windows では setup.cmd <command> でも実行できます (prepare は PowerShell、他は Git Bash に転送)。

  ./setup.sh bootstrap
  ./setup.sh bootstrap --update
  ./setup.sh bootstrap --link-only

どれも --dry-run で変更予定を確認できます。
既存の dotfiles を置き換える場合は --link-force=y を指定します。
OS (ubuntu / mac / windows) は自動判定します。
EOF
}

[[ $# -ge 1 ]] || {
  usage
  exit 1
}

command="$1"
shift

case "$(uname -s)" in
  Linux) os_name="ubuntu" ;;
  Darwin) os_name="mac" ;;
  MINGW* | MSYS*) os_name="windows" ;;
  *) fail "未対応の OS です: $(uname -s)" ;;
esac

case "${command}" in
  prepare)
    log_info "OS: ${os_name}"
    if [[ "${os_name}" == windows ]]; then
      # Windows の prepare は winget を使うため PowerShell で実行する。
      # PowerShell 7 (pwsh) が無い初回は Windows PowerShell 5.1 で動かす。
      powershell="$(command -v pwsh || command -v powershell.exe)"
      exec "${powershell}" -NoProfile -ExecutionPolicy Bypass \
        -File "$(cygpath -w "${SCRIPT_DIR}/windows/scripts/prepare.ps1")" "$@"
    fi
    exec "${SCRIPT_DIR}/${os_name}/scripts/prepare.sh" "$@"
    ;;
  bootstrap)
    exec "${SCRIPT_DIR}/${os_name}/scripts/bootstrap.sh" "$@"
    ;;
  switch)
    fail "switch は廃止しました。macOS でも ./setup.sh bootstrap を使ってください"
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    fail "不明なコマンドです: ${command}"
    ;;
esac
