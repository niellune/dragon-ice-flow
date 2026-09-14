# Unslop Skill

> Flag and repair AI writing patterns in this project's records. Audit by default; a rewrite exits through the folder's existing gate.
>
> Not a workspace. The scanner is `.claude/scripts/unslop/unslop.ps1`; every rule, threshold and allowlist lives in `.claude/scripts/unslop/rules.ps1` and is not repeated here. The voice lives in `.context/identity.md`.

## When to Use

- The user says "unslop", "de-slop", "humanize", "does this read like AI", "clean up this prose".
- Before a closeout commits prose a subagent wrote: a dossier, a wiki entry, a round file under `planning/rounds/`.
- As the prose gate of a task that writes markdown (`.context/gates-ledger.md` §Standard gates).
- Automatically: `.claude/settings.json` wires `unslop.ps1 -Hook` as a PostToolUse hook, so every Edit or Write to a record (`planning/done-plans/`, `wiki/*.md`, `reference/`, `.context/`) is scanned and refused with the findings on stderr. Housekeeping step 1 runs `-All`.

## When NOT to Use

- Code and comments. The stack's linter and formatter own those.
- `raw/` (immutable), `wiki/log/` (the verbatim archive), `template/` (its own copy). Never scanned, never rewritten.
- The board, `STATE.md` and `planning/backlog.md`: the first two have the budget hook, the third is a working list.

## Modes (pick one, state it upfront)

### 1. Audit (default) — report, write nothing

1. Run the scanner on the files named: `powershell -NoProfile -File .claude/scripts/unslop/unslop.ps1 <paths>`. Directories walk `*.md`.
2. Read the same files for what a regex cannot see: a recap that restates its own section; praise with no measurement behind it; a vague transformation where the diff would name a function; a hedge that carries no meaning; a moral drawn at the end of a finding.
3. Report per the template. Every item names a line. No edits.

### 2. Rewrite — the smallest repair, through a gate

The preservation contract is what makes rewriting safe on a record:

- Edit only sentences with a finding. Every other sentence is copied byte-for-byte.
- Never touch numbers, counts, units, dates, commit hashes, task ids, paths, code spans, quoted text or citations. A finding inside one of those is a wrong finding, not wrong text.
- In rules text (`.context/`, the briefs, gate ledgers) the words never, must, all and only carry force. A rewrite keeps them exact.
- A false positive fixes the rule in `rules.ps1`, with a why and a silence test in `.claude/scripts/tests/unslop.tests.ps1`, never the text.
- Then the gate for the file's folder: `<task>` for `reference/` and `.context/`, `<planning-task>` for `planning/`, `<ingest>` for `wiki/`. The XML's `<verify>` names the prose gate.

## Output Template

```
Mode: audit — N files

scanner:
<the scanner's lines, verbatim>
unslop: N findings in F file(s)

what regex missed:
- path:line — what, and why it is a pattern rather than a choice

verdict: clean | N repairs proposed (rewrite mode, needs the folder's gate)
```

## Anti-Patterns

- ❌ Flagging house style: em dashes, bold-led bullets, dense sentences, "not just", the `Q? answer` shorthand. If the scanner is silent and the prose is dense, it is dense on purpose.
- ❌ Rewriting a sentence with no finding to improve flow.
- ❌ Loosening a number, a hedge or a scope word to make a sentence shorter.
- ❌ Adding a teach or mimic mode. The voice has one home.

## Transition Out

- Audit clean → say so in one line and stop.
- Repairs proposed → the gate for that folder, one task per gate.
- A rule change → `<task>` on `.claude/scripts/unslop/rules.ps1` with its test.
