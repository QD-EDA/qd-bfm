# Top-level build attempt 1299

Slurm job 1299 ended at the upstream Makefile prerequisite check before any RTL compilation. The Makefile defaults to `riscv64-unknown-elf-gcc`; the protected firmware compiler is xPack `riscv-none-elf-gcc` 15.2.0 (`f0aeb21d7c8aeac5dbbccbcdc2b3c80ecff615a1d7f7f3db3b507836b1c1c398`). The first script omitted both the compiler directory from `PATH` and `GCC_PREFIX=riscv-none-elf`.

The resource log records exit status 2, 0.00 seconds elapsed, and 7,736 KiB peak RSS. No testbench code compiled. The next attempt uses the existing protected toolchain and the matching prefix; it does not alter the design or test criteria.
