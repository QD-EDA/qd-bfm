# Generated SHA-512 row 17 open-MVC gate

Status: **BLOCKED before simulation** on pinned Icarus 13.0 (job 2770). The vendor-free open-MVC filelist was accepted, but the generated testbench has two unsupported constructs during elaboration:

- `SHA512_out_transaction_coverage.svh:50` implicitly requests automatic bins for the 512-bit `coverage_trans.result` coverpoint; Icarus reports that automatic bins for coverpoints wider than 64 bits are not represented.
- `SHA512_env_configuration.svh:85` uses a no-parentheses `SHA512_in_agent_config.convert2string` call in a string concatenation. This matches the already minimized simulator issue [#664](https://github.com/dsellerbrock/iverilog-uvm/issues/664).

The job exited during compile, so this row has no simulation or testcase result. The intern identified the first compiler diagnostic and compile-only status; the full log was checked and contains both errors. No RTL, firmware, or pass criteria changed.

## Run details

- Host: DAN-DESKTOP, current pinned source Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Simulator: Icarus 13.0 devel, source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Row: 17, `SHA512_random_test`, seed 1; one CPU, 2 GiB, 15-minute Slurm limit; runner timeout 600 seconds.
- Open-MVC filelist removed the pinned filelist's inactive proprietary MVC/QVIP sources and supplied QD-BFM compatibility sources. The source inventory found no active MVC API references in this SHA-512 generated environment.
- Local runner source/archive hashes and exact staging state are recorded beside this README. Raw compile log, resource report, result JSON, overlay filelist/manifest, Slurm output, and evidence archive are in [`raw/`](raw/).

The wide automatic-bin failure is separately minimized and filed for A3 as [issue #667](https://github.com/dsellerbrock/iverilog-uvm/issues/667), labeled `from-caliptra-dv`. A 64-bit control compiles and runs; the 512-bit case fails with the same diagnostic. The control also emits an Icarus warning that its class-property sample is treated as constant zero; that limitation is preserved in the raw diagnostic log.
