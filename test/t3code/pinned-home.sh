#!/usr/bin/env bash
set -euo pipefail
export EXPECTED_T3_HOME="$HOME/.t3-test"
test "$(t3 --version)" = "t3 v0.1.0"
source "$(dirname -- "${BASH_SOURCE[0]}")/test.sh"
