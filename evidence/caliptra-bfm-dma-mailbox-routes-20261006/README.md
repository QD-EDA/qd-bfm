> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra DMA mailbox routes through the actual DUT — 2026-10-06

## Result

The guarded DUT runner passed its three existing cases, both directed mailbox
routes, and all 25 generated DCCM replays. All 30 UVM report summaries had
zero warnings, errors, or fatals. The memory guard observed a 66% minimum free
memory against the 60% floor.

| Route | Transfer and checks |
|---|---|
| AXI2MBOX | 65 randomized SRAM words to a local mailbox offset. The endpoint stalls each request for one cycle, checks address/write metadata/data, and stores the words. UVM records two AXI reads and no AXI writes. |
| MBOX2AXI | 65 randomized words from the bounded mailbox model to SRAM. The endpoint stalls each request for one cycle and checks mailbox read addresses/data. UVM records two AXI writes and no AXI reads; the SRAM target and scoreboard check the result. |
| Generated DCCM replay | All 25 records still use the constrained 65-word SRAM-to-SRAM AXI2AXI profile with ECC checks and per-record randomized payloads/offsets. |

This does not qualify the generator's default mixed transfer modes, AHB2AXI,
AXI2AHB, FIFO/fixed/reset/delay combinations outside the existing directed
recovery lane, firmware, the full Caliptra top, or the generated UVMF
environment. The mailbox model is a bounded 65-word endpoint for these DUT
cases, not a full mailbox SRAM replacement.

## Reproduction

From the `BFM WORK` repository root:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `axi-dma-mailbox-routes-and-generated-dccm-replay-20261006.log` (raw artifact omitted from this checkpoint).

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

| Input | SHA-256 |
|---|---|
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| DMA generator overlay | `de703a6cfb00d2eea8784446c27b0a33951729e6ab0137502867e5f2d8e14b3e` |
| DUT/UVM testbench | `a0002384da472522d5d5b8da778ff3496c5cb722bb04cfb3708d23559b7e28ba` |
| Runner | `1ee772311fefa5cd0cb02f5683e012df5de8137f2762d4641f6c22ed7db53647` |
| Icarus compiler binary | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime binary | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
| Captured log | `df66af18010a0a055a4defba4dfed77e013ccfe13ca59de801ae8cfd7cfedf83` |
