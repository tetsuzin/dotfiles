#!/usr/bin/env bash

RED=$'\033[0;31m'
YELLOW=$'\033[1;33m'
GREEN=$'\033[0;32m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

function _log() {
  local label=$1
  local color=$2
  local fd=$3
  shift 3

  local prefix=""
  local suffix=""

  if [[ -t "${fd}" && "${NO_COLOR+x}" != "x" && "${TERM:-}" != "dumb" ]]; then
    prefix="${color}"
    suffix="${NC}"
  fi

  printf '%s[%s]%s %s\n' \
    "${prefix}" "${label}" "${suffix}" "$*" >&"${fd}"
}

function log_step() {
  _log "STEP " "${GREEN}" 1 "$@"
}

function log_debug() {
  [[ "${LOG_DEBUG:-false}" == "true" ]] || return 0
  _log "DEBUG" "${CYAN}" 1 "$@"
}

function log_info() {
  _log "INFO " "${GREEN}" 1 "$@"
}

function log_warning() {
  _log "WARN " "${YELLOW}" 2 "$@"
}

function log_error() {
  _log "ERROR" "${RED}" 2 "$@"
}

function fail() {
  log_error "$@"
  exit 1
}
