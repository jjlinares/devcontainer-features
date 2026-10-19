#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2016
set -euo pipefail

source dev-container-features-test-lib

check "remote user is non-root" bash -c 'test "$(id -u)" -ne 0'
check "official standalone CLI available" bash -c 't3 --version | grep -E "^t3 v[0-9]+\\.[0-9]+\\.[0-9]+"'
check "image-owned binary exists" test -x /opt/t3code/bin/t3

wait_for_server() {
    for _ in {1..120}; do
        if curl --fail --silent http://127.0.0.1:3773/ >/dev/null; then
            return 0
        fi
        sleep 0.5
    done
    return 1
}
check "entrypoint starts reachable server" wait_for_server
check "V2 state belongs to remote user" test -O "${EXPECTED_T3_HOME:-$HOME/.t3}/userdata/statev2.sqlite"
check "logs belong to remote user" test -O "${XDG_STATE_HOME:-$HOME/.local/state}/t3/server.log"
check "CLI pairs with the automatically started server" bash -c 't3 pair | grep -q "Pairing URL:"'
check "default bind accepts container network connections" bash -c 'curl --noproxy "*" --fail --silent "http://$(hostname -I | awk '\''{print $1}'\''):3773/" >/dev/null'
check "repeated entrypoint does not replace server" bash -c '
    pid_file="${XDG_RUNTIME_DIR:-/tmp}/t3-${UID}/server.pid"
    before="$(<"$pid_file")"
    /usr/local/share/t3code-feature/entrypoint.sh
    test "$before" = "$(<"$pid_file")"
    kill -0 "$before"
'

reportResults
