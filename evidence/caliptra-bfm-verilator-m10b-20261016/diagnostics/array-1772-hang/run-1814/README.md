# Uninstrumented sanity row, job 1814

Host: `DAN-DESKTOP`. Single selected row `smoke_test_ahb_mux` (`cadf43c78de6a454`), built with assertions enabled and the production overlay without trace instrumentation. Slurm allocated 1 CPU and 3 GiB; the wrapper applied a 600-second outer cap.

Outcome: **PASS**. `firmware_exit=0`, `sim_exit=0`, `sim_elapsed_s=2.712`, and total wrapper time was 4.877 seconds. `sim.log` contains `* TESTCASE PASSED` and `Finished : minstret = 582, mcycle = 3973`; the c339 baseline is also `PASS`, `mcycle=3973`. No AW, W, or B handshake assertion fires. The c339 wall-time baseline is unavailable, so no speedup is claimed for this pilot.

Model SHA-256: `430fcb1ee9fea6f76ce3efc7c8fe7efa3150d7d338315858776c7836e1baf7e0`. Uninstrumented overlay SHA-256: `e8fec740da3fb9ffcd72fd7eb72c63480d30bd4de531e390772138dcf9ad6d1a`.

The archive preserves the result JSON, logs, resource reports, per-file checksums, and Slurm output. Archive SHA-256: `edf47e2bc0027372e42df4674fe7c671555d2b9abe863774b8667208d90f67dd`.
