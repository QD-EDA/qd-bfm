# Firmware build compatibility reruns

This three-row array reruns the terminal firmware-build failures from the pinned top-firmware sweep with the opt-in build-time compatibility headers. The pinned-only baseline remains unchanged and is linked below. The overlay is force-included only for the selected firmware build; testcase C, vectors, simulator, result scanner, and pass criteria are unchanged.

## Pins and execution

- QD-BFM snapshot: `0b5efd3fa67ee7e68d62914c403128ba8f400948` under `/home/dsell/toolchains/qd-bfm-0b5efd3/`.
- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Adams Bridge: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.
- Icarus c339: source `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; VVP SHA-256 `ac6cd60d97ccf128118166f10855ca75d9271a561b440d30eb010404705be60f`.
- Slurm array: one CPU and 3 GiB per task, throttle 3; each task retains its original per-row timeout from the pinned-only sweep.
- Timeout exit 137 is classified as TIMEOUT only when the recorded elapsed time matches the configured per-test cap; an earlier 137 remains an infrastructure outcome.

## Pinned-only and overlay outcomes

| Source row | Pinned-only baseline | With overlay | Overlay |
|---:|---|---|---|
| 9 `smoke_test_uart` | FAIL during firmware build: missing UART register identifiers. Evidence: [`terminal-results/task-9-smoke_test_uart/`](../terminal-results/task-9-smoke_test_uart/). | PASS, final mcycle 56,493. The test log says internal UART is disabled and skips the UART smoke test, so this confirms the compatibility build and testcase flow, not UART peripheral behavior. | `caliptra-legacy-uart-qspi-reg-compat.h` |
| 27 `smoke_test_qspi` | FAIL during firmware build: missing QSPI register identifiers. Evidence: [`terminal-results/task-27-smoke_test_qspi/`](../terminal-results/task-27-smoke_test_qspi/). | PASS, final mcycle 56,761. | `caliptra-legacy-uart-qspi-reg-compat.h` |
| 31 matrix `smoke_test_ecc_errortrigger4` | FAIL during firmware build: undeclared ABR hooks. Source case directory is `smoke_test_ecc_errortrigger5`; its YAML still says `testname: smoke_test_ecc_errortrigger4`. Evidence: [`terminal-results/task-31-smoke_test_ecc_errortrigger4/`](../terminal-results/task-31-smoke_test_ecc_errortrigger4/). | Retry job 826_1 is running; at 07:42 MDT its latest heartbeat was wall 12,300 s, mcycle 17,901, with no terminal marker. | `caliptra-errortrigger5-abr-compat.h` |

Rows 9 and 27 reference register identifiers from the generated header immediately before upstream removed UART/QSPI. The pinned RTL no longer integrates those blocks, and their old enable bits overlap current hardware-config fields. Therefore a successful C build alone does not imply a working peripheral; any resulting runtime FAIL or TIMEOUT is recorded without changing the tests.

The errortrigger4/5 discrepancy is retained in both `selection.tsv` and `result.json` (`test` is the actual case directory; `testname` is the original YAML value). The array does not rewrite the upstream YAML or count the misnamed case as a different testcase.

## Artifacts

- `array.sbatch`: exact submitted task wrapper and timeout classification.
- `selection.tsv`: source row, case path, YAML identity, timeout, and selected header.
- `runs/`: task provenance, overlay copies and hashes, build/simulation logs, result JSON, heartbeat, and resource data after collection.

Results are filled in after each row reaches PASS, FAIL, TIMEOUT, or an infrastructure outcome.

The initial array was submitted as Slurm job 823 at 04:05 MDT on 2026-10-13.
Task 3 (source row 31) reached a terminal firmware-build FAIL in 36 seconds:
the ABR hooks were force-included, then shared `mldsa.c` failed on stale
`abr_error`/`abr_notif` fields absent from errortrigger5's current interrupt
record. Its raw compiler and resource logs are preserved under
`attempt-01-row31/`; the corrected single-row retry is job 826 in the
`20261013-02` directory. Tasks 1 and 2 were still running at the 04:13 MDT
queue check.

At 04:25 MDT, jobs 823 tasks 1 and 2 were still running; task 3 remained the
initial overlay-build failure, with its retry active as job 826.

At 05:08 MDT, jobs 823 tasks 1 and 2 remain in simulation. Their latest
heartbeats are `wall_s=3600 mcycle=24172` and `wall_s=3600 mcycle=24236`;
neither log has a terminal marker.

By the 06:49 MDT queue check, jobs 823 tasks 1 and 2 had completed PASS. Their
saved simulator logs contain `* TESTCASE PASSED`, with final mcycles 56,493
and 56,761; both have matching `passed=true` result JSON and runner exit 0.
Task 3's first attempt remains a build FAIL as documented under
`attempt-01-row31/`; retry job 826_1 is still simulating and advancing. At the
07:42 MDT check its latest heartbeat was wall 12,300 s, mcycle 17,901. The
simulator log reports a lower mcycle value at wall 9,900 than at wall 9,600;
no terminal marker or result JSON is present.
