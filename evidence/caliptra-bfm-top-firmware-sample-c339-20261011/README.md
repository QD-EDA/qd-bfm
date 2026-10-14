# Ten-test Caliptra top-level firmware sample

The matrix has 271 YAML test rows, including 162 stock-firmware integration
rows; this sample is drawn from the 162 full-top suites. The upstream YAMLs
provide seed and plusarg metadata, but no cycle budget. The ten cases below
were ranked from their pinned C/assembly test bodies: expected-path instruction
count, bounded memory/register operations, and one-block cryptographic work.
Long watchdog waits, reset-phase tests, unbounded loops, large random-transfer
tests, and multi-case crypto suites were excluded. `expected_mcycle` is a
conservative estimate for choosing the timeout, not a measured result.

The task timeout is `ceil(3 * expected_mcycle / 7.31 + 1800)` seconds: three
times the measured 7.31 cycles/s projection plus 30 minutes for build, vector
generation, and startup. The Slurm allocation is capped at three hours, below
the requested six-hour maximum. Each task requests one CPU and 3 GiB; the array
throttle is six (18 GiB reserved at peak) because DAN-DESKTOP had 18 idle CPUs
at staging time.

All tasks use pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`,
Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`, and Icarus c339
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The normal full-top BFM profile is
used; diagnostic fast-TRNG, preload, and limited-case options are not enabled.
Run-local overlays are generated outside the pinned source checkout by the
QD-BFM runner.

Array script and selection manifest: [`array.sbatch`](array.sbatch),
[`selection.tsv`](selection.tsv). Per-test logs, statuses, and tool provenance
are retained under `runs/`.

## Current results

| Test | Result | Evidence |
|---|---|---|
| `smoke_test_strap` | TIMEOUT | `runs/smoke_test_strap/` |
| `smoke_test_veer` | PASS | `runs/smoke_test_veer/` |
| `memCpy_ROM_to_dccm` | PASS | `runs/memCpy_ROM_to_dccm/` |
| `memCpy_dccm_to_iccm` | PASS | `runs/memCpy_dccm_to_iccm/` |
| `hello_world_iccm` | PASS | `runs/hello_world_iccm/` |
| `smoke_test_hw_config` | FAIL (firmware link) | `runs/smoke_test_hw_config/` |
| `smoke_test_ahb_mux` | PASS | `runs/smoke_test_ahb_mux/` |
| `smoke_test_sha256` | TIMEOUT | `runs/smoke_test_sha256/` |
| `smoke_test_doe_rand` | PASS | `runs/smoke_test_doe_rand/` |
| `smoke_test_sha256_wntz_rand` | PASS | `runs/smoke_test_sha256_wntz_rand/` |

The runner's raw `SETUP_BLOCKED` for `smoke_test_hw_config` is recorded as a
sample `FAIL` because firmware linking fails before simulation: the linker
reports the undefined callback `service_soc_ifc_notif_intr`. The linker diagnostic is preserved in
`runs/smoke_test_hw_config/firmware.log`. This is a firmware build failure,
not a simulator result. Seven cases passed and two timed out without terminal
test results. Strap reached
`SoC: Ready for Fuses deasserted` before its configured 3,852-second runner
timeout (exit 124); VVP did not emit a terminal test result. Its wall time was
1:04:12 and peak RSS was 1,859,896 KiB. `smoke_test_sha256` reached the same
flow-status poll before its configured 6,725-second runner timeout (exit 124),
with no terminal pass/fail marker; wall time was 1:52:05 and peak RSS was
1,860,216 KiB. The other two crypto cases completed: DOE random reported
`mcycle=56787`, and WNTZ random reported `mcycle=60240`; both emitted
`* TESTCASE PASSED`, had zero simulator exit, and have runner/resource/compile/
simulation evidence under their `runs/` directories. All ten array tasks are
terminal.
