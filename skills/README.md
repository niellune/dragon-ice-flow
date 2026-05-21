# skills/

**Skills are on-demand capabilities.** Different from workspaces.

| | Workspaces | Skills |
|---|---|---|
| Loaded by | Task type (feature, bug, refactor, etc.) | User request or Claude's judgment |
| Frequency | Once per task | Briefly, possibly multiple times |
| Output | Files in the project | Conversational; files optional |
| Gate | Has one (XML task / planning task) | No gate |
| Lifetime | Whole task | Single exchange or short sequence |

A workspace says *"this is the kind of work we're doing."*
A skill says *"this is a kind of thinking I'm reaching for right now."*

## Current Skills

- **`brainstorm/`** — explore possibilities before committing. Four modes: divergent, convergent, stress-test, analogize.

## Adding a Skill

Each skill is a folder with a `SKILL.md`. Conventions:

- **When to use** — explicit triggers
- **When NOT to use** — explicit anti-triggers
- **Modes or shapes** — if the skill has variants, name them
- **Output template** — what the user should expect to see
- **Transition out** — how this skill hands off to a workspace or to silence

Suggested future skills as the template grows:
- `code-review/` — structured review of a diff or PR
- `retrospective/` — periodic reflection on what shipped
- `estimate/` — sizing work without committing to a plan

These are suggestions, not required. Add when the *absence* starts to hurt.
