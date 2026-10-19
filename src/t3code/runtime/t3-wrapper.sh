#!/usr/bin/env bash
set -euo pipefail

if [ -z "${T3CODE_HOME:-}" ]; then
    configured_home="$(</usr/local/share/t3code-feature/t3-home)"
    case "${configured_home}" in
        /*) export T3CODE_HOME="${configured_home}" ;;
        \~/*) export T3CODE_HOME="${HOME}/${configured_home#\~/}" ;;
        *) printf '[t3code] ERROR: invalid t3Home: %s\n' "${configured_home}" >&2; exit 1 ;;
    esac
fi

exec /opt/t3code/bin/t3 "$@"
