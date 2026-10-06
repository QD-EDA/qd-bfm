> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Open Caliptra AXI complex top smoke — 2026-10-06

**Status: diagnostic integration evidence, not a qualification pass.** The
full pinned `caliptra_top_tb` compiles with the open `caliptra_top_tb_axi_complex`
replacement. `smoke_test_veer` then reaches its pass marker and normal finish:
1,033 retired instructions, 7,355 cycles, and 1,034 trace records. The firmware
and DCCM image hashes match the frozen L0 runner inputs. No SVA, simulation
error, or fatal markers were emitted.

The run has two JTAG DPI socket bind errors because this sandbox denies socket
creation, including with the existing port-0 overlay. The L0 runner treats
those errors as a failure, so this is not counted as a qualified L0 pass. The
test also issues no DMA traffic; the AXI target behavior remains covered by
the separate block-level DMA/DUT evidence.

The integration uncovered and fixed an open-BFM control bug: Caliptra
initializes `dma_gen_block_size` only when `+CPTRA_RAND_TEST_DMA` is supplied.
The replacement now enables its generated recovery sequence only with that
same plusarg. Without it, an X block-size array is ignored as intended. The
focused test first failed on the X array, then passed after the fix.

The compile used `driver/iverilog` with `-g2017 -gassertions
-gcommercial-unsafe`, the open AXI complex module, and a temporary
Icarus-compatible SRAM-export copy. Runtime used hash-guarded temporary
reset, checker, numeric-`$fatal`, and JTAG-port overlays; no pinned Caliptra
file was changed. Guard results stayed above the 60% free-memory floor:
79% minimum during compile and 77% during simulation. The simulation had a
900-second bound and finished before it.

Files:

- [`result.json`](result.json) — commands’ qualification limits, hashes, and
  guard/finish metrics.
- `strict-diagnostic-compile.log` (raw artifact omitted from this checkpoint)
- `sim-diagnostic.log` (raw artifact omitted from this checkpoint)

The remaining top-level step is a firmware DMA scenario that supplies
`+CPTRA_RAND_TEST_DMA` and exercises the open AXI target through the actual
Caliptra top. It needs a JTAG-capable runner environment to satisfy the current
L0 result gate.
