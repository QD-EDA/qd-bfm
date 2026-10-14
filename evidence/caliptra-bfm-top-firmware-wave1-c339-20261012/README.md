# Caliptra top-level firmware sweep, wave 1

This run covers the next 50 source-backed, unverified stock-firmware integration rows from the 2026-10-10 matrix, plus one six-hour retry each for the two prior timeouts. The prior ten-test sample rows are excluded from the 50 new rows. The matrix had 162 stock-firmware integration rows before this wave: 152 unverified, seven pass, two timeout, and one firmware-link failure.

`selection.tsv` is the array manifest. It maps each matrix ID to the exact YAML under `src/integration/test_suites`, the code directory that owns that YAML, a static workload rank, an expected-cycle estimate, and the resulting timeout. This matters for cases whose YAML is stored in a shared suite directory. The runner receives both `--case` and `--case-yaml`; the result retains the matrix ID in the task evidence and the YAML's own test name in `result.json`.

[`results.tsv`](results.tsv) is the per-row status ledger. `terminal_outcome` remains blank until a valid PASS, FAIL, or TIMEOUT is recorded; infrastructure/setup attempts are tracked in `state` and do not count as test verdicts.

The ranking is a conservative source-based approximation, not a measured cycle count. Its static score is `case_source_lines + 12 * loop_sites + 5 * wait_or_poll_sites + 8 * crypto_call_sites`, counting nonblank test-specific source lines and omitting the common ISR header. The call counts are lexical proxies, so the rank is an estimate rather than a prediction of exact runtime. Rows without case source and known high-variance or multi-vector families (randomized or large transfers, reset/watchdog, variable TRNG, multi-vector MLDSA/MLKEM/SHA3/cSHAKE, and long HMAC flows) are not ranked as short cases. The expected-cycle estimate is `min(50000, max(5000, 5000 + 80 * static_score))`. Case timeout is `min(21600, ceil(3 * expected_mcycle / 7.31 + 1800))` seconds, using the prior measured 7.31 cycles/s rate, a 3x projection, and 30 minutes for build/startup. The two retries use 21,600 seconds directly. These are timeout budgets; the actual `mcycle` is recorded per result.

Each task uses one CPU and 3 GiB; the previous sample peaked near 1.86 GiB. Job 591 started at throttle 4 and was reduced to 3 after host recovery. Fresh job 606 reruns rows 1–3 at throttle 3, keeping this workstream at no more than six concurrent tasks. Each task has a timeout of at most six hours and a 6h10m Slurm allocation for launch, termination, and evidence writing. The runner preserves build and simulation logs, result JSON, and resource reports under `runs/<test_id>-<array_index>/`. Runner exits 137/143 are infrastructure outcomes, not firmware verdicts.

