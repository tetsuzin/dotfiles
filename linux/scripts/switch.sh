#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

function usage() {
  cat <<'HELP'
Usage: ./setup.sh switch [--debug] [--dry-run] [--link-force=y] [--update | --link-only]

  --dry-run       変更予定を表示する
  --update        宣言した apt パッケージと mise ツールを更新して適用する
  --link-only     dotfiles の配置のみ実行する (外部テーマ等は事前取得が必要)
  --link-force=y  競合する dotfiles の置き換えを許可する

Linux は Ubuntu 26 (x86_64)、mise 2026.10.14 以上に対応。
--update-only は macOS の flake.lock 更新専用です。
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
    --update-only) fail "Linux では --update-only は使いません。更新には --update を指定してください" ;;
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

check_linux_environment
export PATH="${HOME}/.local/bin:${PATH}"
command -v mise &>/dev/null || fail "先に ./setup.sh prepare を実行してください"
check_mise_version

# setup.sh の実行はこの checkout の設定を適用する明示的な操作。
# dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
cd "${SCRIPT_DIR}/.."
mise trust mise.toml
if [[ ${#mise_args[@]} -gt 0 ]]; then
  mise trust mise.wsl.toml
fi

if [[ "${link_only}" == true ]]; then
  mise "${mise_args[@]}" bootstrap --only dotfiles "${bootstrap_args[@]}"
elif [[ "${update}" == true ]]; then
  mise "${mise_args[@]}" bootstrap --update --skip task "${bootstrap_args[@]}"
  mise "${mise_args[@]}" bootstrap packages upgrade --manager apt
  mise "${mise_args[@]}" upgrade
  mise "${mise_args[@]}" run bootstrap
else
  mise "${mise_args[@]}" bootstrap "${bootstrap_args[@]}"
fi

if [[ "${dry_run}" != true ]]; then
  log_info "適用が完了しました。ログインシェルを再起動してください: exec bash -l"
fi
