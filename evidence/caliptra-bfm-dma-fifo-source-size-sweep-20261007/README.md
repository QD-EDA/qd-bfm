# Caliptra generated FIFO-source size sweep

The generated AXI2AXI, AXI2MBOX, and AXI2AHB FIFO-source profiles below
completed through the pinned Caliptra `axi_dma_top`. Each run checked the FIFO
word count and drain, route destination payload, and randomized target stalls.
UVM warning, error, and fatal counts were zero in all 24 runs.

| FIFO words | AXI2AXI stalls | AXI2MBOX stalls | AXI2AHB stalls |
|---:|---:|---:|---:|
| 1 | 2 | 1 | 1 |
| 4 | 13 | 3 | 3 |
| 5 | 13 | 5 | 5 |
| 16 | 24 | 14 | 14 |
| 64 | 186 | 108 | 108 |
| 65 | 209 | 128 | 128 |
| 255 | 1,239 | 887 | 887 |
| 256 | 1,241 | 887 | 887 |

Run from the QD-EDA `qd-bfm` checkout:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=240 \
dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --fifo-source-size-sweep-only
```

The memory guard reported a minimum of 62% free memory against the 40% floor.
The test uses deterministic generated record indices 35–58 in a 59-record
profile and ran against Caliptra RTL revision
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the QD-EDA starting revision was
`0ac50752fee563b48960fe6b9bc06aeb7657ab4e`.

The Icarus tools were read from the separate `BFM WORK` checkout:

| Tool | SHA-256 |
|---|---|
| `driver/iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| `vvp/vvp` | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |

Source SHA-256 values for this run:

| Source | SHA-256 |
|---|---|
| `docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py` | `aad732d5c7e0d0ce12571ca22750d102177ed0bda5455239bc940ba2bd85e469` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv` | `085c8905a1b7b59cb77da22749fad252a28d6fa47885fbfda4fc327344732089` |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` | `be99447429724f2acb54675145dd3bb892b498d0a9085adc67ad5afd29dd7318` |
