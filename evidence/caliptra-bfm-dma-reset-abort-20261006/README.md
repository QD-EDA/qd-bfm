> Checkpoint copy: the raw simulation log and generated images remain in the local temporary output.

# Caliptra DMA DUT reset-abort profile — 2026-10-06

The guarded `run_caliptra_axi_dma_top_uvm_bfm.sh` run passed nine directed
cases and 27 generated DCCM records. All 36 UVM summaries reported zero
warnings, errors, or fatals. The memory guard observed 68% minimum free memory
against its 60% floor; the command exited 0.

The `+RESET_ABORT` case ran Caliptra's actual `axi_dma_top` against the open
AXI target. It waited for the DUT's first accepted AW, asserted reset before
the next W handshake, then released reset. It verified that no write was
completed, all AXI VALID channels stayed low, the target's route/write/read
queues were empty, and all 65 destination words remained unchanged. The UVM
scoreboard published no completed write.

This is block-level DUT reset-abort coverage. It does not exercise the
firmware `inject_rst` request or Caliptra's full-top warm-reset service.

## Reproduction

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=900 \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  ./dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `/private/tmp/qd-bfm-dma-reset-run.log` (raw log not committed).

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
| `tb_caliptra_axi_dma_top_uvm_bfm.sv` | `f55557472cd5790d7b2ffb8777d404887dc6f0fed7303f2fa1b1294c49118244` |
| `run_caliptra_axi_dma_top_uvm_bfm.sh` | `fe8f9a66663a6b744ee00e193e6bd977935d0f75b672aa3f02db6905202ed878` |
| `axi4_caliptra_dma_if_subordinate.sv` | `3ef2180e298d7798c3b2caa5ac31587f623a817983075ef7556a5071f1f5b029` |
| Captured output | `aff240390903dfb138c42d03e58d7afacd6faccbc653fbfbfa8557c41140ef5b` |
| BFM WORK `driver/iverilog` | `235804ad26d84eaa3ab043f201e38e63643ddcf1e4fb0671f43b705199566392` |
| BFM WORK `vvp/vvp` | `ca8b19d01187c9bc30387becba5d81b4cc7241c3a708b8c32ccf37aef663e574` |
