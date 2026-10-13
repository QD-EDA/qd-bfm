# M5b heartbeat smoke verification

A fresh one-test job repeats `smoke_test_kv` with the M5b runner commit and pinned c339 toolchain. It is submitted after job 669 (`afterany:669`) so it cannot overlap the six still-running old VVPs. The job requests one CPU and 3 GiB, has a 6h10m allocation, and applies the row's 9,073-second timeout with SIGINT and a 60-second kill grace.

The check records the firmware verdict separately from whether the flushed mcycle heartbeat appears in `sim.log`; heartbeat telemetry does not affect firmware PASS criteria. The staged QD source commit and file hashes are in `source-snapshot.txt`.

Job 669 drained at about 01:19 MDT on 2026-10-13, and job 785 then started from its `afterany:669` dependency. At 01:22 MDT it had emitted two flushed heartbeats (`wall_s=0, mcycle=0`; `wall_s=300, mcycle=1722`), but had not yet written `result.json` or a testcase PASS marker. This shows forward progress; the firmware verdict remains pending. The protected source snapshot is commit `d1d358e92ea47eacbcdefd58266f7563682400f3`; script SHA-256 and run root are in `submission.txt`.
