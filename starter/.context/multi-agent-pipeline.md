# Multi-Agent Pipeline Rules

Canonical for pipeline roles, routing, and escalation.
Project-specific values live in **Project binding** below; the rules themselves never name a language, framework, tool, or model.

---

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

---

## Roles

| Stage | Tier | Output |
|---|---|---|
| Plan | TIER-1, separate session | Feature-level plan + risk flags |
| Orchestrate | TIER-3, main agent | Six-line dispatch only; writes nothing |
| Spec | TIER-2 subagent | Spec + tasks + findings + proposed map delta + risk confirmation |
| Implement | low risk: TIER-3 · high risk: TIER-2 | Code diff + map-delta confirmation |
| Verify — mechanical | low risk: TIER-3 · high risk: TIER-2 | Code vs spec, assumption checklist |
| Verify — intent | TIER-2, always, regardless of risk | Spec vs intent |
| Closeout | TIER-3 subagent | Commit, docs, apply map delta, housekeeping |

**One feature at a time.** There is a single working tree and a single build workspace — parallel features collide on commits and builds, not just on the wiki. This does not relax even if wiki locking is added.

---

## 1. Planning

Own session. Produces artifacts, not code.

- Read the architecture map first, then read only the areas the plan touches. Do not load the whole repository.
- Plan at **feature level**: intent, scope, boundaries, ordering. No file paths, no pseudo-code, no implementation design — the spec is written later, against current repository state.
- Plan one coherent slice. Do not plan far ahead; the codebase will move.
- Assign each feature a **risk flag** (`low` / `high`). High = architecturally risky, touches many modules, or has weak test coverage. This is a switch, not a label: it selects the implementer tier, the mechanical-verifier tier, and verify depth.
- Output an **open questions block**, each tagged:
  - `decided` — cheap and reversible. Decide, record the decision and reason, continue.
  - `blocking` — expensive or irreversible (data model, public contract, migration, system boundary). Do not decide. Stop and ask.
  - `spike` — unanswerable until code exists. Becomes a task whose deliverable is a written finding in the wiki, not a commit.
- If a "question" is just a fact about the codebase, go read it. It is not an open question.
- A spike may kill its own plan: if its finding invalidates a plan premise, it is tagged `plan-conflict` and routed as one.
- **Retry budget per feature:** 2 spec attempts, 2 implement attempts, then human. Nothing loops forever.
- **Gate:** any `blocking` question means the plan is not ready. The tasklist stays empty until it is answered.

---

## 2. Orchestration

The orchestrator dispatches and waits. It does not exercise judgment on quality, scope, or ambiguity, and it **writes nothing**: every file a round produces is written and committed by the role that produced it. Its context lives for the whole plan, so everything it reads or writes is paid on every later turn.

**Per cycle it reads:** the board (`TaskList.md`) and the **last ten** entries of `wiki/log.md` (`grep "^## \[" wiki/log.md | head -10`, then those sections). It **opens no source**, no architecture map, no spec body, no round file, no dossier. Every subagent starts fresh and reads its own inputs; an orchestrator read is the wasted one. Do not carry state across cycles in context.

**Dispatch is six lines. A seventh is forbidden.**

```
Role: <spec | implementer | verify-a | verify-b | closeout>
Feature: <feature-id — title>
Plan: <planning/plans/slug.md>
Risk: <low | high>
Baseline: <commit hash the round starts from>
Read .context/briefs/<role>.md first, then .context/briefs/_common.md.
```

The XML task is the spec agent's output, written into the plan file; the orchestrator forwards it by pointer, never pasted, never edited.

**Dispatch, then wait.** The subagent's report is the only completion signal. **Never poll**: no loops on status, diff, or process list; no "helping" reads while a round is out. One feature, one round, one subagent at a time.

- Never answer another agent's open questions. Route them.
- Never decide whether a finding matters. Route by the tag the producing agent assigned.
- Never mark a feature done. Only closeout does that.

