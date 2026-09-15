# gates.ps1 - verification ledger runner and linter (playbook R7). Zero dependencies. ASCII only:
# powershell.exe reads BOM-less scripts as ANSI, so non-ASCII bytes inside strings corrupt the parse.
# Format and lifecycle: .context/gates-ledger.md. Tests: .claude/scripts/tests/gates.tests.ps1
#
#   gates.ps1 -Run      gates/<id>.md   run the gates that are not met yet, write EVIDENCE lines
#   gates.ps1 -Reverify gates/<id>.md   run EVERY runnable gate, met or not, and demote failures (verify-a)
#   gates.ps1 -Status   gates/<id>.md   recompute from the file only (no execution)
#   gates.ps1 -Lint     gates/<id>.md   refuse gates that cannot fail
#   -TimeoutSeconds N   per-CHECK timeout (default 120); a CHECK past it is killed and recorded unmet
#
# Exit 0 = every runnable gate met and nothing abandoned. Exit 1 = an unmet gate or an ABANDON (a handoff).
# Exit 64/66 = usage error / missing ledger.
#
# A gate is MET only when its CHECK exited 0 AND its output matched EXPECT, and the EVIDENCE line's
# digest equals the digest of the current CHECK+EXPECT. Editing either flips the gate to unmet.
# MANUAL gates (no CHECK) are reported as `owed` until an owner writes `EVIDENCE: owner-confirmed ...`.
# `ABANDON: <id> <reason>` at column 1 marks a gate impossible in this task: reported owed, never run,
# and the ledger exits 1 so the handoff is visible. Output over 1 MiB is unmet (overflow), never truncated.
param(
    [switch]$Run, [switch]$Reverify, [switch]$Status, [switch]$Lint, [switch]$Strict,
    [Parameter(Position = 0)][string]$LedgerPath,
    [int]$TimeoutSeconds = 120,
    [string[]]$WorkspaceRule = @()   # "<command regex>=<required flag regex>" - fill from the Project binding when the stack exists
)
$ErrorActionPreference = 'Stop'
if (-not $LedgerPath) { [Console]::Error.WriteLine('usage: gates.ps1 -Run|-Reverify|-Status|-Lint [-TimeoutSeconds N] gates/<task-id>.md'); exit 64 }
if (-not (Test-Path -LiteralPath $LedgerPath)) { [Console]::Error.WriteLine("no such ledger: $LedgerPath"); exit 66 }
if ($TimeoutSeconds -lt 1 -or $TimeoutSeconds -gt 86400) { [Console]::Error.WriteLine('TimeoutSeconds must be 1..86400'); exit 64 }

$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir) { $projectDir = (Get-Location).Path }
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$TaskIdPattern = '^(feat|bug|ref|res|story|spec|plan)-\d{3}$'
$EmDash = [string][char]0x2014
$HeaderPattern = '^## (G\d+)\s+(' + $EmDash + '|-)\s+(.+?)\s*$'   # "## G1 - title" or with an em dash
$MaxOutputBytes = 1MB

function Get-Digest([string]$check, [string]$expect) {
    $sha = [System.Security.Cryptography.SHA1]::Create()
    $bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes("$check`n$expect"))
    return (($bytes | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 8)
}

