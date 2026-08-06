#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

check "random piVersion option exposed" bash -c 'test -n "${PIVERSION}"'
check "default piVersion exposed" test "${PIVERSION__DEFAULT}" = latest
check "Pi remains available after duplicate install" bash -c 'pi --version | grep -E "^[0-9]+\\.[0-9]+\\.[0-9]+"'
check "one global Pi package" bash -c 'test "$(npm list --global --parseable @earendil-works/pi-coding-agent | grep -c pi-coding-agent)" -eq 1'

reportResults
