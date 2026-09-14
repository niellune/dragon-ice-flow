# unslop.ps1 - prose scanner for records (playbook R8). Zero dependencies. ASCII only (powershell.exe
# reads BOM-less scripts as ANSI). Rules, thresholds and allowlists live in rules.ps1, nowhere else.
# Tests: .claude/scripts/tests/unslop.tests.ps1. Skill: skills/unslop/SKILL.md.
#
#   unslop.ps1 <path> [<path> ...]   scan files; a directory walks *.md (SkipDirectories never entered)
#   unslop.ps1 -All                  scan every record root (housekeep)
#   unslop.ps1 -Hook                 PostToolUse mode: read the tool JSON on stdin, scan the edited file
#                                    only if it is a record; exit 2 with findings on stderr, else exit 0
#   unslop.ps1 -ListRules            print every rule with its family and reason
#
# Exit 0 = no findings; 1 = findings (scan / -All); 2 = findings (hook mode, so the editing agent sees them).
# Protected spans are never scanned: fenced blocks, inline code, quoted strings, images, link targets,
# URLs, path-like tokens, task ids, hashes, HTML comments, strikethrough. They are replaced by spaces of
# equal length so columns survive.
param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)][string[]]$Paths = @(),
    [switch]$All, [switch]$Hook, [switch]$ListRules
)
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'rules.ps1')

$projectDir = $env:CLAUDE_PROJECT_DIR
if (-not $projectDir) { $projectDir = (Get-Location).Path }
$projectDir = [IO.Path]::GetFullPath($projectDir)
$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Blank = [System.Text.RegularExpressions.MatchEvaluator]{ param($m) ' ' * $m.Value.Length }
# Non-ASCII characters are built from code points so the script itself stays ASCII.
$LQ = [string][char]0x201C; $RQ = [string][char]0x201D; $Bom = [string][char]0xFEFF; $Apos = [string][char]0x2019

function ConvertTo-Slash([string]$p) { return ($p -replace '\\', '/') }

function Get-Masked([string]$line) {
    $s = $line
    foreach ($pat in @(
        '<!--.*?-->', '~~[^~]+~~', '`[^`]*`', '!\[[^\]]*\]\([^)]*\)', '\]\([^)]*\)', 'https?://\S+',
        '"[^"]*"', ($LQ + '[^' + $RQ + ']*' + $RQ), '\S*[/\\]\S*',
        '\b(?:feat|bug|ref|res|story|spec|plan)-\d+[a-z]?\b', '\b[0-9a-f]{7,40}\b')) {
        $s = [regex]::Replace($s, $pat, $Blank)
    }
    return $s
}

# Classify every line once. kind drives paragraph grouping; masked is what the phrase and structure rules see.
function Get-Rows([string]$text) {
    $lines = ($text -replace ('^' + $Bom), '') -split "\r?\n"
    $rows = New-Object System.Collections.ArrayList
    $inFence = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $raw = $lines[$i]
        if ($raw -match '^\s*(?:```|~~~)') { $inFence = -not $inFence; [void]$rows.Add(@{ n = $i + 1; raw = $raw; kind = 'fence'; masked = '' }); continue }
        if ($inFence) { [void]$rows.Add(@{ n = $i + 1; raw = $raw; kind = 'fence'; masked = '' }); continue }
        $kind = 'text'
        if (-not $raw.Trim()) { $kind = 'blank' }
        elseif ($raw -match '^#{1,6}\s') { $kind = 'heading' }
        elseif ($raw -match '^\s*\|') { $kind = 'table' }
        elseif ($raw -match '^\s*>') { $kind = 'quote' }
        elseif ($raw -match '^\s*(?:[-*+]|\d+[.)])\s+') { $kind = 'bullet' }
        elseif ($raw -match '^\s+\S') { $kind = 'continuation' }
        $prose = if ($kind -eq 'quote') { $raw -replace '^\s*>\s?', '' } else { $raw }
        $masked = if ($kind -eq 'blank') { '' } else { Get-Masked $prose }
        [void]$rows.Add(@{ n = $i + 1; raw = $raw; kind = $kind; masked = $masked })
    }
    return $rows
}