function Read-Ledger([string]$path) {
    $text = [IO.File]::ReadAllText($path, $Utf8) -replace "`r", ''
    $lines = $text -split "`n"
    $gates = @(); $cur = $null; $abandoned = @{}
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ($l -match '^ABANDON:\s*(G\d+)\s+(.+?)\s*$') { $abandoned[$Matches[1]] = $Matches[2]; continue }
        if ($l -match $HeaderPattern) {
            $cur = [ordered]@{ Id = $Matches[1]; Title = $Matches[3]; Check = $null; Expect = $null; Manual = $null; Evidence = $null; Ticked = $false; HeaderLine = $i; EvidenceLine = -1; LastFieldLine = $i; Abandon = $null }
            $gates += $cur; continue
        }
        if ($null -eq $cur) { continue }
        if ($l -match '^CHECK:\s*(.*)$')    { $cur.Check = $Matches[1].Trim();  $cur.LastFieldLine = $i; continue }
        if ($l -match '^EXPECT:\s*(.*)$')   { $cur.Expect = $Matches[1].Trim(); $cur.LastFieldLine = $i; continue }
        if ($l -match '^MANUAL:\s*(.*)$')   { $cur.Manual = $Matches[1].Trim(); $cur.LastFieldLine = $i; continue }
        if ($l -match '^EVIDENCE:\s*(.*)$') { $cur.Evidence = $Matches[1].Trim(); $cur.EvidenceLine = $i; continue }
        if ($l -match '^\s*-\s*\[[xX]\]')   { $cur.Ticked = $true; continue }
    }
    foreach ($g in $gates) { if ($abandoned.ContainsKey($g.Id)) { $g.Abandon = $abandoned[$g.Id] } }
    return @{ Lines = $lines; Gates = $gates; Abandoned = $abandoned }
}

function Get-GateState($g) {
    # met | unmet | owed, from the file alone
    if ($g.Abandon) { return "owed (abandoned: $($g.Abandon))" }
    if ($null -eq $g.Check) {
        if ($g.Evidence -and $g.Evidence -match '^owner-confirmed\s+\S+') { return 'met (owner)' }
        return 'owed'
    }
    if (-not $g.Evidence) { return 'unmet (no evidence line)' }
    if ($g.Evidence -notmatch '^met\s+\S+\s+exit=0\s+digest=([0-9a-f]{8})\b') { return 'unmet (evidence does not record a met run)' }
    $d = $Matches[1]
    if ($d -ne (Get-Digest $g.Check $g.Expect)) { return 'unmet (digest mismatch: CHECK or EXPECT edited since the run)' }
    return 'met'
}

function Write-Evidence($ledger, $g, [string]$line) {
    $lines = $ledger.Lines
    if ($g.EvidenceLine -ge 0) { $lines[$g.EvidenceLine] = $line }
    else {
        $at = $g.LastFieldLine + 1
        $tail = @(); if ($at -lt $lines.Count) { $tail = @($lines[$at..($lines.Count - 1)]) }
        $lines = @($lines[0..($at - 1)]) + @($line) + $tail
        foreach ($o in $ledger.Gates) { if ($o.HeaderLine -gt $g.HeaderLine) { $o.HeaderLine++; $o.LastFieldLine++; if ($o.EvidenceLine -ge 0) { $o.EvidenceLine++ } } }
        $g.EvidenceLine = $at
    }
    $ledger.Lines = $lines
}

function Stop-ProcessTree([int]$rootPid) {
    # Kill a process and everything it spawned. Windows: taskkill /T. Elsewhere: walk children with pgrep, kill leaves first.
    if ($env:OS -eq 'Windows_NT') {
        $taskkill = Join-Path (Join-Path $env:SystemRoot 'System32') 'taskkill.exe'
        if (Test-Path $taskkill) { $null = & $taskkill /PID $rootPid /T /F 2>&1 }
        try { Stop-Process -Id $rootPid -Force -ErrorAction SilentlyContinue } catch {}
        return
    }
    $stack = New-Object System.Collections.Stack; $order = @()
    $stack.Push($rootPid)
    while ($stack.Count -gt 0) {
        $cur = $stack.Pop(); $order += $cur
        $kids = @(& pgrep -P $cur 2>$null | ForEach-Object { [int]$_ })
        foreach ($k in $kids) { $stack.Push($k) }
    }
    [array]::Reverse($order)
    foreach ($id in $order) { $null = & kill -9 $id 2>$null }
}

