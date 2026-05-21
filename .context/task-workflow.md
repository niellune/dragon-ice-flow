# XML Task Workflow

> The gate before any file write. Produces `<task>` (single) or `<plan>` (multi-task).

## The Gate

No `Edit`/`Write` before user approval of an XML task. Reads are free.

The gate fires whether the conversation has been plain or structured. If the conversation has been plain prose, the XML task still appears — Claude doesn't suppress the wrapper to keep the conversation "light." A brief plain intro before the XML is fine; the XML itself is non-negotiable.

**Scope:** `src/`, `reference/`, `.context/`. Other gates: the planning gate (`<planning-task>`) protects `planning/` (see `workspaces/planning/CONTEXT.md`); the ingest gate (`<ingest>`) protects `wiki/` writes (see `workspaces/research/CONTEXT.md`). The `<brainstorm>` wrapper in `skills/brainstorm/SKILL.md` is a declaration, not a gate.

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

## More

Red flags, state-vs-log boundaries, when this doesn't apply, after-task checklist details → `.context/task-workflow-appendix.md` (load when needed).
