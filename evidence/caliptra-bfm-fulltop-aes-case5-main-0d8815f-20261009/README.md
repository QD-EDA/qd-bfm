# Caliptra full-top AES/DMA case 5 on published Icarus main — 2026-10-09

The fifth short AES/DMA vector passed through the pinned Caliptra top with the
open AXI target and native checker enabled. Compilation, firmware generation,
and simulation exited 0. The trace contains one `TESTCASE PASSED`, no checker
failure marker, and normal `$finish` at 43,480,000 ps. The final periodic trace
is cycle 4300 / 1,575 retired instructions; firmware reports `minstret=1584`
and `mcycle=4209`. AXI totals were three AW/B responses with ten W beats, and
two AR requests with ten R beats.

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
  --limit-aes-cases 1 --start-aes-case 4 --fast-trng --trace-axi \
  --output /private/tmp/qd-bfm-fulltop-aes-case5-0d8815f-20261009
```

## Revisions and fingerprints

- QD BFM branch at launch: `e93e8efdba151c6ebc96021abd12cf9f312b5619`.
- Caliptra source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus `main`: live-verified published SHA
  `0d8815febc260928e62d5c2ce82b14afd2e38dc3`.
- `iverilog` SHA-256: `603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a`.
- `vvp` SHA-256: `07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c`.
- `iverilog-vpi` SHA-256: `1e393171c4272f92db03541c9c483afb4b9211e01a1476ab01d4890f0e949d83`.
- Full-top runner SHA-256: `2a5b59b60371e1508305014fdabcbb217b47e3978c2f84c12ed545ae1c85d400`.
- Compiled simulation image SHA-256: `1f32ed5c6c2424d3d406baecf01928d16c519e3665d1114f9420f13eda8c1119`.
- AXI trace VPI SHA-256: `ea9e5d5cf2168437f27b5911c07592cbc892187f71b054eb1164022e918dc75c`.

The Icarus source checkout is not embedded in `result.json`; its
`source_checkout` field is null. The published revision and clean build are
recorded above.

Retained artifacts:

- [`result.json`](result.json), SHA-256 `8c24c364d4e834ec270c494bc72091a426c191b2762936db5db2b6dc9a1514fe`.
- [`compile.log.gz`](compile.log.gz), compressed SHA-256 `d01fa481bf9f23d527f417d87be41df1723b85e7465b55a0625499cfdc1e244d`;
  uncompressed SHA-256 `66436721c32794e7875ec63d520e588af22f229704594d05a8aea38ba3fd84aa`.
- [`sim.log.gz`](sim.log.gz), compressed SHA-256 `b16868315a7071437f3fc1b881dc961b5dd546d2ca4ef6dcf246e8b60b39cdec`;
  uncompressed SHA-256 `a59bd21116311782df0a0afd78cd70c105237f7b9d6febe27e4d0f2a2f361d0d`.
