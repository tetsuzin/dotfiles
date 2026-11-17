#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../scripts/_functions"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/environment.sh"

function usage() {
  cat <<'HELP'
Usage: ./run.sh bootstrap [--debug] [--dry-run] [--link-force=y] [--link-only]
       ./run.sh link [--debug] [--dry-run] [--link-force=y]

  --dry-run       変更予定を表示する
  --link-only     dotfiles の配置のみ実行する。./run.sh link と同じ
  --link-force=y  競合する dotfiles の置き換えを許可する

パッケージとツールの更新は ./run.sh update を使う。
Windows は Git Bash から実行し、mise 2026.10.12 以上に対応。
HELP
}

dry_run=false
link_only=false
bootstrap_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug) set -x ;;
    --dry-run)
      dry_run=true
      bootstrap_args+=(--dry-run)
      ;;
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

enter_environment

if [[ "${link_only}" == true ]]; then
  mise bootstrap --only dotfiles "${bootstrap_args[@]}"
else
  mise bootstrap "${bootstrap_args[@]}"
fi

if [[ "${dry_run}" != true ]]; then
  log_info "適用が完了しました。新しい PowerShell を起動してください"
fi
