
# T3 Code (t3code)

Installs the official standalone T3 Code server and starts it with the container.

## Example Usage

```json
"features": {
    "ghcr.io/jjlinares/devcontainer-features/t3code:1.0.0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| t3Version | Official T3 Code version. latest resolves the stable release at image build time; use an exact version to pin it. | string | latest |
| t3Home | T3 state directory. Must be an absolute path or begin with ~/; T3CODE_HOME overrides it at runtime. | string | ~/.t3 |

## Usage

Installs the official standalone server from `pingdotgg/t3code` using
`https://t3.codes/install.sh`. The upstream installer verifies the release archive
against its published SHA256SUMS. Supports Debian/Ubuntu-based Linux AMD64 and ARM64.

No T3 source build, npm package, Node dependency, desktop app, or provider harness
is installed. Install Pi or another provider separately.

`t3Version` defaults to the latest stable release at image build time. Pin an
exact upstream version to match your desktop client. Feature version and T3 version
are independent. Releases must include the standalone CLI archive.

## Startup and connections

The container entrypoint starts `t3 serve` as the configured remote user, including
when the container itself starts as root. It listens on `0.0.0.0:3773` by default.
Set `T3CODE_HOST=127.0.0.1` to restrict it to container-local clients, or
`T3CODE_PORT` to change the port.

Forward port 3773 in VS Code, or publish/proxy it through Docker or your workspace
host. The Feature does not publish ports or create a public URL.

```sh
tail -F ~/.local/state/t3/server.log
t3 pair
```

Logs follow `XDG_STATE_HOME` when set. Pairing links contain credentials. When using
a proxy, replace the URL's origin with the reachable proxy origin and keep its token.

Startup needs no network access. There is no systemd service or crash supervisor;
restart the container if the server exits.

## State and updates

State defaults to `~/.t3`. The `t3Home` option accepts an absolute path or a
`~/` path. `T3CODE_HOME` overrides it at runtime for both startup and CLI commands.
Persist that directory with a volume or use a writable directory in your persistent
workspace. The Feature does not mount host T3 state.

Binaries live under `/opt/t3code`, separate from state, and are owned by the image.
Update by changing `t3Version` and rebuilding the image, not with `t3 update`.
The `latest` option only resolves when the installation layer runs; rebuild without
cache to refresh it.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/jjlinares/devcontainer-features/blob/main/src/t3code/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
