#!/usr/bin/env node

import { createHash } from "node:crypto";
import { createReadStream, createWriteStream, readFileSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { pipeline } from "node:stream/promises";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const installSource = readFileSync(path.join(root, "src/browser-automation/install.sh"), "utf8");
const reportFlag = process.argv.indexOf("--report");
const reportPath = reportFlag === -1 ? null : process.argv[reportFlag + 1];
if (reportFlag !== -1 && !reportPath) throw new Error("--report requires a path");

const constants = Object.fromEntries(
  [...installSource.matchAll(/^readonly ([A-Z0-9_]+)="([^"\r\n$]+)"$/gm)].map((match) => [match[1], match[2]]),
);
for (const name of ["CHROME_VERSION", "CHROME_SHA256", "AGENT_BROWSER_VERSION", "AGENT_BROWSER_SHA256"]) {
  if (!constants[name]) throw new Error(`Could not parse ${name} from install.sh`);
}

const headers = {
  Accept: "application/vnd.github+json",
  "User-Agent": "devcontainer-features-version-check",
};
if (process.env.GITHUB_TOKEN) headers.Authorization = `Bearer ${process.env.GITHUB_TOKEN}`;

async function json(url) {
  const response = await fetch(url, { headers });
  if (!response.ok) throw new Error(`${url}: HTTP ${response.status}`);
  return response.json();
}

async function sha256(url, destination) {
  const response = await fetch(url, { headers, redirect: "follow" });
  if (!response.ok || !response.body) throw new Error(`${url}: HTTP ${response.status}`);
  const temporary = `${destination}.partial`;
  rmSync(temporary, { force: true });
  await pipeline(response.body, createWriteStream(temporary));
  renameSync(temporary, destination);
  const hash = createHash("sha256");
  await pipeline(createReadStream(destination), hash);
  rmSync(destination, { force: true });
  return hash.digest("hex");
}

const chromeFeed = await json("https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json");
const chrome = chromeFeed.channels?.Stable;
const chromeAsset = chrome?.downloads?.chrome?.find((asset) => asset.platform === "linux64");
if (!chrome?.version || !chromeAsset?.url) throw new Error("Stable Linux64 Chrome asset missing from Chrome for Testing feed");

const agentRelease = await json("https://api.github.com/repos/vercel-labs/agent-browser/releases/latest");
const agentVersion = agentRelease.tag_name?.replace(/^v/, "");
const agentAsset = agentRelease.assets?.find((asset) => asset.name === "agent-browser-linux-x64");
if (!agentVersion || !agentAsset?.browser_download_url) throw new Error("Linux x64 agent-browser asset missing from latest release");

const chromeChanged = chrome.version !== constants.CHROME_VERSION;
const agentChanged = agentVersion !== constants.AGENT_BROWSER_VERSION;
if (!chromeChanged && !agentChanged) {
  console.log(`Browser automation pair is current: Chrome ${chrome.version}, agent-browser ${agentVersion}`);
  process.exit(0);
}

const downloadDir = process.env.RUNNER_TEMP || "/tmp";
const chromeHash = chromeChanged
  ? await sha256(chromeAsset.url, path.join(downloadDir, `chrome-linux64-${chrome.version}.zip`))
  : constants.CHROME_SHA256;
const agentHash = agentChanged
  ? await sha256(agentAsset.browser_download_url, path.join(downloadDir, `agent-browser-linux-x64-${agentVersion}`))
  : constants.AGENT_BROWSER_SHA256;

if (agentAsset.digest && agentAsset.digest !== `sha256:${agentHash}`) {
  throw new Error(`Downloaded agent-browser hash ${agentHash} differs from GitHub asset digest ${agentAsset.digest}`);
}

const report = `# Browser automation version update available

Current tested pair:
- Chrome for Testing \`${constants.CHROME_VERSION}\`
- agent-browser \`${constants.AGENT_BROWSER_VERSION}\`

Proposed pair:
- Chrome for Testing \`${chrome.version}\`
  - URL: ${chromeAsset.url}
  - SHA-256: \`${chromeHash}\`
- agent-browser \`${agentVersion}\`
  - URL: ${agentAsset.browser_download_url}
  - SHA-256: \`${agentHash}\`

This automation only proposes inputs. Update the Feature version and documentation, review both upstream releases and hashes, then run the full test matrix before merging. Publication remains manual.
`;

if (reportPath) writeFileSync(reportPath, report);
console.log(report);
process.exitCode = 2;
