#!/usr/bin/env bash
# 人が使う Ubuntu マシン (WSL を含む) の入口。スクリプトは ubuntu-worker からも使う。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ENV_DIR}/../scripts/_functions"

run_command "${ENV_DIR}" "${ENV_DIR}/scripts" "$@"
