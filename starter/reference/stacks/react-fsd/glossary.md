| Layer | FSD top-level role under `src/`: `app`, `pages`, `widgets`, `features`, `entities`, `shared` | tier, level |
| Slice | A business domain inside a layer (e.g. `entities/user`) | module, domain, folder |
| Segment | Technical purpose inside a slice: `ui`, `model`, `api`, `lib`, `config` | subfolder |
| Barrel | A slice's `index.ts`, the only file other slices may import from | public API, entry point |
