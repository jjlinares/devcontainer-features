#!/bin/bash
# shellcheck disable=SC1091
set -e

source dev-container-features-test-lib

check "pre-existing Chrome replaced" test ! -e /opt/chrome-for-testing/151.0.7922.76/TAMPERED
check "verified Chrome installed" bash -c "google-chrome --version | sed 's/[[:space:]]*$//' | grep -Fx 'Google Chrome for Testing 151.0.7922.76'"

reportResults
