# MBOX AR assertion-sample trace (job 2064)

This one-row diagnostic used `smoke_test_mbox` (`78bfcc1e9aac255e`) with the pinned Caliptra RTL and the M11 overlay, plus a private `axi_sub_rd.sv` assertion action that prints `$sampled` operands. No operational RTL, official overlay, firmware, or pass criteria changed.

- Host: DAN-DESKTOP; Verilator 5.052 with `--assert` and `CLP_ASSERT_ON`.
- Model SHA-256: `14ab5f899e2686a459fdbf470f18e5a3b10a4e22b7c00d53c39548add620422b`.
- Cap: 600 seconds for one simulation; actual simulation time was 39.547 seconds and total task time 41.970 seconds. The cap was not reached.
- Firmware build: exit 0. Simulation: exit 1, `AXI_SUB_AR_HSHAKE_ERR` at time 5,718,000. This diagnostic is a failure, not a firmware result.

At cycle 57149/time 5,717,000, the instance-qualified `#1step` monitor saw mailbox-lock address `0x00020000` with `ARVALID=1`, `ARREADY=0`, reset high; post-edge values were `ARVALID=0`, `ARREADY=0`. At the assertion action's failure edge/time 5,718,000, `$sampled` printed `ARVALID=0`, `ARREADY=1`, `rst_n=1`. Together these confirm a valid-drop sequence without reset during the assertion window. They do not identify why the BFM withdrew `ARVALID` or prove that the separate RDATA sampling race caused this failure.

The copied raw result files passed `FILE-SHA256SUMS`; `sim.log`, `result.json`, resource reports, firmware log, native-vector logs, and Slurm output are under [`raw/job-2064/`](raw/job-2064/). The simulation's assertion failure and c339 PASS are also summarized in the [local issue draft](../../issue-drafts/mbox-first-read-sampling-race.md). No upstream issue was posted. After checksum verification, the completed remote run directory was removed; its recorded size was 727,940,700 bytes.
