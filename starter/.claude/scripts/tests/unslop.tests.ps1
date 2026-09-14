# unslop.tests.ps1 - tests for the unslop scanner (zero dependencies). Run:
#   powershell -NoProfile -File .claude/scripts/tests/unslop.tests.ps1
# Prints "N run, N passed" on success; exit 1 on any failure. Fixtures: ./fixtures/unslop/
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$scripts = Split-Path -Parent $here
$unslop = Join-Path $scripts 'unslop/unslop.ps1'
$fx = Join-Path $here 'fixtures/unslop'
$root = Split-Path -Parent (Split-Path -Parent $scripts)
. (Join-Path $scripts 'unslop/rules.ps1')

$script:run = 0; $script:passed = 0; $script:failures = @()
function Assert([string]$name, [bool]$cond, [string]$detail = '') {
    $script:run++
    if ($cond) { $script:passed++ } else { $script:failures += "$name  $detail" }
}
function Invoke-Unslop([string[]]$argv, [string]$projectDir = $root, [string]$stdin = $null) {
    $ErrorActionPreference = 'Continue'
    $env:CLAUDE_PROJECT_DIR = $projectDir
    if ($null -ne $stdin) { $out = ($stdin | & powershell -NoProfile -ExecutionPolicy Bypass -File $unslop $argv 2>&1 | Out-String) }
    else { $out = (& powershell -NoProfile -ExecutionPolicy Bypass -File $unslop $argv 2>&1 | Out-String) }
    $ErrorActionPreference = 'Stop'
    return @{ Exit = $LASTEXITCODE; Out = $out }
}
function Rel([string]$p) { return ".claude/scripts/tests/fixtures/unslop/$p" }

# --- list-rules prints every rule with a reason
$r = Invoke-Unslop @('-ListRules')
$ids = Get-AllRuleIds
Assert 'list-rules: every rule id printed with its family' ($r.Exit -eq 0 -and (@($ids | Where-Object { $r.Out -notmatch [regex]::Escape($_.id) }).Count -eq 0)) $r.Out
Assert 'list-rules: every rule has a why' (@($ids | Where-Object { -not $_.why }).Count -eq 0) 'empty why'

# --- phrase family: the slop fixture hits the expected rules, once each on their line
$r = Invoke-Unslop @((Rel 'slop.md'))
foreach ($rule in @('worth-noting', 'leverage', 'needless-to-say', 'game-changer', 'delve', 'in-conclusion', 'feel-free', 'utilize')) {
    Assert "phrase: $rule fires on slop.md" ($r.Out -match "slop\.md:\d+: $rule ") $r.Out
}
Assert 'phrase: exit 1 with findings' ($r.Exit -eq 1) $r.Out

# --- structure family
Assert 'structure: exclamation fires' ($r.Out -match 'slop\.md:3: exclamation') $r.Out
Assert 'structure: rhetorical question fires' ($r.Out -match 'slop\.md:7: rhetorical-question') $r.Out
$r2 = Invoke-Unslop @((Rel 'rhythm.md'))
Assert 'structure: uniform rhythm fires on eight even sentences' ($r2.Out -match 'rhythm\.md:3: uniform-rhythm') $r2.Out

# --- protected spans and the allowlist stay silent
$r = Invoke-Unslop @((Rel 'clean.md'))
Assert 'clean: no findings (code, quotes, URLs, paths, strikethrough protected; allowlist words silent)' ($r.Exit -eq 0 -and $r.Out -match 'unslop: 0 findings') $r.Out
foreach ($w in $DomainAllowlist) {
    $tmp = [IO.Path]::GetTempFileName() + '.md'
    [IO.File]::WriteAllText($tmp, "# t`n`nWe $($w.word) the thing here today.`n")
    $rr = Invoke-Unslop @($tmp)
    Remove-Item $tmp -Force
    Assert "allowlist: '$($w.word)' is silent" ($rr.Exit -eq 0) $rr.Out
}

# --- record family: log heads below the marker; dossier bullets and paragraphs
$r = Invoke-Unslop @((Rel 'wiki/log.md'))
Assert 'record: bad log heads flagged, structural heading above the marker is not' ($r.Out -match 'log\.md:15: log-entry-head' -and $r.Out -match 'log\.md:19: log-entry-head' -and $r.Out -notmatch 'log\.md:5:') $r.Out
$r = Invoke-Unslop @((Rel 'planning/done-plans/sample.md'))
Assert 'record: six summary bullets flagged' ($r.Out -match 'summary-bullets - 6 bullets') $r.Out
Assert 'record: narrative paragraph over 60 words flagged' ($r.Out -match 'narrative-paragraph - \d+ words') $r.Out

# --- directory walk skips raw/, wiki/log/, template/
$walk = Join-Path ([IO.Path]::GetTempPath()) ("unslop-walk-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path (Join-Path $walk 'raw'), (Join-Path $walk 'wiki/log'), (Join-Path $walk 'template'), (Join-Path $walk 'reference') | Out-Null
foreach ($p in @('raw/a.md', 'wiki/log/2026-01.md', 'template/b.md', 'reference/c.md')) { [IO.File]::WriteAllText((Join-Path $walk $p), "# x`n`nWe delve into it.`n") }
$r = Invoke-Unslop @('reference', 'raw', 'wiki', 'template') $walk
Assert 'walk: only reference/c.md scanned' ($r.Out -match 'reference/c\.md:3: delve' -and $r.Out -match '1 findings in 1 file') $r.Out

# --- hook mode: a record edit with findings exits 2; a non-record edit exits 0
$hookRoot = Join-Path ([IO.Path]::GetTempPath()) ("unslop-hook-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path (Join-Path $hookRoot 'reference'), (Join-Path $hookRoot 'planning') | Out-Null
$record = Join-Path $hookRoot 'reference/notes.md'; $nonRecord = Join-Path $hookRoot 'planning/backlog.md'
[IO.File]::WriteAllText($record, "# n`n`nIt is worth noting that this works.`n")
[IO.File]::WriteAllText($nonRecord, "# b`n`nIt is worth noting that this works.`n")
$json = '{"tool_name":"Write","tool_input":{"file_path":"' + ($record -replace '\\', '\\\\') + '"}}'
$r = Invoke-Unslop @('-Hook') $hookRoot $json
Assert 'hook: record edit with a finding exits 2 and names the line' ($r.Exit -eq 2 -and $r.Out -match 'reference/notes\.md:3: worth-noting') $r.Out
$json2 = '{"tool_name":"Write","tool_input":{"file_path":"' + ($nonRecord -replace '\\', '\\\\') + '"}}'
$r = Invoke-Unslop @('-Hook') $hookRoot $json2
Assert 'hook: non-record edit exits 0 silently' ($r.Exit -eq 0 -and -not $r.Out.Trim()) $r.Out
Remove-Item -Recurse -Force $walk, $hookRoot

Write-Output "$($script:run) run, $($script:passed) passed"
if ($script:failures.Count -gt 0) { $script:failures | ForEach-Object { [Console]::Error.WriteLine("FAIL: $_") }; exit 1 }
exit 0
