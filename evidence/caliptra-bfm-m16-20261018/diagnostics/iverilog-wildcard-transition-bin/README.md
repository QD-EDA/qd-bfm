# Icarus wildcard transition-bin reproducer

This one-file reproducer is reduced from the `wildcard bins set = (32'h0000_0000 => 32'h400?_????);` declaration in pinned Caliptra `cptra_status_transaction_coverage.svh` (the M16 job 2692 compile log points to this declaration family).

- Slurm job: `2694`, host `DAN-DESKTOP`; 1 CPU, 1 GiB, 30 s command timeout; compile-only, no simulation.
- Icarus source: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Source SHA-256: `c7b6b2dac4ec6b7db746ad216ff387a50756322a3ebc3014dbf60914142c421c`.
- Command: `iverilog -g2012 -s wildcard_transition_bin_tb -o wildcard_transition_bin_tb.vvp wildcard_transition_bin_tb.sv`.
- Result: exit 1; Icarus reports `syntax error` and `sorry: unsupported bins declaration was ignored (functional coverage for it is not collected).` The compile took under 0.01 s and used 8,320 KiB peak RSS.

This confirms a reproducible Icarus limitation at the exact coverage syntax blocking job 2692. Internal issue [dsellerbrock/iverilog-uvm#661](https://github.com/dsellerbrock/iverilog-uvm/issues/661) is filed with `from-caliptra-dv`; it leaves bug-versus-feature classification to A3. Raw compile output, versions, resources, source, hashes, and the Slurm wrapper are preserved under `raw/`.
