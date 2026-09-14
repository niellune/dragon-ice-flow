# Brief — spec

Role: TIER-2 subagent. Writes the spec, the gate ledger and the XML task(s) for **one** feature, against the repository as it is now. You are the XML author; the orchestrator forwards your tasks verbatim. Rules: `.context/multi-agent-pipeline.md` §3 and `## Cost rule`.

## Read

- The dispatch (feature, plan, risk, baseline)
- `planning/plans/<slug>.md` — the plan's goal and context, and the **one** feature under spec. Not the other features.
- The architecture map sections this feature touches: find them by grep on the map (`STATE.md ## Architecture Snapshot` until the map is an index), open only those headings
- The source files the feature touches. Open them; never guess a path or a signature.
- `.context/task-workflow.md` (task format, Closeout Rule) · `.context/gates-ledger.md` (ledger format, standard gates)

## Never open

- `wiki/log.md`, `wiki/log/`, `planning/done-plans/*` whole — grep only
- Other features' specs or `planning/rounds/*`
- The whole repository or the whole map

## Outputs on disk

- `planning/specs/<slug>.md` — per §3: file paths; code to reuse; acceptance criteria (every AC about existing code cites `file:line` opened this round); out-of-scope; ordering; stated assumptions; findings tagged `fact` / `spec-surprise` / `plan-conflict`; proposed map delta; risk confirmation; **the map sections touched**, by heading; per task, what shipped path it protects and why (pins, golden files, shims are owed only there).
- The XML task(s) in the plan file, in the task format, `<verify>` naming `gates/<id>.md` and gate ids.
- `gates/<id>.md` — the ledger, linted (`gates.ps1 -Lint`) and status-checked (`-Status`). **Never run it**: executing gates is the implementer's job.
- `planning/rounds/<id>/assumptions.md` — the stated assumptions, one per line, for both verifiers; its header lists the map sections touched, so verify-b gets them without the spec body.
- Board row moved to In Progress; one spec-round entry in `wiki/log.md`.
- **One commit** `[<id>] spec round: <title>` with all of the above. Nothing under `src/`.

## Return

- Commit hash. Wall-clock, tool-use count.
- Risk: `confirmed` or `raised to high` (never lowered).
- Gate count (runnable / manual), the lint and status result lines.
- Findings with tags. A `plan-conflict`, or "blocked: <why>", is the first line.
- A task expected past ~2 hours or 150 tool uses is split before dispatch; name the seam.
