# M5b instrumented rerun array

This fresh array will rerun the original 17 pending rows and all terminal TIMEOUT rows from the old uninstrumented run. It uses one CPU and 3 GiB per task, a six-task array throttle, a six-hour per-test cap with a 6h10m allocation, SIGINT followed by a 60-second kill grace, line-buffered VVP output, and the mcycle VPI heartbeat. Rows are ordered shortest first.

The selection is finalized after job 669 has no more running tasks and the separate `smoke_test_kv` heartbeat verification passes. This preserves the original running work and avoids overlapping reruns. Each task records its latest heartbeat in `status.txt` and `sim.log`; a timeout is called a hang only if mcycle remains flat for at least 30 minutes.

Status: the final 42-row selection is prepared: 25 terminal timeouts plus the original 17 rows, sorted by expected mcycle cost. Job 669 is terminal. Smoke verification job 785 is RUNNING and has emitted two heartbeats (`wall_s=0, mcycle=0`; `wall_s=300, mcycle=1722`), showing forward progress. Its firmware PASS/result is not available yet, so the rerun array has not been submitted.
