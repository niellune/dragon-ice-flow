# TaskList.md

> The task board. Every XML task lives here from creation to completion.
>
> Status flow: `backlog` → `ready` → `in-progress` → `done`
> (Verification happens inside `in-progress`: run the task's gate ledger before moving to Done. Skip statuses freely — don't make work for yourself.)

## How to Use

- When the user approves an XML task, append it to `## Ready` with a generated ID.
- When you start work, move it to `## In Progress`.
- On close, write the Done row exactly per the Closeout Rule in `.context/task-workflow.md` (one line; detail goes to the dossier or `wiki/log.md`).
- Rows are budgeted mechanically (`.claude/hooks/budget-check.ps1`). If a write is refused, shorten the row, never the rule.

## ID Convention

`[prefix]-[number]` — incrementing per prefix. This is the canonical list for the whole template.

**Code work** (executed under code gate):
- `feat-001`, `feat-002`, ... feature-development
- `bug-001`, `bug-002`, ... debugging
- `ref-001`, `ref-002`, ... refactoring

**Research work** (executed under the ingest gate — no XML task; the ID just tracks the operation on this board):
- `res-001`, `res-002`, ... wiki ingests, lints, wiki structural changes. If a research operation also edits code (e.g. distilling into `reference/`), that edit gets its own code-gate task.

**Planning artifacts** (executed under planning gate):
- `story-001`, `story-002`, ... user stories in `planning/stories/`
- `spec-001`, `spec-002`, ... specs in `planning/specs/`
- `plan-001`, `plan-002`, ... plans in `planning/plans/`

When a story and its spec describe the same feature, reuse the slug (e.g. `dashboard-export`), not the number — numbers stay per-prefix.

---

## In Progress

*Active work. Should usually have exactly 1 item. More than 2 = drift.*

- [ ] [task-id] — [one-line goal] — [risk] — spec `planning/specs/[slug].md`, ledger `gates/[task-id].md`

## Ready

*Approved XML tasks, not yet started. Pick from the top. One plan header per plan, then its rows.*

**plan-[slug] — 0/[total]** (approved [YYYY-MM-DD]). Plan `planning/plans/[slug].md` · spec `planning/specs/[slug].md` · dossier `planning/done-plans/[slug].md`. Next: [task-id].

- [ ] [task-id] — [one-line goal] — [low|high] — [depends: id or none] — [pointer]

## Backlog

*Counts only. Rows live in `planning/backlog.md`.*

feat 0 · bug 0 · ref 0 · res 0 · planning 0

## Blocked

*Tasks that can't proceed. Note the blocker.*

- [ ] [task-id] — [one-line goal] — **blocked by:** [reason]

## Done

*Most recent at top. Last 20; older rows are in `planning/done-plans/` or `wiki/log/`.*

- [x] [task-id] — [title] — DONE [YYYY-MM-DD] — [commit] — [gate-owed? yes/no] — [pointer]

---

*Last updated: [YYYY-MM-DD]*
