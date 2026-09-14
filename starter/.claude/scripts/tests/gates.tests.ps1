# gates.tests.ps1 - tests for gates.ps1 (zero dependencies). Run:
#   powershell -NoProfile -File .claude/scripts/tests/gates.tests.ps1
# Prints "N run, N passed" on success; exit 1 on any failure. Fixtures: ./fixtures/gates/
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$gates = Join-Path (Split-Path -Parent $here) 'gates.ps1'
$fx = Join-Path $here 'fixtures/gates'
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("gates-tests-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
$env:CLAUDE_PROJECT_DIR = (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $here)))

$script:run = 0; $script:passed = 0; $script:failures = @()
function Assert([string]$name, [bool]$cond, [string]$detail = '') {
    $script:run++
    if ($cond) { $script:passed++ } else { $script:failures += "$name  $detail" }
}
function Invoke-Gates([string[]]$argv) {
    $ErrorActionPreference = 'Continue'
    $out = (& powershell -NoProfile -ExecutionPolicy Bypass -File $gates $argv 2>&1 | Out-String)
    $ErrorActionPreference = 'Stop'
    return @{ Exit = $LASTEXITCODE; Out = $out }
}
function Copy-Fixture([string]$rel) {
    $dst = Join-Path $tmp ([IO.Path]::GetFileName($rel))
    Copy-Item (Join-Path $fx $rel) $dst -Force
    return $dst
}

# --- lint: good ledger passes
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'good/ref-900.md'))
Assert 'lint: good ledger is clean' ($r.Exit -eq 0) $r.Out

# --- lint: rejects non-task-id ledger name
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'bad-name/not-a-task.md'))
Assert 'lint: non-task-id name rejected' ($r.Exit -ne 0 -and $r.Out -match 'not a task id') $r.Out

# --- lint: rejects bare success EXPECT
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'bad-expect/ref-901.md'))
Assert 'lint: EXPECT ok rejected' ($r.Exit -ne 0 -and $r.Out -match 'bare success marker') $r.Out

# --- lint: rejects activity title
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'bad-title/ref-902.md'))
Assert 'lint: activity title rejected' ($r.Exit -ne 0 -and $r.Out -match 'is an activity') $r.Out

# --- lint: rejects pinned test count
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'bad-count/ref-903.md'))
Assert 'lint: pinned count rejected' ($r.Exit -ne 0 -and $r.Out -match 'pins a test count') $r.Out

# --- lint: hand-ticked box rejected
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'hand-tick/ref-904.md'))
Assert 'lint: hand-ticked box rejected' ($r.Exit -ne 0 -and $r.Out -match 'hand-ticked') $r.Out

# --- lint: workspace flag rule
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'good/ref-900.md'), '-WorkspaceRule', 'Write-Output=--nope')
Assert 'lint: workspace rule fires when flag missing' ($r.Exit -ne 0 -and $r.Out -match 'workspace flag') $r.Out

# --- status: hand-ticked box with no evidence line is unmet
$r = Invoke-Gates @('-Status', (Join-Path $fx 'hand-tick/ref-904.md'))
Assert 'status: hand-tick without evidence is unmet' ($r.Exit -ne 0 -and $r.Out -match 'G1\s+unmet') $r.Out

# --- run: good ledger becomes met, evidence line carries digest
$led = Copy-Fixture 'good/ref-900.md'
$r = Invoke-Gates @('-Run', $led)
$txt = [IO.File]::ReadAllText($led)
Assert 'run: good ledger met' ($r.Exit -eq 0 -and $r.Out -match '2 met, 0 unmet') $r.Out
Assert 'run: evidence line written with digest' ($txt -match 'EVIDENCE: met \S+ exit=0 digest=[0-9a-f]{8}') $txt
Assert 'run: file stays LF' (-not $txt.Contains("`r")) 'CR found'

# --- run: failing check is unmet, exit 1
$led2 = Copy-Fixture 'failing/ref-905.md'
$r = Invoke-Gates @('-Run', $led2)
Assert 'run: failing check is unmet' ($r.Exit -ne 0 -and $r.Out -match 'G1\s+unmet') $r.Out

# --- status after run: met without re-execution
$r = Invoke-Gates @('-Status', $led)
Assert 'status: met after run' ($r.Exit -eq 0 -and $r.Out -match '2 met, 0 unmet') $r.Out

# --- tamper: editing EXPECT flips to unmet without a re-run
$tampered = [IO.File]::ReadAllText($led) -replace 'EXPECT: \^hello\$', 'EXPECT: ^hello world$'
[IO.File]::WriteAllText($led, $tampered)
$r = Invoke-Gates @('-Status', $led)
Assert 'tamper: edited EXPECT reports unmet (digest mismatch)' ($r.Exit -ne 0 -and $r.Out -match 'G1\s+unmet.*digest mismatch') $r.Out

# --- manual gate reports owed
$led3 = Copy-Fixture 'manual/ref-906.md'
$r = Invoke-Gates @('-Run', $led3)
Assert 'manual: reported owed, not unmet' ($r.Exit -eq 0 -and $r.Out -match 'G2\s+owed' -and $r.Out -match '0 unmet, 1 owed') $r.Out

Remove-Item -Recurse -Force $tmp
Write-Output "$($script:run) run, $($script:passed) passed"
if ($script:failures.Count -gt 0) { $script:failures | ForEach-Object { [Console]::Error.WriteLine("FAIL: $_") }; exit 1 }
exit 0
