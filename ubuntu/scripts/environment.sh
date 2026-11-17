# shellcheck shell=bash
# prepare / bootstrap / update 共通の対応環境チェック。
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
}

# bootstrap / update 共通。--env の値から mise のプロファイルを決め、設定を trust する。
#   workstation  人が使うマシン。最小構成に workstation を重ね、WSL では wsl も重ねる。
#   worker       AI エージェントのワーカー。最小構成だけを使う。
function enter_environment() {
  local env_name=$1
  check_environment

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

  export PATH="${HOME}/.local/bin:${PATH}"
  command -v mise &>/dev/null || fail "先に ./run.sh prepare を実行してください"

  # run.sh の実行はこの checkout の設定を適用する明示的な操作。
  # dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
  cd "${DOTFILES_ENV_DIR:?run.sh から実行してください}" || return
  mise trust mise.toml
  # プロファイルのフォルダは独立した config root なので個別に trust する。
  local profile profiles="${MISE_ENV:-}"
  for profile in ${profiles//,/ }; do
    mise trust "mise/conf.d/${profile}/mise.${profile}.toml"
  done
}
