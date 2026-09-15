## code-style
- `cargo fmt` output is the style; no hand formatting, no `rustfmt.toml` beyond edition and width.
- Clippy at `-D warnings` on every crate and target; an `#[allow]` carries a one-line reason on the same line.
- `unsafe` only behind a safe API with a `// SAFETY:` comment stating the invariant; never in a binary crate.
- Dependencies: one crate per job, pinned with a caret range in `Cargo.toml`, `Cargo.lock` committed; a new dependency is a spec decision, not a task-level choice.

## architecture
- A Cargo **workspace**: the root crate in `src/`, member crates in `crates/<name>/`, integration tests in `tests/`. A crate is split out when a second crate needs it or its build time dominates, never for tidiness. Crates depend downward only (`crates/` never depend on the root crate). Conventions and layout guide: `reference/stacks/rust/conventions.md`.
- Feature flags gate optional surfaces (`--features vr`); a default-off feature is compiled by its own lane or it rots, so every feature has a lane row in the standard gates.

## naming
- Crates and modules `snake_case` (`mp_world_core`, `src/render/mesh.rs`); types and traits `PascalCase`; functions, fields and locals `snake_case`; constants and statics `SCREAMING_SNAKE`; lifetimes short and lowercase. Error types end in `Error` (`ParseError`), builders in `Builder`; conversion functions follow `as_` / `to_` / `into_` by cost. Full rules: `reference/stacks/rust/conventions.md` §Naming.

## testing
- Unit tests beside the code in `#[cfg(test)] mod tests`; integration tests in `tests/<surface>.rs`; fixtures byte-pinned under `fixtures/` with `-text` in `.gitattributes`.
- The verify lane is `cargo nextest run --workspace`; the `--workspace` flag is mandatory (bare `cargo test` selects the root package only and false-greens past member crates).
- `#[ignore]` carries a reason and a tracked issue; a test that ignores itself for more than one plan is deleted or fixed.
