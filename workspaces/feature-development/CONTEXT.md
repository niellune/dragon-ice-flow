# Feature Development Workspace

> Loaded when building something new and the "what" is already clear.
> If the "what" is fuzzy, start in `workspaces/planning/` instead.

## Gate

Before any file write: follow `.context/task-workflow.md`. Write an XML task, surface gotchas, get user approval. No `Edit`/`Write` without it.

## Upstream

This workspace executes work that has been defined elsewhere. Common upstream sources:

- A `planning/stories/[slug].md` (approved)
- A `planning/specs/[slug].md` (approved)
- A `planning/plans/[slug].md` whose tasks have moved into `TaskList.md ## Ready`
- A direct user request for something small and clear ("add a logout button to the navbar")

If the request doesn't match one of these, ask: "Is this clear enough to write as an XML task, or should we plan it first?"

## Process

1. **PRD first** (only if no story/spec already exists). A short PRD in chat:
   - Problem (1 sentence)
   - User-facing behavior (3–5 bullets)
   - Non-goals (what we're *not* doing)
   - Acceptance criteria

   For anything more involved, switch to `workspaces/planning/` and produce a real story.

2. **Plan, then build.** Use Claude Code's plan mode. Get user approval on the plan before touching files.

3. **Smallest shippable slice.** Build the thinnest end-to-end version first. Polish later.

## Files to Load (Layer 3 references)

> Paths below are **examples**. Reference files only exist if you've written them. Load what's present; skip what isn't. Don't create reference files just to populate this table.

| When working on... | Load |
|---|---|
| Where a new file/feature belongs (FSD layer/slice/segment) | `reference/architecture/feature-sliced-design.md` |
| Frontend / UI | `reference/ui-patterns.md` |
| API endpoints | `reference/api-conventions.md` |
| Database schema | `reference/data-model.md` |
| Auth flows | `reference/auth-architecture.md` + `.context/rules.md` (security section) |

## Code Blueprint Convention

Specs come as **typed objects, not prose**.

✅ Good:
```ts
const featureSpec = {
  route: '/dashboard/exports',
  auth: 'required',
  rateLimit: '10/min',
  inputs: { format: 'csv' | 'json', dateRange: [Date, Date] },
  output: 'streaming-download'
}
```

❌ Bad:
> "Make a dashboard export feature that lets users download their data, with rate limiting and auth."

## Definition of Done

- [ ] Tests pass
- [ ] No TypeScript / lint errors
- [ ] User-facing strings match `.context/identity.md` voice
- [ ] PR description filled in per `.context/rules.md`