Pins are Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus c339 `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The per-task provenance records the staged QD commit, host, tool versions, binary hashes, exact YAML hash, command, wall time, peak RSS, and outcome.

## Compatibility diagnosis

The `smoke_test_hw_config` link failure is recorded separately in [`hwconfig-linkdiag/README.md`](hwconfig-linkdiag/README.md). Object-level symbol evidence and five build-flag probes identify an upstream C inline-linkage defect exposed by the pinned QD `-std=gnu11 -O2` build. Changing optimization either leaves the undefined symbol or introduces a different build failure; this is not a QD harness defect.

## Results

As of 09:41 MDT, rows 0 and 4 have terminal `TIMEOUT` outcomes and no wave-1 PASS/FAIL has been recorded. Jobs 591 tasks 5–7 and 606 tasks 1–3 all had live VVP processes using 99.9% CPU; their simulator logs remained byte-identical to the prior snapshot, with no terminal marker. Job 591's pending rows 8–51 were canceled before launch after the shared toolchain and firmware inputs were removed; they produced no test results. The user-approved cleanup policy treats `slurm-runs` as disposable, so the pinned c339 toolchain and its RTL, Adams Bridge, RISC-V compiler, Python, MbedTLS, and JTAG inputs have been rebuilt under `/home/dsell/toolchains/iverilog-c339/`. Job 609 completed the builds but exited at a JTAG output-path check; job 612 then wrote the protected JTAG module and manifest but failed an invalid MbedTLS header grep. Job 613 reran finalization successfully (exit 0). The old/new Icarus hashes and environment versions are in [`toolchain-recovery-20261012-01/BUILD-MANIFEST.txt`](toolchain-recovery-20261012-01/BUILD-MANIFEST.txt). Fresh job 611 covers only rows 8–51, with throttle 6 and dependencies on completion of jobs 591 and 606 and successful job 613. This keeps no more than six wave-1 firmware tests active at once. The local row-1 duplicate was stopped only after task 606_1 was confirmed running; its `localrun_exit=143` is intentional supersession. Job 591 task 4's remote duplicate was canceled without a status/result; the local row-4 timeout remains its terminal outcome. Recovery notes and snapshots are under [`toolchain-recovery-20261012-01/`](toolchain-recovery-20261012-01/) and [`resubmission-20261012-03/`](resubmission-20261012-03/). Earlier recovery evidence is under [`resubmission-20261012-02/`](resubmission-20261012-02/) and [`local-fallback/`](local-fallback/README.md).

At the 10:27 MDT checkpoint, 2 of 52 rows have terminal `TIMEOUT` results, six remain `RUNNING`, and 44 are pending. The rebuilt `iverilog` and `vvp` hashes are `683c94313f596bba25aa4e6de37efb4e68bb5dadc37394a91a2a0e6078ac26cb` and `ac6cd60d97ccf128118166f10855ca75d9271a561b440d30eb010404705be60f`; both are recorded beside the prior hashes in the protected build manifest. Job 611's submitted script hash matches the checked-in copy and points its remaining rows at `/home/dsell/toolchains/iverilog-c339/`. The six already-running processes still consume CPU, but `/proc/<pid>/exe` identifies their old VVP image as deleted; all six logs remain at the fuse-ready polling text, have the same 49,398-byte SHA256, and contain no `result.json`. They remain `RUNNING` with no test verdict, consistent with the supervisor's note that these live VVPs are unaffected. Job 611 remains dependency-held until jobs 591 and 606 terminate, preserving the six-task cap. The 10:27 Slurm/process/log snapshot is in [`resubmission-20261012-03/status-10-27.txt`](resubmission-20261012-03/status-10-27.txt). A local ask-intern log-triage request timed out while reaching its model endpoint; the above state was checked directly against Slurm, process mappings, and log hashes.

At the 14:18 MDT checkpoint, rows 0–7, 10, 13, and 15 have terminal `TIMEOUT` outcomes; row 8 (`pv_hash_zeroize`) has a simulation `FAIL` on the pinned SHA-512 RTL assertion `ERR_SHA_BLOCK_NOT_STABLE`; and row 9 has a firmware-build `FAIL`. Rows 11, 12, and 14 have `PASS` outcomes, each confirmed by result JSON, runner output, and a `TESTCASE PASSED` simulator marker. Job 660's wrapper falsely labeled these passes `FAIL` because it searched the wrong result path; the raw statuses are preserved with the corrected verdicts. The row-8 evidence does not establish an Icarus defect. Job 660 is complete. Corrected job 669 has started rows 16–21 and has rows 22–51 queued at throttle 6. The new tasks use the protected QD snapshot, c339, and OpenSSL paths; their provenance and binary hashes were verified. The ledger has 16 terminal verdicts, six running rows, and 30 pending rows. See [`terminal-results/README.md`](terminal-results/README.md) and [`resubmission-20261012-05/`](resubmission-20261012-05/).

The Mac fallback built Icarus from the exact c339 source SHA. Row 4's first local setup attempt stopped during firmware build with header-copy errors; its serial retry reached ROM flow and hit the 7,431-second timeout without a result JSON. Row 0 similarly reached ROM flow and hit its 6,775-second timeout. Both terminal logs and hashes are under [`local-fallback/`](local-fallback/). Row 1's local attempt ran from about 06:57 to 08:46 MDT; the active run was intentionally stopped after its Slurm rerun began. Its partial log and stop record are under [`local-fallback/attempt-04-row1/`](local-fallback/attempt-04-row1/).

## Submission

Slurm job 591 is the original array from the immutable snapshot above. Job 606 reruns rows 1–3 from a fresh immutable copy under `/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-02`. Jobs 609 and 613 rebuilt and finalized the shared c339 toolchain and firmware inputs in the protected location. Job 611 is the fresh array for rows 8–51 under `/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-03`; it is held until the old test arrays finish. Its script, manifest, and submission snapshot are under [`resubmission-20261012-03/`](resubmission-20261012-03/). Original preflight and submission records remain in `preflight.txt` and `submission.txt`.

At the 15:23 MDT checkpoint, rows 16–21 remained active in job 669 and rows 22–51 were pending at array throttle 6. All six protected c339 VVP processes were using about 99.9% CPU and 1.0 GiB RSS each; all were under their per-test timeouts, with no result JSON or terminal marker yet. This is not a test verdict. The process and log snapshot is recorded in [`resubmission-20261012-05/status-15-23.txt`](resubmission-20261012-05/status-15-23.txt).

At 16:04 MDT, job 669 tasks 16–21 remained active and rows 22–51 pending. The six simulations had each consumed about 1:53 of CPU time, remained under their per-test limits, and had no result JSON; the previous top-level PASS in this sweep took 2:18:44. No verdict is inferred. See [`resubmission-20261012-05/status-16-04.txt`](resubmission-20261012-05/status-16-04.txt).

At 16:15 MDT, row 18 (`smoke_test_doe_kv_ocp_progress`) completed PASS on job 669: the runner/status, JSON, and simulator pass marker agree; it took 2:02:55 and peaked at 1,852,448 KiB. Five prior tasks (16, 17, 19–21) and new task 22 are running, with rows 23–51 pending. The ledger now has 17 terminal verdicts, six running rows, and 29 pending. Full task evidence is in [`terminal-results/task-18-smoke_test_doe_kv_ocp_progress/`](terminal-results/task-18-smoke_test_doe_kv_ocp_progress/); queue/result details are in [`resubmission-20261012-05/status-16-15.txt`](resubmission-20261012-05/status-16-15.txt).


## Current checkpoint — 18:36 MDT, 2026-10-12

Rows 0–21 and 27 now have terminal outcomes: 15 TIMEOUT, 5 PASS, and 3 FAIL. Row 27 (`smoke_test_qspi`) failed during firmware compilation because its test source references QSPI register symbols absent from the generated register header at the pinned Caliptra revision; simulation did not start. Rows 22–26 and 28 are running on job 669; rows 29–51 are pending at throttle 6. The two six-hour retries (`smoke_test_strap` and `smoke_test_sha256`, rows 50–51) remain queued. The hardware-config link failure has an evidenced upstream inline-linkage cause in [`hwconfig-linkdiag/README.md`](hwconfig-linkdiag/README.md).

At 18:27 MDT the queue remains rows 22–26 and 28 running, with rows 29–51 pending at throttle 6. DAN-DESKTOP had been up 9:52; all six VVP processes were active at 99.9% CPU. Their simulator logs remained 45,302 bytes with no PASS/FAIL/Finished marker, result JSON, or task status file. This is nonterminal simulation activity, not a verdict. The queue, process, log-size, and marker snapshot is [`resubmission-20261012-05/status-18-27.txt`](resubmission-20261012-05/status-18-27.txt).

At 18:36 MDT the same six tasks remained active and rows 29–51 remained pending. Row 22's simulator log grew from 45,302 to 49,398 bytes and reached the reset assertion/deassertion messages; it still has no testcase marker, result JSON, or runner status. The other five simulator logs remained unchanged and had no terminal markers. This is progress, not a verdict; see [`resubmission-20261012-05/status-18-36.txt`](resubmission-20261012-05/status-18-36.txt).

## Current checkpoint — 19:27 MDT, 2026-10-12

Row 22 (`smoke_test_kv_securitystate`) reached its 11,240-second per-test timeout on job 669. Runner exit 124, elapsed time 3:07:20, peak RSS 1,852,368 KiB; it produced no result JSON or testcase terminal marker. Its simulator log reached reset assertion/deassertion before timing out. Rows 0–22 and 27 now have terminal outcomes: 16 TIMEOUT, 5 PASS, and 3 FAIL. Rows 23–26, 28, and 29 are RUNNING; rows 30–51 are PENDING at throttle 6, including the two six-hour retries in rows 50–51. The queue and process snapshot is [`resubmission-20261012-05/status-19-26.txt`](resubmission-20261012-05/status-19-26.txt). The hardware-config link failure remains attributed to the evidenced upstream inline-linkage cause in [`hwconfig-linkdiag/README.md`](hwconfig-linkdiag/README.md).

At 19:45 MDT, the same six tasks were still RUNNING and rows 30–51 remained pending. Task 669_24’s nested simulator log advanced to the Datavault Mini Smoke Test (49,398 bytes), but no runner status, result JSON, or terminal marker exists. Task 669_23 remains at 49,398 bytes; the other four logs are unchanged. This is simulation progress, not a verdict; see [`resubmission-20261012-05/status-19-45.txt`](resubmission-20261012-05/status-19-45.txt).

At 20:00 MDT, row 28 (`smoke_test_dma_aes_kv_short`) completed PASS on job 669. Runner status, result JSON (`passed=true`), simulator marker, and finish record agree; elapsed time was 2:24:22 with peak RSS 1,852,464 KiB (`mcycle=60,133`). Rows 0–22 and 27–28 now have terminal outcomes: 16 TIMEOUT, 6 PASS, and 3 FAIL. Rows 23–26, 29, and 30 are RUNNING; rows 31–51 remain pending at throttle 6. The queue snapshot is [`resubmission-20261012-05/status-19-58.txt`](resubmission-20261012-05/status-19-58.txt), and full row evidence is in [`terminal-results/task-28-smoke_test_dma_aes_kv_short/`](terminal-results/task-28-smoke_test_dma_aes_kv_short/).

At 20:10 MDT, job 669 still has six active tasks and 21 pending. Task 669_23 has run 3:08:53 against its 11,601-second cap, but still has no status file, result JSON, or testcase marker; it remains RUNNING. Rows 24–26, 29, and 30 also have no terminal markers. See [`resubmission-20261012-05/status-20-10.txt`](resubmission-20261012-05/status-20-10.txt).

At 20:22 MDT, task 669_23 reached its 11,601-second TIMEOUT (3:13:21; peak RSS 1,852,440 KiB). Task 669_31 ended in a firmware-build FAIL after GCC reported implicit declarations for two ABR ISR callbacks; simulation did not start. Rows 0–23, 27–28, and 31 now have 27 terminal outcomes: 17 TIMEOUT, 6 PASS, and 4 FAIL. Rows 24–26, 29, 30, and 32 are RUNNING; rows 33–51 are PENDING at throttle 6. Row 31’s selected matrix name is `smoke_test_ecc_errortrigger4`, but its case folder/YAML path names `smoke_test_ecc_errortrigger5`; the YAML test name matches row 31. See [`resubmission-20261012-05/status-20-22.txt`](resubmission-20261012-05/status-20-22.txt) and the two task evidence folders.

## Current checkpoint — 20:36 MDT, 2026-10-12

Row 24 (`smoke_test_datavault_mini`) reached its configured 12,257-second timeout on job 669: runner exit 124, elapsed 3:24:17, peak RSS 1,852,492 KiB, and no result JSON, testcase terminal marker, or finish record. Rows 0–24, 27–28, and 31 now have 28 terminal outcomes: 18 TIMEOUT, 6 PASS, and 4 FAIL. Rows 25, 26, 29, 30, 32, and 33 are RUNNING; rows 34–51 are PENDING at throttle 6. The live queue/process snapshot is [`resubmission-20261012-05/status-20-36.txt`](resubmission-20261012-05/status-20-36.txt), and row 24's raw logs and hashes are in [`terminal-results/task-24-smoke_test_datavault_mini/`](terminal-results/task-24-smoke_test_datavault_mini/).

## Current checkpoint — 20:54 MDT, 2026-10-12

Row 25 (`smoke_test_aes_gcm`) reached its 13,210-second timeout on job 669: runner exit 124, elapsed 3:40:10, and peak RSS 1,852,500 KiB. The compile log has warnings but no errors and a 367,680,829-byte VVP artifact was present; no result JSON, simulation log, testcase marker, or finish record was preserved, so test progress is unknown. Rows 0–25, 27–28, and 31 now have 29 terminal outcomes: 19 TIMEOUT, 6 PASS, and 4 FAIL. Rows 26, 29, 30, 32, 33, and 34 are RUNNING; rows 35–51 are PENDING at throttle 6. See [`resubmission-20261012-05/status-20-54.txt`](resubmission-20261012-05/status-20-54.txt) and [`terminal-results/task-25-smoke_test_aes_gcm/`](terminal-results/task-25-smoke_test_aes_gcm/).

## Current checkpoint — 21:06 MDT, 2026-10-12

Row 26 (smoke_test_dma_aes_gcm_short_1_dword) reached its 13,341-second per-test timeout: runner exit 124, elapsed 3:42:21, peak RSS 1,852,348 KiB. Its compile artifact exists, but no result JSON, simulation log, testcase terminal marker, or finish record was preserved. The ledger now marks 20 timeouts as TIMEOUT (progress unknown); six rows have PASS, four have FAIL, and six remain RUNNING. To prepare M5b, only previously pending tasks 669_36–669_51 were canceled; tasks 669_29, 30, 32–35 remain running. The cancellation record and queue snapshot are in [m5b-progress-20261012/](m5b-progress-20261012/); row 26 evidence is in [terminal-results/task-26-smoke_test_dma_aes_gcm_short_1_dword/](terminal-results/task-26-smoke_test_dma_aes_gcm_short_1_dword/).

## Current checkpoint — 23:40 MDT, 2026-10-12

Task 669_29 ended at its configured timeout and task 669_35 failed on `ERR_ECC_PRIVKEY_NOT_STABLE`. The ledger now has 21 `TIMEOUT (progress unknown)`, six PASS, five FAIL, four RUNNING, and 16 `CANCELLED_BEFORE_START` rows. Tasks 669_30, 669_32, 669_33, and 669_34 remain running under their existing limits. Row 35 remains in the original 17-row resubmission set even though its earlier run failed. Raw evidence for rows 29 and 35 is under [`terminal-results/`](terminal-results/README.md).

## Current checkpoint — 00:29 MDT, 2026-10-13

Task 669_30 (`iccm_lock`) reached its 15,639-second timeout after 4:20:39, with peak RSS 1,852,396 KiB. The simulator log reached the first pass through ICCM, but no result JSON, testcase marker, or mcycle heartbeat exists; it remains `TIMEOUT (progress unknown)`, not a hang. The ledger now has 22 timeouts, six PASS, five FAIL, three RUNNING, and 16 `CANCELLED_BEFORE_START` rows. Tasks 669_32–34 remain running; smoke verification job 785 remains pending after array 669. Row 30 evidence is in [`terminal-results/task-30-iccm_lock/`](terminal-results/task-30-iccm_lock/).

## Current checkpoint — 00:51 MDT, 2026-10-13

Task 669_32 (`smoke_test_ecc_keygen`) reached its 16,033-second timeout after 4:27:13, with peak RSS 1,852,504 KiB. It has no result JSON, testcase marker, or heartbeat, so the result is `TIMEOUT (progress unknown)`, not a hang. The ledger now has 23 timeouts, six PASS, five FAIL, two RUNNING, and 16 `CANCELLED_BEFORE_START` rows. Tasks 669_33–34 remain under their existing limits, and smoke verification job 785 remains pending after array 669. Row 32 evidence is in [`terminal-results/task-32-smoke_test_ecc_keygen/`](terminal-results/task-32-smoke_test_ecc_keygen/).

## Current checkpoint — 01:04 MDT, 2026-10-13

Task 669_33 (`smoke_test_ecc_sign`) reached its 16,033-second timeout after 4:27:13, with peak RSS 1,852,384 KiB. It has no result JSON, testcase marker, or heartbeat, so its status is `TIMEOUT (progress unknown)`, not a hang. The ledger now has 24 timeouts, six PASS, five FAIL, one RUNNING, and 16 `CANCELLED_BEFORE_START` rows. Task 669_34 remains within its existing limit; smoke verification job 785 remains pending after array 669. Row 33 evidence is in [`terminal-results/task-33-smoke_test_ecc_sign/`](terminal-results/task-33-smoke_test_ecc_sign/).

## Current checkpoint — 01:22 MDT, 2026-10-13

Task 669_34 (`smoke_test_ecc_verify`) reached its 16,033-second timeout after 4:27:13, with peak RSS 1,852,436 KiB. It has no result JSON, testcase marker, or heartbeat, so it remains `TIMEOUT (progress unknown)`, not a hang. All job 669 tasks are now terminal: 25 timeouts, six PASS, five FAIL, and 16 `CANCELLED_BEFORE_START` rows. Smoke verification job 785 has started and is RUNNING; no rerun array has been submitted. Row 34 evidence is in [`terminal-results/task-34-smoke_test_ecc_verify/`](terminal-results/task-34-smoke_test_ecc_verify/).

## Current checkpoint — 01:45 MDT, 2026-10-13

Smoke verification job 785 completed successfully. `result.json` reports `passed=true`, `testname=smoke_test_kv`, and `sim_exit=0`; the simulator log has one `* TESTCASE PASSED` marker and no failure marker. The runner status records `firmware_outcome=PASS`, `heartbeat_verification=PASS`, and two flushed heartbeats; mcycle advanced from 0 to 1,722 by wall time 300 seconds. The 42-row rerun selection is ready, ordered by expected mcycle cost, and will use throttle 6, one CPU, and 3 GiB per task. See [`m5b-verification-20261012-01/`](m5b-verification-20261012-01/) and [`m5b-rerun-20261012-01/`](m5b-rerun-20261012-01/).

## Current checkpoint — 01:53 MDT, 2026-10-13

Instrumented array 799 was submitted from the immutable M5b source and protected c339 toolchain, with 42 rows, one CPU and 3 GiB per task, a six-task throttle, and 6h10m allocation. Slurm accepted the array; per-task heartbeat visibility is pending the next log check. The recorded selection and submission details are in [`m5b-rerun-20261012-01/`](m5b-rerun-20261012-01/).

## Current checkpoint — 02:07 MDT, 2026-10-13

Array 799 tasks 1–6 are RUNNING, with tasks 7–42 pending at the six-task throttle. Each running simulator log has three heartbeats; mcycle rose from 0 at wall time 0 to 4,306–4,347 by wall time 600 seconds. No task has a terminal marker yet, and none meets the flat-mcycle hang rule. The M5b completion checkpoint is met: the runner change is committed and pushed, `smoke_test_kv` PASS and heartbeat behavior are verified, the timeout ledger is updated, and the instrumented rerun is active with heartbeats visible. Per-task values are recorded in [`m5b-rerun-20261012-01/heartbeat-snapshot-20261013-0207.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-0207.txt).

