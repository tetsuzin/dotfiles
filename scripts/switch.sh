#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_functions"

function usage() {
  cat <<'EOF'
Usage: ./setup.sh switch [--debug] [--dry-run] [--link-force=y] [--update | --update-only | --link-only]

Options:
  --update        flake.lock を更新してから構成を適用する
  --update-only   flake.lock の更新のみ行う
  --link-only     DotfilesLinker のみ実行する (Nix は不要)
  --link-force=y  DotfilesLinker で既存のファイルやディレクトリを上書きする
EOF
}

function update_flake_lock() {
  echo
  log_step "flake.lock の更新"
  nix --extra-experimental-features 'nix-command flakes' flake update --flake "${NIX_DIR}"
}

function apply_nix_config() {
  resolve_flake_attr
  log_debug "FLAKE_ATTR: ${flake_attr}"

  echo
  log_step "nix 構成の適用"
  if [[ "${dry_run}" == "true" ]]; then
    nix --extra-experimental-features 'nix-command flakes' build --no-update-lock-file --dry-run "${flake_attr}"
  else
    run_activation
    post_activation_env
  fi
}

function run_dotfiles_linker() {
  local dotfiles_root

  echo
  log_step "DotfilesLinker の実行"

  if [[ "${dry_run}" == "true" && "${link_only}" != "true" ]] && ! command -v DotfilesLinker &>/dev/null; then
    log_warning "DotfilesLinker は nix 構成の適用後に利用可能になるためスキップします"
    return
  fi

  command -v DotfilesLinker &>/dev/null ||
    fail "DotfilesLinker が見つかりません。先に ./setup.sh switch で構成を適用してください"

  set --
  if [[ "${dry_run}" == "true" ]]; then
    set -- "$@" --dry-run
  fi
  if [[ "${link_force}" == "true" ]]; then
    set -- "$@" --force=y
  fi

  for dotfiles_root in "${REPO_DIR}/common/dotfiles" "${REPO_DIR}/${OS_NAME}/dotfiles"; do
    log_info "DOTFILES_ROOT: ${dotfiles_root}"
    DOTFILES_ROOT="${dotfiles_root}" DotfilesLinker "$@"
  done
}

debug=false
dry_run=false
update=false
update_only=false
link_only=false
link_force=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --debug) debug=true ;;
    --dry-run) dry_run=true ;;
    --link-force=y) link_force=true ;;
    --link-only) link_only=true ;;
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
[[ "${link_only}" != "true" || "${update}" != "true" ]] ||
  fail "--link-only は --update / --update-only と同時に指定できません"

# shellcheck disable=SC2034 # _functions の log_debug が参照する
LOG_DEBUG="${debug}"
log_debug "--debug=${debug}"
log_debug "--dry-run=${dry_run}"
log_debug "--update=${update}"
log_debug "--update-only=${update_only}"
log_debug "--link-only=${link_only}"
log_debug "--link-force=y: ${link_force}"

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

if [[ "${link_only}" != "true" ]]; then
  command -v nix &>/dev/null ||
    fail "Nix が見つかりません。先に ./setup.sh prepare を実行してください"
fi

NIX_DIR="${REPO_DIR}"

log_debug "OS_NAME: ${OS_NAME}"
log_debug "NIX_DIR: ${NIX_DIR}"

if [[ "${update}" == "true" ]]; then
  update_flake_lock
fi

if [[ "${update_only}" == "true" ]]; then
  log_info "flake.lock の更新が完了しました"
  exit 0
fi

if [[ "${link_only}" != "true" ]]; then
  apply_nix_config
fi

run_dotfiles_linker

echo
log_step "セットアップ完了"
if [[ "${link_only}" != "true" ]]; then
  log_info "新しいシェルを起動するか、以下を実行してください:"
  log_info "exec ${os_shell}"
fi
