#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "1. plugin.json is valid and correctly named"
jq -e '.name == "eng-tutor"' .claude-plugin/plugin.json > /dev/null

echo "2. marketplace.json lists this repo as the plugin source"
jq -e '.plugins[0].name == "eng-tutor" and .plugins[0].source == "./"' .claude-plugin/marketplace.json > /dev/null

echo "3. hooks.json registers a SessionStart command hook"
jq -e '.hooks.SessionStart[0].hooks[0].type == "command"' hooks/hooks.json > /dev/null

echo "4. session-start.sh emits valid SessionStart hook JSON"
out="$(bash hooks-handlers/session-start.sh)"
echo "$out" | jq -e '.hookSpecificOutput.hookEventName == "SessionStart"' > /dev/null
echo "$out" | jq -e '.hookSpecificOutput.additionalContext | length > 200' > /dev/null

echo "ALL CHECKS PASS"