## Current checkpoint — 02:59 MDT, 2026-10-13

Array 799 tasks 1–6 are still RUNNING; tasks 7–42 are PENDING at throttle 6. Each running task has 14 heartbeats, with mcycle increasing from 0 to 27,381–27,548 by wall time 3,900 seconds. No terminal result marker is present, and no task meets the flat-mcycle hang rule. The requested M5b checkpoint is satisfied while the longer array continues; current values are in [`heartbeat-snapshot-20261013-0259.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-0259.txt).

## Current checkpoint — 05:08 MDT, 2026-10-13

Array 799 tasks 1–6 reached their configured per-test timeouts and are recorded as TIMEOUT with their last mcycle. Tasks 7–12 remain RUNNING and tasks 13–42 are PENDING at throttle 6. All six active heartbeats advanced since the previous check; none meets the 30-minute flat-mcycle hang rule. Overlay jobs 823 (UART and QSPI) and 826 (corrected errortrigger5) are also RUNNING, with advancing heartbeats and no terminal markers. See [`heartbeat-snapshot-20261013-0508.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-0508.txt).

## Current checkpoint — 05:58 MDT, 2026-10-13

Array task 799_7 (`smoke_test_dma_aes_gcm_wr_enc_axi_err`) reached its configured 7,628-second cap. Its wrapper recorded exit 137 as `INFRA_ERROR`, but `/usr/bin/time` recorded exactly 7,628 seconds and 1,852,420 KiB peak RSS; the corrected result is `TIMEOUT`, with last heartbeat `wall_s=7500 mcycle=51400` and maximum flat interval 0 seconds. Tasks 799_8–13 are RUNNING, with task 13 just starting; tasks 14–42 remain pending at throttle 6. Overlay jobs 823 and 826 continue with advancing heartbeats. The raw timeout evidence is in [`timeout-reclassification-799/`](m5b-rerun-20261012-01/timeout-reclassification-799/), and active heartbeats are in [`heartbeat-snapshot-20261013-0558.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-0558.txt).

## Current checkpoint — 06:07 MDT, 2026-10-13

Array task 799_8 (`smoke_test_kv_lock_use_mid_read`) reached its configured timeout: 7,956 seconds, exactly matching `/usr/bin/time`'s `2:12:36`, with 1,852,348 KiB peak RSS. Its wrapper reported exit 137 as `INFRA_ERROR`; the corrected result is `TIMEOUT`, last heartbeat `wall_s=7800 mcycle=54368`, and maximum flat interval 0 seconds. Tasks 799_9–14 are RUNNING, 15–42 remain pending at throttle 6, and the three overlay simulations continue with advancing heartbeats. See [`timeout-reclassification-799/`](m5b-rerun-20261012-01/timeout-reclassification-799/) and [`heartbeat-snapshot-20261013-0607.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-0607.txt).

