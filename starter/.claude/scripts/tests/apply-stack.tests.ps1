# apply-stack.tests.ps1 - tests for apply-stack.ps1 (zero dependencies). Run:
#   powershell -NoProfile -File .claude/scripts/tests/apply-stack.tests.ps1
# Builds a temp project from this repo's own generic files and packs, then applies, re-applies, checks, drifts, replaces.
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$scripts = Split-Path -Parent $here
$apply = Join-Path $scripts 'apply-stack.ps1'
$root = Split-Path -Parent (Split-Path -Parent $scripts)
$Utf8 = New-Object System.Text.UTF8Encoding($false)

$script:run = 0; $script:passed = 0; $script:failures = @()
function Assert([string]$name, [bool]$cond, [string]$detail = '') { $script:run++; if ($cond) { $script:passed++ } else { $script:failures += "$name  $detail" } }
function Invoke-Apply([string[]]$argv, [string]$dir) {
    $ErrorActionPreference = 'Continue'
    $env:CLAUDE_PROJECT_DIR = $dir
    $out = (& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File $apply $argv 2>&1 | Out-String)
    $ErrorActionPreference = 'Stop'
    return @{ Exit = $LASTEXITCODE; Out = $out }
}
function New-TempProject {
    $t = Join-Path ([IO.Path]::GetTempPath()) ("apply-stack-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
    foreach ($rel in @('.context/rules.md', '.context/glossary.md', '.context/pipeline/00-binding.md', '.context/gates-ledger.md', 'CONTEXT.md', 'workspaces/refactoring/CONTEXT.md', 'STATE.md', 'wiki/log.md', 'src/README.md')) {
        $dst = Join-Path $t $rel; New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force | Out-Null
        Copy-Item (Join-Path $root $rel) $dst
    }
    Copy-Item (Join-Path $root 'reference/stacks') (Join-Path $t 'reference/stacks') -Recurse
    return $t
}
function Read-Text([string]$p) { return ([IO.File]::ReadAllText($p, $Utf8) -replace "`r", '') }
function Get-Hashes([string]$dir) { $h = @{}; Get-ChildItem $dir -Recurse -File | Where-Object { $_.FullName -notmatch '\\reference\\' } | ForEach-Object { $h[$_.FullName] = (Get-FileHash $_.FullName).Hash }; return $h }

# The generic files must carry a "Stack pack: none" line and unapplied anchors for these tests to mean anything.
$t = New-TempProject
Assert 'fixture: generic STATE says no pack' ((Read-Text (Join-Path $t 'STATE.md')) -match '(?m)^- Stack pack: none$') 'STATE line'

# --- -Check before any apply: nothing inferable
$r = Invoke-Apply @('-Check') $t
Assert 'check: no pack applied yet is a usage error' ($r.Exit -eq 64) $r.Out

# --- apply react-fsd
$r = Invoke-Apply @('react-fsd') $t
Assert 'apply: exit 0 and reports sections' ($r.Exit -eq 0 -and $r.Out -match 'code-style\s+applied' -and $r.Out -match 'binding\s+applied') $r.Out
$rules = Read-Text (Join-Path $t '.context/rules.md')
Assert 'apply: prose spliced between begin and anchor' ($rules -match '(?s)<!-- stack:architecture begin:react-fsd -->\n- `src/` is laid out by \*\*Feature-Sliced Design\*\*.*?<!-- stack:architecture applied:react-fsd -->') $rules
$bind = Read-Text (Join-Path $t '.context/pipeline/00-binding.md')
Assert 'apply: binding rows replaced in place' ($bind -match '(?m)^\| Build command \| `pnpm build`' -and $bind -notmatch 'not yet defined' -and $bind -match '(?m)^\| Ledger timeout \|') $bind
$gl = Read-Text (Join-Path $t '.context/glossary.md')
Assert 'apply: glossary rows appended to the table' ($gl -match '(?m)^\| Layer \|' -and $gl -match '(?m)^\| Barrel \|.*\n<!-- stack:glossary applied:react-fsd -->') $gl
Assert 'apply: layout copied into src' ((Test-Path (Join-Path $t 'src/features/README.md')) -and ((Read-Text (Join-Path $t 'src/README.md')) -match 'Feature-Sliced')) 'src'
Assert 'apply: STATE line set' ((Read-Text (Join-Path $t 'STATE.md')) -match '(?m)^- Stack pack: react-fsd \(applied \d{4}-\d{2}-\d{2}; reference/stacks/react-fsd/\)$') 'STATE'
Assert 'apply: log entry added below the marker' ((Read-Text (Join-Path $t 'wiki/log.md')) -match '(?s)<!-- new entries go below this line -->\n\n## \[\d{4}-\d{2}-\d{2}\] decision \| Stack pack react-fsd applied') 'log'
Assert 'apply: files stay LF' (-not (Read-Text (Join-Path $t '.context/rules.md')).Contains("`r")) 'CR'

# --- idempotent: second apply changes nothing
$before = Get-Hashes $t
$r = Invoke-Apply @('react-fsd') $t
$after = Get-Hashes $t
$diff = @($before.Keys | Where-Object { $before[$_] -ne $after[$_] })
Assert 'idempotent: second apply is a no-op' ($r.Exit -eq 0 -and $r.Out -match 'already applied' -and $diff.Count -eq 0) ("changed=" + ($diff -join ','))

# --- -Check clean, then drift one row and one prose line
$r = Invoke-Apply @('react-fsd', '-Check') $t
Assert 'check: clean after apply' ($r.Exit -eq 0 -and $r.Out -match '0 section\(s\) not as the pack') $r.Out
$r = Invoke-Apply @('-Check') $t
Assert 'check: pack inferred from STATE' ($r.Exit -eq 0) $r.Out
$bp = Join-Path $t '.context/pipeline/00-binding.md'
[IO.File]::WriteAllText($bp, ((Read-Text $bp) -replace '`pnpm build` \(Vite\)', '`pnpm build --mode prod`'), $Utf8)
$rp = Join-Path $t '.context/rules.md'
[IO.File]::WriteAllText($rp, ((Read-Text $rp) -replace 'no class components', 'class components allowed'), $Utf8)
$r = Invoke-Apply @('react-fsd', '-Check') $t
Assert 'check: drifted row and prose reported, exit 1' ($r.Exit -eq 1 -and $r.Out -match 'binding\s+drifted' -and $r.Out -match 'code-style\s+drifted' -and $r.Out -match 'glossary\s+same') $r.Out

# --- re-apply refreshes the drifted sections
$r = Invoke-Apply @('react-fsd') $t
Assert 'apply: drifted sections refreshed' ($r.Exit -eq 0 -and $r.Out -match 'binding\s+refreshed' -and $r.Out -match 'code-style\s+refreshed') $r.Out

# --- a second pack is refused without -Replace, applied with it
$r = Invoke-Apply @('rust') $t
Assert 'replace: second pack refused without -Replace' ($r.Exit -eq 1 -and $r.Out -match "already applied by 'react-fsd'") $r.Out
$r = Invoke-Apply @('rust', '-Replace') $t
$rules2 = Read-Text (Join-Path $t '.context/rules.md'); $gl2 = Read-Text (Join-Path $t '.context/glossary.md'); $bind2 = Read-Text (Join-Path $t '.context/pipeline/00-binding.md')
Assert 'replace: rust prose in, react prose out' ($r.Exit -eq 0 -and $rules2 -match 'begin:rust' -and $rules2 -notmatch 'react-fsd' -and $rules2 -notmatch 'Feature-Sliced') $rules2
Assert 'replace: react glossary rows removed, rust rows present' ($gl2 -notmatch '(?m)^\| Layer \|' -and $gl2 -match '(?m)^\| Crate \|') $gl2
Assert 'replace: binding rows now cargo' ($bind2 -match '(?m)^\| Build command \| `cargo build --workspace`') $bind2
Assert 'replace: STATE line now rust' ((Read-Text (Join-Path $t 'STATE.md')) -match '(?m)^- Stack pack: rust \(applied') 'STATE'

# --- a missing anchor stops everything before any write
$t2 = New-TempProject
$cp = Join-Path $t2 'CONTEXT.md'
[IO.File]::WriteAllText($cp, ((Read-Text $cp) -replace '<!-- stack:routing -->', ''), $Utf8)
$before = Get-Hashes $t2
$r = Invoke-Apply @('react-fsd') $t2
$after = Get-Hashes $t2
$diff = @($before.Keys | Where-Object { $before[$_] -ne $after[$_] })
Assert 'anchors: a missing anchor refuses the apply and writes nothing' ($r.Exit -eq 2 -and $r.Out -match 'stack:routing must appear exactly once' -and $diff.Count -eq 0) ("changed=" + ($diff -join ',') + ' ' + $r.Out)

Remove-Item -Recurse -Force $t, $t2
Write-Output "$($script:run) run, $($script:passed) passed"
if ($script:failures.Count -gt 0) { $script:failures | ForEach-Object { [Console]::Error.WriteLine("FAIL: $_") }; exit 1 }
exit 0
