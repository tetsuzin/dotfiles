#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../scripts/_functions"

function check_xcode_clt() {
  log_step "Xcode Command Line Tools の確認"

  if xcode-select -p &>/dev/null; then
    log_info "Xcode Command Line Tools はインストール済みです: $(xcode-select -p)"
    return
  fi

  xcode-select --install || true
  fail "Xcode Command Line Tools が必要です。インストール完了後に再実行してください"
}

function install_nix() {
  local nix_version

  if command -v nix &>/dev/null; then
    nix_version="$(nix --version | head -n 1)"
    log_info "Nix はインストール済みです: ${nix_version}"
    return
  fi

  log_step "Nix のインストール (Determinate Systems installer)"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm

  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  command -v nix &>/dev/null ||
    fail "Nix をPATHに反映できませんでした。シェルを開き直して再実行してください"

  nix_version="$(nix --version | head -n 1)"
  log_info "Nix をインストールしました: ${nix_version}"
}

[[ "${EUID}" -ne 0 ]] ||
  fail "root では実行しないでください。必要な処理ではスクリプト内から sudo を使用します"

[[ "$(uname -s)" == "Darwin" ]] ||
  fail "macOS 以外の環境には対応していません: $(uname -s)"
[[ "$(uname -m)" == "arm64" ]] ||
  fail "未対応のアーキテクチャです: $(uname -m)"

check_xcode_clt
install_nix

log_step "ホストの準備が完了しました"
log_info "続けて ./setup.sh switch を実行してください"
