# gate-check.tests.ps1 - tests for the gate hook and its Bash pre-filter (zero dependencies). Run:
#   powershell -NoProfile -File .claude/scripts/tests/gate-check.tests.ps1
# Prints "N run, N passed" on success; exit 1 on any failure. Uses a temp project dir; no fixtures.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $here))
$hook = Join-Path $root '.claude/hooks/gate-check.ps1'
$guard = Join-Path $root '.claude/hooks/sentinel-guard.sh'
$proj = Join-Path ([IO.Path]::GetTempPath()) ("gate-tests-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path (Join-Path $proj '.claude') | Out-Null
$sentinel = Join-Path $proj '.claude/gate-open'
$env:CLAUDE_PROJECT_DIR = $proj

$script:run = 0; $script:passed = 0; $script:failures = @()
function Assert([string]$name, [bool]$cond, [string]$detail = '') {
    $script:run++
    if ($cond) { $script:passed++ } else { $script:failures += "$name  $detail" }
}
function Payload([string]$tool, [hashtable]$toolInput, [string]$agentId = $null) {
    $p = @{ tool_name = $tool; tool_input = $toolInput }
    if ($agentId) { $p.agent_id = $agentId; $p.agent_type = 'general-purpose' }
    return ($p | ConvertTo-Json -Compress)
}
function Invoke-Hook([string]$json) {
    $ErrorActionPreference = 'Continue'
    $out = ($json | & (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File $hook 2>&1 | Out-String)
    $ErrorActionPreference = 'Stop'
    return @{ Exit = $LASTEXITCODE; Out = $out }
}
function Invoke-Guard([string]$json) {
    $ErrorActionPreference = 'Continue'
    $out = ($json | & sh $guard 2>&1 | Out-String)
    $ErrorActionPreference = 'Stop'
    return @{ Exit = $LASTEXITCODE; Out = $out }
}
function Write-To([string]$rel, [string]$agentId = $null) { Payload 'Write' @{ file_path = (Join-Path $proj $rel); content = 'x' } $agentId }
function Bash([string]$cmd, [string]$agentId = $null) { Payload 'Bash' @{ command = $cmd } $agentId }

try {
    # --- path gate: closed without the sentinel, open with it, for main and subagent alike
    $r = Invoke-Hook (Write-To 'src/a.ts')
    Assert 'gate closed: main write to src/ blocked' ($r.Exit -eq 2) $r.Out
    Assert 'gate closed: message names the workflow and no bypass' ($r.Out -match 'task-workflow\.md' -and $r.Out -notmatch 'echo approved') $r.Out
    $r = Invoke-Hook (Write-To 'planning/x.md')
    Assert 'gate closed: ungated path allowed' ($r.Exit -eq 0) $r.Out
    Set-Content -Path $sentinel -Value 'approved'
    $r = Invoke-Hook (Write-To 'src/a.ts')
    Assert 'gate open: main write to src/ allowed' ($r.Exit -eq 0) $r.Out
    $r = Invoke-Hook (Write-To 'src/a.ts' 'sub-1')
    Assert 'gate open: subagent write to src/ allowed' ($r.Exit -eq 0) $r.Out
    Remove-Item $sentinel -Force

    # --- sentinel ownership: Write/Edit
    $r = Invoke-Hook (Write-To '.claude/gate-open' 'sub-1')
    Assert 'owner: subagent Write to sentinel blocked' ($r.Exit -eq 2 -and $r.Out -match 'main session owns') $r.Out
    $r = Invoke-Hook (Payload 'Edit' @{ file_path = (Join-Path $proj '.claude/GATE-OPEN'); old_string = 'a'; new_string = 'b' } 'sub-1')
    Assert 'owner: subagent Edit to sentinel blocked (case-insensitive)' ($r.Exit -eq 2) $r.Out
    $r = Invoke-Hook (Write-To '.claude/gate-open')
    Assert 'owner: main Write to sentinel allowed' ($r.Exit -eq 0) $r.Out

    # --- sentinel ownership: Bash, direct and through the pre-filter
    $r = Invoke-Hook (Bash 'echo approved > .claude/gate-open' 'sub-1')
    Assert 'owner: subagent Bash creating sentinel blocked' ($r.Exit -eq 2) $r.Out
    $r = Invoke-Hook (Bash 'rm .claude/gate-open' 'sub-1')
    Assert 'owner: subagent Bash removing sentinel blocked' ($r.Exit -eq 2) $r.Out
    $r = Invoke-Hook (Bash 'echo approved > .claude/gate-open')
    Assert 'owner: main Bash creating sentinel allowed' ($r.Exit -eq 0) $r.Out
    $r = Invoke-Hook (Bash 'ls src' 'sub-1')
    Assert 'owner: subagent Bash unrelated allowed' ($r.Exit -eq 0) $r.Out
    $r = Invoke-Guard (Bash 'echo approved > .claude/gate-open' 'sub-1')
    Assert 'guard: subagent sentinel command blocked through sh' ($r.Exit -eq 2 -and $r.Out -match 'main session owns') $r.Out
    $r = Invoke-Guard (Bash 'echo approved > .claude/gate-open')
    Assert 'guard: main sentinel command allowed through sh' ($r.Exit -eq 0) $r.Out
    $r = Invoke-Guard (Bash 'ls src' 'sub-1')
    Assert 'guard: unrelated command passes without PowerShell' ($r.Exit -eq 0 -and $r.Out.Trim() -eq '') $r.Out

    # --- hook source carries no bypass recipe
    Assert 'source: no echo-approved recipe in the hook' (-not (Select-String -Path $hook -Pattern 'echo approved' -SimpleMatch -Quiet)) ''
}
finally {
    Remove-Item $proj -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Output "$($script:run) run, $($script:passed) passed"
if ($script:failures.Count -gt 0) { $script:failures | ForEach-Object { [Console]::Error.WriteLine("FAIL: $_") }; exit 1 }
exit 0
