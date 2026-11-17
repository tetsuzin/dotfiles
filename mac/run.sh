#!/usr/bin/env bash
# macOS のセットアップ。共通の流れは ../scripts/run.sh にあり、ここには macOS 固有の処理を書く。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/run.sh
source "${ENV_DIR}/../scripts/run.sh"

function os_check() {
  [[ "${EUID}" -ne 0 ]] || fail "root では実行しないでください。必要な処理ではスクリプト内から sudo を使用します"
  [[ "$(uname -s)" == "Darwin" ]] || fail "macOS 以外の環境には対応していません: $(uname -s)"
  [[ "$(uname -m)" == "arm64" ]] || fail "未対応のアーキテクチャです: $(uname -m)"
}

function os_prepare() {
  # Homebrew と git が必要とする。
  if ! xcode-select -p &>/dev/null; then
    xcode-select --install || true
    fail "Xcode Command Line Tools が必要です。インストール完了後に再実行してください"
  fi

  # OS パッケージの導入元。mise bootstrap は Homebrew 本体を入れないためここで行う。
  if [[ ! -x /opt/homebrew/bin/brew ]]; then
    /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

function os_enter() {
  [[ -x /opt/homebrew/bin/brew ]] || fail "Homebrew が見つかりません。先に ./run.sh prepare を実行してください"
  eval "$(/opt/homebrew/bin/brew shellenv)"
}

function os_upgrade_packages() {
  mise bootstrap packages upgrade --manager brew
  mise bootstrap packages upgrade --manager brew-cask
}

function os_done() {
  log_info "完了しました。ログインシェルを再起動してください: exec zsh -l"
  log_info "Dock と Finder の設定を変えた場合は killall Dock Finder で反映されます"
}

main "$@"
