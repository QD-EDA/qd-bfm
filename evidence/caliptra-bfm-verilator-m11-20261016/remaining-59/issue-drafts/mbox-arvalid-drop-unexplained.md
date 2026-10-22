# Separate diagnostic note: MBOX ARVALID drop remains unexplained

**Status:** Local diagnostic note only; not an upstream draft. Keep this separate from the verified RDATA sampling race.

On pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, assertion-enabled Verilator 5.052 reports `AXI_SUB_AR_HSHAKE_ERR` in `smoke_test_mbox` at time 5,718,000. At cycle 57149/time 5,717,000, the instance-qualified `#1step` trace sampled the mailbox-lock address `0x00020000` with `ARVALID=1`, `ARREADY=0`, and reset high; after the edge, `ARVALID=0`, `ARREADY=0`. At the failure edge, the diagnostic assertion action printed `$sampled(ARVALID)=0`, `$sampled(ARREADY)=1`, and `$sampled(rst_n)=1`.

This confirms the assertion's sampled valid-drop sequence and that reset did not disable the property. It does not establish why the BFM withdrew `ARVALID`, nor that the separately verified RDATA race caused this failure. Both c339/Verilator status and the focused raw trace are documented in [job 2064](../diagnostics/mbox-ar-trace-20261017-04/README.md); the initial interface trace is in [job 2055](../diagnostics/mbox-ar-trace-20261017-03/README.md).
