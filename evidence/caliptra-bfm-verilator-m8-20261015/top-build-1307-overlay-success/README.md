# Verilator top-level model build with JTAG port overlay: job 1307

This model is the one used by the M8 firmware runs. The only testbench edits are the existing runner's pinned timescale prefix and JTAG listen-port change from 63224 to 0; the AXI-complex filelist entry is replaced by the QD-BFM wrapper plus 15 BFM sources. No test logic or pass criteria changed.

- Host: DAN-DESKTOP, Slurm job 1307 (`a2-vlt-qd-top`), run `m8-verilator-top-20261015-05`.
- Source: QD-BFM commit `d0d728d7a4aea66ce1962a418d6403d017b72157`, clean staged tree; Caliptra RTL `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; Adams Bridge `b77e3d899e828d626cfc2a0d26a6b5704cc121e0`.
- Toolchain: Verilator `5.052 2026-09-05 rev v5.052`; `riscv-none-elf-gcc` 15.2.0. The compiler SHA is in `riscv-gcc.sha256`.
- Build: upstream `tools/scripts/Makefile` `verilator-build` with `--timing`, 4 CPUs, 12 GiB requested; 4:07 elapsed, peak RSS 2,363,192 KiB, exit 0. The model tree was 708,119,501 bytes. Executable SHA-256 is in `model.sha256`.
- Filelist: base SHA-256 `9892643a7eb1c89a98b1aec4c3aceee17224d077263919317d5d2bf146a1ae90`; generated overlay SHA-256 `b28b65582f08000d32ef5ef4049c10230c24ecab0937376e999e9f6e1d524714`. The top testbench source hash is `c212c32da99e90cd3991da65e653998cac3e945d7479abfd640b9d82f47659f9`; overlay hash is `6b3d6eeb6bbb3acddcc6045b86c9cc6c6ca3934164f29564485a9a3d2fc4d02a`.
- Warnings: nonfatal upstream `MISINDENT` at `caliptra_top_tb_services.sv:1111` and `CASEINCOMPLETE` at the QD checker `axi4_caliptra_checker.sv:217`. They remain in the build logs; `--Wno-fatal` allows warnings but build errors still fail.
- The run tree remains on Slurm because its model is being used by the comparison arrays. Remove it after all result logs and checksums are copied.

`build.log`, `verilator_make.log`, `verilator_build.log`, `build.resource`, the generated filelist, and generated testbench overlay preserve the evidence. `SHA256SUMS` covers the files in this directory.
