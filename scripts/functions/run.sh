#!/usr/bin/env bash

function _run_usage() {
  cat <<'EOF'
Usage: ./run.sh <command> [args...]

適用したい環境のディレクトリ (ubuntu / ubuntu-worker / mac / windows) で実行します。

Commands:
  prepare    ホストの準備 (mise 本体。macOS は Homebrew、Windows は scoop も)
  bootstrap  環境の適用と dotfiles の配置

  ./run.sh bootstrap
  ./run.sh bootstrap --update
  ./run.sh bootstrap --link-only

どれも --dry-run で変更予定を確認できます。
既存の dotfiles を置き換える場合は --link-force=y を指定します。
EOF
}

# 各環境の run.sh から呼ぶ。scripts_dir の <command>.sh を、env_dir の設定に対して実行する。
function run_command() {
  local env_dir=$1
  local scripts_dir=$2
  shift 2

  if [[ $# -eq 0 ]]; then
    _run_usage
    exit 1
  fi

  local command=$1
  shift
  case "${command}" in
    prepare | bootstrap)
      export DOTFILES_ENV_DIR="${env_dir}"
      exec "${scripts_dir}/${command}.sh" "$@"
      ;;
    -h | --help)
      _run_usage
      ;;
    *)
      _run_usage >&2
      fail "不明なコマンドです: ${command}"
      ;;
  esac
}
