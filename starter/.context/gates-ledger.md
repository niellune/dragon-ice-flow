# Gate Ledger

> Verification is a ledger of evidence, run once, re-verified once. One ledger per feature in flight at `gates/<feature-id>.md`; nothing else lives in `gates/`. This file is canonical for the format, the lifecycle and the standard gates. Runner and linter: `.claude/scripts/gates.ps1` (tests: `.claude/scripts/tests/gates.tests.ps1`).

## Format

```
# Gates — <feature-id>

## G1 — <a property that holds, not an activity>
CHECK: <one PowerShell command, run from the project root>
EXPECT: <regex the output must match; ^ and $ are per line>
EVIDENCE: met 2026-09-14T20:11:02Z exit=0 digest=3fa9c1e0 out="first line of output"

## G2 — <an outcome only the owner can observe>
MANUAL: <what the owner must see>
EVIDENCE: owed
```

- A gate is **met** only when CHECK exited 0 **and** the output matched EXPECT, **and** the EVIDENCE digest equals the digest of the current CHECK+EXPECT. Editing either flips the gate to unmet without a re-run.
- EVIDENCE lines are written only by `gates.ps1 -Run`. A hand-ticked box is not evidence; the linter rejects it and `-Status` reports the gate unmet.
- MANUAL gates have no CHECK and are reported as **owed** until the owner writes `EVIDENCE: owner-confirmed <date> <who>`.
- EXPECT for a test lane pins self-consistency, never a count: `(\d+) run, \1 passed`, not `12 passed`.
- The ledger name is the task id (`feat|bug|ref|res|story|spec|plan-NNN`). The linter refuses anything else.
- Keep CHECK and EXPECT ASCII. Output is captured through the console code page, so a non-ASCII character in the output (an em dash, say) may arrive as `-` or `?` and never match.
- `ABANDON: <id> <reason>` at column 1, only when the outcome is genuinely impossible in the authorized task (needs the owner, hardware, a deploy). The gate is reported **owed (abandoned)**, never run, and the ledger exits 1: a visible handoff, not a pass. Closeout turns it into `gate-owed? yes` on the board row and a line under **Owed** in the dossier.
- A CHECK past the timeout is killed and recorded `exit=timeout`, unmet. Output over 1 MiB is unmet (overflow), never truncated into a pass; make the CHECK print less (a summary line, `| Select-Object -Last 5`).

## Commands

| Command | Does | Exit 0 when |
|---|---|---|
| `gates.ps1 -Lint gates/<id>.md` | Refuses gates that cannot fail; `-Strict` turns warnings into failures | No lint finding |
| `gates.ps1 -Run gates/<id>.md` | Runs the gates **not yet met**, writes EVIDENCE lines, prints status | Every runnable gate met and nothing abandoned |
| `gates.ps1 -Reverify gates/<id>.md` | Runs **every** runnable gate, met or not, and demotes failures | same |
| `gates.ps1 -Status gates/<id>.md` | Recomputes from the file alone, no execution | No gate unmet and nothing abandoned |

`-TimeoutSeconds N` (default 120) bounds each CHECK; pass a larger value for a real test lane. Add `-WorkspaceRule '<command regex>=<flag regex>'` to the lint call when the stack has a workspace-wide test command that needs a package flag; put both values in the Project binding (`.context/pipeline/00-binding.md`) so every role passes the same ones.

## Lifecycle

| Stage | Does with the ledger |
|---|---|
| Spec | Writes it (standard gates + feature gates), runs `-Lint` and `-Status`, commits it. Never runs it. `<verify>` in the XML task names the ledger and gate ids. |
| Implementer | Runs `-Run` when the diff is ready; iterates with the inner loop, not by re-running the ledger (`-Run` re-executes only what is still unmet). Commits the evidence lines with the diff. |
| Verify-a (code vs spec) | Runs `-Reverify`: the feature's **one** re-execution. Nobody runs the lanes after this. A pass that did not re-verify has not verified. |
| Verify-b (spec vs intent) | Reads `-Status` only. Any unmet gate is a fail. Never executes. |
| Closeout | Pastes the EVIDENCE lines verbatim into the dossier, lists owed and abandoned gates under **Owed**, sets `gate-owed? yes` on the board row when any are, deletes `gates/<id>.md`. |

## Linter rules

Each refuses a gate that cannot fail or a ledger that cannot be traced:

| Rule | Refuses |
|---|---|
| task-id name | A ledger not named `<prefix>-NNN.md` |
| bare success | `EXPECT: ok`, `true`, `passed`, `done`, `0`, `1` and the like |
| pinned count | An EXPECT with a literal `N passed` / `N run` / `N tests` |
| activity title | A title starting with run / check / test / verify / execute / ensure / make sure / try |
| missing pair | CHECK without EXPECT, or a gate with neither CHECK nor MANUAL |
| hand tick | Any `- [x]` line inside a gate |
| workspace flag | With `-WorkspaceRule`, a CHECK matching the command regex but not the flag regex |
| abandon | An `ABANDON:` naming a gate that is not in the ledger, or with a reason too short to be a handoff |
| tautological | A CHECK that only prints a literal equal to its own EXPECT (`Write-Output X` / `EXPECT: X`); it observes nothing |
| mostly manual | *Warning:* more than half the gates have no CHECK. Fails only under `-Strict` |

## Standard gates

Every feature ledger starts with these; the spec adds feature-specific gates after them. Slots marked _binding_ are filled from the Project binding when the stack exists.

| Gate | CHECK | EXPECT |
|---|---|---|
| unit lane | _binding: test command_ | `(\d+) run, \1 passed` (or the lane's own self-consistent line) |
| lint | _binding: lint / typecheck command_ | the tool's clean line |
| format | _binding: format check_ | the tool's clean line |
| board budget | `powershell -NoProfile -File .claude/hooks/budget-check.ps1 -All` | `^budget-check: ok` |
| zero CR | `git diff --name-only <baseline>..HEAD \| ForEach-Object { if (Select-String -Path $_ -Pattern '\r' -Quiet) { 'CR: ' + $_ } }; 'scanned'` | `^scanned$` |
| ledger tests | `powershell -NoProfile -File .claude/scripts/tests/gates.tests.ps1` | `(\d+) run, \1 passed` (only for tasks that touch the runner) |
| prose (tasks that write markdown) | `powershell -NoProfile -File .claude/scripts/unslop/unslop.ps1 <the files the task writes>` | `^unslop: 0 findings` |
<!-- stack:gates -->

## Proofs on record

The tamper case (editing EXPECT on a met gate flips `-Status` to unmet) and the hand-tick case (a ticked box with no EVIDENCE line is unmet) are covered by `gates.tests.ps1` and were proven once on 2026-09-14 (`wiki/log.md`, ref-014).
