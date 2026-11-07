#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../scripts/_functions"
source "${SCRIPT_DIR}/environment.sh"

check_environment

# Homebrew と git が必要とする。
if ! xcode-select -p &>/dev/null; then
  xcode-select --install || true
  fail "Xcode Command Line Tools が必要です。インストール完了後に再実行してください"
fi

# OS パッケージの導入元。mise bootstrap は Homebrew 本体を入れないためここで行う。
# nix-homebrew が入れた Homebrew は git リポジトリを持たず brew 本体が Nix store にあるため、
# 公式インストーラで同じ prefix に入れ直す。Cellar と Caskroom は保持される。
if [[ ! -d /opt/homebrew/.git ]]; then
  /bin/bash -c "$(curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

export PATH="${HOME}/.local/bin:${PATH}"
# Nix や Homebrew 版が PATH にあっても、独立した mise を最新版で導入する。
# 必要な最低バージョンは mac/mise.toml の min_version が検査する。
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
