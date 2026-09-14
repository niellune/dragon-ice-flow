## Standing constraints

- **Fresh context per role.** No session both plans and executes, or both specs and verifies.
- **State lives on disk** (board, log, round files in `planning/rounds/<id>/`, ledgers in `gates/`), not in agent context. Any agent can be restarted from disk state alone. The producer commits its own files; the orchestrator commits nothing.
- **The gate is not the gatekeeper.** Closeout commits only what verify passed.
- **Escalation is rule-triggered, never discretionary.**
- **Capability is never removed from the intent check.** If something must be downgraded for cost, downgrade the implementer.
- **Build and test commands are foreground-only and serialized.** Implementer and verifier never run them concurrently.
- **Every loop has a floor.** If no retry budget covers a situation, it escalates to human by default.
- This document is canonical for roles, routing, and escalation. The task-format and closeout-dossier docs named in Project binding are canonical for their formats. Neither copies the other.
