# M16 MLDSA AHB one-row gate: row 96

Job 2715 ran `ML_DSA_randomized_early_run_test` from row 96 using the pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` sources. The QD-BFM AHB filelist supplied the previously missing, unused `qvip_memory_message_handler` declaration, so compilation advanced beyond that error.

The row is **BLOCKED** before simulation. Pinned Icarus 13.0 (`9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) reported 12 elaboration errors. The first error is in generated `mldsa_env_configuration.svh:92`: it rejects the no-argument `qvip_ahb_lite_slave_subenv_config.convert2string` expression in a string concatenation. Other errors include one-argument `string.substr` calls, nested class-property paths, and dynamic-array slice assignments. No VVP simulation ran.

The test used one CPU, 3 GiB, a 20-minute Slurm cap, and the runner's 600-second per-row timeout. Compilation exited 12 in 4.01 seconds at 709,580 KiB peak RSS. The first warning is an ignored `set_inst_name` call on an Icarus covergroup stub; it is not the blocking error. An intern summary missed the first compile error and called the warning the first diagnostic; the full captured log was checked directly.

The first call was minimized and filed internally as [issue #664](https://github.com/dsellerbrock/iverilog-uvm/issues/664), labeled `from-caliptra-dv`; see [`diagnostics/icarus-noarg-method-string-concat/`](../../diagnostics/icarus-noarg-method-string-concat/). The one-argument `substr` calls, nested-property reports, and dynamic-slice diagnostics have not yet been minimized or classified. The AHB environment is not yet qualified by a PASS.

The staged input archive SHA256 is `1936101326db27ca10f306f4d15f56bf61c3a4b087781812902c00cb97c30bf5`; the batch script SHA256 is `1a6ac8e34504588390114e13b18e3be898088fa4d62d8cd8d0083cafe8eaf4a0`. Job metadata, runner resource data, compile command/log, generated AHB overlay filelist and manifest, result JSON, and Slurm output are under `raw/`.
