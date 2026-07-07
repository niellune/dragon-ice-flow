# Task Workflow — Appendix

> Loaded on demand when you need the deeper detail. The lean core is in `task-workflow.md`.

## After Each Task — Full Checklist

- Run the `<verify>` command (or closest equivalent).
- Commit with a focused message per `rules.md` Git conventions. One task = one commit.
- Move the task from `## In Progress` to `## Done` in `TaskList.md` with the commit SHA and date.
- If the task changed the current state of the project (architecture, stack, focus, environments), update the relevant section in `STATE.md`. **Overwrite**, don't append — `STATE.md` is the present, not the past.
- If the task produced a notable decision (architecture, library, pattern), append a new entry at the top of `wiki/log.md`. Format: `## [YYYY-MM-DD] <kind> | <summary>` — the canonical list of kinds lives in `wiki/log.md`'s header; don't restate it elsewhere.
- If the task created a new wiki page or reference doc, add a one-line entry to the appropriate index.

## State vs Log — Which File?

| Information | Goes in |
|---|---|
| "We picked Postgres over MySQL" (the event) | `wiki/log.md` as a `decision` entry |
| "Database: Postgres 16" (the current fact) | `STATE.md` Stack & Versions |
| "Task feat-007 shipped on 2026-05-13" | `TaskList.md` Done + `wiki/log.md` |
| "Currently working on auth refactor" | `STATE.md` Current Focus |
| "Bug bug-003 in payments still open" | `STATE.md` Known Issues (and/or `TaskList.md` Ready) |

## Red Flags — Stop and Write the Task

| Thought | Reality |
|---|---|
| "This is a tiny tweak, skip the task" | Still needs an XML task. Tiny tasks are fine; no task is not. |
| "Let me just open a few files first" | Reads are fine. `Edit`/`Write` without approval is not. |
| "I'll combine tasks 2 and 3 since they're close" | Don't. Commit each separately — reverting is cheaper. |
| "While I'm in this file, I'll also fix X" | No. Separate task, separate commit, or skip. |
| "I'll move to task 4 even though 3's test is red" | No. Fix 3 first. |
| "The user said 'do it', I'll skip surfacing gotchas" | Gotchas go in `<action>` or as flagged notes above the task, not silently into the implementation. |
| "I'll just assume X works the way I expect" | Write it in `<assumptions>`. If you can't verify cheaply, ask. |

## When This Workflow Does NOT Apply

- Pure research / "how does X work in this codebase" → skip, just answer.
- The user explicitly says "no XML needed for this" or "just do it" after seeing a one-line plan — honor that.
- Meta questions about project docs, commits, or git state — answer directly.
- The `research` workspace's wiki operations (ingest, query, lint) — those have their own discipline; XML tasks would add noise. But if a research operation requires editing project code (e.g. moving a wiki insight into `reference/`), the gate applies for that edit.

## Relation to Other Files

- `rules.md` carries the absolute "never" list. This file implements the workflow.
- Every workspace's `CONTEXT.md` references the core `task-workflow.md` in its gate section.
