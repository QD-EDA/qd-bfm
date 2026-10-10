# AXI checker unknown-control coverage — 2026-10-09

Slurm job 105 passed the complete guarded `tests/run_checker.sh` regression,
including existing valid and invalid traffic plus both X and Z injected
individually on all ten AXI VALID/READY pins (`AW`, `W`, `B`, `AR`, and `R`).
Each unknown-control case was rejected with the checker's
`VALID/READY control is unknown` diagnostic.

The job used QD-BFM base commit `e88c8809b01c59ff0147f9232124444ce820c7f0`
with the changed checker testbench and runner recorded in `qd-inputs.sha256`.
It used Icarus Verilog 13.0 (devel) from clean published `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` and the pinned Caliptra toolchain's
`iverilog`/`vvp`; this plain SystemVerilog regression needs neither UVM nor
Caliptra RTL.

The job requested 256 MiB and one CPU. The estimate used the previous guarded
Icarus run's 17,536 KiB MaxRSS; the new run measured 17,600 KiB MaxRSS and a
0.01 GiB maximum process group, completed in 0.53 s, and exited zero. The
process-group cap was 150,000,000 bytes. `job105/` retains the submitted Slurm
script, raw logs, tool hashes, and exact source manifests.

This establishes Icarus checker coverage for X/Z VALID/READY controls. It does
not establish four-state parity on another simulator or full Caliptra/UVMF
qualification.
