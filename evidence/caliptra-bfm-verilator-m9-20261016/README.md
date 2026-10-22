# M9: Caliptra firmware coverage on Verilator 5.052

The pinned census has 271 rows; M9 covers only the 162 `stock-firmware-test-suite` rows under `src/integration/test_suites`. The other 109 authored-stimulus and generated-UVMF rows remain `NOT_RUN_NON_FIRMWARE` because M9 excludes non-firmware benches; block-level UVM stays on Icarus per M8.

`build-ledger.py` regenerates the full 271-row result table and the 162-row run selection from the pinned source matrix and prior Icarus evidence. Existing per-row timeout budgets are reused where available; remaining firmware rows use the existing 21,600-second maximum from the wave-1 policy. The wrapper accepts an explicit source YAML path so each matrix configuration runs without changing firmware, simulator behavior, or pass criteria.

## Pins and limits

- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- QD-BFM source snapshot: Git commit `41fe54a891e8cde20b6ef8df4a2745cc4cb7cddd`
- Verilator: 5.052, binary SHA-256 `098b09b11ba7d3e904ae13d924a9e8dac8ced5c9d7c9beff3b9d36119a417581`
- Model: built with the existing Caliptra `--timing` flow and QD-BFM full-top wrapper
- Slurm: at most six tasks at once, one CPU and 3 GiB per task, seven-hour job cap; each simulation keeps its selected per-test timeout
- Icarus reference: pinned c339; at least six prior PASS rows and all previous M8 results remain retained

## Icarus comparisons

See [`disagreements.md`](disagreements.md) for every completed-result mismatch where Icarus finished; the first is an assertion-configuration mismatch.

## Root-cause findings

