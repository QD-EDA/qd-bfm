# M11 non-PASS cause groups and c339 disagreements

Final classification for all 162 stock-firmware rows. Per-row outcomes, IDs, mcycle, wall time, and evidence paths are in [`remaining-59/final-162-results.tsv`](remaining-59/final-162-results.tsv).

## Non-PASS groups

The 162 terminal rows contain 78 non-PASS results: 63 simulation `FAIL`, 14 `FIRMWARE_BUILD_FAIL`, and one `TIMEOUT`. Each row maps to one group below. “Confirmed” describes the recorded first-failure mechanism; where traces are missing, the RTL/testbench condition causing that signature remains unresolved and is called out explicitly.

| Group | Rows | Confirmed first-failure mechanism and limits |
|---|---:|---|
| `FW-BUILD` | 14 | Firmware compilation or link fails before simulation. Per-row diagnostics and the distinct compiler/linker errors are listed in [`remaining-59/firmware-build-failures.md`](remaining-59/firmware-build-failures.md). |
| `LMS-DCCM-BOUNDS` | 34 | `$readmemh` rejects the DCCM preload range with “file address beyond bounds of array.” The generated `dccm.hex` files were not retained, so image size versus preload-range/index mismatch is unresolved; see the [LMS draft](remaining-59/issue-drafts/lms-dccm-readmem-bounds.md). |
| `SIM-MAX-CYCLE-20M` | 5 | The testbench reaches its explicit 20,000,000-cycle watchdog in `caliptra_top_tb_services.sv:2408`, before a firmware result. The final firmware phase is preserved in each log, but its completion is not established. |
| `JTAG-TAP-MBOX` | 1 | `jtag_tap_mbox` reaches the 20M-cycle watchdog while writing its ROM-to-TAP mailbox payload. Its root cause is the already-closed M9/#13 diagnosis; this record reuses that result without reopening it. |
| `DMA-READ-RETURN-UB` | 1 | `smoke_test_dma.c:319` tests `soc_ifc_axi_dma_read_mbox_payload` as a boolean, but the `uint8_t` helper at `soc_ifc.c:464-467` falls off the end without returning. The persistent `fail` flag is observed at the later test fatal after reset. The run does not record the helper's returned byte, so the exact runtime value is unavailable. |
| `DMA-AES-STATE` | 2 | `AXI_DMA_AES_FSM_ERR_SYNC` fails at `axi_dma_ctrl.sv:1497` during injected AXI-error tests. The assertion’s required state relation is the confirmed terminal condition; the two FSM values and transition history were not captured. See the [draft](remaining-59/issue-drafts/axi-dma-aes-error-sync.md). |
| `ECC-PRIVKEY-STABILITY` | 7 | `ERR_ECC_PRIVKEY_NOT_STABLE` fires at `ecc_dsa_ctrl.sv:1014`. The archived logs confirm the property failure; they do not show which permitted or unexpected register transition triggered it. See the [draft](remaining-59/issue-drafts/ecc-keyseed-stability-assertions.md). |
| `ECC-SEED-STABILITY` | 2 | `ERR_ECC_SEED_NOT_STABLE` fires at `ecc_dsa_ctrl.sv:1015`. As above, the assertion signature is confirmed but the edge-level trigger was not captured. See the [draft](remaining-59/issue-drafts/ecc-keyseed-stability-assertions.md). |
| `SHA-BLOCK-STABILITY` | 4 | `ERR_SHA_BLOCK_NOT_STABLE` terminates the row. A focused trace confirms `smoke_test_sha512` clears the block during ZEROIZE while the property does not exempt ZEROIZE; the other three rows share the signature but were not independently traced. See the [draft](remaining-59/issue-drafts/sha512-zeroize-assertion-guard.md). |
| `MLKEM-KV-COMPARE` | 2 | `KV_MLKEM_CHECK0` reports a key-vault byte comparison mismatch at `caliptra_top_tb_services.sv:993`. The archived log does not include the byte index or actual/expected values. See the [draft](remaining-59/issue-drafts/mlkem-keyvault-check.md). |
| `AXI-R-HANDSHAKE` | 1 | `AXI_SUB_R_HSHAKE_ERR` reports that the read response valid signal was withdrawn before ready. No focused edge trace was captured; see the [AXI sampling draft](remaining-59/issue-drafts/axi_if-ready-valid-edge-sampling.md). |
| `STRAP-ASSERTION-GUARD` | 1 | The selected YAML intentionally randomizes strap size above `0x40`, while the Verilator build leaves `SS_STRAP_KEY_SIZE_LTE_64` active. The testbench guard mismatch is confirmed; see the [draft](remaining-59/issue-drafts/strap-size-assertion-guard.md). |
| `MBOX-AR-HANDSHAKE` | 1 | `AXI_SUB_AR_HSHAKE_ERR` reports ARVALID withdrawn after a not-ready sample. The instance-qualified trace observed address `0x00020000`, `ARVALID=1, ARREADY=0`, then `ARVALID=0`; the v4 assertion action sampled `ARVALID=0, ARREADY=1, rst_n=1` at failure time 5,718,000. The exact BFM scheduling cause remains unresolved; see the [mailbox draft](remaining-59/issue-drafts/mbox-first-read-sampling-race.md). |
| `DOE-STATUS-AFTER-CLEAR` | 1 | DOE status assertion fires after obfuscation clear. The pinned assertion source documents a reset-deassertion timing corner, but this run did not capture whether the clear remained asserted through that edge; see the [draft](remaining-59/issue-drafts/doe-status-after-obf-clear.md). |
| `RESULT-SCAN-FALSE-POSITIVE` | 1 | Firmware prints PASS and exits successfully, but the runner’s broad `ERROR` scan counts the expected `error=0x1` text as a failure. This is a confirmed result-scanner false positive. |
| `SS-DMA-FIFO-STALL` | 1 | `cptra_ss_test_rom` times out during its AHB payload transfer. The confirmed M9 root cause is the DMA stall at FIFO word 15; M11 reused that closed diagnosis without re-auditing it. See the [M9 root-cause record](../caliptra-bfm-verilator-m9-20261016/root-causes.md) and this row's [archived log](remaining-59/completed-1964-02.tar.gz). |

