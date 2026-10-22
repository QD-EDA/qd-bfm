# PCR Vault AHB MVC one-row gate: row 46

Job 2670 ran pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, row 46 (`pv_rand_wr_rd_test`), on DAN-DESKTOP with Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` and binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. The open AHB/MVC filelist overlay was generated and compilation reached the generated PV environment, but stopped with 80 errors; no simulation started. Row status is **BLOCKED**.

The first error is Icarus rejecting a generated `$psprintf` call. The log also reports nested class-property and dynamic-array-slice constructs and generated interface modport direction conflicts. The AHB predictor's missing transfer-member errors were isolated in [`diagnostics/ahb-pv-generic-transfer/`](../../diagnostics/ahb-pv-generic-transfer/): the minimized type-parameter reproducer fails on pinned Icarus and passes on Verilator. That likely indicates a simulator issue, now filed for A3 in [issue #663](https://github.com/dsellerbrock/iverilog-uvm/issues/663). Row 46 remains blocked by its other generated UVMF/Icarus errors. The intern triage is preserved in `intern-triage.md`; its initial structural-error classification was corrected after the minimal reproduction.

The result, compile command/log/resource record, overlay list/manifest, Slurm log, job metadata, batch script, and staged source archive are preserved here. Archive SHA256: `137891799072c9eb02e208d0ebe01079ac5d6e5cfc757b22113f1bb8d2a9d6e5`.

Resources were 1 CPU, 3 GiB, 20-minute Slurm cap, and 600-second per-row timeout. The completed 2.4 MiB remote run directory was removed after capture.
