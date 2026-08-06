#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

check "remote user is non-root" bash -c 'test "$(id -u)" -ne 0'
check "Node 24 dependency available" bash -c 'node --version | grep -E "^v24\\."'
check "npm available" bash -c 'npm --version >/dev/null'
check "Pi available through launcher" bash -c 'pi --version | grep -E "^[0-9]+\\.[0-9]+\\.[0-9]+"'
check "Pi npm package installed globally" bash -c 'npm list --global --depth=0 @earendil-works/pi-coding-agent >/dev/null'
check "host-backed agent directory configured" test "${PI_CODING_AGENT_DIR}" = /mnt/pi-agent
check "session path state uses workspace" node -e 'const fs=require("fs"), path=require("path"); const actual=fs.readFileSync(process.env.HOME+"/.cache/pi-coding-agent-feature/session-dir","utf8").trim(); if (actual !== path.resolve(process.cwd(), ".pi/sessions")) process.exit(1)'
check "session directory created" bash -c 'dir="$(<"$HOME/.cache/pi-coding-agent-feature/session-dir")"; test -d "$dir" && grep -Fx "*" "$dir/.gitignore"'
check "host settings activated" bash -c 'test -L /mnt/pi-agent/settings.json && test -f /mnt/pi-host/settings.json'
check "host auth activated" bash -c 'test -L /mnt/pi-agent/auth.json && test -f /mnt/pi-host/auth.json'
check "host skills activated" bash -c 'test -L /mnt/pi-agent/skills && test "$(readlink /mnt/pi-agent/skills)" = /mnt/pi-host-resolved/skills'
check "host extensions activated" bash -c 'test -L /mnt/pi-agent/extensions && test "$(readlink /mnt/pi-agent/extensions)" = /mnt/pi-host-resolved/extensions'

reportResults
