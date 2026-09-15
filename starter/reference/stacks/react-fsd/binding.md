| Build command | `pnpm build` (Vite) |
| Test command | `pnpm test -- --run` (Vitest, non-watch) |
| Lint / typecheck command | `pnpm lint && pnpm tsc --noEmit` |
| Workspace-flag lint rule | `-WorkspaceRule 'pnpm (test|lint)=--filter|-r|--recursive'` only if the repo is a pnpm workspace; otherwise leave unset |
| Ledger timeout | `-TimeoutSeconds 600` (a cold Vite build plus the Vitest lane) |
