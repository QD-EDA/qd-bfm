# M23 Verilator 5.052 selected-row matrix (2026-10-22)

Job 3989 ran the 20 cases selected from M21 Part B on the Caliptra v2.1.2 RTL revision `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, with Verilator 5.052 and the QD-BFM timing wrapper. The shared model SHA-256 was `7c0f8bbe238f824149b0ba242da9dd3579d5bbb43b34cc125ad267d7d84725e7`. Six array tasks ran concurrently; each had four CPUs and a four-hour limit.

## Results

| Verilator 5.052 | Cases | M21 Icarus comparison |
| --- | ---: | --- |
| PASS | 18 | 8 of these were M21 TIMEOUTs |
| FAIL | 1 | M21 TIMEOUT; `smoke_test_doe_scan` |
| FIRMWARE_BUILD_FAIL | 1 | M21 PASS; `smoke_test_sha3_interrupts` |
| TIMEOUT | 0 | None |

M23 summed per-case wall time: 2113.194 s (35.22 min). M21 summed per-case Icarus wall time: 276,567 s (76.82 h); its 20 outcomes were 11 PASS and 9 TIMEOUT. These are sums of case wall times, not array elapsed time.

`smoke_test_sha3_interrupts` failed during firmware build before simulation (runner exit 1 after 0.781 s). The compact fetched bundle did not retain the compiler diagnostic; it is recorded in [`docs/E-VERILOG-WAITLIST.md`](../../../docs/E-VERILOG-WAITLIST.md) for follow-up. The row57 `smoke_test_doe_scan` FAIL is a terminal simulation result, not a timeout; its detailed raw output was omitted from this summary.

## Per-case results

| M11 row | Test | Verilator 5.052 | Wall (s) | M21 Icarus | Wall (s) |
| ---: | --- | --- | ---: | --- | ---: |
| 104 | `smoke_test_sha_accel` | PASS | 15.521 | PASS | 2,040 |
| 48 | `smoke_test_mldsa_zeroize` | PASS | 86.574 | TIMEOUT | 21,600 |
| 62 | `smoke_test_kv_uds_reset` | PASS | 189.069 | TIMEOUT | 21,600 |
| 41 | `rand_test_dma` | PASS | 33.297 | TIMEOUT | 21,600 |
| 124 | `smoke_test_wdt_rst` | PASS | 444.065 | TIMEOUT | 21,600 |
| 81 | `smoke_test_doe_cg` | PASS | 34.736 | PASS | 6,286 |
| 147 | `smoke_test_kv_uds_reset` | PASS | 184.879 | TIMEOUT | 21,600 |
| 90 | `smoke_test_dma_aes_kv` | PASS | 34.254 | PASS | 6,580 |
| 93 | `smoke_test_dma_aes_kv` | PASS | 34.290 | PASS | 6,589 |
| 23 | `smoke_test_wdt` | PASS | 98.788 | PASS | 16,540 |
| 96 | `smoke_test_iccm_reset` | PASS | 132.457 | TIMEOUT | 21,600 |
| 69 | `smoke_test_sha3_regs` | PASS | 34.942 | PASS | 6,475 |
| 52 | `smoke_test_cg_wdt` | PASS | 171.134 | TIMEOUT | 21,600 |
| 57 | `smoke_test_doe_scan` | FAIL | 165.284 | TIMEOUT | 21,600 |
| 144 | `smoke_test_sha3_interrupts` | FIRMWARE_BUILD_FAIL | 0.781 | PASS | 6,731 |
| 19 | `smoke_test_hmac_kv_ocp_progress` | PASS | 36.598 | PASS | 6,764 |
| 49 | `smoke_test_fw_kv_backtoback_hmac` | PASS | 38.351 | PASS | 8,072 |
| 30 | `smoke_test_cshake` | PASS | 39.273 | PASS | 7,415 |
| 29 | `smoke_test_mldsa_kv_ocp_progress` | PASS | 45.719 | PASS | 8,675 |
| 159 | `smoke_test_datavault_reset` | PASS | 293.182 | TIMEOUT | 21,600 |

See [`results.tsv`](results.tsv) for stable case IDs and exact selection rows. The matrix summary intentionally retains no raw per-run logs or firmware/build products.
