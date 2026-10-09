#!/bin/sh
# sentinel-guard.sh - PreToolUse pre-filter for Bash calls.
# Starts PowerShell only when the payload mentions gate-open; gate-check.ps1 holds the rule.
#   sh .claude/hooks/sentinel-guard.sh   (payload on stdin)
payload=$(cat)
case "$payload" in
  *gate-open*) printf '%s' "$payload" | sh "$(dirname "$0")/../run-ps.sh" "$(dirname "$0")/gate-check.ps1" ;;
  *) exit 0 ;;
esac
