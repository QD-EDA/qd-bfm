# Caliptra full-top AES/DMA case 2 on published Icarus main — 2026-10-09

The second short AES/DMA vector passed through the pinned Caliptra top with
the open AXI target and native checker enabled. The guarded runner exited 0
with one `TESTCASE PASSED`, no failure markers or bad diagnostics, and normal
`$finish` at 39,380,000 ps. The final trace reports cycle 3,938 / 1,461 retired
instructions; the firmware reports `minstret=1460`, `mcycle=3799`. AXI totals
were two AW/B transactions with four W beats, and two AR requests with four R
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
  --limit-aes-cases 1 --start-aes-case 1 --fast-trng --trace-axi \
  --output /private/tmp/qd-bfm-fulltop-aes-case2-0d8815f-20261009
```

## Revisions and fingerprints

- QD BFM branch at launch: `c83ed794b9c8130676f4026bcca1273491267d2e`.
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
  `81b36dccc08cc4f25be009d915f89d8b0d2fab00b066dd3428b140df7d5aa2d7`.
- AXI trace VPI SHA-256:
  `44ce0db395e9fdd77b45cf3ba43eecda6ab521039b73250e2e9e0ee2a5fc458d`.

The Icarus source checkout is not embedded in `result.json`; its
`source_checkout` field is null. The published revision is recorded above and
the clean build and tool fingerprints match the [case-12 published-main
evidence](../caliptra-bfm-fulltop-aes-case12-main-0d8815f-20261009/README.md).

Retained artifacts:

- [`result.json`](result.json), SHA-256
  `3485993d7c98f8811b3a574c3aea8973d03edc7407960cd54bb86d473b22a67b`.
- [`compile.log.gz`](compile.log.gz), compressed SHA-256
  `3dc6a13204650a3f0182616f3247b1b47e77393e52e426c3bfc6ee141aac1812`;
  uncompressed SHA-256
  `e89300a0b872b724059cbc8207fb50314d96da53ea12cb5a320925f0a467edc2`.
- [`sim.log.gz`](sim.log.gz), compressed SHA-256
  `372420ce95bd3128e484ffbf5aa8f2872f0c6b7ca3a0d0d5197eb33f940cf44c`;
  uncompressed SHA-256
  `1bebb968d0a1f899c344c2d943aadc92a99571eda430cbb27906dd299a8eae2b`.
