# Setup Guide

> One-time setup for a new project built on this template. 15–30 minutes for the basics; the pipeline binding can wait until you've chosen a stack.
>
> Canonical for setup. `README.md` points here; it doesn't repeat these steps.

## Step 0 — Get the template

- **Copy** this folder into your new project location (or use it as a GitHub template).
- If you copied it, detach the template's git history and start your own:

  ```
  rm -rf .git
  git init
  git add -A
  git commit -m "Bootstrap from Ice Flow template"
  ```

- Keep `.claude/` and `.gitignore` — the gate hook lives there, and the gitignore excludes the gate sentinel (`.claude/gate-open`).

## Step 1 — Verify the gate hook (2 min)

The XML task gate is enforced mechanically, not on trust. Check it before anything else:

1. Open the project in Claude Code. Approve the hooks when prompted (`.claude/settings.json` registers a PreToolUse hook).
2. Smoke test: ask Claude to make a trivial edit to a file under `src/` *without* approving an XML task. The write should be **blocked** with a "Gate closed" message.
3. If it isn't blocked: confirm `.claude/settings.json` exists (not renamed), and that PowerShell can run `.claude/hooks/gate-check.ps1`.

Sentinel lifecycle (Claude manages this, but you should recognize it): approving an XML task → `.claude/gate-open` is created → task executes and commits → sentinel deleted. A sentinel left behind means the gate is silently open — delete the file.

## Step 2 — Project identity (5 min)

Open `CLAUDE.md` and fill the four lines under **Project Identity**: Name, One-line purpose, Stage, Primary stack.

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
| Closeout dossier format | `.context/task-workflow-appendix.md` (after-task checklist) |
| Wiki root | `wiki/` |
| Architecture map | `STATE.md` → `## Architecture Snapshot` (until you outgrow it) |
| Tasklist / log | `TaskList.md` · `wiki/log.md` |
| Build / Test / Lint commands | Per your stack — fill when the stack exists |

Only the table gets edited; the rules themselves stay generic.

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
