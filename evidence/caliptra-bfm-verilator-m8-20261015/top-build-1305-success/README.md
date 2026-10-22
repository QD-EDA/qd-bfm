# Verilator top-level model build: job 1305

This is compile evidence only; the model built here was not used for firmware test results.

- Host: DAN-DESKTOP, Slurm job 1305 (`a2-vlt-qd-top`), run `m8-verilator-top-20261015-04`.
- Source: QD-BFM commit `d0d728d7a4aea66ce1962a418d6403d017b72157`, clean staged tree; Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.
- Toolchain: Verilator `5.052 2026-09-05 rev v5.052`; `riscv-none-elf-gcc` 15.2.0, SHA-256 recorded in `riscv-gcc.sha256`.
- Build: upstream `tools/scripts/Makefile` `verilator-build`, `--timing`, 4 CPUs, 12 GiB requested. The QD filelist replaced only the upstream AXI-complex BFM and added 15 BFM sources. The command and filelist hashes are recorded in `build-qd-bfm-top-2state.sbatch` and `filelist-manifest.txt`.
- Result: frontend elaborated 813 modules and generated the C++ model; C++ link completed, exit 0. Wall time 4:01, peak RSS 2,363,276 KiB. Model tree size was 747,800,926 bytes; executable SHA-256 is in `model.sha256`.
- Warnings: `MISINDENT` in upstream `caliptra_top_tb_services.sv:1111` and `CASEINCOMPLETE` in the QD `axi4_caliptra_checker.sv:217`. `--Wno-fatal` allowed these warnings to remain visible while errors still failed the build.
- Follow-up: the upstream top testbench binds JTAG DPI to port 63224. Parallel test runs need the existing runner's port-0 overlay, so this first model is superseded for runtime tests by a fresh model with that overlay.

`build.log`, `verilator_make.log`, `verilator_build.log`, and `build.resource` preserve the run output. `SHA256SUMS` covers the evidence files.
