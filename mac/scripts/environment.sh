# shellcheck shell=bash
# prepare / bootstrap 共通の対応環境チェック。
function check_environment() {
  [[ "${EUID}" -ne 0 ]] || fail "root では実行しないでください。必要な処理ではスクリプト内から sudo を使用します"
  [[ "$(uname -s)" == "Darwin" ]] || fail "macOS 以外の環境には対応していません: $(uname -s)"
  [[ "$(uname -m)" == "arm64" ]] || fail "未対応のアーキテクチャです: $(uname -m)"
}

# bootstrap / update 共通。Homebrew と mise を確認し、mac/ へ移って設定を trust する。
function enter_environment() {
  check_environment
  [[ -x /opt/homebrew/bin/brew ]] || fail "Homebrew が見つかりません。先に ./run.sh prepare を実行してください"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH="${HOME}/.local/bin:${PATH}"
  command -v mise &>/dev/null || fail "先に ./run.sh prepare を実行してください"

  # run.sh の実行はこの checkout の設定を適用する明示的な操作。
  # dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
  cd "$(dirname "${BASH_SOURCE[0]}")/.." || return
  mise trust mise.toml
}
