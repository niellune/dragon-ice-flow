# Briefs — common rules

> Every pipeline role reads its own brief first, then this file. Rules here bind every role; the role brief adds its **Read**, **Never open**, **Outputs on disk** and **Return** lists. Roles and routing: `.context/multi-agent-pipeline.md`.

## Reading

- Read only what your brief lists. Your context is fresh by design; the orchestrator did not read on your behalf and nothing it saw reaches you.
- History is **grep-only**: never open `wiki/log.md`, `wiki/log/`, or `planning/done-plans/*` whole. Grep the ruling, then print the section.
- Every `file:line` you cite was opened by you **this round**.
- Every count, size, range or timing you write comes from a command you ran **this round**. Never compute a number from an earlier report.
- Load the map sections the spec names, never "the map".

## Writing

- Your outputs go to the files your brief names. You commit them yourself, **by pathspec** (`git add <paths>`). Never `git add -A`, never renormalize — the index may be shared with another session.
- Files are LF. Before returning, run the zero-CR check on every file you touched:
  `powershell -NoProfile -Command "git diff --name-only HEAD | ForEach-Object { if (Select-String -Path $_ -Pattern '\r' -Quiet) { 'CR: ' + $_ } }"` — empty output is the pass.
- Board rows and always-load files are budgeted; the PostToolUse hook refuses over-budget writes. Trim the row, not the rule (`.context/task-workflow.md ## Closeout Rule`).
- Phantom modified files with empty diffs are a stale stat cache: `git update-index --refresh -- <those files>`. Never sweep them into a commit.

## Box facts

- The build, tests and lint (Project binding in the pipeline doc) are **foreground-only and serialized**: one working tree, one build directory. Never run them while another role's run is in flight.
- Never background any job from a subagent. You get no completion callback; the job outlives your report.
- Verification runs the ledger (`gates/<feature-id>.md`, format in `.context/gates-ledger.md`); the implementer runs it once, verify-a re-verifies once, verify-b reads status only. Three full-lane runs on one commit buy nothing the first did not.

## Returning

- Your report is the orchestrator's **only** completion signal. Return exactly what your brief's Return list names: commit hash, verdict or seam, and flags with their tags (`fact` / `spec-surprise` / `plan-conflict`). Nothing the orchestrator would have to open a file to learn.
- If you are blocked, the first line of the report says so and why. Never improvise past a blocker.
