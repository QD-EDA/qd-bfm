# Job 799 pass evidence

Task 32 (`smoke_test_ecc_flow1_kv_ocp_progress`, source row 41) completed as PASS. Slurm job 880 and the runner both exited 0. `output/result.json` reports `passed=true`, `sim_exit=0`, one testcase pass marker, and zero fail markers. The simulator log contains `* TESTCASE PASSED` and finishes at mcycle 60,927.

The full simulator log has 29 progress heartbeats through `wall_s=8400 mcycle=59912`; no adjacent samples repeat mcycle, so the 30-minute hang criterion is not met. The wrapper's `status.txt` is stale at 27 heartbeats through `wall_s=7800 mcycle=55508`; the recorded final mcycle comes from the complete simulator log. Resource wall time was 2:22:54 (8,574 seconds), with maximum RSS 1,852,488 KiB.

Selected run metadata, result JSON, and logs are under `runs/41-044d2b8bcd486492-32/`; the Slurm wrapper log is under `logs/`. The remote file hashes are recorded in `REMOTE-SHA256SUMS-task32.txt`.
