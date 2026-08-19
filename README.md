# Ice Flow Template for Claude Code

A general-purpose template combining three complementary patterns:

- **Folder-based routing** (ICM, Van Clief) — *how* the AI does work
- **Markdown knowledge base** (LLM Wiki, Karpathy) — *what* the AI knows
- **XML task gates** (DesignFlow) — *what* gets approved before any change

## Core Idea

Most templates make you learn commands. This one doesn't.

**Default: plain conversation.** You ask questions. Claude answers like a thoughtful colleague — short sentences, no XML, minimal ceremony. The workspace that fits your request gets loaded silently in the background.

**Structure fires on intent.** When you ask Claude to actually change something — "add a button", "fix this bug", "create the spec" — the XML task wrapper appears. The gate is real. You approve, Claude executes. Otherwise, structure stays out of the way.

**Depth is opt-in.** Want more? Say "tell me more", "why", "explain", "details". Without those signals, Claude gives you the short answer.

## Folder Map

```
your-project/
│
├── CLAUDE.md              ← always loaded
├── CONTEXT.md             ← routing table
├── STATE.md               ← current state (now)
├── TaskList.md            ← active kanban board
│
├── .context/
│   ├── identity.md
│   ├── rules.md
│   ├── glossary.md
│   ├── task-workflow.md   ← code gate
│   ├── task-workflow-appendix.md
│   ├── multi-agent-pipeline.md   ← roles/routing/escalation (bind per project)
│   └── housekeeping.md
│
├── workspaces/            ← feature-development, debugging, refactoring, planning, research
├── skills/                ← brainstorm (and future skills)
├── planning/              ← stories, specs, plans (each with index.md)
├── reference/             ← deep docs YOU wrote
│
├── raw/                   ← immutable sources
├── wiki/                  ← LLM-maintained knowledge (index, log, entities, concepts, sources)
│
└── src/                   ← your actual code
```

## The Flow

```
brainstorm (ephemeral)
    ↓ "let's plan this"
planning workspace
    ↓ produces story → spec? → plan
plan approved
    ↓ tasks move to TaskList.md ## Ready
feature-development workspace
    ↓ XML task gate → user approves → write code
shipped → TaskList.md ## Done + wiki/log.md
```

## First-Time Bootstrap (15–30 min)

Full walkthrough in **[SETUP.md](SETUP.md)** — getting the template, verifying the gate hook actually blocks, filling identity/state/rules, binding the multi-agent pipeline, and a first-session smoke test. Don't skip the hook check.

## Day-to-Day Usage

Just describe what you need. Claude will pick the workspace silently. Examples:

| You say | What happens |
|---|---|
| "I want to add export to dashboards" | feature-development workspace, XML task proposed |
| "There's a weird bug with login" | debugging workspace, diagnostic questions |
| "Let's think through options for caching" | brainstorm skill, divergent mode |
| "Let me write a story for export" | planning workspace, story format |
| "Ingest the file at raw/karpathy-llm-wiki.md" | research workspace, ingest gate |
| "What does the wiki say about caching?" | research workspace, query mode |

The structure is there when you need it; otherwise it's out of the way.

## Production Housekeeping

Real projects accumulate files. Without rules, the always-load budget grows and the wiki becomes noise. Run a housekeep pass periodically:

- **Weekly:** trim `STATE.md` + completed-task windows (5 min)
- **Monthly:** full housekeep — wiki lint, planning archive review, reference cleanup
- **Quarterly:** archive done planning artifacts to `planning/_archive/[year-quarter]/`

The full ruleset lives in `.context/housekeeping.md`. It's a *proposal* workflow — Claude lists what should be trimmed; you approve before anything moves.

## Core Principles

### Structure
1. **One-Place Rule.** Every fact lives in exactly one file.
2. **One-Way References.** A → B only, never bidirectional.
3. **Selective Section Loading.** Load the named section, not whole files.
4. **Routing is not work.** `CONTEXT.md` directs traffic; it doesn't contain answers.

### Knowledge
5. **`raw/` is immutable.** Source of truth; never modified.
6. **Compile once, query forever.** Don't re-read raw sources every time.
7. **Good answers compound.** File comparisons and analyses back as wiki pages.
8. **The LLM does maintenance.** Humans curate sources; Claude handles bookkeeping.

### Discipline
9. **The gate.** No writes to a gated surface without approval — `src/`/`reference/`/`.context/` need an XML task; `planning/` and `wiki/` have their own gates; task bookkeeping (`STATE.md`, `TaskList.md`, `wiki/log.md`) is exempt. Canonical table: `.context/task-workflow.md`. Reads are free.
10. **State vs Log.** `STATE.md` = now (overwrite). `wiki/log.md` = past (append). `TaskList.md` = in-flight.
11. **One task, one commit.** No opportunistic refactoring; no combined tasks.

## Anti-Patterns

- ❌ Editing files in `raw/`
- ❌ Letting `wiki/index.md` grow stale
- ❌ Treating `wiki/` as authoritative for project decisions
- ❌ Loading the whole wiki instead of starting at `index.md`
- ❌ Dumping all docs into one `CLAUDE.md`
- ❌ Bidirectional references between docs
- ❌ Letting `STATE.md` accumulate resolved decisions and fixed bugs
- ❌ Using `reference/` as a dumping ground for general knowledge (that's `wiki/concepts/`)
- ❌ Skipping housekeeping because nothing feels broken (it never feels broken until it does)

## Works At Any Stage

- **Planning:** Folders as thinking tools. Optional: ingest 2–3 foundational sources.
- **Early prototype:** Minimal fill-in. Skip wiki.
- **MVP:** Full workspaces. Wiki grows as you research adjacent topics.
- **Production:** Both fully active. Wiki becomes the team's compounding memory.

## Further Reading

- Karpathy's LLM Wiki gist: gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- ICM paper: arXiv 2603.16021 (Van Clief & McDermott)
- Reference ICM repo: github.com/RinDig/Content-Agent-Routing-Promptbase

## License

MIT — see [LICENSE](LICENSE). Copyright (c) 2026 Mighty Dragon.
