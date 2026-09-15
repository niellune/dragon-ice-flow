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
    $out = (& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File $gates $argv 2>&1 | Out-String)
    $ErrorActionPreference = 'Stop'
    return @{ Exit = $LASTEXITCODE; Out = $out }
}
function Copy-Fixture([string]$rel) {
    $dst = Join-Path $tmp ([IO.Path]::GetFileName($rel))
    Copy-Item (Join-Path $fx $rel) $dst -Force
    return $dst
}
function Get-Evidence([string]$path, [string]$id) {
    $t = [IO.File]::ReadAllText($path)
    if ($t -match "(?s)## $id .*?\nEVIDENCE: (\S+ \S+)") { return $Matches[1] } else { return '' }
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
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'good/ref-900.md'), '-WorkspaceRule', 'Join=--nope')
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

# --- run: only unmet gates re-execute; -Reverify re-executes all
$g1Before = Get-Evidence $led 'G1'
$edited = [IO.File]::ReadAllText($led) -replace 'CHECK: 2 \+ 2', 'CHECK: 2 + 3'
[IO.File]::WriteAllText($led, $edited)
Start-Sleep -Seconds 1
$r = Invoke-Gates @('-Run', $led)
Assert 'run: unmet-only leaves the met gate untouched' ((Get-Evidence $led 'G1') -eq $g1Before -and $r.Out -match 'G2\s+unmet') ("before=$g1Before after=" + (Get-Evidence $led 'G2'))
Start-Sleep -Seconds 1
$r = Invoke-Gates @('-Reverify', $led)
Assert 'reverify: re-executes the met gate too' ((Get-Evidence $led 'G1') -ne $g1Before) ("before=$g1Before after=" + (Get-Evidence $led 'G1'))

# --- tamper: editing EXPECT flips to unmet without a re-run
$led3 = Copy-Fixture 'good/ref-900.md'
$null = Invoke-Gates @('-Run', $led3)
$tampered = [IO.File]::ReadAllText($led3) -replace 'EXPECT: \^hello\$', 'EXPECT: ^hello world$'
[IO.File]::WriteAllText($led3, $tampered)
$r = Invoke-Gates @('-Status', $led3)
Assert 'tamper: edited EXPECT reports unmet (digest mismatch)' ($r.Exit -ne 0 -and $r.Out -match 'G1\s+unmet.*digest mismatch') $r.Out

# --- manual gate reports owed
$led4 = Copy-Fixture 'manual/ref-906.md'
$r = Invoke-Gates @('-Run', $led4)
Assert 'manual: reported owed, not unmet' ($r.Exit -eq 0 -and $r.Out -match 'G2\s+owed' -and $r.Out -match '0 unmet, 1 owed') $r.Out

# --- timeout: a CHECK past the budget is killed and recorded unmet
$led5 = Copy-Fixture 'timeout/ref-907.md'
$sw = [Diagnostics.Stopwatch]::StartNew()
$r = Invoke-Gates @('-Run', $led5, '-TimeoutSeconds', '1')
$sw.Stop()
$txt5 = [IO.File]::ReadAllText($led5)
Assert 'timeout: gate unmet with timeout evidence' ($r.Exit -ne 0 -and $txt5 -match 'EVIDENCE: unmet \S+ exit=timeout') $txt5
Assert 'timeout: runner returned well before the CHECK would have' ($sw.Elapsed.TotalSeconds -lt 15) ("took " + $sw.Elapsed.TotalSeconds)

# --- abandon: reported owed, never run, exit 1 (visible handoff); lint accepts it
$led6 = Copy-Fixture 'abandon/ref-908.md'
$r = Invoke-Gates @('-Lint', $led6)
Assert 'abandon: lint accepts a reasoned ABANDON' ($r.Exit -eq 0) $r.Out
$r = Invoke-Gates @('-Run', $led6)
$txt6 = [IO.File]::ReadAllText($led6)
Assert 'abandon: G2 owed as abandoned, exit 1' ($r.Exit -eq 1 -and $r.Out -match 'G2\s+owed.*abandoned' -and $r.Out -match '1 abandoned') $r.Out
Assert 'abandon: abandoned gate was never executed' (-not ($txt6 -match '(?s)## G2 .*?EVIDENCE:')) $txt6

# --- overflow: output over 1 MiB is unmet, never truncated into a pass
$led7 = Copy-Fixture 'overflow/ref-909.md'
$r = Invoke-Gates @('-Run', $led7)
$txt7 = [IO.File]::ReadAllText($led7)
Assert 'overflow: gate unmet with overflow evidence' ($r.Exit -ne 0 -and $txt7 -match 'output overflow') $txt7

# --- lint: tautological CHECK (prints its own EXPECT) is refused
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'bad-tautology/ref-911.md'))
Assert 'lint: tautological check rejected' ($r.Exit -ne 0 -and $r.Out -match 'only prints its own EXPECT') $r.Out

# --- lint: mostly-manual ledger warns, and fails only under -Strict
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'mostly-manual/ref-912.md'))
Assert 'lint: mostly-manual warns without failing' ($r.Exit -eq 0 -and $r.Out -match 'lint: warn ledger is mostly manual') $r.Out
$r = Invoke-Gates @('-Lint', (Join-Path $fx 'mostly-manual/ref-912.md'), '-Strict')
Assert 'lint: mostly-manual fails under -Strict' ($r.Exit -ne 0) $r.Out

# --- timeout: the CHECK's own child processes are killed with it (process tree)
$led8 = Copy-Fixture 'tree-kill/ref-913.md'
$r = Invoke-Gates @('-Run', $led8, '-TimeoutSeconds', '2')
Start-Sleep -Seconds 1
$lingering = if ($env:OS -eq 'Windows_NT') { @(Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'tree-kill-marker-7f3a' }).Count } else { @(& pgrep -f 'tree-kill-marker-7f3a' 2>$null).Count }
Assert 'timeout: grandchild process does not outlive the gate' ($r.Exit -ne 0 -and $lingering -eq 0) ("lingering=$lingering " + $r.Out)

Remove-Item -Recurse -Force $tmp
Write-Output "$($script:run) run, $($script:passed) passed"
if ($script:failures.Count -gt 0) { $script:failures | ForEach-Object { [Console]::Error.WriteLine("FAIL: $_") }; exit 1 }
exit 0
