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
