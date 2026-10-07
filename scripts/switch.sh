#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_functions"

function usage() {
  cat <<'EOF'
Usage: ./setup.sh switch [--debug] [--dry-run] [--update | --update-only]

Options:
  --update       flake.lock を更新してから構成を適用する
  --update-only  flake.lock の更新のみ行う
EOF
}

debug=false
dry_run=false
update=false
update_only=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --debug) debug=true ;;
    --dry-run) dry_run=true ;;
    --update) update=true ;;
    --update-only)
      update=true
      update_only=true
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      fail "不明な引数です: $1"
      ;;
  esac
  shift
done

[[ "${dry_run}" != "true" || "${update}" != "true" ]] ||
  fail "--dry-run は --update / --update-only と同時に指定できません"

# shellcheck disable=SC2034 # _functions の log_debug が参照する
LOG_DEBUG="${debug}"
log_debug "--debug=${debug}"
log_debug "--dry-run=${dry_run}"
log_debug "--update=${update}"
log_debug "--update-only=${update_only}"

if [[ "${debug}" == "true" ]]; then
  set -x
fi

[[ "${EUID}" -ne 0 ]] ||
  fail "root では実行しないでください。root 権限が必要な処理ではスクリプト内から sudo を使用します"

[[ "${OS_NAME:-}" == "linux" || "${OS_NAME:-}" == "mac" ]] ||
  fail "OS_NAME が設定されていません。./setup.sh switch から実行してください"

REPO_DIR="$(dirname "${SCRIPT_DIR}")"

# OS 固有の処理 (resolve_flake_attr / run_activation /
# post_activation_env / os_shell) を読み込む
# shellcheck disable=SC1091
source "${REPO_DIR}/${OS_NAME}/scripts/switch_hooks.sh"

command -v nix &>/dev/null ||
  fail "Nix が見つかりません。先に ./setup.sh prepare を実行してください"

NIX_DIR="${REPO_DIR}"

log_debug "OS_NAME: ${OS_NAME}"
log_debug "NIX_DIR: ${NIX_DIR}"

if [[ "${update_only}" != "true" ]]; then
  resolve_flake_attr
  log_debug "FLAKE_ATTR: ${flake_attr}"
fi

if [[ "${update}" == "true" ]]; then
  echo
  log_step "flake.lock の更新"
  nix --extra-experimental-features 'nix-command flakes' flake update --flake "${NIX_DIR}"
fi

if [[ "${update_only}" == "true" ]]; then
  log_info "flake.lock の更新が完了しました"
  exit 0
fi

echo
log_step "nix 構成の適用"

if [[ "${dry_run}" == "true" ]]; then
  nix --extra-experimental-features 'nix-command flakes' build --no-update-lock-file --dry-run "${flake_attr}"
else
  run_activation
  post_activation_env
fi

echo
log_step "DotfilesLinker の実行"

if [[ "${dry_run}" == "true" ]] && ! command -v DotfilesLinker &>/dev/null; then
  log_warning "DotfilesLinker は nix 構成の適用後に利用可能になるためスキップします"
else
  command -v DotfilesLinker &>/dev/null ||
    fail "DotfilesLinker をPATHに反映できませんでした"
  for dotfiles_root in "${REPO_DIR}/common/dotfiles" "${REPO_DIR}/${OS_NAME}/dotfiles"; do
    log_info "DOTFILES_ROOT: ${dotfiles_root}"
    export DOTFILES_ROOT="${dotfiles_root}"
    if [[ "${dry_run}" == "true" ]]; then
      DotfilesLinker --dry-run
    else
      DotfilesLinker
    fi
  done
fi

echo
log_step "セットアップ完了"
log_info "新しいシェルを起動するか、以下を実行してください:"
log_info "exec ${os_shell}"
