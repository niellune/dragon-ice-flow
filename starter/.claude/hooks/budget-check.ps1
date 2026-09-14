# budget-check.ps1 - mechanical budget for the always-load board files (playbook R3).
# SINGLE HOME OF THE NUMBERS. The PostToolUse hook (.claude/settings.json) and the
# housekeeping `-All` run both execute this file, so there is nothing to keep in sync.
#   hook mode  : reads the tool payload on stdin; checks the edited file if it is budgeted;
#                exit 2 with the offending line numbers on stderr so the editing agent sees them.
#   -All       : checks every budgeted file under the project root; exit 1 on any failure.
#   -Path FILE : checks one file explicitly (tests, gates); exit 1 on failure.
# Project root comes from CLAUDE_PROJECT_DIR (the harness sets it), never from this script's path.
param([switch]$All, [string]$Path)
$ErrorActionPreference = 'Stop'

$FileBudgetBytes = 8192   # TaskList.md and STATE.md
$RowBudgetChars  = 240    # any line of TaskList.md
$Budgeted        = @('TaskList.md', 'STATE.md')

$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir) { $projectDir = (Get-Location).Path }
$projectDir = [IO.Path]::GetFullPath($projectDir)

function Test-Budget([string]$file) {
    $problems = @()
    if (-not (Test-Path -LiteralPath $file)) { return $problems }
    $name  = [IO.Path]::GetFileName($file)
    $bytes = (Get-Item -LiteralPath $file).Length
    if ($bytes -gt $FileBudgetBytes) { $problems += "$name is $bytes bytes; budget $FileBudgetBytes" }
    if ($name -ieq 'TaskList.md') {
        $n = 0
        foreach ($line in [IO.File]::ReadLines($file)) {
            $n++
            if ($line.Length -gt $RowBudgetChars) { $problems += "${name}:${n} is $($line.Length) chars; budget $RowBudgetChars" }
        }
    }
    return $problems
}

$targets = @()
if ($Path)    { $targets = @([IO.Path]::GetFullPath($Path)) }
elseif ($All) { $targets = @($Budgeted | ForEach-Object { Join-Path $projectDir $_ }) }
else {
    try { $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
    $fp = $payload.tool_input.file_path
    if (-not $fp) { exit 0 }
    if ($Budgeted -notcontains [IO.Path]::GetFileName($fp)) { exit 0 }
    $targets = @([IO.Path]::GetFullPath($fp))
}

$found = @()
foreach ($t in $targets) { $found += @(Test-Budget $t) }
if ($found.Count -eq 0) {
    if ($All -or $Path) { Write-Output "budget-check: ok ($($targets.Count) file(s))" }
    exit 0
}
[Console]::Error.WriteLine("Over budget - trim per the Closeout Rule in .context/task-workflow.md (limits live in .claude/hooks/budget-check.ps1):")
foreach ($p in $found) { [Console]::Error.WriteLine("  $p") }
if ($All -or $Path) { exit 1 } else { exit 2 }
