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
const path = require("node:path");

for (const entry of fs.readdirSync("src", { withFileTypes: true })) {
  if (!entry.isDirectory()) continue;
  const metadataPath = path.join("src", entry.name, "devcontainer-feature.json");
  const readmePath = path.join("src", entry.name, "README.md");
  if (!fs.existsSync(metadataPath) || !fs.existsSync(readmePath)) continue;

  const metadata = JSON.parse(fs.readFileSync(metadataPath, "utf8"));
  const readme = fs.readFileSync(readmePath, "utf8");
  const major = metadata.version.split(".")[0];
  const mutableExample = `ghcr.io/jjlinares/devcontainer-features/${metadata.id}:${major}\"`;
  const pinnedExample = `ghcr.io/jjlinares/devcontainer-features/${metadata.id}:${metadata.version}\"`;
  if (!readme.includes(mutableExample)) {
    throw new Error(`Generated mutable-major example was not found in ${readmePath}; review generator output`);
  }
  fs.writeFileSync(readmePath, readme.replace(mutableExample, pinnedExample));
}
NODE