The group memberships are:

- `DMA-AES-STATE`: `smoke_test_dma_aes_gcm_wr_enc_axi_err`, `smoke_test_dma_aes_gcm_rd_enc_axi_err`.
- `ECC-PRIVKEY-STABILITY`: `smoke_test_ecdh`, `smoke_test_pcr_zeroize`, `smoke_test_ecc_errortrigger1`, `smoke_test_ecc_errortrigger2`, `smoke_test_ecc_errortrigger3`, `smoke_test_pcr_signing`, `smoke_test_ecc_sign`.
- `ECC-SEED-STABILITY`: `smoke_test_kv_swwe_lock`, `smoke_test_ecc_keygen`.
- `SHA-BLOCK-STABILITY`: `smoke_test_sha512_restore`, `pv_hash_and_sign`, `pv_hash_zeroize`, `smoke_test_sha512`.
- `MLKEM-KV-COMPARE`: `smoke_test_mlkem_locked_api`, `smoke_test_mlkem_kv`.
- `AXI-R-HANDSHAKE`: `smoke_test_sram_ecc`.
- `STRAP-ASSERTION-GUARD`: `smoke_test_dma_aes_kv` using `smoke_test_dma_aes_kv_large.yml`.
- `LMS-DCCM-BOUNDS`: the 32 LMS rows in [`remaining-59/batch-01-results.tsv`](remaining-59/batch-01-results.tsv), plus `fw_test_lms_n32_w1_h5` and `fw_test_lms_n32_w2_h10` in [`remaining-59/batch-04-results.tsv`](remaining-59/batch-04-results.tsv).
- `SIM-MAX-CYCLE-20M`: `infinite_loop`, `smoke_test_mldsa_sign_rnd`, `randomized_pcr_ecc_signing`, and `smoke_test_kv_parallel_access` in [`remaining-59/batch-04-results.tsv`](remaining-59/batch-04-results.tsv), plus `smoke_test_mbox_cg` in [`remaining-59/final-162-results.tsv`](remaining-59/final-162-results.tsv).
- `JTAG-TAP-MBOX`: `jtag_tap_mbox` in [`remaining-59/batch-04-results.tsv`](remaining-59/batch-04-results.tsv); root cause reused from closed M9/#13.
- `DMA-READ-RETURN-UB`: `smoke_test_dma` in [`remaining-59/batch-04-results.tsv`](remaining-59/batch-04-results.tsv).
- `FW-BUILD`: `smoke_test_uart` in [`remaining-59/batch-03-results.tsv`](remaining-59/batch-03-results.tsv) and `smoke_test_kv_crypto_flow2` in [`remaining-59/batch-04-results.tsv`](remaining-59/batch-04-results.tsv). The closed M9 disagreement record confirms the same 12 undefined UART macros in c339, so UART is a result-label difference rather than a different build cause.
- `SS-DMA-FIFO-STALL`: `cptra_ss_test_rom` (`f1991acb7ebadfe1`), with c339 and overlay both timing out.
- `MBOX-AR-HANDSHAKE`: `smoke_test_mbox`.
- `DOE-STATUS-AFTER-CLEAR`: `smoke_test_doe_scan`.
- `RESULT-SCAN-FALSE-POSITIVE`: `smoke_test_kv_lock_use_mid_read`.

