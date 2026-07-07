# PreToolUse hook: enforces the XML task gate from .context/task-workflow.md.
# Blocks Edit/Write to gated paths (src/, reference/, .context/) unless the
# sentinel file .claude/gate-open exists. The sentinel is created when the user
# approves an XML task and deleted after the task's commit.

$ErrorActionPreference = 'Stop'

try { $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
$filePath = $payload.tool_input.file_path
if (-not $filePath) { exit 0 }

$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir) { $projectDir = (Get-Location).Path }
$projectDir = [IO.Path]::GetFullPath($projectDir)

try { $full = [IO.Path]::GetFullPath($filePath) } catch { exit 0 }
if (-not $full.StartsWith($projectDir, [StringComparison]::OrdinalIgnoreCase)) { exit 0 }

$rel = $full.Substring($projectDir.Length).TrimStart('\', '/') -replace '\\', '/'

$gated = @('src/', 'reference/', '.context/')
$isGated = $false
foreach ($prefix in $gated) {
    if ($rel.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { $isGated = $true; break }
}
if (-not $isGated) { exit 0 }

if (Test-Path (Join-Path $projectDir '.claude\gate-open')) { exit 0 }

[Console]::Error.WriteLine("Gate closed: '$rel' is under the XML task gate (src/, reference/, .context/) and no approved task is open. Write the XML task per .context/task-workflow.md, get user approval, then create the sentinel: echo approved > .claude/gate-open. Delete the sentinel after the task's commit.")
exit 2
