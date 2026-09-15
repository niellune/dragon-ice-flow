# Rules

> Non-negotiables. If something here conflicts with a user request, surface the conflict — do not silently override.
>
> **Filling this file:** the bracketed `[...]` placeholders are prompts for the project owner, not instructions for Claude. **Delete any section that doesn't apply** to this project; don't leave empty brackets — they read as instructions and cause confusion. Stack-specific rules (language, layout, lanes, naming) are not written here by hand: a stack pack from `reference/stacks/` fills the `<!-- stack:... -->` anchors when applied (`.claude/scripts/apply-stack.ps1 <pack>`).

## Non-Negotiables (always loaded)
1. Never commit secrets, API keys, or `.env` files.
2. Never push directly to `main` / `master`.
3. Never delete files without explicit user confirmation.
4. Never invent function/library names — verify they exist.
5. Always read a file before editing it.
6. Code layout and import boundaries follow the applied stack pack (`STATE.md` → Stack & Versions names it). No stack pack applied means no layout rule yet; ask before inventing one.

## Code Style
- **Comments:** Only when *why* is non-obvious. Never explain *what*.
<!-- stack:code-style -->

## Architecture
<!-- stack:architecture -->

## Naming
<!-- stack:naming -->

## Security
- All user input is untrusted until validated.
- Auth checks happen at the route level, not the component level.
- PII never enters logs.

## Compliance
[If applicable: GDPR, HIPAA, SOC2, etc.]

## Testing
- New features need a test. Bug fixes need a regression test.
- No skipped or focused tests in committed files.
<!-- stack:testing -->

## Git / PR Conventions
- Commit messages: `[task-id] short imperative` (e.g. `feat-012 add dashboard export button`)
- One concern per PR.
- PR description: what changed, why, how tested.