# Group rows into paragraphs: a run of text/continuation rows, one bullet with its continuations, or one
# quote run. Headings, tables, fences and blanks are boundaries and never paragraphs.
function Get-Paragraphs($rows) {
    $out = New-Object System.Collections.ArrayList
    $cur = $null
    foreach ($row in $rows) {
        switch ($row.kind) {
            { $_ -in 'blank', 'heading', 'table', 'fence' } { if ($cur) { [void]$out.Add($cur) }; $cur = $null }
            'bullet' { if ($cur) { [void]$out.Add($cur) }; $cur = @{ kind = 'bullet'; start = $row.n; rows = @($row) } }
            'quote' {
                if ($cur -and $cur.kind -eq 'quote') { $cur.rows += $row }
                else { if ($cur) { [void]$out.Add($cur) }; $cur = @{ kind = 'quote'; start = $row.n; rows = @($row) } }
            }
            'continuation' { if ($cur) { $cur.rows += $row } else { $cur = @{ kind = 'text'; start = $row.n; rows = @($row) } } }
            default {
                if ($cur -and ($cur.kind -eq 'text' -or $cur.kind -eq 'bullet')) { $cur.rows += $row }
                else { if ($cur) { [void]$out.Add($cur) }; $cur = @{ kind = 'text'; start = $row.n; rows = @($row) } }
            }
        }
    }
    if ($cur) { [void]$out.Add($cur) }
    foreach ($p in $out) {
        $p.masked = (($p.rows | ForEach-Object { $_.masked }) -join ' ') -replace '\s+', ' '
        $p.raw = (($p.rows | ForEach-Object { $_.raw }) -join ' ') -replace '\s+', ' '
        $p.masked = $p.masked.Trim(); $p.raw = $p.raw.Trim()
    }
    return $out
}

