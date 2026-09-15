| unit lane | `pnpm test -- --run --reporter=basic` | `Tests\s+(\d+) passed \(\1\)` |
| lint | `pnpm lint; if ($LASTEXITCODE -eq 0) { 'LINT_CLEAN' }` | `^LINT_CLEAN$` |
| format | `pnpm prettier --check .; if ($LASTEXITCODE -eq 0) { 'FMT_CLEAN' }` | `^FMT_CLEAN$` |
| typecheck | `pnpm tsc --noEmit; if ($LASTEXITCODE -eq 0) { 'TSC_CLEAN' }` | `^TSC_CLEAN$` |
