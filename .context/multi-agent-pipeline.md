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
| Task format | _path to the doc that defines task units; canonical for that_ |
| Closeout dossier format | _path; canonical for that_ |
| Wiki root | _path_ |
| Architecture map | _path_ |
| Tasklist / log | _paths_ |
| Build command | _command_ |
| Test command | _command_ |
| Lint / typecheck command | _command_ |

Where this document says "the build", "the tests", or "the task format", it means the entries above.

---

## Roles

| Stage | Tier | Output |
|---|---|---|
| Plan | TIER-1, separate session | Feature-level plan + risk flags |
| Orchestrate | TIER-3, main agent | Dispatch, state updates, wiki writes |
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

The orchestrator dispatches and records. It does not exercise judgment on quality, scope, or ambiguity.

- Re-read tasklist and log from the wiki at the start of every cycle. Do not carry state across cycles in context.
- Never answer another agent's open questions. Route them.
- Never decide whether a finding matters. Route by the tag the producing agent assigned.
- Never mark a feature done. Only closeout does that.

| Trigger | Action |
|---|---|
| Finding tagged `fact` | Write to the wiki (log or entity page), then continue |
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
- **Acceptance criteria** written so the verifier checks them literally. "Done" is defined here, once.
- Explicit out-of-scope list.
- Task ordering and dependencies.
- **Stated assumptions** about the codebase, one line each. These are the objective trigger for re-planning later.
- **Findings**, each tagged `fact` / `spec-surprise` / `plan-conflict`. The orchestrator writes these to the wiki; they must not be left only in this agent's context.
- **Proposed architecture-map delta**: which modules, boundaries, and data flows this feature will change, in the map's own vocabulary. Written before code exists, so it is a prediction — the implementer confirms or amends it.
- **Risk confirmation**: confirm the planner's flag, or raise it. Never lower it. The planner set the flag without reading the relevant code; this agent has.

Do not write pseudo-code or implementation logic. Specify contract and intent; leave the how to the implementer.

---

## 4. Implementation

- Fresh context. Inputs: the task unit, the spec, the architecture map. Not the planning or spec session's history.
- Implement exactly the task. Do not expand scope.
- If the spec is wrong or impossible, stop and report. Do not improvise a fix.
- On completion, return the **map delta confirmed or amended**, one line per change. Divergence from the spec's predicted boundaries is a `spec-surprise` — tag and report it.

---

## 5. Verification

Never the session that wrote the code. Two checks, both required, and the second never downgrades:

**Check 1 — code vs spec.** Does the diff satisfy the acceptance criteria? Includes running the build, tests, and lint. TIER-3 on low risk, TIER-2 on high.

**Check 2 — spec vs intent.** Does this spec actually deliver the feature that was planned? **TIER-2, always.** The spec author cannot catch its own spec-level errors, and a misclassified risk flag must never leave a feature with no independent check. Inputs: feature intent from the plan, the spec, the diff.

**Depth by risk.** Low: one pass each. High: run the two checks as blinded sessions — check 1 receives spec + diff only, check 2 receives plan intent + diff only. If both sessions receive everything, you have one reviewer running twice, not two reviewers.

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

- Commit the diff.
- Write feature docs; commit.
- **Apply the verified map delta** to the architecture map. Apply only. If the delta is missing or contradicts the map, closeout stops and reports. It never invents.
- Mark the feature done in the tasklist; note any plan deviation in the log.
- Last feature of a plan: wiki housekeeping.

---

## Standing constraints

- **Fresh context per role.** No session both plans and executes, or both specs and verifies.
- **State lives in the wiki**, not in agent context. Any agent can be restarted from wiki state alone.
- **The gate is not the gatekeeper.** Closeout commits only what verify passed.
- **Escalation is rule-triggered, never discretionary.**
- **Capability is never removed from the intent check.** If something must be downgraded for cost, downgrade the implementer.
- **Build and test commands are foreground-only and serialized.** Implementer and verifier never run them concurrently.
- **Every loop has a floor.** If no retry budget covers a situation, it escalates to human by default.
- This document is canonical for roles, routing, and escalation. The task-format and closeout-dossier docs named in Project binding are canonical for their formats. Neither copies the other.
