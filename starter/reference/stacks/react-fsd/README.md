# Stack pack: react-fsd

React + TypeScript, laid out by Feature-Sliced Design. Pick it for a browser frontend with more than a handful of screens; below that FSD's layers are ceremony.

## What the defaults assume

Package manager pnpm, bundler Vite, tests Vitest, lint ESLint with Prettier for formatting, typecheck `tsc --noEmit`. Each is a row in `binding.md` and `gates.md`; edit the applied rows in your project when the tooling differs, and `apply-stack.ps1 -Check` will show the divergence, which is fine and expected.

## What the pack carries

| File | What it fills |
|---|---|
| `rules.md` | code style (TypeScript strict, imports), architecture (the FSD boundaries), naming (React and FSD names), testing (Vitest conventions) |
| `binding.md` | build / test / lint / typecheck commands, workspace-flag rule, ledger timeout |
| `gates.md` | unit lane, lint, format and typecheck gates with self-consistent EXPECTs |
| `routing.md` | "deciding where code goes" → `architecture.md`; "naming a component / hook / slice" → `naming.md` |
| `workspaces.md` | refactoring boundaries: import direction, barrels, sibling slices |
| `glossary.md` | Layer, Slice, Segment, Barrel |
| `layout/` | the six layer folders with a README each, and the `src/README.md` that replaces the generic one |
| `architecture.md` | the full FSD spec and decision guide (deep doc, load by section) |
| `naming.md` | React and FSD naming rules with examples (deep doc) |

## Deep docs

- `architecture.md` — layers, slices, segments, import rules, the decision guide for where a file goes.
- `naming.md` — components, hooks, files, folders, props, events, tests.
