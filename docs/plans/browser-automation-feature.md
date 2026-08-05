# Browser automation Dev Container Feature

## Goal

Build and publish `ghcr.io/jjlinares/devcontainer-features/browser-automation` as one reusable Dev Container Feature.

The Feature will always install one exact, checksum-verified full Chrome for Testing build and expose it through `/usr/local/bin/google-chrome`. An `installAgentBrowser` option will conditionally install one exact, checksum-verified standalone `agent-browser` binary. `agent-browser` will consume the installed Chrome and must never download its own browser.

Each Feature release will own and document one CI-tested Chrome/`agent-browser` version pair. Consumers will pin the complete Feature version or OCI digest rather than mutable major tags. The initial implementation targets Debian/Ubuntu-based Linux AMD64 images, runs Chrome headlessly as a non-root user, and installs no ChromeDriver, Playwright package, desktop, Xvfb, VNC, browser sidecar, or web UI.

Feature application belongs in CI image construction. Runtime devcontainer configurations will consume the resulting prebuilt image without declaring the Feature again.

## Phases

### Phase 1 — prove pinned Chrome installation

Create the smallest Feature that installs and launches the intended browser on the first target platform.

Tasks:

- [x] Initialize `/home/jj/projects/devcontainer-features` as a Git repository on `main`.
- [x] Adopt the minimal `devcontainers/feature-starter` repository structure and workflows without retaining example Features.
- [x] Add `src/browser-automation/devcontainer-feature.json` with the `installAgentBrowser` boolean option.
- [x] Pin one exact Chrome for Testing version and archive SHA-256 in Feature source.
- [x] Implement Debian/Ubuntu and AMD64 validation with explicit unsupported-platform errors.
- [x] Install only Chrome's required runtime libraries and the full Chrome for Testing archive.
- [x] Install under a versioned `/opt/chrome-for-testing/` path and expose `/usr/local/bin/google-chrome` plus `/usr/local/bin/chrome`.
- [x] Declare stable `CHROME_BIN` and `BROWSER_EXECUTABLE_PATH` container environment values.
- [x] Keep installation idempotent and remove package-manager/download residue.
- [x] Add generated-default and scenario tests using the Dev Container CLI Feature test framework.

Verification:

- [x] Build the Feature against `mcr.microsoft.com/devcontainers/base:ubuntu`.
- [x] Run `google-chrome --version` and observe the exact pinned version.
- [x] Launch a headless page as the image's non-root user and verify its title or DOM output.
- [x] Confirm no ChromeDriver, Xvfb, VNC, or second browser binary is installed.
- [x] Reapply the Feature in a duplicate-style test without breaking the stable executable path.

### Phase 2 — add the optional agent adapter

Prove the same Chrome installation can be controlled through an independently versioned CLI adapter.

Tasks:

- [x] Pin one exact `agent-browser` release and platform-binary SHA-256 in Feature source.
- [x] When `installAgentBrowser=true`, install the standalone native binary at `/usr/local/bin/agent-browser` without Node or npm.
- [x] Ensure `agent-browser` discovers `/usr/local/bin/google-chrome` and never runs its browser installer.
- [x] Leave no `agent-browser` executable or cache when `installAgentBrowser=false`.
- [x] Add scenarios for both option values and for a non-root remote user.
- [x] Serve a deterministic local fixture during tests so browser verification does not depend on an external website.

Verification:

- [x] With the option disabled, launch Chrome directly and confirm `agent-browser` is absent.
- [x] With the option enabled, verify the exact `agent-browser` version.
- [x] Use `agent-browser` to open the local fixture, take an accessibility snapshot, and read a known value.
- [x] Confirm the session uses the Feature-owned Chrome executable and creates no second browser installation.

### Phase 3 — publish a consumable Feature release

Package the tested implementation as a personal GHCR Feature collection.

Tasks:

- [x] Add validation, Feature tests, and release workflows derived from `devcontainers/feature-starter`.
- [x] Add generated Feature documentation covering options, installed paths, bundled tool versions, supported platforms, and non-goals.
- [x] Add a release process that publishes semantic-version tags and collection metadata under `ghcr.io/jjlinares/devcontainer-features`.
- [x] Document why consumers must pin a complete Feature version or OCI digest rather than `:1`.
- [ ] Create the `jjlinares/devcontainer-features` GitHub repository only after local tests pass.
- [ ] Publish the first Feature release and configure the chosen GHCR visibility.

Verification:

- [ ] Pull the published Feature into a clean sample devcontainer by complete version.
- [ ] Verify its published OCI metadata resolves through the Dev Container CLI.
- [ ] Build and run both option scenarios from the published artifact, not local source.
- [ ] Confirm an unaffiliated clean checkout can pull the artifact under the selected visibility/authentication policy.

### Phase 4 — prove CI-prebuilt consumption in DataHub

Demonstrate that Features execute in image CI but not during developer container recreation.

Tasks:

- [ ] Wait for `fintech-infosource/datahub#57` to establish the prebuilt development-image workflow.
- [ ] Add the pinned published Feature only to DataHub's CI build configuration with `installAgentBrowser=true`.
- [ ] Keep DataHub's runtime `devcontainer.json` free of a `features` declaration.
- [ ] Remove DataHub's direct Chrome libraries, unpinned npm `agent-browser`, `agent-browser install`, and `playwright install chromium` paths once the prebuilt Feature replaces them.
- [ ] Configure DataHub Playwright tests to use `BROWSER_EXECUTABLE_PATH` inside the prebuilt image while preserving an explicit outside-container fallback.
- [ ] Explicitly forward and label DataHub's application port without forwarding Chrome/CDP ports.
- [ ] Update DataHub issue #58 only after this Feature architecture is reviewed and accepted.

Verification:

- [ ] DataHub image CI builds and smoke-tests the Feature-provided Chrome and optional CLI.
- [ ] A clean DataHub checkout creates its container from the published image without executing Feature installers or downloading browsers locally.
- [ ] `agent-browser` can inspect the running DataHub app and Playwright E2E smoke tests use the same Chrome executable.
- [ ] Recreating the DataHub container is limited to image pull/create plus project dependency setup.

### Phase 5 — automate safe version maintenance

Make browser security updates routine without silently changing consumer environments.

Tasks:

- [x] Add automation that proposes Chrome for Testing and `agent-browser` version/checksum updates without publishing automatically.
- [ ] Require the full Feature test matrix before merging a version update.
- [x] Document the tested-pair update procedure and semantic-version policy.
- [x] Document rollback by pinning the preceding Feature version or digest.

Verification:

- [ ] Exercise one test update PR through version discovery, checksum review, CI, and package publication.
- [ ] Build a consumer against both the new and preceding Feature release.
- [ ] Confirm consumers remain unchanged until they explicitly update their Feature pin.

## Open questions and future decisions

- Repository and GHCR visibility: choose public for frictionless reuse or private with documented package authentication before the first release.
- License: select the repository license before publication.
- `installAgentBrowser` default: resolved to `false` so the default capability remains minimal Chrome.
- Additional platforms: consider Debian/Ubuntu ARM64, Alpine/musl, and non-Debian images only after the AMD64 tracer bullet works; official Linux Chrome for Testing currently lacks ARM64 artifacts.
- Version configurability: initially ship one tested pair per Feature release; add caller-selectable version options only if real consumers need older parallel versions.
- Public Feature index: decide whether to register the collection on containers.dev after the interface and maintenance process stabilize.
