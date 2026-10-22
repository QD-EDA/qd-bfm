# Draft: ECC key and seed stability assertions reject internal clears

**Status:** Local review draft only; not posted. The `ERR_ECC_SEED_NOT_STABLE` cause is traced below. The separate private-key assertion failures remain untraced.

Assertion-enabled Verilator runs in array 1835 failed `ERR_ECC_PRIVKEY_NOT_STABLE` in seven rows (`smoke_test_ecdh`, `smoke_test_pcr_zeroize`, `smoke_test_ecc_errortrigger1/2/3`, `smoke_test_pcr_signing`, `smoke_test_ecc_sign`) and `ERR_ECC_SEED_NOT_STABLE` in two (`smoke_test_kv_swwe_lock`, `smoke_test_ecc_keygen`). The run outcome table is in [`partial-results.tsv`](../../../caliptra-bfm-verilator-m10b-20261016/diagnostics/array-1772-hang/overlay-v2/array-1835/partial-results.tsv).

## Seed-stability trace

The M11 focused trace for `smoke_test_ecc_keygen` first recorded a nonzero-to-zero seed change at time 78,353,000, but only printed control values at that sample, when they were low. The M12 trace gate (Slurm job 2106, model SHA-256 `a081cbacf2cf9146d015c1c4b9a214846c6a16a7f02736de2fb778b8797850f6`) added sampled signal history. At the same transition it reports `zeroize_hist=01000` and `hwclr_hist=01000`, with `write_en_hist=00000`, `swwe0=0`, `we0=0`, `present_reset_hist=00000`, and `read_fail_hist=00000`. This shows a hardware clear was asserted in the preceding sampled cycle; there was no software or Key Vault write.

The pinned controller drives `ECC_SEED.SEED.hwclr` from `zeroize_reg | kv_seed_data_present_reset | (kv_seed_error == KV_READ_FAIL)` (line 384). The existing stability assertion at line 1015 is disabled only by reset or `ecc_ready_reg`, so it reports a valid zeroize clear and its registered update as an unexpected seed change. This disproves the original claim that no clear control was active.

Job 2106 stopped at the assertion after 536.5 seconds and did not reach firmware PASS. The assertion-only build-time guard candidate in [`ecc-seed-guard`](../../../caliptra-bfm-verilator-m12-20261017/ecc-seed-guard/README.md) exempts the clear cycle and its one-cycle delayed register update. Full-timeout gate 2130 passed `smoke_test_ecc_keygen` at mcycle 783,243 with no scanner errors; the remaining row `smoke_test_kv_swwe_lock` passed in job 2144 at mcycle 848,287 with no scanner errors. These candidate results support the traced assertion guard; functional RTL is not changed, and this draft has not been posted.

## Other assertion failures

Array 1835 also reported `ERR_ECC_PRIVKEY_NOT_STABLE` in seven rows. This seed trace does not identify the cause of those separate failures, and they remain untraced.
