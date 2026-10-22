# Row 63 include-path gate (job 2688)

Adding both `src/abr_prim/rtl` and `src/abr_libs/rtl` resolved the nested `abr_prim_assert.sv` / `abr_sva.svh` includes. Compilation then exposed two pinned testbench defects: its `MLDSA_MEM_ADDR_WIDTH` identifier is undefined, and it connects `.w1_encode_done()` to `decompose`, which has no such port. Result: **BLOCKED**, compile exit 3; no simulation ran.

Inputs were Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` and Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`). `raw/SHA256SUMS.remote.txt` verifies every captured remote file. The source and build tree was removed after capture (200,859 bytes reported by `du -sb`).
