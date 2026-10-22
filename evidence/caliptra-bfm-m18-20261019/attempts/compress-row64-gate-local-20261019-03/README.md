# M18 row 64 compressor gate on refreshed Icarus main

Ran the authored `compress_normal_test` at Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` with Icarus source `cae035642e056644274a01e98d4422ce286685b4`. The Mac binary SHA-256 is `3039f3a706ecad191020170096f782c7b5b7a5776e72aa978ac04094daeae7e2`; `vvp` SHA-256 is `81d85816e4ced18dfcfed5f6658ba3a08e4662ff827879e62c617da7a25b9ef5`.

Result: `PASS` in 0.538 s of simulation. The log shows all three modes (d=1,5,11), no mismatch, and the original `* TESTCASE PASSED` marker. Captured output lengths were checked against 1024, 5120, and 11264 bits and every packed coefficient was compared with the pinned bench's unchanged `coeff_exp` formula. The row used a 600-second test cap and a 1200-second localrun cap; the local wrapper completed in 1.23 s with 26,181,632-byte peak RSS.

The testbench-only overlay maps the old ports to the current API bus, models one-cycle coefficient reads from the test's original vector, holds the requested address during DUT backpressure, and samples `compress_done` at rising edges. The clock-sampled wait is needed because the DUT's combinational done output can pulse during the separate busy/read-state NBA updates. No RTL, firmware, expected values, or pass markers changed.

Host: `MacBook-Air.local`, macOS 27.0 arm64. Icarus source pin, platform-specific binary hashes, Caliptra/Adams Bridge pins, and source-file hashes are in `raw/run-info.txt` and `source-files.sha256`. The result archive is `raw/job-local.tar.gz`; its adjacent SHA-256 was verified. Ask-intern's triage of the simulation log was independently checked against the raw log.
