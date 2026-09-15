# Rust conventions

> Deep doc for the `rust` pack. The one-paragraph summaries live in the applied sections of `.context/rules.md`; this file is the full rule set. Load by section.

## Layout

- Root crate in `src/`: `main.rs` for a binary, `lib.rs` for a library, or both with the binary a thin shell over the library.
- Modules: `src/<name>.rs` for a leaf, `src/<name>/mod.rs` plus children for a tree. One public concern per module; `pub(crate)` by default, `pub` only at a crate's intended surface.
- Member crates in `crates/<name>/` with their own `Cargo.toml`, `src/lib.rs`, and tests. Split out when a second crate needs the code or when the crate's build time dominates the root's; never for tidiness alone.
- Dependencies point downward: `crates/` never depend on the root crate. Shared vocabulary types live in the lowest crate that needs them (`crates/<project>_shared/` is the usual name).
- Integration tests in `tests/<surface>.rs` at the crate they exercise; byte-pinned fixtures under `fixtures/` with `-text` in `.gitattributes` so no platform rewrites them.

## Errors

- Library crates define an error enum per public surface with `thiserror`; variants carry the data a caller needs to act, never a formatted string alone.
- Binaries use `anyhow::Result` at the top level and add context at each boundary (`.with_context(|| ...)`).
- `panic!`, `unwrap` and `expect` only where a broken invariant is a bug: tests, `const` setup, and after an explicit check on the previous line. `expect` messages state the invariant, not the failure.
- `Result` in, `Result` out: a function that can fail returns `Result`; a function that cannot fail does not.

## Naming

| Thing | Rule | Example |
|---|---|---|
| Crate | `snake_case`, project prefix for members | `mp_world_core` |
| Module / file | `snake_case` | `src/render/mesh.rs` |
| Type / trait / enum | `PascalCase` | `ChunkMesher`, `WorldSource` |
| Function / method / local | `snake_case` | `build_mesh` |
| Constant / static | `SCREAMING_SNAKE` | `WORLD_SEED` |
| Error type | ends in `Error` | `ParseError` |
| Builder | ends in `Builder` | `MeshBuilder` |
| Conversion | `as_` (free), `to_` (costly, borrows), `into_` (consumes) | `to_string`, `into_iter` |
| Feature flag | `kebab-case` in `Cargo.toml` | `vr` |
| Lifetime | short, lowercase | `'a`, `'src` |

## Tests and lanes

- Unit tests beside the code in `#[cfg(test)] mod tests`; name the behaviour (`fn rejects_empty_input()`), not the function.
- The verify lane is `cargo nextest run --workspace`; `--workspace` is mandatory because bare `cargo test` selects the root package only and reports green past every member crate. Each feature flag has its own lane (`--features <flag>`), or its code rots uncompiled.
- `cargo clippy --workspace --all-targets -- -D warnings` and `cargo fmt --all --check` are gates, not suggestions; both run before every commit.
- A test that asserts a count pins self-consistency (`(\d+) tests run: \1 passed`), never a literal number.
- `#[ignore]` carries a reason and a tracked issue in the attribute string; an ignored test older than one plan is fixed or deleted.

## Unsafe

- `unsafe` only inside a module that exposes a safe API, with a `// SAFETY:` comment on every block stating the invariant that makes it sound.
- Never in a binary crate; never to silence the borrow checker.
- A change near `unsafe` re-states the invariant in the round file and the verifier checks it.

## Dependencies

- One crate per job; prefer the crate the ecosystem has settled on over a newer one.
- Caret ranges in `Cargo.toml`, `Cargo.lock` committed for binaries and workspaces.
- Adding a dependency is a spec decision (it is a shipped-footprint change); the spec names what it defends and why.
- `cargo deny` or `cargo audit` in CI when the project has one; until then, the lint gate is the floor.
