# Draft: AXI BFM reads handshake signals after the sampling edge

**Status:** Local draft for user review only; not posted.

## Summary

The pinned Caliptra `src/axi/rtl/axi_if.sv` BFM drives AXI controls, waits for `@(posedge clk)`, then reads live READY/VALID or RDATA in the active task process. Concurrent protocol assertions sample at the edge before those live values update. The BFM and assertion can therefore disagree about whether a handshake occurred and what read data was accepted.

The M11 `smoke_test_mbox` rerun (c339 PASS, overlay FAIL) reported `AXI_SUB_AR_HSHAKE_ERR` at 5,718,000 after the SoC BFM requested the mailbox lock. The v3 instance-qualified `#1step` trace at the exact assertion instance sampled mailbox-lock address `0x00020000`, `ARVALID=1`, `ARREADY=0`, and reset high at cycle 57149/time 5,717,000; the post-edge live values were `ARVALID=0`, `ARREADY=0`. This confirms the property antecedent's valid-drop sequence on the subordinate interface. The BFM-task clocking-block trace has a phase-offset sample and is not sufficient to identify the cause. V4 replaces the diagnostic copy of the assertion macro call with an equivalent property whose failure action prints `$sampled` operands. At the failure edge, it reports `ARVALID=0`, `ARREADY=1`, and `rst_n=1`, confirming the assertion sample and that reset did not mask the sequence; it does not explain why the BFM withdrew `ARVALID`. See [job 2055](../diagnostics/mbox-ar-trace-20261017-03/raw/job-2055/) and [job 2064](../diagnostics/mbox-ar-trace-20261017-04/README.md).

Array 1835 also reports `AXI_SUB_R_HSHAKE_ERR` for `smoke_test_sram_ecc` (`42f2671ec114cfb5`): the assertion checks that `RVALID` stays high until `RREADY` is observed. Its current `sim.log` confirms the response-channel failure, but this row has no focused edge trace.

## Evidence

On Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052 with `--assert` and `CLP_ASSERT_ON` reported `AXI_SUB_AW_HSHAKE_ERR` before a firmware result on the pinned smoke selection. One-row traces show the AW/W/B edge disagreements; the corrected local overlay drives those channels nonblocking, waits on `posedge clk`, and reads clocking-block inputs sampled with `#1step`. The traced `smoke_test_ahb_mux` then reached the first fuse write and firmware PASS at `mcycle=3973`; the v2 overlay also passed its 600-second gate. Exact records are in the [M10b diagnostic summary](../../../caliptra-bfm-verilator-m10b-20261016/README.md) and [first-fuse trace record](../../../caliptra-bfm-verilator-m10b-20261016/diagnostics/array-1772-hang/run-1812/README.md).

## Expected behavior

The BFM should decide transfers and capture read data from values sampled for the same rising edge as the protocol checker. A compatibility overlay should not be required to make an assertion-enabled simulation advance through a legal handshake.
