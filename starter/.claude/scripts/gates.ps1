# gates.ps1 - verification ledger runner and linter (playbook R7). Zero dependencies. ASCII only:
# powershell.exe reads BOM-less scripts as ANSI, so non-ASCII bytes inside strings corrupt the parse.
# Format and lifecycle: .context/gates-ledger.md. Tests: .claude/scripts/tests/gates.tests.ps1
#
#   gates.ps1 -Run    gates/<id>.md   run every CHECK, write EVIDENCE lines, exit 0 iff every CHECK gate is met
#   gates.ps1 -Status gates/<id>.md   recompute from the file only (no execution), exit 0 iff no gate is unmet
#   gates.ps1 -Lint   gates/<id>.md   refuse gates that cannot fail, exit 0 iff clean
#
# A gate is MET only when its CHECK exited 0 AND its output matched EXPECT, and the EVIDENCE line's
# digest equals the digest of the current CHECK+EXPECT. Editing either flips the gate to unmet.
# MANUAL gates (no CHECK) are reported as `owed` until an owner writes `EVIDENCE: owner-confirmed ...`.
param(
    [switch]$Run, [switch]$Status, [switch]$Lint,
    [Parameter(Position = 0)][string]$LedgerPath,
    [string[]]$WorkspaceRule = @()   # "<command regex>=<required flag regex>" - fill from the Project binding when the stack exists
)
$ErrorActionPreference = 'Stop'
if (-not $LedgerPath) { [Console]::Error.WriteLine('usage: gates.ps1 -Run|-Status|-Lint gates/<task-id>.md'); exit 64 }
if (-not (Test-Path -LiteralPath $LedgerPath)) { [Console]::Error.WriteLine("no such ledger: $LedgerPath"); exit 66 }

$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir) { $projectDir = (Get-Location).Path }
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$TaskIdPattern = '^(feat|bug|ref|res|story|spec|plan)-\d{3}$'
$EmDash = [string][char]0x2014
$HeaderPattern = '^## (G\d+)\s+(' + $EmDash + '|-)\s+(.+?)\s*$'   # "## G1 - title" or with an em dash

function Get-Digest([string]$check, [string]$expect) {
    $sha = [System.Security.Cryptography.SHA1]::Create()
    $bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes("$check`n$expect"))
    return (($bytes | ForEach-Object { $_.ToString('x2') }) -join '').Substring(0, 8)
}

function Read-Ledger([string]$path) {
    $text = [IO.File]::ReadAllText($path, $Utf8) -replace "`r", ''
    $lines = $text -split "`n"
    $gates = @(); $cur = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $l = $lines[$i]
        if ($l -match $HeaderPattern) {
            $cur = [ordered]@{ Id = $Matches[1]; Title = $Matches[3]; Check = $null; Expect = $null; Manual = $null; Evidence = $null; Ticked = $false; HeaderLine = $i; EvidenceLine = -1; LastFieldLine = $i }
            $gates += $cur; continue
        }
        if ($null -eq $cur) { continue }
        if ($l -match '^CHECK:\s*(.*)$')    { $cur.Check = $Matches[1].Trim();  $cur.LastFieldLine = $i; continue }
        if ($l -match '^EXPECT:\s*(.*)$')   { $cur.Expect = $Matches[1].Trim(); $cur.LastFieldLine = $i; continue }
        if ($l -match '^MANUAL:\s*(.*)$')   { $cur.Manual = $Matches[1].Trim(); $cur.LastFieldLine = $i; continue }
        if ($l -match '^EVIDENCE:\s*(.*)$') { $cur.Evidence = $Matches[1].Trim(); $cur.EvidenceLine = $i; continue }
        if ($l -match '^\s*-\s*\[[xX]\]')   { $cur.Ticked = $true; continue }
    }
    return @{ Lines = $lines; Gates = $gates }
}

function Get-GateState($g) {
    # met | unmet | owed, from the file alone
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

function Invoke-Check([string]$check) {
    # Native stderr under ErrorActionPreference=Stop throws in Windows PowerShell 5.1; relax it around the call.
    $out = ''; $code = 1
    Push-Location $projectDir
    $saved = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        # -EncodedCommand: the CHECK reaches the child verbatim; -Command would strip its inner quotes.
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($check))
        $out = (& powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand $enc 2>&1 | Out-String)
        $code = $LASTEXITCODE
    } catch { $out = "$out`n$($_.Exception.Message)"; $code = 1 }
    finally { $ErrorActionPreference = $saved; Pop-Location }
    if ($null -eq $code) { $code = 0 }
    return @{ Exit = $code; Out = ($out -replace "`r", '').Trim() }
}

$ledger = Read-Ledger $LedgerPath
$name = [IO.Path]::GetFileNameWithoutExtension($LedgerPath)

if ($Lint) {
    $problems = @()
    if ($name -notmatch $TaskIdPattern) { $problems += "ledger name '$name' is not a task id (feat|bug|ref|res|story|spec|plan-NNN)" }
    if ($ledger.Gates.Count -eq 0) { $problems += 'no gates found (headers look like: ## G1 - property that holds)' }
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
    }
    if ($problems.Count -eq 0) { Write-Output "lint: ok ($($ledger.Gates.Count) gates in $name)"; exit 0 }
    foreach ($x in $problems) { [Console]::Error.WriteLine("lint: $x") }
    exit 1
}

if ($Run) {
    foreach ($g in $ledger.Gates) {
        if ($null -eq $g.Check) { if (-not $g.Evidence) { Write-Evidence $ledger $g 'EVIDENCE: owed' }; continue }
        $r = Invoke-Check $g.Check
        $matched = [regex]::IsMatch($r.Out, $g.Expect, [Text.RegularExpressions.RegexOptions]::Multiline)
        $verdict = if ($r.Exit -eq 0 -and $matched) { 'met' } else { 'unmet' }
        $first = ($r.Out -split "`n")[0]; if ($first.Length -gt 100) { $first = $first.Substring(0, 100) }
        $first = $first -replace '"', "'"
        $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        Write-Evidence $ledger $g "EVIDENCE: $verdict $stamp exit=$($r.Exit) digest=$(Get-Digest $g.Check $g.Expect) out=`"$first`""
    }
    [IO.File]::WriteAllText($LedgerPath, (($ledger.Lines -join "`n").TrimEnd() + "`n"), $Utf8)
    $ledger = Read-Ledger $LedgerPath
}

# status (also printed after -Run)
$met = 0; $unmet = 0; $owed = 0
foreach ($g in $ledger.Gates) {
    $s = Get-GateState $g
    if ($s -like 'met*') { $met++ } elseif ($s -eq 'owed') { $owed++ } else { $unmet++ }
    $word = ($s -split ' ')[0]
    $why = ''; if ($s -match '\((.*)\)') { $why = " [$($Matches[1])]" }
    Write-Output ("{0,-4} {1,-6} {2}{3}" -f $g.Id, $word, $g.Title, $why)
}
Write-Output "${name}: $($ledger.Gates.Count) gates - $met met, $unmet unmet, $owed owed"
if ($unmet -gt 0) { exit 1 } else { exit 0 }
