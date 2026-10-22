# Verilator timeout cohort: array 1372 results

Twelve of these 15 archived rows passed on Verilator 5.052. Task 1 timed out at its configured simulator cap without pass/fail or mcycle markers. Task 3 failed at the testbench's 20,000,000-cycle assertion after 11,181.286 seconds; it exited before its 15,212-second simulator timeout and produced no final mcycle. Task 22 has a testbench PASS marker and simulator exit 0, but the shared runner classifies it as FAIL because its `BAD` regex counts the test’s two expected `error=0x1` status strings. Both rows remain FAIL under the current runner result; no test or pass criteria were changed.

Each task used 1 CPU and 3 GiB on DAN-DESKTOP, QD-BFM commit `dd6d43d5416006a9e77f2458e8df2a5a754f86c7`, pinned Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and model SHA-256 `b6ee29ade1b17547c4b31692ed9a0b48e22031c4551604fd9dc250a81e01ae79`.

| Task | Case | Runner result | Final mcycle | Sim wall (s) |
| ---: | --- | --- | ---: | ---: |
| 1 | `cptra_ss_test_rom` | TIMEOUT | NA | 6873.008 |
| 3 | `jtag_tap_mbox` | FAIL (max cycle count) | NA | 11181.286 |
| 7 | `smoke_test_datavault_lock` | PASS | 1468229 | 839.031 |
| 16 | `smoke_test_dma_aes_gcm_wr_enc_axi_err` | PASS | 107835 | 62.735 |
| 17 | `smoke_test_ecc_errortrigger3` | PASS | 64349 | 964.21 |
| 18 | `smoke_test_ecc_keygen` | PASS | 783243 | 466.747 |
| 19 | `smoke_test_ecc_sign` | PASS | 797819 | 464.9 |
| 20 | `smoke_test_ecc_verify` | PASS | 1023648 | 582.416 |
| 21 | `smoke_test_hek_flow` | PASS | 69132 | 39.415 |
| 22 | `smoke_test_kv_lock_use_mid_read` | FAIL (bad=2) | 69079 | 39.22 |
| 23 | `smoke_test_kv_securitystate` | PASS | 56459 | 264.354 |
| 24 | `smoke_test_kv_swwe_lock` | PASS | 848287 | 483.585 |
| 25 | `smoke_test_kv_write_scan_mode` | PASS | 62847 | 35.867 |
| 26 | `smoke_test_mbox_byte_read` | PASS | 135980 | 77.108 |
| 27 | `smoke_test_sram_ecc` | PASS | 163535 | 92.525 |

For `kv_lock_use_mid_read`, the log ends with `ALL CHECKS PASSED`, `* TESTCASE PASSED`, and `mcycle=69079`. Its `sim_scan.bad=2` comes from `HMAC KV_RD_KEY_STATUS = 0x6 (error=0x1)` and `[PASS] Mid-read lock_use correctly reported error=0x1`; `scan_sim_log` treats these `ERROR` tokens as bad diagnostics. The simulator exit is 0, `failed=0`, and JTAG errors are 0.

All files were checksum-verified against remote manifests. Corrected c339 baselines remain pending for comparisons, so speedup fields remain pending.

Task 1 evidence, including its timeout result JSON, firmware and simulator logs, resource records, and Slurm output, is checksum-verified in `task1_cptra_ss_test_rom/`.
