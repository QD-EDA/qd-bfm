# Row 59 include-path gate (job 2683)

The `norm_check_normal_test` compile passed the missing `abr_sva.svh` include after adding the pinned `src/abr_libs/rtl` include directory, then stopped at an undefined `MLDSA_MEM_ADDR_WIDTH` testbench reference. Result: **BLOCKED**, compile exit 4; simulation did not run. This is a pinned testbench parameter typo, not an Icarus result.

Inputs were Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` and Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`). Remote hashes for every captured file are in `raw/SHA256SUMS.remote.txt`; all verified before cleanup.

