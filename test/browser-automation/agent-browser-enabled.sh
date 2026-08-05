#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

readonly CHROME_VERSION="151.0.7922.76"
readonly CHROME_BINARY="/opt/chrome-for-testing/${CHROME_VERSION}/chrome-linux64/chrome"
readonly SESSION="browser-automation-feature-test"

server_pid=""
cleanup() {
    timeout --kill-after=2s 10s agent-browser --session "${SESSION}" close >/dev/null 2>&1 || true
    if [ -n "${server_pid}" ]; then
        kill "${server_pid}" >/dev/null 2>&1 || true
        wait "${server_pid}" 2>/dev/null || true
    fi
}
trap cleanup EXIT

python3 -m http.server 8123 --bind 127.0.0.1 --directory /opt/browser-automation-fixture >/tmp/browser-fixture.log 2>&1 &
server_pid=$!
for _ in $(seq 1 50); do
    if curl --fail --silent --show-error --max-time 2 http://127.0.0.1:8123/ >/dev/null; then
        break
    fi
    sleep 0.1
done
curl --fail --silent --show-error --max-time 2 http://127.0.0.1:8123/ >/dev/null

check "exact agent-browser version" bash -o pipefail -c "timeout 10s agent-browser --version | grep -Fx 'agent-browser 0.33.2'"
check "Feature Chrome forced for agent-browser" test "${AGENT_BROWSER_EXECUTABLE_PATH}" = /usr/local/bin/google-chrome
check "open local fixture" timeout --kill-after=5s 60s agent-browser --session "${SESSION}" open http://127.0.0.1:8123/
check "accessibility snapshot" bash -o pipefail -c "timeout --kill-after=5s 30s agent-browser --session '${SESSION}' snapshot | grep -F 'Browser automation fixture'"
check "read known fixture value" bash -o pipefail -c "timeout --kill-after=5s 30s agent-browser --session '${SESSION}' get text '#known-value' | grep -Fx 'feature-owned-browser'"
check "session runs Feature-owned Chrome" bash -c "for executable in /proc/[0-9]*/exe; do readlink \"\${executable}\" 2>/dev/null || true; done | grep -m1 -Fx '${CHROME_BINARY}'"
check "no downloaded browser cache" bash -c 'test ! -e "$HOME/.agent-browser/browsers" && test ! -e "$HOME/.cache/ms-playwright" && test ! -e "$HOME/.cache/puppeteer/chrome"'
check "one Feature-owned Chrome executable" bash -c "test \"\$(find /opt/chrome-for-testing -type f -name chrome | wc -l)\" -eq 1"
check "close browser session" timeout --kill-after=5s 30s agent-browser --session "${SESSION}" close

reportResults
