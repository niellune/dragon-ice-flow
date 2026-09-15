| Workspace | The set of crates built together from the root `Cargo.toml`; every lane runs with `--workspace` | monorepo, repo |
| Crate | One compilation unit: the root crate in `src/` or a member under `crates/<name>/` | package, module (wrong: a module is inside a crate) |
| Lane | One named test or lint command in the standard gates (`unit lane`, `lint`, `format`, a feature lane) | test suite, CI job |
| Feature flag | A Cargo feature that compiles an optional surface; each has its own lane | cfg, toggle |
