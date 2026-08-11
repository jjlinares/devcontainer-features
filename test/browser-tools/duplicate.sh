#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

readonly CHROME_VERSION="151.0.7922.76"
readonly CHROME_BINARY="/opt/chrome-for-testing/${CHROME_VERSION}/chrome-linux64/chrome"

check "random option exposed" bash -c 'test "${INSTALLAGENTBROWSER}" = true || test "${INSTALLAGENTBROWSER}" = false'
check "default option exposed" test "${INSTALLAGENTBROWSER__DEFAULT}" = true
check "exact Chrome version after duplicate install" bash -c "google-chrome --version | sed 's/[[:space:]]*$//' | grep -Fx 'Google Chrome for Testing ${CHROME_VERSION}'"
check "stable Chrome path after duplicate install" test "$(readlink -f /usr/local/bin/google-chrome)" = "${CHROME_BINARY}"
check "one versioned Chrome after duplicate install" bash -c "test \"\$(find /opt/chrome-for-testing -type f -name chrome | wc -l)\" -eq 1"

check "default agent-browser install preserved" bash -c "agent-browser --version | grep -Fx 'agent-browser 0.33.2'"

reportResults
