# Adams Bridge address-parameter alias runs

All runs used DAN-DESKTOP and the pinned Icarus c339 SHA `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`. Slurm had 17 idle CPUs before the 8-row array. Array 494 used one CPU and 3 GiB per task, concurrency 4, and a 6,900-second per-test timeout. Its staged source was copied from the frozen run snapshot and changed only by `abr-params-alias.patch`; pinned source trees and Icarus were untouched.

## Shared cause

Eight Adams testbenches import `abr_params_pkg` and refer to `MLDSA_MEM_ADDR_WIDTH`, but the pinned package only defines `ABR_MEM_ADDR_WIDTH`. The package derives that width as `$clog2(1472)+3 = 14`. A compiler `-DMLDSA_MEM_ADDR_WIDTH=14` did not resolve the bare SystemVerilog identifier (job 475). Adding the one run-local package alias `MLDSA_MEM_ADDR_WIDTH = ABR_MEM_ADDR_WIDTH` resolved that error in all eight rows. The alias patch and complete array manifest/script are preserved here.

## Arrays 494, 502, and 506 outcomes

- `sigdecode_h_tb` and `skdecode_tb` passed. Their logs contain explicit `Test passed` and `* TESTCASE PASSED` messages respectively, with zero simulator exit and no failure markers.
- `norm_check_tb` exited zero and printed successful checks and `Ctrl test done`; it is PASS in the matrix.
- `makehint_tb` exited zero but printed `Hint sum = x, invalid_h = x` and only `Test done`; it remains BLOCKED.
- `decompose_tb` passed both its normal and usehint checks in array 502 after a run-local stale-port compatibility patch. The raw log prints `Decompose success` and `Decompose + usehint success`; compile and simulation exited zero.
- `pkdecode_tb` compiled and ran in array 502 after removing the obsolete `MEM_ADDR_WIDTH` override, but all 2,048 outputs were X. It remains blocked on invalid all-X results.
- `skencode_tb` compiled and ran in array 502 after adapting the stale error signal, but all outputs were X. It remains blocked on invalid all-X results.
- `sigdecode_z_tb` first had a task-argument mismatch in 494 and lacked NumPy/vectors in 502. Array 506 supplied Python 3.14.4, NumPy 2.5.4, vectors, the address alias, and a one-argument task call; compile and simulation both exited zero, but all 3,584 outputs were X and no testcase pass marker appeared. It remains blocked on invalid all-X results, not Python or vector setup.

The array 502 compatibility overlay is preserved in `runs/502/testbench-compat.patch`. Array 506 raw logs, runtime vectors, hashes, tool versions, and result are under `runs/506/`.

The `mldsa_config_defines.svh` omission is a separate source defect: that file is absent from the pinned source tree, while six other filelists/testbenches reference it. The width alias does not fabricate or replace that absent header.

## Runner errors kept out of matrix results

Job 478 stopped before compilation because the batch script expected `tasks.tsv` while the staged manifest was `alias-tasks.tsv`. Job 486 stopped before compilation because task variables were not exported into the inner shell. Neither is a test result; both raw scheduler logs are retained under `runs/478/` and `runs/486/`. The corrected array 494 used the expected manifest name and exported task variables. Compile-only probes 475 and 477 are preserved under their run directories.
