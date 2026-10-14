> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra DMA FIFO recovery DUT run — 2026-10-06

## Coverage

The actual Caliptra `axi_dma_top` ran a 65-word AXI FIFO-to-SRAM transfer
against the open DMA target. The directed scenario sets the pinned
`dma_transfer_randomizer` contract to AXI-to-AXI, FIFO source, fixed reads,
incrementing SRAM writes, and a 64-byte block. The packed generator input has
one nonzero entry; the recovery sequencer consumes it after `dma_gen_done`.
The open target autonomously fills its FIFO and drives threshold-mode
`recovery_data_avail` into the DUT.

The passive UVM monitor and scoreboard checked five 16-beat-or-shorter fixed
FIFO reads, five incrementing SRAM writes, AXI USER/response/LAST fields, and
payload equality from FIFO read data through the final SRAM contents. The same
runner also reran the existing randomized SRAM transfer and injected-`SLVERR`
case. All three UVM summaries reported zero warnings, errors, or fatals. The
memory guard reported 79% minimum free memory against its 60% floor.

Icarus rejected the pinned class constraints for the recovery tuple, so that
one tuple is directed from the documented class constraints. This run does
not replay the full `dma_testcase_generator` loop, DCCM firmware scenarios,
the full Caliptra top, or a generated UVMF environment.

## Reproduction

Run from the `BFM WORK` repository root:

```sh
env CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
  CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
  IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  sh ./dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

The captured output is `axi-dma-top-uvm-bfm-pass-20261006.log` (raw artifact omitted from this checkpoint).

## Input hashes

| Input | SHA-256 |
|---|---|
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv` | `a5f45a3d26e34ae040ff88a562e8b8c4974cca0fbd71325d7daf1b681c509694` |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` | `6256e1982fd830e8be38fee83c70bf6368bc6a70d09b7986495cbcf855daed44` |
| `axi-dma-top-uvm-bfm-pass-20261006.log` | `029c31db9c8cb2ef78c21fb24090cc96cf07cffa7a67b424bb7ee0c704ece311` |
| Caliptra `axi_dma_top.sv` | `caf763bd878eb4d03df01d528bf30da45280ae5df986384a0554a101adf9c0b1` |
| Caliptra `axi_dma_ctrl.sv` | `a7a1b7038b53505d85982bb03206b2729910ec56ef501d7326094bd976204fad` |
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| `driver/iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| `vvp/vvp` | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
