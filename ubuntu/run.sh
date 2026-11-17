#!/usr/bin/env bash
# Ubuntu (WSL を含む) の入口。人が使うマシンと AI エージェントのワーカーは --env で選ぶ。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ENV_DIR}/../scripts/_functions"

run_command "${ENV_DIR}" "${ENV_DIR}/scripts" "$@"
