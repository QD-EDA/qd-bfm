# Terminal results preserved from top-level wave 1

These six Slurm runs ended with the runner's explicit per-test timeout (`runner_exit=124`) and are terminal `TIMEOUT` verdicts. Their simulator output stopped during fuse-ready polling, before a `result.json` was written. Each directory contains the Slurm output, status, provenance, tool hashes, resource report, simulator log, and firmware log.

| Row | Test | Verdict | Per-test timeout |
|---:|---|---|---:|
| 1 | `cptra_ss_test_rom` | TIMEOUT | 6,873 s |
| 2 | `smoke_test_dma_aes_gcm` | TIMEOUT | 7,004 s |
| 3 | `smoke_test_datavault_basic` | TIMEOUT | 7,333 s |
| 5 | `smoke_test_dma_aes_gcm_rd_enc_axi_err` | TIMEOUT | 7,628 s |
| 6 | `smoke_test_dma_aes_gcm_wr_enc_axi_err` | TIMEOUT | 7,628 s |
| 7 | `smoke_test_kv_lock_use_mid_read` | TIMEOUT | 7,956 s |
| 10 | `smoke_test_sram_ecc` | TIMEOUT | 8,876 s |

Row 8, `pv_hash_zeroize`, is a terminal `FAIL`: its result JSON reports `passed=false`, and the simulation ends on the pinned SHA-512 RTL assertion `ERR_SHA_BLOCK_NOT_STABLE`. The logs and raw wrapper status are in [`task-8-pv_hash_zeroize/`](task-8-pv_hash_zeroize/). This evidence records the RTL assertion failure and does not identify an Icarus defect.

Row 9, `smoke_test_uart`, is a terminal `FAIL`: its firmware C build reports undefined UART and UART-enable register symbols in the test source, which are absent from the generated register header at pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The full compiler log, source, copied header, exact hashes, and batch status are in [`task-9-smoke_test_uart/`](task-9-smoke_test_uart/); simulation did not start.

Row 11, `smoke_test_kv`, is a terminal `PASS`: its result JSON has `passed=true`, the runner reports `PASS`, and the simulation log contains `* TESTCASE PASSED`. The submitted array wrapper's raw status incorrectly says FAIL because it searched for `output/<case_dir>/result.json`, while the runner writes `output/result.json`. Both the raw wrapper status and the corrected evidence classification are in [`task-11-smoke_test_kv/`](task-11-smoke_test_kv/).

Row 12, `smoke_test_sha512`, is a terminal `PASS`: its result JSON has `passed=true`, its runner log reports `PASS`, and its simulation log contains `* TESTCASE PASSED`. Its raw wrapper false `FAIL` and corrected verdict are preserved in [`task-12-smoke_test_sha512/`](task-12-smoke_test_sha512/).

Row 14, `smoke_test_zeroize_crypto`, is a terminal `PASS`: its result JSON has `passed=true`, its runner log reports `PASS`, and its simulation log contains `* TESTCASE PASSED`. Its raw wrapper false `FAIL` and corrected verdict are preserved in [`task-14-smoke_test_zeroize_crypto/`](task-14-smoke_test_zeroize_crypto/).

Rows 0 and 4 have local `TIMEOUT` evidence under [`../local-fallback/`](../local-fallback/README.md).
