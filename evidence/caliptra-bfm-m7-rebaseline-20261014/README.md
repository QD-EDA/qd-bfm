# M7: current-main Icarus rebaseline

The selected upstream pin is `dsellerbrock/iverilog-uvm` main at
`3335fe7ec1495956c8adc5788e9a53b0f1756ecf` (verified with `git ls-remote` on
2026-10-14). The build is isolated at
`/home/dsell/toolchains/iverilog-uvm-3335fe7ec1495956c8adc5788e9a53b0f1756ecf/`;
the c339 toolchain remains the comparison baseline.

The full environment manifest contains all 44 rows from
`docs/conformance/caliptra_bfm_dv_environment_matrix_2026-10-10.csv`. The
current c339 CSV classifies 19 PASS, 22 BLOCKED, and 3 FAIL. An earlier
2026-10-11 snapshot reported 12 PASS, 29 BLOCKED, and 3 FAIL; seven rows have
since advanced under c339 follow-up work. The 44-row rerun checks every row,
including those 29 historical blockers, using the same pinned Caliptra RTL and
Adams Bridge revisions. Compile and simulation share a 6,900-second cap.
`historical-matrix-20261011.tsv` freezes that earlier classification from
commit `d6f7593ed2354b0c63cc015062b01352edfb3a3c`; it confirms that seven
historical blockers now pass on c339 and the remaining 22 stay blocked.

`environment-tasks.tsv` freezes the run order and source filelists;
`c339-baseline.tsv` carries each row's current c339 classification and evidence
references. The current-main array is pinned-only, using the original pinned RTL,
Adams Bridge, and filelists without run-local compatibility patches. The c339
baseline references its per-row source/filelist overlays; row comparisons will
identify those provenance differences. The array is limited to six 1-CPU, 3-GiB
tasks. Results and concise causes will be added after logs are reviewed and
checksum-verified.

## Current-main compiler

Slurm job 1019 built and installed current main at the pinned SHA above with
`--enable-libveriuser` and one make thread. It completed successfully in
6:52 wall time; `make` peaked at 1,753,332 KiB RSS. The installed version is
Icarus 13.0-devel (`3335fe7ec`): `iverilog` SHA-256
`9b6ee458818f80d8cf51d36559f75b34a63090fabe647ab826d8ac9d86a4ef3f`, `vvp`
SHA-256 `766a18b9517be24df9786209f722cb3b8c90f2fe531609aedb1c12c0b65919a8`,
and `iverilog-vpi` SHA-256
`6dd0a9002e038dfa50f8a89278e8169108c8f200bf845cdfcdfd6eeef145adc9`. Full
provenance, versions, hashes, resource log, and build log are in
`current-main-build/`; the protected install remains at the SHA-qualified path.
The Caliptra JTAG DPI plugin was then built with that `iverilog-vpi` in job
1042; its installed SHA-256 is
`5be0c2979d40b377802044dbda068c4b3590416a7f79374ed1d7ef8be1ce396f`. Its
source hashes, build log, resource record, and copied-evidence manifest are in
`jtagdpi-build-1042/`.

## Firmware build-failure root causes

The three reported build failures reproduce on pinned RTL with GCC 15.2.0.
Both KV ECC flow cases fail to compile at `srand(time)` because their source
does not include `<stdlib.h>`. The RAS case links `caliptra_isr.c` but leaves
`service_soc_ifc_notif_intr` undefined: the pinned ISR header's inline
definition does not emit the symbol needed by that separately compiled unit.

The build-only compatibility overlays fix those mechanical issues without
editing test code or pass criteria. The KV cases preinclude `<stdlib.h>`. The
RAS overlay verifies the pinned header hash, copies it into the run output, and
changes only the ISR helper declaration to
`static inline __attribute__((used))`, making the helper available to the
linker. All checks stop after firmware image generation; they do not run VVP.

| Case | Pinned-only result | Pinned-only diagnostic | With-overlay result |
| --- | --- | --- | --- |
| `smoke_test_kv_ecc_flow1` | BUILD_FAIL | implicit declaration of `srand` at line 197 | BUILD_PASS |
| `smoke_test_kv_ecc_flow2` | BUILD_FAIL | implicit declaration of `srand` at line 197 | BUILD_PASS |
| `smoke_test_ras` | BUILD_FAIL | undefined reference to `service_soc_ifc_notif_intr` at `caliptra_isr.c:808` | BUILD_PASS |

