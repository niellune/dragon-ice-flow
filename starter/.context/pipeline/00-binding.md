## Project binding

Fill this in per project. Nothing else in this document needs editing.

| Slot | Value |
|---|---|
| `TIER-1` — highest capability, used sparingly | _model_ |
| `TIER-2` — strong, used at both boundaries | _model_ |
| `TIER-3` — efficient, used on the loop | _model_ |
| Task format | `.context/task-workflow.md` |
| Closeout dossier format | `planning/done-plans/_dossier-template.md` |
| Gate ledger | `gates/<feature-id>.md` · format `.context/gates-ledger.md` · runner `.claude/scripts/gates.ps1` |
| Role briefs | `.context/briefs/<role>.md` + `_common.md` |
| Workspace-flag lint rule | _not yet defined — `-WorkspaceRule '<cmd regex>=<flag regex>'` when the test command is workspace-wide_ |
| Wiki root | `wiki/` |
| Architecture map | `STATE.md` → `## Architecture Snapshot` (or an index over section files once the map grows) |
| Tasklist / log | `TaskList.md` · `wiki/log.md` |
| Build command | _command_ |
| Test command | _command_ |
| Lint / typecheck command | _command_ |

Where this document says "the build", "the tests", or "the task format", it means the entries above.
