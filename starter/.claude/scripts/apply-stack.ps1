# apply-stack.ps1 - apply a stack pack from reference/stacks/<pack>/ into the generic files' anchors.
# Zero dependencies. ASCII only (powershell.exe reads BOM-less scripts as ANSI). Contract: reference/stacks/_pack-shape.md
#
#   apply-stack.ps1 <pack>            fill every anchor, copy layout/ into src/, set the STATE line, add a log entry
#   apply-stack.ps1 <pack> -Check     compare the applied content to the pack; write nothing; exit 1 on drift or missing
#   apply-stack.ps1 <pack> -Replace   swap a previously applied pack for this one
#   apply-stack.ps1 -Check            infer the pack from STATE's "Stack pack:" line
#
# Nothing is written unless every anchor is present exactly once. A second apply of the same pack changes nothing.
param(
    [Parameter(Position = 0)][string]$Pack,
    [switch]$Check, [switch]$Replace,
    [string]$Root
)
$ErrorActionPreference = 'Stop'
# Windows PowerShell -File exits 0 after an unhandled exception; make a crash a visible non-zero exit instead.
trap { [Console]::Error.WriteLine("apply-stack: crashed: $($_.Exception.Message)"); exit 3 }
$projectDir = if ($Root) { $Root } elseif ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }
$projectDir = [IO.Path]::GetFullPath($projectDir)
$Utf8 = New-Object System.Text.UTF8Encoding($false)

# section -> target file, kind, pack source file (+ heading for prose)
$Sections = @(
    @{ name = 'code-style';   kind = 'prose'; file = '.context/rules.md';                  src = 'rules.md';      heading = 'code-style' }
    @{ name = 'architecture'; kind = 'prose'; file = '.context/rules.md';                  src = 'rules.md';      heading = 'architecture' }
    @{ name = 'naming';       kind = 'prose'; file = '.context/rules.md';                  src = 'rules.md';      heading = 'naming' }
    @{ name = 'testing';      kind = 'prose'; file = '.context/rules.md';                  src = 'rules.md';      heading = 'testing' }
    @{ name = 'boundaries';   kind = 'prose'; file = 'workspaces/refactoring/CONTEXT.md';  src = 'workspaces.md'; heading = 'boundaries' }
    @{ name = 'glossary';     kind = 'rows';  file = '.context/glossary.md';               src = 'glossary.md' }
    @{ name = 'routing';      kind = 'rows';  file = 'CONTEXT.md';                         src = 'routing.md' }
    @{ name = 'binding';      kind = 'rows';  file = '.context/pipeline/00-binding.md';    src = 'binding.md' }
    @{ name = 'gates';        kind = 'rows';  file = '.context/gates-ledger.md';           src = 'gates.md' }
)
$StateFile = 'STATE.md'; $LogFile = 'wiki/log.md'; $LogMarker = '<!-- new entries go below this line -->'

function Read-Lines([string]$rel) {
    $p = Join-Path $projectDir $rel
    if (-not (Test-Path -LiteralPath $p)) { throw "missing file: $rel" }
    $list = New-Object System.Collections.ArrayList
    foreach ($l in (([IO.File]::ReadAllText($p, $Utf8) -replace "`r", '') -split "`n")) { [void]$list.Add($l) }
    return ,$list   # the comma keeps PowerShell from unrolling the list into a fixed-size array
}
function Write-Lines([string]$rel, $lines) {
    $text = (($lines -join "`n").TrimEnd() + "`n")
    [IO.File]::WriteAllText((Join-Path $projectDir $rel), $text, $Utf8)
}
function Get-PackBlock([string]$pack, [string]$srcFile, [string]$heading) {
    # prose: the bullet lines under "## <heading>" in the pack file; rows: every "|" line
    $p = Join-Path $projectDir "reference/stacks/$pack/$srcFile"
    if (-not (Test-Path -LiteralPath $p)) { throw "pack $pack is missing $srcFile" }
    $lines = ([IO.File]::ReadAllText($p, $Utf8) -replace "`r", '') -split "`n"
    if (-not $heading) { return @($lines | Where-Object { $_ -match '^\|' }) }
    $out = @(); $in = $false
    foreach ($l in $lines) {
        if ($l -match '^## (\S+)') { $in = ($Matches[1] -eq $heading); continue }
        if ($in -and $l.Trim()) { $out += $l }
    }
    return $out
}
function Find-Anchor($lines, [string]$name) {
    $hits = @()
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -match ('^<!-- stack:' + [regex]::Escape($name) + '( applied:(\S+))? -->$')) { $hits += $i } }
    if ($hits.Count -ne 1) { throw "anchor stack:$name must appear exactly once (found $($hits.Count))" }
    $applied = $null; if ($lines[$hits[0]] -match 'applied:(\S+)') { $applied = $Matches[1] }
    return @{ index = $hits[0]; applied = $applied }
}
function Get-RowKey([string]$row) { return (($row -split '\|')[1]).Trim() }
function Get-AppliedProse($lines, [string]$name, [int]$anchorIdx, [string]$pack) {
    # lines between "begin:<pack>" and the anchor
    $begin = -1
    for ($i = $anchorIdx - 1; $i -ge 0; $i--) { if ($lines[$i] -eq "<!-- stack:$name begin:$pack -->") { $begin = $i; break }; if ($lines[$i] -match '^<!-- stack:') { break } }
    if ($begin -lt 0) { return $null }
    return @{ begin = $begin; content = @($lines[($begin + 1)..($anchorIdx - 1)] | Where-Object { $_ -ne $null }) }
}
function Get-TableRange($lines, [int]$anchorIdx) {
    # contiguous "|" lines immediately above the anchor
    $end = $anchorIdx - 1; while ($end -ge 0 -and -not $lines[$end].Trim()) { $end-- }
    $start = $end; while ($start -ge 0 -and $lines[$start] -match '^\|') { $start-- }
    return @{ start = $start + 1; end = $end }
}

