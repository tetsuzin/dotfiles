#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

function usage() {
  cat <<'HELP'
Usage: ./setup.sh bootstrap [--debug] [--dry-run] [--link-force=y] [--update | --link-only]

  --dry-run       変更予定を表示する
  --update        宣言した Homebrew パッケージと mise ツールを更新して適用する
  --link-only     dotfiles の配置のみ実行する (外部テーマは事前取得が必要)
  --link-force=y  競合する dotfiles の置き換えを許可する

macOS は Apple Silicon、mise 2026.11.2 以上に対応。
HELP
}

dry_run=false
update=false
link_only=false
bootstrap_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) set -x ;;
    --dry-run)
      dry_run=true
      bootstrap_args+=(--dry-run)
      ;;
    --update) update=true ;;
    --link-only) link_only=true ;;
    --link-force=y) bootstrap_args+=(--force-dotfiles) ;;
    -h | --help)
      usage
      exit 0
      ;;
    *) fail "不明な引数です: $1" ;;
  esac
  shift
done
[[ "${update}" != true || "${dry_run}" != true ]] || fail "--update と --dry-run は併用できません"
[[ "${update}" != true || "${link_only}" != true ]] || fail "--update と --link-only は併用できません"

check_environment
[[ -x /opt/homebrew/bin/brew ]] || fail "Homebrew が見つかりません。先に ./setup.sh prepare を実行してください"
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="${HOME}/.local/bin:${PATH}"
command -v mise &>/dev/null || fail "先に ./setup.sh prepare を実行してください"

# setup.sh の実行はこの checkout の設定を適用する明示的な操作。
# dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
cd "${SCRIPT_DIR}/.."
mise trust mise.toml

# macOS 標準の bash 3.2 は set -u で空配列の展開がエラーになるため ${arr[@]+"${arr[@]}"} で渡す。
if [[ "${link_only}" == true ]]; then
  mise bootstrap --only dotfiles ${bootstrap_args[@]+"${bootstrap_args[@]}"}
elif [[ "${update}" == true ]]; then
  # プラグインの更新は含めない。clone が壊れていても本体の更新を止めないため。
  mise self-update --yes --no-plugins
  mise bootstrap --update --skip task ${bootstrap_args[@]+"${bootstrap_args[@]}"}
  mise bootstrap packages upgrade --manager brew
  mise bootstrap packages upgrade --manager brew-cask
  mise upgrade
  mise run bootstrap
else
  mise bootstrap ${bootstrap_args[@]+"${bootstrap_args[@]}"}
fi

if [[ "${dry_run}" != true ]]; then
  log_info "適用が完了しました。ログインシェルを再起動してください: exec zsh -l"
  log_info "Dock と Finder の設定を変えた場合は killall Dock Finder で反映されます"
fi
