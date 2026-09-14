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
