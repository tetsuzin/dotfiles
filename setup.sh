#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/scripts/_functions"

function usage() {
  cat <<'EOF'
Usage: ./setup.sh <command> [args...]

Commands:
  prepare  ホストの準備 (パッケージマネージャと Nix 環境のインストール)
  switch   nix 構成の適用と dotfiles のリンク

必要環境: Nix 2.26 以上

パッケージ更新:
  ./setup.sh switch --update       更新して構成を適用
  ./setup.sh switch --update-only  flake.lock の更新のみ

dotfiles のリンクのみ:
  ./setup.sh switch --link-only
  ./setup.sh switch --link-only --link-force=y  既存のファイルやディレクトリを上書き

既存の dotfiles を上書き:
  ./setup.sh switch --link-force=y

OS (linux / mac) は自動判定し、共通処理と <os>/scripts/ 配下の OS 別処理を実行します。
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
  prepare | switch)
    log_info "OS: ${os_name}"
    if [[ "${command}" == "switch" ]]; then
      OS_NAME="${os_name}" exec "${SCRIPT_DIR}/scripts/switch.sh" "$@"
    else
      exec "${SCRIPT_DIR}/${os_name}/scripts/prepare.sh" "$@"
    fi
    ;;
  -h | --help)
    usage
    ;;
  *)
    usage >&2
    fail "不明なコマンドです: ${command}"
    ;;
esac
