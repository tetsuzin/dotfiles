#!/usr/bin/env bash
# 人が使う Ubuntu マシン (WSL を含む) の入口。処理の本体は ubuntu-worker と共通。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ENV_DIR}/../scripts/_functions"

run_command "${ENV_DIR}" "${ENV_DIR}/../scripts/ubuntu" "$@"
