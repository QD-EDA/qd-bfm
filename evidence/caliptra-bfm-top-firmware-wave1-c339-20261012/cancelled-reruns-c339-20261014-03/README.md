# Corrected reruns after host restart

This fresh array reruns the four original array-799 maintenance cancellations: 799_28, 799_30, 799_34, and 799_35. They map to source rows 37, 39, 43, and 44, respectively. Prior job 936 was interrupted by a host restart; job 949 failed before any test started because `selection.tsv` was staged in the wrong directory. Both are infrastructure attempts, not test outcomes, and their evidence is preserved in the neighboring run folders.

This submission stages `selection.tsv` both at `$ROOT/selection.tsv` (the exact path used by the array script) and under `submit/`. The tasks use the original per-test timeouts, 1 CPU and 3 GiB each, 6h10m allocation, and array throttle 6. The pinned source/toolchain inputs were re-verified before submission. No local duplicates are running.

[`selection.tsv`](selection.tsv) maps the array tasks; [`results.tsv`](results.tsv) records terminal outcomes only after complete run evidence is collected.


## Initial submission state

Slurm accepted array 955 at 07:39:17 MDT. At 07:39:21, all four tasks were RUNNING on DAN-DESKTOP, each with one CPU, 3 GiB, and a 6h10m limit; `ArrayTaskThrottle=6`. The 07:39:32 queue/resource snapshot is in [`initial-queue-20261014-0739.txt`](initial-queue-20261014-0739.txt). The four task logs show the expected source-row mappings and pinned QD commit.
