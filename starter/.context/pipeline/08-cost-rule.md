## Cost rule

Costs are recorded per stage so that "make it cheaper" lands where the cost is, not where it is visible. Verification is about a sixth of a feature; the bulk is the implementer and the fix rounds, and fix rounds are bought by ambiguous specs.

**Stage-cost table.** Filled from dossiers, cited here, never copied. One row per stage per closed feature; the source column names the dossier.

| Stage | Model | Wall-clock | Verdict | Flags | Source (dossier) |
|---|---|---|---|---|---|
| spec round | | | | | _none closed yet_ |
| implementer | | | | | |
| verify-a | | | | | |
| verify-b | | | | | |
| fix rounds | | | | | |

**Four rulings, pre-committed before any data exists:**

1. **The spec round is never cut.** Every fix round it prevents costs more than it does.
2. **Verification is not the lever.** Pre-committed here so it cannot be re-opened by whoever reads the table first. If something must be downgraded for cost, downgrade the implementer.
3. **Protection scales with shipped footprint.** Pins, golden files and shims are owed only by code a shipped path reads. The spec names per task what it defends and why; a task with no shipped path owes none.
4. **Fix rounds traced to spec ambiguity become a spec finding at closeout**, recorded in the dossier's Spec findings bullet, so the next spec round starts from them.

**Time-side rules:**

- Every acceptance criterion that asserts a property of existing code cites `file:line` (§3).
- A task expected past **~2 hours or 150 tool uses** is split before dispatch, with the seam named in the spec.
- The implementer **stops hard at 150 tool uses**: commits nothing, returns the seam. The orchestrator routes the seam to the spec agent as a split, never back to the implementer as "continue".
- The implementer returns an **AC self-audit table** (criterion · covering test · red-on-revert evidence). Verify-a checks it row by row; a row without evidence is an unmet AC.

**Spike lane.** A task that ships nothing (its deliverable is a written finding) keeps the spec round and verify-b, drops verify-a, and batches its closeout with the plan's. Eligibility is per task, never per plan:

- deliverable is a finding in `wiki/` or `planning/`, not a diff under `src/`;
- no shipped path reads anything it writes: no production lever, no golden row, no pin to defend;
- it touches no wire, protocol constant, format version, or deployed artifact;
- its code lands on a branch that is discarded, or is reverted before the plan closes.

A task failing any one runs the full lane, even inside a spike plan. The moment a spike's code is wanted in production it becomes an ordinary feature with a spec round and two blinded passes: the numbers do not carry the code across. A number measured on throwaway-shaped code is recorded **with that fact**, every time; a number that forgets its provenance gets quoted later as if it did not.

**Verify-cost review, pre-committed.** Trigger: the first plan to close after **five** features have closed under this pipeline. Rulings already made: the review reads the stage-cost table and the dossiers' verify-cost blocks; it may re-tier the implementer or re-scope spec depth; it may not remove verify-b, merge the two passes, or cut the spec round (rulings 1 and 2 above). Output: `planning/done-plans/verify-cost-review-YYYY-MM.md`, citing the dossiers it read.
