# NTT masking row 73 gate

- Job: 2908 on DAN-DESKTOP; 600 s per-row cap; 1 CPU, 4 GiB.
- Source: Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; snapshot SHA-256 `59b9402650f64fd98b85c3c6c8f9e79f166273ba3e96bfa7009a52f3e5d0f053`.
- Toolchain: Icarus `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Overlay: context-sized zero literals, removal of the stale `.hybrid_pw_uvw_i()` connection, and invocation of the active `masked_hybrid_bf_2x2_test` task. The source has no active result checker.
- Result: compile exit 0, simulation exit 0, elapsed 75.081 s. The log ends at `$finish` at time 10685 and contains no test pass/fail marker; therefore row 73 remains `BLOCKED` for functional qualification.
- Raw archive: `raw/job-2908.tar.gz`; SHA-256 `46acc8352d90ad3f3f1c5b8964bf7185144ad2c6ed175867243ca3e78cb08a`.

The intern summary (“no functional pass/fail marker; simulation terminated via `$finish`”) was checked against the archived `sim.log` and `result.json`.