function Invoke-Check([string]$check) {
    # The CHECK runs in a child powershell via -EncodedCommand (verbatim; -Command would strip inner quotes),
    # with stdout+stderr redirected to temp files so a timeout can kill it without a pipe deadlock.
    $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($check))
    $outFile = [IO.Path]::GetTempFileName(); $errFile = [IO.Path]::GetTempFileName()
    $code = 1; $timedOut = $false
    try {
        # The CHECK runs in the same PowerShell this runner is running in (pwsh or Windows PowerShell).
        $psExe = (Get-Process -Id $PID).Path
        $p = Start-Process -FilePath $psExe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $enc) `
            -WorkingDirectory $projectDir -RedirectStandardOutput $outFile -RedirectStandardError $errFile -NoNewWindow -PassThru
        if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
            $timedOut = $true
            Stop-ProcessTree $p.Id   # a test runner the CHECK spawned must not outlive the gate
            try { $p.WaitForExit(5000) | Out-Null } catch {}
        }
        if (-not $timedOut) { $code = $p.ExitCode; if ($null -eq $code) { $code = 0 } }
        $bytes = (Get-Item $outFile).Length + (Get-Item $errFile).Length
        $out = ([IO.File]::ReadAllText($outFile) + "`n" + [IO.File]::ReadAllText($errFile)) -replace "`r", ''
    } catch { $out = $_.Exception.Message; $code = 1; $bytes = 0 }
    finally { Remove-Item $outFile, $errFile -Force -ErrorAction SilentlyContinue }
    return @{ Exit = $code; Out = $out.Trim(); TimedOut = $timedOut; Overflow = ($bytes -gt $MaxOutputBytes) }
}

$ledger = Read-Ledger $LedgerPath
$name = [IO.Path]::GetFileNameWithoutExtension($LedgerPath)

if ($Lint) {
    $problems = @()
    if ($name -notmatch $TaskIdPattern) { $problems += "ledger name '$name' is not a task id (feat|bug|ref|res|story|spec|plan-NNN)" }
    if ($ledger.Gates.Count -eq 0) { $problems += 'no gates found (headers look like: ## G1 - property that holds)' }
    foreach ($id in $ledger.Abandoned.Keys) { if (-not ($ledger.Gates | Where-Object { $_.Id -eq $id })) { $problems += "ABANDON names $id, which is not a gate in this ledger" } }
    foreach ($g in $ledger.Gates) {
        $p = "$($g.Id)"
        if ($g.Title -match '^(run|check|test|verify|execute|ensure|make sure|try)\b') { $problems += "$p title is an activity ('$($g.Title)'); state the property that holds" }
        if ($null -eq $g.Check -and $null -eq $g.Manual) { $problems += "$p has neither CHECK nor MANUAL" }
        if ($null -ne $g.Check) {
            if (-not $g.Check) { $problems += "$p CHECK is empty" }
            if ([string]::IsNullOrWhiteSpace($g.Expect)) { $problems += "$p has CHECK without EXPECT" }
            elseif ($g.Expect -match '^\^?\s*(ok|OK|true|True|yes|success|succeeded|passed|pass|done|0|1)\s*\$?$') { $problems += "$p EXPECT '$($g.Expect)' is a bare success marker; it cannot fail" }
            elseif ($g.Expect -match '(?<!\\)\b\d+\s+(passed|run|tests?|ok)\b') { $problems += "$p EXPECT pins a test count ('$($g.Expect)'); pin self-consistency instead, e.g. (\d+) run, \1 passed" }
            foreach ($r in $WorkspaceRule) {
                $parts = $r -split '=', 2
                if ($parts.Count -eq 2 -and $g.Check -match $parts[0] -and $g.Check -notmatch $parts[1]) { $problems += "$p CHECK runs a workspace-wide command without its workspace flag ($($parts[1]))" }
            }
        }
        if ($g.Ticked) { $problems += "$p has a hand-ticked box; only EVIDENCE lines written by -Run count" }
        if ($g.Abandon -and $g.Abandon.Length -lt 8) { $problems += "$p ABANDON reason is too short to be a handoff" }
        # tautological: the CHECK merely prints a literal that is its own EXPECT; it observes nothing.
        if ($g.Check -and $g.Expect -and $g.Check -match "^\s*(?:Write-Output|Write-Host|echo|'|`")\s*['`"]?(.+?)['`"]?\s*$") {
            $literal = $Matches[1].Trim(); $bare = ($g.Expect -replace '^\^', '') -replace '\$$', ''
            if ($literal -eq $bare -or $literal -eq $g.Expect) { $problems += "$p CHECK only prints its own EXPECT ('$literal'); observe the artifact the title names" }
        }
    }
    $warnings = @()
    $manual = @($ledger.Gates | Where-Object { $null -eq $_.Check }).Count
    if ($ledger.Gates.Count -gt 0 -and $manual * 2 -gt $ledger.Gates.Count) { $warnings += "ledger is mostly manual ($manual of $($ledger.Gates.Count) gates have no CHECK); a runnable gate per acceptance criterion is the norm" }
    foreach ($w in $warnings) { [Console]::Error.WriteLine("lint: warn $w") }
    if ($problems.Count -eq 0 -and -not ($Strict -and $warnings.Count -gt 0)) { Write-Output "lint: ok ($($ledger.Gates.Count) gates in $name)"; exit 0 }
    foreach ($x in $problems) { [Console]::Error.WriteLine("lint: $x") }
    exit 1
}

