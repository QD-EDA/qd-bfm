# Job 799 pass evidence

Task 32 (`smoke_test_ecc_flow1_kv_ocp_progress`, source row 41) completed as PASS. Slurm job 880 and the runner both exited 0. `output/result.json` reports `passed=true`, `sim_exit=0`, one testcase pass marker, and zero fail markers. The simulator log contains `* TESTCASE PASSED` and finishes at mcycle 60,927.

The full simulator log has 29 progress heartbeats through `wall_s=8400 mcycle=59912`; no adjacent samples repeat mcycle, so the 30-minute hang criterion is not met. The wrapper's `status.txt` is stale at 27 heartbeats through `wall_s=7800 mcycle=55508`; the recorded final mcycle comes from the complete simulator log. Resource wall time was 2:22:54 (8,574 seconds), with maximum RSS 1,852,488 KiB.

Selected run metadata, result JSON, and logs are under `runs/41-044d2b8bcd486492-32/`; the Slurm wrapper log is under `logs/`. The remote file hashes are recorded in `REMOTE-SHA256SUMS-task32.txt`.

## Task 33 — `smoke_test_kv_rules_ocp_lock`

Task 33 (source row 42, Slurm array element 799_33) completed PASS. `result.json` reports `passed=true`, compile and simulation exit 0, one testcase pass marker, and zero fail markers. `sim.log` contains `* TESTCASE PASSED` and ends at finish mcycle 60,518. Its full log has 29 progress heartbeats; the last is `wall_s=8400 mcycle=58921` with no repeated adjacent mcycle. `status.txt` reports 28 heartbeats, but its last heartbeat agrees with the complete simulator log.

Resource wall time was 2:24:19 (8,659 seconds) and maximum RSS was 1,852,432 KiB. Selected metadata, result JSON, and logs are under `runs/42-ac4e209a8a8dca30-33/`; the Slurm wrapper log is under `logs/`. Remote hashes are recorded in `REMOTE-SHA256SUMS-task33.txt`.

## Task 41 — `smoke_test_strap`

Array task 799_41 (source row 50) completed PASS. The runner exited 0; `result.json` reports `passed=true`, compile and simulation exit 0, one testcase pass marker, and zero fail markers. The full simulator log contains `* TESTCASE PASSED` and finishes at mcycle 57,180. The final progress heartbeat was `wall_s=7800 mcycle=55683` (27 heartbeats), which is the recorded final heartbeat mcycle. Resource wall time was 2:14:07 (8,047 seconds), with maximum RSS 1,852,252 KiB.

Selected run metadata, result JSON, and logs are under `runs/50-804790f41f3373fe-41/`; the Slurm wrapper log is under `logs/`. All 25 copied files match the remote SHA-256 manifest `REMOTE-SHA256SUMS-task41.txt`. At 21:29 MDT, after the evidence commit and confirming the job had left Slurm, I deleted its remote output tree; this freed 375,633,657 bytes (about 0.350 GiB). The compact status/resource metadata and wrapper log remain in the protected run directory.
