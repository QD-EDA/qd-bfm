# Caliptra top-level firmware sweep, wave 1

This run covers the next 50 source-backed, unverified stock-firmware integration rows from the 2026-10-10 matrix, plus one six-hour retry each for the two prior timeouts. The prior ten-test sample rows are excluded from the 50 new rows. The matrix had 162 stock-firmware integration rows before this wave: 152 unverified, seven pass, two timeout, and one firmware-link failure.

`selection.tsv` is the array manifest. It maps each matrix ID to the exact YAML under `src/integration/test_suites`, the code directory that owns that YAML, a static workload rank, an expected-cycle estimate, and the resulting timeout. This matters for cases whose YAML is stored in a shared suite directory. The runner receives both `--case` and `--case-yaml`; the result retains the matrix ID in the task evidence and the YAML's own test name in `result.json`.

The ranking is a conservative source-based approximation, not a measured cycle count. Its static score is `case_source_lines + 12 * loop_sites + 5 * wait_or_poll_sites + 8 * crypto_call_sites`, counting nonblank test-specific source lines and omitting the common ISR header. The call counts are lexical proxies, so the rank is an estimate rather than a prediction of exact runtime. Rows without case source and known high-variance or multi-vector families (randomized or large transfers, reset/watchdog, variable TRNG, multi-vector MLDSA/MLKEM/SHA3/cSHAKE, and long HMAC flows) are not ranked as short cases. The expected-cycle estimate is `min(50000, max(5000, 5000 + 80 * static_score))`. Case timeout is `min(21600, ceil(3 * expected_mcycle / 7.31 + 1800))` seconds, using the prior measured 7.31 cycles/s rate, a 3x projection, and 30 minutes for build/startup. The two retries use 21,600 seconds directly. These are timeout budgets; the actual `mcycle` is recorded per result.

The array uses one CPU and 3 GiB per task with a four-task throttle (12 GiB reserved), leaving headroom for the other jobs currently on DAN-DESKTOP while staying within the six-task milestone cap. The previous sample's peak RSS was about 1.86 GiB; 3 GiB preserves the earlier 1.25x-plus margin. The task timeout is at most six hours; the Slurm allocation is 6h10m to leave room for launch, termination, and evidence writing. `array.sbatch` preserves the runner output, raw build/simulation logs, result JSON, and resource report under `runs/<test_id>-<array_index>/`. A runner exit of 137 or 143 is recorded as `INFRA_ERROR`, not a firmware verdict; such a row must be rerun before it counts as terminal.

Pins are Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus c339 `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The per-task provenance records the staged QD commit, host, tool versions, binary hashes, exact YAML hash, command, wall time, peak RSS, and outcome.

## Compatibility diagnosis

The `smoke_test_hw_config` link failure is recorded separately in [`hwconfig-linkdiag/README.md`](hwconfig-linkdiag/README.md). Object-level symbol evidence and five build-flag probes identify an upstream C inline-linkage defect exposed by the pinned QD `-std=gnu11 -O2` build. Changing optimization either leaves the undefined symbol or introduces a different build failure; this is not a QD harness defect.

## Results

Array submission details and terminal results will be appended after the tasks finish. No wave-1 test result is claimed by this preparation commit.
