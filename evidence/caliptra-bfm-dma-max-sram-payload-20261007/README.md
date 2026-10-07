# Maximum checked SRAM payload through Caliptra DMA — 2026-10-07

## Result

The generated DUT replay selected DCCM record 24 from Caliptra's actual
`dma_testcase_generator`, with AXI2AXI and a 16,384-word (65,536-byte)
payload. The pinned `axi_dma_top` completed the transfer through the open
SRAM/FIFO target and passive UVM monitor. The scoreboard checked all 16,384
source reads and destination writes; UVM reported zero warnings, errors, and
fatals. The guarded run exited 0 with 57% minimum free memory against a 40%
floor.

The replay profile uses disjoint SRAM ranges: source offset `0x1000`,
destination offset `0x20000`, each within the 256 KiB target. This avoids
changing unread source words during the copy. An initial overlapping profile
failed at read burst 48 because earlier destination writes had changed later
source data; the overlay and bench now pin and check the disjoint ranges.
Caliptra's generator does not prohibit overlap, so overlapping-copy result
semantics remain unqualified.

## Replay

From the repository root, with the pinned Caliptra source tree and the local
Icarus build selected:

```sh
CALIPTRA_RTL=/path/to/caliptra-rtl \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=180 \
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --max-sram-dut-replay-only
```

The run compiled the real Caliptra `axi_dma_top` against the open target and
monitor using Icarus 13.0 development (`246c58e4-dirty`) and Accellera UVM
2020.3.1. Caliptra source revision:
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

The all-in-one DMA regression also exercised 40 profiles before its 300-second
guard expired while starting the final recovery record; completed runs had
zero UVM errors/fatals and 59% minimum free memory. The separate
`--recovery-route-sweep-only` run completed all 20 AXI2MBOX/AXI2AHB recovery
cases for block sizes 4 through 2048 bytes, with zero UVM warnings/errors/
fatals and 59% minimum free memory. The aggregate all-in-one script did not
finish its final summary checks.

## Source hashes

| Input | SHA-256 |
|---|---|
| Caliptra `axi_dma_top.sv` | `caf763bd878eb4d03df01d528bf30da45280ae5df986384a0554a101adf9c0b1` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Generator overlay | `120b16c163f493c5499cd52ec64ad99d47c03b479e06d1d26f46e76927f03033` |
| DMA DUT/UVM bench | `774f802e78851b4620e33828ebedf630c6e7a1a1656d4af1fae3e093f0a6457d` |
| DMA runner | `81d8f5876d2c65b54e109a5f02cce933f2668de01656c49191dd03b151a1882a` |
| Open DMA subordinate | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| Icarus compiler | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime | `a78ea8a8dfdaaef20402733cf26870f71b18f3fd6971655ae5e94103ebf8a749` |
