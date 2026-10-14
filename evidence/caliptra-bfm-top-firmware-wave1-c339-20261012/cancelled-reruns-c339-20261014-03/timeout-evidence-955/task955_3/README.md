# Task 955_3 timeout

Task 955_3 reruns original array task 799_34 / source row 43, `smoke_test_kv_parallel_access`. It reached its configured 18,167-second per-test limit without a testcase result. The final recognized heartbeat is `wall_s=18000 mcycle=80975`; the wrapper reports 54 progress heartbeats. No PASS/FAIL marker or `result.json` exists.

The unchanged wrapper status is `INFRA_ERROR` / `runner_terminated_by_signal` / exit 137. The resource log records `timeout --signal=INT --kill-after=60s 18167`, an elapsed time of 5:02:47 (exactly 18,167 seconds), and peak RSS of 1,852,700 KiB. The job no longer appeared in `squeue` when collected; `sacct` reports that accounting storage is disabled, so the scheduler terminal state could not be independently verified. Following the established M6 timeout-reclassification convention, the result ledger records TIMEOUT and preserves the raw status unchanged.

The run used the pinned Icarus source `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` on DAN-DESKTOP, which had been up since 07:28:20 MDT. Selected run metadata, compiler and simulator logs, native-vector logs, tool versions, and Slurm output are preserved here. `REMOTE-SHA256SUMS-task955_3.txt` was generated on the host and verifies against the archived files.
