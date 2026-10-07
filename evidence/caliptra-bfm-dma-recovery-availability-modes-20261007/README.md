# Caliptra DMA recovery availability modes — 2026-10-07

## Result

The generated AXI2AXI FIFO-recovery DCCM record 26 completed 65 words through
the pinned Caliptra `axi_dma_top` in each open target availability policy:

| Policy | Selected mode ID | Result |
|---|---:|---|
| Not empty | 1 | PASS |
| Threshold | 2 | PASS |
| Pulse | 3 | PASS |

The testbench asserts the selected mode before running the DMA transfer. The
pass condition also requires the real DUT to complete the recovery copy and
the UVM monitor scoreboard to account for all read/write bursts and payload
words. Each simulation reported zero UVM warnings, errors, and fatals. The
memory guard observed 59% minimum free memory against a 40% floor.

## Replay

```sh
CALIPTRA_RTL=/path/to/caliptra-rtl \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=180 \
IVERILOG_BIN=/path/to/iverilog VVP_BIN=/path/to/vvp \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --recovery-availability-modes-only
```

The runner compiles the real `axi_dma_top`, the pinned Caliptra testcase
generator, the open SRAM/FIFO target, and passive UVM monitor. It selects
generated record 26 with a 64-byte AXI2AXI recovery block and reruns that record
with each policy plusarg. Caliptra v2.1.2 revision:
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. No Caliptra source files were
modified. Temporary simulation logs and binaries were removed by the runner.

## Source hashes

| Input | SHA-256 |
|---|---|
| Caliptra `axi_dma_top.sv` | `caf763bd878eb4d03df01d528bf30da45280ae5df986384a0554a101adf9c0b1` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Generator overlay | `448054cbc4481882cc440e02bba3310e678ed31fc2647dcedb13b915bad99dab` |
| Recovery availability model | `ca4a3dadfc06c550722f489a40832fbfd6a8364cdcecb3816e363fc130476c8b` |
| DMA subordinate | `71aedfb9de92064a6d63f4523ab0620ebcc55b84ee4b2955c04a54ab75c8c3a8` |
| FIFO subordinate | `49416a58859e4664be14850e9f118191194d480a43d6459cc9842ceb7087fbf3` |
| DMA DUT/UVM bench | `aabd48e317e22cc4edcb8e4807bfd832f2a58004f01da8e8ccf612b3ff4c2ac0` |
| Replay runner | `bd3caa1c4977fc27aea6c0a0afc9dc4f649c37f1aaccf90b56b042b385816fc4` |
| Icarus compiler | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime | `a78ea8a8dfdaaef20402733cf26870f71b18f3fd6971655ae5e94103ebf8a749` |
