# Setup Guide

> One-time setup for a new project built on this template. 15–30 minutes for the basics; the pipeline binding can wait until you've chosen a stack.
>
> Canonical for setup. `README.md` points here; it doesn't repeat these steps.

## Step 0 — Get the template

- **Copy the `starter/` folder** — and only it — as the root of your new project. Everything at this repo's top level (`README.md`, `SETUP.md`, `LICENSE`) is documentation *about* the template and doesn't belong in your app.
- Then start your own git history inside the copied folder:

  ```
  git init
  git add -A
  git commit -m "Bootstrap from Ice Flow template"
  ```

- Keep the hidden files: `.claude/` (the gate hook lives there) and `.gitignore` (it excludes the gate sentinel `.claude/gate-open`).

## Step 1 — Verify the gate hook (2 min)

The XML task gate is enforced mechanically, not on trust. Check it before anything else:

1. Open the project in Claude Code. Approve the hooks when prompted (`.claude/settings.json` registers a PreToolUse gate hook and a PostToolUse budget hook).
2. Smoke test: ask Claude to make a trivial edit to a file under `src/` *without* approving an XML task. The write should be **blocked** with a "Gate closed" message.
3. If it isn't blocked: confirm `.claude/settings.json` exists (not renamed), and that PowerShell can run `.claude/hooks/gate-check.ps1`.
4. Budget hook smoke test: `sh .claude/run-ps.sh .claude/hooks/budget-check.ps1 -Path .claude/scripts/tests/fixtures/over-budget/TaskList.md` should print `TaskList.md:3 is 276 chars; budget 240` and exit 1. That is the same refusal Claude sees when a board row grows past its budget.
5. Ledger runner self-test: `sh .claude/run-ps.sh .claude/scripts/tests/gates.tests.ps1` should end with `N run, N passed`.
6. Prose scanner self-test: `sh .claude/run-ps.sh .claude/scripts/tests/unslop.tests.ps1` should end with `N run, N passed`. The same scanner runs as the second PostToolUse hook on records (`planning/done-plans/`, `wiki/*.md`, `reference/`, `.context/`) and refuses an edit that reads like assistant prose; `skills/unslop/SKILL.md` says how to repair one, and `.claude/scripts/unslop/rules.ps1` is where a false positive gets fixed.

Sentinel lifecycle (Claude manages this, but you should recognize it): approving an XML task → `.claude/gate-open` is created → task executes and commits → sentinel deleted. A sentinel left behind means the gate is silently open — delete the file.

