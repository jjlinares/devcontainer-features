#!/usr/bin/env bash
set -euo pipefail

readonly RUNTIME_DIR="/usr/local/share/pi-coding-agent-feature"
readonly OPTIONS_FILE="${RUNTIME_DIR}/options.env"
readonly SESSION_PATH_FILE="${HOME}/.cache/pi-coding-agent-feature/session-dir"

if [ -z "${PI_CODING_AGENT_SESSION_DIR:-}" ]; then
    if [ -r "${SESSION_PATH_FILE}" ]; then
        PI_CODING_AGENT_SESSION_DIR="$(<"${SESSION_PATH_FILE}")"
    else
        if [ -r "${OPTIONS_FILE}" ]; then
            # shellcheck disable=SC1090
            source "${OPTIONS_FILE}"
        fi
        PI_CODING_AGENT_SESSION_DIR="$(node "${RUNTIME_DIR}/session-path.mjs" \
            --session-dir "${SESSIONDIR:-.pi/sessions}" \
            --workspace "${PWD}")"
    fi
    export PI_CODING_AGENT_SESSION_DIR
fi

script_path="$(readlink -f "$0")"
exec "${script_path}.upstream" "$@"
