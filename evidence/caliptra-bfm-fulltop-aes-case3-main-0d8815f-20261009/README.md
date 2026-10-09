# Caliptra full-top AES/DMA case 3 on published Icarus main — 2026-10-09

The third short AES/DMA vector passed through the pinned Caliptra top with
the open AXI target and native checker enabled. The guarded runner exited 0
with one `TESTCASE PASSED`, no failure markers or bad diagnostics, and normal
`$finish` at 39,960,000 ps. The final trace reports cycle 3,996 / 1,500 retired
instructions; the firmware reports `minstret=1499`, `mcycle=3857`. AXI totals
were two AW/B transactions with six W beats, and two AR requests with six R
beats.

This is one diagnostic vector, not stock-firmware or full-suite qualification.
It uses fast TRNG cadence, `.data`/`.bss` preload, PQ-vector suppression, the
open-source source overlays, and the Caliptra BFM checker. The separate
12-case batch remains open after its bounded timeout.

## Command

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
CALIPTRA_BFM_PROFILE=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/src/integration/config/caliptra_top_tb.vf \
CALIPTRA_JTAGDPI_VPI=/private/tmp/caliptra-jtag-vpi-197f9ba/jtagdpi.vpi \
CALIPTRA_GCC_PREFIX=/private/tmp/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf \
IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
IVERILOG_VPI_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog-vpi \
sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh \
  --case smoke_test_dma_aes_gcm_short_1_dword \
  --limit-aes-cases 1 --start-aes-case 2 --fast-trng --trace-axi \
  --output /private/tmp/qd-bfm-fulltop-aes-case3-0d8815f-20261009
```

## Revisions and fingerprints

- QD BFM branch at launch: `6777f29c1b5e1d52be8360ecf1f2b9a3ce807157`.
- Caliptra source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus `main`: live-verified published SHA
  `0d8815febc260928e62d5c2ce82b14afd2e38dc3`.
- `iverilog` SHA-256:
  `603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a`.
- `vvp` SHA-256:
  `07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c`.
- `iverilog-vpi` SHA-256:
  `1e393171c4272f92db03541c9c483afb4b9211e01a1476ab01d4890f0e949d83`.
- Full-top runner SHA-256:
  `2a5b59b60371e1508305014fdabcbb217b47e3978c2f84c12ed545ae1c85d400`.
- Compiled simulation image SHA-256:
  `206e1f825335eafff8b2d991704d86e0c9a2577815c12d65ce1381b54b123bae`.
- AXI trace VPI SHA-256:
  `27ab75a9edc82c92c2662759df8b0de6137c397f625375b10c437bbdf776de26`.

The Icarus source checkout is not embedded in `result.json`; its
`source_checkout` field is null. The published revision is recorded above and
the clean build and tool fingerprints match the [case-12 published-main
evidence](../caliptra-bfm-fulltop-aes-case12-main-0d8815f-20261009/README.md).

Retained artifacts:

- [`result.json`](result.json), SHA-256
  `713ffba771ea8d96959bb9744dc14575fa02c691857f8061722448e95c6b0b0d`.
- [`compile.log.gz`](compile.log.gz), compressed SHA-256
  `e221c6ccb554cf5376ce2c8511548553d3d3d05aef47dc547ba7a91991136a5a`;
  uncompressed SHA-256
  `18164c05af3f1d2bb19bbeac6a4a57f6804c3a11ee154df8f3ea022e911b2a11`.
- [`sim.log.gz`](sim.log.gz), compressed SHA-256
  `36a7724f6f3900ba3672d0c8654e0fe733446a59aed7137a4dcda8ab81499be6`;
  uncompressed SHA-256
  `5d7151376c7b048d38368cd957697410a338bc6e76aefc1d0be163af2c6c95ec`.
