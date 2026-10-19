#!/usr/bin/env bash
set -euo pipefail

readonly SHARE_DIR="/usr/local/share/t3code-feature"
readonly SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

fail() {
    printf '[t3code] ERROR: %s\n' "$*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || fail "installation must run as root"
[ "$(uname -s)" = Linux ] || fail "only Linux is supported"
[ -r /etc/os-release ] || fail "/etc/os-release is required"
# shellcheck disable=SC1091
. /etc/os-release
case " ${ID:-} ${ID_LIKE:-} " in
    *" debian "*|*" ubuntu "*) ;;
    *) fail "only Debian/Ubuntu-based images are supported" ;;
esac
case "$(dpkg --print-architecture)" in
    amd64|arm64) ;;
    *) fail "only AMD64 and ARM64 are supported" ;;
esac

version="${T3VERSION:-latest}"
if [ "${version}" = latest ]; then
    version=""
elif [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$ ]]; then
    fail "t3Version must be latest or an exact release version without a v prefix"
fi

t3_home="${T3HOME-~/.t3}"
case "${t3_home}" in
    /*|\~/*) ;;
    *) fail "t3Home must be an absolute path or begin with ~/" ;;
esac
remote_user="${_REMOTE_USER:-${_CONTAINER_USER:-root}}"
id "${remote_user}" >/dev/null || fail "container user does not exist: ${remote_user}"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git libatomic1 libstdc++6 tar util-linux
rm -rf /var/lib/apt/lists/*
rm -f /var/cache/apt/archives/*.deb

work_dir="$(mktemp -d)"
trap 'rm -rf "${work_dir}"' EXIT
curl --fail --location --silent --show-error --retry 5 \
    https://t3.codes/install.sh -o "${work_dir}/install.sh"

# Keep image-owned binaries outside the user's mounted state directory.
T3CODE_HOME=/opt/t3code \
T3CODE_INSTALL_BIN_DIR=/opt/t3code/bin \
T3CODE_CHANNEL=stable \
T3CODE_VERSION="${version}" \
    sh "${work_dir}/install.sh"
chmod -R a+rX /opt/t3code

mkdir -p "${SHARE_DIR}" /usr/local/bin
printf '%s\n' "${t3_home}" > "${SHARE_DIR}/t3-home"
printf '%s\n' "${remote_user}" > "${SHARE_DIR}/remote-user"
install -m 0755 "${SOURCE_DIR}/runtime/entrypoint.sh" "${SHARE_DIR}/entrypoint.sh"
install -m 0755 "${SOURCE_DIR}/runtime/t3-wrapper.sh" /usr/local/bin/t3
printf '[t3code] installed %s\n' "$(/opt/t3code/bin/t3 --version)"
