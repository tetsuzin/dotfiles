#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

function usage() {
  cat <<'HELP'
Usage: ./run.sh update [--debug] [--link-force=y]

mise 本体、宣言した Homebrew パッケージ、mise ツールを更新して適用する。

  --link-force=y  競合する dotfiles の置き換えを許可する

macOS は Apple Silicon、mise 2026.11.2 以上に対応。
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
# macOS 標準の bash 3.2 は set -u で空配列の展開がエラーになるため ${arr[@]+"${arr[@]}"} で渡す。
mise bootstrap --update --skip task ${bootstrap_args[@]+"${bootstrap_args[@]}"}
mise bootstrap packages upgrade --manager brew
mise bootstrap packages upgrade --manager brew-cask
mise upgrade
mise run bootstrap

log_info "更新が完了しました。ログインシェルを再起動してください: exec zsh -l"
log_info "Dock と Finder の設定を変えた場合は killall Dock Finder で反映されます"
