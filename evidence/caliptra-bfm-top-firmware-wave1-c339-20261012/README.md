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

As of 08:46 MDT, rows 0 and 4 have terminal `TIMEOUT` outcomes and no wave-1 PASS/FAIL has been recorded. After DAN-DESKTOP rebooted at 08:35, live VVP processes were verified for job 591 tasks 5–7; its pending range remains throttled to 3. Rows 1–3, which had no terminal results, are rerunning in fresh job 606 tasks 1–3. All three reached VVP; the local duplicate of row 1 was stopped only after task 606_1 was confirmed running. Its local `localrun_exit=143` is intentional supersession, with no local result/status file and no terminal marker. Job 591 task 4's remote duplicate was canceled without a status/result; the local row-4 timeout remains its terminal outcome. The queue/process snapshot, new submission, array script, and task-4 cancellation log are under [`resubmission-20261012-02/`](resubmission-20261012-02/). See [`local-fallback/`](local-fallback/README.md) for earlier recovery evidence.

The Mac fallback built Icarus from the exact c339 source SHA. Row 4's first local setup attempt stopped during firmware build with header-copy errors; its serial retry reached ROM flow and hit the 7,431-second timeout without a result JSON. Row 0 similarly reached ROM flow and hit its 6,775-second timeout. Both terminal logs and hashes are under [`local-fallback/`](local-fallback/). Row 1's local attempt ran from about 06:57 to 08:46 MDT; the active run was intentionally stopped after its Slurm rerun began. Its partial log and stop record are under [`local-fallback/attempt-04-row1/`](local-fallback/attempt-04-row1/).

## Submission

Slurm job 591 is the original array from the immutable snapshot above. Job 606 is the recovery array for rows 1–3, submitted from a fresh immutable copy under `/home/dsell/slurm-runs/caliptra-bfm/a2/m5-top-wave1-c339-20261012-02`; its script and submission record are linked above. Original preflight and submission records remain in `preflight.txt` and `submission.txt`.
