# M16 SoC-IFC open-AHB setup gate (job 2695)

This gate validates the runner setup correction against the complete generated environment. The corrected filelist now omits the duplicate clean-room MVC package stub in generated-runtime mode, and the frozen snapshot includes both required helper directories. Icarus then reached compilation and stopped on the reduced wildcard-transition-bin limitation; VVP did not start, so there is no firmware result.

- Slurm job: `2695`, host `DAN-DESKTOP`, run directory `/home/dsell/slurm-runs/caliptra-bfm/a2/m16-socifc-open-ahb-20261018-03`.
- Runner exit 47; elapsed 1.30 s; process-group peak RSS 136,712 KiB; 1 CPU, 5 GiB requested; 600 s per-test guard configured.
- Firmware source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Frozen source snapshot SHA-256: `e79ba3c0736cf9f7fea668ee9d253e8755c2db3c6ff8239003abb2c0e0c74113` (208 files; hashes verified locally and on DAN-DESKTOP).
- The earlier missing `prepare_overlay.py` and `hdl_stubs.sv` errors are gone, as are both duplicate-package errors. The remaining 47 diagnostics are syntax errors paired with Icarus's unsupported-bin message in generated coverage sources. The minimal case is captured in `diagnostics/iverilog-wildcard-transition-bin/` and tracked as [internal issue #661](https://github.com/dsellerbrock/iverilog-uvm/issues/661).

The testbench setup change passed `py_compile` and `git diff --check`; this integration run confirms it removes the duplicate package failure. Raw runner logs, resource data, metadata, source manifest, and remote capture are preserved under `raw/`. The remote run tree and capture archive are removed after evidence capture.
