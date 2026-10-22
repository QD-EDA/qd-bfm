# M17 authored row 73 and 90 gates

Array job 2900 ran rows 73 and 90 on DAN-DESKTOP with pinned Icarus 13.0 development build (source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) and Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The array used 1 CPU, 4 GiB and a 600-second timeout per row. Source snapshot SHA-256: `e0cdab0d0ff43848572afa10bfaa11e62e1a808b589b39663671f7f0976c8cab`.

- Row 73 compiled the context-sized zero assignment overlay, then stopped at the stale unconnected `.hybrid_pw_uvw_i()` port and a call to `masked_bfu_1x2_test`, whose only task definition is commented out. The remaining active task has no live output checker, so no pass result can be established without changing criteria. No simulation started.
- Row 90 compiled with the testbench-only alias from `MLDSA_MEM_ADDR_WIDTH` to `ABR_MEM_ADDR_WIDTH` and ran to `$finish`. The output was `Hint sum = x, invalid_h = x`; the bench prints `Test done` but contains no expected-result check. This does not establish a functional pass.

Both rows remain BLOCKED. Raw archive: `raw/job-2900.tar.gz`; SHA-256: `f58b74a7669fa5dc26635a008517c3ae8f793e6fe9e551698d902d92e2e7b5e4`; sidecar checksum: `raw/job-2900.tar.gz.sha256`.
