# KeyVault AHB MVC one-row gate: row 6

Job 2667 ran pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, row 6 (`kv_rand_lock_test`), on DAN-DESKTOP with Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` and binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. The open AHB/MVC overlay was generated and accepted; compile then stopped in generated KeyVault/UVMF code with 224 hard errors and 574 `sorry` diagnostics. No simulation started; row status is **BLOCKED**.

One diagnostic was subsequently minimized: the generated `kv_rst_configuration.svh` `$psprintf` call has a trailing empty argument. Pinned Icarus rejects the form while Verilator 5.032 compiles and runs it; internal issue [#670](https://github.com/dsellerbrock/iverilog-uvm/issues/670) is labeled `from-caliptra-dv`. This does not resolve the row's other compile blockers.

The full `compile.log`, result JSON, overlay filelist and manifest, command, compile resource record, Slurm log, run script, job metadata, and staged source archive are preserved here. The staged archive SHA256 is `b187bf109effb0fa9b4570bf3096bed8ccfc878ef5d47903505a35b867de8837`.

The intern saw a truncated log and misidentified the first error. The full log starts with Icarus rejecting a `$psprintf` call; source review also confirms the generated reset configuration declares `wait_for_num_clocks`, so the repeated unknown-task errors are not missing QD-BFM API. Icarus separately reports unsupported nested class-property paths. Generated read/write driver BFMs also assign signals declared input in their initiator modports. These broader generated-environment issues make KV a poor first proof environment; no broad stubbing or RTL/firmware changes were made.

Resources were 1 CPU, 3 GiB, 20-minute Slurm cap, and 600-second per-row timeout. The completed 2.7 MiB remote run directory was removed after evidence capture.