The paired outcomes and per-case evidence paths are recorded in
`firmware-build-comparison.tsv`. The pinned-only failures are confirmed by fresh
array 1107 tasks 1–3 in `firmware-build-pinned-only-20261014/`; corrected
with-overlay builds are array 1038 tasks 1–3 in `firmware-build-rerun-1038/`.
Both arrays use the same Caliptra RTL, QD-BFM, GCC 15.2.0, and explicit
`GCC_PREFIX=riscv-none-elf`; all three pinned-only builds fail on the source
diagnostics above, while all three overlays build the images successfully.

The earlier runs remain separate harness evidence. Array 1025 used the
upstream-default `GCC_PREFIX=riscv64-unknown-elf` and stopped at Makefile
preflight. Array 1032's overly strict output check marked completed overlay
builds as failures because `iccm.hex` and `mailbox.hex` are empty; the actual
runner only requires those paths to exist and `program.hex` to be nonempty.
Array 1038 uses that runner-compatible check and its copied outputs are
checksum-verified. These are build-only checks; they do not run VVP.

## Top-level comparison set

`top-level-selection.tsv` currently contains the six c339 PASS cases and the
ten TIMEOUT cases with the highest c339 final heartbeat mcycle. The cases
retain their original per-test caps. For completed PASS rows, c339's endpoint
mcycle is the `finish` value in `result.json`; for TIMEOUT rows it is the last
progress heartbeat. Rows 39 and 44 were refreshed from fresh c339 array 1015
evidence: row 39 remains TIMEOUT at mcycle 132232 (17543 s), and row 44 remains
PASS at finish mcycle 62472 (8229 s). Their updated endpoints and cycles/s are
in `top-level-selection.tsv`; raw evidence is in
`../caliptra-bfm-top-firmware-wave1-c339-20261012/cancelled-reruns-c339-20261014-04/task1015_2/`
and `task1015_4/`. Array 1043 is at throttle 6 with an afterany dependency on
the 44-row array 1021, so environment outcomes cannot suppress the independent
top-level comparison. It will use the JTAG DPI plugin built with the
current-main `iverilog-vpi` (job 1042).

The `expected_mcycle` field in the current selection carries the c339 endpoint
used for comparison: all six PASS values match their `result.json` `finish`
value, and all ten TIMEOUT values match `c339_last_heartbeat_mcycle`.

## Current execution state

At 2026-10-14 18:26 MDT, fresh c339 array 1015 had completed all four
post-maintenance reruns: tasks 1-3 were TIMEOUT at their per-test caps and task
4 passed. Their evidence checksums verify, and 1.51 GB of run output/cache was
removed. Current-main environment array 1021 is running at throttle 6; top-level
array 1043 remains pending `afterany:1021`. The collectors wait in 600-second
intervals, copy and verify evidence, then remove completed build/output trees.

At 19:08 MDT, `1021_1`, `1021_27`, `1021_28`, and `1021_29` were still
running; each VVP process was using about 100% of one CPU after 48–49 minutes.
Their simulator logs had not grown since startup, but the live processes were
actively executing. Top-level array 1043 remained pending on `afterany:1021`.

At 19:26 MDT, 40/44 rows had terminal logs: 9 valid PASS, 1 FAIL
(`cbd_sampler_tb`), 1 VVP SIM_ABORT (`butterfly_top_tb`), and 29 BLOCKED. I
reclassified `power2round_tb`, `ecc_montgomerymultiplier_tb`, and
`entropy_src_tb` as BLOCKED despite PASS markers: their logs show failed input
generation or zero test vectors. `masking_tb` has a valid 5-test PASS. The same
four VVPs remained active at about 100% CPU after 65 minutes; their logs stayed
quiet and the 6,900-second per-test caps remain in force. The butterfly abort
also reproduces on c339 in the reduced VVP probes, so it is not a new
current-main simulator defect.

