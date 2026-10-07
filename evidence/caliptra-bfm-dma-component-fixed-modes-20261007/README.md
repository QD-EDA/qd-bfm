# Caliptra DMA component-route FIXED modes — 2026-10-07

The guarded focused replay passed two legal profiles through the actual
Caliptra `axi_dma_top`:

| Route | Profile and checks |
|---|---|
| AXI2AHB | 65 FIXED-address AXI reads repeatedly fetch the first SRAM word; the component data path returns and checks all 65 words. |
| AHB2AXI | 65 component-register words are written through FIXED AXI bursts; the scoreboard checks beats and repeated destination address, then verifies the final SRAM word and untouched neighbors. |

Both runs reported zero UVM warnings, errors, or fatals. The memory guard
observed 61% minimum free memory against a 40% floor. This qualifies these two
directed 65-word profiles through the component-register path; it does not
exercise an AHB bus or the full Caliptra top.

## Reproduction

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --component-fixed-modes-only
```

The runner's temporary logs and compiled image were removed on exit.

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
Icarus is 13.0-devel at revision `246c58e4580f38a130ec08e5a7e6d93f110a5084`.

| Input | SHA-256 |
|---|---|
| DUT/UVM testbench | `1d5c4e175c2da137ea745f43164f6360a0292001c9bebd3b0f41586d46c9a560` |
| Focused runner | `5fcba4bb5581c653303f652e6d815189078f9bd5ef6a2fe923820a1cb3d4b0c7` |
| Icarus compiler binary | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime binary | `a78ea8a8dfdaaef20402733cf26870f71b18f3fd6971655ae5e94103ebf8a749` |
