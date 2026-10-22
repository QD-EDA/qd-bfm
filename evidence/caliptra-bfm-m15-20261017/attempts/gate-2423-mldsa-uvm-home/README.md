# M15 row 96 UVM_HOME gate

Row 96 (`ML_DSA_randomized_early_run_test`) was run on DAN-DESKTOP with pinned Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` and binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. The runner change sets `UVM_HOME` to the pinned install's `lib/ivl/uvm`; the log no longer reports a missing UVM package and advances to the next dependency.

Result: BLOCKED at `/include/questa_mvc_svapi.svh: No such file or directory` (compile exit 1, 0.28 seconds). The generated Adams Bridge filelist references `QUESTA_MVC_HOME` and `UVMF_HOME`. Neither root is installed in the protected toolchain area; a search there found only QD-BFM's `uvmf_lite/uvmf_base_pkg.sv`, and no Questa MVC headers or full UVMF package files. The exact result, command, resource record, compile log, generated tops, runner snapshot, and Slurm log are preserved here. Job 2423 requested 1 CPU, 3 GiB, with a 20-minute cap; the row timeout was 600 seconds.

This gate validates the Icarus UVM package setup and documents the remaining external dependency blocker. It does not claim simulation coverage for row 96.
