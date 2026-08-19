# Research Workspace

> Loaded when ingesting a source, querying the wiki, or maintaining accumulated knowledge.
> This workspace is the **only** one with write access to `wiki/`.

## Gates

Gate scopes are defined once in `.context/task-workflow.md` → "Which Gate Covers What". For this workspace:

- **Multi-page wiki writes** (ingest, lint fixes) use the `<ingest>` gate defined in this file.
- **Single-page wiki writes** (filing a query answer back) use a one-line confirmation — see Operation: Query.
- **Code writes** (e.g. moving a wiki insight into `reference/`, updating a script) follow the standard XML task gate in `.context/task-workflow.md`.
- **Reads** (querying the wiki, exploring `raw/`) are free. Appending to `wiki/log.md` is exempt bookkeeping.

## What This Workspace Is For

Three operations, based on Karpathy's LLM Wiki pattern:

1. **Ingest** — adding new sources to `raw/` and compiling them into `wiki/`
2. **Query** — answering questions by reading the wiki (not raw sources)
3. **Lint** — health-checking the wiki for contradictions, orphans, stale claims

## The Three Layers (Karpathy)

- **`raw/`** — immutable source documents. PDFs, articles, transcripts, notes. **Never modify these.** Read-only.
- **`wiki/`** — LLM-maintained markdown pages. The compiled, compounding artifact.
- **Schema** — this file tells you HOW to maintain the wiki (process, conventions, anti-patterns below).

## Operation: Ingest

Ingest is the biggest research operation — it touches 5–15 wiki pages per source and is expensive to undo. So it has its own gate, parallel to the code and planning gates.

**The ingest gate:** before any wiki page is written, declare scope in this wrapper and get user approval. Reading the source is fine without approval; *writing* is gated.

```xml
<ingest>
  <source>raw/[filename]</source>
  <new-pages>
    Wiki pages this will create. Group by type:
    - sources/: [page-slug]
    - entities/: [page-slug-1], [page-slug-2]
    - concepts/: [page-slug]
  </new-pages>
  <updated-pages>
    Existing wiki pages this will modify and what changes. If empty, "none".
  </updated-pages>
  <contradictions>
    Anything in the source that conflicts with existing wiki claims.
    Format: "wiki/[path] says X; source says Y." If empty, "none".
  </contradictions>
  <questions>
    Open questions to resolve with the user before writing. If empty, "none".
  </questions>
</ingest>
```

The wrapper is the user's surface to:
- Reduce scope ("skip the entity pages, just create the source page")
- Resolve contradictions before they propagate
- Catch wrong slugs before they're committed
- Confirm before a multi-file write

### Sequence

1. **Read the source.** Discuss key takeaways with the user.
2. **Write the `<ingest>` wrapper.** Surface contradictions and open questions explicitly.
3. **Wait for user approval.** Same standard as other gates: "approve" / "yes" / "do it" counts; silence does not.
4. **On approval, write the pages** in this order: source → entities → concepts → cross-links → index → log.
   - **Source pages** (`wiki/sources/[slug].md`): title, author, date, source URL/path; 5–10 bullet takeaways; notable quotes (under 15 words each, paraphrase the rest); open questions raised.
   - **Entity pages** (`wiki/entities/[slug].md`): people, organizations, products, places mentioned.
   - **Concept pages** (`wiki/concepts/[slug].md`): ideas, frameworks, patterns.
5. **Use `[[wiki-link]]` syntax** for cross-references. Every page should have inbound and outbound links.
6. **Flag contradictions in-page.** If the new source disagrees with an existing wiki page, add a "Disputed" section to that page rather than overwriting.
7. **Update `wiki/index.md`.** Add new pages with one-line summaries.
8. **Append to `wiki/log.md`.** Format: `## [YYYY-MM-DD] ingest | [source title]` followed by a short note about what changed.

A single ingest typically touches 5–15 wiki pages. That's normal — but the wrapper ensures the user saw the scope before the writes happened.

## Operation: Query

When the user asks a question that requires accumulated knowledge:

1. **Start at `wiki/index.md`.** Find candidate pages.
2. **Read only relevant pages.** Follow `[[wiki-links]]` to drill in. Never load the whole wiki.
3. **Synthesize with citations.** Every claim should reference a wiki page or a `raw/` source.
4. **File good answers back into the wiki.** If the answer is a new comparison, analysis, or connection — create or update a page so it compounds. This is a wiki write: confirm in one line first ("Filing this back as `wiki/concepts/[slug].md` — ok?") and wait for a yes. If the filing would touch 3+ pages, use the full `<ingest>` gate instead.
5. **Log the query.** Append to `wiki/log.md`: `## [YYYY-MM-DD] query | [question]`.

## Operation: Lint

Periodically (when the user asks, or after several ingests):

1. **Contradictions.** Search for pages that contradict each other or stale claims newer sources have superseded.
2. **Orphans.** Pages with no inbound links. Decide: delete, merge, or add links.
3. **Missing pages.** Concepts referenced in the text but lacking their own page.
4. **Index drift.** `wiki/index.md` out of sync with actual pages.
5. **Report findings** to the user before making changes. Lint is a *proposal*, not an autonomous rewrite.

## Wiki Conventions

- **Page size:** Aim for 200–800 words per page. If a page exceeds 1500 words, split it.
- **Wikilinks:** Use `[[Page Name]]`. Match the filename without `.md`.
- **Frontmatter** (optional but useful):
  ```yaml
  ---
  type: entity | concept | source
  created: 2026-05-13
  sources: [source-slug-1, source-slug-2]
  status: stable | draft | disputed
  ---
  ```
- **Voice:** Wiki pages are descriptive, not first-person. Sources speak; the wiki summarizes.
- **Quoting:** Paraphrase by default. Direct quotes only when wording itself matters, and under 15 words.

## Boundary with the Project

- The wiki is **informational**, not authoritative for the project's decisions.
- If a wiki page contains a useful pattern for THIS project's code, distill it into `reference/` and link both ways.
- Do not let the wiki replace clear decision-making — it's a memory aid, not a substitute for judgment.

## Anti-Patterns

- ❌ Modifying `raw/` files (they are immutable)
- ❌ Querying `raw/` directly when a wiki page already covers it
- ❌ Letting `wiki/index.md` grow stale
- ❌ Wiki pages that read like marketing copy or summaries-of-summaries
- ❌ Using the wiki as a TODO list (logs and tasks belong elsewhere)
