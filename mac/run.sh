#!/usr/bin/env bash
# macOS の入口。
set -euo pipefail

ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${ENV_DIR}/../scripts/_functions"

run_command "${ENV_DIR}" "${ENV_DIR}/scripts" "$@"
