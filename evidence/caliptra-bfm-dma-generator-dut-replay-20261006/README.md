> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra DMA generator DCCM replay through actual DUT — 2026-10-06

This evidence record describes the original AXI2AXI-only replay. The current
five-route generated replay supersedes its coverage scope; see the
[`all-route evidence`](../caliptra-bfm-dma-all-routes-20261006/README.md).

## Coverage

The actual-DUT runner executes its success, injected-error, and FIFO-recovery
cases, then runs all 25 records from Caliptra's real `dma_testcase_generator`
through `axi_dma_top`. For this replay lane, the hash-guarded overlay uses a
deterministic per-record seed and constrains each record to a supported
65-word SRAM-to-SRAM AXI2AXI transfer. It keeps generated payloads and
randomizes non-overlapping source/destination offsets; FIFO, fixed-burst,
reset, delay, and block-size modes are disabled.

The generator stages the 25 records into a bounded 39-bit DCCM shadow. For
each selected record, the bench checks ECC on the metadata and payload of all
25 records, verifies their profile, seeds the open SRAM target from the
selected payload, programs the real DMA DUT, and checks the reads, writes, and
destination contents through the passive UVM monitor and scoreboard. The
runner launches one simulation per record index and asserts a distinct pass
marker for each index.

All 25 indices passed with 25 distinct source/destination pairs. The 28 UVM
report summaries (three baseline cases plus 25 generated-record replays) each
had zero warnings, errors, or fatals. The memory guard observed 71% minimum
free memory against the configured 60% floor. Compiler output includes known
static-initialization, task-style `randomize()`, mixed-timescale, and UVM
`eval_object_select` warnings; UVM report counts remain zero. This is a
constrained block-level replay. The generator's default mixed DMA types, sizes,
FIFO/fixed-burst/reset/delay behaviors, firmware flow, full Caliptra top, and
full generated UVMF environment remain unqualified.

## Reproduction

Run from the `BFM WORK` repository root:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh
```

Captured output: `axi-dma-all-generated-dccm-replay-20261006.log` (raw artifact omitted from this checkpoint).

## Source identity

Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
Icarus compiler and runtime identify as 13.0-devel (`246c58e4-dirty`).

| Input | SHA-256 |
|---|---|
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Generated DUT replay overlay | `9bca81fad404b3deb1785ea0e2e5c73fda5d1f202e4cf59863a6a3222cb31a70` |
| Overlay generator | `de703a6cfb00d2eea8784446c27b0a33951729e6ab0137502867e5f2d8e14b3e` |
| DUT/UVM testbench | `66245696eb9807c5e93b13925f0f518db3d992be9ceb95fccd7e3da4bf2c2f45` |
| Runner | `17ab0189f831f7696b01363fccda9dcd3dba65db50a81df792b42213a6280c2d` |
| Captured all-record log | `ebd512b68f5ba3622d40c4f9c553aa34bbd8efefcbbddd161c794bc65734004d` |