## Current checkpoint — 06:23 MDT, 2026-10-13

Array task 799_9 (`smoke_test_sram_ecc`) reached its configured timeout: 8,876 seconds, exactly matching `/usr/bin/time`'s `2:27:56`, with 1,852,468 KiB peak RSS. Its wrapper reported exit 137 as `INFRA_ERROR`; the corrected result is `TIMEOUT`, last heartbeat `wall_s=8700 mcycle=59294`, and maximum flat interval 0 seconds. Tasks 799_10–15 are RUNNING, 16–42 remain pending at throttle 6, and the three overlay simulations continue with advancing heartbeats. The timeout records are in [`timeout-reclassification-799/`](m5b-rerun-20261012-01/timeout-reclassification-799/), with the live snapshot in [`heartbeat-snapshot-20261013-0623.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-0623.txt).

## Current checkpoint — 19:06 MDT, 2026-10-13

After Slurm reopened, array 799 tasks 36–39, 41, and 42 were live; task 40 had ended before simulation. Task 799_40 (`smoke_test_ras`) is recorded as **FAIL** after a 30.90-second firmware build: the linker could not resolve `service_soc_ifc_notif_intr`, no heartbeat or result JSON was produced, and final mcycle is N/A. Its compiler/resource logs and hashes are in [`result-task40-smoke-test-ras-fail/`](result-task40-smoke-test-ras-fail/); its 373,110,141-byte build output was removed after recording the result.

