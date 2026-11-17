#!/usr/bin/env bash
# ubuntu と mac の run.sh が読み込む共通の流れ。Windows は windows/run.ps1 が同じ役割を持つ。
#
# 各 OS の run.sh は ENV_DIR (自分のディレクトリ) を設定してこのファイルを読み込み、
# 次の関数を定義してから main "$@" を呼ぶ。
#   os_check             対応環境の確認
#   os_prepare           mise 本体を入れる前に必要な準備
#   os_enter             mise を実行する前の OS 固有の設定。mise に渡す引数 ARGS を書き換えてよい
#   os_upgrade_packages  update で OS パッケージを更新する
#   os_done              完了後の案内
#   os_usage             (任意) usage に足す OS 固有の説明

function log_info() {
  printf '[INFO ] %s\n' "$*"
}

function fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

function usage() {
  cat <<'EOF'
Usage: ./run.sh <command> [mise bootstrap のオプション...]

Commands:
  prepare    ホストの準備 (mise 本体と、その導入に必要なもの)
  bootstrap  環境の適用と dotfiles の配置
  update     mise 本体、宣言した OS パッケージ、mise ツールを更新して適用
  link       dotfiles の配置のみ

bootstrap / update / link の残りの引数は mise bootstrap にそのまま渡します。
  --dry-run         変更予定を表示する
  --force-dotfiles  競合する dotfiles の置き換えを許可する
EOF
  if declare -F os_usage >/dev/null; then
    echo
    os_usage
  fi
}

# パッケージマネージャ経由の mise が PATH にあっても、公式スクリプトの独立した mise を導入する。
# 導入済みなら触らない。更新は update と self_update.auto が担う。
function install_mise() {
  if [[ ! -x "${HOME}/.local/bin/mise" ]]; then
    local installer
    installer="$(mktemp)"
    curl --proto '=https' --tlsv1.2 -fsSL https://mise.run -o "${installer}"
    MISE_INSTALL_PATH="${HOME}/.local/bin/mise" sh "${installer}"
    rm -f "${installer}"
  fi
}

# bootstrap / update / link 共通。mise を確認し、この環境の設定を trust する。
function enter() {
  os_check
  export PATH="${HOME}/.local/bin:${PATH}"
  command -v mise &>/dev/null || fail "先に ./run.sh prepare を実行してください"

  # run.sh の実行はこの checkout の設定を適用する明示的な操作。
  # dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
  cd "${ENV_DIR}" || exit
  mise trust mise.toml
  os_enter
}

# mise に渡す引数。macOS 標準の bash 3.2 は set -u で空配列の展開がエラーになるため、
# 使うときは ${ARGS[@]+"${ARGS[@]}"} と書く。
ARGS=()

function is_dry_run() {
  local arg
  for arg in ${ARGS[@]+"${ARGS[@]}"}; do
    [[ "${arg}" != --dry-run ]] || return 0
  done
  return 1
}

function main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi
  local command=$1
  shift
  ARGS=("$@")

  case "${command}" in
    prepare)
      os_check
      os_prepare
      install_mise
      log_info "準備が完了しました。続けて ./run.sh bootstrap を実行してください"
      ;;
    bootstrap)
      enter
      mise bootstrap ${ARGS[@]+"${ARGS[@]}"}
      is_dry_run || os_done
      ;;
    link)
      enter
      mise bootstrap --only dotfiles ${ARGS[@]+"${ARGS[@]}"}
      is_dry_run || os_done
      ;;
    update)
      enter
      # プラグインの更新は含めない。clone が壊れていても本体の更新を止めないため。
      mise self-update --yes --no-plugins
      mise bootstrap --update --skip task ${ARGS[@]+"${ARGS[@]}"}
      os_upgrade_packages
      mise upgrade
      # bootstrap タスクを持たない構成 (Ubuntu の worker) では実行しない。
      if mise tasks info bootstrap &>/dev/null; then
        mise run bootstrap
      fi
      os_done
      ;;
    -h | --help)
      usage
      ;;
    *)
      usage >&2
      fail "不明なコマンドです: ${command}"
      ;;
  esac
}
