#!/usr/bin/env bash
set -euo pipefail

readonly FEATURE_NAME="pi-coding-agent"
readonly PACKAGE_NAME="@earendil-works/pi-coding-agent"
readonly AGENT_DIR="/mnt/pi-agent"
readonly HOST_AGENT_DIR="/mnt/pi-host"
readonly RESOLVED_HOST_DIR="/mnt/pi-host-resolved"
readonly RUNTIME_DIR="/usr/local/share/pi-coding-agent-feature"
readonly OPTIONS_FILE="${RUNTIME_DIR}/options.env"

log() {
    printf '[%s] %s\n' "${FEATURE_NAME}" "$*"
}

fail() {
    printf '[%s] ERROR: %s\n' "${FEATURE_NAME}" "$*" >&2
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    fail "installation must run as root"
fi

if [ "$(uname -s)" != "Linux" ]; then
    fail "unsupported operating system: only Linux is supported"
fi

if [ ! -r /etc/os-release ]; then
    fail "unsupported distribution: /etc/os-release is missing; only Debian/Ubuntu-based images are supported"
fi
# shellcheck disable=SC1091
. /etc/os-release
os_family=" ${ID:-} ${ID_LIKE:-} "
case "${os_family}" in
    *" debian "*|*" ubuntu "*) ;;
    *) fail "unsupported distribution '${ID:-unknown}': only Debian/Ubuntu-based images are supported" ;;
esac

command -v apt-get >/dev/null 2>&1 || fail "apt-get is required"
command -v node >/dev/null 2>&1 || fail "Node.js dependency was not installed"
command -v npm >/dev/null 2>&1 || fail "npm dependency was not installed"
node_major="$(node -p 'process.versions.node.split(".")[0]')"
[ "${node_major}" = "24" ] || fail "Node.js 24 is required, but $(node --version) is active"

pi_version="${PIVERSION:-latest}"
[ -n "${pi_version}" ] || fail "piVersion must not be empty"
session_dir="${SESSIONDIR:-.pi/sessions}"
[ -n "${session_dir}" ] || fail "sessionDir must not be empty"

export DEBIAN_FRONTEND=noninteractive
log "installing Pi runtime dependencies"
apt_update_log="$(mktemp)"
if ! apt-get update 2>&1 | tee "${apt_update_log}"; then
    mapfile -t broken_yarn_sources < <(
        grep -lR 'dl\.yarnpkg\.com' /etc/apt/sources.list.d 2>/dev/null || true
    )
    if ! grep -q 'dl.yarnpkg.com' "${apt_update_log}" \
        || ! grep -Eq 'NO_PUBKEY|not signed' "${apt_update_log}" \
        || [ "${#broken_yarn_sources[@]}" -eq 0 ]; then
        rm -f "${apt_update_log}"
        fail "apt-get update failed"
    fi
    for source_file in "${broken_yarn_sources[@]}"; do
        mv "${source_file}" "${source_file}.disabled-by-pi-coding-agent"
        log "disabled stale Yarn APT source ${source_file}"
    done
    apt-get update || fail "apt-get update failed after disabling stale Yarn sources"
fi
rm -f "${apt_update_log}"
apt-get install -y --no-install-recommends ca-certificates git ripgrep
rm -rf /var/lib/apt/lists/*
rm -f /var/cache/apt/archives/*.deb

# Restore the npm-owned executable before a duplicate Feature installation.
existing_pi="$(command -v pi 2>/dev/null || true)"
if [ -n "${existing_pi}" ] && [ -e "${existing_pi}.upstream" ]; then
    rm -f "${existing_pi}"
    mv "${existing_pi}.upstream" "${existing_pi}"
fi

log "installing ${PACKAGE_NAME}@${pi_version}"
npm install --global --ignore-scripts "${PACKAGE_NAME}@${pi_version}"
hash -r

pi_path="$(command -v pi)" || fail "npm completed but pi is not available on PATH"
installed_version="$("${pi_path}" --version)" || fail "pi --version failed"

mkdir -p \
    "${RUNTIME_DIR}" \
    "${AGENT_DIR}" \
    "${HOST_AGENT_DIR}" \
    "${RESOLVED_HOST_DIR}"/{extensions,skills}
touch "${RESOLVED_HOST_DIR}/AGENTS.md"
chmod 1777 "${AGENT_DIR}"
chmod 0755 "${HOST_AGENT_DIR}" "${RESOLVED_HOST_DIR}" "${RESOLVED_HOST_DIR}"/{extensions,skills}
chmod 0644 "${RESOLVED_HOST_DIR}/AGENTS.md"
cp "$(dirname "$0")/runtime/post-start.sh" "${RUNTIME_DIR}/post-start.sh"
cp "$(dirname "$0")/runtime/session-path.mjs" "${RUNTIME_DIR}/session-path.mjs"
cp "$(dirname "$0")/runtime/pi-wrapper.sh" "${RUNTIME_DIR}/pi-wrapper.sh"
chmod 0755 "${RUNTIME_DIR}/post-start.sh" "${RUNTIME_DIR}/pi-wrapper.sh"
chmod 0644 "${RUNTIME_DIR}/session-path.mjs"

{
    printf 'SESSIONDIR=%q\n' "${session_dir}"
} > "${OPTIONS_FILE}"
chmod 0644 "${OPTIONS_FILE}"

mv -f "${pi_path}" "${pi_path}.upstream"
cp "${RUNTIME_DIR}/pi-wrapper.sh" "${pi_path}"
chmod 0755 "${pi_path}"
hash -r

log "installed Pi ${installed_version} with Node $(node --version)"
