
# Browser Automation (browser-automation)

Installs one pinned Chrome for Testing build and, optionally, a pinned standalone agent-browser CLI.

## Example Usage

```json
"features": {
    "ghcr.io/jjlinares/devcontainer-features/browser-automation:1.0.0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installAgentBrowser | Install the pinned standalone agent-browser binary. It is configured to use the Feature-owned Chrome. | boolean | false |

# Browser Automation

Installs a release-owned, CI-tested browser/tool pair:

| Component | Version | Installed path |
|---|---:|---|
| Chrome for Testing (full build) | `151.0.7922.76` | `/opt/chrome-for-testing/151.0.7922.76/chrome-linux64/chrome` |
| agent-browser (optional) | `0.33.2` | `/usr/local/bin/agent-browser` |

Stable Chrome entry points are `/usr/local/bin/google-chrome` and `/usr/local/bin/chrome`. `CHROME_BIN`, `BROWSER_EXECUTABLE_PATH`, and `AGENT_BROWSER_EXECUTABLE_PATH` all select `/usr/local/bin/google-chrome`. Every application downloads, checksum-verifies, and replaces the versioned Chrome tree rather than trusting pre-existing files.

## Supported platform

Debian/Ubuntu-based Linux AMD64 images only. Installation exits with an explicit error on other distributions, architectures, or operating systems. Chrome runs headlessly as a non-root user. The shipped Chrome SUID sandbox is configured because many container hosts disable unprivileged user namespaces. Restrictive container runtimes may still require direct Chrome/Playwright callers to pass `--no-sandbox`; `agent-browser` adds that flag itself when it detects a container, per its upstream behavior.

## Deliberate non-goals

This Feature does not install ChromeDriver, Playwright, Node.js, npm, Xvfb, VNC, a desktop, a browser sidecar, or a web UI. Never run `agent-browser install`: that command downloads another Chrome. The configured executable path makes normal `agent-browser` commands use the Feature-owned Chrome.

`installAgentBrowser=false` means this application does not install or remove the CLI. Feature installation is additive, so reapplying with `false` does not uninstall an existing `agent-browser` executable.

## Consumption

Pin the complete Feature version or OCI digest:

```jsonc
{
  "features": {
    "ghcr.io/jjlinares/devcontainer-features/browser-automation:1.0.0": {
      "installAgentBrowser": true
    }
  }
}
```

Do not consume mutable major tags such as `:1`: a Feature release owns one exact browser/tool pair, and browser changes must remain explicit consumer updates.

Apply the Feature while building a prebuilt development image in CI. Runtime devcontainer configuration should consume that image and must not declare the Feature again.

See [`docs/browser-automation-maintenance.md`](../../docs/browser-automation-maintenance.md) for version updates, release policy, and rollback.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/jjlinares/devcontainer-features/blob/main/src/browser-automation/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
