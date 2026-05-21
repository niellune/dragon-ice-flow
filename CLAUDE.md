# CLAUDE.md

> Always loaded. The map of where things live in this project.

## Response Style

**Default: plain conversation.** Short sentences, no XML, minimal headers. Answer like a thoughtful colleague.

**Structure fires on intent.** When the user asks for a write action ("add a button", "fix this bug", "create the spec") or when a decision is being committed, switch to the XML task wrapper from `.context/task-workflow.md`. The gate is non-negotiable; the conversation around it can stay light.

**Depth is opt-in.** Trigger words: "tell me more", "explain", "why", "details", "show me how", "walk me through it". Without those signals, give the short answer.

**Silent workspace loading.** When the user's intent maps to a workspace (a bug → debugging, a new feature → feature-development, ingesting a doc → research), load that workspace silently. Don't announce *"I've loaded the debugging workspace"*. The workspace rules apply; the user just sees Claude being helpful.

## Project Identity

- **Name:** [YOUR PROJECT NAME]
- **One-line purpose:** [What this project does in one sentence]
- **Stage:** [planning | prototype | MVP | production]
- **Primary stack:** [e.g., Next.js + TypeScript + Postgres]

## Folder Map

**Root files (always-load):** `CLAUDE.md` · `CONTEXT.md` · `STATE.md` · `TaskList.md`

**`.context/`** — canonical project rules:
- `identity.md` · `rules.md` · `glossary.md`
- `task-workflow.md` (gate; always-load) · `task-workflow-appendix.md` (on-demand)
- `housekeeping.md` (on-demand)

**`workspaces/`** — task-type contexts: `feature-development/`, `debugging/`, `refactoring/`, `planning/`, `research/`

**`skills/`** — on-demand thinking: `brainstorm/`

**`planning/`** — artifacts: `stories/`, `specs/`, `plans/` (each has `index.md`)

**`reference/`** — deep docs YOU wrote (loaded on demand)

**`raw/`** — immutable source documents (PDFs, transcripts, articles)

**`wiki/`** — LLM-maintained knowledge: `index.md`, `log.md`, `entities/`, `concepts/`, `sources/`

**`src/`** — your actual code

## Routing Rule

Before doing anything, read `CONTEXT.md` to find which workspace applies. Then load only that workspace's `CONTEXT.md` and the specific files it points to.

**Do NOT** load the entire `reference/` folder. **Do NOT** load the whole `wiki/` — always start with `wiki/index.md` and drill in.

## Canonical Sources (the One-Place Rule)

Every fact lives in exactly one file. Other files point to it; they never copy it.

- Identity & voice → `.context/identity.md`
- Hard rules → `.context/rules.md`
- Domain terms → `.context/glossary.md`
- Project decisions, project-specific patterns → `reference/`
- Accumulated knowledge from external sources → `wiki/`

## Authority Boundary

Four content folders, in decreasing authority:

- **`.context/`** = absolute project rules. Highest authority.
- **`reference/`** = things YOU decided about THIS project. Authoritative for project decisions.
- **`planning/`** = authoritative for *in-flight* work while `status: draft | approved | in-progress`. After `done`, becomes historical record.
- **`wiki/`** = knowledge compiled from external sources. Informational only.

If a wiki page contradicts a reference file, the reference file wins. If a done planning artifact contradicts current code, the code wins. Always surface contradictions to the user.

## State vs Log Boundary

- `STATE.md` = how things ARE right now. No history. Overwrite freely.
- `TaskList.md` = work-in-flight. The kanban board.
- `wiki/log.md` = what HAPPENED, append-only, chronological.
- Never duplicate between them. A completed task moves from `TaskList.md` to `wiki/log.md`; it doesn't live in both.

## Naming Conventions

- Folders & markdown files: `kebab-case`
- Task IDs: see `TaskList.md` (canonical list)
- Wiki pages: `wiki/{entities,concepts,sources}/[slug].md`
- Planning artifacts: same slug across story/spec/plan (e.g. `dashboard-export.md` in all three).

## When in Doubt

1. Re-read `CONTEXT.md`.
2. Ask the user before assuming.
3. Never duplicate information across files.
