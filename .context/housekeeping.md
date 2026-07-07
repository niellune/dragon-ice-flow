# Housekeeping

> Rules for keeping a real project lean as it grows. Run weekly or after every 10–20 ingests/tasks.

## Why This Matters

Without housekeeping, three things break around month 3 of real use:

1. **Always-load tokens balloon** — STATE.md fills with stale entries, indexes get crowded
2. **Wiki ingest cost grows** — too many entity/concept pages to consider when checking for duplicates
3. **Planning folder becomes noise** — done stories crowd out active ones

Housekeeping is *not* deleting things. It's moving them from "always visible" to "findable when needed."

## The Five Rules

### Rule 1 — Trim windows on every operational file

These files have explicit "last N" rules. Enforce on every housekeep:

| File | Keep | Move overflow to |
|---|---|---|
| `STATE.md` Recently Shipped | Last 5 | `wiki/log.md` (already there if logged correctly) |
| `TaskList.md` Done | Last 20 | Nothing — git history + `wiki/log.md` already preserve it |
| `wiki/log.md` | Last 6 months at the top, rest in an `archive/` section at the bottom | Same file, just below an `## Archive` header |
| `planning/stories/index.md` Done | Last 20 | Older entries stay in `planning/stories/` but drop from the index |
| `planning/plans/index.md` Done | Last 10 | Same |

When a list exceeds its window, trim the *oldest* entries. Never delete the underlying file — only the index entry.

### Rule 2 — Archive completed planning artifacts in batches

When `planning/stories/` exceeds ~30 files (or any subfolder ≥30), move all `status: done` items to `planning/_archive/[year-quarter]/`:

```
planning/_archive/2026-Q2/stories/[slug].md
planning/_archive/2026-Q2/specs/[slug].md
planning/_archive/2026-Q2/plans/[slug].md
```

Keep the original slug. Update each subfolder's `index.md` to drop the archived entries from the active list. Do NOT delete — archived artifacts are referenced from `wiki/log.md` decision entries.

The active `planning/stories/` should rarely exceed 30 files. If it does, the project is accumulating undecided work — that's a planning problem, not a housekeeping problem.

### Rule 3 — Wiki page hygiene

Run these checks during a housekeep pass. Report findings, don't auto-fix.

**Orphans** — pages with no inbound `[[links]]` from `wiki/index.md` or other pages. Options:
- Delete (rare — only if duplicate or wrong)
- Merge into a related page
- Add inbound links

**Bloated pages** — anything over 1500 words. Split into focused pages with cross-links.

**Stale claims** — pages last touched >6 months ago that talk about external tools, versions, or rapidly-changing facts. Either re-verify or mark `status: stale` in frontmatter.

**Duplicates** — multiple pages about the same entity or concept under different slugs. Pick a canonical, redirect others by adding `> See [[canonical-name]]` at the top.

**Index drift** — pages in `wiki/entities/` etc. not listed in `wiki/index.md`, or vice versa. Reconcile.

### Rule 4 — Reference folder boundaries

`reference/` is for **decisions about THIS project** that don't fit in `.context/`. The temptation is to dump everything there. Enforce these rules:

- Each `reference/` file is ≤ 1500 words. Split if longer.
- If a `reference/` doc has been read in zero tasks for 90 days, propose archiving (move to `reference/_archive/`).
- If a `reference/` doc contains general knowledge (not project-specific), it belongs in `wiki/concepts/` instead.
- If a `reference/` doc duplicates content in `.context/identity.md`, `.context/rules.md`, or `.context/glossary.md`, fix the duplication — the `.context/` file wins.

### Rule 5 — STATE.md pruning

The most overlooked file. Production drift looks like:
- "Open Decisions" with entries that were resolved months ago
- "Known Issues" listing bugs that were fixed
- "Recently Shipped" showing items from 6 months ago

On every housekeep:
- Remove resolved Open Decisions (they should already be in `wiki/log.md` as `decision` entries)
- Remove fixed Known Issues (verify they're in `wiki/log.md` as `fix` entries)
- Trim Recently Shipped to actual last 5
- Update Architecture Snapshot and Stack & Versions if reality has diverged
- Update the "Last updated" line

`STATE.md` should be roughly the **same size** at month 12 as at month 1. If it's growing, you're not pruning.

## The Housekeep Sequence

When the user asks to run housekeeping:

1. **Report current state** — token counts of each always-load file vs targets, file counts in each folder.
2. **Run Rule 1 trims** — propose specific deletions/moves; wait for approval.
3. **Run Rule 5 STATE.md pruning** — propose specific changes; wait for approval.
4. **Run Rule 2 archival check** — if any planning subfolder ≥30 files, propose batch archive.
5. **Run Rule 3 wiki lint** — invoke the existing wiki lint operation from `workspaces/research/`. This already follows the propose-then-approve pattern.
6. **Run Rule 4 reference review** — list files unused for 90+ days, propose archive.
7. **Append a housekeep entry to `wiki/log.md`** with kind `housekeep` and a summary of what was changed.

Housekeeping is a **proposal** workflow, not autonomous cleanup. Every action waits for approval.

## Token Budgets (Production Targets)

For an active project at month 6:

| File | Target | Hard limit |
|---|---|---|
| `CLAUDE.md` | ~850 | 1100 |
| `CONTEXT.md` | ~600 | 800 |
| `STATE.md` | ~300 | 500 |
| `TaskList.md` | ~400 (most in Done) | 700 |
| `.context/rules.md` | ~500 (filled in) | 800 |
| `.context/task-workflow.md` | ~480 (incl. gate table) | 600 |
| **Always-load total** | **~3,500** | **5,000** |
| Workspace files | 300–1400 each | 1500 |
| `wiki/index.md` | ~600 (~50 entries) | 1200 |
| Planning indexes (each) | ~200 | 500 |

If you blow a hard limit, that's the trigger for a housekeep pass whether or not it's "scheduled."

## When NOT to Housekeep

- Mid-task. Finish the task first.
- When you don't know what changed in the last week — read `wiki/log.md` first to refresh context.
- When you're about to do a big migration or refactor — those will reshape everything anyway.

## Frequency

- **Weekly:** Rules 1 + 5 (the lightweight ones — STATE and trim windows)
- **Monthly:** All five rules
- **Quarterly:** Plus a `planning/_archive/` batch and a `reference/_archive/` review

Set a recurring reminder. Real projects rarely housekeep when "needed" because it never feels urgent — schedule it.
