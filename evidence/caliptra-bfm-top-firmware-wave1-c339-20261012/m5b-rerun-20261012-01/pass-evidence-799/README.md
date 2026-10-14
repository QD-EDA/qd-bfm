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

## Task 42 — `smoke_test_sha256`

Array task 799_42 (source row 51) completed PASS. The runner exited 0; `result.json` reports `passed=true`, compile and simulation exit 0, one testcase pass marker, and zero fail markers. The full simulator log contains `* TESTCASE PASSED` and finishes at mcycle 61,567. Its last progress heartbeat is `wall_s=8400 mcycle=59985` (29 heartbeats), which is the recorded final heartbeat mcycle. `status.txt` is stale at 28 heartbeats through `wall_s=8100 mcycle=57824`; the full simulator log is authoritative. Resource wall time was 2:24:06 (8,646 seconds), with maximum RSS 1,852,416 KiB.

Selected run metadata, result JSON, and logs are under `runs/51-e0d4538883521cca-42/`; the Slurm wrapper log is under `logs/`. All 25 copied files match the remote SHA-256 manifest `REMOTE-SHA256SUMS-task42.txt`. At 21:41 MDT, after committing the evidence and confirming the task had left Slurm, I deleted its remote output tree; this freed 375,637,757 bytes (about 0.350 GiB). Compact status/resource metadata and the wrapper log remain in the protected run directory.


Task 799_38 (`smoke_test_sha256_wntz`, source row 47) ended **PASS**. `result.json` has `passed=true`, one testcase PASS marker, no FAIL marker, and finish mcycle 155,834. For the wave ledger, the final heartbeat is `wall_s=20400 mcycle=149887` (58 heartbeats); elapsed wall time was 5:53:58 and peak RSS was 1,852,356 KiB. Selected result, simulator, firmware, compile, provenance, status, resource, tool-version, and Slurm logs are under `runs/47-d51cc47c71747905-38/` and `logs/`; all 25 files match `REMOTE-SHA256SUMS-task38.txt` (transferred archive SHA-256 `2c6cc2468adaf8fad6a9e5a91129b94fdeb710cc486a0a954095281b7acc5280`). The remote output tree occupied 375,714,907 bytes and is pending cleanup after the evidence commit.
