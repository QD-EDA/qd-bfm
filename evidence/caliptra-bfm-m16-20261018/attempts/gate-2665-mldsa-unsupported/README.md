# MLDSA AHB MVC one-row gate: row 96

Job 2665 ran on DAN-DESKTOP with pinned Icarus 13.0 (source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) and the open AHB/MVC overlay. It reached generated MLDSA package elaboration and stopped with compile exit 12; no simulation started. Result status is **BLOCKED**, not a firmware result.

The first diagnostic is Icarus treating the generated zero-argument `qvip_ahb_lite_slave_subenv_config.convert2string` reference as a non-string value. The QD-BFM config class does define that method, so the intern's “missing BFM API” classification was incorrect. Additional diagnostics are Icarus gaps on dynamic-array slice r-values and nested class member paths. The generated MLDSA sources also call `string.substr(8)` with one argument; the tool reports that two are required. The first config formatting call and `substr` uses may be handled by a testbench overlay if MLDSA remains the chosen proof environment, but its remaining compiler gaps make a smaller AHB environment a better next gate.

The intern triage is preserved in `intern-triage.md`; its claims were checked against `compile.log`, the pinned generated sources, and `dv/caliptra_bfm/uvm/caliptra_ahb_qvip_compat_pkg.sv`.

## Reproduction record

- Source: Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`; row 96, `ML_DSA_randomized_early_run_test`, seed 1.
- Run: `/home/dsell/slurm-runs/caliptra-bfm/a2/m16-mldsa-open-ahb-20261018-03`; 1 CPU, 3 GiB, 20-minute Slurm cap, 600-second per-row timeout.
- Command and compile log: `row-96/compile.command`, `row-96/compile.log`; result and resource records are adjacent.
- Staged source archive SHA256: `4686a543c11f86b1d8f400979328a6d771bf8d14cdfde07928761a867501fcd1`.
- Slurm log, job metadata, batch script, and runner resource record are preserved here. The completed 3.1 MiB remote run directory was removed only after these files were copied.
- Overlay scope was limited to BFM, testbench filelist and setup. No RTL, firmware, or pass criteria changed.
