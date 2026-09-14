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

1. Every acceptance criterion met **literally**, with `file:line` evidence from the tree at the implementer's commit.
2. **AC self-audit table, row by row** — re-run each row's red-on-revert evidence yourself. A row that does not go red is a finding. Restore the tree after every probe (`git checkout -- <file>`); the diff is committed, so a probe cannot destroy work.
3. Re-verify **every** gate: `gates.ps1 -Reverify gates/<id>.md`. This is the feature's one re-execution; nobody runs the lanes again after you. A pass that did not re-verify has not verified.
4. **Lane-selection check** — name the lane(s) whose test processes actually compile and execute each touched file, with evidence. A lane that ran green without seeing the file proves nothing.
5. **Map delta** in `implement.md` matches the diff; rule on each amended line. Mismatch is feedback, not a fail.
6. **Scope** — nothing outside the spec's `<write>` set changed; zero CR bytes in touched files.
7. Rule on every finding in `implement.md`.
8. **Assumption checklist** — every row of `assumptions.md` resolved `✓` (with `file:line`) / `✗` (with evidence) / `n/a` (one line of reasoning, no citation). An output missing a row is not a verify result.
- Cite only `file:line` you opened this round.

## Outputs on disk

- `planning/rounds/<id>/verify-a.md`: verdict PASS/FAIL; per-AC row with evidence or the finding; the re-verify summary lines verbatim; lane-selection evidence; rulings on the implementer's findings; your own findings, tagged, with `file:line`; if FAIL, feedback specific enough for the implementer to act on; `git status --short` at the end (clean); **wall-clock, tool-use count**.
- **One commit** `[<id>] verify A: PASS|FAIL` with `verify-a.md` and the refreshed ledger evidence. No other file.

## Return

- `PASS` or `FAIL`, with feedback specific enough to act on.
- Commit hash. Wall-clock, tool-use count.
- Flags with tags; a violated assumption is a `plan-conflict`, not a code defect.
