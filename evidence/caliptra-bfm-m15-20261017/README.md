# M15: Icarus runner for the 108 runner-less rows

Status: complete (2026-10-18).

This milestone builds one runner for the 51 generated-UVMF and 57 authored-stimulus rows that had no exact selector in the M13 inventory. The source YAMLs were read from the protected Slurm checkouts and are pinned by per-file SHA256 in `source-metadata.json` and by repository revision in `m15-test-to-environment.tsv`.

Pinned sources:

- Caliptra RTL: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`
- Adams Bridge: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`
- Current-main Icarus used for M15 runs: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`

`m15-test-to-environment.tsv` is the canonical input to the shared runner. It preserves all YAML plusargs, adds `+UVM_TESTNAME=<testname>` when the YAML does not provide one, records a deterministic seed, and maps authored rows to the existing M7 component filelist. Generated rows point to their UVMF environment `.vf` and separate HDL/HVL top filelists. The UART row is mapped to its `compile.yml`; this is not an Icarus filelist and needs a local runner setup before it can execute.

Mapping validation: 108 unique rows, 51 generated-UVMF and 57 authored-stimulus; every row has a source pin, YAML hash, environment, filelist and exact selector. See `m15-map-validation.txt`.

No RTL, firmware, or pass criteria are changed by this milestone. The complete row-by-row result table and final requirements are below.

## Shared runner

`dv/caliptra_bfm/uvmf_lite/tests/run_m15_test.py` accepts one manifest row and writes `result.json`, stage logs, exact command records, and `/usr/bin/time -v` resource records. It verifies the pinned repository, YAML, and filelist hashes before compiling. Each row has a 3600-second overall timeout. PASS requires an explicit testbench pass marker or the standalone suite's exact zero-error completion summary, with no failure marker or UVM error/fatal. Compile/setup failures are BLOCKED with the first diagnostic; zero-exit simulations without a pass marker preserve the first runtime diagnostic when available.

The final classifier update is commit `82a36ac0`.

The runner uses the existing M7 `.vf` and runtime setup for authored tests, and generated UVMF `.vf` plus the separate HDL/HVL lists for generated tests. The HMAC path reuses `run_generated_hmac_runtime.sh` and adds three hash-guarded testbench compatibility overlays for the current-main compile blockers. The HMAC overlays do not change RTL, firmware, or pass criteria.

The Slurm array template `run_m15_array.sbatch` requests one CPU and 3 GiB per task, with a six-task throttle and two-hour job cap. The runner's per-test timeout is one hour. Run artifacts are copied into this evidence directory before the disposable Slurm run directory is removed.

The one-row HMAC gate is row 5 (`HMAC_otf_reset_test`). The first pilot batch covers the full HMAC, SoC-IFC, and Adams Bridge ML-DSA environments; the remaining-row list excludes all gate/pilot rows so evidence is not duplicated. See `pilot-row-ids.txt` and `remaining-row-ids.txt`.

## Gates and simulator issue

Row 5 passed on current-main Icarus in Slurm job 2365 after the testbench-only compatibility overlay split the nested configuration access into two assignments. Compile and simulation both exited 0; the run log contains the explicit testcase pass marker and reports zero UVM errors/fatals. Reproducibility details and logs are in `attempts/gate-2365-hmac-pass/`. The earlier gate attempts are preserved separately and are not counted as test results.

The classifier gates caught two result-format cases: row 68 (`masking_test`, job 2547) passes from `Total tests: 5, Errors: 0` followed by `PASS` and `All tests completed.`; row 57 (`sigencode_normal_test`, job 2548) is BLOCKED with the precise `ModuleNotFoundError: No module named 'numpy'`. Both use the same pinned Icarus binary and the final runner snapshot; evidence is in `attempts/classification-gates-20261018/`.

## Additional blockers and rerun

The one-row SoC-IFC gate for row 21 advanced past the testbench assignment-pattern overlay and exposed an Icarus issue: an out-of-class extern function with implicit return type is rejected. The minimized source and explicit-`void` control are in `attempts/gate-2422-socifc-row21/diagnostics/`; filed in `dsellerbrock/iverilog-uvm` as [issue #641](https://github.com/dsellerbrock/iverilog-uvm/issues/641), label `from-caliptra-dv`.

The generated MLDsa row 96 gate (job 2423) verified the runner's `UVM_HOME` points at the pinned Icarus UVM package. Compilation then stopped because the protected toolchain area does not contain the required Questa MVC header or full UVMF package tree. Details and preserved logs are in `attempts/gate-2423-mldsa-uvm-home/`. This is a dependency blocker, not a simulation result.

The updated diagnostic matcher was gated on row 59 (job 2541) and row 63 (job 2546). Their compile blockers are now recorded exactly: missing `abr_sva.svh` and missing `abr_prim_assert.sv`. See `attempts/gate-2541-row59-diagnostic/`.

Array 2424 rechecked pilot rows affected by the UVM package setup or SoC-IFC overlay and ran the 51 rows not previously covered. It used six concurrent single-CPU tasks at 3 GiB each. The result table combines those results with the prior HMAC gate, two pilot passes, the row-96 dependency gate, and refreshed gates for rows 57, 59, 63, and 68.

## 108-row result

The full table is [`m15-results.tsv`](m15-results.tsv). Each row includes its exact selector, source pin and YAML hash, result and cause, compiler/simulator exit status, job ID, runtime, overlay scope, and evidence path. Final counts on pinned current-main Icarus are **13 PASS, 1 FAIL, 92 BLOCKED, and 2 TIMEOUT**. The overlay column identifies the hash-guarded HMAC and SoC-IFC testbench/setup overlays.

| Test group | PASS | FAIL | BLOCKED | TIMEOUT |
|---|---:|---:|---:|---:|
| Generated UVMF (51) | 1 | 0 | 50 | 0 |
| Authored stimulus (57) | 12 | 1 | 42 | 2 |

The one failure is row 62 (`cbd_rand_test`), which prints `* TESTCASE FAILED`. The two one-hour timeouts are row 13 (`doe_cbc_nist_test`) and row 51 (`ecc_normal_test`). The 92 blocked rows are fully attributed in the table: 50 generated-UVMF rows stop at the absent Questa MVC header; 21 SoC-IFC rows hit the out-of-class `lock_fuses` Icarus issue; 5 lack `mldsa_config_defines.svh`; 5 cannot bind `MLDSA_MEM_ADDR_WIDTH`; 4 lack Python/vector-generation inputs; and 7 have individual filelist, package, include, or width blockers.

## What it takes to run the remaining rows

The authored rows already use the shared M7 component runner. To make all 57 produce results, supply their missing source packages and vector files, provide Python 3 plus NumPy for the vector generators, and resolve the specific compile/setup blockers in the table. The 21-row `lock_fuses` failure is filed in [dsellerbrock/iverilog-uvm issue #641](https://github.com/dsellerbrock/iverilog-uvm/issues/641) with label `from-caliptra-dv` for A3 to fix.

The 50 other generated-UVMF rows need the missing `QUESTA_MVC_HOME` header/packages and complete `UVMF_HOME` tree; some filelists also name `AVERY_AXI` and `AVERY_SIM`. The pinned Icarus UVM package is now found through `UVM_HOME`, but those external trees are absent from the protected toolchain area. Running them requires installing those dependencies or replacing the used Questa/Avery APIs with compatible open implementations. No upstream issue was posted.

All compatibility overlays in this milestone are hash-guarded testbench or setup changes. They do not touch RTL, firmware, or pass criteria. The gate and per-row evidence directories preserve the exact inputs and commands; disposable Slurm run trees were removed after capture.
