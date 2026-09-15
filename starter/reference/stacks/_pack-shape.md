# Stack packs — the pack shape and the anchor contract

> A stack pack is everything the template needs to know about one technology stack, kept out of the generic files until a project picks it. Packs live in `reference/stacks/<pack>/`; `index.md` lists them. Applying one is mechanical: `.claude/scripts/apply-stack.ps1 <pack>` fills the anchors below and copies the layout. Nothing stack-specific is written into the generic files by hand.

## Pack layout

Every pack has the same files, so the script never needs per-pack logic. A file may be empty when the stack has nothing to say; it may not be missing.

| File | Kind | Goes to | Content |
|---|---|---|---|
| `README.md` | doc | stays in the pack | what the stack is, when to pick it, what the defaults assume, deep-doc links |
| `rules.md` | prose sections | `.context/rules.md` | `## code-style`, `## architecture`, `## naming`, `## testing` blocks; each block's bullets go to the anchor of the same name |
| `binding.md` | table rows | `.context/pipeline/00-binding.md` | rows keyed `Build command`, `Test command`, `Lint / typecheck command`, `Workspace-flag lint rule`, `Ledger timeout` |
| `gates.md` | table rows | `.context/gates-ledger.md` standard gates | rows keyed `unit lane`, `lint`, `format`, plus any extra lane the stack has |
| `routing.md` | table rows | `CONTEXT.md` routing table | rows such as "deciding where code goes" pointing at the pack's docs |
| `workspaces.md` | prose sections | `workspaces/refactoring/CONTEXT.md` | `## boundaries` block: what a refactor must preserve |
| `glossary.md` | table rows | `.context/glossary.md` | stack vocabulary rows in the glossary's three-column shape |
| `layout/` | files | `src/` | the scaffold: folders with a README each; the top README replaces `src/README.md` |
| deep docs (`architecture.md`, `naming.md`, ...) | doc | stay in the pack | the full spec the rules point at; loaded on demand by section |

## Anchors

An anchor is an HTML comment on its own line, `<!-- stack:<section> -->`, placed once in each anchored generic file. The script inserts the pack's content **immediately before** the anchor and rewrites the anchor as `<!-- stack:<section> applied:<pack> -->`. A prose section also gets a `<!-- stack:<section> begin:<pack> -->` line before its content, so it can be removed or replaced; table rows carry no markers, since a comment line inside a table breaks it, and are identified by their first cell instead.

| Anchor | File | Kind |
|---|---|---|
| `stack:code-style`, `stack:architecture`, `stack:naming`, `stack:testing` | `.context/rules.md` | prose |
| `stack:glossary` | `.context/glossary.md` | table rows |
| `stack:routing` | `CONTEXT.md` | table rows |
| `stack:boundaries` | `workspaces/refactoring/CONTEXT.md` | prose |
| `stack:binding` | `.context/pipeline/00-binding.md` | table rows; a row whose key already exists is replaced in place |
| `stack:gates` | `.context/gates-ledger.md` | table rows; same replace-by-key rule |
| `Stack pack:` line | `STATE.md` → Stack & Versions | keyed line, replaced with `Stack pack: <pack> (applied YYYY-MM-DD; reference/stacks/<pack>/)` |

Rules the script enforces:

- Every anchor exists exactly once in its file, or the script stops before writing anything.
- An anchor already applied with the same pack is skipped (idempotent). Applied with a different pack: refused unless `-Replace`, which removes the previous pack's content (prose: between `begin` and the anchor; rows: those whose keys the previous pack supplied) before inserting.
- `-Check` compares the applied content against the pack and reports each section as `same`, `drifted` or `missing`; it writes nothing. Housekeeping step 1 runs it.
- The script writes one `wiki/log.md` entry per apply (`decision | Stack pack <pack> applied`) and never touches any other file.

## Writing a new pack

Copy an existing pack folder, keep every file name, replace the content. Commands in `binding.md` and `gates.md` are the stack's usual defaults; an adopter edits them in the applied files, not in the pack, and `-Check` will then report the rows as drifted, which is the intended signal that the project has diverged from the pack's defaults on purpose. Record such a divergence in `STATE.md` → Stack & Versions.