| Trigger | Action |
|---|---|
| Finding tagged `fact` | Producer already recorded it in its round file or wiki page; continue |
| Finding tagged `spec-surprise` | Continue; pass to both verifiers |
| Finding tagged `plan-conflict` (spec, spike, or verify) | Stop. Escalate to human / re-plan |
| Spec reports blocked or impossible | Return once to the spec agent with the blocker; 2nd time → human |
| Spec raises the risk flag | Re-dispatch implement at the new level |
| Verify fails, 1st time | Return to implementer with feedback |
| Verify fails, 2nd time — low risk | Escalate: TIER-2 implements |
| Verify fails, 2nd time — high risk (already TIER-2) | Escalate to human |
| Verifier reports a spec-level problem | Stop. Escalate to human / re-plan |
| Stated assumption violated | Stop. Escalate to human / re-plan |
| Assumption checklist has an unresolved row | Reject the verify output and re-run verify. Not a pass |
| Intent verification missing | Not a pass. Re-run |

---

## 3. Spec + tasks

Written per feature, immediately before implementation, against the repository as it is now. Task units follow the project's task format.

Each spec contains:

- Concrete file paths to create or modify.
- Existing code that must be reused rather than reinvented.
- **Acceptance criteria** written so the verifier checks them literally. "Done" is defined here, once. Every AC that asserts a property of existing code cites `file:line` opened this round; an AC without a citation is a guess, and guesses buy fix rounds.
- **Per task, what it protects and why.** Pins, golden files and shims are owed only by code a shipped path reads; name the shipped path or write "none".
- Explicit out-of-scope list.
- Task ordering and dependencies.
- **Stated assumptions** about the codebase, one line each. These are the objective trigger for re-planning later.
- **Findings**, each tagged `fact` / `spec-surprise` / `plan-conflict`. This agent writes them to its round file (or a wiki page) and commits; they must not be left only in its context.
- **Proposed architecture-map delta**: which modules, boundaries, and data flows this feature will change, in the map's own vocabulary. Written before code exists, so it is a prediction — the implementer confirms or amends it.
- **Map sections touched**, by heading. The implementer and both verify passes load the map index plus those sections and nothing else. No brief ever says "read the map".
- **Risk confirmation**: confirm the planner's flag, or raise it. Never lower it. The planner set the flag without reading the relevant code; this agent has.

The XML task(s) in the task format are this agent's output, written into the plan file and committed with the spec. The orchestrator forwards them by pointer.

Do not write pseudo-code or implementation logic. Specify contract and intent; leave the how to the implementer.

---

## 4. Implementation

- Fresh context. Inputs: the task unit, the spec, the map sections the spec names, the ledger. Not the planning or spec session's history. Reading list and never-open list: `.context/briefs/implementer.md`.
- Implement exactly the task. Do not expand scope.
- If the spec is wrong or impossible, stop and report. Do not improvise a fix.
- On completion, return the **map delta confirmed or amended**, one line per change. Divergence from the spec's predicted boundaries is a `spec-surprise` — tag and report it.

---

## 5. Verification

Never the session that wrote the code. Two checks, both required, and the second never downgrades:

**Check 1 — code vs spec (verify-a).** Does the diff satisfy the acceptance criteria? Re-verifies every gate of the ledger (`gates/<id>.md`, format in `.context/gates-ledger.md`): this is the feature's **one re-execution**. The implementer ran the ledger once when the diff was ready; nobody runs the lanes after verify-a. Also checks the assumption checklist, the AC self-audit table row by row, and the map delta. TIER-3 on low risk, TIER-2 on high.

**Check 2 — spec vs intent (verify-b).** Does this diff actually deliver the feature that was planned? **TIER-2, always.** The spec author cannot catch its own spec-level errors, and a misclassified risk flag must never leave a feature with no independent check. Inputs: feature intent from the plan, the diff, the ledger's `-Status` line (any unmet gate is a fail; it never executes).

**Blinding is by file, on every feature.** Each verifier's brief carries a **Never open** list: verify-a never opens `verify-b.md` or the plan; verify-b never opens the spec body, `implement.md`, or `verify-a.md`. If both passes receive everything, you have one reviewer running twice, not two reviewers. Risk selects only the tier of check 1.

**Assumption checklist — required structural output.** Every stated assumption from the spec, listed, each resolved as:

- `✓` holds — with evidence as `file:line`
- `✗` violated — with evidence
- `n/a` not code-verifiable (design intent, future scope) — with one line of reasoning and no fabricated citation

An output missing this section is not a verify result. A violated assumption is a `plan-conflict`, not a code defect.

**Map delta sanity check.** Does the delta match what the diff actually changed? A mismatch is feedback to the implementer, not a fail on its own.

