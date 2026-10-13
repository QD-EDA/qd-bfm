# Terminal results preserved from top-level wave 1

These twenty-two Slurm runs ended at the configured per-test timeout with runner_exit=124 and are TIMEOUT (progress unknown). The first thirteen timeout logs lack a result JSON and terminal testcase marker; their last visible line does not establish where execution stopped. Rows 22–26, 29, 30, and 32–33 have their available per-task activity recorded below. Each directory contains raw status, provenance, tool hashes, resource reports, and available build/simulation logs.

| Row | Test | Verdict | Per-test timeout |
|---:|---|---|---:|
| 1 | `cptra_ss_test_rom` | TIMEOUT (progress unknown) | 6,873 s |
| 2 | `smoke_test_dma_aes_gcm` | TIMEOUT (progress unknown) | 7,004 s |
| 3 | `smoke_test_datavault_basic` | TIMEOUT (progress unknown) | 7,333 s |
| 5 | `smoke_test_dma_aes_gcm_rd_enc_axi_err` | TIMEOUT (progress unknown) | 7,628 s |
| 6 | `smoke_test_dma_aes_gcm_wr_enc_axi_err` | TIMEOUT (progress unknown) | 7,628 s |
| 7 | `smoke_test_kv_lock_use_mid_read` | TIMEOUT (progress unknown) | 7,956 s |
| 10 | `smoke_test_sram_ecc` | TIMEOUT (progress unknown) | 8,876 s |
| 13 | `smoke_test_hek_flow` | TIMEOUT (progress unknown) | 9,467 s |
| 15 | `smoke_test_dma_aes_gcm_non_gcm_en_dec` | TIMEOUT (progress unknown) | 10,091 s |
| 17 | `c_intr_handler` | TIMEOUT (progress unknown) | 10,813 s |
| 19 | `smoke_test_mbox_byte_read` | TIMEOUT (progress unknown) | 10,846 s |
| 20 | `smoke_test_dma_aes_gcm_collision_test` | TIMEOUT (progress unknown) | 11,010 s |
| 21 | `smoke_test_dma_aes_gcm_short_dword` | TIMEOUT (progress unknown) | 11,240 s |
| 22 | `smoke_test_kv_securitystate` | TIMEOUT (progress unknown) | 11,240 s |
| 23 | `smoke_test_datavault_lock` | TIMEOUT (progress unknown) | 11,601 s |
| 24 | `smoke_test_datavault_mini` | TIMEOUT (progress unknown) | 12,257 s |
| 25 | `smoke_test_aes_gcm` | TIMEOUT (progress unknown) | 13,210 s |
| 26 | smoke_test_dma_aes_gcm_short_1_dword | TIMEOUT (progress unknown) | 13,341 s |
| 29 | `jtag_tap_mbox` | TIMEOUT (progress unknown) | 15,212 s |
| 30 | `iccm_lock` | TIMEOUT (progress unknown) | 15,639 s |
| 32 | `smoke_test_ecc_keygen` | TIMEOUT (progress unknown) | 16,033 s |
| 33 | `smoke_test_ecc_sign` | TIMEOUT (progress unknown) | 16,033 s |

Row 22 reached its 11,240-second per-test limit after 3:07:20, with peak RSS 1,852,368 KiB. It has no `result.json` or testcase terminal marker; see [`task-22-smoke_test_kv_securitystate/`](task-22-smoke_test_kv_securitystate/).

Row 23 reached its 11,601-second per-test limit after 3:13:21, with peak RSS 1,852,440 KiB. It has no `result.json` or testcase terminal marker; see [`task-23-smoke_test_datavault_lock/`](task-23-smoke_test_datavault_lock/).

Row 24 reached its 12,257-second per-test limit after 3:24:17, with peak RSS 1,852,492 KiB. It has no `result.json`, testcase terminal marker, or finish record; see [`task-24-smoke_test_datavault_mini/`](task-24-smoke_test_datavault_mini/).

Row 25 reached its 13,210-second per-test limit after 3:40:10, with peak RSS 1,852,500 KiB. The compile log has warnings but no errors and the VVP output artifact exists; no result JSON, simulation log, testcase marker, or finish record was preserved. See [`task-25-smoke_test_aes_gcm/`](task-25-smoke_test_aes_gcm/).

Row 26 reached its 13,341-second per-test limit after 3:42:21, with peak RSS 1,852,348 KiB. The compile log has warnings but no errors and the VVP output artifact exists; no result JSON, simulation log, testcase marker, or finish record was preserved. Evidence is in [`task-26-smoke_test_dma_aes_gcm_short_1_dword/`](task-26-smoke_test_dma_aes_gcm_short_1_dword/).

Row 29, `jtag_tap_mbox`, reached its 15,212-second per-test limit after 4:13:32, with peak RSS 1,852,372 KiB. Its result JSON is absent and the simulator log has no testcase terminal marker. This run predates the heartbeat instrumentation, so progress is unknown. The compile log, VVP artifact metadata, status, provenance, resource report, and logs are in [`task-29-jtag_tap_mbox/`](task-29-jtag_tap_mbox/).

Row 8, `pv_hash_zeroize`, is a terminal `FAIL`: its result JSON reports `passed=false`, and the simulation ends on the pinned SHA-512 RTL assertion `ERR_SHA_BLOCK_NOT_STABLE`. The logs and raw wrapper status are in [`task-8-pv_hash_zeroize/`](task-8-pv_hash_zeroize/). This evidence records the RTL assertion failure and does not identify an Icarus defect.

