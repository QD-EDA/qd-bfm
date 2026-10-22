# Simple interface-assignment probe: no gap reproduced

The first reduction used a fixed-width `logic` member in an interface and a
continuous assignment through a module's interface port. It passed on current
main (3335fe7), c339, and Verilator 5.052. This case does not reproduce the
Caliptra `el2_mem.sv` diagnostics and is not being filed as a compiler issue.

The Caliptra interface is parameterized from `el2_param.vh` and the module
ports use output modports (`el2_mem_if.veer_sram_src` and
`el2_mem_if.veer_icache_src`). A follow-up reduction is testing that narrower
shape. Source, compile/simulation logs, resource reports, versions and binary
hashes are retained under `results/`; all 21 transferred result files were
verified against DAN-DESKTOP hashes. The disposable remote build directory
was then removed (772,994 bytes freed).
