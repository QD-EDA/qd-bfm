> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra AXI2MBOX through the actual DMA DUT — 2026-10-06

## Result

The guarded DUT runner passed its three existing cases, a new directed
AXI2MBOX case, and all 25 generated DCCM replays. AXI2MBOX moved 65 randomized
words from SRAM to the mailbox request interface. The passive AXI monitor
recorded two source reads and no AXI writes. The bounded mailbox endpoint
stalled each request for one cycle, then checked its address, write metadata,
and payload. All 29 UVM summaries reported zero warnings, errors, and fatals.

The test follows the pinned firmware helper's AXI2MBOX route
(`rd_route=MBOX`, `wr_route=DISABLE`) and holds the mailbox lock. The mailbox
register destination uses the firmware API's local offset (`0x1210` in this
run), while the AXI source is `0x000123440308`.

The 25 generated records remain constrained to SRAM-to-SRAM AXI2AXI. This
directed case does not qualify MBOX2AXI, AHB2AXI, AXI2AHB, other AXI2MBOX
sizes/flags, firmware execution, the full Caliptra top, or the generated UVMF
environment.

## Reproduction

From the `BFM WORK` repository root:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `axi-dma-axi2mbox-and-generated-dccm-replay-20261006.log` (raw artifact omitted from this checkpoint).
The guard observed a minimum of 71% free memory against the 60% floor.

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

| Input | SHA-256 |
|---|---|
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| DMA generator overlay | `de703a6cfb00d2eea8784446c27b0a33951729e6ab0137502867e5f2d8e14b3e` |
| DUT/UVM testbench | `c7da5aa5c4cce253368ae240f4ea8f3ae58873e3bcba247b9c67bd5d9d9b2197` |
| Runner | `17289990dc93fcaf4f721b0cec82144e380fa15a37c77e63e70a454a42e443bd` |
| Icarus compiler binary | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| VVP runtime binary | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
| Captured log | `7f0663e6652e0d5bfedd0ab4db9f2dbad06f629d3a47a1757e2ed8ecba85ce5a` |
