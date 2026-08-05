#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

check "Chrome available to non-root user" bash -c "google-chrome --version | sed 's/[[:space:]]*$//' | grep -Fx 'Google Chrome for Testing 151.0.7922.76'"
check "agent-browser absent" bash -c '! command -v agent-browser'
check "agent-browser cache absent" bash -c 'test ! -e "$HOME/.agent-browser/browsers" && test ! -e "$HOME/.cache/ms-playwright" && test ! -e "$HOME/.cache/puppeteer/chrome"'

reportResults
