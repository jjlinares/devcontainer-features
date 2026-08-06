#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

check "Pi agent directory configured" test "${PI_CODING_AGENT_DIR}" = /mnt/pi-agent
check "host agent directory mounted" test -d /mnt/pi-host
check "settings activated by symlink" bash -c 'test -L /mnt/pi-agent/settings.json && test "$(readlink /mnt/pi-agent/settings.json)" = /mnt/pi-host/settings.json'
check "auth activated by symlink" bash -c 'test -L /mnt/pi-agent/auth.json && test "$(readlink /mnt/pi-agent/auth.json)" = /mnt/pi-host/auth.json'
check "AGENTS resolved and activated" bash -c 'test -L /mnt/pi-agent/AGENTS.md && test "$(readlink /mnt/pi-agent/AGENTS.md)" = /mnt/pi-host-resolved/AGENTS.md && test -s /mnt/pi-agent/AGENTS.md'
check "skills resolved and activated" bash -c 'test -L /mnt/pi-agent/skills && test "$(readlink /mnt/pi-agent/skills)" = /mnt/pi-host-resolved/skills && test -n "$(find -L /mnt/pi-agent/skills -mindepth 1 -type f -print -quit)"'
check "extensions resolved and activated" bash -c 'test -L /mnt/pi-agent/extensions && test "$(readlink /mnt/pi-agent/extensions)" = /mnt/pi-host-resolved/extensions && test -n "$(find -L /mnt/pi-agent/extensions -mindepth 1 -type f -print -quit)"'
check "host settings remain unchanged" node -e 'const fs=require("fs"); JSON.parse(fs.readFileSync("/mnt/pi-host/settings.json"))'
check "custom session path uses workspace" node -e 'const fs=require("fs"), path=require("path"); const actual=fs.readFileSync(process.env.HOME+"/.cache/pi-coding-agent-feature/session-dir","utf8").trim(); if (actual !== path.resolve(process.cwd(), ".pi/container-sessions")) process.exit(1)'
check "custom session directory exists" bash -c 'dir="$(<"$HOME/.cache/pi-coding-agent-feature/session-dir")"; test -d "$dir" && test -f "$dir/.gitignore"'
check "Pi launcher remains usable" bash -c 'pi --version | grep -E "^[0-9]+\\.[0-9]+\\.[0-9]+"'

reportResults
