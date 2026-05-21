# Refactoring Workspace

> Loaded when improving existing code without changing behavior.

## Gate

Before any file write: follow `.context/task-workflow.md`. Refactors are *especially* prone to scope creep, so the XML task's `<files><write>` list is your guardrail — if you need to touch a file not on the list, stop and expand the task.

## Hard Rule

**Refactoring must not change behavior.** If you find yourself wanting to change behavior, that's a feature task — switch workspaces.

## Process

1. **Tests must exist first.** If the code being refactored has no tests, write characterization tests before changing anything.
2. **One refactor type per pass.** Don't rename AND extract AND restructure in the same commit.
3. **Run tests after every meaningful change.** Not at the end.

## Approved Refactor Types

- Rename for clarity
- Extract function / component
- Inline trivial wrapper
- Collapse duplication (with caution — see "Rule of Three")
- Move file to better location
- Replace prose comment with better names

## Rule of Three

Don't deduplicate until you see the same pattern three times. Two occurrences may be coincidence; three is a pattern.

## What NOT to Refactor

- ❌ Code you don't understand yet — read first.
- ❌ Code with no test coverage and no time to add it.
- ❌ Code that's about to be deleted.
- ❌ Style preferences that don't change correctness or readability.

## Files to Load

> Paths are **examples**; reference files only exist if you've written them. Load what's present.

| Refactor target | Load |
|---|---|
| API surface | `reference/api-conventions.md` |
| Data layer | `reference/data-model.md` |
| Component library | `reference/ui-patterns.md` |
