# Caliptra DMA SRAM fixed-burst modes — 2026-10-07

## Result

The pinned `axi_dma_top` passed three generated 65-word AXI2AXI SRAM replays:

| Generated record | Read burst | Write burst | Result |
| ---: | --- | --- | --- |
| 29 | FIXED | INCR | PASS |
| 30 | INCR | FIXED | PASS |
| 31 | FIXED | FIXED | PASS |

All profiles use source offset `0x1000` and destination offset `0x4000`. The
UVM monitor scoreboard checks each observed burst type and address, every data
beat, and the final SRAM locations. Fixed reads repeat the source word; fixed
writes update only the destination word selected by the repeated address.
Each run reported zero UVM warnings, errors, and fatals. The memory guard
observed 52% minimum free memory against a 40% floor.

## Replay

```sh
CALIPTRA_RTL=/path/to/caliptra-rtl \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=180 \
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --fixed-sram-modes-only
```

This selects all 32 generated DCCM records and replays records 29–31 through
the real Caliptra DMA control/register block, AXI managers, open SRAM target,
and passive UVM monitor. The test uses Caliptra v2.1.2 at
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, Icarus 13.0 development
`246c58e4-dirty`, and Accellera UVM 2020.3.1. No Caliptra source files were
modified.

## Source hashes

| Input | SHA-256 |
|---|---|
| Caliptra `axi_dma_top.sv` | `caf763bd878eb4d03df01d528bf30da45280ae5df986384a0554a101adf9c0b1` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Generator overlay | `448054cbc4481882cc440e02bba3310e678ed31fc2647dcedb13b915bad99dab` |
| DMA DUT/UVM bench | `bf2fa2ed9f6c03938325e2de4bfbdc99818c6ef3e0f9f331d3198895d77660c1` |
| Replay runner | `324052da58cd92b0cf378055a2b9c603a9b0ce2a0dde4287bf49459f7e1ac200` |
| Open DMA subordinate | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| Icarus compiler | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime | `a78ea8a8dfdaaef20402733cf26870f71b18f3fd6971655ae5e94103ebf8a749` |
