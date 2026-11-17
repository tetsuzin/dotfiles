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

# bootstrap / update 共通。mise を確認し、適用する環境のディレクトリへ移って設定を trust する。
function enter_environment() {
  check_environment
  export PATH="${HOME}/.local/bin:${PATH}"
  command -v mise &>/dev/null || fail "先に ./run.sh prepare を実行してください"

  # run.sh の実行はこの checkout の設定を適用する明示的な操作。
  # dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
  cd "${DOTFILES_ENV_DIR:?run.sh から実行してください}" || return
  mise trust mise.toml
  # フォルダフラグメントは独立した config root なので個別に trust する。WSL の設定を持たない環境もある。
  if [[ -n "${MISE_ENV:-}" && -f mise/conf.d/wsl/mise.wsl.toml ]]; then
    mise trust mise/conf.d/wsl/mise.wsl.toml
  fi
}
