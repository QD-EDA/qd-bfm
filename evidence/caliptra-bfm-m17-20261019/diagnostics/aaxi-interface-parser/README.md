# AAXI interface parser minimal variants

Job 2886 tested four small interface declarations on DAN-DESKTOP. Icarus 13.0 (devel) from pinned source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` compiled `ansi-wire`, `ansi-logic`, `nonansi-wire`, and `no-port` with exit 0; Verilator 5.032 compiled all four with exit 0.

Job 2892 compiled the full `axi4_caliptra_record_if.sv` plus a small instantiating module using the same `-uvm -g2017 -gassertions` flags as row 43. Icarus and Verilator both exited 0. This rules out the BFM interface’s syntax itself as the cause; row 43’s original error came from adding the same interface twice through the AHB and AAXI filelists.

Intern’s review of job 2886 independently confirmed Verilator success; job 2886’s raw result confirms all eight exits were 0. For job 2892, intern summarized the full interface and Verilator logs as successful; both Icarus logs and result codes are verified in the archive.

Raw archive SHA-256 values: job 2886 `8ce45c971affd261d90fac019a31c64eeccc742599ca55c1620384caae4522a8`; job 2892 `2f43ba1edb6e1a7865fa5a345474cb7b7b5864518225d4628d009d2e97d70614`.
