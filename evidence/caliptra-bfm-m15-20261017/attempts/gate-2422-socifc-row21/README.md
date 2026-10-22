# SoC-IFC row-21 compatibility gate

Job 2422 tested row 21 (`fuse_reg_prod_test`) with the hash-guarded associative-array syntax overlay from runner commit `c0ecd686`. Compilation advanced past the eight array initializers, then stopped at `function SocRegisters::lock_fuses();` in the same pinned testbench package. The result is `BLOCKED`, compile exit 3, elapsed 0.194 s; no simulation ran.

The minimized class-method reproducer in `diagnostics/implicit.sv` fails on pinned Icarus 13.0 (`9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) with `lock_fuses doesn't name a type`. Verilator 5.032 accepts the same source. The explicit-`void` control passes both compilers. Filed as [iverilog-uvm issue #641](https://github.com/dsellerbrock/iverilog-uvm/issues/641), labeled `from-caliptra-dv`, for A3 to fix.

The gate result, transformed testbench source, temporary filelist, overlay manifest, exact command, compile log, and resources are preserved in `row-21/`.
