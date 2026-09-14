# Brief — verify-a (code vs spec)

Role: TIER-3 (low risk) or TIER-2 (high risk) subagent. Never the session that wrote the code. Checks the diff against the spec literally and performs the feature's **one** re-verification of the ledger. Rules: `.context/multi-agent-pipeline.md` §5, check 1.

## Read

- The dispatch (feature, plan, risk, baseline)
- `planning/specs/<slug>.md` — acceptance criteria, stated assumptions, out-of-scope, map sections named
- The diff: `git diff <baseline>..<implementer commit>`
- `planning/rounds/<id>/assumptions.md` · `planning/rounds/<id>/implement.md` (map delta, AC self-audit table)
- `gates/<id>.md` · `.context/gates-ledger.md`
- The source files the diff touches, at the lines you cite

## Never open

- `planning/rounds/<id>/verify-b.md`
- The plan file (intent is verify-b's job, not yours)
- `wiki/log.md`, `wiki/log/`, `planning/done-plans/*` whole

## Do

- Re-verify **every** gate: `gates.ps1 -Run gates/<id>.md`. This is the feature's one re-execution; nobody runs the lanes again after you.
- **Assumption checklist** — every row of `assumptions.md` resolved `✓` (with `file:line`) / `✗` (with evidence) / `n/a` (one line of reasoning, no citation). An output missing a row is not a verify result.
- **AC self-audit table** — verify the implementer's table row by row: the covering test exists, and the red-on-revert evidence is real (run it if cheap, else say why not).
- **Map delta sanity** — does the delta match what the diff changed? Mismatch is feedback, not a fail.
- Cite only `file:line` you opened this round.

## Outputs on disk

- `planning/rounds/<id>/verify-a.md`, committed by you by pathspec: verdict, checklist, row-by-row audit, map-delta note, flags.

## Return

- `pass` or `fail`, with feedback specific enough to act on.
- Commit hash of `verify-a.md`.
- Flags with tags; a violated assumption is a `plan-conflict`, not a code defect.
