#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../scripts/_functions"

function install_system_packages() {
  local -a packages=(
    ca-certificates
    curl
    libatomic1
    openssh-server
  )

  case "${VERSION_ID}" in
    24.*) packages+=(libicu74) ;;
    26.*) packages+=(libicu78) ;;
    *) fail "未対応の Ubuntu バージョンです: ${VERSION_ID}" ;;
  esac

  log_step "システムパッケージのインストール"
  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
}

function install_lix() {
  local nix_version
  local nix_version_output

  if command -v nix &>/dev/null; then
    nix_version_output="$(nix --version)"
    nix_version="${nix_version_output%%$'\n'*}"
    [[ "${nix_version_output}" == *Lix* ]] ||
      fail "Lix 以外の Nix がインストールされています: ${nix_version}"
    log_info "Lix はインストール済みです: ${nix_version}"
    return
  fi

  log_step "Lix のインストール"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.lix.systems/lix |
    sh -s -- install --no-confirm

  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  command -v nix &>/dev/null ||
    fail "Lix をPATHに反映できませんでした。シェルを開き直して再実行してください"

  nix_version_output="$(nix --version)"
  nix_version="${nix_version_output%%$'\n'*}"
  [[ "${nix_version_output}" == *Lix* ]] ||
    fail "Lix のインストールを確認できませんでした: ${nix_version}"
}

[[ "${EUID}" -ne 0 ]] ||
  fail "root では実行しないでください。必要な処理ではスクリプト内から sudo を使用します"

[[ -r /etc/os-release ]] || fail "/etc/os-release を読み込めません"
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID}" == "ubuntu" ]] || fail "Ubuntu 以外の環境には対応していません: ${ID}"

command -v sudo &>/dev/null || fail "sudo が必要です"

install_system_packages
install_lix

log_step "ホストの準備が完了しました"
log_info "続けて ./setup.sh switch を実行してください"