Output: pass/fail plus feedback specific enough to act on.

---

## 6. Closeout

Runs only after both verify checks pass. Mechanical — no authoring, no free-form summarizing. Follows the project's closeout dossier format.

- The diff is already committed by the implementer; closeout commits only records, by pathspec.
- **Apply the verified map delta** to the architecture map. Apply only. If the delta is missing or contradicts the map, closeout stops and reports. It never invents.
- Board row per the Closeout Rule; note any plan deviation in the log entry, never the row.
- Last feature of a plan: author the dossier from the round files (`planning/rounds/<id>/`) into `planning/done-plans/<slug>.md` from the template; paste every feature's EVIDENCE lines verbatim; list owed manual gates under Owed; delete each `gates/<id>.md`; add the row to `planning/done-plans.md`; run housekeeping Rules 1 + 5.

---

## Cost rule

Costs are recorded per stage so that "make it cheaper" lands where the cost is, not where it is visible. Verification is about a sixth of a feature; the bulk is the implementer and the fix rounds, and fix rounds are bought by ambiguous specs.

**Stage-cost table.** Filled from dossiers, cited here, never copied. One row per stage per closed feature; the source column names the dossier.

| Stage | Model | Wall-clock | Verdict | Flags | Source (dossier) |
|---|---|---|---|---|---|
| spec round | | | | | _none closed yet_ |
| implementer | | | | | |
| verify-a | | | | | |
| verify-b | | | | | |
| fix rounds | | | | | |

**Four rulings, pre-committed before any data exists:**

1. **The spec round is never cut.** Every fix round it prevents costs more than it does.
2. **Verification is not the lever.** Pre-committed here so it cannot be re-opened by whoever reads the table first. If something must be downgraded for cost, downgrade the implementer.
3. **Protection scales with shipped footprint.** Pins, golden files and shims are owed only by code a shipped path reads. The spec names per task what it defends and why; a task with no shipped path owes none.
4. **Fix rounds traced to spec ambiguity become a spec finding at closeout**, recorded in the dossier's Spec findings bullet, so the next spec round starts from them.

**Time-side rules:**

- Every acceptance criterion that asserts a property of existing code cites `file:line` (§3).
- A task expected past **~2 hours or 150 tool uses** is split before dispatch, with the seam named in the spec.
- The implementer **stops hard at 150 tool uses**: commits nothing, returns the seam. The orchestrator routes the seam to the spec agent as a split, never back to the implementer as "continue".
- The implementer returns an **AC self-audit table** (criterion · covering test · red-on-revert evidence). Verify-a checks it row by row; a row without evidence is an unmet AC.

**Spike lane.** A task that ships nothing (its deliverable is a written finding) keeps the spec round and verify-b, drops verify-a, and batches its closeout with the plan's. Eligibility is per task, never per plan:

- deliverable is a finding in `wiki/` or `planning/`, not a diff under `src/`;
- no shipped path reads anything it writes;
- its ledger has no test-lane gate (only the board-budget, zero-CR and prose gates).

**Verify-cost review, pre-committed.** Trigger: the first plan to close after **five** features have closed under this pipeline. Rulings already made: the review reads the stage-cost table and the dossiers' verify-cost blocks; it may re-tier the implementer or re-scope spec depth; it may not remove verify-b, merge the two passes, or cut the spec round (rulings 1 and 2 above). Output: `planning/done-plans/verify-cost-review-YYYY-MM.md`, citing the dossiers it read.

---

## Standing constraints

- **Fresh context per role.** No session both plans and executes, or both specs and verifies.
- **State lives on disk** (board, log, round files in `planning/rounds/<id>/`, ledgers in `gates/`), not in agent context. Any agent can be restarted from disk state alone. The producer commits its own files; the orchestrator commits nothing.
- **The gate is not the gatekeeper.** Closeout commits only what verify passed.
- **Escalation is rule-triggered, never discretionary.**
- **Capability is never removed from the intent check.** If something must be downgraded for cost, downgrade the implementer.
- **Build and test commands are foreground-only and serialized.** Implementer and verifier never run them concurrently.
- **Every loop has a floor.** If no retry budget covers a situation, it escalates to human by default.
- This document is canonical for roles, routing, and escalation. The task-format and closeout-dossier docs named in Project binding are canonical for their formats. Neither copies the other.
