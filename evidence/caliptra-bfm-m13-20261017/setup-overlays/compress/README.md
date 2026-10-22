# `compress_tb` filelist overlay

The M13 pinned-only row compiled with current Icarus main `9b5fad2afb4104caa816b257d5bccc40f01b8c66` and stopped because the pinned filelist omits the existing `ntt_defines_pkg.sv`, imported by the Barrett reduction modules. The raw row is `pinned-only/run-2196_21/`; its task job ID is 2217 (array `2196`, element 21). The pinned filelist SHA-256 is `220822ea8e9c03ffdf3bd01567ea6192ab8c3a3b1f6df04fa328082f8f3fa16c`.

The overlay makes one filelist-only change: add `ntt_defines_pkg.sv` after its prerequisite `abr_params_pkg.sv`. It does not modify RTL or the testbench. The overlay filelist SHA-256 is `75455163fd14ae54bdb58505714867e18be0822d07d0a6c70ae6b7dc05fa02f8`; the package SHA-256 is `8c25823dbe45da21874236963d5d7a5ab66792532f1fba3bc498edf4ea7187f8`. The patch, exact filelist, and runner are stored here.

One-row overlay gate 2276 ran on DAN-DESKTOP with 1 CPU, 3 GiB, and a 600-second total compile/simulation cap. Current Icarus `iverilog`/`vvp` binaries match the M13 toolchain hashes. Compilation no longer reports the missing package; it instead stops at `compress_tb.sv:43` because obsolete ports `mem_wr_req` and `mem_wr_data` are absent from `compress_top`. Simulation did not run. The setup blocker is fixed; the row remains **BLOCKED** by the pinned testbench/RTL interface mismatch, matching the c339 overlay result. It is not an Icarus defect.

The run archive SHA-256 is `c4ede00476030bbf47f092c9279b831fffabd0c3d654069e0167fa1227a3de54`. The output manifest verifies. After archiving it, the 24,083-byte Slurm run directory was removed; protected toolchains and firmware inputs were untouched.
