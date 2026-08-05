#!/usr/bin/env bash
set -euo pipefail

if command -v devcontainer >/dev/null 2>&1; then
    cli=(devcontainer)
else
    cli=(npm exec --yes --package=@devcontainers/cli@0.88.0 -- devcontainer)
fi

"${cli[@]}" features generate-docs \
    --project-folder ./src \
    --namespace jjlinares/devcontainer-features \
    --github-owner jjlinares \
    --github-repo devcontainer-features

node <<'NODE'
const fs = require("node:fs");
const metadataPath = "src/browser-automation/devcontainer-feature.json";
const readmePath = "src/browser-automation/README.md";
const metadata = JSON.parse(fs.readFileSync(metadataPath, "utf8"));
const readme = fs.readFileSync(readmePath, "utf8");
const mutableExample = "ghcr.io/jjlinares/devcontainer-features/browser-automation:1\"";
const pinnedExample = `ghcr.io/jjlinares/devcontainer-features/browser-automation:${metadata.version}\"`;
if (!readme.includes(mutableExample)) {
  throw new Error("Generated mutable-major example was not found; review generator output");
}
fs.writeFileSync(readmePath, readme.replace(mutableExample, pinnedExample));
NODE
