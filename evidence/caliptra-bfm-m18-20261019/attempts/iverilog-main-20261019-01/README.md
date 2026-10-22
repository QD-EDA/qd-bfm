# Icarus main build — initial M18 pin

Slurm job 2994 built a fresh shallow clone of `dsellerbrock/iverilog-uvm` main at `82023726be90ab269d6e0ef5e755ebb69e6f648c`; its `uvm-core` submodule is `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. The build completed on DAN-DESKTOP and installed to the protected path `/home/dsell/toolchains/iverilog-uvm-m18-main-82023726be90ab269d6e0ef5e755ebb69e6f648c`.

The UVM smoke compiled and printed `No-rand test PASSED!`, with `UVM_ERROR=0` and `UVM_FATAL=0`. Compiler and runtime identify as Icarus 13.0 (devel) at the pinned SHA. Binary SHA-256 values are `9c34ccc0e24fe17881e0153927d60668ff78afd21a639091087bcc09edca988b` (`iverilog`) and `ab0c3ae4e0e2b31e0d6ed978dca9fc58198a46333ee63afa7af77c474ce41dbf` (`vvp`). The build host used GCC 15.2.0, Bison 3.8.2, Flex 2.6.4, and gperf 3.3. Slurm accounting storage is disabled, so the exit code was unavailable; the scripted install and final smoke check both produced their expected outputs.

Raw source snapshot, build/install logs, smoke logs, and checksums are under `raw/`. The snapshot SHA-256 is `f105b5eadd46e5779d323615ff3e57b410072b260091705bc8075ad48bf132c8`. M18 still requires a second immutable build if A3 merges `batch/2026-10-19-1`.
