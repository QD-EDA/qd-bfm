# M9 terminal FAIL classification

This ledger covers the 43 stock-firmware rows whose final Verilator result is `FAIL`. Each row is assigned once. The 14 `FIRMWARE_BUILD_FAIL` and two `TIMEOUT` rows are separate outcome classes and are not included here.

## DCCM image-loader bounds (34)

All 34 rows stop before firmware execution with `$readmem` reporting an address beyond the target array. The pinned testbench calls `$readmemh("dccm.hex", dummy_dccm_preloader.ram, 0, RV_DCCM_EADR-RV_DCCM_SADR)` at line 2579. Representative evidence is `runs/8c392993b1af6e0c/`; the individual generated hex was removed after result collection, so the offending address is not retained.

Rows:
- `8c392993b1af6e0c` — `fw_test_lms32`
- `e5e18eb8f20efc5f` — `fw_test_lms_n24_w8_h20`
- `bc3ce0773f27b4b2` — `fw_test_lms_n32_w2_h15`
- `32fd8dbe1f783dd4` — `fw_test_lms_n24_w8_h10`
- `415642c79c0b7644` — `fw_test_lms_n24_w4_h10`
- `f740e445978756c4` — `fw_test_lms_n24_w1_h20`
- `2f208e5a8bd69c61` — `fw_test_lms_n24_w1_h5`
- `34c7f9d19c8079cd` — `fw_test_lms_n32_w1_h10`
- `cdfafa2fe78a1b8f` — `fw_test_lms_n32_w2_h20`
- `1dd7e7b6a72b9fa9` — `fw_test_lms_n24_w4_h15`
- `4eb08645576768aa` — `fw_test_lms_n32_w4_h5`
- `3a5ea4e3a4522cbd` — `fw_test_lms_n32_w4_h10`
- `c68ca7ca8bdee9eb` — `fw_test_lms_n24_w8_h5`
- `3e372ffbd571a6c7` — `fw_test_lms_n24_w2_h15`
- `382735897db9fc23` — `fw_test_lms_n32_w1_h20`
- `5b0c6004da878938` — `fw_test_lms_n32_w8_h15`
- `f357834a5cc31406` — `fw_test_lms_n32_w8_h20`
- `d9d8c4e06a47cf5c` — `fw_test_lms_n32_w1_h15`
- `865fa7ef18ae19cf` — `fw_test_lms_n24_w2_h10`
- `5b9446fd36d612e3` — `fw_test_lms_n24_w8_h15`
- `42ee901b77bb2871` — `fw_test_lms_n32_w8_h5`
- `6e0f9924e43386cd` — `fw_test_lms24`
- `f1de3422b40f8fa8` — `fw_test_lms_n24_w4_h5`
- `52db40b9b86d1f5b` — `fw_test_lms_n24_w4_h20`
- `fc1a36f2d1524343` — `fw_test_lms_n32_w8_h10`
- `7fd0f83fb5074d59` — `fw_test_lms_n24_w2_h20`
- `363ea4266c0a87aa` — `fw_test_lms_n32_w2_h5`
- `bce6c86a752d75fe` — `fw_test_lms_n24_w2_h5`
- `d52c84ca080b3037` — `fw_test_lms_n32_w4_h15`
- `22ba61d343ff96c2` — `fw_test_lms_n24_w1_h10`
- `73de10235f92435f` — `fw_test_lms_n24_w1_h15`
- `c0866089be6265aa` — `fw_test_lms_n32_w4_h20`
- `bc539264d9dd07ff` — `fw_test_lms_n32_w1_h5`
- `29a997acc9f713cc` — `fw_test_lms_n32_w2_h10`

## 20-million-cycle testbench guard (5)

Five rows reach the shared `MAX_CYCLES` guard in `caliptra_top_tb_services.sv:2408`; the testbench emits a fatal and finishes before a firmware result marker. This is a harness ceiling result, not a per-row simulator crash. The named `infinite_loop` case is expected to exercise nontermination.

Rows:
- `7d123347fca44dd0` — `infinite_loop`
- `9dea5b9b42b8176b` — `smoke_test_mldsa_sign_rnd`
- `5ba3459d20156034` — `randomized_pcr_ecc_signing`
- `d39c57745790b3e2` — `smoke_test_kv_parallel_access`
- `79b6f2f02c78683d` — `smoke_test_mbox_cg`

## Missing JTAG Tcl client (1)

The wrapper starts the full-top model but not `jtag_tap_mbox.tcl`, which is required to service DMI mailbox requests and write the terminal byte. The row hits the same cycle guard. This is QD wrapper coverage issue #13, documented in `root-causes.md`.

Rows:
- `3439695c6637d6f2` — `jtag_tap_mbox`

## DOE status checker failure (1)

The DOE checker reports `DOE STATUS valid bit not set after clear obf secrets cmd`, while firmware also prints a pass marker. The checker failure controls the FAIL result. Its prior Icarus result is unverified, so the RTL-versus-checker source is not adjudicated.

Rows:
- `8f9e58bda7a24230` — `smoke_test_doe_scan`

## Firmware-reported DMA test failure (1)

The pinned `smoke_test_dma` firmware reaches its post-reset short-transfer sequence and prints `smoke_test_dma failed!`, which triggers the top testbench failure marker. The retained log has no per-word mismatch or specific helper error, so the exact `fail`-flag assignment is not isolated; no simulator defect is inferred.

Rows:
- `9fab7c30fc8d76ba` — `smoke_test_dma`

## Wrapper result-classifier false positive (1)

The firmware prints `* PASS` with the expected `error=0x1` status, exits zero, and the case-insensitive runner `ERROR|FATAL` scan counts the lowercase field twice, overriding the pass marker. This is known wrapper issue #12, documented in `root-causes.md`.

Rows:
- `5623a0f9b5e00f77` — `smoke_test_kv_lock_use_mid_read`
