# usage.ps1 - token consumption over Claude Code transcripts, main vs subagent (playbook R10). Zero dependencies. ASCII only.
#
#   usage.ps1 [-Project <slug>] [-By week|day|session] [-Since yyyy-MM-dd] [-Root <dir>]
#
# Reads ~/.claude/projects/<slug>/*.jsonl (main sessions) and <slug>/<session>/subagents/*.jsonl (subagents).
# The slug defaults to CLAUDE_PROJECT_DIR (or the current directory) with ':' and path separators replaced by '-'.
# One API response can appear as several assistant lines (one per content block); a turn is counted once per requestId.
# Columns: turns, prompts (user messages that are not tool results), tool uses, cached input (cache reads),
# uncached input (input + cache creation), output, mean and peak context per turn (all input tokens of a request),
# input per output token, output per tool use, compactions (compact-summary lines). Run weekly; record the mean
# context figures in the housekeep log entry; re-cut whatever the context-per-turn column says is growing.
param(
    [string]$Project,
    [ValidateSet('week', 'day', 'session')][string]$By = 'week',
    [string]$Since,
    [string]$Root = (Join-Path $HOME '.claude/projects')
)
$ErrorActionPreference = 'Stop'

if (-not $Project) {
    $dir = $env:CLAUDE_PROJECT_DIR
    if (-not $dir) { $dir = (Get-Location).Path }
    $Project = ($dir -replace '[:\\/]', '-')
}
$base = Join-Path $Root $Project
if (-not (Test-Path -LiteralPath $base)) { [Console]::Error.WriteLine("no transcripts at $base"); exit 66 }
$sinceDate = if ($Since) { [datetime]::Parse($Since) } else { [datetime]::MinValue }

$rxType    = [regex]'"type":"(assistant|user)"'
$rxReq     = [regex]'"requestId":"([^"]+)"'
$rxStamp   = [regex]'"timestamp":"([^"]+)"'
$rxIn      = [regex]'"input_tokens":(\d+)'
$rxCreate  = [regex]'"cache_creation_input_tokens":(\d+)'
$rxRead    = [regex]'"cache_read_input_tokens":(\d+)'
$rxOut     = [regex]'"output_tokens":(\d+)'
$rxTool    = [regex]'"type":"tool_use"'
$rxResult  = [regex]'"type":"tool_result"'
$rxMeta    = [regex]'"isMeta":true'
$rxCompact = [regex]'"isCompactSummary":true|"subtype":"compact_boundary"'

