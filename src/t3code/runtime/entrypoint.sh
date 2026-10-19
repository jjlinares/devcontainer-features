#!/usr/bin/env bash
set -euo pipefail

# Feature entrypoints can run as root even when remoteUser is non-root.
remote_user="$(</usr/local/share/t3code-feature/remote-user)"
if [ "$(id -u)" -eq 0 ] && [ "${remote_user}" != root ]; then
    exec runuser -u "${remote_user}" -- /usr/local/share/t3code-feature/entrypoint.sh
fi

readonly STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/t3"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/t3-${UID}"
readonly LOG_FILE="${STATE_DIR}/server.log"

umask 077
mkdir -p "${STATE_DIR}" "${RUNTIME_DIR}"
chmod 0700 "${STATE_DIR}" "${RUNTIME_DIR}"

# The server inherits the lock, so repeated entrypoint calls do not start it twice.
exec 9>"${RUNTIME_DIR}/server.lock"
flock -n 9 || exit 0

export T3CODE_HOST="${T3CODE_HOST:-0.0.0.0}"
nohup /usr/local/bin/t3 serve > "${LOG_FILE}" 2>&1 < /dev/null &
pid="$!"
printf '%s\n' "${pid}" > "${RUNTIME_DIR}/server.pid"
printf '[t3code] server started (pid %s); logs: %s\n' "${pid}" "${LOG_FILE}"

for _ in {1..50}; do
    if pairing_url="$(grep -m1 '^Pairing URL:' "${LOG_FILE}" 2>/dev/null)"; then
        printf '[t3code] %s\n' "${pairing_url}"
        exit 0
    fi
    if ! kill -0 "${pid}" 2>/dev/null; then
        printf '[t3code] ERROR: server exited during startup\n' >&2
        cat "${LOG_FILE}" >&2
        exit 1
    fi
    sleep 0.1
done

printf '[t3code] server is starting; follow the log for pairing details\n'
