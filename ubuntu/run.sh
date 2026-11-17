#!/usr/bin/env bash
# Ubuntu (WSL を含む) のセットアップ。共通の流れは ../scripts/run.sh にあり、ここには Ubuntu 固有の処理を書く。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/run.sh
source "${ENV_DIR}/../scripts/run.sh"

function os_usage() {
  cat <<'EOF'
Ubuntu では bootstrap / update / link に --env で構成を指定できます。
  --env workstation  人が使うマシン (既定)。WSL では WSL 用の設定も重ねる
  --env worker       AI エージェントのワーカー。最小構成だけを適用する
EOF
}

function os_check() {
  [[ "${EUID}" -ne 0 ]] || fail "root では実行しないでください"
  [[ "$(uname -s)" == "Linux" ]] || fail "Linux で実行してください"
  [[ -r /etc/os-release ]] || fail "/etc/os-release を読み込めません"

  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID}" == "ubuntu" ]] || fail "Ubuntu 以外には対応していません: ${ID}"
  case "${VERSION_ID}" in
    26.*) ;;
    *) fail "未対応の Ubuntu バージョンです: ${VERSION_ID}" ;;
  esac
}

# mise 自体の取得に必要な最小限のパッケージ。導入済みなら apt には触らない。
# これらを含む OS パッケージは mise bootstrap が packages.toml の宣言で管理する。
function os_prepare() {
  command -v sudo &>/dev/null || fail "sudo が必要です"
  if ! command -v curl &>/dev/null || ! command -v git &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl git
  fi
}

# ARGS から --env を取り出し、mise のプロファイルを決める。残りは mise bootstrap に渡る。
function os_enter() {
  local env_name=workstation rest=()
  set -- "${ARGS[@]}"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --env)
        [[ $# -ge 2 ]] || fail "--env には workstation か worker を指定してください"
        env_name=$2
        shift
        ;;
      --env=*) env_name=${1#--env=} ;;
      *) rest+=("$1") ;;
    esac
    shift
  done
  ARGS=("${rest[@]}")

  case "${env_name}" in
    workstation)
      export MISE_ENV=workstation
      if grep -qi microsoft /proc/version; then
        MISE_ENV+=",wsl"
      fi
      ;;
    worker) unset MISE_ENV ;;
    *) fail "不明な環境です: ${env_name} (workstation か worker を指定してください)" ;;
  esac

  # プロファイルのフォルダは独立した config root なので個別に trust する。
  local profile profiles="${MISE_ENV:-}"
  for profile in ${profiles//,/ }; do
    mise trust "mise/conf.d/${profile}/mise.${profile}.toml"
  done
}

function os_upgrade_packages() {
  mise bootstrap packages upgrade --manager apt
}

function os_done() {
  log_info "完了しました。ログインシェルを再起動してください: exec bash -l"
}

main "$@"
