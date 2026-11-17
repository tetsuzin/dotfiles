#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

function usage() {
  cat <<'HELP'
Usage: ./run.sh update [--env workstation|worker] [--debug] [--link-force=y]

mise 本体、宣言した apt パッケージ、mise ツールを更新して適用する。

  --env NAME      適用する構成。workstation (既定) は人が使うマシン、worker は AI エージェントのワーカー
  --link-force=y  競合する dotfiles の置き換えを許可する

Linux は Ubuntu 26、mise 2026.10.14 以上に対応。
HELP
}

env_name=workstation
bootstrap_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) set -x ;;
    --link-force=y) bootstrap_args+=(--force-dotfiles) ;;
    --env)
      [[ $# -ge 2 ]] || fail "--env には workstation か worker を指定してください"
      env_name=$2
      shift
      ;;
    --env=*) env_name=${1#--env=} ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) fail "不明な引数です: $1" ;;
  esac
  shift
done

enter_environment "${env_name}"

# プラグインの更新は含めない。clone が壊れていても本体の更新を止めないため。
mise self-update --yes --no-plugins
mise bootstrap --update --skip task "${bootstrap_args[@]}"
mise bootstrap packages upgrade --manager apt
mise upgrade
# bootstrap タスクを持たない構成 (worker) では実行しない。
if mise tasks info bootstrap &>/dev/null; then
  mise run bootstrap
fi

log_info "更新が完了しました。ログインシェルを再起動してください: exec bash -l"
