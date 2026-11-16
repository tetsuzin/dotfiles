#!/usr/bin/env bash
# AI エージェントのワーカー用 Ubuntu の入口。処理の本体は ubuntu と共通。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ENV_DIR}/../scripts/_functions"

run_command "${ENV_DIR}" "${ENV_DIR}/../scripts/ubuntu" "$@"