## c339 terminal disagreements

There are 32 terminal outcome differences among the 162 rows. This table assigns each to a cause group. The final row `smoke_test_mbox_cg` has no verified c339 result, so it adds no disagreement.

| Test | c339 → overlay | Cause group |
|---|---|---|
| `kv_entry_read_err` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_mbox_byte_read` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_datavault_basic` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_dma_aes_gcm_short_1_dword` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_kv_write_scan_mode` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_dma_aes_gcm_non_gcm_en_dec` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_ecc_verify` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_datavault_mini` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_hek_flow` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_aes_gcm` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_dma_aes_gcm_short_dword` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `iccm_lock` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_kv_securitystate` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_datavault_lock` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_dma_aes_gcm_collision_test` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_dma_aes_gcm` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `c_intr_handler` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_dma_aes_gcm_cmd_err` | TIMEOUT → PASS | `C339-TIME-CAP` |
| `smoke_test_dma_aes_gcm_wr_enc_axi_err` | TIMEOUT → FAIL | `DMA-AES-STATE` |
| `smoke_test_dma_aes_gcm_rd_enc_axi_err` | TIMEOUT → FAIL | `DMA-AES-STATE` |
| `smoke_test_ecc_errortrigger3` | TIMEOUT → FAIL | `ECC-PRIVKEY-STABILITY` |
| `smoke_test_kv_swwe_lock` | TIMEOUT → FAIL | `ECC-SEED-STABILITY` |
| `smoke_test_ecc_keygen` | TIMEOUT → FAIL | `ECC-SEED-STABILITY` |
| `smoke_test_ecc_sign` | TIMEOUT → FAIL | `ECC-PRIVKEY-STABILITY` |
| `smoke_test_sram_ecc` | TIMEOUT → FAIL | `AXI-R-HANDSHAKE` |
| `smoke_test_kv_lock_use_mid_read` | TIMEOUT → FAIL | `RESULT-SCAN-FALSE-POSITIVE` |
| `smoke_test_mbox` | PASS → FAIL | `MBOX-AR-HANDSHAKE` |
| `smoke_test_sha512` | PASS → FAIL | `SHA-BLOCK-STABILITY` (ZEROIZE trigger confirmed for this row) |
| `smoke_test_ecc_errortrigger4` | FAIL → FIRMWARE_BUILD_FAIL | `FW-BUILD` (same build-stage cause; result label differs) |
| `smoke_test_qspi` | FAIL → FIRMWARE_BUILD_FAIL | `FW-BUILD` (same build-stage cause; result label differs) |
| `smoke_test_uart` | FAIL → FIRMWARE_BUILD_FAIL | `FW-BUILD` (same 12 missing UART macros; result label differs) |
| `jtag_tap_mbox` | TIMEOUT → FAIL | `JTAG-TAP-MBOX` (M11 watchdog result; root cause reused from closed M9/#13) |

The 18 `TIMEOUT → PASS` rows reached firmware PASS under Verilator after c339’s recorded timeout; the row table retains each c339 wall limit. They are grouped as simulator/runtime-cap disagreements, not firmware failures. For `smoke_test_ecc_errortrigger4`, `smoke_test_qspi`, and `smoke_test_uart`, the c339 `FAIL` label and Verilator `FIRMWARE_BUILD_FAIL` refer to the same pre-simulation build stage; see the per-row diagnostics in the firmware-build list and the existing closed M9 comparison for UART.

## Final status

All 162 rows have terminal overlay outcomes. The 78 non-PASS rows are assigned to the groups above, and all 32 c339 terminal disagreements are listed. The unresolved details above remain explicitly qualified; no upstream issue was posted.
