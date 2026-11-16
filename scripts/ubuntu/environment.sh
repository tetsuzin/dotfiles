# shellcheck shell=bash
# prepare / bootstrap 共通の対応環境チェック。
function check_environment() {
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

  # WSL では mise.wsl.toml も読む。
  if grep -qi microsoft /proc/version; then
    export MISE_ENV=wsl
  fi
}
