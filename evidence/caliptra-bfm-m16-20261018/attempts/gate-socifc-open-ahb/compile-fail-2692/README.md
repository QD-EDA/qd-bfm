# M16 SoC-IFC open-AHB gate: compile failure (job 2692)

The corrected snapshot reached Icarus, but compilation failed with exit 49 before VVP ran. This is not a firmware pass/fail result.

- Slurm job: `2692`, host `DAN-DESKTOP`, run directory `/home/dsell/slurm-runs/caliptra-bfm/a2/m16-socifc-open-ahb-20261018-02`.
- Elapsed 1.31 s; process-group peak RSS 135,832 KiB; 1 CPU, 5 GiB requested; 600 s per-test guard configured.
- Firmware source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source pin: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Frozen source snapshot SHA-256: `750166742900f16fe14b87f6a61d2e2684eeaaee449806cb664110693d1025cf` (205 files; per-file hashes verified locally and on DAN-DESKTOP).

Verified compile blockers:

1. The snapshot still omitted `evidence/caliptra-bfm-soc-ifc-generated-hdl-20261004/hdl_stubs.sv`.
2. `generated_test_dependency_stubs.sv` redeclared `QUESTA_MVC` and `qvip_utils_pkg`, already provided by `caliptra_ahb_mvc_compat_pkg.sv` and `caliptra_ahb_qvip_compat_pkg.sv` in the QD-BFM filelist.
3. Icarus emitted syntax errors for generated covergroup bin declarations in mailbox, SHA-512, SoC-IFC register, and CPTRA status coverage sources, each followed by its “unsupported bins declaration was ignored” diagnostic. Those coverage sources need a narrowly scoped compile overlay if the runtime gate can avoid collecting them without changing functional checks.

`raw/` preserves the complete runner log, exit/resource reports, Slurm output, job metadata, frozen source snapshot, file manifests, and capture archive. No simulation or firmware outcome is claimed. The remote run tree and temporary capture archive are removed after evidence capture.
