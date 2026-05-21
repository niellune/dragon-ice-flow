# Rules

> Non-negotiables. If something here conflicts with a user request, surface the conflict — do not silently override.
>
> **Filling this file:** the bracketed `[...]` placeholders are prompts for the project owner, not instructions for Claude. **Delete any section that doesn't apply** to this project; don't leave empty brackets — they read as instructions and cause confusion.

## Non-Negotiables (always loaded)
1. Never commit secrets, API keys, or `.env` files.
2. Never push directly to `main` / `master`.
3. Never delete files without explicit user confirmation.
4. Never invent function/library names — verify they exist.
5. Always read a file before editing it.

## Code Style
- **Language conventions:** [e.g., TypeScript strict mode, no `any`]
- **Formatting:** [e.g., Prettier defaults, 2-space indent]
- **Imports:** [e.g., absolute paths from `@/`]
- **Comments:** Only when *why* is non-obvious. Never explain *what*.

## Security
- All user input is untrusted until validated.
- Auth checks happen at the route level, not the component level.
- PII never enters logs.

## Compliance
[If applicable: GDPR, HIPAA, SOC2, etc.]

## Testing
- [e.g., New features need a test. Bug fixes need a regression test.]
- [e.g., No `skip` or `only` in committed test files.]

## Git / PR Conventions
- Commit messages: `[workspace-id] short imperative`
- One concern per PR.
- PR description: what changed, why, how tested.
