# Browser tools maintenance

Each Feature release owns one exact Chrome for Testing and agent-browser pair. The scheduled `check-versions.yml` workflow checks the stable Chrome feed and latest stable agent-browser release. When either changes, it independently downloads changed assets, computes SHA-256 values, checks the agent-browser hash against GitHub's asset digest, and creates or refreshes an issue. It never edits source or publishes a Feature.

Run the same check locally:

```bash
node scripts/check-browser-tools-versions.mjs
```

Exit status `0` means current; `2` means an update is available.

## Update procedure

1. Review the upstream Chrome and agent-browser releases. Do not trust the scheduled issue blindly.
2. Update the version and SHA-256 constants in `src/browser-tools/install.sh`.
3. Update `CHROME_DEVEL_SANDBOX` in `devcontainer-feature.json` and all version assertions plus `NOTES.md`.
4. Increment the Feature version in `devcontainer-feature.json`, then run `./scripts/generate-feature-docs.sh`.
5. Run metadata packaging and the complete generated, duplicate, disabled, and enabled test matrix on both supported base-image families.
6. Merge only with green CI. Manually run the release workflow from `main`.
7. Smoke-test the published artifact by complete version or digest from a clean, unaffiliated checkout before announcing it.

## Semantic versions

- **Patch**: tested Chrome/agent-browser pair maintenance, checksum correction, dependency/install fix, or documentation correction without an interface change.
- **Minor**: backward-compatible option, environment variable, or supported-platform addition.
- **Major**: option removal/rename, default change, installed-path change, or platform support removal.

Consumers must pin the complete Feature version or OCI digest. Mutable major tags do not preserve the tested browser pair and are deliberately unsupported consumption inputs.

## Rollback

Pin the preceding complete Feature version or its OCI digest and rebuild the prebuilt development image. Do not mutate or republish an existing Feature version. Keep runtime `devcontainer.json` free of the Feature so rollback remains an image-CI change rather than a developer recreation-time install.
