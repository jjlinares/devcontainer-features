#!/usr/bin/env bash
# shellcheck disable=SC1091
set -euo pipefail

source dev-container-features-test-lib

check "Python base remains available" bash -c 'python3 --version | grep -E "^Python 3\\.13\\."'
check "Node added to Python image" bash -c 'node --version | grep -E "^v24\\."'
check "Pi installed in Python image" bash -c 'pi --version | grep -E "^[0-9]+\\.[0-9]+\\.[0-9]+"'

reportResults
