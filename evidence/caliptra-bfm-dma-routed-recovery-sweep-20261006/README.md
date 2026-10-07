# Caliptra DMA recovery on AXI2MBOX and AXI2AHB — 2026-10-06

The guarded actual-DUT run passed FIFO recovery block sizes 4, 8, 16, 32, 64,
128, 256, 512, 1024, and 2048 bytes on both AXI2MBOX and AXI2AHB. Each of the
20 cases transferred 65 FIFO words through the pinned `axi_dma_top`; the
mailbox and component data-register paths checked all output words. Every UVM
summary reported zero warnings, errors, and fatals. The memory guard observed
68% minimum free memory against its 60% floor.

Caliptra's pinned
[`dma_transfer_randomizer.sv`](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/integration/tb/dma_transfer_randomizer.sv)
allows one-hot `test_block_size` values from 4 through 2048 bytes for AXI2MBOX
and AXI2AHB. Its 64-byte cap applies only to AXI2AXI. These route-directed
cases use the pinned randomizer for route and transfer size, then set the FIFO
source and legal block-size metadata in the testbench because Icarus cannot
solve Caliptra's `test_block_size` constraints. The BFM FIFO supplies its
random stream, which the testbench records at each FIFO push and checks at the
route output. The cases exercise the actual DMA RTL, but do not replay
generated DCCM records for these two routes or run the full firmware service.

## Reproduction

From the QD-EDA repository root:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --recovery-route-sweep-only
```

The existing AXI2AXI 4–64-byte regression also passed with zero UVM warnings,
errors, and fatals and 67% minimum free memory:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --recovery-block-sweep-only
```

Raw logs are not committed:

| Run | Captured output | SHA-256 |
|---|---|---|
| AXI2MBOX/AXI2AHB route sweep | `/private/tmp/qd-bfm-valid-recovery-route-sweep-20261006.log` | `6c3401848b80caee92d76b5e2a7ddbaada272cc77cc9d44d704136bc0136a0d1` |
| AXI2AXI regression | `/private/tmp/qd-bfm-axi2axi-recovery-regression-20261006.log` | `06c927207c32c8f6bef5e1107f1088c9e76632b75ebef723dc84a0563f2b684f` |

## Source identity

Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
QD-EDA base commit: `e52765d375a9fbe26f4a4e7f7aeacae0cf1a87a5`.
Icarus Verilog: `13.0 (devel) (246c58e4-dirty)`.

| Input | SHA-256 |
|---|---|
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Recovery route testbench | `04cb8af7d803cb46f973a101259b5994e5e4205f9bb694f6a5c50cc46acc1443` |
| Recovery sweep runner | `35e53cde7c6f7081e10cb60e2db12d15c39a4dc569e5292477bc20365c636dd0` |
| Icarus compiler | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| Icarus runtime | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
