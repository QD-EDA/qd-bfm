# Generated DMA FIFO no-injected-delay sweep — 2026-10-08

**Status: diagnostic integration result; not qualification.** Four generated
65-word FIFO records passed through Caliptra `axi_dma_top` with
`inject_rand_delays=0`:

| DCCM record | Route | FIFO direction | Result |
| ---: | --- | --- | --- |
| 25 | AXI2AXI | SRAM to FIFO | Generated destination payload check passed |
| 32 | AXI2AXI | FIFO to SRAM | 65 FIFO words supplied and drained |
| 33 | AXI2MBOX | FIFO to mailbox | 65 FIFO words supplied and drained |
| 34 | AXI2AHB | FIFO to component data register | 65 FIFO words supplied and drained |

The runner checked each record's route, size, disabled delay flag, FIFO drain
where applicable, and actual-DUT pass marker. All four UVM summaries reported
zero warnings, errors, and fatals. The complete compiler and simulation output
is in [`run.log`](run.log), with trailing whitespace removed; its SHA-256 is
`8661ab43236cad6fd802c33233a5c7335cbe4167d92b20b5874ec8f6b14da735`.

## Replay

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --fifo-no-random-delays-only
```

Caliptra revision was `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Its pinned
DMA generator and randomizer SHA-256 values were, respectively,
`940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` and
`b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f`.

The QD-EDA base revision was `b02af1665ac9159eedf671943c10e33a9bffb0fc`.
The run used the existing Icarus binaries read-only:

| Artifact | SHA-256 |
|---|---|
| `driver/iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| `vvp/vvp` | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |

Source hashes for the replay implementation:

| Source | SHA-256 |
|---|---|
| `docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py` | `af92afaba84cd5622995463a586d383339885475904282017763f7fc0a632061` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_axi_dma_top_uvm_bfm.sv` | `58b988c7a4745e1fa3527da721518cdba2237b21178badfed0239a7df18584c0` |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh` | `31825ef88a1e3253c9d5fa13cbe6b936c1301f2212e53ba1c86d29bbe1323836` |

Icarus identified itself as `13.0 (devel) (ac4532fa-dirty)` from source
`ac4532fab037e91df2f903e67fb40f59baedccca`; this source revision is dirty and
unpublished, so this result is diagnostic only. A clean, published Icarus
revision is required before qualification.
