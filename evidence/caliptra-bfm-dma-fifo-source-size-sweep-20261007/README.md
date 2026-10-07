# Caliptra generated FIFO-source size sweep

The generated AXI2AXI FIFO-source profiles below completed through the pinned
Caliptra `axi_dma_top`. Each run checked the FIFO word count and drain, the
destination SRAM payload, and observed randomized target stalls. UVM warning,
error, and fatal counts were zero in all eight runs.

| FIFO words | Observed target stall cycles |
|---:|---:|
| 1 | 2 |
| 4 | 13 |
| 5 | 13 |
| 16 | 24 |
| 64 | 186 |
| 65 | 209 |
| 255 | 1,239 |
| 256 | 1,241 |

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
The test uses deterministic generated record indices 35–42 and ran against
Caliptra RTL revision
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the QD-EDA starting revision was
`089ffac5f29abb4d9089a2fd99fa8850620b890b`.

The Icarus tools were read from the separate `BFM WORK` checkout:

| Tool | SHA-256 |
|---|---|
| `driver/iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| `vvp/vvp` | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |

Source SHA-256 values for this run:

| Source | SHA-256 |
|---|---|
| `docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py` | `af8d0ba3e3563a834b27f921b1dc61beb0209db393a560b8260b2fc65e5bc0b9` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv` | `55b3b02a94d5264f7eecfec30bf9bee06718816cf73be257c6c5b33d7ac08621` |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` | `093172b2c6185189c82ddaff331efc936c15a649fa3e3721d7a5e7970623b30f` |
