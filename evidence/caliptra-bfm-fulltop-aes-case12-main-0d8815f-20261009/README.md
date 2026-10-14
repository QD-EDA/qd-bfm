# Caliptra full-top AES/DMA case 12 on Icarus main — 2026-10-09

The final 12-beat short AES/DMA vector passed through the pinned Caliptra top
with the open AXI target and native checker enabled. The run produced one
`TESTCASE PASSED`, no fail markers or bad diagnostics, and normal `$finish` at
simulation cycle 5276 (`minstret=1840`, `mcycle=5137`). AXI totals were four
AW/B transactions, 24 W beats, and 24 R beats across two AR requests.

This is a single-vector diagnostic, not stock-firmware or full-suite
qualification. It uses fast TRNG cadence, `.data`/`.bss` preload, PQ-vector
suppression, and the open-source source overlays. The expected sandbox JTAG
socket bind denial was recorded; there were no JTAG server errors. The memory
guard exited 0, with 7.05 GiB minimum available memory and a 1.73 GiB maximum
process group. The 344 MiB compiled simulation image and firmware build files
remain in `/private/tmp`.

## Command

```sh
env \
  CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  CALIPTRA_BFM_PROFILE=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl/src/integration/config/caliptra_top_tb.vf \
  CALIPTRA_JTAGDPI_VPI=/private/tmp/caliptra-jtag-vpi-197f9ba/jtagdpi.vpi \
  CALIPTRA_GCC_PREFIX=/private/tmp/xpack-riscv-none-elf-gcc-15.2.0-1/bin/riscv-none-elf \
  IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
  VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
  IVERILOG_VPI_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog-vpi \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_top_firmware_bfm.sh \
    --case smoke_test_dma_aes_gcm_short_1_dword \
    --limit-aes-cases 1 --start-aes-case 11 \
    --fast-trng --trace-axi \
    --output /private/tmp/qd-bfm-fulltop-aes-case12-0d8815f-20261009
```

## Revisions and fingerprints

- QD BFM source at run start: `4adf5d6872e29378ed0ea88915e2f5aad9c8f5c9`.
- Caliptra source: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus source: clean archive of locally recorded `origin/main`
  `0d8815febc260928e62d5c2ce82b14afd2e38dc3`; bundled UVM pin
  `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`. GitHub DNS prevented refreshing
  the remote head, so this records the newest locally available published ref,
  not a live-verified remote head. No Icarus checkout or branch was modified.
- Clean macOS arm64 build using Bison 3.8.2, Homebrew libffi/Z3,
  `--enable-libveriuser`, and the pinned UVM submodule. Icarus reports
  `13.0 (devel)` and bundled UVM `Accellera:1800.2:UVM:2020.3.1`.
- `iverilog` SHA-256:
  `603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a`.
- `vvp` SHA-256:
  `07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c`.
- `iverilog-vpi` SHA-256:
  `1e393171c4272f92db03541c9c483afb4b9211e01a1476ab01d4890f0e949d83`.
- JTAG VPI SHA-256:
  `1ff7ec3a466a6fac8afe2599b1b5c1901ad91bde48172423b1edb5470125f5fd`.

Retained artifacts:

- [`result.json`](result.json), SHA-256
  `c0030f8a7df32e3e2bd318b3aa85ee86bfd8d6f5909a9aa9f3bc4bdac757cfcf`.
- [`compile.log.gz`](compile.log.gz), compressed SHA-256
  `684fadd52f38e9accaae1b0abe7c51015ee5757f1aebf9063a52d0d8f8ac04d2`;
  uncompressed SHA-256 `6b3265bd5d14edee85007f463dc1495a0c6faed139cbc6464329c36040242514`.
- [`sim.log.gz`](sim.log.gz), compressed SHA-256
  `d0dcedf5b9c87057474a538c4606a3c23a43eed782c364a87fef1bbbc25423a8`;
  uncompressed SHA-256 `7fb04c9d399f1014b9b9067b7dd8133122327c78de91ae5053c5062d10c49dfa`.
- [`guard.log`](guard.log), SHA-256
  `4cabd14833515feab11e858c37f1817411979b59c48909f01177caf3b00d642d`.
