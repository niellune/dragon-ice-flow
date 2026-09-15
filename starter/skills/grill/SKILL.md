# Grill Skill

> A relentless interview to sharpen a plan, decision, or design *that lives in the user's head*.
>
> Thin wrapper: the interview behaviour itself is the built-in Claude Code `grilling` skill. This file only defines project routing — when to fire it and where its output goes.

## When to Use

- The user says "grill me", "grill me about X", "interview me", "stress-test my thinking".
- A feature is heading toward the `planning` workspace but the "what" is fuzzy **and the missing knowledge is in the user's head, not the codebase** (product intent, priorities, constraints the code cannot answer).
- Before writing a spec for a risky or cross-cutting feature, *offer* a grill session.
- A planning round raised a `blocking` question that only the owner can answer.

## When NOT to Use

- The user wants **Claude's** critique of an idea → `brainstorm` skill, stress-test mode. Boundary: **grilling = the user talks; stress-test = Claude talks.**
- Bug fixes, scoped requests, tweaks — just do the work.
- Questions that need a prototype to react to (feel, layout, format) — ungrillable; build the cheapest testable thing instead.
- Facts about the codebase. Go read it; that is not a question.

## How

Invoke the Skill tool with `grilling`. Follow its instructions for the interview itself. Project constraints on top:

- **No file writes during the session.** The interview is conversational and ephemeral.
- One decision branch at a time; prerequisites before dependents.
- Watch for passivity — forty "yes" answers produce confident nonsense. If the user stops pushing back, say so.

## Transition Out

Session conclusions are **not** committed directly. They exit through the existing gates:

- Sharpened "what" → `<planning-task>` for a story or spec (`workspaces/planning/CONTEXT.md`).
- An answered `blocking` question → an ADR in `reference/adr/` (code gate; format in `reference/adr/README.md`) plus a one-line `wiki/log.md` entry.
- New domain terms that surfaced → propose rows for `.context/glossary.md` (code gate).
- Nothing landed → fine. The session's only required artifact is a sharper idea.
