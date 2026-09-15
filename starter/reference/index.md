# Reference Index

> Catalog of deep docs **you** wrote about *this* project. Authoritative for project
> decisions and patterns. Loaded on demand — load only the named section, never the whole folder.

## Stack packs

- [`stacks/`](stacks/index.md) — one pack per technology stack (`react-fsd/`, `rust/`), applied at setup by `apply-stack.ps1` into the `<!-- stack:... -->` anchors. Shape and anchor contract: `stacks/_pack-shape.md`. The generic files carry no stack rules of their own.

## Architecture

*Stack-level architecture (layout, boundaries) lives in the applied pack's deep docs: `stacks/react-fsd/architecture.md`, `stacks/rust/conventions.md`. Project-level architecture (the map) starts in `STATE.md` → Architecture Snapshot and moves here as an index over section files once it outgrows a paragraph.*

## Decisions of record

- [`adr/`](adr/README.md) — one `NNNN-slug.md` per expensive or irreversible decision (status, considered options, consequences). Never edited after acceptance; superseded by a newer ADR. Format and who writes one: `adr/README.md`.

## Conventions

*Add files here as you write them (e.g. `api-conventions.md`, `data-model.md`, `ui-patterns.md`). Don't create them just to fill the table.*
