# Caliptra generated SRAM-to-FIFO size sweep

Generated AXI2AXI SRAM-to-FIFO profiles completed through the pinned Caliptra
`axi_dma_top` at eight payload sizes. Each run checked the generated DCCM
metadata and payload ECC, UVM read/write transactions, FIFO occupancy and every
queued payload word, and nonzero randomized target backpressure. UVM warning,
error, and fatal counts were zero in all eight runs.

| FIFO words | Randomized target stall cycles |
|---:|---:|
| 1 | 51 |
| 4 | 42 |
| 5 | 39 |
| 16 | 38 |
| 64 | 145 |
| 65 | 159 |
| 255 | 996 |
| 256 | 997 |

Run from the QD-EDA `qd-bfm` checkout:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=240 \
dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --fifo-destination-size-sweep-only
```

The memory guard reported a minimum of 47% free memory against the 40% floor.
The runner selected generated record indices 59–66 from a 67-record profile
and ran against Caliptra RTL revision
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the QD-EDA starting revision was
`607c320ba02d82ef5085dd87dad2df7acb00f981`.

Icarus was read from the separate `BFM WORK` checkout:

| Tool | SHA-256 |
|---|---|
| `driver/iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| `vvp/vvp` | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |

Source SHA-256 values for this run:

| Source | SHA-256 |
|---|---|
| `docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py` | `23f5ee39f42ceeabd9c90ea9ef3b1877b03b03b38aef450bd41d8cea1ab8dbcc` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv` | `a07f28783a9e6f6c7760a2e8e22be52096339e0a332ac3aeaaa0ffbcdc1bf214` |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` | `1d01caefe894793246f6b982eba12daa97506be5b7c320646055b4230f76cbbf` |

The Icarus compile logged its existing static-initialization, timescale, and
`eval_object_select` warnings. These are compiler diagnostics; the runtime UVM
summaries reported zero warnings, errors, and fatals for every selected case.
