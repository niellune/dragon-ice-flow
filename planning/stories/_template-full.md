# Story: [slug]

> Full-format story template. Use when scope warrants it (multiple personas, edge cases, business rules, or cross-cutting). For simpler work, use the lightweight format in `workspaces/planning/CONTEXT.md`.

## Summary

One paragraph. What this story is about, who it's for, and why now.

## Personas

| Persona | Role | What they care about |
|---|---|---|
| [name] | [role / context] | [outcome they want] |

If there's only one persona, you may not need the full format — consider lightweight.

## Narrative

A few sentences in the user's voice. Concrete situation, not abstract.

> "I'm a [persona] and I [current situation]. I want to [capability] so that [outcome]. Right now I have to [pain] which means [consequence]."

## Acceptance Criteria

Use Given/When/Then for behavior-driven clarity, or plain checklist if simpler.

- [ ] **Given** [precondition], **when** [action], **then** [observable outcome]
- [ ] [criterion]
- [ ] [criterion]

## Edge Cases

- [Edge case]: [expected behavior]
- [Edge case]: [expected behavior]

## Out of Scope

Things this story explicitly does NOT cover. Critical for preventing scope creep.

- [excluded item]
- [excluded item]

## Dependencies

- Blocks: [other stories that depend on this]
- Depends on: [stories or specs that must come first]
- Related: [non-blocking links]

## Open Questions

Resolve before the story is approved.

- [ ] [question]
- [ ] [question]

## Links

- Spec: `planning/specs/[slug].md` (if any)
- Plan: `planning/plans/[slug].md` (once written)
- Wiki context: [relevant wiki pages]

## Status

draft | approved | in-progress | done | deprecated

---

*Created: [YYYY-MM-DD] · Last updated: [YYYY-MM-DD]*
