#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

check_environment
command -v sudo &>/dev/null || fail "sudo が必要です"

# mise 自体の取得に必要な最小限のパッケージ。
# その他の OS パッケージは mise bootstrap で導入する。
sudo apt-get update
sudo apt-get install -y ca-certificates curl git

export PATH="${HOME}/.local/bin:${PATH}"
# Nix 版が PATH にあっても、Nix を削除できる独立した mise を最新版で導入する。
# 必要な最低バージョンは linux/mise.toml の min_version が検査する。
if [[ -x "${HOME}/.local/bin/mise" ]]; then
  "${HOME}/.local/bin/mise" self-update --yes
else
  installer="$(mktemp)"
  trap 'rm -f "${installer}"' EXIT
  curl --proto '=https' --tlsv1.2 -fsSL https://mise.run -o "${installer}"
  MISE_INSTALL_PATH="${HOME}/.local/bin/mise" sh "${installer}"
fi
hash -r

log_info "準備が完了しました。続けて ./setup.sh bootstrap を実行してください"
