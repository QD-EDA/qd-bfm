# Generated Caliptra recovery block-size sweep — 2026-10-06

The focused, guarded Icarus run passed generated DCCM testcase 26 through the
actual Caliptra `axi_dma_top` for 4-, 8-, 16-, 32-, and 64-byte recovery
blocks. Each case moved 65 FIFO words to SRAM; the UVM monitor and scoreboard
reported zero warnings, errors, or fatals in all five runs. The memory guard
measured 64% minimum free memory against its 60% floor.

The test selects the actual generated DCCM record, then uses the testbench's
`+RECOVERY_BLOCK_BYTES` diagnostic override for the size under test. The
original Caliptra sources and generated DCCM image remain unchanged. This
qualifies single-request block sizes through 64 bytes at Caliptra's 32-bit AXI
width. Larger multi-request blocks, other generated FIFO modes, firmware reset
injection, and full-top firmware remain unqualified.

## Reproduction

From the QD-EDA repository root:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --recovery-block-sweep-only
```

The runner applies the repository's 60%-free-memory guard. Captured output is
at `/private/tmp/qd-bfm-recovery-block-sweep.log` (SHA-256
`aab18c426d4e119cfeefbfd8e28f1dfd69bf45da9df15abacfafa61267cf7b85`); raw
output is not committed.

## Source identity

Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
QD-EDA base commit: `2676f50b73ef28d97ade55bd0da54d0a6470969d`.
Icarus Verilog: `13.0 (devel) (246c58e4-dirty)`.

| Input | SHA-256 |
|---|---|
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Icarus generator overlay | `f30a0a6f44c487b00004b3038d21652198c0d2ce0995096dba78e34733098ee6` |
| Recovery sweep testbench | `d065edf88bfcad97e06bef71c01b95d67d6a96f103a659ebf92cd87564f0434f` |
| Recovery sweep runner | `f47c16530138053127e8b42bc42b270ee03bec0d90d9bfa61c94d483ac4886a9` |
| Icarus compiler | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| Icarus runtime | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
