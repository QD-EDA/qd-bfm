# Caliptra DMA DUT reset-abort profile — 2026-10-06

The focused guarded command
`run_caliptra_axi_dma_top_uvm_bfm.sh --reset-abort-only` passed. The memory
guard observed 71% free before launch and 70% minimum, against a 60% floor.
UVM warning, error, and fatal counts were all zero.

The test runs Caliptra's actual `axi_dma_top` against the open AXI target. It
holds B, waits for an accepted AW and final W beat, then confirms B is pending
and not presented before asserting reset. After reset, it checks that target
queues are empty, only the accepted first burst remains in SRAM, and no
completed write was published. It then reprograms the DMA and verifies a full
65-word transfer with two read and two write records. The successful replay
confirms the DUT and BFM recover after the reset-aborted write.

This is block-level DUT reset-abort coverage. It does not exercise the
firmware `inject_rst` request or Caliptra's full-top warm-reset service.

## Reproduction

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  ./dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh --reset-abort-only
```

Captured output: `/private/tmp/qd-bfm-dma-reset-abort-20261006-followup.log` (raw log not committed).

## Source identity

Caliptra RTL is pinned at
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.

| Input | SHA-256 |
|---|---|
| `axi_dma_top.sv` | `caf763bd878eb4d03df01d528bf30da45280ae5df986384a0554a101adf9c0b1` |
| `axi_dma_ctrl.sv` | `a7a1b7038b53505d85982bb03206b2729910ec56ef501d7326094bd976204fad` |
| `axi_mgr_wr.sv` | `8b0d4c52996f1b19bb21a53c0d9103df853dccb0ddf10708a92c489d8b0bc157` |
| `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| `dma_testcase_generator_overlay.py` | `f30a0a6f44c487b00004b3038d21652198c0d2ce0995096dba78e34733098ee6` |
| `tb_caliptra_axi_dma_top_uvm_bfm.sv` | `dabfe1233cbf040cc59544ab7f9305edffecf2d5c633ba54718a0470bc1648ba` |
| `run_caliptra_axi_dma_top_uvm_bfm.sh` | `96f6976c676a7d8ac501b4fc023d8d7244ecdacdc1d0bb8f0f1a414eb3476b2f` |
| `axi4_caliptra_dma_if_subordinate.sv` | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| Captured output | `eb4420f277f60e1776cc8a1dd89de94594cd4d9091170503f37d78e0d94486e2` |
| BFM WORK `driver/iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| BFM WORK `vvp/vvp` | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
