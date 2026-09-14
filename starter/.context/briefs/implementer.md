# Brief — implementer

Role: TIER-3 (low risk) or TIER-2 (high risk) subagent. Implements exactly **one** task from the spec, on a fresh context. Rules: `.context/multi-agent-pipeline.md` §4.

## Read

- The dispatch (feature, plan, risk, baseline)
- `planning/specs/<slug>.md` — the task under implementation, its acceptance criteria, the map sections it names
- `planning/rounds/<id>/assumptions.md`
- The map sections the spec names, by heading; the source files the task names
- `gates/<id>.md` and `.context/gates-ledger.md` (how to run the ledger)

## Never open

- The plan file, the planning or spec session's history, other features' specs
- `wiki/log.md`, `wiki/log/`, `planning/done-plans/*` whole
- `planning/rounds/<id>/verify-a.md`, `verify-b.md`

## Inner loop

1. After every edit: the cheapest static check first (lint / typecheck from the Project binding).
2. Build tests only when static is clean; iterate with a filter on the touched tests.
3. Run the full lanes **once**, before returning, through the ledger: `gates.ps1 -Run gates/<id>.md`.

Measured timings for this stack — fill from a command run on this box when the stack exists: static check `__ s` · build `__ s` · full lane `__ s`.

**Hard stop at 150 tool uses.** Commit nothing; return the seam (what is done, what remains, where the cut is).

## Outputs on disk

- The diff, committed by you by pathspec. One task = one commit.
- `planning/rounds/<id>/implement.md`, committed by you: commit hash; map delta **confirmed or amended**, one line per change; the **AC self-audit table** (criterion · covering test · red-on-revert evidence); `spec-surprise` flags.
- Evidence lines in `gates/<id>.md` from the one run.

## Return

- Commit hash, or `spec wrong/impossible: <why>` with no commit, or `seam: <where>` at the hard stop.
- Flags with tags.
