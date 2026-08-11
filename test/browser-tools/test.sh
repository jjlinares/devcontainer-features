#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

readonly CHROME_VERSION="151.0.7922.76"
readonly CHROME_BINARY="/opt/chrome-for-testing/${CHROME_VERSION}/chrome-linux64/chrome"
readonly CHROME_SANDBOX="/opt/chrome-for-testing/${CHROME_VERSION}/chrome-linux64/chrome_sandbox"

check "exact Chrome version" bash -c "google-chrome --version | sed 's/[[:space:]]*$//' | grep -Fx 'Google Chrome for Testing ${CHROME_VERSION}'"
check "google-chrome stable link" test "$(readlink -f /usr/local/bin/google-chrome)" = "${CHROME_BINARY}"
check "chrome stable link" test "$(readlink -f /usr/local/bin/chrome)" = "${CHROME_BINARY}"
check "CHROME_BIN" test "${CHROME_BIN}" = /usr/local/bin/google-chrome
check "BROWSER_EXECUTABLE_PATH" test "${BROWSER_EXECUTABLE_PATH}" = /usr/local/bin/google-chrome
check "agent-browser executable path" test "${AGENT_BROWSER_EXECUTABLE_PATH}" = /usr/local/bin/google-chrome
check "SUID sandbox configured" bash -c "test \"\$(stat -c '%U:%G %a' '${CHROME_SANDBOX}')\" = 'root:root 4755'"

work_dir="$(mktemp -d)"
chrome_job=""
cleanup() {
    if [ -n "${chrome_job}" ]; then
        kill "${chrome_job}" >/dev/null 2>&1 || true
        wait "${chrome_job}" 2>/dev/null || true
    fi
    rm -rf "${work_dir}"
}
trap cleanup EXIT

printf '%s\n' '<!doctype html><title>browser-ready</title><h1 id="fixture">feature-owned-chrome</h1>' > "${work_dir}/fixture.html"
timeout --kill-after=3s 20s google-chrome \
    --headless=new --no-sandbox --disable-dev-shm-usage --disable-gpu \
    --no-first-run --disable-background-networking --disable-component-update \
    --disable-default-apps --disable-sync --metrics-recording-only \
    --user-data-dir="${work_dir}/profile" \
    --remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 \
    "file://${work_dir}/fixture.html" >"${work_dir}/chrome.log" 2>&1 &
chrome_job=$!

page_targets=""
for _ in $(seq 1 100); do
    page_targets="$(wget -qO- --timeout=1 http://127.0.0.1:9222/json/list 2>/dev/null || true)"
    if printf '%s' "${page_targets}" | grep -Fq '"title": "browser-ready"'; then
        break
    fi
    if ! kill -0 "${chrome_job}" 2>/dev/null; then
        cat "${work_dir}/chrome.log" >&2
        break
    fi
    sleep 0.1
done

printf '%s\n' "${page_targets}" > "${work_dir}/page-targets.json"
check "remote user is non-root" bash -c 'test "$(id -u)" -ne 0'
check "headless page title" grep -F '"title": "browser-ready"' "${work_dir}/page-targets.json"

check "agent-browser enabled by default" bash -c "agent-browser --version | grep -Fx 'agent-browser 0.33.2'"
check "one Feature-owned Chrome executable" bash -c "test \"\$(find /opt/chrome-for-testing -type f -name chrome | wc -l)\" -eq 1"
check "no ChromeDriver" bash -c '! command -v chromedriver && ! find /opt/chrome-for-testing -iname "*chromedriver*" | grep -q .'
check "no Xvfb" bash -c '! command -v Xvfb'
check "no VNC server" bash -c '! command -v vncserver && ! command -v x11vnc'
check "no agent-browser browser cache" bash -c 'test ! -e "$HOME/.agent-browser/browsers" && test ! -e "$HOME/.cache/ms-playwright" && test ! -e "$HOME/.cache/puppeteer/chrome"'

reportResults