function Get-GroupKey([datetime]$t, [string]$session) {
    switch ($By) {
        'session' { return $session }
        'day'     { return $t.ToString('yyyy-MM-dd') }
        default   {
            $cal = [Globalization.CultureInfo]::InvariantCulture.Calendar
            $wk = $cal.GetWeekOfYear($t, [Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
            return ('{0}-W{1:00}' -f $t.Year, $wk)
        }
    }
}

$rows = @{}   # key "scope|group" -> accumulator
function Get-Row([string]$scope, [string]$group) {
    $k = "$scope|$group"
    if (-not $rows.ContainsKey($k)) {
        $rows[$k] = [ordered]@{ scope = $scope; group = $group; sessions = @{}; turns = 0; prompts = 0; tools = 0; cached = 0L; uncached = 0L; output = 0L; ctxSum = 0L; ctxPeak = 0L; compactions = 0 }
    }
    return $rows[$k]
}

$files = @()
Get-ChildItem -LiteralPath $base -Filter '*.jsonl' -File | ForEach-Object { $files += [pscustomobject]@{ Path = $_.FullName; Scope = 'main'; Session = $_.BaseName } }
Get-ChildItem -LiteralPath $base -Directory | ForEach-Object {
    $sub = Join-Path $_.FullName 'subagents'
    $sess = $_.Name
    if (Test-Path -LiteralPath $sub) { Get-ChildItem -LiteralPath $sub -Filter '*.jsonl' -File | ForEach-Object { $files += [pscustomobject]@{ Path = $_.FullName; Scope = 'sub'; Session = $sess } } }
}

foreach ($f in $files) {
    $seen = @{}
    $reader = [IO.StreamReader]::new($f.Path, [Text.Encoding]::UTF8)
    try {
        while ($null -ne ($line = $reader.ReadLine())) {
            $m = $rxType.Match($line); if (-not $m.Success) { continue }
            $ts = $rxStamp.Match($line); if (-not $ts.Success) { continue }
            $t = [datetime]::Parse($ts.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AdjustToUniversal)
            if ($t -lt $sinceDate) { continue }
            $row = Get-Row $f.Scope (Get-GroupKey $t $f.Session)
            $row.sessions[$f.Session] = $true
            if ($rxCompact.IsMatch($line)) { $row.compactions++ }
            if ($m.Groups[1].Value -eq 'user') {
                if (-not $rxResult.IsMatch($line) -and -not $rxMeta.IsMatch($line)) { $row.prompts++ }
                continue
            }
            if ($rxTool.IsMatch($line)) { $row.tools++ }
            $rq = $rxReq.Match($line); $rid = if ($rq.Success) { $rq.Groups[1].Value } else { [guid]::NewGuid().ToString() }
            if ($seen.ContainsKey($rid)) { continue }
            $seen[$rid] = $true
            $in = 0L; $cr = 0L; $rd = 0L; $out = 0L
            $x = $rxIn.Match($line);     if ($x.Success) { $in  = [long]$x.Groups[1].Value }
            $x = $rxCreate.Match($line); if ($x.Success) { $cr  = [long]$x.Groups[1].Value }
            $x = $rxRead.Match($line);   if ($x.Success) { $rd  = [long]$x.Groups[1].Value }
            $x = $rxOut.Match($line);    if ($x.Success) { $out = [long]$x.Groups[1].Value }
            $ctx = $in + $cr + $rd
            $row.turns++; $row.cached += $rd; $row.uncached += ($in + $cr); $row.output += $out
            $row.ctxSum += $ctx; if ($ctx -gt $row.ctxPeak) { $row.ctxPeak = $ctx }
        }
    } finally { $reader.Dispose() }
}

$out = $rows.Values | Sort-Object { $_.group }, { $_.scope } | ForEach-Object {
    $meanCtx = if ($_.turns) { [math]::Round($_.ctxSum / $_.turns) } else { 0 }
    $inPerOut = if ($_.output) { [math]::Round(($_.cached + $_.uncached) / $_.output, 1) } else { 0 }
    $outPerTool = if ($_.tools) { [math]::Round($_.output / $_.tools) } else { 0 }
    [pscustomobject]@{
        group = $_.group; scope = $_.scope; sessions = $_.sessions.Count; turns = $_.turns; prompts = $_.prompts; tool_uses = $_.tools
        cached_in = $_.cached; uncached_in = $_.uncached; output = $_.output
        mean_ctx = $meanCtx; peak_ctx = $_.ctxPeak; in_per_out = $inPerOut; out_per_tool = $outPerTool; compactions = $_.compactions
    }
}
if (-not $out) { Write-Output "no turns found under $base"; exit 0 }
Write-Output "usage: $Project  by=$By  files=$($files.Count)"
# Fixed-width rows: Format-Table wraps to the host width in a non-interactive shell and drops columns.
$fmt = '{0,-36} {1,-5} {2,8} {3,6} {4,7} {5,9} {6,11} {7,11} {8,9} {9,9} {10,9} {11,10} {12,12} {13,11}'
Write-Output ($fmt -f 'group', 'scope', 'sessions', 'turns', 'prompts', 'tool_uses', 'cached_in', 'uncached_in', 'output', 'mean_ctx', 'peak_ctx', 'in_per_out', 'out_per_tool', 'compactions')
foreach ($r in $out) {
    Write-Output ($fmt -f $r.group, $r.scope, $r.sessions, $r.turns, $r.prompts, $r.tool_uses, $r.cached_in, $r.uncached_in, $r.output, $r.mean_ctx, $r.peak_ctx, $r.in_per_out, $r.out_per_tool, $r.compactions)
}
