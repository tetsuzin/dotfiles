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

[[ "${EUID}" -ne 0 ]] ||
  fail "root では実行しないでください。必要な処理ではスクリプト内から sudo を使用します"

[[ -r /etc/os-release ]] || fail "/etc/os-release を読み込めません"
# shellcheck disable=SC1091
source /etc/os-release
[[ "${ID}" == "ubuntu" ]] || fail "Ubuntu 以外の環境には対応していません: ${ID}"

command -v sudo &>/dev/null || fail "sudo が必要です"

install_system_packages
install_nix

log_step "ホストの準備が完了しました"
log_info "続けて ./setup.sh switch を実行してください"