Fresh array 895 was submitted at 19:02 for only the four maintenance-cancelled cases (original array tasks 28, 30, 34, and 35), using the same pinned source/toolchain, 1 CPU and 3 GiB per task, original per-test timeouts, and throttle 6. The initial queue view showed tasks 895_1–3 RUNNING and 895_4 PENDING for resources; the next view still showed the remaining 799 tasks running. No local duplicate was started. See [`cancelled-reruns-c339-20261013-01/`](cancelled-reruns-c339-20261013-01/) for the staged selection, hashes, and submission record.

The main ledger has 39 terminal rows (26 TIMEOUT, 5 FAIL, 4 CANCELLED-FOR-MAINTENANCE, 4 PASS) and three RUNNING in array 799. The cancellation rows retain their historical status until the fresh runs finish and are recorded; all four fresh runs in array 895 are also RUNNING.

## Current checkpoint — 19:18 MDT, 2026-10-13

The 19:18 Slurm snapshot shows array 799 tasks 36–39, 41, and 42 RUNNING, with task 40 already recorded as a firmware-build FAIL. Fresh array 895 tasks 1–3 are RUNNING and task 4 is queued for resources. All nine active simulators emitted a heartbeat at wall time 900 seconds; the last simulator-log writes were 19:15 for 799 and 19:17 for 895, so these are early samples and none meets the 30-minute flat-heartbeat hang rule. Per-task mcycles and queue state are in [`m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1918.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1918.txt).

## Current checkpoint — 19:29 MDT, 2026-10-13

Array 799 still has tasks 36–39, 41, and 42 RUNNING; fresh array 895 has tasks 1–3 RUNNING and task 4 PENDING for resources. All nine active simulators advanced from wall time 900 to 1,500 seconds and increased mcycle by about 4,300 during the last interval. Host uptime exceeds their elapsed times; no ghost or 30-minute flat-heartbeat task was found. No new terminal results were ready for collection. See [`m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1929.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1929.txt).