# ---------------------------------------------------------------- plan every section first (no writes)
if (-not $Pack) {
    $st = Read-Lines $StateFile
    $m = $st | Where-Object { $_ -match '^- Stack pack: (\S+)' } | Select-Object -First 1
    if ($m -and $m -match '^- Stack pack: (\S+)' -and $Matches[1] -ne 'none') { $Pack = $Matches[1] } else { [Console]::Error.WriteLine('usage: apply-stack.ps1 <pack> [-Check] [-Replace]  (no pack applied yet)'); exit 64 }
}
if (-not (Test-Path -LiteralPath (Join-Path $projectDir "reference/stacks/$Pack/README.md"))) { [Console]::Error.WriteLine("no such pack: reference/stacks/$Pack"); exit 66 }

$files = @{}      # rel -> lines (loaded once, edited in memory)
$plan = @()       # per-section: status + edit closure inputs
$errors = @()
foreach ($s in $Sections) {
    if (-not $files.ContainsKey($s.file)) { $files[$s.file] = Read-Lines $s.file }
    $lines = $files[$s.file]
    try { $a = Find-Anchor $lines $s.name } catch { $errors += $_.Exception.Message; continue }
    $want = if ($s.kind -eq 'prose') { Get-PackBlock $Pack $s.src $s.heading } else { Get-PackBlock $Pack $s.src $null }
    $status = 'missing'; $other = $null
    if ($a.applied -eq $Pack) {
        if ($s.kind -eq 'prose') {
            $cur = Get-AppliedProse $lines $s.name $a.index $Pack
            $status = if ($cur -and (($cur.content -join "`n") -eq ($want -join "`n"))) { 'same' } else { 'drifted' }
        } else {
            $range = Get-TableRange $lines $a.index
            $table = @(); if ($range.end -ge $range.start) { $table = @($lines[$range.start..$range.end]) }
            $status = 'same'
            foreach ($w in $want) { $k = Get-RowKey $w; $have = $table | Where-Object { (Get-RowKey $_) -eq $k } | Select-Object -First 1; if ($have -ne $w) { $status = 'drifted' } }
        }
    } elseif ($a.applied) { $other = $a.applied; $status = "applied:$other" }
    $plan += @{ s = $s; anchor = $a; want = $want; status = $status; other = $other }
}
if ($errors.Count) { foreach ($e in $errors) { [Console]::Error.WriteLine("apply-stack: $e") }; [Console]::Error.WriteLine('apply-stack: nothing written'); exit 2 }

if ($Check) {
    $bad = 0
    foreach ($p in $plan) { $line = "{0,-13} {1}" -f $p.s.name, $p.status; Write-Output $line; if ($p.status -ne 'same') { $bad++ } }
    $st = Read-Lines $StateFile; $stateOk = ($st | Where-Object { $_ -match ('^- Stack pack: ' + [regex]::Escape($Pack) + ' \(applied') }).Count -eq 1
    Write-Output ("{0,-13} {1}" -f 'state-line', $(if ($stateOk) { 'same' } else { 'missing' })); if (-not $stateOk) { $bad++ }
    Write-Output "apply-stack -Check ${Pack}: $bad section(s) not as the pack has them"
    if ($bad) { exit 1 } else { exit 0 }
}

$blockers = @($plan | Where-Object { $_.other -and -not $Replace })
if ($blockers.Count) { foreach ($b in $blockers) { [Console]::Error.WriteLine("apply-stack: stack:$($b.s.name) already applied by '$($b.other)'; pass -Replace to swap") }; [Console]::Error.WriteLine('apply-stack: nothing written'); exit 1 }

