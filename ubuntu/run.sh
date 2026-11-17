#!/usr/bin/env bash
# Ubuntu (WSL を含む) のセットアップ。共通の流れは ../scripts/run.sh にあり、ここには Ubuntu 固有の処理を書く。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../scripts/run.sh
source "${ENV_DIR}/../scripts/run.sh"

function os_usage() {
  cat <<'EOF'
Ubuntu では初回の bootstrap に --env でこのマシンの構成を指定します。
指定は ~/.config/mise/miserc.local.toml に記録され、以降は省略できます。
  --env workstation  人が使うマシン。WSL では WSL 用の設定も重ねる
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

# ARGS から --env を取り出し、このマシンの構成を記録する。残りは mise bootstrap に渡る。
# 構成は mise がマシンごとに読む miserc.local.toml の env に書くので、指定は初回だけでよい。
# 以降は run.sh でも素の mise コマンドでも同じプロファイルが有効になる。
function os_enter() {
  local env_name="" rest=()
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

  local role_file="${XDG_CONFIG_HOME:-${HOME}/.config}/mise/miserc.local.toml"
  local envs
  case "${env_name}" in
    "")
      [[ -f "${role_file}" ]] ||
        fail "このマシンの構成が未設定です。初回は --env workstation か --env worker を指定してください"
      ;;
    workstation)
      envs='"workstation"'
      if grep -qi microsoft /proc/version; then
        envs+=', "wsl"'
      fi
      ;;
    worker) envs="" ;;
    *) fail "不明な環境です: ${env_name} (workstation か worker を指定してください)" ;;
  esac
  if [[ -n "${env_name}" ]]; then
    # trust と同じく、dry-run でも記録する。ホスト構成は変更しない。
    mkdir -p "$(dirname "${role_file}")"
    printf '# ubuntu/run.sh --env %s が書いたこのマシンの構成。\nenv = [%s]\n' "${env_name}" "${envs}" >"${role_file}"
  fi

  # プロファイルのフォルダは独立した config root なので個別に trust する。
  mise trust mise/conf.d/workstation/mise.workstation.toml
  mise trust mise/conf.d/wsl/mise.wsl.toml
}

function os_upgrade_packages() {
  mise bootstrap packages upgrade --manager apt
}

function os_done() {
  log_info "完了しました。ログインシェルを再起動してください: exec bash -l"
}

main "$@"
