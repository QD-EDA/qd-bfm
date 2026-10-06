> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra DMA route and size profiles through the actual DUT — 2026-10-06

## Result

The guarded run passed eight directed DUT cases and all 25 generated DCCM
replays. All 33 UVM reports had zero warnings, errors, or fatals. The generated
records covered AHB2AXI (2), MBOX2AXI (6), AXI2AXI (5), AXI2MBOX (5), and
AXI2AHB (7). The eight short sizes (1, 4, 5, 16, 64, 65, 255, and 256 words)
each appeared three times. Record 0 moved 65,536 auto-generated FIFO words
through 4,096 fixed 16-beat reads into 1,024 64-beat SRAM writes; the FIFO
drained and every destination word matched the captured source stream.
Caliptra's randomized delay flag remained intact; record 2 applied delays and
observed five target-stall cycles. The separate SRAM-to-FIFO case observed 160
active-target stall cycles. The memory guard measured 80% minimum free memory
against its 60% floor (80% at preflight).

| Route | Directed profile |
|---|---|
| AHB2AXI | 65 randomized words enter through the component `WRITE_DATA` register (`0x02c`); AXI scoreboard checks both writes and the SRAM target checks every word. |
| MBOX2AXI | 65 randomized mailbox words are returned with one-cycle mailbox backpressure; the AXI monitor checks two writes and the SRAM target/scoreboard check the payload. |
| AXI2AXI | 65 randomized SRAM words; the UVM monitor checks two reads and two writes. Five generated DCCM records also exercised this route. |
| AXI2AXI, maximum FIFO source | 65,536 BFM-generated FIFO words move through 4,096 fixed reads into 1,024 SRAM writes; the scoreboard compares every destination word and checks that the FIFO drains. |
| AXI2AXI, FIFO destination | 65 SRAM words are sent in five fixed write bursts under weighted random channel stalls; the monitor checks AXI records, and the FIFO endpoint checks depth and every queued word. |
| AXI2MBOX | 65 randomized SRAM words are written to mailbox offsets with one-cycle request backpressure and per-request address, metadata, and data checks. |
| AXI2AHB | 65 randomized SRAM words are read through the component `READ_DATA` register (`0x030`); the test polls FIFO depth and checks every word. |

The component input/output lanes use the DMA's register-side `soc_ifc_req_t`
interface; they do not instantiate an AHB bus. This run's generated replay
covers the five named route types, the eight short sizes, and the 65,536-word
maximum FIFO-source/SRAM-destination stream. A later generated FIFO-destination
follow-up adds a 65-word fixed-write SRAM-to-FIFO record with 160 observed stall
cycles; see the [follow-up evidence](../caliptra-bfm-dma-generated-fifo-destination-20261006/README.md).
Other generated FIFO, reset, and block-size modes remain constrained off.
Other generated sizes/flags, firmware, the full Caliptra top, and the generated
UVMF environment remain unqualified. The mailbox model is bounded to these DUT
tests rather than implementing the full mailbox SRAM.

## Reproduction

From the `BFM WORK` repository root:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `axi-dma-max-65536-fifo-stream-20261006.log` (raw artifact omitted from this checkpoint). It includes the guard result: exit 0, 80% minimum free memory, 60% floor.

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

| Input | SHA-256 |
|---|---|
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Generated DMA overlay | `0fe9b59dfe1e396e5bc95c2108ebeaeeef1fe144ae0e025dcf8781580b606a69` |
| DMA overlay helper | `5d4b6035edbce5377cadfbd67972d6f55f222280063fc28bc15180705f6ecfb8` |
| Weighted AXI stall model | `6c828f9112d2895ea9f67d2132c157545bd2ac22a49acd2ad7736dd4b24f1924` |
| DUT/UVM testbench | `a4926b5b1866a39fa05f32bcde7a6602367283fd1882d136cf13b8b28f3ca38e` |
| Runner | `ace4ec7c9fdc9a7e8cb2b874b3392acd302b317971d31ed79a33eb710ea07450` |
| Icarus compiler binary | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime binary | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
| Captured log | `fa5a1057637d403ddd9d8fbadfbc10d390ff37c46d9ed25ea3c7bfc1ca6fcbd1` |
