# CONTEXT.md — Routing Table

> The load balancer. Directs traffic; does not do work.

## How to Use This File

Match the user's intent to a row. Load only the files listed in that row, silently. Do not announce the load.

If no row matches, ask the user which workspace applies. Do not guess.

## Workspaces vs Skills

Workspaces frame a whole task. Skills are invoked briefly within one, then you return. A skill typically produces no files.

## Routing Table

| If the user's intent is... | Load these files (silently) |
|---|---|
| Building a new feature (and the "what" is clear) | `workspaces/feature-development/CONTEXT.md` |
| Defining what to build — user stories, specs, task plans | `workspaces/planning/CONTEXT.md` |
| Exploring possibilities before committing | `skills/brainstorm/SKILL.md` |
| Fixing a bug | `workspaces/debugging/CONTEXT.md` |
| Refactoring existing code | `workspaces/refactoring/CONTEXT.md` |
| Researching a topic / ingesting a source / querying the wiki | `workspaces/research/CONTEXT.md` |
| Anything touching auth, payments, or PII | Above row + `.context/rules.md` (sections: security, compliance) |
| Writing user-facing copy | `.context/identity.md` (sections: voice, tone) |
| Naming things / API design | `.context/glossary.md` |
| Deciding where code goes — which layer/slice/segment a file belongs in | `reference/architecture/feature-sliced-design.md` |

## Wiki Integration Rules

- **Reading the wiki:** Always start at `wiki/index.md`. Drill into specific entity/concept pages by name. Never load the whole `wiki/` folder.
- **Writing to the wiki:** Only the `research` workspace writes to `wiki/`. Other workspaces may *read* it, but never modify.
- **Ingesting sources:** New PDFs/articles/transcripts go into `raw/` (immutable). The research workspace then compiles them into `wiki/`.

## Always-Load Rules

Loaded for every task regardless of workspace:
- `STATE.md` → current situation
- `.context/rules.md` → the `## Non-Negotiables` section only
- `.context/task-workflow.md` → **required before any file write.** Its "Which Gate Covers What" table is the canonical map of which gate (or exemption) applies to each surface.

`TaskList.md` is loaded when starting, completing, or planning work. Not always-load.

## Selective Loading

When a workspace points to a reference file, load **only the named section**, not the whole file. Locate it by heading — headings survive edits; line numbers don't.
- ✅ `reference/api-conventions.md` → only the `## Auth` section
- ❌ `reference/api-conventions.md` (the whole 400-line file)