At 20:18 MDT, environment array 1021 had 44/44 terminal results. The outcome
counts are 9 PASS, 4 TIMEOUT, 1 FAIL, 1 SIM_ABORT, and 29 BLOCKED. The four
timeouts reached the 6,900-second simulation cap. Of the 29 rows classified
BLOCKED on 2026-10-11, 23 remain BLOCKED, four now TIMEOUT, one passes with
valid tests, and one aborts in VVP. Of the 12 historical PASS rows, eight
remain PASS and four are now blocked; of three historical FAIL rows, one still
fails and two are blocked. The row-level c339/current-main/cause comparison is
in `environment-comparison.tsv`.

The 29 current BLOCKED rows consist of 22 compile or filelist incompatibilities
and seven unavailable test inputs or generator dependencies. Three apparent
PASS markers were reclassified as BLOCKED after checking their logs: the
power2round generator failed, Montgomery had no vector file, and entropy_src
ran zero tests. `masking_tb` is a valid five-test PASS. The `cbd_sampler_tb`
failure reports too few valid queue samples. `butterfly_top_tb` aborts after
missing `kyber_zeta.txt` input and a VVP event-wait assertion. A reduced
fork/clock-loop reproducer aborts on both c339 and current main, while its
automatic-task control passes; the crash is filed as
[issue #596](https://github.com/dsellerbrock/iverilog-uvm/issues/596) with the
`from-caliptra-dv` label.

The 44-row archive was SHA-256 verified before the remote run tree was removed.
Only logs, result records, source metadata, and checksums were retained; the
build and simulation outputs were deleted after collection.

The six top-level rows that passed on c339 have now also passed on current
main. Each finished at the same mcycle endpoint as its c339 run. Current-main
throughput is 7.589–7.744 cycles/s, or 1.0103–1.1032x c339 (mean ratio
1.0663). Per-row elapsed times, cycles/s, and checksum-verified evidence are
in `top-level-results.tsv` and `top-level-task1043_1/` through
`top-level-task1043_6/`. The six corresponding remote run trees have been
removed after collection. All ten selected c339 TIMEOUT comparisons have now reached their caps and are
recorded as TIMEOUT: `smoke_test_kv_swwe_lock` (159,527 mcycle; 1.0161x c339),
`smoke_test_ecc_verify` (116,527; 1.0474x),
`smoke_test_dma_aes_gcm_short_1_dword` (85,169; 0.9090x),
`smoke_test_datavault_mini` (81,008; 0.9423x), `smoke_test_aes_gcm`
(95,376; 1.0418x), `smoke_test_ecc_sign` (118,808; 1.0316x),
`smoke_test_ecc_keygen` (119,398; 1.0372x), `smoke_test_ecc_errortrigger3`
(126,965; 1.0446x), `kv_entry_read_err` (128,141; 0.9690x), and
`jtag_tap_mbox` (110,636; 1.0229x). Timeout-case throughput was 6.384–7.447
cycles/s (0.9090–1.0474x c339). Each raw runner status says signal exit 137, but
each resource log records elapsed time equal to its selected cap; the collector
records TIMEOUT and preserves the raw exit code and logs. All 16 array 1043 rows
are now terminal: the six c339 PASS rows passed again, and all ten c339 TIMEOUT
rows timed out again. The fresh c339 reruns for original array 799 tasks 28, 30, 34, and 35 all
completed in array 1110 at throttle 6: task 35 passed at mcycle 62472; tasks
28, 30, and 34 timed out at last mcycles 62479, 126060, and 79377. See the
[rerun table](../caliptra-bfm-top-firmware-wave1-c339-20261012/cancelled-reruns-c339-20261014-05/results.tsv).

## Cleanup

After recording results, cleanup removed 39 source snapshots, 154 output trees,
5 build directories, and 42 Python cache directories from A2's Slurm area.
Logs, result text, and source metadata were retained in the checksummed archive
`cleanup-retained-evidence.tar.gz` (SHA-256
`3b09abca9284c0619a83bef12aa249cea026bf809c3aa71343f157dcd14aa9a6`). The
measured free-space increase was 5,507,518,464 bytes (5.13 GiB); details are in
`cleanup-dan-desktop-20261014.json`. The local butterfly probe's two recorded
`.vvp` outputs were also removed after their hashes and results were retained.
