#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../scripts/_functions"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/environment.sh"

function usage() {
  cat <<'HELP'
Usage: ./run.sh update [--debug] [--link-force=y]

mise 本体、宣言した winget / scoop パッケージ、mise ツールを更新して適用する。

  --link-force=y  競合する dotfiles の置き換えを許可する

Windows は Git Bash から実行し、mise 2026.10.12 以上に対応。
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
mise bootstrap --update "${bootstrap_args[@]}"
mise bootstrap packages upgrade
mise upgrade

log_info "更新が完了しました。新しい PowerShell を起動してください"