## Current checkpoint — 19:41 MDT, 2026-10-13

The six remaining 799 tasks and the first three 895 tasks remain RUNNING; 895_4 remains PENDING for resources. Each active simulator advanced since the 19:29 snapshot. The host has been up longer than every active job, and no 30-minute flat-heartbeat case is present. There were no terminal results to collect or clean; see [`m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1941.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1941.txt).

## Current checkpoint — 19:51 MDT, 2026-10-13

Array 799 tasks 36–39, 41, and 42 remain RUNNING. Fresh array 895 tasks 1–3 remain RUNNING, while task 4 is still PENDING for resources. All nine active simulations advanced since the prior checkpoint; none meets the 30-minute flat-heartbeat criterion. No terminal rows were ready for collection or cleanup. The full snapshot is [`m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1951.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-1951.txt).

## Current checkpoint — 23:55 MDT, 2026-10-13

799_36 failed on `ERR_ECC_PRIVKEY_NOT_STABLE`; 799_41 and 799_42 passed. Their final heartbeats are recorded in the TSV, and those three output trees were removed after evidence was committed, freeing 1,126,991,048 bytes. Tasks 799_37–39 remain RUNNING. Fresh 895_4 (source row 44, previously cancelled as 799_35) passed with final heartbeat mcycle 62,186, and its output tree was removed after commit. Fresh 895_1 and 895_2 reached their per-test timeouts with final heartbeat mcycles 62,443 and 126,506; their logs and wrapper metadata are SHA-verified under [`cancelled-reruns-c339-20261013-01/timeout-evidence-895/`](cancelled-reruns-c339-20261013-01/timeout-evidence-895/). Their output trees were removed after commit, freeing 751,595,456 bytes. Fresh 895_3 remains RUNNING. All four active heartbeats advanced, and none meets the 30-minute flat-heartbeat rule. See [`m5b-rerun-20261012-01/heartbeat-snapshot-20261013-2354.txt`](m5b-rerun-20261012-01/heartbeat-snapshot-20261013-2354.txt).


