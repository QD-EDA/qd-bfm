# Terminal results preserved from top-level wave 1

These fourteen Slurm runs ended with the runner's explicit per-test timeout (`runner_exit=124`) and are terminal `TIMEOUT` verdicts. The thirteen earlier timeouts stopped during fuse-ready polling before a `result.json` was written; row 22 progressed through reset assertion/deassertion before its timeout. Each directory contains raw status, provenance, tool hashes, resource reports, and the available build/simulation logs.

| Row | Test | Verdict | Per-test timeout |
|---:|---|---|---:|
| 1 | `cptra_ss_test_rom` | TIMEOUT | 6,873 s |
| 2 | `smoke_test_dma_aes_gcm` | TIMEOUT | 7,004 s |
| 3 | `smoke_test_datavault_basic` | TIMEOUT | 7,333 s |
| 5 | `smoke_test_dma_aes_gcm_rd_enc_axi_err` | TIMEOUT | 7,628 s |
| 6 | `smoke_test_dma_aes_gcm_wr_enc_axi_err` | TIMEOUT | 7,628 s |
| 7 | `smoke_test_kv_lock_use_mid_read` | TIMEOUT | 7,956 s |
| 10 | `smoke_test_sram_ecc` | TIMEOUT | 8,876 s |
| 13 | `smoke_test_hek_flow` | TIMEOUT | 9,467 s |
| 15 | `smoke_test_dma_aes_gcm_non_gcm_en_dec` | TIMEOUT | 10,091 s |
| 17 | `c_intr_handler` | TIMEOUT | 10,813 s |
| 19 | `smoke_test_mbox_byte_read` | TIMEOUT | 10,846 s |
| 20 | `smoke_test_dma_aes_gcm_collision_test` | TIMEOUT | 11,010 s |
| 21 | `smoke_test_dma_aes_gcm_short_dword` | TIMEOUT | 11,240 s |
| 22 | `smoke_test_kv_securitystate` | TIMEOUT | 11,240 s |

Row 22 reached its 11,240-second per-test limit after 3:07:20, with peak RSS 1,852,368 KiB. It has no `result.json` or testcase terminal marker; see [`task-22-smoke_test_kv_securitystate/`](task-22-smoke_test_kv_securitystate/).

Row 8, `pv_hash_zeroize`, is a terminal `FAIL`: its result JSON reports `passed=false`, and the simulation ends on the pinned SHA-512 RTL assertion `ERR_SHA_BLOCK_NOT_STABLE`. The logs and raw wrapper status are in [`task-8-pv_hash_zeroize/`](task-8-pv_hash_zeroize/). This evidence records the RTL assertion failure and does not identify an Icarus defect.

Row 9, `smoke_test_uart`, is a terminal `FAIL`: its firmware C build reports undefined UART and UART-enable register symbols in the test source, which are absent from the generated register header at pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The full compiler log, source, copied header, exact hashes, and batch status are in [`task-9-smoke_test_uart/`](task-9-smoke_test_uart/); simulation did not start.

Row 11, `smoke_test_kv`, is a terminal `PASS`: its result JSON has `passed=true`, the runner reports `PASS`, and the simulation log contains `* TESTCASE PASSED`. The submitted array wrapper's raw status incorrectly says FAIL because it searched for `output/<case_dir>/result.json`, while the runner writes `output/result.json`. Both the raw wrapper status and the corrected evidence classification are in [`task-11-smoke_test_kv/`](task-11-smoke_test_kv/).

Row 12, `smoke_test_sha512`, is a terminal `PASS`: its result JSON has `passed=true`, its runner log reports `PASS`, and its simulation log contains `* TESTCASE PASSED`. Its raw wrapper false `FAIL` and corrected verdict are preserved in [`task-12-smoke_test_sha512/`](task-12-smoke_test_sha512/).

Row 14, `smoke_test_zeroize_crypto`, is a terminal `PASS`: its result JSON has `passed=true`, its runner log reports `PASS`, and its simulation log contains `* TESTCASE PASSED`. Its raw wrapper false `FAIL` and corrected verdict are preserved in [`task-14-smoke_test_zeroize_crypto/`](task-14-smoke_test_zeroize_crypto/).

Rows 0 and 4 have local `TIMEOUT` evidence under [`../local-fallback/`](../local-fallback/README.md).

Row 18, `smoke_test_doe_kv_ocp_progress`, is a terminal `PASS`: runner and task status report exit 0, result JSON reports `passed=true` with one pass and zero fail markers, and sim.log contains `* TESTCASE PASSED` (`mcycle=53552`). Wall time was 2:02:55 with 1,852,448 KiB maximum RSS. Nine entropy_src/csrng unique/priority-case warnings are preserved; the result reports `bad_diagnostics=0`. See [`task-18-smoke_test_doe_kv_ocp_progress/`](task-18-smoke_test_doe_kv_ocp_progress/).


Row 27, `smoke_test_qspi`, is a terminal firmware-build `FAIL`: its C source references QSPI register macros absent from the generated `caliptra_reg.h` at the pinned Caliptra revision. The runner exited 1 before simulation, and no testcase result was written. The compiler log, raw task status, resource report, tool provenance, source/header hashes, and exact missing-symbol evidence are in [`task-27-smoke_test_qspi/`](task-27-smoke_test_qspi/). This is an upstream firmware test/header mismatch, not an Icarus result.

Row 28, `smoke_test_dma_aes_kv_short`, is a terminal `PASS`: the task status and runner exit 0, result JSON `passed=true`, and one simulator testcase pass marker agree. It finished in 2:24:22 with peak RSS 1,852,464 KiB (`mcycle=60,133`). See [`task-28-smoke_test_dma_aes_kv_short/`](task-28-smoke_test_dma_aes_kv_short/).
