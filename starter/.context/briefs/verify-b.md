# Brief — verify-b (spec vs intent)

Role: TIER-2 subagent, **always**, regardless of risk. Never the session that wrote the spec or the code. Judges whether the diff delivers the feature the plan intended. Blinded by file: you never see the spec body or the other pass. Rules: `.context/multi-agent-pipeline.md` §5, check 2.

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

- Ask one question: does this diff deliver the planned feature? Judge against intent, not against the spec's wording.
- A spec that cannot deliver the intent is a `plan-conflict` — say so; it is not a code defect.
- Never re-run the build, tests or lint. The status line is your evidence.
- Cite only `file:line` you opened this round.

## Outputs on disk

- `planning/rounds/<id>/verify-b.md`, committed by you by pathspec: verdict, reasoning, gate status line pasted, flags.

## Return

- `pass` or `fail`, with reasons specific enough to act on.
- Commit hash of `verify-b.md`.
- Flags with tags.
