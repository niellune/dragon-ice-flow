# XML Task Workflow

> The gate before any file write. Produces `<task>` (single) or `<plan>` (multi-task).

## The Gate

No `Edit`/`Write` on a gated surface before user approval of the matching gate (table below). Reads are free.

The gate fires whether the conversation has been plain or structured. If the conversation has been plain prose, the XML task still appears — Claude doesn't suppress the wrapper to keep the conversation "light." A brief plain intro before the XML is fine; the XML itself is non-negotiable.

## Which Gate Covers What

**This table is canonical.** Other files point here; they never restate scope.

| Surface | Gate | Defined in |
|---|---|---|
| `src/`, `reference/`, `.context/` | `<task>` / `<plan>` | this file |
| `planning/` | `<planning-task>` | `workspaces/planning/CONTEXT.md` |
| `wiki/` (multi-page: ingest, lint fixes) | `<ingest>` | `workspaces/research/CONTEXT.md` |
| `wiki/` (single-page query filing) | One-line confirmation | `workspaces/research/CONTEXT.md` |
| `STATE.md`, `TaskList.md`, `wiki/log.md`, index files | **Exempt** — bookkeeping required by an already-approved task | — |

The exemption covers only the bookkeeping an approved task's checklist demands (board moves, state updates, log appends, index entries). It is not a side door for content changes.

The `<brainstorm>` wrapper in `skills/brainstorm/SKILL.md` is a declaration, not a gate.

## Sequence

1. Restate the task if ambiguous. Surface gotchas *before* the XML.
2. Write the XML below.
3. Wait for approval ("yes" / "do it" / "approve"). Silence ≠ approval.
4. Execute one task. Verify. Commit. Move on.

## Format

```xml
<task>
  <goal>One sentence.</goal>
  <assumptions>What you're inferring. "none" if empty.</assumptions>
  <files>
    <read>...</read>
    <write>...</write>
  </files>
  <action>Exact instructions, baked-in decisions, what to avoid.</action>
  <verify>Runnable command that proves the goal.</verify>
  <done>Definition of complete.</done>
</task>
```

Multi-task:
```xml
<plan>
  <phase>name</phase>
  <task id="1">...</task>
  <task id="2" depends="1">...</task>
</plan>
```

## Core Rules

- One task at a time. Only touch files in `<write>`.
- No opportunistic refactoring.
- Failed task → fix before next.
- After: run `<verify>`, commit (one task = one commit), move to `TaskList.md ## Done`, update `STATE.md` if state changed, append to `wiki/log.md` if notable decision.

## Enforcement (hook)

The code gate is enforced mechanically by a PreToolUse hook (`.claude/hooks/gate-check.ps1`, registered in `.claude/settings.json`): `Edit`/`Write` to `src/`, `reference/`, or `.context/` is blocked unless the sentinel file `.claude/gate-open` exists.

Sentinel lifecycle:
1. User approves the XML task → create the sentinel: `echo approved > .claude/gate-open`
2. Execute the task, verify, commit.
3. Delete the sentinel: `rm .claude/gate-open` (or `Remove-Item`). Never leave it open between tasks.

The sentinel is gitignored. If the hook blocks a write you believe is exempt, check the "Which Gate Covers What" table — bookkeeping files are outside the gated paths by design.

## More

Red flags, state-vs-log boundaries, when this doesn't apply, after-task checklist details → `.context/task-workflow-appendix.md` (load when needed).

Pipeline roles, model routing, and escalation for executing approved work → `.context/multi-agent-pipeline.md` (load when executing).
