## 6. Closeout

Runs only after both verify checks pass. Mechanical — no authoring, no free-form summarizing. Follows the project's closeout dossier format.

- The diff is already committed by the implementer; closeout commits only records, by pathspec.
- **Apply the verified map delta** to the architecture map. Apply only. If the delta is missing or contradicts the map, closeout stops and reports. It never invents.
- Board row per the Closeout Rule; note any plan deviation in the log entry, never the row.
- Last feature of a plan: author the dossier from the round files (`planning/rounds/<id>/`) into `planning/done-plans/<slug>.md` from the template; paste every feature's EVIDENCE lines verbatim; list owed manual gates under Owed; delete each `gates/<id>.md`; add the row to `planning/done-plans.md`; run housekeeping Rules 1 + 5.
