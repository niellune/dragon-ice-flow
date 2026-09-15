# reference/adr/

Decisions of record: the answers to `blocking` questions and any other choice that is expensive or irreversible (data model, public contract, migration, system boundary, direction). One file per decision, `NNNN-slug.md`, numbered from the highest existing. Never edited after acceptance; a change of mind is a new ADR that supersedes the old one and says so in both.

An ADR is a rule for the future, so it lives here with the project's other decisions, not in `wiki/log.md`, which records events. The log gets a one-line `decision` entry pointing at the ADR when it is accepted.

## Format

```markdown
---
status: proposed | accepted (YYYY-MM-DD, who) | superseded by NNNN
---

# <the decision as a sentence>

<Context: the situation and the question, two paragraphs at most.>

## Considered options

- **Option.** Rejected: why, in a clause.
- **Option.** Chosen. Why, in a clause.

## Consequences

- <What this rules out, what it commits us to, what it makes cheaper or dearer.>
- <What existing rule or plan it retires or amends, by name.>
```

## Who writes one

- The planner (`.context/pipeline/02-planning.md`): an answered `blocking` question becomes an ADR before the plan is marked ready.
- The owner, after a `grill` session, through the code gate.
- Nobody else. A spec or an implementer that finds it needs a decision of this size reports a `plan-conflict`; it does not write an ADR.
