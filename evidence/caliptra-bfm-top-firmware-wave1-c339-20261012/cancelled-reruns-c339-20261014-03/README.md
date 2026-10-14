# Corrected reruns after host restart

This fresh array reruns the four original array-799 maintenance cancellations: 799_28, 799_30, 799_34, and 799_35. They map to source rows 37, 39, 43, and 44, respectively. Prior job 936 was interrupted by a host restart; job 949 failed before any test started because `selection.tsv` was staged in the wrong directory. Both are infrastructure attempts, not test outcomes, and their evidence is preserved in the neighboring run folders.

This submission stages `selection.tsv` both at `$ROOT/selection.tsv` (the exact path used by the array script) and under `submit/`. The tasks use the original per-test timeouts, 1 CPU and 3 GiB each, 6h10m allocation, and array throttle 6. The pinned source/toolchain inputs were re-verified before submission. No local duplicates are running.

[`selection.tsv`](selection.tsv) maps the array tasks; [`results.tsv`](results.tsv) records terminal outcomes only after complete run evidence is collected.


## Initial submission state

Slurm accepted array 955 at 07:39:17 MDT. At 07:39:21, all four tasks were RUNNING on DAN-DESKTOP, each with one CPU, 3 GiB, and a 6h10m limit; `ArrayTaskThrottle=6`. The 07:39:32 queue/resource snapshot is in [`initial-queue-20261014-0739.txt`](initial-queue-20261014-0739.txt). The four task logs show the expected source-row mappings and pinned QD commit.


At the 07:52 MDT check, all four array-955 tasks remained RUNNING. Each simulator emitted three heartbeats through `wall_s=600`; final observed mcycles were 4,500, 4,500, 4,512, and 4,512 for tasks 1–4. VVP processes were using about 99.9% CPU and 1.04 GiB RSS each. No result JSON, status file, or testcase terminal marker exists yet. The 30-minute flat-heartbeat rule is not met; the exact snapshot is [`heartbeat-snapshot-20261014-0752.txt`](heartbeat-snapshot-20261014-0752.txt).


At 08:03 MDT all four array-955 tasks remained RUNNING. Each had five heartbeats through `wall_s=1200`; latest mcycles were 9,185, 9,185, 9,231, and 9,238 for tasks 1–4. VVP was still consuming about 99.9% CPU per task. No result JSON, status file, or terminal marker was present. The latest heartbeat had been written about 3.5 minutes earlier, so no task meets the 30-minute flat-heartbeat rule. See [`heartbeat-snapshot-20261014-0803.txt`](heartbeat-snapshot-20261014-0803.txt).


At 08:14 MDT, all four tasks were still RUNNING with no result/status file or testcase marker. Their last heartbeat remains `wall_s=1800`, with mcycles 13,882; 13,880; 13,939; and 13,953. The last simulator log write was 07:59:50 MDT, about 14 minutes before this check; each VVP was still using 99.9% CPU at about 1.04 GiB RSS. This is below the 30-minute flat-heartbeat threshold, so no row is classified as a hang. Snapshot: [`heartbeat-snapshot-20261014-0814.txt`](heartbeat-snapshot-20261014-0814.txt).
