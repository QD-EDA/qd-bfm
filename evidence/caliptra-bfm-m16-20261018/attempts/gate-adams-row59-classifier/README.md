# Row 59 classifier gate (job 2686)

**PASS** for `norm_check_normal_test` on DAN-DESKTOP, using Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0` and pinned Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`). Python was 3.14.4. The row completed in 10.855 s; compile and simulation both exited 0 without timeout. Runner peak RSS was 23,840 KiB; simulation peak RSS was 11,880 KiB. The per-test cap was 600 s; Slurm requested one CPU and 3 GiB.

The log includes `Ctrl test done`, successful norm checks, expected rejection checks, and no `ERROR:` line. The runner now treats this exact completion marker as PASS only when the return code is zero and the log has no `ERROR:` line; a unit test covers both acceptance and error override. The full runner unit suite passed (23 tests).

The only overlay replaces the three undefined `MLDSA_MEM_ADDR_WIDTH` references with `ABR_MEM_ADDR_WIDTH`; its manifest states testbench and filelist scope only, with no RTL, firmware, or pass-criteria change. Pinned-only row59 remained BLOCKED at compile: the original include omissions are recorded in the M15 baseline, and job 2683 exposed the undefined testbench parameter after fixing the include path. With the testbench/filelist overlay, this run is PASS. Overlay source SHA256: `cc5cfc48169328257c116a717c043653f5097d6db1adb1d7f919e8862b0aac55`; overlay filelist SHA256: `f3ab587346db436e5de1626b5e9db2b2bd17ff777493cc32590eedd395c0da39`; compiled VVP SHA256: `14ae3cf0badf6609cba6aa4044beeac6662b0bb9fa05b4c415e7d3ce493ed6dc`.

`raw/run.sbatch` and captured command/resource/result/log/overlay files preserve the run. `raw/SHA256SUMS.remote.txt` was verified successfully before the remote run tree was removed.
