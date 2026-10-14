> Checkpoint copy: raw simulation output and compiled images remain in the local temporary output directory.

# Generated Caliptra FIFO recovery block-size replay — 2026-10-06

The guarded `run_caliptra_axi_dma_top_uvm_bfm.sh` run passed all eight directed
DUT cases and 27 generated DCCM records. All 35 UVM summaries had zero
warnings, errors, or fatals. The memory guard observed 74% minimum free memory
against its 60% floor.

Generated record 26 moves 65 BFM-generated FIFO words to SRAM through the real
`axi_dma_top`. Its 64-byte block-size entry travels through the generated
DCCM/block-size array to the BFM recovery sequencer. The DUT then completes
five recovery-sized read/write chunks; the UVM monitor and scoreboard verify
the transactions and data. The record's payload remains random. Because
Icarus cannot solve Caliptra's pinned `test_block_size` constraint, the
hash-guarded generator overlay sets the legal one-hot `test_block_size` and
block-size metadata after randomizing the rest of the record.

This covers one generated recovery block size. Other block-size values, reset
injection modes, default mixed profiles, and full-top firmware remain open.

## Reproduction

From `BFM WORK`:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=600 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `/private/tmp/qd-generated-recovery-profile.log`; raw output
is not committed.

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

| Input | SHA-256 |
|---|---|
| `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| `dma_testcase_generator_overlay.py` | `f30a0a6f44c487b00004b3038d21652198c0d2ce0995096dba78e34733098ee6` |
| `tb_caliptra_axi_dma_top_uvm_bfm.sv` | `1cf1334caaf2064e87921d2da9b76731768e102658811bc97fde557b563efc8b` |
| `run_caliptra_axi_dma_top_uvm_bfm.sh` | `24b7817e81b768552801a6a9df8968a3b527c2e2795dbdb15364b91e88715267` |
| Captured output | `d34e70605ee83022b882441ebac07fea910cb96fcd24d1f9d34e6ab7116b6d8c` |
