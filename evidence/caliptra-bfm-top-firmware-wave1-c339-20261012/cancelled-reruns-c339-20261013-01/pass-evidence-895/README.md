# Fresh array 895 task 4 PASS evidence

Fresh array task 895_4 reran source row 44, `smoke_test_ecc_flow2_kv_ocp_progress`, which had been cancelled for maintenance as original array task 799_35. The original 799 row remains classified `CANCELLED-FOR-MAINTENANCE`; this is a separate fresh execution.

The runner exited 0. `output/result.json` reports `passed=true`, compile, firmware, and simulation exit 0, one testcase pass marker, zero fail markers, and zero bad diagnostics. The full `sim.log` contains `* TESTCASE PASSED`, 29 progress heartbeats, and ends at `wall_s=8400 mcycle=62186`; the test's final finish record is mcycle 62,472. The run-level `status.txt` is stale at 27 heartbeats through `wall_s=8100 mcycle=59961`, so the full simulator log supplies the recorded last-heartbeat mcycle.

The timeout was 19,152 seconds. `resource.log` records 8,469 seconds elapsed (2:21:09), maximum RSS 1,852,676 KiB, and exit status 0. The selected result, simulator and firmware logs, toolchain metadata, resource record, and Slurm wrapper output are under `runs/44-bcb5b29a003aa2a6-4/` and `logs/`.

All 18 selected files match [`REMOTE-SHA256SUMS-task4.txt`](REMOTE-SHA256SUMS-task4.txt). The transferred tar archive SHA-256 was `0b3eb1e95369341826fb36ebd32ac2ca16c7c49284f54d24636e65fbdecf0483`; the result JSON's `sim_log_sha256` matches the copied simulator log.

After commit `b39f737` preserved this evidence, the completed remote `output/` tree was removed at 23:41 MDT, freeing 375,765,215 bytes. The run-level status, resource, provenance, version metadata, and Slurm wrapper log remain on DAN-DESKTOP.
