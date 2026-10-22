# Task 955_2 timeout

Task 955_2 reruns original task 799_30 / source row 39, `kv_entry_read_err`. It reached its configured 17,543-second per-test limit without a testcase result. The final recognized heartbeat is `wall_s=17400 mcycle=135271`; there are no PASS/FAIL markers or `result.json`.

The unchanged raw `status.txt` says `INFRA_ERROR` / `runner_terminated_by_signal` / exit 137. The resource log shows `timeout --signal=INT --kill-after=60s 17543` and 4:52:23 elapsed, exactly 17,543 seconds, with exit 137. Slurm records the job completed at 12:31:42 MDT after 4:52:25; the host stayed up and the job's 3 GiB limit was not reached (peak RSS 1,852,684 KiB). Consistent with earlier M6 timeout reclassification, the result ledger records `TIMEOUT` and preserves the wrapper status unchanged.

The raw status and full simulator log both recognize 56 progress heartbeats through the final sample. Selected run metadata, compiler and simulator logs, native-vector logs, tool versions, Slurm output, and the remote SHA-256 manifest are preserved here. `REMOTE-SHA256SUMS-task955_2.txt` verifies against the archived files.

After commit `b134913`, the completed run's output tree was removed. This freed 376,032,275 bytes; `/home/dsell` available space increased by 376,475,648 bytes. No separate run-local Python cache remained. The run status/resource/provenance metadata and protected shared toolchain were retained. See [`cleanup-task955_2-20261014.txt`](cleanup-task955_2-20261014.txt).
