#!/usr/bin/env bash
set -euo pipefail

readonly CHROME_VERSION="151.0.7922.76"
readonly CHROME_SHA256="d9e4c5916f77e737f22056cab47cd8abb7d39ebec559500ffc2d6f3e02106a7e"
readonly CHROME_URL="https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VERSION}/linux64/chrome-linux64.zip"
readonly AGENT_BROWSER_VERSION="0.33.2"
readonly AGENT_BROWSER_SHA256="b7bc3dfcf0a7326c1f5a60423163259ba2349eebfa5bd2e70e111af743da4a49"
readonly AGENT_BROWSER_URL="https://github.com/vercel-labs/agent-browser/releases/download/v${AGENT_BROWSER_VERSION}/agent-browser-linux-x64"
readonly CHROME_ROOT="/opt/chrome-for-testing/${CHROME_VERSION}"
readonly CHROME_BINARY="${CHROME_ROOT}/chrome-linux64/chrome"
readonly CHROME_SANDBOX="${CHROME_ROOT}/chrome-linux64/chrome_sandbox"

log() {
    printf '[browser-automation] %s\n' "$*"
}

fail() {
    printf '[browser-automation] ERROR: %s\n' "$*" >&2
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    fail "installation must run as root"
fi

if [ "$(uname -s)" != "Linux" ]; then
    fail "unsupported operating system: only Linux is supported"
fi

architecture="$(dpkg --print-architecture 2>/dev/null || true)"
if [ "${architecture}" != "amd64" ]; then
    fail "unsupported architecture '${architecture:-unknown}': only Debian/Ubuntu AMD64 is supported"
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

install_agent_browser="${INSTALLAGENTBROWSER:-false}"
install_agent_browser="$(printf '%s' "${install_agent_browser}" | tr '[:upper:]' '[:lower:]')"
case "${install_agent_browser}" in
    true|false) ;;
    *) fail "installAgentBrowser must be true or false, got '${INSTALLAGENTBROWSER}'" ;;
esac

command -v apt-get >/dev/null 2>&1 || fail "apt-get is required"

work_dir=""
cleanup() {
    if [ -n "${work_dir}" ]; then
        rm -rf "${work_dir}"
    fi
    rm -rf /var/lib/apt/lists/*
    rm -f /var/cache/apt/archives/*.deb
}
trap cleanup EXIT

export DEBIAN_FRONTEND=noninteractive
download_packages_to_remove=()
for package in curl unzip; do
    if ! dpkg-query -W -f='${db:Status-Abbrev}' "${package}" 2>/dev/null | grep -q '^ii '; then
        download_packages_to_remove+=("${package}")
    fi
done

log "installing download tools"
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl unzip

work_dir="$(mktemp -d)"

log "downloading Chrome for Testing ${CHROME_VERSION}"
curl --fail --location --silent --show-error \
    --retry 5 --retry-all-errors \
    --output "${work_dir}/chrome-linux64.zip" \
    "${CHROME_URL}"
printf '%s  %s\n' "${CHROME_SHA256}" "${work_dir}/chrome-linux64.zip" | sha256sum --check --strict

mkdir -p "${work_dir}/chrome" /opt/chrome-for-testing
unzip -q "${work_dir}/chrome-linux64.zip" -d "${work_dir}/chrome"
[ -x "${work_dir}/chrome/chrome-linux64/chrome" ] || fail "Chrome archive did not contain the expected executable"
[ -r "${work_dir}/chrome/chrome-linux64/deb.deps" ] || fail "Chrome archive did not contain deb.deps"

rm -rf "${CHROME_ROOT}"
mv "${work_dir}/chrome" "${CHROME_ROOT}"
printf '%s\n' "${CHROME_VERSION}" > "${CHROME_ROOT}/.version"

log "installing dependencies declared by Chrome ${CHROME_VERSION}"
chrome_dependencies=()
while IFS= read -r dependency; do
    [ -n "${dependency}" ] || continue
    chrome_dependencies+=("${dependency}")
done < "${CHROME_ROOT}/chrome-linux64/deb.deps"
apt-get satisfy -y --no-install-recommends "${chrome_dependencies[@]}"

chown -R root:root "${CHROME_ROOT}"
chmod -R a+rX "${CHROME_ROOT}"
# Chrome for Testing is a raw build. Configure its shipped SUID sandbox so
# non-root users can launch Chrome where unprivileged user namespaces are off.
chmod 4755 "${CHROME_SANDBOX}"

actual_chrome_version="$(${CHROME_BINARY} --version)"
case "${actual_chrome_version}" in
    "Google Chrome for Testing ${CHROME_VERSION}"*) ;;
    *) fail "installed Chrome version mismatch: ${actual_chrome_version}" ;;
esac

for link in /usr/local/bin/google-chrome /usr/local/bin/chrome; do
    if [ -d "${link}" ] && [ ! -L "${link}" ]; then
        fail "cannot replace directory ${link}"
    fi
    rm -f "${link}"
    ln -s "${CHROME_BINARY}" "${link}"
done

if [ "${install_agent_browser}" = "true" ]; then
    log "downloading agent-browser ${AGENT_BROWSER_VERSION}"
    curl --fail --location --silent --show-error \
        --retry 5 --retry-all-errors \
        --output "${work_dir}/agent-browser" \
        "${AGENT_BROWSER_URL}"
    printf '%s  %s\n' "${AGENT_BROWSER_SHA256}" "${work_dir}/agent-browser" | sha256sum --check --strict
    install -m 0755 "${work_dir}/agent-browser" /usr/local/bin/agent-browser

    actual_agent_version="$(agent-browser --version)"
    [ "${actual_agent_version}" = "agent-browser ${AGENT_BROWSER_VERSION}" ] || \
        fail "installed agent-browser version mismatch: ${actual_agent_version}"
else
    log "installAgentBrowser=false; agent-browser was not installed"
fi

if [ "${#download_packages_to_remove[@]}" -gt 0 ]; then
    apt-get purge -y "${download_packages_to_remove[@]}"
fi

log "installed ${actual_chrome_version}"
