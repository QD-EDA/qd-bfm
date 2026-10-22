# M11: Caliptra stock-firmware Verilator run

M11 covers the 162 `stock-firmware-test-suite` rows only. The 109 authored/generated-UVMF tests remain outside this run; block-level UVM stays on Icarus. The default top-level flow is documented in the repository [README](../../README.md).

## Pins and overlay

- QD-BFM source: `ffc12ab427e961f40354f32a8e7a147e5d4e5764`.
- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Verilator: 5.052, assertions enabled.
- Build-time `axi_if.sv` overlay: `d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1`.
- Rows reused from array 1835 use model `2fd1bdfde761a04ea5905384badcb3a927677545e383368a42c77f978d6659a3`; the fresh build for array 1964 is `3c4d5541ff5f8e8642d0017a414fcf1b216467703b62aaf98df5d7ffd14efb1f`. Both use the same overlay source hash. The new binary passed its own 600-second one-row gate before array 1964 started.

## Final results

The closed M9 stock-firmware manifest contributes exactly 162 unique test IDs and names. All 103 completed overlay-v2 rows from array 1835 and all 59 terminal array-1964 rows are in [`remaining-59/final-162-results.tsv`](remaining-59/final-162-results.tsv), including overlay outcome, final mcycle where available, wall time, prior Icarus c339 result, model hash, and evidence path.

Final outcomes: 84 PASS, 63 FAIL, 14 FIRMWARE_BUILD_FAIL, and one TIMEOUT (78 non-PASS). The per-row cause groups and all 32 terminal c339 outcome differences are indexed in [`cause-groups.md`](cause-groups.md). Row 152, `smoke_test_mbox_cg`, reached the testbench's explicit 20,000,000-cycle limit after the BFM requested the mailbox lock; it has no final mcycle or firmware-pass marker and no verified c339 result. The archived log and exact result JSON are in [`remaining-59/final-row-1964_54/raw/`](remaining-59/final-row-1964_54/raw/).

Collection 01 includes 12 `FIRMWARE_BUILD_FAIL` and 35 `FAIL` rows, all with checksum-verified logs. The failure classes and archive/cleanup record are in [`remaining-59/README.md`](remaining-59/README.md). The `smoke_test_mbox` AR assertion is separately traced: the instance-qualified monitor captured `ARVALID=1, ARREADY=0` then a valid drop, and the v4 assertion action printed its `$sampled` values at the failure edge. The first-read issue draft remains local for user review.

## Review drafts and #600 rerun

The AXI edge-sampling, mailbox, DOE assertion, SHA512 ZEROIZE, high strap-size, ECC key/seed stability, AXI DMA/AES error-sync, MLKEM key-vault, and LMS DCCM-bound reports are local issue drafts for user review; none has been posted upstream. The current-main `butterfly_top_tb` rerun is documented [here](../caliptra-bfm-m7-rebaseline-20261014/repro-butterfly-vvp-null-head/post-main-631b7a869-20261016/README.md). The #600 event-wait abort did not recur; the overall bench failed because the current testbench loads its output vector into the input array.
