# M16 AHB transfer type-parameter reproducer

The M16 PV open-AHB gate (row 46, job 2670) exposed missing-member errors in the generated PV predictor and the QD-BFM AHB predictor. The minimized case in `pv_generic_transfer_repro.sv` keeps the nested generic class inheritance, typed transfer members, and queue accesses involved in those errors.

Pinned Icarus 13.0 devel at source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` (compiler SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) exits 10 while elaborating this source. It reports that `RnW`, `address`, `size`, `data`, and `resp` are absent from class type `T`; VVP does not run. Slurm job 2705 used 1 CPU, 1 GiB, and a 60-second per-command timeout; peak RSS was 10,868 KiB.

Verilator 5.051 devel (`v5.050-196-g7dcd4e0b6`) compiled and ran the same file on the Mac, printing `PV_WRITE 00001000 0000000000001234`. This isolates the failure from the full generated UVMF source. The reduced behavior is filed for A3 classification and repair in [iverilog-uvm issue #663](https://github.com/dsellerbrock/iverilog-uvm/issues/663) with the `from-caliptra-dv` label.

The original row 46 gate remains **BLOCKED** by other generated UVMF/Icarus compile diagnostics as well. Issue #663 does not by itself qualify the PV environment; no QD-BFM code was changed while the simulator behavior is classified.

The Slurm capture contains the source copy, toolchain metadata, compile log, result, and resource report. Capture SHA256: `a4aa00e9406124eca9f50948d2154ee4f7cedc851f07826d43b3f5d47af08f88`. `SHA256SUMS.local.txt` verifies its members. Local Verilator commands, version/hash, and output are in `verilator-meta.txt`, `verilator-build.log`, and `verilator-run.log`.
