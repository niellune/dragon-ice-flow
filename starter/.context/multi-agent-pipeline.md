# Multi-Agent Pipeline Rules — index

Canonical for pipeline roles, routing, and escalation. Project-specific values live in `pipeline/00-binding.md`; the rules themselves never name a language, framework, tool, or model.

This file is an **index**. Load only the section a brief or a routing row names, by file; never the whole set. Section numbers (§1–§6) are the headings inside the files and are what the briefs cite. Sizes are bytes at the 2026-09-14 split; refresh them at housekeeping.

| File (`.context/pipeline/`) | Covers | Size | Headings for grep |
|---|---|---|---|
| `00-binding.md` | Project binding: tier models, task format, dossier, ledger, briefs, map, build/test/lint slots | 1.2 KB | `## Project binding` |
| `01-roles.md` | Roles table (stage, tier, output); one feature at a time | 0.9 KB | `## Roles` · `One feature at a time` |
| `02-planning.md` | §1 Planning: feature-level plans, risk flag, open questions (`decided` / `blocking` / `spike`), retry budget | 1.5 KB | `## 1. Planning` |
| `03-orchestration.md` | §2 Orchestration: last ten log entries, opens no source, six-line dispatch, dispatch then wait, writes nothing, routing table | 2.6 KB | `## 2. Orchestration` · `Per cycle it reads` · `Dispatch is six lines` · `Dispatch, then wait` · `Trigger \| Action` |
| `04-spec.md` | §3 Spec + tasks: spec contents, cited ACs, protection per task, map sections touched, XML authored here | 1.9 KB | `## 3. Spec + tasks` · `Acceptance criteria` · `Map sections touched` |
| `05-implementation.md` | §4 Implementation: fresh context, exact task, map delta confirmed or amended | 0.5 KB | `## 4. Implementation` |
| `06-verification.md` | §5 Verification: check 1 and 2, blinding by file, assumption checklist, record-error tag, lane-selection check, fix-at-source rule | 3.0 KB | `## 5. Verification` · `Check 1` · `Check 2` · `Blinding is by file` · `Assumption checklist` · `Lane-selection check` · `Record-error fix-at-source rule` |
| `07-closeout.md` | §6 Closeout: records only, apply the map delta, dossier at plan close | 0.8 KB | `## 6. Closeout` |
| `08-cost-rule.md` | Cost rule: stage-cost table, four rulings, time-side rules (150 tool uses), spike lane, verify-cost review | 3.4 KB | `## Cost rule` · `Stage-cost table` · `Four rulings` · `Time-side rules` · `Spike lane` · `Verify-cost review` |
| `09-standing-constraints.md` | Standing constraints: fresh context per role, state on disk, escalation rule-triggered, build serialized | 1.0 KB | `## Standing constraints` |

Reading list per role: `.context/briefs/<role>.md`. Routing for "run the board": `CONTEXT.md`. Split record: `wiki/log.md` [2026-09-14], ref-023.
