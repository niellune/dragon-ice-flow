# Planning Workspace

> Loaded when defining *what* to build, before deciding *how*.
> Produces three artifact types: user stories, specs, and plans.

## Gate

Planning has its own gate, parallel to the code-write gate in `.context/task-workflow.md`:

- Gate scopes are defined once in `.context/task-workflow.md` → "Which Gate Covers What". In short: the code gate covers `src/`, `reference/`, `.context/`; the wiki has its own `<ingest>` gate.
- **The planning gate** (this section) protects files in `planning/` — stories, specs, plans.
- **Both apply** if a single action touches both surfaces (e.g. moving a wiki insight into `reference/` *and* updating a spec).

Specifically, no story, spec, or plan is written before the user approves a `<planning-task>` describing what artifact you're producing and why. A plan does not become tasks in `TaskList.md` until the user approves the plan as a whole.

Reads, brainstorming, and "let me sketch this in chat" are fine. Committing artifacts to `planning/` requires approval.

## When to Use This Workspace

- The user is describing something to build but the scope isn't clear yet
- A feature involves multiple users, edge cases, or trade-offs that warrant writing down
- The work crosses 3+ files and needs sequencing
- You're about to enter `feature-development` but the "what" is fuzzy

## When NOT to Use This Workspace

- Bug fixes (use `debugging`)
- Tweaks under ~30 min of work (just write the XML task in `feature-development`)
- Research into how something works (use `research`)
- Exploring possibilities with no commitment yet (use the `brainstorm` skill instead)

## Three Artifact Types

### 1. User Story → `planning/stories/[slug].md`

Captures *what a user wants and why*, before deciding how to build it.

**Decide format based on scope:**

| Story shape | Use this format |
|---|---|
| Single screen, clear user, obvious value | **Lightweight** (1 line + acceptance) |
| Multiple personas, edge cases, or business rules | **Full** (persona, narrative, acceptance criteria, out-of-scope) |
| Cross-cutting (touches auth, payments, notifications, etc.) | **Full** + link to spec |

**Lightweight template:**
```markdown
# Story: [slug]

**As a** [user role]
**I want** [capability]
**So that** [outcome]

## Acceptance
- [ ] Observable behavior 1
- [ ] Observable behavior 2

## Status
draft | approved | in-progress | done
```

**Full template:** see `planning/stories/_template-full.md` (ships with the template).

### 2. Spec → `planning/specs/[slug].md`

Captures the *technical shape* of what you're building. Decisions, constraints, interfaces, data model.

Use a spec when:
- A user story has been approved and "what to build" is clear, but "how it fits the system" needs design.
- The change touches data model, public API, or a security boundary.
- More than one reasonable implementation exists and you need to commit to one.

**Spec template:**
```markdown
# Spec: [slug]

## Purpose
One paragraph. What this enables. Link to the story.

## Non-Goals
What this explicitly does NOT do.

## Decisions
- **[Decision name]:** [Chosen option]. Rationale: [why this over alternatives].

## Data Model Changes
[New tables, columns, indexes. Or "none".]

## API Surface
[New endpoints, modified signatures. Or "none".]

## Open Questions
[Things still undecided. Block plan creation until resolved.]

## Status
draft | approved | implemented | deprecated
```

### 3. Plan → `planning/plans/[slug].md`

Decomposes a spec (or directly a story, for simpler work) into the actual XML tasks that will be created in `TaskList.md`.

A plan is *the user's approval surface* for a sequence of changes. Once approved, its tasks move to `TaskList.md` and execution begins under `feature-development`'s gate.

**Plan template:**
```markdown
# Plan: [slug]

## Goal
One sentence. What "done" looks like.

## Source
- Story: `planning/stories/[slug].md`
- Spec: `planning/specs/[slug].md` (if any)

## Task Sequence

```xml
<plan>
  <phase>[short name]</phase>
  <task id="feat-NNN">
    <goal>...</goal>
    <files><read>...</read><write>...</write></files>
    <verify>...</verify>
  </task>
  <task id="feat-NNN+1" depends="feat-NNN">...</task>
</plan>
```

## Risks
- [risk and mitigation]

## Out of Scope
- [explicit exclusions]

## Status
draft | approved | in-progress | done
```

## The Planning Task Format

When working in this workspace, the gate task looks slightly different from the code-write XML task — you're not editing application code, you're producing planning artifacts:

```xml
<planning-task>
  <kind>story | spec | plan</kind>
  <slug>kebab-case-name</slug>
  <purpose>One sentence — why this artifact exists.</purpose>
  <inputs>
    Sources you'll draw from: user request, brainstorm notes, existing stories/specs, wiki pages.
  </inputs>
  <format>lightweight | full | spec | plan</format>
  <questions>
    Open questions to resolve with the user *before* writing. If empty, write "none".
  </questions>
  <done>What "this artifact is complete" looks like.</done>
</planning-task>
```

## Process

1. **Gather context.** Read what the user said. Check `planning/stories/index.md`, `planning/specs/index.md`, `planning/plans/index.md` first — don't duplicate existing artifacts. Check `wiki/` if domain knowledge applies.
2. **If exploration is needed first**, switch to the `brainstorm` skill. Come back with notes.
3. **Write the `<planning-task>`.** Surface the format choice (lightweight vs full story; story-only vs story+spec). Surface open questions.
4. **Get approval.** User confirms format and answers questions, or asks for changes.
5. **Write the artifact.** Save to the right folder under `planning/`.
6. **Update the relevant index** (`planning/stories/index.md`, `specs/index.md`, or `plans/index.md`) with a one-line entry.
7. **Update `STATE.md` Open Decisions** if the artifact unblocks one.
8. **If you produced a plan**, ask the user to approve it as a whole before moving tasks into `TaskList.md`.

## After Planning

- Approved stories with no spec needed → write a `<task>` in `feature-development` referencing the story
- Approved specs → typically produce a plan next
- Approved plans → their tasks move into `TaskList.md` under `## Ready`; execution happens in `feature-development`
- Log the planning decision in `wiki/log.md` as a `decision` entry

## Files to Load

| Working on... | Load |
|---|---|
| Any planning artifact | This file + `STATE.md` + `.context/identity.md` (voice/positioning) |
| User-facing story | + `.context/glossary.md` (term hygiene) |
| Spec | + relevant `reference/` files for the affected subsystem |
| Plan | + the source story and spec |

## Anti-Patterns

- ❌ Writing a full spec for a one-screen feature
- ❌ Writing a plan with vague tasks ("implement the backend")
- ❌ Letting `planning/` accumulate orphan drafts — clean as you go, or mark `deprecated`
- ❌ Copying story content into the spec, or spec content into the plan (link instead — one-place rule)
- ❌ Moving plan tasks into `TaskList.md` before the user approves the plan
