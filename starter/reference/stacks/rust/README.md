# Stack pack: rust

A Rust workspace: a root crate in `src/`, member crates under `crates/`, integration tests under `tests/`. Pick it for services, tools, engines and anything where the compiler is the first reviewer.

## What the defaults assume

Stable toolchain pinned in `rust-toolchain.toml`; tests through `cargo nextest` (falls back to `cargo test` if nextest is absent); `cargo clippy --workspace --all-targets -- -D warnings`; `cargo fmt --all --check`. Each is a row in `binding.md` and `gates.md`; edit the applied rows when the project differs (a second clippy run per feature set, a generation lane), and `apply-stack.ps1 -Check` will show the divergence.

## What the pack carries

| File | What it fills |
|---|---|
| `rules.md` | code style (fmt, clippy, unsafe), architecture (workspace boundaries, module layout), naming (crates, modules, types, errors), testing (placement, lanes, `#[ignore]`) |
| `binding.md` | build / test / lint commands, the `--workspace` flag rule, ledger timeout |
| `gates.md` | unit lane, clippy, fmt gates with self-consistent EXPECTs |
| `routing.md` | "deciding where code goes" and "error handling" → `conventions.md` sections |
| `workspaces.md` | refactoring boundaries: crate seams, public API, feature flags |
| `glossary.md` | Workspace, Crate, Lane, Feature flag |
| `layout/` | `src/`, `crates/`, `tests/` with a README each, and the `src/README.md` that replaces the generic one |
| `conventions.md` | the full conventions: layout, errors, tests, lanes, unsafe, dependencies (deep doc, load by section) |

## Deep docs

- `conventions.md` — module layout, error handling, test placement and lanes, feature flags, `unsafe`, dependency policy.