**Prerequisite, all platforms:** PowerShell. macOS and Linux need PowerShell 7 (`pwsh`, https://aka.ms/powershell); Windows works with the built-in Windows PowerShell 5.1 or with PowerShell 7. Every hook runs through `sh .claude/run-ps.sh <script>`, which picks `pwsh` when present and falls back to `powershell`, so `.claude/settings.json` never names a binary and needs no edit per OS. Run any script by hand the same way: `sh .claude/run-ps.sh .claude/scripts/gates.ps1 -Status gates/<id>.md`. The scripts are ASCII-only and spawn child shells as the runtime they are running in.

## Step 2 — Project identity (5 min)

Open `CLAUDE.md` and fill the four lines under **Project Identity**: Name, One-line purpose, Stage, Primary stack.

## Step 2b — Choose a stack pack (2 min)

The template ships stack-free: `.context/rules.md`, the glossary, the routing table, the refactoring workspace, the pipeline binding and the standard gates each carry a `<!-- stack:... -->` anchor, and `src/` is a README. A stack pack fills them mechanically:

```
sh .claude/run-ps.sh .claude/scripts/apply-stack.ps1 react-fsd
sh .claude/run-ps.sh .claude/scripts/apply-stack.ps1 rust
```

Available packs and what each carries: `reference/stacks/index.md`; the pack shape and anchor contract: `reference/stacks/_pack-shape.md`. The script fills the anchors, copies the pack's `layout/` into `src/`, sets the `Stack pack:` line in `STATE.md`, and adds a log entry; running it twice changes nothing. Edit the applied rows in your project when your tooling differs from the pack's defaults; `apply-stack.ps1 -Check` then lists the divergence, which is expected. To swap packs later, pass `-Replace`. No pack that fits? Copy a pack folder, keep every file name, replace the content.

Self-test: `sh .claude/run-ps.sh .claude/scripts/tests/apply-stack.tests.ps1` should end with `N run, N passed`.

## Step 3 — Fill `STATE.md` (10 min)

Current Focus, Architecture Snapshot, Stack & Versions, Environments. Skip Recently Shipped / Known Issues while they're empty. `STATE.md` is overwrite-freely — don't polish it.

## Step 4 — Non-negotiables in `.context/rules.md` (5 min)

The top 5 rules are universal — keep them. Below that, fill in or **delete** sections that don't apply. Bracketed placeholders are prompts for you, not instructions for Claude.

## Step 5 — `.context/identity.md`, if user-facing (5 min)

Voice, tone, target user. Skip entirely for internal tooling.

## Step 6 — Bind the multi-agent pipeline (optional until you scale)

`.context/multi-agent-pipeline.md` defines roles, routing, and escalation for multi-model work. It ships **unbound** — the project works single-agent without touching it. When you're ready, fill the **Project binding** table:

| Slot | Typical value |
|---|---|
| `TIER-1` / `TIER-2` / `TIER-3` | Your strongest / strong / efficient models (e.g. Fable / Opus / Sonnet) |
| Task format | `.context/task-workflow.md` (the default fits) |
| Closeout dossier format | `planning/done-plans/_dossier-template.md` (ships filled in) |
| Gate ledger / Role briefs | ship filled in (`gates/<id>.md`, `.context/briefs/`) |
| Wiki root | `wiki/` |
| Architecture map | `STATE.md` → `## Architecture Snapshot` (until you outgrow it; then an index over section files) |
| Tasklist / log | `TaskList.md` · `wiki/log.md` |
| Build / Test / Lint commands | Per your stack — fill when the stack exists. Then fill the **standard gates** table in `.context/gates-ledger.md` and the measured timings in `.context/briefs/implementer.md`. |
| Workspace-flag lint rule | Only if your test command is workspace-wide (e.g. a monorepo): `-WorkspaceRule '<cmd regex>=<flag regex>'` |

Only the table gets edited; the rules themselves stay generic. The pipeline's operating rules (six-line dispatch, orchestrator writes nothing, blinding by file, one ledger re-execution, cost rulings) are in the same file and need no binding.

## Step 6b — Take a usage baseline (1 min, after the first week)

`sh .claude/run-ps.sh .claude/scripts/usage.ps1 -By week` reads the Claude Code transcripts for this project and prints main-vs-subagent consumption. Paste the `mean_ctx` figures into your first `housekeep` log entry; every later optimization cites a before and after from this script.

## Step 7 — Reset the wiki log (1 min, optional)

`wiki/log.md` may carry a baseline entry from the template's own history. Delete everything below the `<!-- new entries go below this line -->` marker so your project's log starts clean — this is the one time editing the log is fine, because it isn't *your* history yet.

## Step 8 — Decide your starting point

- Pre-code, fuzzy idea → **planning** workspace
- Concrete first feature → **feature-development**
- Existing codebase → **research** first, to ingest key docs

## Step 9 — First session

Start with:

> "Read CLAUDE.md, CONTEXT.md, and STATE.md. Then tell me which workspace applies to: [my task]"

Sanity checks for the first real task: the XML `<task>` wrapper should appear before any write to `src/`, `reference/`, or `.context/`; after your approval and the commit, the task should land in `TaskList.md ## Done`.

## Troubleshooting

| Symptom | Likely cause / fix |
|---|---|
| Gate blocks a file you believe is exempt | Check the "Which Gate Covers What" table in `.context/task-workflow.md` — only `STATE.md`, `TaskList.md`, `wiki/log.md`, and index files are exempt, and only for bookkeeping |
| Hook never fires | `.claude/settings.json` missing/renamed, or hooks not approved in Claude Code |
| Writes succeed with no approved task | Stale `.claude/gate-open` sentinel — delete it |
| Claude loads whole folders | Re-point it at the Routing Rule in `CLAUDE.md`; loading is per-file, per-section by design |
