# Caliptra DMA mailbox FIXED modes — 2026-10-07

The guarded focused replay passed two legal route profiles through the actual
Caliptra `axi_dma_top`:

| Route | Profile and checks |
|---|---|
| AXI2MBOX | 65-word FIXED AXI reads repeatedly fetch the first SRAM word; all 65 mailbox writes retain sequential destination addresses and are checked against that data. |
| MBOX2AXI | The mailbox supplies 65 sequential words; FIXED AXI writes target one SRAM address, and the scoreboard checks burst addresses, beats, final SRAM data, and untouched neighboring words. |

Both runs reported zero UVM warnings, errors, or fatals. The memory guard
observed 60% minimum free memory against a 40% floor. This qualifies the two
directed 65-word profiles only, not generated mixed-mode records, firmware, or
the full Caliptra top.

## Reproduction

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --mailbox-fixed-modes-only
```

The runner's temporary logs and compiled image were removed on exit.

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
Icarus is 13.0-devel at revision `246c58e4580f38a130ec08e5a7e6d93f110a5084`.

| Input | SHA-256 |
|---|---|
| DUT/UVM testbench | `4018062eb41048959baa43918660d615829d49b21d8dada5c56a0c20e5e94ee8` |
| Focused runner | `dac99958980495f99ab4fccaa0c96bdbeba5dd878059b4a0b9f0085da20a5529` |
| Icarus compiler binary | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime binary | `a78ea8a8dfdaaef20402733cf26870f71b18f3fd6971655ae5e94103ebf8a749` |
