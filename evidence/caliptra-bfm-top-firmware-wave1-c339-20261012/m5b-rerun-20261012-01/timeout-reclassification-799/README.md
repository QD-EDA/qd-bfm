# Job 799 timeout reclassification

The submitted wrapper labeled Slurm tasks 1–6 `INFRA_ERROR` because VVP was
terminated with exit 137. For every task, the measured elapsed time equals its
configured per-test timeout exactly, so the terminal outcome is `TIMEOUT`.
Each task requested 3 GiB and peaked at about 1.85 GiB RSS; the logs do not
indicate memory pressure. The full heartbeat sequences contain no repeated
mcycle values at adjacent 300-second samples, so none meets the 30-minute
flat-mcycle hang criterion.

`results.tsv` records the corrected outcome and final mcycle. The raw
`status.txt`, `resource.log`, and `runner.log` files are retained under
`runs/`; the wrapper's original status is unchanged.
