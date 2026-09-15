| unit lane | `cargo nextest run --workspace --status-level fail` | `(\d+) tests run: \1 passed` |
| lint | `cargo clippy --workspace --all-targets -- -D warnings; if ($LASTEXITCODE -eq 0) { 'CLIPPY_CLEAN' }` | `^CLIPPY_CLEAN$` |
| format | `cargo fmt --all --check; if ($LASTEXITCODE -eq 0) { 'FMT_CLEAN' }` | `^FMT_CLEAN$` |
