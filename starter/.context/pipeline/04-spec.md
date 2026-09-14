## 3. Spec + tasks

Written per feature, immediately before implementation, against the repository as it is now. Task units follow the project's task format.

Each spec contains:

- Concrete file paths to create or modify.
- Existing code that must be reused rather than reinvented.
- **Acceptance criteria** written so the verifier checks them literally. "Done" is defined here, once. Every AC that asserts a property of existing code cites `file:line` opened this round; an AC without a citation is a guess, and guesses buy fix rounds.
- **Per task, what it protects and why.** Pins, golden files and shims are owed only by code a shipped path reads; name the shipped path or write "none".
- Explicit out-of-scope list.
- Task ordering and dependencies.
- **Stated assumptions** about the codebase, one line each. These are the objective trigger for re-planning later.
- **Findings**, each tagged `fact` / `spec-surprise` / `plan-conflict`. This agent writes them to its round file (or a wiki page) and commits; they must not be left only in its context.
- **Proposed architecture-map delta**: which modules, boundaries, and data flows this feature will change, in the map's own vocabulary. Written before code exists, so it is a prediction — the implementer confirms or amends it.
- **Map sections touched**, by heading. The implementer and both verify passes load the map index plus those sections and nothing else. No brief ever says "read the map".
- **Risk confirmation**: confirm the planner's flag, or raise it. Never lower it. The planner set the flag without reading the relevant code; this agent has.

The XML task(s) in the task format are this agent's output, written into the plan file and committed with the spec. The orchestrator forwards them by pointer.

Do not write pseudo-code or implementation logic. Specify contract and intent; leave the how to the implementer.
