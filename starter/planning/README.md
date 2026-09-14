# planning/

Artifacts produced by the **planning workspace**, plus the pipeline's on-disk records.

- **`stories/`** — what users want and why (user stories, lightweight or full)
- **`specs/`** — technical shape of what you're building (decisions, data model, API surface)
- **`plans/`** — sequenced XML task plans, approved before execution
- **`backlog.md`** — the rows behind the board's Backlog counts
- **`rounds/<feature-id>/`** — round files written by each pipeline role (assumptions, implement, verify-a, verify-b), committed by their producer
- **`done-plans.md`** + **`done-plans/`** — index over one dossier per closed plan (template: `done-plans/_dossier-template.md`)
- **`_archive/YYYY-Qn/`** — closed stories/specs/plans, moved in batches

## Lifecycle

```
brainstorm (optional, ephemeral)
    ↓
story (planning/stories/)
    ↓
spec (planning/specs/) ← optional, only when technical design warrants it
    ↓
plan (planning/plans/) ← contains the XML tasks
    ↓
TaskList.md (## Ready) ← only after user approves the plan
    ↓
TaskList.md (## In Progress) ← execution under feature-development gate; round files in planning/rounds/<id>/
    ↓
TaskList.md (## Done) + wiki/log.md entry + dossier in planning/done-plans/ (at plan close)
```

## Filename Convention

`kebab-case-slug.md` — the same slug across story, spec, plan, and dossier when they refer to the same effort.

Example: a feature for exporting dashboards might produce
- `planning/stories/dashboard-export.md`
- `planning/specs/dashboard-export.md`
- `planning/plans/dashboard-export.md`
- `planning/done-plans/dashboard-export.md` (after close)

## Status Conventions

Every artifact has a `## Status` line near the bottom. Values:

- `draft` — being written, not yet approved
- `approved` — user has approved; downstream artifacts can be created
- `in-progress` — corresponding tasks are running
- `done` — all related tasks complete
- `deprecated` — superseded or abandoned (do not delete; rename status only)

## Indexes

Each subfolder has an `index.md` from day one:
- `stories/index.md`
- `specs/index.md`
- `plans/index.md`
- `done-plans.md` (index over `done-plans/`)

Update the relevant index whenever you create a new artifact or change its status. Format: one line per artifact (`[slug] — short summary — status`). Group by status (Active / Done / Deprecated) inside the index.

This matches `wiki/index.md`'s pattern — a single place to scan what exists without loading all the artifacts.
