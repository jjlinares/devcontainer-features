#!/usr/bin/env bash
set -euo pipefail

readonly FEATURE_NAME="pi-coding-agent"
readonly AGENT_DIR="/mnt/pi-agent"
readonly HOST_AGENT_DIR="/mnt/pi-host"
readonly RESOLVED_HOST_DIR="/mnt/pi-host-resolved"
readonly RUNTIME_DIR="/usr/local/share/pi-coding-agent-feature"
readonly OPTIONS_FILE="${RUNTIME_DIR}/options.env"
readonly STATE_DIR="${HOME}/.cache/pi-coding-agent-feature"
readonly SESSION_PATH_FILE="${STATE_DIR}/session-dir"

log() {
    printf '[%s] %s\n' "${FEATURE_NAME}" "$*"
}

warn() {
    printf '[%s] WARNING: %s\n' "${FEATURE_NAME}" "$*" >&2
}

link_file_if_present() {
    local source_path="$1"
    local target_path="$2"

    rm -rf "${target_path}"
    if [ -f "${source_path}" ]; then
        ln -s "${source_path}" "${target_path}"
    elif [ -L "${source_path}" ]; then
        warn "host resource is a broken symlink inside the container: ${source_path}"
    fi
}

link_directory_if_present() {
    local source_path="$1"
    local target_path="$2"

    rm -rf "${target_path}"
    if [ -d "${source_path}" ]; then
        ln -s "${source_path}" "${target_path}"
    elif [ -L "${source_path}" ]; then
        warn "host resource is a broken symlink inside the container: ${source_path}"
    fi
}

main() {
    if [ -r "${OPTIONS_FILE}" ]; then
        # shellcheck disable=SC1090
        source "${OPTIONS_FILE}"
    fi

    local configured_session_dir="${SESSIONDIR:-.pi/sessions}"
    local resolved_session_dir
    local resource

    for resource in settings.json keybindings.json models.json SYSTEM.md APPEND_SYSTEM.md auth.json; do
        link_file_if_present "${HOST_AGENT_DIR}/${resource}" "${AGENT_DIR}/${resource}"
    done
    link_file_if_present "${RESOLVED_HOST_DIR}/AGENTS.md" "${AGENT_DIR}/AGENTS.md"

    for resource in prompts themes; do
        link_directory_if_present "${HOST_AGENT_DIR}/${resource}" "${AGENT_DIR}/${resource}"
    done
    link_directory_if_present "${RESOLVED_HOST_DIR}/skills" "${AGENT_DIR}/skills"
    link_directory_if_present "${RESOLVED_HOST_DIR}/extensions" "${AGENT_DIR}/extensions"

    resolved_session_dir="$(node "${RUNTIME_DIR}/session-path.mjs" \
        --session-dir "${configured_session_dir}" \
        --workspace "${PWD}")"

    mkdir -p "${STATE_DIR}" "${resolved_session_dir}"
    printf '%s\n' "${resolved_session_dir}" > "${SESSION_PATH_FILE}"
    chmod 0600 "${SESSION_PATH_FILE}"

    local session_ignore="${resolved_session_dir}/.gitignore"
    if [ ! -e "${session_ignore}" ] || cmp -s "${session_ignore}" <(printf '*\n!.gitignore\n'); then
        printf '*\n' > "${session_ignore}"
    fi

    if [ ! -e "${AGENT_DIR}/settings.json" ]; then
        warn "host settings.json is unavailable; Pi will use defaults"
    fi
    if [ ! -e "${AGENT_DIR}/auth.json" ]; then
        warn "host auth.json is unavailable; authenticate through an environment variable or /login"
    fi

    log "activated available host Pi resources from ${HOST_AGENT_DIR}"
    log "sessions persist at ${resolved_session_dir}"
}

main "$@"