## Current checkpoint — 00:17 MDT, 2026-10-14

Fresh array 936 re-runs the four maintenance-cancelled rows at 1 CPU, 3 GiB, 6h10m, throttle 6. All tasks were RUNNING at first observation: 936_1→source row 37, 936_2→39, 936_3→43, and 936_4→44. The pinned Icarus source and binary were verified. Tasks 799_37 and 799_38 remain RUNNING; their latest heartbeats are wall 18,900 seconds, mcycle 138,820 and 138,750. Task 799_39 is a FAIL at mcycle 59,872 with the ECC private-key stability assertion. Fresh task 895_3 reached its 18,167-second cap and is TIMEOUT at mcycle 78,485. The selected evidence for both terminal tasks was SHA-verified, committed, and their output trees removed, freeing 751,554,560 bytes of filesystem space. No task meets the 30-minute flat-heartbeat rule. See [the 00:16 snapshot](m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0016.txt) and [fresh rerun job 936](cancelled-reruns-c339-20261014-01/README.md).


## Current checkpoint — 00:29 MDT, 2026-10-14

All four fresh job 936 reruns remain RUNNING and their mcycles advanced from wall 300 to wall 900. The two remaining original tasks, 799_37 and 799_38, advanced to wall 19,500 and mcycles 143,339 and 143,178. Task 799_39 is recorded FAIL; the prior fresh task 895_3 is recorded TIMEOUT. No active task meets the 30-minute flat-heartbeat rule. See the [00:29 heartbeat snapshot](m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0029.txt).


## Current checkpoint — 00:39 MDT, 2026-10-14

All six active simulations advanced. The 799_37/38 runs are at wall 20,100 seconds; the fresh job 936 reruns are at wall 1,500 seconds. Their latest mcycles and scheduler state are in the [00:39 snapshot](m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0039.txt). No task meets the 30-minute flat-heartbeat rule.


## Current checkpoint — 00:49 MDT, 2026-10-14

All six simulations remain RUNNING. The four fresh job 936 rows are at wall 2,100 seconds; original rows 799_37/38 are at wall 20,700/20,400 seconds. All mcycles advanced since 00:39, with no row meeting the 30-minute flat-heartbeat rule. See the [00:49 snapshot](m5b-rerun-20261012-01/heartbeat-snapshot-20261014-0049.txt).


## Current checkpoint — 07:33 MDT, 2026-10-14

The older 799 array is terminal: task 799_37 TIMEOUT at the exact 21,600-second cap (last heartbeat mcycle 157,015), and 799_38 PASS (last heartbeat mcycle 149,887). Fresh job 936 was interrupted by a DAN-DESKTOP reboot before any wrapper completion record; its four partial attempts have no result JSON or testcase markers and are not test outcomes. The host is back up, and I’m preparing a new isolated four-row rerun. Evidence and the 07:31 queue snapshot are recorded under the wave-1 run folders.


After commit `6e16604`, I removed the six completed/interrupted output trees and their run-local caches from DAN-DESKTOP. Their combined allocated tree size was 2,263,652,833 bytes; `/home/dsell` available space increased by 2,267,467,776 bytes. Shared toolchains and the unrelated queued work were untouched.

## Current checkpoint — 07:39 MDT, 2026-10-14

Corrected fresh array 955 is running the four rows previously cancelled for maintenance (799_28, 799_30, 799_34, and 799_35), mapped to source rows 37, 39, 43, and 44. All four tasks were RUNNING by 07:39:21, with one CPU and 3 GiB per task, a 6h10m allocation, and array throttle 6. No local duplicate is running. Array 949 exited before test startup because its selection file was staged at the wrong path; its setup-error logs are preserved and it produced no test result. Pinned source/toolchain hashes were re-verified before array 955. See [`cancelled-reruns-c339-20261014-02/`](cancelled-reruns-c339-20261014-02/) and [`cancelled-reruns-c339-20261014-03/`](cancelled-reruns-c339-20261014-03/).

## Current checkpoint — 07:52 MDT, 2026-10-14

Array 955 remains RUNNING on all four reruns. Each simulator has three progress heartbeats through wall 600 seconds; latest mcycles are 4,500, 4,500, 4,512, and 4,512. VVP processes are consuming CPU, but no row has a terminal marker or result JSON. None meets the 30-minute flat-heartbeat hang threshold. Full details are in [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0752.txt`](cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0752.txt).

## Current checkpoint — 08:03 MDT, 2026-10-14

Array 955 remains active on all four rows. Latest heartbeats are at wall 1,200 seconds with mcycles 9,185, 9,185, 9,231, and 9,238. VVP is using CPU; no terminal result has appeared, and the latest heartbeat was only about 3.5 minutes old. No row meets the 30-minute hang threshold. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0803.txt`](cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0803.txt).

## Current checkpoint — 08:14 MDT, 2026-10-14

