# Local DOE reset-release diagnostic (Mac)

Host: MacBook-Air.local, macOS 27.0 arm64. QD-BFM source is pinned at `ffc12ab427e961f40354f32a8e7a147e5d4e5764`; Caliptra RTL is `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Verilator reports `5.052 2026-09-05 rev v5.052` from upstream tag commit `ea338be98e1e838d3518809ce8899f85a009963c`. To build that tag on this Mac, a local build-only header patch changed Flex's `yy_create_buffer` declaration from `int` to `size_t`, matching the generated scanner; patch SHA-256 is recorded here. No Verilator source was changed in the project repository.

The assertion-enabled model uses `--assert`, `CLP_ASSERT_ON`, and the pinned M10b AXI overlay (`d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`). Model SHA-256: `1acdba86496a7b08c64498f9c0da359d1233c77c76b58f90587cc540fec9bfb0`. The checker overlay changes only the DOE assertion failure action to print prior/current reset, clear, and status values; its SHA is in `doe-trace-manifest.txt`.

Row `smoke_test_doe_scan` (`8f9e58bda7a24230`) ran with a 600-second `localrun` cap. Firmware passed at `mcycle=62,260`, but the row remains **FAIL** because the DOE SVA fired once. Simulation took 358.43 seconds; the outer wrapper took 367.26 seconds and reported 62,767,104 bytes peak RSS. The `localrun` resource report is preserved in `task.resource`.

At the failing sample (`time=24464000`), the trace shows `prev_clear=1`, `prev_valid=1`, `prev_deobf=1`, then `now_clear=0`, `now_valid=0`, `now_deobf=0`; sampled `cptra_rst_b` and `DOE_PATH.rst_b` are high in both samples. The log shows `cptra_rst_b` asserted at cycle 244628 and deasserted at 244638 immediately before the error. This supports an outstanding DOE-status assertion crossing a top-level reset pulse that the current `disable iff (~DOE_PATH.rst_b)` does not cover. The next candidate adds the top-level reset to that guard. The exact `cptra_noncore_rst_b`/`cptra_pwrgood` reset edge at the failing sample is not captured in this trace.

`gate-results/8f9e58bda7a24230/` preserves the result JSON, simulation/firmware/preflight logs, and native vector logs. Its file checksums are in `FILE-SHA256SUMS`.
