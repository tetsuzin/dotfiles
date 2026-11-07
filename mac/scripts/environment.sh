# shellcheck shell=bash
# prepare / bootstrap 共通の対応環境チェック。
function check_environment() {
  [[ "${EUID}" -ne 0 ]] || fail "root では実行しないでください。必要な処理ではスクリプト内から sudo を使用します"
  [[ "$(uname -s)" == "Darwin" ]] || fail "macOS 以外の環境には対応していません: $(uname -s)"
  [[ "$(uname -m)" == "arm64" ]] || fail "未対応のアーキテクチャです: $(uname -m)"
}
