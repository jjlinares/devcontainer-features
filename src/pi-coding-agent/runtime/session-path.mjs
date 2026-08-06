#!/usr/bin/env node

import { homedir } from "node:os";
import { isAbsolute, join, resolve } from "node:path";

function argument(name) {
  const index = process.argv.indexOf(name);
  if (index === -1 || !process.argv[index + 1]) {
    throw new Error(`${name} is required`);
  }
  return process.argv[index + 1];
}

function resolveSessionDir(value, workspace) {
  if (value === "~") return homedir();
  if (value.startsWith("~/")) return resolve(join(homedir(), value.slice(2)));
  return isAbsolute(value) ? resolve(value) : resolve(workspace, value);
}

const configuredSessionDir = argument("--session-dir");
const workspace = argument("--workspace");
process.stdout.write(resolveSessionDir(configuredSessionDir, workspace));
