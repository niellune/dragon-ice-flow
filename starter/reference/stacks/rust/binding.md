| Build command | `cargo build --workspace` |
| Test command | `cargo nextest run --workspace` (or `cargo test --workspace` where nextest is absent) |
| Lint / typecheck command | `cargo clippy --workspace --all-targets -- -D warnings && cargo fmt --all --check` |
| Workspace-flag lint rule | `-WorkspaceRule 'cargo (nextest run|test|clippy|build)=--workspace|-p '` |
| Ledger timeout | `-TimeoutSeconds 1800` (a cold workspace build plus the test lane) |
