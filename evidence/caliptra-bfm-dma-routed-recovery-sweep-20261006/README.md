# Caliptra DMA recovery on AXI2MBOX and AXI2AHB — 2026-10-06

The guarded actual-DUT run passed FIFO recovery block sizes 4, 8, 16, 32, 64,
128, 256, 512, 1024, and 2048 bytes on both AXI2MBOX and AXI2AHB. Each of the
20 cases selected generated DCCM record 27 or 28, transferred 65 FIFO words
through the pinned `axi_dma_top`, and checked every mailbox or component
data-register output word. Every UVM summary reported zero warnings, errors,
and fatals. The memory guard observed 68% minimum free memory against its 60%
floor.

Caliptra's pinned
[`dma_transfer_randomizer.sv`](https://github.com/chipsalliance/caliptra-rtl/blob/49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e/src/integration/tb/dma_transfer_randomizer.sv)
allows one-hot `test_block_size` values from 4 through 2048 bytes for AXI2MBOX
and AXI2AHB. Its 64-byte cap applies only to AXI2AXI. The hash-guarded
generator overlay constructs legal records 27 and 28 after randomizing their
route profiles, then sets `test_block_size` and a 128-byte base block because
Icarus cannot solve that pinned class-constraint tuple. Each run replays the
selected ECC-checked DCCM record and overrides its block-size array entry for
the sweep. The BFM FIFO supplies its random stream, which the testbench records
at each FIFO push and checks at the route output. This qualifies the generated
route records through the actual DMA RTL; it does not run the full firmware
service.

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

The generated AXI2AXI record 26 4–64-byte regression also passed with zero UVM
warnings, errors, and fatals and 68% minimum free memory:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --recovery-block-sweep-only
```

The normal guarded runner also passed all 29 generated records and nine
directed setup profiles: 42 UVM reports, all with zero warnings, errors, and
fatals. Its minimum free memory was 60%, the configured floor. Raw logs are
not committed:

| Run | Captured output | SHA-256 |
|---|---|---|
| AXI2MBOX/AXI2AHB generated-record sweep | `/private/tmp/qd-bfm-generated-routed-recovery-sweep-20261006.log` | `a7f20544660c90615a96f8d4e3bc850962d2b5b48b781572e5b4bee89531d648` |
| AXI2AXI generated-record regression | `/private/tmp/qd-bfm-generated-axi2axi-recovery-regression-20261006.log` | `78931441da1de2e3643cf4fe127ad4870a0408714b1c97e448b13d3c47385b99` |
| Full guarded runner | `/private/tmp/qd-bfm-full-caliptra-dma-29-records-20261006.log` | `dd76c778da73fdc7c13d9d9cd0856e37311f923a7e089a4ccc680faee70ad09a` |

## Source identity

Caliptra RTL commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
QD-EDA base commit: `f03f5e83664a947f967a7edb39271e77fea855e9`.
Icarus Verilog: `13.0 (devel) (246c58e4-dirty)`.

| Input | SHA-256 |
|---|---|
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| DMA generator overlay | `f66b7e4ed96d67fd570bd454e095034d38f1e43896bcb32538653fac1c04e997` |
| Recovery route testbench | `f0ad3e94115f49fbce4ac441dac471be088a287df76ffb711079e5b84b307f73` |
| Recovery sweep runner | `66779fb00f21aa6ef7dc240bc95a062e1992b729c43c59b33a0b77eb31148445` |
| Icarus compiler | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| Icarus runtime | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
