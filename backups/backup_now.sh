#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

GITEA_VOLUME="/Users/pedroangones/srv/docker/volumes/gitea"
PORTAINER_VOLUME="/Users/pedroangones/srv/docker/volumes/portainer"
DATE_DIR="$(today)"

GITEA_OUT_DIR="${BACKUP_ROOT}/gitea/${DATE_DIR}"
PORTAINER_OUT_DIR="${BACKUP_ROOT}/portainer/${DATE_DIR}"
GITEA_TAR="${GITEA_OUT_DIR}/gitea-volume-${DATE_DIR}.tar.gz"
PORTAINER_TAR="${PORTAINER_OUT_DIR}/portainer-volume-${DATE_DIR}.tar.gz"

stopped_gitea="no"
stopped_portainer="no"

restart_containers() {
  if [ "${stopped_gitea}" = "yes" ]; then
    start_container_if_exists "gitea"
    log_line "INFO" "Container gitea restarted"
  fi
  if [ "${stopped_portainer}" = "yes" ]; then
    start_container_if_exists "portainer"
    log_line "INFO" "Container portainer restarted"
  fi
}

on_error() {
  local exit_code="$?"
  restart_containers
  log_line "ERROR" "Backup failed with exit code ${exit_code}"
  echo "Backup failed (exit ${exit_code}). Check ${LOG_FILE}."
  exit "${exit_code}"
}
trap on_error ERR

ensure_dir "${GITEA_OUT_DIR}"
ensure_dir "${PORTAINER_OUT_DIR}"

log_line "INFO" "Backup run started"

gitea_state="$(stop_container_if_running "gitea")"
case "${gitea_state}" in
  stopped)
    stopped_gitea="yes"
    log_line "INFO" "Container gitea stopped for consistent backup"
    ;;
  already_stopped)
    log_line "INFO" "Container gitea already stopped"
    ;;
  missing)
    log_line "WARN" "Container gitea not found"
    ;;
esac

portainer_state="$(stop_container_if_running "portainer")"
case "${portainer_state}" in
  stopped)
    stopped_portainer="yes"
    log_line "INFO" "Container portainer stopped for consistent backup"
    ;;
  already_stopped)
    log_line "INFO" "Container portainer already stopped"
    ;;
  missing)
    log_line "WARN" "Container portainer not found"
    ;;
esac

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

restart_containers
trap - ERR

log_line "INFO" "Backup run finished successfully"

echo "Backup summary"
echo "- Date: ${DATE_DIR}"
echo "- Gitea archive: ${GITEA_TAR}"
echo "- Portainer archive: ${PORTAINER_TAR}"
echo "- Log file: ${LOG_FILE}"
