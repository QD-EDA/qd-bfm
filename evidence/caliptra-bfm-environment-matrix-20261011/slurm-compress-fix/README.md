# Compress filelist package-order repair

The pinned `compress_tb.vf` omits `ntt_defines_pkg.sv`, which is imported by `masked_barrett_if_cond.sv`; `ntt_defines_pkg` imports `abr_params_pkg`, already listed immediately before it. Array 468 tests that single missing-package repair using a copied filelist with the package inserted at that dependency point.

The run used pinned Icarus c339 (`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`) and the existing Caliptra/Adams revisions. It requested one CPU, 3 GiB, two hours, and applied a 6,900-second test timeout. Remote run directory: `/home/dsell/slurm-runs/caliptra-bfm/a2/compress-filelist-c339-20261011-01`.

The package omission was repaired, then compilation exited 2 because `compress_tb.sv` connects obsolete `mem_wr_req` and `mem_wr_data` ports that are absent from the current `compress_top`. Simulation did not run. The matrix row remains BLOCKED on the testbench/RTL interface mismatch.
