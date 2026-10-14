# CSRNG filelist repair on c339

The original `csrng_tb` row failed before simulation because `caliptra_prim_ram_1p_pkg.sv` appeared after `caliptra_prim_generic_ram_1p.sv`, which imports it. Two fresh isolated runs tested a copied filelist; the pinned RTL and upstream filelist were left untouched.

Job 469 moved the existing package entry earlier. That cleared the package error and revealed a missing include directory for `caliptra_reg_field_defines.svh` used by `aes_clp_wrapper.sv`. Job 470 retained the ordering fix and added `src/integration/rtl/caliptra_reg` to the include path. On DAN-DESKTOP with Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`), compile and simulation both exited 0 in 5 seconds. The raw simulation log contains `* TESTCASE PASSED`, with zero failure markers. It also contains nonfatal `unique case` warnings; they are not followed by a failure marker.

Each task requested 1 CPU and 3 GiB, with a 2-hour allocation and 6,900-second process timeout. Per-task resource logs, exact overlays, source and binary hashes, versions, host snapshots, and the intermediate job 469 failure are retained here. Job 470's runtime source copy was `/home/dsell/slurm-runs/caliptra-bfm/a2/csrng-filelist-c339-20261011-02`.
