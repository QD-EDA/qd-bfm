# Caliptra full-top AES/DMA cases 1–12 on published Icarus main — 2026-10-09

## Result

This is an incomplete diagnostic run, not a qualification pass. The guarded
full-top runner compiled the pinned Caliptra top and firmware, then stopped at
its 1,800-second time limit before a testcase pass/fail marker or normal
simulation finish. The final VPI snapshot was cycle 5,900 / 2,328 retired
instructions. The native AXI checker was enabled; the trace showed three
write address/response transactions, four W beats, and two read transactions.
No checker/SVA error marker was present in the retained simulation log.

The earlier single-vector case-12 pass remains valid as a separate diagnostic;
this batch timeout does not replace or invalidate it. The 12-case batch gate
remains open.

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
  --limit-aes-cases 12 --start-aes-case 0 --fast-trng --trace-axi \
  --output /private/tmp/qd-bfm-fulltop-aes-cases1-12-0d8815f-20261009
```

## Provenance

- Caliptra: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- QD BFM branch at launch: `012909e45b76a16a3ee333ce71e77bc6f81ae3c7`.
- Icarus `main`: live remote-head SHA `0d8815febc260928e62d5c2ce82b14afd2e38dc3`.
- `iverilog` SHA-256: `603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a`.
- `vvp` SHA-256: `07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c`.
- `iverilog-vpi` SHA-256: `1e393171c4272f92db03541c9c483afb4b9211e01a1476ab01d4890f0e949d83`.
- Full-top BFM wrapper SHA-256: `2a5b59b60371e1508305014fdabcbb217b47e3978c2f84c12ed545ae1c85d400`.
- Firmware-case runner SHA-256: `ec326729e62cc20c179d8608cb2b18ffcd9c907176b560393e83306a007d5b77`.
- Compiled simulation image SHA-256: `5d37354e019781932e14ecd8b8db00d1c3663899421fb9af4e262894c2ee20be`.
- `compile.log` SHA-256: `62c32c8d3dc75928834b30e92cad0001c62940f8e4d37499d5aa782de406cbe4`; compressed artifact SHA-256 is in `result.json`.
- `sim.log` SHA-256: `851660dc3dd1a6fe17fffe16f0bc408fead698c45a0649be0f7c14976b22b31c`; compressed artifact SHA-256 is in `result.json`.

The compact compile and simulation logs are retained as `compile.log.gz` and
`sim.log.gz`. The large generated simulator image and firmware build products
were removed after collecting the hashes and logs.
