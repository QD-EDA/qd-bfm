# DOE top-level reset-guard gate (local diagnostic)

This one-row gate tested the checker-only candidate on `smoke_test_doe_scan` (`8f9e58bda7a24230`) with a 600-second `localrun` cap. QD-BFM was pinned at `ffc12ab427e961f40354f32a8e7a147e5d4e5764`, Caliptra RTL at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and the M10b AXI overlay at `d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`.

**Result: FAIL.** Firmware printed `TESTCASE PASSED` at `mcycle=62260`, but the simulation log contains one DOE assertion error, so the runner correctly reports `FAIL`. `sim_exit=0`, `firmware_exit=0`, simulation time was 424.028 seconds, total run time 432.67 seconds, and peak RSS was 61,997,056 bytes. The preserved raw result is in [`gate-results/8f9e58bda7a24230/`](gate-results/8f9e58bda7a24230/).

The candidate added `~CPTRA_TOP_PATH.cptra_rst_b` to this property's `disable iff`, with a failure-only trace. It still fails at `time=24464000`; the trace reports previous/current top-level and DOE resets high, `clear_obf_secrets` changing 1→0, and DOE `VALID` and `DEOBF_SECRETS_CLEARED` changing 1→0. The reset guard alone does not resolve the reset-release sequence. This candidate is not validated and is excluded from the M12 pass count.

Verilator reports version 5.052, but this local binary was built from the pinned v5.052 source with a build-only Flex `yy_create_buffer` declaration compatibility patch (`verilator-build-compat.patch`, SHA-256 `de9c45bb15ccaead1b511c31c8b64149bf0dff4cb42e6646c7e9a31c9093ff21`). The DOE property and testbench were built with assertions enabled; no RTL, firmware, or pass criteria were changed.
