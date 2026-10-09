# Caliptra full-top AES/DMA case 1 on published Icarus main — 2026-10-09

The first short AES/DMA vector passed through the pinned Caliptra top with the
open AXI target and native checker enabled. The guarded runner exited 0 with
one `TESTCASE PASSED`, no failure markers or bad diagnostics, and normal
`$finish` at 38,020,000 ps. The final trace reports cycle 3,802 / 1,430 retired
instructions; the firmware reports `minstret=1429`, `mcycle=3663`. AXI totals
were two single-beat AW/B transactions and two single-beat AR/R transactions.

This is one diagnostic vector, not stock-firmware or full-suite qualification.
It uses fast TRNG cadence, `.data`/`.bss` preload, PQ-vector suppression, the
open-source source overlays, and the Caliptra BFM checker. It does not replace
the separate 12-case batch, which remains open after its bounded timeout.

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
  --first-aes-case-diagnostic --fast-trng --trace-axi \
  --output /private/tmp/qd-bfm-fulltop-first-aes-0d8815f-20261009
```

## Revisions and fingerprints

- QD BFM branch at launch: `a19b4ffbda0b7a236fb581ac134e246650488963`.
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
  `ba94b4aab669ff3c08c1ce171bdf4232d898d549a9c6e85b3a6dc77c5a74f1c6`.
- AXI trace VPI SHA-256:
  `b842a68d9fa906dc6971eb28e88616a70c169699e99a999da67d692727a81a6f`.

The Icarus source checkout is not embedded in `result.json`; its `source_checkout`
field is null. The published revision is recorded above and the clean build and
tool fingerprints match the [case-12 published-main evidence](../caliptra-bfm-fulltop-aes-case12-main-0d8815f-20261009/README.md).

Retained artifacts:

- [`result.json`](result.json), SHA-256
  `27fb42ba9bdd00cc8e82931eee561329313222f35051f32564fbe409ebf7b241`.
- [`compile.log.gz`](compile.log.gz), compressed SHA-256
  `6c6299efe13ccd3b436bd7b5f2a82029901627ad4134ef9ae311738edb129838`;
  uncompressed SHA-256
  `8fd0df0f4a54e76547c4aa907fa573064ebbceacf2afd0160dc7c6defdd634ea`.
- [`sim.log.gz`](sim.log.gz), compressed SHA-256
  `efdea90b5a46d102776610199389fb7cd787c5be119e98db22583cebf225e95d`;
  uncompressed SHA-256
  `6f32945e6e87ff70a803d24054470fdea63de46d1014a3c38836faf471a9b185`.
