# Caliptra full-top AES/DMA case 6 on published Icarus main — 2026-10-09

The sixth short AES/DMA vector passed through the pinned Caliptra top with the
open AXI target and native checker enabled. Compilation, firmware generation,
and simulation exited 0. The trace contains one `TESTCASE PASSED`, no checker
failure marker, and normal `$finish` at 45,180,000 ps. The final periodic trace
is cycle 4500 / 1,627 retired instructions; firmware reports
`minstret=1630` and `mcycle=4379`. AXI totals were
3 AW/B responses with 12 W beats, and
2 AR requests with 12 R beats.

This is one diagnostic vector, not stock-firmware or full-suite qualification.
It uses fast TRNG cadence, `.data`/`.bss` preload, PQ-vector suppression, the
open-source source overlays, and the Caliptra BFM checker. Other vectors and
stock-firmware qualification remain open.

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
  --limit-aes-cases 1 --start-aes-case 5 --fast-trng --trace-axi \
  --output /private/tmp/qd-bfm-fulltop-aes-case6-0d8815f-20261009
```

## Revisions and fingerprints

- QD BFM branch at launch: `89e23043dbc5e1aac5c880cc6de70e5602733ab8`.
- Caliptra source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus `main`: live-verified published SHA
  `0d8815febc260928e62d5c2ce82b14afd2e38dc3`.
- `iverilog` SHA-256: `603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a`.
- `vvp` SHA-256: `07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c`.
- `iverilog-vpi` SHA-256: `1e393171c4272f92db03541c9c483afb4b9211e01a1476ab01d4890f0e949d83`.
- Full-top runner SHA-256: `2a5b59b60371e1508305014fdabcbb217b47e3978c2f84c12ed545ae1c85d400`.
- Compiled simulation image SHA-256: `52c13c201d6061f07051ac3430291866da15b7a4065a7abc740c7aa3f450df62`.
- AXI trace VPI SHA-256: `d3e13c165009d1be1c89aa64001afe61775413a0609b828f3e911a14deecf153`.

The Icarus source checkout is not embedded in `result.json`; its
`source_checkout` field is null. The published revision and clean build are
recorded above.

Retained artifacts:

- [`result.json`](result.json), SHA-256 `0c002c976e4e2266f49d0813e12772133beabc23dbddfa572c7823847990e9e7`.
- [`compile.log.gz`](compile.log.gz), compressed SHA-256 `939f325159de6cb73a2a6f6f12215385611844eece87e0982a670398b1457441`;
  uncompressed SHA-256 `2acc4b9e63833145fae20acd4dc667be08d06552024c20c6c3cc3ad3d3d1bce6`.
- [`sim.log.gz`](sim.log.gz), compressed SHA-256 `d6dad428ed7d73cf2eeb3c6317d5a39ecebf74c380501ee453a701d90af57d3c`;
  uncompressed SHA-256 `a700ce3babd180129ce0b1ea8a836940ce1da8b28fa808065a1a7843783cee5e`.