Array 955 remains RUNNING on all four rows, but there has been no new heartbeat since `wall_s=1800` (last log write 07:59:50 MDT). Latest mcycles are 13,882, 13,880, 13,939, and 13,953. Each VVP still uses 99.9% CPU, and the no-progress interval is about 14 minutes, below the 30-minute hang rule. No terminal result is available. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0814.txt`](cancelled-reruns-c339-20261014-0814.txt).

## Current checkpoint — 08:25 MDT, 2026-10-14

Array 955 remains RUNNING on all four rows and advanced to wall 2,700 seconds. Latest mcycles are 20,838, 20,837, 20,913, and 20,939; no result JSON or terminal marker exists yet. The heartbeat gap observed at 08:14 resolved, and no row meets the 30-minute hang threshold. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0825.txt`](cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0825.txt).

## Current checkpoint — 08:36 MDT, 2026-10-14

Array 955 remains active on all four reruns, with heartbeats advanced to wall 3,300 seconds and mcycles 25,630, 25,628, 25,708, and 25,738. No result JSON or terminal testcase marker is present. All four VVPs continue using CPU. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0836.txt`](cancelled-reruns-c339-20261014-0836.txt).

## Current checkpoint — 08:46 MDT, 2026-10-14

Array 955 remains RUNNING on all four rows, now at wall 3,900 seconds. Latest mcycles are 30,335, 30,319, 30,412, and 30,446. Heartbeats continue to advance; no terminal result has appeared. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0846.txt`](cancelled-reruns-c339-20261014-0846.txt).

## Current checkpoint — 08:57 MDT, 2026-10-14

All four array-955 rows remain RUNNING, now at wall 4,500 seconds with mcycles 35,184, 35,164, 35,259, and 35,299. No terminal results have appeared yet. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0857.txt`](cancelled-reruns-c339-20261014-0857.txt).

## Current checkpoint — 09:08 MDT, 2026-10-14

Array 955 remains active on all four rows, with latest heartbeats at wall 5,100 seconds and mcycles 39,977, 39,950, 40,054, and 40,094. No testcase result is available yet. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0908.txt`](cancelled-reruns-c339-20261014-0908.txt).

## Current checkpoint — 09:19 MDT, 2026-10-14

All four array-955 rows remain RUNNING, now at wall 5,700 seconds and mcycles 44,777, 44,743, 44,851, and 44,897. No terminal outcome is available yet. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0919.txt`](cancelled-reruns-c339-20261014-0919.txt).

## Current checkpoint — 09:29 MDT, 2026-10-14

Array 955 remains active on all four rows, now at wall 6,300 seconds with mcycles 49,641, 49,602, 49,715, and 49,764. No test outcome has appeared yet. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0929.txt`](cancelled-reruns-c339-20261014-0929.txt).

## Current checkpoint — 09:40 MDT, 2026-10-14

Array 955 remains active. Tasks 1–3 are at wall 6,900 seconds with mcycles 54,491, 54,453, and 54,567; task 4 is at wall 7,200 with mcycle 57,034. No terminal outcomes are available yet. See [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0940.txt`](cancelled-reruns-c339-20261014-0940.txt).

## Current checkpoint — 09:53 MDT, 2026-10-14

Fresh rerun 955_4 passed (original 799_35 / source row 44), with final heartbeat mcycle 59,434. The three other reruns remain active: task 1 is at wall 7,500 / mcycle 59,285; task 2 at wall 7,800 / mcycle 61,613; task 3 at wall 7,500 / mcycle 59,366. Evidence for the pass is under [`cancelled-reruns-c339-20261014-03/pass-evidence-955/`](cancelled-reruns-c339-20261014-03/pass-evidence-955/); the full checkpoint is [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-0953.txt`](cancelled-reruns-c339-20261014-0953.txt).

The passed task's build/output and Python cache trees were deleted after its evidence commit, removing 377,301,648 bytes (about 0.351 GiB); tasks 955_1–3 remained active. Cleanup record: [`cancelled-reruns-c339-20261014-03/pass-evidence-955/cleanup-task955_4-20261014.txt`](cancelled-reruns-c339-20261014-03/pass-evidence-955/cleanup-task955_4-20261014.txt).

## Current checkpoint — 10:05 MDT, 2026-10-14

Task 955_4 remains PASS at final heartbeat mcycle 59,434. Tasks 955_1–3 remain RUNNING: task 1 is at wall 8,700 / mcycle 6,195, task 2 at wall 8,400 / mcycle 66,338, and task 3 at wall 8,700 / mcycle 63,534. Task 1's mcycle decreased from 59,285 at wall 7,500 to 1,333 at wall 8,100, then advanced; the log records this without an inferred cause. Snapshot: [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-1005.txt`](cancelled-reruns-c339-20261014-1005.txt).

## Current checkpoint — 10:16 MDT, 2026-10-14

Task 955_4 remains PASS at final heartbeat mcycle 59,434. Tasks 955_1–3 remain RUNNING at wall 9,300, with latest mcycles 11,003, 73,443, and 64,612. No terminal result is available for these three. Snapshot: [`cancelled-reruns-c339-20261014-03/heartbeat-snapshot-20261014-1016.txt`](cancelled-reruns-c339-20261014-1016.txt).
