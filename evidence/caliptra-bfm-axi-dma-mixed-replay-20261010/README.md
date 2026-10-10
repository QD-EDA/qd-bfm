# Actual-DUT mixed DMA replay — 2026-10-10

The guarded `--default-mixed-replay-only` runner passed all 25 seeded records
through the pinned Caliptra `axi_dma_top` and its native UVM BFM environment.
The runner checked every record, all five DMA routes, FIFO source/destination
modes, FIXED read/write modes, randomized delay on/off, and recovery-block
profiles. Each of the 25 UVM report summaries had zero errors and fatals. The
runner's final assertion confirmed coverage of the required profile set.

This is an actual-DUT DMA-block replay, not the full `caliptra_top` firmware
suite. It does not qualify stock firmware or four-state/cross-simulator
behavior. The memory guard reported a 0.38 GiB peak process-group RSS and a
successful exit.

## Reproduction

From the QD-BFM repository root:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-install-4b3f342/bin/vvp \
sh dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --default-mixed-replay-only
```

The [complete runner output](full-mixed-run.log), source revisions, executable
hashes, and runner-input hashes are retained here. The run used clean published
Icarus main commit `4b3f3424c440aca6af92153b6860a7253b925234`, pinned Caliptra
RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, and Accellera UVM
2020.3.1.
