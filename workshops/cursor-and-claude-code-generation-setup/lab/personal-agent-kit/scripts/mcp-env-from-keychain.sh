#!/usr/bin/env bash
# Launch an MCP server with secrets pulled from the macOS Keychain at start-up,
# so no token is ever written into mcp.json or any other config file.
#
# Store a secret once (you are prompted for the value; it never hits shell history):
#   security add-generic-password -a "$USER" -s jira-api-token -w
#
# Use in ~/.cursor/mcp.json (Cursor expands ${userHome}; it does not expand ~,
# and Gemini settings need the full /Users/<you>/... path instead):
#   "command": "bash",
#   "args": ["${userHome}/.agents/scripts/mcp-env-from-keychain.sh",
#            "JIRA_API_TOKEN=jira-api-token",
#            "--", "docker", "run", "-i", "--rm", "-e", "JIRA_API_TOKEN", "<image>"]
#
# Each VAR=keychain-service pair before "--" is exported; everything after
# "--" is the server command. Non-macOS: export the variables yourself instead
# (a password manager CLI or your shell profile sourcing a file outside git).
set -euo pipefail

while [[ $# -gt 0 && "$1" != "--" ]]; do
  pair="$1"; shift
  var="${pair%%=*}"
  svc="${pair#*=}"
  if [[ -z "${!var:-}" ]]; then
    value="$(security find-generic-password -a "$USER" -s "$svc" -w 2>/dev/null)" || {
      echo "mcp-env-from-keychain: no Keychain item '$svc' for $var" >&2
      exit 1
    }
    export "$var=$value"
  fi
done
[[ "${1:-}" == "--" ]] && shift
[[ $# -gt 0 ]] || { echo "mcp-env-from-keychain: missing server command after --" >&2; exit 2; }
exec "$@"
