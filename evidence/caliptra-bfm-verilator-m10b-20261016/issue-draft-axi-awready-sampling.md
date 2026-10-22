# Draft issue: AXI BFM samples ready/valid after the handshake edge

**Status:** local draft only; not posted upstream.

## Summary

The Verilator-specific AXI BFM in the pinned Caliptra `src/axi/rtl/axi_if.sv` drives AR/AW/W/B controls with blocking assignments, waits on `@(posedge clk)`, then evaluates live `arready`, `awready`, `wready`, or `bvalid` after the edge. That can read a value updated after the edge rather than the value sampled for that edge. A concurrent protocol assertion samples in the preponed region, so the task and assertion can disagree about whether VALID was accepted before the BFM deasserts it or advances the response.

## Reproduction

On Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, build the top-level firmware model with Verilator 5.052, `--assert`, and `CLP_ASSERT_ON`, then run the assertion-enabled firmware selection. The pinned run failed before a firmware result on 102 of 103 rows at `AXI_SUB_AW_HSHAKE_ERR`; the remaining row stopped at the unrelated `SS_STRAP_KEY_SIZE_LTE_64` assertion. With AW-only adjusted, the one-row trace then failed at `AXI_SUB_W_HSHAKE_ERR`; with AW/W adjusted, it next failed at `AXI_SUB_B_HSHAKE_ERR` on the first fuse write. The AW/W/B overlay reached firmware PASS and traced the first fuse write at AW address `0x30200` through its B handshake (jobs 1811–1814). The next assertion-enabled array using that overlay exposed `AXI_SUB_AR_HSHAKE_ERR` in two rows at 32 ns. See `diagnostics/array-1772-hang/run-1806/`, `run-1809/`, and `array-1816-partial/`.

## Expected behavior

The master BFM should decide whether AR/AW/W transferred from READY and B transferred from VALID values sampled at the same rising edge, matching the protocol assertion's sampling region. The local build-time overlay applies nonblocking drives and posedge clocking-block samples using `#1step` to the affected BFM channels; it changes no RTL, firmware, assertion, or pass criterion. The follow-on AR overlay passed its one-row validation; the full selection is still being checked.

## Current validation state

The AW/W/B trace reached firmware PASS on the first fuse-bank write (job 1812). The AR/AW/W/B overlay then passed the 600-second `smoke_test_ahb_mux` gate (job 1834, `mcycle=3973`). The full 103-row array (job 1835) is still running; the latest archived snapshot has 83 terminal rows, with 66 PASS and 17 FAIL. No overlay failure in that snapshot has an Icarus PASS baseline, so a simulator-only RTL/assertion disagreement is not established.
