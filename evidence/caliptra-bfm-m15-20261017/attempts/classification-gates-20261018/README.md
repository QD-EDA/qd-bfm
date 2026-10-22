# M15 classifier gates

Both gates used current-main Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`, runner SHA256 `2d1d6d9016921b510b59983cc7036b29d065b2d9d71dd5fb7639f7ce9e715136`, and the pinned 108-row manifest SHA256 `049ea8f7a78a72b32bdded08b8116f8691ac8ad43a13a7624529ec0398ae61ea`. Each used one CPU, 3 GiB, and a 600-second row timeout on DAN-DESKTOP.

- Job 2547, row 68 (`masking_test`): PASS. Compile and simulation exited 0; output reported `Total tests: 5, Errors: 0`, `PASS`, and `All tests completed.` in 0.031 seconds.
- Job 2548, row 57 (`sigencode_normal_test`): BLOCKED. Compile and simulation exited 0, but the testbench's vector generator failed with `ModuleNotFoundError: No module named 'numpy'`; the runner now preserves that first diagnostic. No valid test result was produced (0.119 seconds).

Commands, runner and test snapshots, results, logs, copied runtime inputs, resources, and Slurm job records are preserved here.
