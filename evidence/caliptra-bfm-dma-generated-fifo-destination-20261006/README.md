> Checkpoint copy: raw simulation output and compiled images remain in the local temporary output directory.

# Generated Caliptra SRAM-to-FIFO replay — 2026-10-06

The guarded `run_caliptra_axi_dma_top_uvm_bfm.sh` run passed all eight existing
directed DUT cases and 26 generated DCCM records. All 34 UVM summaries had zero
warnings, errors, or fatals. The memory guard observed 74% minimum free memory
against its 60% floor.

Generated record 25 exercised a 65-word AXI2AXI copy from SRAM to the FIFO
endpoint. Caliptra's generator marked the destination as FIFO, selected fixed
write bursts, and enabled randomized delays. The AXI monitor and scoreboard
checked the transfer; the FIFO endpoint contained all 65 expected words, and
the BFM observed 160 target-stall cycles. This is block-level DUT evidence; it
does not qualify the full Caliptra top or untested reset/block-size profiles.

The Icarus inline-constraint profile for this tuple did not randomize when
expressed with the generic conditional implications. The overlay uses an
equivalent direct constraint block for this one record; the pinned randomizer
and RTL are unchanged.

## Reproduction

From `BFM WORK`:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=600 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `/private/tmp/qd-generated-fifo-destination.log`; raw output
is not committed.

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

| Input | SHA-256 |
|---|---|
| `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| `dma_testcase_generator_overlay.py` | `c9ee104af525cf2f5ed157e2a3a6bf750cdc546c0e1bf26bdb3155aeb173420a` |
| `tb_caliptra_axi_dma_top_uvm_bfm.sv` | `76e02ea2b26c0fe698b3f817f17dadf6915ef24452246c3ee949e4dee88ab860` |
| `run_caliptra_axi_dma_top_uvm_bfm.sh` | `3ea9500519a42db5b3ca51c96abfa6d3fb3325171bd489c6faeea1c3a61b3b35` |
| Captured output | `aa569923adf93ff5c4c1dcb6282ef8613ec76be5c44cf2d9e20914f7b0bc1cba` |
