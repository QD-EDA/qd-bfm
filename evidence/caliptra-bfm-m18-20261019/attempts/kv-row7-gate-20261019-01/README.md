# M18 KeyVault row 7 one-row gate

This gate runs `example_derived_test` with the rebuilt Icarus `82023726be90ab269d6e0ef5e755ebb69e6f648c` and the existing open AHB overlay. The additional testbench overlay changes the generated example sequence base from `kv_rst_sequence_base` to `kv_bench_sequence_base`, matching the type required by generated `test_top`; a hash guard pins the source declaration. The original test, stimulus, checks, RTL, and firmware are unchanged.

The job requests 1 CPU and 4 GiB for 15 minutes; the runner timeout is 600 seconds. This is the one-row gate for the KeyVault overlay before rerunning rows 9 and 10. Source snapshot and hashes are recorded alongside this README; raw Slurm logs will be added after completion.

Job 2999 completed, but its raw archive was not copied into this evidence directory before its remote run tree was removed. This attempt is retained as an execution record only and is excluded from `m18-results.tsv`; rerun the gate with the refreshed compiler and preserve its archive before cleanup.
