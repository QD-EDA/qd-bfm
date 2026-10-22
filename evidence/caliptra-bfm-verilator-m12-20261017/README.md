# M12: top-level Verilator pass-rate overlays

Scope is the 162 stock-firmware top-level rows on pinned QD-BFM source `ffc12ab427e961f40354f32a8e7a147e5d4e5764`, Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Verilator 5.052 with assertions, and the M10b AXI overlay. M9 is closed; its results are not being re-audited. Upstream bug drafts remain local.

The M11 baseline table has 84 PASS, 63 FAIL, 14 FIRMWARE_BUILD_FAIL, and 1 TIMEOUT (162 total). It is `../caliptra-bfm-verilator-m11-20261016/remaining-59/final-162-results.tsv`.

## Build-time overlay gates

| Overlay | Affected rows | Gate and affected-row result |
| --- | ---: | --- |
| Strap-size assertion guard (draft 4) | 1 | PASS: `smoke_test_dma_aes_kv_large`, mcycle 60,405; job 2100 |
| DOE reset-corner delay (draft 5) | 1 | Combined delay+reset-guard gate 2121 still FAILs: two DOE SVA errors (`sim_scan.bad=2`) although firmware reaches its pass marker at mcycle 62,260. Evidence is in `doe-reset-delay/`; no wider rerun is justified. |
| LMS DCCM image load (draft 9) | 34 | All 34 PASS: full-timeout gate 2123 plus all 33 remaining rows in array 2146. The gate reached mcycle 2,675,745 with `sim_scan.bad=0`; the per-row evidence archive is checksummed under `lms-dccm/generated/array-2146/`. |
| MBOX RDATA sampling (draft 2) | 1 | Gate 2133 FAILs at `AXI_SUB_W_HSHAKE_ERR` before any RDATA sample (`sim_scan.bad=2`); the RDATA candidate is unvalidated and no affected-row array is justified. |
| ECC seed clear assertion guard (draft 6) | 2 | Root cause traced by job 2106; gate 2130 PASSes `smoke_test_ecc_keygen` at mcycle 783,243. Job 2141 exited in a stale M10b launcher before simulation (no test result). Fresh-run job 2144 PASSed only `smoke_test_kv_swwe_lock` at mcycle 848,287 (`sim_scan.bad=0`); the gate row was excluded. |
| SHA512 ZEROIZE assertion guard (additional shared group) | 4 | Gate 2126 PASS: `smoke_test_sha512`, mcycle 63,435, `sim_scan.bad=0`. Array 2136: `smoke_test_sha512_restore` PASS at mcycle 73,221; `pv_hash_and_sign` and `pv_hash_zeroize` FAIL at `ERR_SHA_BLOCK_NOT_STABLE`. |

## Final 162-row comparison

The complete per-row comparison is [`final-162-results.tsv`](final-162-results.tsv). Pinned-only Verilator passed 84/162 rows (51.85%); with the M12 build-time overlays, 123/162 passed (75.93%), a gain of 39 rows or 24.07 percentage points. Outcome counts are pinned-only: 84 PASS, 63 FAIL, 14 FIRMWARE_BUILD_FAIL, 1 TIMEOUT; with overlays: 123 PASS, 24 FAIL, 14 FIRMWARE_BUILD_FAIL, 1 TIMEOUT. The 43 affected rows have terminal results: strap 1/1 PASS; DOE 0/1 PASS; LMS 34/34 PASS; MBOX 0/1 PASS; ECC 2/2 PASS; SHA512 2/4 PASS. Candidate outputs are matched by test ID, including repeated firmware case names.

Overlays change only build-time BFM, testbench, or assertion-guard code. No functional RTL, firmware, or pass criteria changed. DOE remains FAIL because the reset-corner assertion still fires; the firmware pass marker does not override scanner errors. MBOX remains FAIL before RDATA at `AXI_SUB_W_HSHAKE_ERR`, so the RDATA candidate is not validated on the official row. The two SHA512 rows that still fail remain failures because only `smoke_test_sha512` has a focused ZEROIZE trace. The DOE reset-guard-only local candidate also failed; its evidence records a v5.052 source build with a local Flex declaration compatibility patch. The combined DOE gate uses the pinned Slurm Verilator binary.

All 33 LMS array result folders have `wrapper_exit=0`, terminal PASS results, and verified per-row SHA-256 manifests. At collection time the completed Slurm job metadata had expired (`squeue` was empty and `scontrol` no longer recognized the job; accounting is unavailable), so scheduler-level exit state could not be independently checked. The row results, wrapper logs, resources, and hashes are preserved in the evidence archive.

## Draft 6 trace

Job 2106 traced `smoke_test_ecc_keygen`: zeroize asserted the seed hardware-clear control and the next sampled value was zero. The stability assertion did not exempt that clear/update window. The trace and passing assertion-only candidate are recorded in `ecc-seed-guard/`; no functional RTL change was made.

## Other M11 failures checked for overlay scope

`smoke_test_dma` remains FAIL. Its pinned firmware caller uses `soc_ifc_axi_dma_read_mbox_payload` as a boolean, but the `uint8_t` helper reaches its closing brace without returning a value; this is undefined firmware behavior and is outside M12's allowed overlay scope. The four other 20,000,000-cycle-limit rows remain untraced, so no portability overlay is justified for them yet. `smoke_test_kv_lock_use_mid_read` is the known result-scanner false positive; the scanner and pass criteria remain unchanged, so its M11 FAIL is retained.

After preserving and verifying the result bundles, five completed A2 Slurm run trees were removed. Their measured allocated size was 3,659,743,232 bytes (about 3.41 GiB); shared toolchains were left in place. The clean detached local M12 source-staging worktree (116 MiB) was also removed.
