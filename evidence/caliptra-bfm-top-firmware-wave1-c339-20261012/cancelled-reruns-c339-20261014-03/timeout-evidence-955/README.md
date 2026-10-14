# Task 955_1 timeout

Task 955_1 reruns original task 799_28 / source row 37, `smoke_test_ecc_errortrigger4`. It reached its configured 17,281-second per-test limit without a testcase result. The final recognized heartbeat is `wall_s=17100 mcycle=9009`; there are no PASS/FAIL markers or `result.json`.

The unchanged raw `status.txt` says `INFRA_ERROR` / `runner_terminated_by_signal` / exit 137 because the array wrapper maps signal exit codes that way. The resource log shows the exact command was run under `timeout --signal=INT --kill-after=60s 17281` and records 4:48:01 elapsed (17,281 seconds), with exit 137. Slurm records the job completed at 12:27:20 MDT after 4:48:03, while the host had remained up since 07:28:20; peak RSS was 1,852,684 KiB under the 3 GiB limit. As in the earlier M6 timeout reclassification, this exact configured-cap termination is recorded as `TIMEOUT`, while preserving the wrapper's raw status unchanged.

The raw status recognizes 55 progress heartbeats. The simulator log has 58 substring matches, of which 55 begin with the heartbeat marker; all agree on the final heartbeat. The selected run metadata, compile and simulator logs, native-vector logs, tool versions, Slurm output, and remote SHA-256 manifest are preserved here. `REMOTE-SHA256SUMS-task955_1.txt` verifies against the archived files.

Task 955_2 / original 799_30 is also recorded as TIMEOUT; its raw evidence and classification details are under [`task955_2/`](task955_2/).

Task 955_3 / original 799_34 (`smoke_test_kv_parallel_access`) reached its 18,167-second per-test cap with final heartbeat `wall_s=18000 mcycle=80975`. The raw wrapper exit is 137, with no testcase marker or result JSON; the resource log records the exact timeout command and elapsed time. Its evidence is SHA-verified under [`task955_3/`](task955_3/).

After commit `ed0ce4f`, task 955_3's completed output tree was removed, freeing 375,777,048 bytes; `/home/dsell` available space increased by 376,217,600 bytes. Cleanup details are in [`task955_3/cleanup-task955_3-20261014.txt`](task955_3/cleanup-task955_3-20261014.txt).
