# Generated FIFO-source reset-abort replay — 2026-10-09

**Status: diagnostic integration result; not qualification.** Caliptra's
generated reset record 67 was constrained to a legal 65-word fixed-read
AXI2AXI FIFO-source profile. The open target held the first SRAM write response
before B; the test reset the DMA, checked that it discarded the in-flight
transaction and target queues, then reprogrammed it and completed the full
transfer. The post-reset check verifies the destination payload, exactly 65
FIFO pushes and pops, and an empty FIFO.

The generated FIFO-source reset case and the existing SRAM-source reset case
both passed with zero UVM warnings, errors, or fatals. Logs are retained at
[`fifo-source-reset.log`](fifo-source-reset.log) and
[`sram-reset-regression.log`](sram-reset-regression.log); trailing whitespace
was removed from each log. Their SHA-256 values are:

| Log | SHA-256 |
|---|---|
| `fifo-source-reset.log` | `b9990aa2c23db14300572dc171423ad396df3006ed8bd74a638df3c071a3e583` |
| `sram-reset-regression.log` | `14e67c78d14f72e92551e69695dc67013b7d0988a9398399866d8e38f7fa49e0` |

## Replay

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --generated-fifo-source-reset-abort-only
```

The SRAM-source regression used the same command with
`--generated-reset-abort-only`. Caliptra revision was
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; the DMA generator and randomizer
SHA-256 values were `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447`
and `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f`.
The QD-EDA base revision was
`297f5c25c4d5e31aed5a62c4cc82c3722e27112c`.

The existing Icarus binaries were read-only:

| Artifact | SHA-256 |
|---|---|
| `driver/iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| `vvp/vvp` | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |

Icarus identified itself as `13.0 (devel) (ac4532fa-dirty)` from source
`ac4532fab037e91df2f903e67fb40f59baedccca`. The source revision is dirty and
unpublished, so both results are diagnostic only. Re-run on a clean, published
Icarus revision before qualification.

Source hashes for the implementation under test:

| Source | SHA-256 |
|---|---|
| `docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py` | `34baac88fd62405b800f3f5e2ee00399a2b6b32f98ce168fe6b4d873e6a4c2be` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv` | `c37cc6439091575cd8b4db9416754f3efcfb8dbf25b893938b0d60b421b49a3a` |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` | `de2a0710d264d0a3c58435e81dac78aab9d073e4fd09754668c0c3e1ed69a2d5` |
