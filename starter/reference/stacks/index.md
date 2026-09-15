# Stack packs — index

> One pack per technology stack; apply one at project setup with `.claude/scripts/apply-stack.ps1 <pack>` (`template/SETUP.md` Step 2b). Shape and anchor contract: `_pack-shape.md`. The applied pack is named in `STATE.md` → Stack & Versions; `apply-stack.ps1 -Check` reports drift.

| Pack | Stack | Layout | Lanes (defaults) |
|---|---|---|---|
| `react-fsd/` | React + TypeScript, Feature-Sliced Design | `src/{app,pages,widgets,features,entities,shared}` | pnpm · Vite · Vitest · ESLint + Prettier · `tsc --noEmit` |
| `rust/` | Rust workspace (root crate + `crates/`) | `src/`, `crates/<name>/`, `tests/` | cargo build · cargo nextest (`--workspace`) · clippy `-D warnings` · `cargo fmt --check` |

Each pack has the same nine files (`README.md`, `rules.md`, `binding.md`, `gates.md`, `routing.md`, `workspaces.md`, `glossary.md`, `layout/`, deep docs). To add a stack, copy a pack folder and replace the content; keep every file name.
