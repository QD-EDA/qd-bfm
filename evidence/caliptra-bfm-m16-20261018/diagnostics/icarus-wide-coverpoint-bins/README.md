# Icarus wide automatic-bin diagnostic

Status: **reproduced on pinned Icarus; filed internally** as [issue #667](https://github.com/dsellerbrock/iverilog-uvm/issues/667), label `from-caliptra-dv`.

The 512-bit class-property coverpoint copied from generated SHA-512 coverage fails elaboration with `automatic bins for a coverpoint wider than 64 bits are not represented`. The 64-bit control compiles and runs to `NARROW_AUTO_BINS_OK`. The control also emits a `sorry`/warning that Icarus treats this class-property coverpoint as constant zero at the sample site; this is recorded, not presented as successful coverage sampling. No simulation was run for the 512-bit case.

## Toolchain and run

- Host: DAN-DESKTOP.
- Icarus 13.0 devel, source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, `iverilog` SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`, `vvp` SHA256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Each compile/runtime command had a 60-second timeout. One CPU, 1 GiB RAM, 5-minute Slurm limit; the remote run tree was removed after the logs and source were saved.
- `wide_auto_bins.sv` and `narrow_auto_bins_control.sv` are the exact test/control pair. Full compile/run logs, resource/output archive, source archive/hash, and submission metadata are beside them.

The unrelated no-parentheses concatenation diagnostic from SHA-512 row 17 is tracked separately in [issue #664](https://github.com/dsellerbrock/iverilog-uvm/issues/664). No upstream issue or PR was opened.
