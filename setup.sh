#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/_functions"

function usage() {
  cat <<'EOF'
Usage: ./setup.sh <command> [args...]

Commands:
  prepare    ホストの準備 (Linux: mise / macOS: Nix)
  bootstrap  Linux の環境適用と dotfiles の配置
  switch     macOS の Nix 構成適用と dotfiles の配置

必要環境: Linux は mise 2026.10.14 以上、macOS は Nix 2.26 以上

Linux:
  ./setup.sh bootstrap
  ./setup.sh bootstrap --update
  ./setup.sh bootstrap --link-only

macOS:
  ./setup.sh switch
  ./setup.sh switch --update
  ./setup.sh switch --update-only  flake.lock の更新のみ

どちらも --dry-run で変更予定を確認できます。
既存の dotfiles を置き換える場合は --link-force=y を指定します。
OS (linux / mac) は自動判定します。
EOF
}

[[ $# -ge 1 ]] || {
  usage
  exit 1
}

command="$1"
shift

case "$(uname -s)" in
  Linux) os_name="linux" ;;
  Darwin) os_name="mac" ;;
  *) fail "未対応の OS です: $(uname -s)" ;;
esac

case "${command}" in
  prepare)
    log_info "OS: ${os_name}"
    exec "${SCRIPT_DIR}/${os_name}/scripts/prepare.sh" "$@"
    ;;
  bootstrap)
    [[ "${os_name}" == linux ]] || fail "macOS では ./setup.sh switch を使ってください"
    exec "${SCRIPT_DIR}/linux/scripts/bootstrap.sh" "$@"
    ;;
  switch)
    [[ "${os_name}" == mac ]] || fail "Linux では ./setup.sh bootstrap を使ってください"
    OS_NAME="${os_name}" exec "${SCRIPT_DIR}/scripts/switch.sh" "$@"
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    fail "不明なコマンドです: ${command}"
    ;;
esac
