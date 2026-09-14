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
