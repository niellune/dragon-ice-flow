# Brief — verify-b (spec vs intent)

Role: TIER-2 subagent, **always**, regardless of risk. Never the session that wrote the spec or the code. Judges whether the diff delivers the feature the plan intended. Blinded by file: you never see the spec body or the other pass. Rules: `.context/pipeline/06-verification.md` (§5), check 2.

## Read

- The dispatch (feature, plan, risk, baseline)
- `planning/plans/<slug>.md` — the plan's goal and context, and the **one** feature's intent. Not the task sequence, not the other features.
- The diff: `git diff <baseline>..<implementer commit>`
- `planning/rounds/<id>/assumptions.md`
- Ledger **status only**: `gates.ps1 -Status gates/<id>.md`. Any unmet gate is a fail; you do not run gates.

## Never open

- `planning/specs/<slug>.md` — the spec body
- `planning/rounds/<id>/verify-a.md` · `planning/rounds/<id>/implement.md`
- `wiki/log.md`, `wiki/log/`, `planning/done-plans/*` whole

## Do

- Ask one question: does this diff deliver the planned feature? Judge against intent, not against the spec's wording. Is anything in the intent silently dropped or contradicted?
- A spec that cannot deliver the intent is a `plan-conflict` — say so; it is not a code defect.
- **Assumption checklist is structural**: every row of `assumptions.md` marked `✓` (holds, with `file:line` you opened) / `✗` (violated, with evidence) / `n/a — not code-verifiable` (one-line reason). When the evidence says the *record* is stale (an old comment, a spec typo, a superseded reference line) rather than the code wrong, mark it `✗ record-error suspected`; same routing, pre-triaged for closeout's fix-at-source step. An unmarked row invalidates the pass.
- Never re-run the build, tests or lint. The status line is your evidence. **Do not modify the tree.**
- Cite only `file:line` you opened this round.

## Outputs on disk

- `planning/rounds/<id>/verify-b.md`: verdict PASS/FAIL with the intent reasoning; the `-Status` summary line; the assumption checklist, every row marked; findings tagged with `file:line`; **wall-clock, tool-use count**.
- **One commit** `[<id>] verify B: PASS|FAIL` with `verify-b.md`. No other file.

## Return

- `PASS` or `FAIL`, with reasons specific enough to act on.
- Commit hash. Wall-clock, tool-use count.
- Flags with tags. A `plan-conflict` stops the pipeline.
