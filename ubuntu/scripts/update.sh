#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

function usage() {
  cat <<'HELP'
Usage: ./run.sh update [--debug] [--link-force=y]

mise 本体、宣言した apt パッケージ、mise ツールを更新して適用する。

  --link-force=y  競合する dotfiles の置き換えを許可する

Linux は Ubuntu 26、mise 2026.10.14 以上に対応。
HELP
}

bootstrap_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) set -x ;;
    --link-force=y) bootstrap_args+=(--force-dotfiles) ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) fail "不明な引数です: $1" ;;
  esac
  shift
done

enter_environment

# プラグインの更新は含めない。clone が壊れていても本体の更新を止めないため。
mise self-update --yes --no-plugins
mise bootstrap --update --skip task "${bootstrap_args[@]}"
mise bootstrap packages upgrade --manager apt
mise upgrade
# bootstrap タスクを持たない環境 (ubuntu-worker) では実行しない。
if mise tasks info bootstrap &>/dev/null; then
  mise run bootstrap
fi

log_info "更新が完了しました。ログインシェルを再起動してください: exec bash -l"