if ($Run -or $Reverify) {
    foreach ($g in $ledger.Gates) {
        if ($g.Abandon) { continue }
        if ($null -eq $g.Check) { if (-not $g.Evidence) { Write-Evidence $ledger $g 'EVIDENCE: owed' }; continue }
        if ($Run -and -not $Reverify -and (Get-GateState $g) -eq 'met') { continue }   # -Run: unmet gates only
        $r = Invoke-Check $g.Check
        $matched = [regex]::IsMatch($r.Out, $g.Expect, [Text.RegularExpressions.RegexOptions]::Multiline)
        $verdict = if ($r.TimedOut) { 'unmet' } elseif ($r.Overflow) { 'unmet' } elseif ($r.Exit -eq 0 -and $matched) { 'met' } else { 'unmet' }
        $first = ($r.Out -split "`n")[0]; if ($first.Length -gt 100) { $first = $first.Substring(0, 100) }
        $first = $first -replace '"', "'"
        if ($r.TimedOut) { $first = "timeout after ${TimeoutSeconds}s" }
        elseif ($r.Overflow) { $first = 'output overflow (> 1 MiB); make the CHECK print less' }
        $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $exitShown = if ($r.TimedOut) { 'timeout' } else { $r.Exit }
        Write-Evidence $ledger $g "EVIDENCE: $verdict $stamp exit=$exitShown digest=$(Get-Digest $g.Check $g.Expect) out=`"$first`""
    }
    [IO.File]::WriteAllText($LedgerPath, (($ledger.Lines -join "`n").TrimEnd() + "`n"), $Utf8)
    $ledger = Read-Ledger $LedgerPath
}

# status (also printed after -Run / -Reverify)
$met = 0; $unmet = 0; $owed = 0; $abandoned = 0
foreach ($g in $ledger.Gates) {
    $s = Get-GateState $g
    if ($s -like 'met*') { $met++ } elseif ($s -like 'owed (abandoned*') { $owed++; $abandoned++ } elseif ($s -eq 'owed') { $owed++ } else { $unmet++ }
    $word = ($s -split ' ')[0]
    $why = ''; if ($s -match '\((.*)\)') { $why = " [$($Matches[1])]" }
    Write-Output ("{0,-4} {1,-6} {2}{3}" -f $g.Id, $word, $g.Title, $why)
}
$suffix = if ($abandoned -gt 0) { " ($abandoned abandoned)" } else { '' }
Write-Output "${name}: $($ledger.Gates.Count) gates - $met met, $unmet unmet, $owed owed$suffix"
if ($unmet -gt 0 -or $abandoned -gt 0) { exit 1 } else { exit 0 }
