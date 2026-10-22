# M16 SoC-IFC open-AHB gate: staging failure (job 2691)

This attempt is an infrastructure/setup failure, not a compile or simulation result. The staged source omitted `evidence/caliptra-bfm-soc-ifc-axi-target-20261004/prepare_overlay.py`. The runner stopped while preparing the disposable testbench overlay, before invoking Icarus; no firmware simulation started.

- Slurm job: `2691`, host `DAN-DESKTOP`, run directory `/home/dsell/slurm-runs/caliptra-bfm/a2/m16-socifc-open-ahb-20261018-01`.
- Result: runner exit 1 after 0.55 s; process-group peak RSS 34,816 KiB; one CPU, 5 GiB requested; 600 s per-test guard configured.
- Source snapshot SHA-256: `f548d35e8fa43a40857485efdc223604345e5d02edbe34c7b35baf55e85597b8`. Its manifest includes the hostpkgs runner but not the omitted helper directory.
- Firmware source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source pin: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- The payload checksum list validates all archived non-AppleDouble files. Its missing `._*` entries are macOS resource-fork sidecars and are not source inputs.

Raw capture, extracted payload, runner logs, resource report, exit code, source snapshot, and checksums are preserved under `raw/`. The exact remote run directory and temporary capture archive are removed after capture; this attempt does not qualify or disqualify the BFM.
