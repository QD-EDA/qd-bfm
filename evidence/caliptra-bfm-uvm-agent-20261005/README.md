> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra AXI UVM agent regression — 2026-10-05

## Scope and result

The guarded native UVM agent regression completed AXI burst write/readback,
RAL accesses, injected `SLVERR`, successful and invalidated exclusive
sequences, and the AAXI compatibility path. Both native and projected monitor
streams saw `EXOKAY` for successful exclusives, and `OKAY` plus preserved
memory contents for the invalidated store. It exited 0 with zero UVM errors
and fatals. The report had two `PREDICT_NOK` warnings from injected-error
reads.

The ordinary two-beat burst remains non-exclusive. An earlier version set
`AWLOCK` on that write without a matching exclusive read; the target correctly
returned `OKAY` and left memory unchanged. The regression now tests normal
burst readback, a successful single-beat exclusive pair, and a failed store
after reservation invalidation. Standalone AXI target regressions also cover
failed exclusive writes and multi-beat locks.

## Reproduction

Run from the BFM worktree root:

```sh
IVERILOG_BIN=./driver/iverilog VVP_BIN=./vvp/vvp \
  ./dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh
```

The runner's memory guard has a 70% free-memory floor and observed 75% minimum.
The run printed:

```text
PASS: UVM AXI agent and AAXI compatibility stream completed burst read/write and propagated SLVERR
UVM_WARNING : 2
UVM_ERROR   : 0
UVM_FATAL   : 0
```

An earlier combined DMA-map attempt stopped at its 70% floor before producing
a test result. The retry used a 50% free-memory floor and 10-minute timeout;
it passed the SRAM/FIFO and failed-exclusive cases with zero UVM errors/fatals
and a 66% minimum free-memory observation. Reproduce it with:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=50 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=600 \
IVERILOG_BIN=./driver/iverilog VVP_BIN=./vvp/vvp \
  ./dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh
```

Simulator: Icarus Verilog/VVP 13.0 devel, build `246c58e4-dirty`; bundled
Accellera UVM 2020.3.1.

## Source hashes

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh` | `0ba543869fec10a29076ecaa0e654fe9ccc014b79ac0e3db3ca416af456c76ef` |
| `dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh` | `5cc94602de18b1707d2f7f7d3d383d90ae8f8a95d4b04d1ad987c0474b404266` |
| `dv/caliptra_bfm/uvm/tests/tb_axi4_caliptra_uvm_agent.sv` | `82201be2acd8697bfac19f18de5733ba5fea4d279114ffbb91f5a2c245b073d1` |
| `dv/caliptra_bfm/uvm/axi4_caliptra_uvm_pkg.sv` | `f589cb4395892a575a47fcdf1feecd718ac1202d92ba9151af8ecc39a609076d` |
| `dv/caliptra_bfm/uvm/caliptra_aaxi_compat_pkg.sv` | `8e7da67e9a586912f5e6af630bafd8997dbd8090df19181fc5d2affa2a5cc5ff` |
| `dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv` | `9c5abea1072e99510b3aefb61d4c4c796685aeaec46314fb1bc7101144156e54` |
