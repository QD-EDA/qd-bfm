> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra DMA route profiles through the actual DUT — 2026-10-06

## Result

The guarded DUT runner passed its three existing cases, three directed route
profiles, and all 25 generated DCCM replays. All 31 UVM report summaries had
zero warnings, errors, or fatals. The memory guard observed a 69% minimum free
memory against the 60% floor.

| Route | Transfer and checks |
|---|---|
| AXI2AXI | Existing SRAM copy/error cases and the 25 generated DCCM records under the constrained 65-word SRAM-to-SRAM profile. |
| AXI2MBOX | 65 randomized SRAM words to a local mailbox offset. The mailbox model stalls each request for one cycle, checks address/metadata/data, and stores the words. UVM sees two AXI reads and no AXI writes. |
| MBOX2AXI | 65 randomized mailbox words to SRAM. The mailbox model stalls each request for one cycle and checks its local read address/data. UVM sees two AXI writes and no AXI reads; the SRAM target and scoreboard check the result. |
| AHB2AXI | 65 randomized words enter through the component `WRITE_DATA` register (`0x02c`). UVM checks the two AXI writes and the SRAM target checks the complete payload. |

The component interface is driven through `soc_ifc_req_t`; this run does not
instantiate an AHB bus or manager. It also does not qualify AXI2AHB, the
generator's default mixed modes, other sizes or fixed/FIFO/reset/delay
combinations, firmware execution, the full Caliptra top, or the generated UVMF
environment. The mailbox model is bounded to this 65-word profile rather than
implementing the full mailbox SRAM.

## Reproduction

From the `BFM WORK` repository root:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `axi-dma-route-profiles-and-generated-dccm-replay-20261006.log` (raw artifact omitted from this checkpoint).

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

| Input | SHA-256 |
|---|---|
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| DMA generator overlay | `de703a6cfb00d2eea8784446c27b0a33951729e6ab0137502867e5f2d8e14b3e` |
| DUT/UVM testbench | `df477caae7de75fdfc3df9628b5b3c78100e57ceb86c39aefdcf13b98150dbd6` |
| Runner | `39a93c3efe13715dd9eac5e071cd9c657ece94873e77304e1f57f6bce9d2b3bb` |
| Icarus compiler binary | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime binary | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
| Captured log | `d90d9df9b6e81c2c7babdc50252b43023c46b6fb746db392613bce6c120291cc` |