function Get-WordCount([string]$t) { return ([regex]::Matches($t, ("[A-Za-z0-9][A-Za-z0-9'" + $Apos + "-]*"))).Count }
function Get-Sentences([string]$t) { return @(($t -split '(?<=[.!?])\s+') | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
function Get-Excerpt([string]$raw, [int]$index, [int]$length) {
    $from = [Math]::Max(0, $index - 30); $to = [Math]::Min($raw.Length, $index + $length + 30)
    return ($(if ($from -gt 0) { '...' } else { '' })) + $raw.Substring($from, $to - $from).Trim() + ($(if ($to -lt $raw.Length) { '...' } else { '' }))
}
function Get-Clip([string]$t, [int]$max = 90) { if ($t.Length -gt $max) { return $t.Substring(0, $max - 3) + '...' } else { return $t } }

function Add-Finding($list, $path, $line, $family, $rule, $excerpt) {
    [void]$list.Add([pscustomobject]@{ path = $path; line = $line; family = $family; rule = $rule; excerpt = $excerpt })
}

function Test-Phrases($rows, $path, $findings) {
    foreach ($row in $rows) {
        if (-not $row.masked) { continue }
        foreach ($p in $Phrases) {
            foreach ($m in [regex]::Matches($row.masked, $p.re, 'IgnoreCase')) {
                Add-Finding $findings $path $row.n 'phrase' $p.id (Get-Excerpt $row.raw $m.Index $m.Length)
            }
        }
    }
}

function Test-Structure($rows, $path, $findings) {
    foreach ($row in $rows) {
        if (-not $row.masked) { continue }
        $m = [regex]::Match($row.masked, '!(?![\w(\[{=-])')
        if ($m.Success) { Add-Finding $findings $path $row.n 'structure' 'exclamation' (Get-Excerpt $row.raw $m.Index 1) }
    }
    $rq = $Structure.rhetoricalQuestion; $ur = $Structure.uniformRhythm
    foreach ($p in (Get-Paragraphs $rows)) {
        $parts = Get-Sentences $p.masked
        for ($i = 0; $i + 1 -lt $parts.Count; $i++) {
            $q = $parts[$i]; $a = $parts[$i + 1]
            if (-not $q.EndsWith('?') -or $a.EndsWith('?')) { continue }
            if ((Get-WordCount $q) -gt $rq.maxQuestionWords -or (Get-WordCount $a) -lt $rq.minAnswerWords) { continue }
            if ($a.Length -le $rq.maxAnswerChars -and $a -cmatch '^[A-Z]' -and $a -match '\.$') {
                Add-Finding $findings $path $p.start 'structure' 'rhetorical-question' (Get-Clip ($q + ' ' + $a))
                break
            }
        }
        if ($parts.Count -ge $ur.minSentences) {
            $lengths = @($parts | ForEach-Object { Get-WordCount $_ })
            $mean = ($lengths | Measure-Object -Average).Average
            $var = ($lengths | ForEach-Object { ($_ - $mean) * ($_ - $mean) } | Measure-Object -Average).Average
            if ($mean -ge $ur.minMeanWords -and [Math]::Sqrt($var) -lt $ur.maxStdDevWords) {
                Add-Finding $findings $path $p.start 'structure' 'uniform-rhythm' ("$($parts.Count) sentences, lengths " + ($lengths -join '/'))
            }
        }
    }
}

function Test-DonePlans($rows, $path, $findings) {
    $dp = $Record.donePlans
    foreach ($p in (Get-Paragraphs $rows)) {
        if ($p.kind -ne 'text') { continue }
        $words = Get-WordCount $p.raw
        if ($words -gt $dp.maxParagraphWords) { Add-Finding $findings $path $p.start 'record' 'narrative-paragraph' ("$words words: " + (Get-Clip $p.raw 60)) }
    }
    for ($i = 0; $i -lt $rows.Count; $i++) {
        $row = $rows[$i]
        if ($row.kind -ne 'heading' -or $row.raw -notmatch $dp.summaryHeadingRe) { continue }
        $bullets = 0
        for ($c = $i + 1; $c -lt $rows.Count; $c++) {
            $next = $rows[$c]
            if ($next.kind -in 'blank', 'continuation') { continue }
            if ($next.kind -eq 'bullet') { if ($next.raw -match '^(?:[-*+]|\d+[.)])\s+') { $bullets++ }; continue }
            break
        }
        if ($bullets -gt $dp.maxSummaryBullets) { Add-Finding $findings $path $row.n 'record' 'summary-bullets' "$bullets bullets, at most $($dp.maxSummaryBullets)" }
    }
}

function Test-Log($rows, $path, $findings) {
    $lg = $Record.log
    $head = '^## \[\d{4}-\d{2}-\d{2}\] (?:' + ($lg.ops -join '|') + ') \| \S'
    $below = $false
    foreach ($row in $rows) {
        if ($row.raw.Trim() -eq $lg.marker) { $below = $true; continue }
        if (-not $below -or $row.kind -ne 'heading' -or $row.raw -notmatch '^##\s' -or $row.raw -match '^###') { continue }
        if ($row.raw -notmatch $head) { Add-Finding $findings $path $row.n 'record' 'log-entry-head' (Get-Clip $row.raw) }
    }
}

function Invoke-ScanText([string]$text, [string]$shownPath) {
    $rows = Get-Rows $text
    $findings = New-Object System.Collections.ArrayList
    Test-Phrases $rows $shownPath $findings
    Test-Structure $rows $shownPath $findings
    if ($shownPath -match $Record.donePlans.pathRe) { Test-DonePlans $rows $shownPath $findings }
    if ($shownPath -match $Record.log.pathRe) { Test-Log $rows $shownPath $findings }
    return @($findings | Sort-Object line, rule)
}

function Invoke-ScanFile([string]$path) {
    $full = if ([IO.Path]::IsPathRooted($path)) { [IO.Path]::GetFullPath($path) } else { [IO.Path]::GetFullPath((Join-Path $projectDir $path)) }
    $shown = ConvertTo-Slash $path
    if ($full.StartsWith($projectDir, [StringComparison]::OrdinalIgnoreCase)) { $shown = ConvertTo-Slash ($full.Substring($projectDir.Length).TrimStart('\', '/')) }
    return Invoke-ScanText ([IO.File]::ReadAllText($full, $Utf8)) $shown
}

function Test-Skipped([string]$rel) {
    foreach ($entry in $SkipDirectories) {
        if ($entry.Contains('/')) { if ($rel -eq $entry -or $rel.EndsWith('/' + $entry) -or $rel.StartsWith($entry + '/')) { return $true } }
        elseif (($rel -split '/') -contains $entry) { return $true }
    }
    return $false
}

# Expand the inputs: files as given, directories walked for *.md, SkipDirectories never entered.
function Get-MarkdownFiles([string[]]$inputs) {
    $files = @(); $missing = @()
    foreach ($in in $inputs) {
        $abs = if ([IO.Path]::IsPathRooted($in)) { $in } else { Join-Path $projectDir $in }
        if (-not (Test-Path -LiteralPath $abs)) { $missing += $in; continue }
        if (Test-Path -LiteralPath $abs -PathType Container) {
            Get-ChildItem -LiteralPath $abs -Recurse -File -Filter '*.md' | Sort-Object FullName | ForEach-Object {
                $rel = ConvertTo-Slash ($_.FullName.Substring($projectDir.Length).TrimStart('\', '/'))
                if (-not (Test-Skipped $rel)) { $files += $rel }
            }
        } else { $files += $in }
    }
    return @{ files = $files; missing = $missing }
}

function Write-Report($findings, [bool]$toStderr, [int]$fileCount = 1) {
    $w = { param($s) if ($toStderr) { [Console]::Error.WriteLine($s) } else { Write-Output $s } }
    foreach ($f in $findings) { & $w ("{0}:{1}: {2} - {3}" -f $f.path, $f.line, $f.rule, $f.excerpt) }
    & $w ("unslop: {0} findings in {1} file(s)" -f $findings.Count, $fileCount)
}

if ($ListRules) {
    foreach ($r in (Get-AllRuleIds)) { Write-Output ("{0,-10} {1,-22} {2}" -f $r.family, $r.id, $r.why) }
    exit 0
}

if ($Hook) {
    try { $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { exit 0 }
    $fp = $payload.tool_input.file_path
    if (-not $fp) { exit 0 }
    try { $full = [IO.Path]::GetFullPath($fp) } catch { exit 0 }
    if (-not $full.StartsWith($projectDir, [StringComparison]::OrdinalIgnoreCase)) { exit 0 }
    $rel = ConvertTo-Slash ($full.Substring($projectDir.Length).TrimStart('\', '/'))
    if ($rel -notmatch $RecordRe -or (Test-Skipped $rel)) { exit 0 }
    $findings = @()
    try { $findings = Invoke-ScanFile $rel } catch { exit 0 }
    if ($findings.Count -eq 0) { exit 0 }
    [Console]::Error.WriteLine("unslop: $rel has findings; a false positive fixes .claude/scripts/unslop/rules.ps1, a true one fixes the text (skills/unslop/SKILL.md)")
    Write-Report $findings $true
    exit 2
}

$inputs = $Paths
if ($All) { $inputs = $RecordRoots }
if (-not $inputs -or $inputs.Count -eq 0) { [Console]::Error.WriteLine('usage: unslop.ps1 <path>... | -All | -Hook | -ListRules'); exit 64 }
$set = Get-MarkdownFiles $inputs
foreach ($m in $set.missing) { [Console]::Error.WriteLine("unslop: no such path: $m") }
$targets = $set.files
if ($All) { $targets = @($targets | Where-Object { $_ -match $RecordRe }) }
$found = New-Object System.Collections.ArrayList
foreach ($f in $targets) { foreach ($x in (Invoke-ScanFile $f)) { [void]$found.Add($x) } }
Write-Report $found $false $targets.Count
if ($found.Count -gt 0) { exit 1 } else { exit 0 }
