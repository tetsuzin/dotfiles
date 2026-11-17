# shellcheck shell=bash
# bootstrap / update 共通。Git Bash と mise を確認し、windows/ へ移って設定を trust する。
function enter_environment() {
  case "$(uname -s)" in
    MINGW* | MSYS*) ;;
    *) fail "Windows の Git Bash で実行してください: $(uname -s)" ;;
  esac
  command -v mise &>/dev/null || fail "mise が見つかりません。先に ./run.sh prepare を実行してください"

  # run.sh の実行はこの checkout の設定を適用する明示的な操作。
  # dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
  cd "$(dirname "${BASH_SOURCE[0]}")/.." || return
  mise trust mise.toml
}
