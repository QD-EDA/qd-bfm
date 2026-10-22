# Top-level build attempt 1300

The pinned RISC-V compiler was found and the upstream firmware Makefile prerequisite passed. Verilator then generated C++ but exited before the C++ model build because it treats two warnings as fatal by default: upstream testbench `MISINDENT` at `caliptra_top_tb_services.sv:1111`, and QD-BFM checker `CASEINCOMPLETE` at `axi4_caliptra_checker.sv:217`. Slurm job 1300 ended with exit status 2, peak RSS 2,362,516 KiB; its full log and resource report are retained here.

The checker initializes `candidate = addr` before the `case (burst)`, so fixed burst encoding `2'b00` intentionally retains the address while INCR and WRAP update it. No test logic, checker behavior, or pass criteria are changed. The next build passes `--Wno-fatal` so warnings remain visible in the compiler log while ordinary errors still fail the build.
