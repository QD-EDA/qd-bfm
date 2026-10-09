# Caliptra full-top AES/DMA case 4 on published Icarus main — 2026-10-09

The fourth short AES/DMA vector passed through the pinned Caliptra top with
the open AXI target and native checker enabled. The guarded runner exited 0
with one `TESTCASE PASSED`, no failure markers or bad diagnostics, and normal
`$finish` at 41,390,000 ps. The final trace reports cycle 4,139 / 1,528 retired
instructions; the firmware reports `minstret=1527`, `mcycle=4000`. AXI totals
were two AW/B transactions with eight W beats, and two AR requests with eight
R beats.

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
  --limit-aes-cases 1 --start-aes-case 3 --fast-trng --trace-axi \
  --output /private/tmp/qd-bfm-fulltop-aes-case4-0d8815f-20261009
```

## Revisions and fingerprints

- QD BFM branch at launch: `402f5030c11e5c217d6d5f12a15166b5c7501b68`.
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
  `7cd43c99fa815f9f8e62d48c326acfc8b3a87a01aea18524d6a382d6e12f41af`.
- AXI trace VPI SHA-256:
  `0f2af7b1cc303ebe9341fc65e6ea709cf540d64751c68302d082bf7cc54a61e2`.

The Icarus source checkout is not embedded in `result.json`; its
`source_checkout` field is null. The published revision is recorded above and
the clean build and tool fingerprints match the [case-12 published-main
evidence](../caliptra-bfm-fulltop-aes-case12-main-0d8815f-20261009/README.md).

Retained artifacts:

- [`result.json`](result.json), SHA-256
  `3ce11d7098eb09f6240d0fe5853e061837ed8b4aebabf797c4dee0fd05da777d`.
- [`compile.log.gz`](compile.log.gz), compressed SHA-256
  `23cf62f818b20ce1e1440beedb07ea795e1d3659e946379a82c5902a37fb708f`;
  uncompressed SHA-256
  `f98ded06bb1843458787ab18156089da2b2415a09e91baebf57377b5bfd7942e`.
- [`sim.log.gz`](sim.log.gz), compressed SHA-256
  `d730dbdf21753efd404b6dfe4e3f9f7f927756f208c48eeaf14684ed4588ab60`;
  uncompressed SHA-256
  `b99ad1ba5c891ee15bced8ee96fa300282329df93c3dc5219ebc46b8f8494f72`.
