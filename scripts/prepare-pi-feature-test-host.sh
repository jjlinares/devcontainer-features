#!/usr/bin/env bash
set -euo pipefail

agent_dir="${HOME}/.pi/agent"
fixture_dir="${HOME}/.local/share/pi-coding-agent-feature-test"
mkdir -p \
    "${agent_dir}" \
    "${fixture_dir}/skills/example" \
    "${fixture_dir}/extensions/example"

printf '%s\n' '# Pi Feature test instructions' > "${fixture_dir}/AGENTS.md"
printf '%s\n' '% pi-feature-test' > "${fixture_dir}/skills/example/SKILL.md"
printf '%s\n' 'export default function piFeatureTest() {}' > "${fixture_dir}/extensions/example/index.ts"

if [ ! -e "${agent_dir}/settings.json" ] && [ ! -L "${agent_dir}/settings.json" ]; then
    printf '%s\n' '{"theme":"dark"}' > "${agent_dir}/settings.json"
fi
if [ ! -e "${agent_dir}/auth.json" ] && [ ! -L "${agent_dir}/auth.json" ]; then
    printf '%s\n' '{"test":{"type":"api_key","key":"fixture"}}' > "${agent_dir}/auth.json"
fi
if [ ! -e "${agent_dir}/AGENTS.md" ] && [ ! -L "${agent_dir}/AGENTS.md" ]; then
    ln -s "${fixture_dir}/AGENTS.md" "${agent_dir}/AGENTS.md"
fi
if [ ! -e "${agent_dir}/skills" ] && [ ! -L "${agent_dir}/skills" ]; then
    ln -s "${fixture_dir}/skills" "${agent_dir}/skills"
fi
if [ ! -e "${agent_dir}/extensions" ] && [ ! -L "${agent_dir}/extensions" ]; then
    ln -s "${fixture_dir}/extensions" "${agent_dir}/extensions"
fi
chmod 0600 "${agent_dir}/auth.json"

printf 'Prepared Pi Feature host fixture at %s\n' "${agent_dir}"
