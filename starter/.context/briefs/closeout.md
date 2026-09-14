# Brief — closeout

Role: TIER-3 subagent. Mechanical: applies, records, files. Authors nothing from memory; every line comes from a round file, a ledger, or a command run this round. Runs only after verify-a and verify-b both pass. Rules: `.context/multi-agent-pipeline.md` §6; formats: `.context/task-workflow.md ## Closeout Rule`, `planning/done-plans/_dossier-template.md`.

## Read

- The dispatch (feature, plan, risk, baseline)
- `planning/rounds/<id>/` — all four round files
- `gates/<id>.md` (evidence lines)
- `TaskList.md` · `STATE.md ## Architecture Snapshot` (the map) · `planning/done-plans.md`
- `.context/housekeeping.md` Rules 1 and 5, at plan close only

## Never open

- Source files — you apply a delta, you do not read code
- `wiki/log.md`, `wiki/log/`, `planning/done-plans/*` whole (grep to append or to check a fact)

## Do (commit order)

- **Step 1 — record errors fixed at source.** Every `✗` in `verify-a.md` / `verify-b.md` adjudicated a record error (code stands, no fix round): fix the stale text where it lives — a code comment, a spec, `reference/`, a wiki page. Own commit `[<id>] record fix at source: <what>`. Skip if none. A wrong record that survives unfixed fails the next checklist too.
- **Apply the verified map delta** from `implement.md` (as confirmed in `verify-a.md`). Apply only. Missing or contradicting the map → stop and report; never invent.
- Board: Done row exactly per the Closeout Rule template; update the plan header. Plan deviations → one line in the log entry, never the row.
- Log: one entry, head `## [YYYY-MM-DD] <kind> | <title>`, short note. Kinds: the list in the log header.
- Fix rounds traced to spec ambiguity → a spec finding, recorded for the dossier.
- **Last feature of a plan:** dossier from the template into `planning/done-plans/<slug>.md`, from the round files; paste every feature's evidence lines verbatim; delete each `gates/<id>.md`; add the row to `planning/done-plans.md`; run housekeeping Rules 1 + 5; append the feature's map delta to the plan's map section.
- Commit by pathspec. The budget hook applies to every board and state write.

## Outputs on disk

- `TaskList.md`, `STATE.md`, `wiki/log.md`, the map; at plan close also the dossier and `planning/done-plans.md`.

- Final commit `[<id>] closeout: <title>` with the board, state, log, map and (at plan close) the dossier.

## Return

- Commit hash(es). `git status --short` (expect empty). Byte sizes of `TaskList.md` and `STATE.md`.
- `done`, or `stopped: <reason>` (delta missing/contradicting, budget refused, gate unmet).
- Wall-clock, tool-use count.
