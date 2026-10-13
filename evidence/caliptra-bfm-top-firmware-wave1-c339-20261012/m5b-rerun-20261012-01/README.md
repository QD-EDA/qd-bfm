# M5b instrumented rerun array

This fresh array will rerun the original 17 pending rows and all terminal TIMEOUT rows from the old uninstrumented run. It uses one CPU and 3 GiB per task, a six-task array throttle, a six-hour per-test cap with a 6h10m allocation, SIGINT followed by a 60-second kill grace, line-buffered VVP output, and the mcycle VPI heartbeat. Rows are ordered shortest first.

The selection is finalized after job 669 has no more running tasks and the separate `smoke_test_kv` heartbeat verification passes. This preserves the original running work and avoids overlapping reruns. Each task records its latest heartbeat in `status.txt` and `sim.log`; a timeout is called a hang only if mcycle remains flat for at least 30 minutes.

[`results.tsv`](results.tsv) is the live 42-row ledger for array 799. Terminal
rows include the verdict and final mcycle; active rows include their latest
heartbeat, and queued rows remain PENDING. Exit-137 timeout corrections and
their raw artifacts are detailed in [`timeout-reclassification-799/`](timeout-reclassification-799/).

Status: the final 42-row selection is prepared: 25 terminal timeouts plus the original 17 rows, sorted by expected mcycle cost. Job 669 is terminal. Smoke verification job 785 passed: the runner exited 0, the result JSON reports `passed=true` for `smoke_test_kv`, and the simulator has one PASS marker with no failure markers. Its two heartbeats show mcycle advancing from 0 to 1,722 by 300 seconds. The first submission attempt was rejected because Slurm no longer recognized completed job 785 as a dependency; no tasks started. Since the PASS is verified, the final array script omits that stale dependency. The 42-row array was submitted successfully as job 799 at 01:53 MDT on 2026-10-13 (1 CPU, 3 GiB, 6h10m, throttle 6). At 02:07, tasks 1–6 were RUNNING with three heartbeat records each; mcycle increased from 0 to 4,306–4,347 by 600 seconds. At 02:59, those same six tasks were still RUNNING with 14 heartbeats each, with mcycle at 27,381–27,548 at wall time 3,900 seconds; tasks 7–42 were pending at throttle 6. No terminal markers were present and no task met the hang condition. The [02:07 snapshot](heartbeat-snapshot-20261013-0207.txt) and [02:59 snapshot](heartbeat-snapshot-20261013-0259.txt) record the live values.

At 04:12 MDT, tasks 1–6 had each exited 137 at exactly their configured timeout (6,775–7,628 seconds). The wrapper's `INFRA_ERROR` label is therefore corrected to `TIMEOUT`; their last mcycles are recorded in [`timeout-reclassification-799/results.tsv`](timeout-reclassification-799/results.tsv), with raw status and resource logs alongside it. Peak RSS was about 1.85 GiB under the 3 GiB cap, and no adjacent heartbeat samples repeated mcycle. Tasks 7–12 were still running and advancing at the latest check; tasks 13–42 remained pending at the array throttle.

At 04:25 MDT, tasks 7–12 were still running. Their latest mcycles ranged from 10,431 to 14,979, with no repeated adjacent mcycle samples; tasks 13–42 remained pending at throttle 6. The [04:25 snapshot](heartbeat-snapshot-20261013-0425.txt) records the six heartbeat values and the overlay job progress.

At 06:49 MDT, task 11 had exited 137 at exactly its 10,091-second cap; its
latest simulator heartbeat was `wall_s=9900 mcycle=67671`, with no testcase
terminal marker. This is classified as TIMEOUT in
[`timeout-reclassification-799/results.tsv`](timeout-reclassification-799/results.tsv).
Tasks 12–17 were running with advancing heartbeats; their latest
`wall_s/mcycle` pairs were 10,200/71,202; 3,300/21,788; 3,000/20,147;
1,800/12,200; 900/5,864; and 300/1,945. Tasks 18–42 were pending at throttle 6.
Overlay retry 826_1 was also running, with latest heartbeat
`wall_s=9300 mcycle=64274`; no observed mcycle window was flat for 30 minutes.

At 07:07 MDT, task 799_12 (`c_intr_handler`) reached its 10,813-second
per-test timeout and is recorded as TIMEOUT with final heartbeat
`wall_s=10500 mcycle=73262`. Tasks 799_13–18 were running with advancing
heartbeats; tasks 19–42 remained pending at throttle 6. Overlay retry 826_1
remained active, with latest heartbeat `wall_s=10200 mcycle=2882`; its mcycle
value decreased between the 9,600- and 9,900-second samples, and no terminal
marker/result was present. See [`heartbeat-snapshot-20261013-0707.txt`](heartbeat-snapshot-20261013-0707.txt).

At 07:42 MDT, tasks 799_13–18 were still running with all six mcycle
heartbeats advancing; tasks 19–42 remained pending at throttle 6. Overlay
retry 826_1 was also running, at `wall_s=12300 mcycle=17901`. Current values
are in [`heartbeat-snapshot-20261013-0742.txt`](heartbeat-snapshot-20261013-0742.txt).
