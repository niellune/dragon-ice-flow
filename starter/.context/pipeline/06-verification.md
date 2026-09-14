## 5. Verification

Never the session that wrote the code. Two checks, both required, and the second never downgrades:

**Check 1 — code vs spec (verify-a).** Does the diff satisfy the acceptance criteria? Re-verifies every gate of the ledger (`gates/<id>.md`, format in `.context/gates-ledger.md`): this is the feature's **one re-execution**. The implementer ran the ledger once when the diff was ready; nobody runs the lanes after verify-a. Also checks the assumption checklist, the AC self-audit table row by row, and the map delta. TIER-3 on low risk, TIER-2 on high.

**Check 2 — spec vs intent (verify-b).** Does this diff actually deliver the feature that was planned? **TIER-2, always.** The spec author cannot catch its own spec-level errors, and a misclassified risk flag must never leave a feature with no independent check. Inputs: feature intent from the plan, the diff, the ledger's `-Status` line (any unmet gate is a fail; it never executes).

**Blinding is by file, on every feature.** Each verifier's brief carries a **Never open** list: verify-a never opens `verify-b.md` or the plan; verify-b never opens the spec body, `implement.md`, or `verify-a.md`. If both passes receive everything, you have one reviewer running twice, not two reviewers. Risk selects only the tier of check 1.

**Assumption checklist — required structural output.** Every stated assumption from the spec, listed, each resolved as:

- `✓` holds — with evidence as `file:line`
- `✗` violated — with evidence
- `n/a` not code-verifiable (design intent, future scope) — with one line of reasoning and no fabricated citation

An output missing this section is not a verify result. A violated assumption is a `plan-conflict`, not a code defect.

A `✗` whose evidence points at a stale *record* (an outdated code comment, a spec typo, a superseded reference line) rather than wrong code is marked `✗ record-error suspected`: same routing, pre-triaged for adjudication.

**Map delta sanity check.** Does the delta match what the diff actually changed? A mismatch is feedback to the implementer, not a fail on its own.

**Lane-selection check (verify-a).** Confirm the documented test lane actually *compiles and executes* tests covering the touched files, not just that it ran green. A lane that physically cannot see the touched file is the classic verify escape (a feature-gated or member-package file whose tests never built). Name the lane per touched file, with evidence.

**Record-error fix-at-source rule.** When a `✗` is adjudicated a record error (the code stands, no fix round), the same closeout fixes the stale record at its source, whatever durable file holds it: a code comment, a spec, `reference/`, the wiki. A wrong record that survives adjudication unfixed misleads the next blinded pass too.

Output: pass/fail plus feedback specific enough to act on. Every pass records its wall-clock and tool-use count in its round file; that is the only source for the stage-cost table.
