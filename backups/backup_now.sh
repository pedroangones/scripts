#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

GITEA_VOLUME="/Users/pedroangones/srv/docker/volumes/gitea"
PORTAINER_VOLUME="/Users/pedroangones/srv/docker/volumes/portainer"
GITEA_STACK_DIR="/Users/pedroangones/srv/docker/stacks/gitea"
PORTAINER_STACK_DIR="/Users/pedroangones/srv/docker/stacks/portainer"
DATE_DIR="$(today)"

GITEA_OUT_DIR="${BACKUP_ROOT}/gitea/${DATE_DIR}"
PORTAINER_OUT_DIR="${BACKUP_ROOT}/portainer/${DATE_DIR}"
GITEA_TAR="${GITEA_OUT_DIR}/gitea-volume-${DATE_DIR}.tar.gz"
PORTAINER_TAR="${PORTAINER_OUT_DIR}/portainer-volume-${DATE_DIR}.tar.gz"

log_service_ps_snapshot() {
  local phase="$1"
  local lines

  lines="$(docker ps --format 'table {{.Names}}\t{{.Status}}' | awk '$1=="gitea" || $1=="portainer"')"

  if [ -z "${lines}" ]; then
    log_line "WARN" "docker ps ${phase}: no lines found for gitea/portainer"
    return 0
  fi

  while IFS= read -r line; do
    [ -n "${line}" ] && log_line "INFO" "docker ps ${phase}: ${line}"
  done <<< "${lines}"
}

compose_stop_service() {
  local service="$1"
  local stack_dir="$2"

  if [ ! -d "${stack_dir}" ]; then
    log_line "WARN" "Compose stop skipped for ${service}: stack dir not found (${stack_dir})"
    return 1
  fi

  if (cd "${stack_dir}" && docker compose stop >/dev/null); then
    log_line "INFO" "Compose stop succeeded for ${service} (${stack_dir})"
    return 0
  fi

  log_line "WARN" "Compose stop failed for ${service} (${stack_dir}); continuing backup"
  return 1
}

compose_up_service() {
  local service="$1"
  local stack_dir="$2"

  if [ ! -d "${stack_dir}" ]; then
    log_line "WARN" "Compose up skipped for ${service}: stack dir not found (${stack_dir})"
    return 1
  fi

  if (cd "${stack_dir}" && docker compose up -d >/dev/null); then
    log_line "INFO" "Compose up succeeded for ${service} (${stack_dir})"
    return 0
  fi

  log_line "WARN" "Compose up failed for ${service} (${stack_dir}); manual check required"
  return 1
}

start_services_best_effort() {
  compose_up_service "gitea" "${GITEA_STACK_DIR}" || true
  compose_up_service "portainer" "${PORTAINER_STACK_DIR}" || true
}

on_error() {
  local exit_code="$?"
  start_services_best_effort
  log_service_ps_snapshot "after start"
  log_line "ERROR" "Backup failed with exit code ${exit_code}"
  echo "Backup failed (exit ${exit_code}). Check ${LOG_FILE}."
  exit "${exit_code}"
}
trap on_error ERR

ensure_dir "${GITEA_OUT_DIR}"
ensure_dir "${PORTAINER_OUT_DIR}"

log_line "INFO" "Backup run started"
log_service_ps_snapshot "before stop"

compose_stop_service "gitea" "${GITEA_STACK_DIR}" || true
compose_stop_service "portainer" "${PORTAINER_STACK_DIR}" || true

if [ -d "${GITEA_VOLUME}" ]; then
  tar -C "/Users/pedroangones/srv/docker/volumes" -czf "${GITEA_TAR}" "gitea"
  log_line "INFO" "Gitea backup created: ${GITEA_TAR}"
else
  log_line "WARN" "Gitea volume path not found: ${GITEA_VOLUME}"
fi

if [ -d "${PORTAINER_VOLUME}" ]; then
  tar -C "/Users/pedroangones/srv/docker/volumes" -czf "${PORTAINER_TAR}" "portainer"
  log_line "INFO" "Portainer backup created: ${PORTAINER_TAR}"
else
  log_line "WARN" "Portainer volume path not found: ${PORTAINER_VOLUME}"
fi

start_services_best_effort
log_service_ps_snapshot "after start"
trap - ERR

log_line "INFO" "Backup run finished successfully"

echo "Backup summary"
echo "- Date: ${DATE_DIR}"
echo "- Gitea archive: ${GITEA_TAR}"
echo "- Portainer archive: ${PORTAINER_TAR}"
echo "- Log file: ${LOG_FILE}"
