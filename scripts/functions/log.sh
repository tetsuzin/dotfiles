#!/usr/bin/env bash

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
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

function log_info() {
  _log "INFO " "${GREEN}" 1 "$@"
}

function log_error() {
  _log "ERROR" "${RED}" 2 "$@"
}

function fail() {
  log_error "$@"
  exit 1
}
