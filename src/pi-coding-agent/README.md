
# Pi Coding Agent (pi-coding-agent)

Installs the latest Pi coding agent, activates available host setup, and persists sessions in the workspace.

## Example Usage

```json
"features": {
    "ghcr.io/jjlinares/devcontainer-features/pi-coding-agent:1.0.0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| piVersion | Version of @earendil-works/pi-coding-agent to install. The default resolves npm's latest tag at image build time. | string | latest |
| sessionDir | Pi session directory. Relative paths resolve from the workspace folder; absolute paths and ~/ paths are supported. | string | .pi/sessions |

# Pi Coding Agent

Installs `@earendil-works/pi-coding-agent` from npm after the official Dev Container Node Feature installs Node.js 24. The default `piVersion=latest` intentionally resolves npm's mutable `latest` tag whenever the image is built.

## Developer-owned opt-in

This Feature is intended as personal developer tooling, not project configuration. Add it to VS Code **User Settings**, preferably in a dedicated profile if it should not apply to every devcontainer:

```jsonc
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/jjlinares/devcontainer-features/pi-coding-agent:1.0.0": {}
  }
}
```

No project `devcontainer.json` change is required. Current VS Code Dev Containers and Dev Container CLI expand `${localEnv:HOME}` in Feature-provided mounts. The developer is responsible for ensuring `~/.pi/agent`, `AGENTS.md`, `skills/`, and `extensions/` exist before creating the container.

## Host setup

The Feature bind-mounts the complete host `~/.pi/agent` read-write at `/mnt/pi-host`. It then activates this allowlist under Pi's container agent directory, `/mnt/pi-agent`, using symlinks:

- `settings.json`, `keybindings.json`, and `models.json`
- `auth.json`
- `AGENTS.md`, `SYSTEM.md`, and `APPEND_SYSTEM.md`
- `skills/`, `prompts/`, `themes/`, and `extensions/`

`AGENTS.md`, `skills/`, and `extensions/` are hard prerequisites because Feature metadata mounts them separately to resolve host symlinks; Docker refuses to start when one is absent. The other allowlisted resources are optional and activated only when present. Deleting an optional host resource removes its active symlink at the next container start.

Authentication is not copied. OAuth refreshes through `/mnt/pi-agent/auth.json` write to the mounted host file. Running host Pi and container Pi concurrently can race while changing shared files.

The entire host agent directory is accessible at `/mnt/pi-host`, including sessions, trust state, caches, histories, packages, and binaries. Pi does not use those paths by default because `PI_CODING_AGENT_DIR` points to `/mnt/pi-agent`; they are nevertheless visible to container processes.

### Host symlinks

A bind mount of a parent directory preserves nested symlinks. Absolute host symlinks usually point to paths that do not exist inside the container. This host setup uses direct child mounts for the known symlinked `AGENTS.md`, `skills/`, and `extensions/` resources, exposing their resolved contents under `/mnt/pi-host-resolved` before activation. The extensions directory can therefore be mounted once rather than mounting each extension.

Other allowlisted resources should be regular files/directories inside `~/.pi/agent`. If one is an unresolved nested symlink, startup logs a warning and skips it.

## Container-local state

Pi creates unmounted state under `/mnt/pi-agent`, including:

- `trust.json`
- `models-store.json`
- `run-history.jsonl`
- `npm/` and `git/` package installations
- `bin/` managed tools
- debug logs and incidental caches

This prevents Pi from using host trust decisions and platform-specific binaries or dependencies. Container-local state is discarded on rebuild. Packages listed in shared `settings.json` may therefore be reinstalled after a rebuild.

## Session persistence

The default session directory is `.pi/sessions`, resolved to an absolute path from the devcontainer workspace folder during `postStartCommand`. Since the workspace is already mounted, no second session mount is required. A local `.gitignore` prevents session JSONL files from entering git accidentally.

A small `pi` launcher exports `PI_CODING_AGENT_SESSION_DIR` without modifying shared host settings. An explicitly supplied `PI_CODING_AGENT_SESSION_DIR` takes precedence.

Override the location with an absolute, workspace-relative, or home-relative Feature option:

```jsonc
{
  "dev.containers.defaultFeatures": {
    "ghcr.io/jjlinares/devcontainer-features/pi-coding-agent:1.0.0": {
      "sessionDir": "../pi-session-data"
    }
  }
}
```

## Supported platform and deliberate behavior

- Supported target: Debian/Ubuntu-based Linux images. If `apt-get update` fails specifically because an existing Yarn repository has a missing signing key, the Feature disables that stale source before installing runtime dependencies.
- A Python image remains a Python image; the Node dependency adds Node.js and npm.
- Node.js comes from `ghcr.io/devcontainers/features/node:2`, configured for Node 24. Installation fails if another conflicting Node Feature leaves a different major version active.
- Pi and its transitive npm dependencies are mutable because `piVersion` defaults to `latest`.
- Project-local `.pi` resources continue to use Pi's normal project-trust behavior.
- External absolute paths in host settings are not rewritten for the container.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/jjlinares/devcontainer-features/blob/main/src/pi-coding-agent/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