See [`root-causes.md`](root-causes.md) for the M8 KV classifier false positive, missing JTAG Tcl client, ROM DMA destination-map mismatch, and MBOX read-to-set behavior. The classifier and Tcl client gaps were filed as [QD-BFM issue #12](https://github.com/QD-EDA/qd-bfm/issues/12) and [issue #13](https://github.com/QD-EDA/qd-bfm/issues/13). The six Icarus-finished comparisons are in [`disagreements.md`](disagreements.md).

## Run artifacts

- [`run-selection.tsv`](run-selection.tsv): exact firmware YAMLs, timeout, and prior Icarus evidence
- [`results.tsv`](results.tsv): 271-row table; refreshed from `runs/<test_id>/result.json` by `build-ledger.py`
- [`build-model.sbatch`](build-model.sbatch): fresh pinned model build
- [`run-array.sbatch`](run-array.sbatch): firmware array with a six-task cap; the Slurm throttle was raised to 6 after the c339 reruns ended

## Current execution

The pinned Verilator model build completed as Slurm job 1424 (exit 0, 85 seconds, 2,359,360 KiB peak RSS). Its binary hash and build diagnostics are saved in [`build-evidence/`](build-evidence/).

The 162-row firmware array is job 1430, submitted with throttle 2 to keep A2 at six concurrent tests alongside the four fresh c339 reruns in array 1426. At the 21:16 MDT checkpoint, 54 rows were complete: 38 PASS, 12 model-startup FAIL, 3 FIRMWARE_BUILD_FAIL, and 1 HARNESS_ERROR. See [`early-findings.md`](early-findings.md) for triage and [`disagreements.md`](disagreements.md) for the terminal Icarus comparison. The parser fix for the commented-seed harness error is committed as `ccebefb`; single-row rerun job 1493 is pending on successful completion of array 1430. The four c339 reruns remain active with progressing heartbeats (see the latest snapshot in their run folder).

After copying and checking 14 more terminal results, their remote result trees and separate resource logs were removed, freeing 5.33 MiB. The pinned model build remains in place because active array 1430 and dependent retry 1493 still use it.

At 22:29 MDT, c339 rerun 1426_4 completed PASS at mcycle 62,472. With that slot free, array 1430's throttle increased to 3; it now has one additional task running while the other three c339 reruns continue. A2 remains capped at six active tests. The 1426_4 raw output tree was checksum-verified locally and removed from the remote run area. Parser retry 1493 now depends on 1426_1, so it starts after the first c339 slot frees instead of waiting for the full M9 array.
The later task-1426_4 output cleanup freed another 359.78 MiB. Across that cleanup and the 14 M9 result bundles above, the documented remote cleanup total for this turn is about 0.36 GiB.

At 22:35 MDT, array task 1430_56 (`smoke_test_hw_config`) completed as `FIRMWARE_BUILD_FAIL`: the shared ISR object has an unresolved `service_soc_ifc_notif_intr` reference despite the test header's inline handler. Its verified result and logs are in [`runs/4e6f763fa02018da/`](runs/4e6f763fa02018da/); the remote result tree, resource sample, and Slurm log were removed after checksum verification, freeing 4,785,748 bytes (4.56 MiB). The table now has 55 terminal firmware rows (38 PASS, 12 FAIL, 4 FIRMWARE_BUILD_FAIL, 1 HARNESS_ERROR); 107 firmware rows remain pending.

At 22:49 MDT, tasks 1430_57 through 1430_61 were copied, manifest-checked, and removed from the remote output area, freeing 307,137 bytes. They add two PASS, one DOE SVA FAIL, and two LMS image-load FAIL outcomes. [`early-findings.md`](early-findings.md) records the observed messages and the 60-row aggregate: 40 PASS, 15 FAIL, 4 FIRMWARE_BUILD_FAIL, and 1 HARNESS_ERROR, with 102 firmware rows still pending. All five prior Icarus results are `UNVERIFIED`.

At 23:03 MDT, task 1430_62 (`smoke_test_kv_uds_reset`) passed at mcycle 56,383. Its verified remote output cleanup freed 88,698 bytes. The table now has 61 terminal firmware rows (41 PASS, 15 FAIL, 4 FIRMWARE_BUILD_FAIL, 1 HARNESS_ERROR); 101 firmware rows remain pending.

At 23:15 MDT, no new rows had completed. M9 tasks 47, 55, and 63 remain active at the three-task throttle alongside the three c339 reruns; A2 remains at its six-task cap. Seed-fix retry 1493 is still pending on `afterok:1426_1`.

At 23:25 MDT, there were still no new terminal results. Tasks 47 (`infinite_loop`), 55 (`smoke_test_mldsa_sign_rnd`), and 63 (`smoke_test_mbox`) each had an active simulator process using 99.9% CPU. The logs were quiet, but the CPU check showed the runs were working; no jobs were interrupted. Details are in [`active-process-audit-20261015-2325.txt`](active-process-audit-20261015-2325.txt).

At 23:36 MDT, M9 still had no new terminal results. Tasks 47, 55, and 63 remained RUNNING; the c339 reruns also advanced. The table remains at 61 terminal rows with 101 firmware rows pending.

At 23:46 MDT, there were still no new M9 results. Tasks 47, 55, and 63 remain active with CPU activity, and the c339 rows continue to progress. The six A2 slots remain fully occupied.

At 23:57 MDT, the same six A2 simulations remain active. No new M9 result is ready; the ledger remains at 61 terminal rows and 101 pending firmware rows.

At 00:07 MDT on 2026-10-16, all six A2 slots were still occupied by active simulations. The three M9 processes remained CPU-active, there were no new terminal outcomes, and the seed-fix retry remained dependency-held.

At 00:17 MDT, all six A2 slots remained active and there were still no new M9 terminal results. The ledger remains at 61 terminal and 101 pending firmware rows.

At 00:28 MDT, tasks 1430_47, 1430_55, and 1430_64 through 1430_73 (excluding 1430_67) produced 11 terminal results: eight PASS and three FAIL. The ledger now has 72 terminal firmware rows (49 PASS, 18 FAIL, 4 FIRMWARE_BUILD_FAIL, 1 HARNESS_ERROR), with 90 pending; 109 non-firmware rows remain `NOT_RUN_NON_FIRMWARE`. The two long-run FAILs hit the testbench's 20M-cycle guard, and the new LMS FAIL is the existing DCCM `$readmem` bounds issue. `pv_hash_zeroize` adds an assertion-coverage disagreement; see [`early-findings.md`](early-findings.md) and [`disagreements.md`](disagreements.md). All 11 result bundles were retained locally after checksum verification; remote outputs were removed, freeing 871,850 bytes. Array 1430 still has three running tasks and array 1426 has three running c339 reruns, so all six A2 slots remain occupied; retry 1493 remains dependency-held on `1426_1`.

At 00:45 MDT, tasks 1430_67, 1430_74, and 1430_76–78 added four PASS and one LMS image-load FAIL. The ledger now has 77 terminal firmware rows (53 PASS, 19 FAIL, 4 FIRMWARE_BUILD_FAIL, 1 HARNESS_ERROR) and 85 pending; the 109 non-firmware rows remain `NOT_RUN_NON_FIRMWARE`. These five result bundles were checksum-verified and retained locally, then their remote output trees, separate resource records, and Slurm logs were removed, freeing 389,499 bytes. Tasks 1430_63, 1430_75, and 1430_79 are running alongside c339 tasks 1426_1–3; all six A2 slots are occupied. Retry 1493 remains dependency-held on `1426_1`.

At 01:08 MDT on 2026-10-16, retry job 1493 completed the seed-parser rerun for `smoke_test_mldsa_keygen_standalone_sign_vfy_rand`: PASS at mcycle 370,210 in 212.477 seconds, using the pinned model SHA and the parser fix from commit `ccebefb`. The original array-1430 HARNESS_ERROR is preserved in `runs/758d1f7d83680ac0/initial-array-1430/`; the refreshed ledger reports the retry PASS. Hash-verified retry evidence is in `runs/758d1f7d83680ac0/`, and the completed retry's remote staging tree was deleted.

Tasks 1430_79–92 then added nine PASS, three FAIL, and two firmware-build failures. The 14 result bundles passed their internal manifests and remote/local hashes for the completion marker, resource record, and Slurm log. The refreshed 271-row table now has 91 terminal supported-firmware rows: 63 PASS, 22 FAIL, and 6 FIRMWARE_BUILD_FAIL; 71 supported rows remain pending and 109 rows remain `NOT_RUN_NON_FIRMWARE`. The PASS rate is 69.2% of terminal supported rows (63/91), or 38.9% of all 162 supported rows so far. The two LMS failures repeat the DCCM `$readmem` image-boundary startup issue; `caliptra_demo` fails firmware compilation on missing KV/HMAC384 register symbols; `smoke_test_kv_lock_use_mid_read` reproduces the known #12 wrapper false positive. Task 1430_83's Icarus `FAIL` versus Verilator `FIRMWARE_BUILD_FAIL` is a label mismatch: both compiler logs contain the same missing ABR ISR hooks and neither run reaches simulation. See [`early-findings.md`](early-findings.md) and [`disagreements.md`](disagreements.md).

The 14 completed result trees, their resource records and Slurm logs, and the completed seed-fix retry staging tree were deleted after evidence verification, freeing 66,912,635 bytes (63.8 MiB). The shared pinned model remains because array 1430 is still running.

At 01:12 MDT, the supervisor authorized increasing array 1430 to throttle 6 after the c339 reruns finished. The direct array-wide `scontrol update` emitted a warning for already completed tasks 94–95 but applied the change; the array record confirms `%6`. Six M9 tasks are currently running (1430_63, _75, _96, _98, _100, and _104); the separate seed-fix job 1493 is no longer queued or running because it completed at 00:51 MDT, so total A2 concurrency remains six.

At 01:19 MDT, tasks 1430_93–106, _108–109, _111, and _113–116 added 11 PASS, eight LMS `$readmem` image-load FAILs, and two firmware-build failures. The QSPI source/header mismatch and ML-KEM helper-argument mismatch are recorded in [`early-findings.md`](early-findings.md); the Icarus-versus-Verilator QSPI label mismatch is rooted in [`disagreements.md`](disagreements.md). The 271-row table now has 112 terminal supported-firmware results (74 PASS, 30 FAIL, 8 `FIRMWARE_BUILD_FAIL`), 50 pending supported rows, and 109 `NOT_RUN_NON_FIRMWARE` rows. The terminal pass rate is 74/112 (66.1%); 74/162 supported rows (45.7%) have passed. Bundle hashes were verified before their remote outputs were deleted, freeing 5,253,409 bytes (5.01 MiB). See [`collection-20261016-0119.txt`](collection-20261016-0119.txt).

The array-wide throttle is confirmed at 6; the seed-fix retry is complete and no longer queued. At the 01:19 queue snapshot, tasks 1430_63, _75, _107, _110, _117, and _118 were running, with indices 119–161 pending. The shared model remains while the array uses it.

At 01:23 MDT, tasks 1430_118–120 and _122 added two PASS, one LMS image-load FAIL, and one firmware-build failure. The 271-row table now has 116 terminal supported-firmware results (76 PASS, 32 FAIL, 10 `FIRMWARE_BUILD_FAIL`), 46 pending supported rows, and 109 `NOT_RUN_NON_FIRMWARE` rows. The terminal pass rate is 76/116 (65.5%); 76/162 supported rows (46.9%) have passed. Evidence was checksum-verified before remote cleanup, which freed 2,252,715 bytes (2.15 MiB); see [`collection-20261016-0123.txt`](collection-20261016-0123.txt).

The array throttle remains 6. At the 01:23 queue snapshot, tasks 1430_63, _75, _117, _121, _123, and _124 were running, with indices 125–161 pending. The shared model remained in use.

At 01:36 MDT, tasks 1430_117, _123–127, and _129–138, _140–142 added 12 PASS, four LMS image-load FAILs, and three firmware-build failures. The 271-row table now has 135 terminal supported-firmware results (88 PASS, 35 FAIL, 12 `FIRMWARE_BUILD_FAIL`), 27 pending supported rows, and 109 `NOT_RUN_NON_FIRMWARE` rows. The terminal pass rate is 88/135 (65.2%); 88/162 supported rows (54.3%) have passed. The new build failures repeat the inline ISR linkage issue and undeclared `srand`; see [`early-findings.md`](early-findings.md). All 19 bundles were verified before cleanup, freeing 10,391,892 bytes (9.91 MiB); details are in [`collection-20261016-0136.txt`](collection-20261016-0136.txt).

Array 1430 remains at throttle 6. At the 01:36 queue snapshot, tasks 1430_63, _75, _128, _139, _143, and _145 are running, with indices 146–161 pending. The shared pinned model remains in use.

At 02:04 MDT, results for tasks 1430_63 and 1430_153–158 were copied and verified. The table now has 154 terminal supported-firmware rows (101 PASS, 38 FAIL, 14 `FIRMWARE_BUILD_FAIL`, and 1 TIMEOUT), with 8 supported rows pending and 109 non-firmware rows marked `NOT_RUN_NON_FIRMWARE`. The terminal pass rate is 101/154 (65.6%); 101/162 supported rows (62.3%) have passed. The new MBOX timeout versus Icarus PASS is documented in [`disagreements.md`](disagreements.md), with the cause still under investigation. Task 153's testbench failure and the new LMS image-load and MLDSA firmware-build failures are in [`early-findings.md`](early-findings.md). All seven completed remote output bundles were verified locally before cleanup, freeing 2,625,479 remote bytes; two unmanifested local staging trees freed another 4,087,354 bytes. See [`collection-20261016-0204.txt`](collection-20261016-0204.txt).

The array throttle remains 6. At the latest queue check, tasks 1430_75, _128, _139, _149, _152, and _159 were running, with 160–161 pending. The model remains in use.

At 02:07 MDT, tasks 1430_159–160 were copied and verified. The ledger now has 156 terminal supported-firmware rows (102 PASS, 39 FAIL, 14 `FIRMWARE_BUILD_FAIL`, and 1 TIMEOUT), with 6 supported rows pending and 109 non-firmware rows marked `NOT_RUN_NON_FIRMWARE`. The terminal pass rate is 102/156 (65.4%); 102/162 supported rows (63.0%) have passed. Task 159 passed; task 160 repeats the LMS DCCM image-load failure. The remote outputs were removed after verification, freeing 117,214 bytes. See [`collection-20261016-0207.txt`](collection-20261016-0207.txt).

At 02:10 MDT, task 1430_161 (`smoke_test_mldsa_edge`) passed at final mcycle 388,027 in 222.017 seconds. The refreshed ledger has 157 terminal supported-firmware rows (103 PASS, 39 FAIL, 14 `FIRMWARE_BUILD_FAIL`, and 1 TIMEOUT), with 5 supported rows still running and 109 non-firmware rows marked `NOT_RUN_NON_FIRMWARE`. The terminal pass rate is 103/157 (65.6%); 103/162 supported rows (63.6%) have passed. Bundle manifests and remote/local hashes matched before cleanup, which freed 86,465 bytes. The live array throttle is 6; five tasks remained running and no pending task, including a seed-fix retry, appeared in `squeue`. See [`collection-20261016-0210.txt`](collection-20261016-0210.txt).

At 02:25 MDT, task 1430_75 (`cptra_ss_test_rom`) timed out after 6,873.008 simulation seconds. It produced no pass/fail marker; its last visible line is `Sending payload via AHB i/f` at simulation time 5,856,000. This repeats the M8 timeout point but does not identify its cause. The refreshed ledger has 158 terminal supported-firmware rows (103 PASS, 39 FAIL, 14 `FIRMWARE_BUILD_FAIL`, and 2 TIMEOUT), with 4 supported rows still running and 109 non-firmware rows marked `NOT_RUN_NON_FIRMWARE`. The terminal pass rate is 103/158 (65.2%); 103/162 supported rows (63.6%) have passed. Evidence hashes matched before cleanup, freeing 85,130 bytes. Array 1430 remains at throttle 6. See [`collection-20261016-0225.txt`](collection-20261016-0225.txt).

At 02:42 MDT, diagnostic job 1606 completed its firmware build and ran `cptra_ss_test_rom` against the pinned Verilator 5.052 model. A logging-only copy of `soc_ifc.c` reached DMA FIFO words 0–14, then stopped after reporting space for word 15; the following `WRITE_DATA` store produced no return marker before the diagnostic's external 600-second cap. The job is not a replacement M9 test result. This narrows the timeout to the 16th DMA FIFO MMIO write, but no bus handshake trace yet establishes why it stalls. The hash-verified evidence is in [`diagnostics/cptra-ss-dma-20261016-01/`](diagnostics/cptra-ss-dma-20261016-01/README.md). The completed diagnostic run tree was removed after recording its evidence, freeing 28,997,682 bytes.

At the 03:12 MDT checkpoint, Slurm confirmed array 1430 at throttle 6. Four firmware rows were running; no separate seed-fix retry appeared in `squeue`. The ledger has 158 terminal firmware rows (103 PASS, 39 FAIL, 14 `FIRMWARE_BUILD_FAIL`, 2 TIMEOUT), four firmware rows still running, and 109 non-firmware rows marked `NOT_RUN_NON_FIRMWARE`. HMAC UVM pilot jobs 1609–1612 were exploratory attempts before the scope correction and are stopped; their diagnostics do not count as M9 coverage. Do not port UVM benches to Verilator; block-level UVM stays on Icarus per M8.

Array 1430 has now finished all 162 firmware rows. Its final four tasks—`randomized_pcr_ecc_signing`, `smoke_test_kv_parallel_access`, `jtag_tap_mbox`, and `smoke_test_mbox_cg`—all hit the existing 20,000,000-cycle testbench guard and are recorded as `FAIL`, with no final mcycle. Their copied result bundles passed the row manifests and remote checksums. The complete firmware totals are 103 PASS, 43 FAIL, 14 `FIRMWARE_BUILD_FAIL`, and 2 TIMEOUT; the pass rate is 103/162 (63.6%). All 109 non-firmware rows remain `NOT_RUN_NON_FIRMWARE` per the M9 scope line above. See the [final-four collection record](collection-20261016-final4.txt) and [remote transfer checksums](collection-20261016-final4-remote-sha256.txt).

After evidence verification, the M9 run's model build and the four completed result trees, separate resource records, and Slurm logs were removed from DAN-DESKTOP, freeing 707,886,227 bytes (0.66 GiB). Its staged source and overlay remain temporarily because the focused mailbox diagnostic uses them. The pinned shared toolchains were not changed.

At 07:20 MDT, diagnostic job 1614 captured the `smoke_test_mbox` lock-register trace. All 12 observed AR/R transactions completed successfully but returned the locked value (`RDATA=1`); the SoC BFM kept polling and never wrote `MBOX_CMD`. This roots the Icarus-PASS versus Verilator-TIMEOUT disagreement in the mailbox lock's set-on-read handoff; the exact simulator scheduling versus upstream RTL-race cause of the different first-read value remains open. The diagnostic hit its separate 600-second cap and is not a replacement M9 result. See [`disagreements.md`](disagreements.md), [`root-causes.md`](root-causes.md), and the [focused trace report](diagnostics/mbox-axi-trace-20261016-01/README.md).

The final table has all 162 firmware rows terminal: 103 PASS, 43 FAIL, 14 `FIRMWARE_BUILD_FAIL`, and 2 TIMEOUT (103/162 PASS, 63.6%). The six Icarus-finished disagreements are listed in [`disagreements.md`](disagreements.md), with a cause recorded for each. The 109 authored-stimulus/generated-UVMF rows remain `NOT_RUN_NON_FIRMWARE` under the scope note at the top of this README.

After copying the diagnostic and verifying its remote SHA-256 manifest, I removed the finished M9 diagnostic and staging run directories from DAN-DESKTOP. This freed 719,424,165 bytes (0.67 GiB); together with the earlier final-four cleanup, those two cleanups freed 1,427,310,392 bytes (1.33 GiB). Shared toolchains were untouched. See [`cleanup-20261016-mbox.txt`](cleanup-20261016-mbox.txt).

At 07:33 MDT, diagnostic job 1617 confirmed the mailbox polling behavior at the task boundary: 20 `axi_read_single` calls returned `data=1`, `resp=0`, and each was followed by the next poll. No lock grant or command write appeared before the separate 90-second diagnostic cap. This establishes the test-level root cause as the Verilator read-to-set lock response trapping the BFM in its busy loop; the exact simulator-scheduling versus upstream RTL-race source of the differing first value remains unresolved. The original M9 row remains `TIMEOUT`; both diagnostics are separate from the result table. See the [call-boundary trace report](diagnostics/mbox-axi-calltrace-20261016-01/README.md).

After checksum verification, I removed job 1617's finished build and staging directory, freeing 719,361,899 bytes (0.67 GiB). Across the final-four, AXI-trace, and call-trace cleanups, DAN-DESKTOP freed 2,146,672,291 bytes (2.00 GiB). Shared toolchains were untouched. See [`cleanup-20261016-calltrace.txt`](cleanup-20261016-calltrace.txt).


At 11:10 MDT, diagnostic job 1769 completed the DMA status and interrupt probe. It confirms the word-15 FIFO write is accepted, then the DMA receives AXI DECERR at unmapped destination `0x21200000`; repeated `NOTIF_TXN_DONE` clear/re-entry traffic follows, with no later `STATUS0` poll. This closes the DMA root-cause chain as a testbench AXI-map mismatch followed by a persistent notification interrupt; see [diagnostic 04](diagnostics/cptra-ss-dma-axi-20261016-04/README.md). The official 162-row table remains unchanged: 103 PASS, 43 FAIL, 14 `FIRMWARE_BUILD_FAIL`, and 2 TIMEOUT. The six Icarus-finished disagreements are documented individually; all 109 non-firmware rows remain `NOT_RUN_NON_FIRMWARE` under the scope note above. After verifying and copying the evidence archive, the completed remote diagnostic tree was removed, freeing 714,153,984 bytes (0.665 GiB).