Row 9, `smoke_test_uart`, is a terminal `FAIL`: its firmware C build reports undefined UART and UART-enable register symbols in the test source, which are absent from the generated register header at pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The full compiler log, source, copied header, exact hashes, and batch status are in [`task-9-smoke_test_uart/`](task-9-smoke_test_uart/); simulation did not start.

Row 11, `smoke_test_kv`, is a terminal `PASS`: its result JSON has `passed=true`, the runner reports `PASS`, and the simulation log contains `* TESTCASE PASSED`. The submitted array wrapper's raw status incorrectly says FAIL because it searched for `output/<case_dir>/result.json`, while the runner writes `output/result.json`. Both the raw wrapper status and the corrected evidence classification are in [`task-11-smoke_test_kv/`](task-11-smoke_test_kv/).

Row 12, `smoke_test_sha512`, is a terminal `PASS`: its result JSON has `passed=true`, its runner log reports `PASS`, and its simulation log contains `* TESTCASE PASSED`. Its raw wrapper false `FAIL` and corrected verdict are preserved in [`task-12-smoke_test_sha512/`](task-12-smoke_test_sha512/).

Row 14, `smoke_test_zeroize_crypto`, is a terminal `PASS`: its result JSON has `passed=true`, its runner log reports `PASS`, and its simulation log contains `* TESTCASE PASSED`. Its raw wrapper false `FAIL` and corrected verdict are preserved in [`task-14-smoke_test_zeroize_crypto/`](task-14-smoke_test_zeroize_crypto/).

Rows 0 and 4 have local TIMEOUT (progress unknown) evidence under ../local-fallback/.

Row 18, `smoke_test_doe_kv_ocp_progress`, is a terminal `PASS`: runner and task status report exit 0, result JSON reports `passed=true` with one pass and zero fail markers, and sim.log contains `* TESTCASE PASSED` (`mcycle=53552`). Wall time was 2:02:55 with 1,852,448 KiB maximum RSS. Nine entropy_src/csrng unique/priority-case warnings are preserved; the result reports `bad_diagnostics=0`. See [`task-18-smoke_test_doe_kv_ocp_progress/`](task-18-smoke_test_doe_kv_ocp_progress/).


Row 27, `smoke_test_qspi`, is a terminal firmware-build `FAIL`: its C source references QSPI register macros absent from the generated `caliptra_reg.h` at the pinned Caliptra revision. The runner exited 1 before simulation, and no testcase result was written. The compiler log, raw task status, resource report, tool provenance, source/header hashes, and exact missing-symbol evidence are in [`task-27-smoke_test_qspi/`](task-27-smoke_test_qspi/). This is an upstream firmware test/header mismatch, not an Icarus result.

Row 28, `smoke_test_dma_aes_kv_short`, is a terminal `PASS`: the task status and runner exit 0, result JSON `passed=true`, and one simulator testcase pass marker agree. It finished in 2:24:22 with peak RSS 1,852,464 KiB (`mcycle=60,133`). See [`task-28-smoke_test_dma_aes_kv_short/`](task-28-smoke_test_dma_aes_kv_short/).

Row 31, `smoke_test_ecc_errortrigger4`, is a terminal firmware-build `FAIL`: GCC reports implicit declarations for `service_abr_error_intr` and `service_abr_notif_intr` in pinned `caliptra_isr.c:754`; simulation did not start. The selected matrix test is `smoke_test_ecc_errortrigger4`, while its case directory and YAML path are `smoke_test_ecc_errortrigger5` and the YAML test name is `smoke_test_ecc_errortrigger4`. The raw status and compiler evidence are in [`task-31-smoke_test_ecc_errortrigger4/`](task-31-smoke_test_ecc_errortrigger4/).

Row 35, `smoke_test_ecc_errortrigger2`, is a terminal simulation `FAIL`: `result.json` reports `passed=false` and `sim_exit=1`; the simulator stopped on the pinned RTL assertion `ERR_ECC_PRIVKEY_NOT_STABLE` at `ecc_dsa_ctrl.sv:1081`. It ran for 2:33:31 with peak RSS 1,852,384 KiB. The raw result, simulator and firmware logs, status, provenance, and resource report are in [`task-35-smoke_test_ecc_errortrigger2/`](task-35-smoke_test_ecc_errortrigger2/).

Row 30, `iccm_lock`, reached its 15,639-second per-test timeout after 4:20:39 with peak RSS 1,852,396 KiB. Its log reached `First pass through ICCM`, but no result JSON or terminal testcase marker exists. This run predates heartbeat instrumentation, so progress is unknown and it is not classified as a hang. The available raw logs, status, provenance, hashes, and resource report are in [`task-30-iccm_lock/`](task-30-iccm_lock/).

Row 32, `smoke_test_ecc_keygen`, reached its 16,033-second timeout after 4:27:13 with peak RSS 1,852,504 KiB. It has no result JSON, terminal testcase marker, or mcycle heartbeat. This run predates heartbeat instrumentation, so it remains `TIMEOUT (progress unknown)`, not a hang. Its raw logs, status, provenance, hashes, and resource report are in [`task-32-smoke_test_ecc_keygen/`](task-32-smoke_test_ecc_keygen/).

Row 33, `smoke_test_ecc_sign`, reached its 16,033-second timeout after 4:27:13 with peak RSS 1,852,384 KiB. It has no result JSON, terminal testcase marker, or mcycle heartbeat. This run predates heartbeat instrumentation, so it remains `TIMEOUT (progress unknown)`, not a hang. Its raw logs, status, provenance, hashes, and resource report are in [`task-33-smoke_test_ecc_sign/`](task-33-smoke_test_ecc_sign/).
