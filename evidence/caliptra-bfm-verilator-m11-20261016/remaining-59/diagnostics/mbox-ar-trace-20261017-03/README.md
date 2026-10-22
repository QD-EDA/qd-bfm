# M11 MBOX assertion-boundary trace

This diagnostic captures `ARVALID`, `ARREADY`, address, and reset at the `axi_sub_rd` instance that owns `AXI_SUB_AR_HSHAKE_ERR`, alongside the interface clocking-block and post-edge values. It is limited to the mailbox lock address `0x00020000`. It runs only `smoke_test_mbox` with a 600-second simulation cap and leaves the official overlay unchanged.

Target: `smoke_test_mbox` (`78bfcc1e9aac255e`), c339 PASS versus M11 overlay FAIL. Inputs are copied from M11 run 1964: QD-BFM commit `ffc12ab427e961f40354f32a8e7a147e5d4e5764`, Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052 with assertions.

The v2 interface monitor captured only `ARVALID=1, ARREADY=1` around deassertion, but did not identify which interface instance produced each line. This version adds an instance-qualified monitor at the assertion's `s_axi_if` boundary so the cause can be classified from the same subordinate interface.

## v3 result (job 2055)

The model built as job 2053 and the one-row simulation completed as job 2055. Firmware compilation passed; the simulation failed at 5,718,000 (40.102 seconds) with `AXI_SUB_AR_HSHAKE_ERR`. The exact assertion instance sampled mailbox-lock address `0x00020000` with `ARVALID=1`, `ARREADY=0`, and reset high at cycle 57149/time 5,717,000; its post-edge values were `ARVALID=0`, `ARREADY=0`. This directly matches the assertion's valid-drop-after-not-ready antecedent. The assertion then failed at 5,718,000.

This confirms a real sampled handshake-rule violation in the overlay run. It does not yet identify which RTL/BFM scheduling or driver behavior causes the valid drop, and the separate interface monitor's clocking-block cycle count is phase-offset. The next focused trace should print `$sampled` operands from the assertion action itself. Raw job-2055 output and resource logs are archived under `raw/job-2055/`; all entries in `FILE-SHA256SUMS` verified against the archived files. The completed remote run tree was removed after archival.
