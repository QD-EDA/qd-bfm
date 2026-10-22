# KeyVault M17 run 07

Fresh retry of rows 7, 9, and 10. Run 06 failed before compilation because its source snapshot omitted `scripts/run_with_memory_pressure_guard.py`; this snapshot includes that exact tracked helper. The KeyVault overlay is unchanged from M16 rows 6 and 8.

Slurm job 2878 used pinned Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) and firmware pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. It ran one CPU per row with a 4 GiB task limit, 30-minute Slurm cap, and 600-second runtime timeout.

- Row 7 `example_derived_test`: **FAIL** at 0 ns with UVM_FATAL `[FCTTYP]`. The override returns `example_derived_test_sequence`, which extends `kv_rst_sequence_base`, while `test_top` requires `kv_bench_sequence_base`. The tech lead confirmed this is a genuine testbench contract defect, not an Icarus issue; it was not patched.
- Row 9 `kv_rand_test`: **PASS**; testcase marker present, UVM_ERROR/FATAL 0, `$finish` at 107360000 ps.
- Row 10 `kv_rand_debug_test`: **PASS**; testcase marker present, UVM_ERROR/FATAL 0, `$finish` at 465860000 ps.

The raw archive is `raw/job-2878.tar.gz`, SHA-256 `df0d622cf2fae9a27d4afe79fd6d033fb618258f8d58d00f129be7df5869eeb1`.
