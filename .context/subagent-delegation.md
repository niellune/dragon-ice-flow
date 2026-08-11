# Subagent Delegation

> How approved work is split across models. Load when executing an approved `<task>` or `<plan>`.

## The Principle

The main agent (Fable) orchestrates and plans; it does not execute gated work itself. Every approved task runs in a subagent chosen by work type. The main agent stays lean: it briefs, reviews results, and manages the gate sentinel.

## Model Routing

| Work | Model | Notes |
|---|---|---|
| Planning — authoring `<task>` / `<plan>` XML, stories, specs | Fable (main agent) | The approval gate still faces the user directly; planning is never delegated away from the main context. |
| Code execution — implementing an approved task on `src/`, `reference/`, `.context/` | Opus subagent | Receives the full XML task verbatim. Touches only files in `<write>`. Returns a diff summary. |
| Verify + commit + docs — running `<verify>`, committing, board moves, `STATE.md`, `wiki/log.md`, index updates | Sonnet subagent | One commit per task. Follows the after-task checklist in `task-workflow.md` Core Rules. |
| Housekeeping — after the last task of a `<plan>` | Sonnet subagent | Runs the sequence in `.context/housekeeping.md`. Still proposal-only: findings come back for user approval, never autonomous cleanup. |

## Sequence per Approved Task

1. User approves the XML task → main agent opens the gate sentinel (`.claude/gate-open`).
2. Main agent spawns an **Opus** subagent with the full XML task; Opus implements and reports back.
3. Main agent spawns a **Sonnet** subagent to run `<verify>`, commit (one task = one commit), and do the bookkeeping (TaskList move, `STATE.md`, `wiki/log.md`).
4. Main agent closes the sentinel and reviews the result before starting the next task.

A failed `<verify>` goes back to step 2 — fix before the next task, per Core Rules.

## End of Plan

After the last task in a `<plan>` reaches Done, spawn the **Sonnet** housekeeping subagent before declaring the plan complete. It follows the housekeep sequence in `.context/housekeeping.md` and reports proposals; the user approves any trims or archives.
