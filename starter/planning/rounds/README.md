# planning/rounds/

One folder per feature in flight: `planning/rounds/<feature-id>/` holding `assumptions.md` (spec), `implement.md` (implementer), `verify-a.md` (code vs spec), `verify-b.md` (spec vs intent). Each file is committed by the role that produced it — `git log --format=%an -- planning/rounds/<id>/` shows who. Blinding is by file: each brief's **Never open** list (`.context/briefs/`) names the round files that role must not read. The orchestrator never opens this folder.

Round files are kept after close (closeout builds the dossier from them) and move to `planning/_archive/YYYY-Qn/rounds/` in housekeeping Rule 2 batches.
