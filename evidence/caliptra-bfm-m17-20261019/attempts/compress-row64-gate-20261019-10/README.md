# M17 row 64 compress filelist gate

Slurm job 2885 ran one task with 1 CPU, 4 GiB, a 20-minute allocation cap, and a 600-second per-row timeout on DAN-DESKTOP. Pinned Icarus source: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; binary SHA-256: `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Adams Bridge pin: `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.

The filelist overlay added the missing `ntt_defines_pkg.sv` after `abr_params_pkg.sv`. Compile then stopped because pinned `compress_tb.sv:43` connects `mem_wr_req` and `mem_wr_data`, which are not ports of the current DUT. No simulation ran. Intern independently extracted both elaboration errors; the archived compiler log confirms them.

Source snapshot SHA-256: `417ca8b53ec686899f48d44e607bc298c171c215f1cf3823d3e9e8454456a1e5`. Raw job archive SHA-256: `dd35f30012385432075659740290e1ca5add24c84c62192d1e9edd77b4acb173`.
