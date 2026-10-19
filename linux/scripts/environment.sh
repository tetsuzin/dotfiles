# shellcheck shell=bash
# prepare / switch 共通の対応環境チェック。
function check_linux_environment() {
  [[ "${EUID}" -ne 0 ]] || fail "root では実行しないでください"
  [[ "$(uname -s)" == "Linux" ]] || fail "Linux で実行してください"
  [[ "$(uname -m)" == "x86_64" ]] || fail "対応アーキテクチャは x86_64 です"
  [[ -r /etc/os-release ]] || fail "/etc/os-release を読み込めません"
  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID}" == "ubuntu" ]] || fail "Ubuntu 以外には対応していません: ${ID}"
  case "${VERSION_ID}" in
    24.*) mise_environment=ubuntu24 ;;
    26.*) mise_environment=ubuntu26 ;;
    *) fail "未対応の Ubuntu バージョンです: ${VERSION_ID}" ;;
  esac
  if grep -qi microsoft /proc/version; then
    mise_environment+=,wsl
  fi
}

function check_mise_version() {
  local current
  current="$(mise --version | cut -d ' ' -f 1)"
  [[ "$(printf '%s\n' 2026.10.14 "${current}" | sort -V | head -n 1)" == 2026.10.14 ]] ||
    fail "mise 2026.10.14 以上が必要です。./setup.sh prepare を実行してください"
}
