#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

check_environment
command -v sudo &>/dev/null || fail "sudo が必要です"

# mise 自体の取得に必要な最小限のパッケージ。導入済みなら apt には触らない。
# これらを含む OS パッケージは mise bootstrap が packages.toml の宣言で管理する。
if ! command -v curl &>/dev/null || ! command -v git &>/dev/null; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl git
fi

export PATH="${HOME}/.local/bin:${PATH}"
# パッケージマネージャ経由の mise が PATH にあっても、公式スクリプトの独立した mise を導入する。
# 導入済みなら触らない。更新は bootstrap --update と self_update.auto が担う。
# 必要な最低バージョンは ubuntu/mise.toml の min_version が検査する。
if [[ ! -x "${HOME}/.local/bin/mise" ]]; then
  installer="$(mktemp)"
  trap 'rm -f "${installer}"' EXIT
  curl --proto '=https' --tlsv1.2 -fsSL https://mise.run -o "${installer}"
  MISE_INSTALL_PATH="${HOME}/.local/bin/mise" sh "${installer}"
fi
hash -r

log_info "準備が完了しました。続けて ./setup.sh bootstrap を実行してください"
