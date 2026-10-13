# Job 799 timeout reclassification

The submitted wrapper labeled Slurm tasks 1–7 `INFRA_ERROR` because VVP was
terminated with exit 137. For every task, the measured elapsed time equals its
configured per-test timeout exactly, so the terminal outcome is `TIMEOUT`.
Each task requested 3 GiB and peaked at about 1.85 GiB RSS; the logs do not
indicate memory pressure. The full heartbeat sequences contain no repeated
mcycle values at adjacent 300-second samples, so none meets the 30-minute
flat-mcycle hang criterion.

`results.tsv` records the corrected outcome and final mcycle. The raw
`status.txt` and `resource.log` are retained for every row. Row 7 also includes
its provenance, tool versions, Slurm output, and build/simulation logs. The
wrapper's original status is unchanged.

Task 7's resource report records `2:07:08` (7,628 seconds), exactly matching
its configured timeout. Its last heartbeat is `wall_s=7500 mcycle=51400`; the
full sequence advances at every 300-second sample, and no testcase PASS/FAIL
marker or result JSON exists. It is a timeout, not a hang.
