# Caliptra BFM M18

M18 starts from the 108-row M15/M16 corpus and preserves the verified terminal result for every row. The authoritative combined table is [`m18-results.tsv`](m18-results.tsv); its `final_status` column has no `NOT_RUN` values. Where M17 marked a row out of scope, the matrix inherits its verified M15 or M16 result and records that source explicitly. The original milestone tables remain unchanged.

## Current matrix

The combined table currently has 49 `PASS`, 9 `FAIL`, 31 `BLOCKED`, and 19 `TIMEOUT` rows, with no `NOT_RUN` rows. It preserves M15/M16 history, M17 records, and one authoritative final status/evidence reference per row. Rows 0, 7, 9, 10, 16, 17, 46–48, 54–56, 58, 61, 65, 69, 64, 77, and all 14 ML-DSA cast-failure rows have current-main M18 records described below.

The M17-era compiler was Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` with binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. M18 first built `82023726be90ab269d6e0ef5e755ebb69e6f648c`, then refreshed from the observed upstream `main` SHA `cae035642e056644274a01e98d4422ce286685b4`; both builds passed the UVM smoke. The refreshed toolchain is installed under `/home/dsell/toolchains/iverilog-uvm-m18-main-cae035642e056644274a01e98d4422ce286685b4`. Build evidence is in `attempts/iverilog-main-cae0356-20261019-02/`. The remote `main` ref was still at this SHA when checked; rebuild again if A3's feature batch is merged later.

The refreshed Linux `iverilog` and `vvp` hashes are `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330` and `979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309`. The shared runner is pinned to this source and compiler hash.

The same source snapshot also builds on the Mac for local fallbacks. That platform build passed the UVM smoke; its separate binary hashes and Homebrew link flags are recorded in `attempts/iverilog-main-cae0356-local-20261019-02/`.

The row 0 AAXI gate on refreshed Icarus and open AAXI/AHB overlays resolved the missing `avery_defines.svh` include and the former `mbox_csr_covergroups.svh:64` blocker. A local rerun at current main `cae035642e056644274a01e98d4422ce286685b4` again stops before simulation at `soc_ifc_reg_covergroups.svh:2055` on an unsupported fixed-array wildcard-bin declaration. Row 0 remains `BLOCKED`; the refreshed-main archive and checksums are in `attempts/aaxi-row0-gate-local-20261019-01/`.


The authored Adams Bridge row 64 compressor gate passes on refreshed main. Its testbench overlay reads the existing coefficient vector by address, honors DUT read stalls, packs the API output stream, and samples `compress_done` on clock edges to avoid a transient delta-cycle pulse. The original `coeff_exp` formula and pass/fail markers remain intact. The three-mode run and checksum are in `attempts/compress-row64-gate-local-20261019-03/`; earlier failures and the focused diagnostic are retained in sibling attempts.

## M18 work

- Build a pinned Icarus toolchain from the observed `main` SHA, then refresh it when A3's batch reaches `main`.
- Add only testbench/BFM/filelist/setup compatibility for the AAXI/SoC-IFC/Caliptra-top, KeyVault, ML-DSA, and Adams Bridge issues. RTL, firmware, expected outputs, and pass criteria remain unchanged.
- Re-run the requested rows against the pinned compiler; record the raw Slurm archives, per-run source/compiler hashes, and adjacent SHA-256 sidecars.
- Finish by verifying all 108 `final_status` cells are `PASS`, `FAIL`, `BLOCKED`, or `TIMEOUT`, and all final evidence references resolve to archived or inherited evidence.

## KeyVault row 7 refreshed-main gate

Row 7 was rerun with the current-main Icarus pin and both open-AHB and hash-guarded sequence-base overlays. Job 3013 stopped during generated testbench compilation at `kv_rst_configuration.svh:149`: `$psprintf` received missing/empty parameters (compile exit 30, 3.199 s, peak RSS 592,956 KiB). No simulation started, so the sequence-base behavior is untested. The terminal `BLOCKED` result points to the archived result JSON; the raw archive SHA-256 was verified locally. The complete compile log contains further unsupported generated constructs, including dynamic-array slice r-values and nested class member paths.

The next gate (job 3025) wired the existing generated-KeyVault BFM overlay into the shared runner. Compilation completed (76 warnings, no errors), and simulation exited 0 with a UVM summary of zero errors and fatals, but emitted no testcase pass/fail marker. The unchanged runner therefore records row 7 as `BLOCKED`; no pass criterion was inferred. The verified archive is `attempts/kv-row7-gate-20261019-03/raw/job-3025.tar.gz` (SHA-256 `cf86c00645c05fb473560259664215b220d029d2cbefdb90dd393375e40a136c`).

## KeyVault rows 9 and 10 refreshed-main array

Rows 9 and 10 were rerun in array job 3016 with the refreshed Icarus pin, open-AHB filelist, and hash-guarded KeyVault sequence-base overlay. Both reached the same generated compile blocker as row 7: `$psprintf` called with missing/empty parameters at `kv_rst_configuration.svh:149` (compile exit 30; approximately 3.1 s each). Neither simulation started. Each row is `BLOCKED` on M18 current-main evidence; the previous M17 passes remain visible in their history columns. Raw archives and checksums are in `attempts/kv-rows9-10-current-main-20261019-01/raw/`.

The generated-BFM overlay rerun passed both rows: `kv_rand_test` (row 9) and `kv_rand_lock_test` (row 10) emitted `** TESTCASE PASSED`, reported zero UVM errors/fatals, and reached `$finish`. Their raw archives and verified SHA-256 sidecars are in `attempts/kv-rows9-10-overlay-20261019-02/raw/`.

## ECC, SHA512, and PCRVault refreshed-main reruns

Array job 3043 reran rows 16–17, 46–48, and 54–55 on current-main Icarus with the open-AHB compatibility filelists. Every compile stopped before simulation: SHA512 and ECC hit automatic bins on a >64-bit coverpoint (#667), and PCRVault hit the generated empty `$psprintf` call (#670). All seven remain `BLOCKED`; their archived per-row results and SHA-256 sidecars are in `attempts/uvmf-ecc-sha512-pv-current-main-array-20261019-01/raw/`. The first compile diagnostics were verified directly from each archive after intern triage.

## Adams Bridge missing-config-header row 58 gate

The pinned Adams Bridge commit `0a45a69535b0443ee7a66532303bd9857abd6686` removed the legacy `mldsa_*` RTL hierarchy and added its renamed `abr_*` successor. The hash-guarded overlay maps those stale filelist entries and uses the exact pinned ABR configuration header; it does not create macro values. The testbench also imports legacy `sampler_pkg`, which the overlay aliases to the renamed `abr_sampler_pkg`. Row 58 now compiles and runs but reaches the bench's unchanged 200,000-cycle cap without a testcase verdict, so it remains `BLOCKED`. The attempts and raw archives are under `attempts/adams-header-row58-gate-20261019-*/`.

## Adams Bridge rows 61, 65, and 69

The same hash-guarded missing-header overlay was first run on rows 61, 65, and 69 in array job 3061. Rows 61 and 65 compile-stopped on a stale `done_i` port in the authored `abr_sha3_tb`; row 69 reached its original checker but failed after 10 invalid sample-queue checks. Follow-up one-row gates removed the stale testbench port and preserved the sampler import alias in the same overlay file. Rows 61 and 65 now compile, then hit the unchanged 200,000-cycle bench cap without testcase verdicts; both remain `BLOCKED` on current-main evidence. Their gates are in `attempts/adams-sha3-row61-gate-20261019-03/` and `attempts/adams-sha3-row65-gate-20261019-01/`. The initial overlay-composition failure and invalid-selector diagnostic are retained in row61 attempts 01–02. The initial array and row69 evidence remain in `attempts/adams-config-array-20261019-01/`.

## ML-DSA row 77 updated-overlay gate

The updated overlay compiles and avoids the previous `SCBD_AHB` cast fatal, but the row did not reach a testcase result within 600 seconds. VVP ran to the configured timeout with the last timestamped progress at 200 ns (“waiting for the reset event trigger”), no UVM error/fatal, and no pass marker. The row is `TIMEOUT` on M18 current-main evidence. Its run archive is in `attempts/mldsa-row77-gate-20261019-04/raw/`; the archive SHA-256 matches the remote sidecar.

## ML-DSA cast array current-main wave 1

Array job 3055 applies the updated AHB transfer typedef, predictor transaction creation, configuration, and environment overlays to the remaining cast-failure rows. All 14 rows compiled and ran until the 600-second VVP timeout without a testcase verdict. Row80 also logged one predictor `UVM_ERROR` for an unhandled register write. The runner records timeouts before checking testcase markers, so all 14 remain `TIMEOUT`. Their archives and checksums are under `attempts/mldsa-cast-array-20261019-01/raw/`.

Because the 600-second cap prevented row93 from reaching a testcase verdict, job 3078 reran it with a 3,600-second cap and the same source/overlay. It completed in 1,372.543 seconds and emitted `* TESTCASE FAILED` with 16 `[SCBD_AHB]` mismatches: these are reads (`RnW=0`, `AHB_READ`) from `0xd8` through `0x114`, with actual returned data `0` while expected words were nonzero. The sequence also read `MLDSA_VERIFY_RES[0..15]` as zero. The archive has no pin-level waveform, so the report records the monitor/scoreboard transaction result without attributing the zeros to DUT logic or monitor sampling. The UVM summary reported 16 errors and zero fatals; VVP exited 0, so the testcase marker determines the `FAIL` result. The verified archive is `attempts/mldsa-row93-longgate-20261019-02/raw/job-3078_93.tar.gz`. Its earlier 600-second `TIMEOUT` remains in the 3055 array archive. The first long-run submission had a bad directory path and is retained as an invalid infrastructure attempt in `attempts/mldsa-row93-longgate-20261019-01/`.

Array job 3081 reruns the 13 ML-DSA cast rows with a 3,600-second per-test cap, six-task throttle, and the committed M18 runner snapshot. Rows91 and92 completed in 1,999.799 and 1,522.05 seconds with `* TESTCASE PASSED`, zero UVM errors/fatals, and no scoreboard mismatches (row91 had 3,448 matches); their verified archives are in `attempts/mldsa-cast-long-array-20261019-01/raw/`. Row97 completed in 865.87 seconds. It emitted `* TESTCASE PASSED` but also one `[SCBD_AHB]` UVM error at `mldsa_scoreboard.svh:207` because the second verification result differed from the successful result; the runner therefore records `FAIL` (UVM_FATAL=0). Its archive SHA-256 is `f3f2fe72ab3fe7d543381a24ae4101b9d3ab0ab5f78c1336b8867d0e641fc989`.

Rows80, 82, 86, and 87 each reached the 3,600-second VVP timeout (about 3,599 seconds). Rows80 and82 emitted respectively 50 UVM errors (32 scoreboard and 16 KAT validation mismatches) and 32 scoreboard UVM errors before timeout; neither emitted a testcase verdict. Rows86 and87 emitted no UVM errors/fatals and remained at the 200 ns reset-wait message. The runner gives an elapsed per-test timeout precedence over log errors, so all four remain `TIMEOUT`. Row96 also timed out at 3,599.545 seconds with no UVM error/fatal or testcase marker; its last progress was `MLDSA_MSG[6]` at 1,895 ns. Row101 passed in 1,544.57 seconds with `* TESTCASE PASSED`, UVM_ERROR=0, UVM_FATAL=0, and scoreboard matches/mismatches=0/0. Row99 timed out at 3,599.631 seconds after 16 `[SCBD_AHB]` read mismatches at 0xd8–0x114 (actual zero, expected nonzero); there was no testcase marker and UVM_FATAL=0. The runner keeps it `TIMEOUT` because the elapsed cap takes precedence. Row102/103/106 each timed out at 3,599.321/3,599.433/3,599.466 seconds without UVM errors/fatals or testcase markers; their last progress was at 1,175 ns, 491,075 ns (a truncated `REG_WRITE_PASS` line), and 1,145 ns respectively. Their verified archive SHAs are `e51aa3386aa8131bf5dc904f668cb55b31203484471a14e76f451e912c3c3e29`, `980a61a34a589d280001e5a86ae2468bb76f35c72f374f8c85bdfde5daea0cbf`, and `3c8b0ad73e2c18caf7129b3a7ec2ab1c4c1691b21feb6b286e00989d43c86471`. All 13 extended rows now have verified terminal results: rows91,92,101 PASS; row97 FAIL; the other nine TIMEOUT. Their result JSONs and archives supersede the earlier 600-second outcomes.

## Final M18 verification

The unified table has 108 terminal rows: 49 `PASS`, 9 `FAIL`, 31 `BLOCKED`, and 19 `TIMEOUT`; no `NOT_RUN` rows remain. The final evidence audit resolved all 108 references, verified SHA-256 sidecars for all 80 final-referenced archives and all 77 explicit archive members, and matched all 93 machine-readable source pins to the table. Eight inherited ML-KEM records intentionally map setup failures from missing key-generation fixtures to `BLOCKED`; their logs show no crypto result ran. Upstream Icarus `main` was still `cae035642e056644274a01e98d4422ce286685b4` on the final check. The compatibility runner suite has 80 passing tests under `localrun`. Array 3081 is terminal; after all 13 archives were copied and checked against both sidecars, its remote run directory was removed, freeing 1,511,614,515 bytes (1.51 GB; 1.41 GiB).

## Adams Bridge row 56 Python-backed authored test

The Python alias removed the setup blocker: the existing model generated both input vectors and expected outputs, and simulation ran. The authored bench then reported 10 `Not enough valid samples in the queue` errors and emitted `* TESTCASE FAILED`; row 56 is `FAIL`, not a timeout or infrastructure blocker. The overlay leaves stimuli, reference model, expected output, and pass criteria unchanged. Job 3022's raw archive and verified SHA-256 are in `attempts/adams-row56-header-gate-20261019-04/`.

## Top-level AAXI and SoC-IFC refreshed-main rows

Rows 1–4 and 43–45 were rerun after the row 0 gate using the refreshed compiler and open AAXI/AHB overlays. All seven compile attempts stop at the same pinned RTL fixed-array wildcard bins in `soc_ifc_reg_covergroups.svh:2055`; simulation did not start. Together with row 0’s local gate, all eight requested AAXI rows have current-main records. The blocker is in pinned Caliptra RTL syntax, not the BFM overlay. Corrected archives and checksums are in `attempts/top-aaxi-current-main-array-20261019-32/raw/`.