# ---------------------------------------------------------------- apply (in memory), then write every file at once
$touched = @(); $changed = 0
foreach ($p in $plan) {
    if ($p.status -eq 'same') { Write-Output ("{0,-13} same" -f $p.s.name); continue }
    $s = $p.s; $lines = $files[$s.file]; $a = Find-Anchor $lines $s.name
    if ($s.kind -eq 'prose') {
        if ($a.applied) {
            $cur = Get-AppliedProse $lines $s.name $a.index $a.applied
            if ($cur) { $lines.RemoveRange($cur.begin, $a.index - $cur.begin); $a = Find-Anchor $lines $s.name }
        }
        $lines.Insert($a.index, "<!-- stack:$($s.name) begin:$Pack -->")
        $at = $a.index + 1
        foreach ($w in $p.want) { $lines.Insert($at, $w); $at++ }
        $lines[$at] = "<!-- stack:$($s.name) applied:$Pack -->"
    } else {
        if ($a.applied -and $a.applied -ne $Pack) {
            # drop the previous pack's rows, by key
            $oldRows = Get-PackBlock $a.applied $s.src $null
            $oldKeys = @($oldRows | ForEach-Object { Get-RowKey $_ })
            $range = Get-TableRange $lines $a.index
            for ($i = $range.end; $i -ge $range.start; $i--) { if ($oldKeys -contains (Get-RowKey $lines[$i])) { $lines.RemoveAt($i) } }
            $a = Find-Anchor $lines $s.name
        }
        foreach ($w in $p.want) {
            $range = Get-TableRange $lines $a.index; $k = Get-RowKey $w; $replaced = $false
            for ($i = $range.start; $i -le $range.end; $i++) { if ((Get-RowKey $lines[$i]) -eq $k) { $lines[$i] = $w; $replaced = $true; break } }
            if (-not $replaced) { $lines.Insert($a.index, $w); $a = Find-Anchor $lines $s.name }
        }
        $lines[$a.index] = "<!-- stack:$($s.name) applied:$Pack -->"
    }
    Write-Output ("{0,-13} {1}" -f $s.name, $(if ($p.other) { "replaced $($p.other)" } elseif ($p.status -eq 'drifted') { 'refreshed' } else { 'applied' }))
    if ($touched -notcontains $s.file) { $touched += $s.file }; $changed++
}

# STATE line
$state = Read-Lines $StateFile; $stamp = (Get-Date).ToString('yyyy-MM-dd')
$newLine = "- Stack pack: $Pack (applied $stamp; reference/stacks/$Pack/)"
$idx = -1; for ($i = 0; $i -lt $state.Count; $i++) { if ($state[$i] -match '^- Stack pack: ') { $idx = $i; break } }
if ($idx -lt 0) { [Console]::Error.WriteLine("apply-stack: STATE.md has no '- Stack pack:' line; nothing written"); exit 2 }
if ($state[$idx] -notmatch ('^- Stack pack: ' + [regex]::Escape($Pack) + ' \(')) { $state[$idx] = $newLine; $files[$StateFile] = $state; if ($touched -notcontains $StateFile) { $touched += $StateFile }; $changed++; Write-Output ("{0,-13} set" -f 'state-line') } else { Write-Output ("{0,-13} same" -f 'state-line') }

if ($changed -eq 0) { Write-Output "apply-stack ${Pack}: already applied, nothing to do"; exit 0 }

# layout
$layout = Join-Path $projectDir "reference/stacks/$Pack/layout"
$copied = 0
if (Test-Path -LiteralPath $layout) {
    Get-ChildItem -LiteralPath $layout -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($layout.Length).TrimStart('\', '/')
        $dst = Join-Path (Join-Path $projectDir 'src') $rel
        $dir = Split-Path -Parent $dst; if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        Copy-Item -LiteralPath $_.FullName -Destination $dst -Force; $copied++
    }
}
Write-Output ("{0,-13} {1} file(s) into src/" -f 'layout', $copied)

# log entry
$log = Read-Lines $LogFile
$mi = -1; for ($i = 0; $i -lt $log.Count; $i++) { if ($log[$i].Trim() -eq $LogMarker) { $mi = $i; break } }
if ($mi -ge 0) {
    $entry = @('', "## [$stamp] decision | Stack pack $Pack applied", '', "Applied `reference/stacks/$Pack/` with `.claude/scripts/apply-stack.ps1`: $changed section(s) filled, $copied layout file(s) copied into `src/`. Rows and bullets now in the anchored files are the pack's defaults; edit them there when the project differs and `-Check` will report the divergence.")
    $at = $mi + 1; foreach ($e in $entry) { $log.Insert($at, $e); $at++ }
    $files[$LogFile] = $log; $touched += $LogFile
}

foreach ($rel in $touched) { Write-Lines $rel $files[$rel] }
Write-Output "apply-stack ${Pack}: $changed section(s) written, files: $($touched -join ', ')"
exit 0
