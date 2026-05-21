# Debugging Workspace

> Loaded when fixing something broken.

## Gate

Before any file write: follow `.context/task-workflow.md`. Even a one-line fix needs a written XML task and user approval. Diagnostic reads/greps are fine without one.

## Process

1. **Reproduce first.** Don't theorize about the bug until you can reproduce it. If you can't reproduce, ask for exact steps.

2. **Narrow before fixing.** Find the smallest input that triggers the bug. Find the smallest file region responsible.

3. **One change at a time.** Fix the bug. Verify. Then refactor or improve in a separate change.

4. **Regression test.** Every bug fix needs a test that would have caught it.

## Diagnostic Order

1. Read the error message literally. Don't pattern-match — read it.
2. Check recent git history (`git log --oneline -20`).
3. Check the file mentioned in the stack trace *before* anything else.
4. Search for the actual error string in the codebase.

## What NOT to Do

- ❌ Add `try/catch` to make errors disappear.
- ❌ Comment out failing tests.
- ❌ Add `@ts-ignore` or `// eslint-disable`.
- ❌ Guess. If unsure, say "I need to check X" and check it.

## Files to Load

> Paths are **examples**; reference files only exist if you've written them. Load what's present.

| Bug type | Load |
|---|---|
| Type errors | `reference/types.md` (only the relevant section) |
| API / network | `reference/api-conventions.md` |
| Database | `reference/data-model.md` |
| Build / tooling | `reference/build-pipeline.md` |
