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
