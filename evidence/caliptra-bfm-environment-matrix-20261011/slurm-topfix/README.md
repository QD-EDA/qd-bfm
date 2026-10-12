# Corrected Adams Bridge tops on c339

Array 460 runs only the two rows whose top names were corrected from the pinned Adams Bridge `compile.yml`. Host: `DAN-DESKTOP`; c339 SHA: `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; Caliptra SHA: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge SHA: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.

Job 460 used one CPU and 3 GiB per task, two concurrent tasks, and a two-hour job limit. The task wrapper applies a 6,900-second timeout. Its staged source snapshot is at `/home/dsell/slurm-runs/caliptra-bfm/a2/env-topfix-c339-20261011-01` on DAN-DESKTOP.

`abr_masked_OR_tb` compiled and simulated with exit 0. Its raw `sim.log` reports five tests, zero errors, `PASS`, and `All tests completed.` The wrapper's pass-marker counter remained zero because it does not recognize this testbench's wording; classification uses the raw terminal result. `ntt_masked_mult_redux46_auto_tb` is still running; do not classify it until it has a terminal result.

The directory contains the exact two-row manifest and batch script, host/queue snapshot, per-row logs and resource records, tool versions and hashes, filelist hash, and pinned source revisions. No local duplicate of either row was run.
