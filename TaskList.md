# TaskList.md

> The task board. Every XML task lives here from creation to completion.
>
> Status flow: `backlog` → `ready` → `in-progress` → `verifying` → `done`
> (Skip statuses freely. Don't make work for yourself.)

## How to Use

- When the user approves an XML task, append it to `## Ready` with a generated ID.
- When you start work, move it to `## In Progress`.
- After running `<verify>` and committing, move it to `## Done` with the commit SHA.
- Notable outcomes (decisions, lessons) still get appended to `wiki/log.md`.

## ID Convention

`[prefix]-[number]` — incrementing per prefix. This is the canonical list for the whole template.

**Code work** (executed under code gate):
- `feat-001`, `feat-002`, ... feature-development
- `bug-001`, `bug-002`, ... debugging
- `ref-001`, `ref-002`, ... refactoring
- `res-001`, `res-002`, ... research (wiki ingests, lints, structural changes)

**Planning artifacts** (executed under planning gate):
- `story-001`, `story-002`, ... user stories in `planning/stories/`
- `spec-001`, `spec-002`, ... specs in `planning/specs/`
- `plan-001`, `plan-002`, ... plans in `planning/plans/`

When a story and its spec describe the same feature, reuse the slug (e.g. `dashboard-export`), not the number — numbers stay per-prefix.

---

## In Progress

*Active work. Should usually have exactly 1 item. More than 2 = drift.*

- [ ] [task-id] — [one-line goal] *(started: YYYY-MM-DD)*

## Ready

*Approved XML tasks, not yet started. Pick from the top.*

- [ ] [task-id] — [one-line goal]

## Backlog

*Ideas and unblocked work that hasn't been written as an XML task yet. Promote to Ready by writing the XML task and getting user approval.*

- [ ] [rough description]

## Blocked

*Tasks that can't proceed. Note the blocker.*

- [ ] [task-id] — [one-line goal] — **blocked by:** [reason]

## Done

*Most recent at top. Trim to last ~20; older ones are findable via `wiki/log.md` + git history.*

- [x] [task-id] — [one-line goal] — `<commit-sha>` *(YYYY-MM-DD)*

---

*Last updated: [YYYY-MM-DD]*
