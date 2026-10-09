# PreToolUse hook: enforces the XML task gate from .context/task-workflow.md.
# Blocks Edit/Write to gated paths (src/, reference/, .context/) unless the
# sentinel file .claude/gate-open exists. The sentinel is created when the user
# approves an XML task and deleted after the task's commit.
# Only the main session owns the sentinel: a call from a subagent (agent_id set)
# that writes .claude/gate-open, or a Bash command naming gate-open, is blocked.
# Bash calls reach this script through .claude/hooks/sentinel-guard.sh.

$ErrorActionPreference = 'Stop'

try { $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }

$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir) { $projectDir = (Get-Location).Path }
$projectDir = [IO.Path]::GetFullPath($projectDir)

$isSubagent = [bool]$payload.agent_id
$ownerMsg = 'Subagents never open or close the gate; the main session owns .claude/gate-open. Report back instead.'

if ($payload.tool_name -eq 'Bash') {
    if ($isSubagent -and "$($payload.tool_input.command)" -match 'gate-open') {
        [Console]::Error.WriteLine($ownerMsg)
        exit 2
    }
    exit 0
}

$filePath = $payload.tool_input.file_path
if (-not $filePath) { exit 0 }

try { $full = [IO.Path]::GetFullPath($filePath) } catch { exit 0 }
if (-not $full.StartsWith($projectDir, [StringComparison]::OrdinalIgnoreCase)) { exit 0 }

$rel = $full.Substring($projectDir.Length).TrimStart('\', '/') -replace '\\', '/'

if ($isSubagent -and $rel -ieq '.claude/gate-open') {
    [Console]::Error.WriteLine($ownerMsg)
    exit 2
}

$gated = @('src/', 'reference/', '.context/')
$isGated = $false
foreach ($prefix in $gated) {
    if ($rel.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { $isGated = $true; break }
}
if (-not $isGated) { exit 0 }

if (Test-Path (Join-Path (Join-Path $projectDir '.claude') 'gate-open')) { exit 0 }

[Console]::Error.WriteLine("Gate closed: '$rel' needs an approved XML task (.context/task-workflow.md). Ask the user.")
exit 2
