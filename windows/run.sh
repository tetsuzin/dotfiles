#!/usr/bin/env bash
# Windows の Git Bash からの入口。cmd や PowerShell からは run.cmd を使う。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ENV_DIR}/../scripts/_functions"

if [[ "${1:-}" == prepare ]]; then
  shift
  # prepare は winget を使うため PowerShell で実行する。
  # PowerShell 7 (pwsh) が無い初回は Windows PowerShell 5.1 で動かす。
  powershell="$(command -v pwsh || command -v powershell.exe)"
  exec "${powershell}" -NoProfile -ExecutionPolicy Bypass \
    -File "$(cygpath -w "${ENV_DIR}/scripts/prepare.ps1")" "$@"
fi

run_command "${ENV_DIR}" "${ENV_DIR}/scripts" "$@"
