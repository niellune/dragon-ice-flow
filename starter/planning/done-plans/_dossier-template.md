# Dossier — <plan-slug>

> One file per closed plan, written by closeout from the round files in `planning/rounds/<id>/` and the gate ledgers — never from memory. The record shape is a budget: five summary bullets, one numbers table, one verify-cost block per feature, evidence lines verbatim, a record-error list. Nothing else. Copy this file to `planning/done-plans/<slug>.md` and fill every slot; leave `(none)` where a slot is empty.

## Summary (exactly five bullets)

- **Shipped:**
- **Replaced or changed:**
- **Plan deviations:**
- **Spec findings** (fix rounds traced to spec ambiguity become a spec finding here):
- **Owed** (manual gates, deferred protection, follow-ups):

## Numbers

| Feature | Tasks | Commits | Fix rounds | Tool uses (implementer) | Wall-clock |
|---|---|---|---|---|---|
| | | | | | |

Every number comes from a command run at closeout (`git log`, the ledger, the round files). Never from an earlier report.

## Verify cost

One block per feature. Cited from `.context/pipeline/08-cost-rule.md`, never copied there.

### <feature-id>

| Pass | Model | Wall-clock | Tool uses | Verdict | Flags | Adjudication (`code-fix` / `record-error` / `n/a`) |
|---|---|---|---|---|---|---|
| spec round | | | | | | |
| implementer | | | | | | |
| verify-a (code vs spec) | | | | | | |
| verify-b (spec vs intent) | | | | | | |
| fix round 1 | | | | | | |

Wall-clock and tool uses come from each role's round file, never estimated.

## Evidence

Pasted verbatim from `gates/<feature-id>.md` at close; the ledger is then deleted.

```
<evidence lines>
```

## Map delta applied

- (none)

## Record errors

Mistakes found in this dossier after it was written. Append; never rewrite the sections above.

- (none)
