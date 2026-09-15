#!/bin/sh
# run-ps.sh - run a PowerShell script with whichever PowerShell this box has.
# Prefers PowerShell 7 (pwsh: Windows, macOS, Linux); falls back to Windows PowerShell 5.1 (powershell).
# Every hook in .claude/settings.json goes through this shim, so the hook commands never name a binary.
#   sh .claude/run-ps.sh <script.ps1> [args...]
if command -v pwsh >/dev/null 2>&1; then
  exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$@"
elif command -v powershell >/dev/null 2>&1; then
  exec powershell -NoProfile -ExecutionPolicy Bypass -File "$@"
else
  echo "run-ps.sh: no PowerShell found. Install PowerShell 7 (pwsh): https://aka.ms/powershell" >&2
  exit 127
fi
