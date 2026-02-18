#!/usr/bin/env bash

BACKUP_ROOT="/Users/pedroangones/srv/backups"
LOG_FILE="${BACKUP_ROOT}/backup.log"

timestamp() {
  date '+%Y-%m-%d %H:%M:%S %Z'
}

today() {
  date '+%Y-%m-%d'
}

log_line() {
  local level="$1"
  local message="$2"
  mkdir -p "${BACKUP_ROOT}"
  printf '[%s] [%s] %s\n' "$(timestamp)" "$level" "$message" >> "${LOG_FILE}"
}

stop_container_if_running() {
  local name="$1"
  if docker ps --format '{{.Names}}' | rg -x "$name" >/dev/null 2>&1; then
    docker stop "$name" >/dev/null
    echo "stopped"
    return 0
  fi
  if docker ps -a --format '{{.Names}}' | rg -x "$name" >/dev/null 2>&1; then
    echo "already_stopped"
    return 0
  fi
  echo "missing"
  return 0
}

start_container_if_exists() {
  local name="$1"
  if docker ps -a --format '{{.Names}}' | rg -x "$name" >/dev/null 2>&1; then
    docker start "$name" >/dev/null
    return 0
  fi
  return 0
}

ensure_dir() {
  local path="$1"
  mkdir -p "$path"
}
