> Checkpoint copy: concise reports and JSON summaries are preserved here; raw simulation logs and generated binaries are kept out of this feature branch.

# Caliptra DMA testcase generator to recovery sequence — 2026-10-06

This artifact records the default generator-to-recovery-sequencer run. The
newer generated-DUT replay spans all five route types under a bounded 65-word
profile; see the [all-route evidence](../caliptra-bfm-dma-all-routes-20261006/README.md).

## Coverage

The runner instantiates Caliptra's real `dma_testcase_generator` and
`dma_transfer_randomizer` at Caliptra v2.1.2 (`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`).
It runs the default 25 random DMA iterations, stores every `slam_dccm_ram`
write into a bounded 39-bit DCCM shadow, parses all 25 records, checks ECC on
every metadata/payload word, reconciles 6,823 payload words with the 6,925
write calls, and matches each metadata block size to its generator output.
It then passes the complete 100-entry list to the open
`axi4_caliptra_recovery_sequence`.

Caliptra intentionally omits DCCM payload data for cases larger than its
16,384-word checking limit. The parser accounts for that layout and validates
the record metadata while advancing to the next testcase; such omitted
payloads are not candidates for DUT replay.

This run staged and ECC-checked 25 testcases with 6,823 payload words and
6,925 DCCM writes. The sequencer skipped zero entries and consumed generated
block-size entries 4 and 10; the test checked the selected block word counts
and threshold ranges. The memory guard reported 72% minimum free memory
against its 60% floor. Compiler warnings
cover static initialization lifetime, Caliptra's task-style `randomize()`, and
mixed timescales; the test exited 0 and printed `PASS`.

The hash-guarded temporary source overlay qualifies Caliptra's unscoped
`slam_dccm_ram`/`riscv_ecc32` testbench callbacks against the harness top and
applies Icarus's numeric `$fatal` requirement. The pinned Caliptra checkout
remained clean. The overlay generator has since gained optional top selection
and a directed DUT-replay profile; its default generated overlay is unchanged
at SHA-256 `a938bd7f0df56b07ac1cd120466b99fca6489561c4f8d2eb5a6f6700feacd004`.
This verifies the generator-to-BFM recovery-sequencer path. The first separate
DUT replay applied only an SRAM-to-SRAM AXI2AXI profile; it has since been
superseded by the all-route replay. The full default size, FIFO/fixed, reset,
and block-size combinations, along with firmware execution, remain outside the
DUT replay. See
[`../caliptra-bfm-dma-generator-dut-replay-20261006/README.md`](../caliptra-bfm-dma-generator-dut-replay-20261006/README.md).

## Reproduction

Run from the `BFM WORK` repository root:

```sh
CALIPTRA_BFM_MIN_FREE_PERCENT=60 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN="$PWD/driver/iverilog" VVP_BIN="$PWD/vvp/vvp" \
  dv/caliptra_bfm/uvm/tests/run_caliptra_dma_testcase_generator_bfm.sh
```

Captured output: `dma-testcase-generator-recovery-sequence-pass-20261006.log` (raw artifact omitted from this checkpoint).

## Input hashes

| Input | SHA-256 |
|---|---|
| Caliptra `dma_testcase_generator.sv` | `940d74ea3d0a939c28ae9a45f3211bfeba2285546399a245dafcd1c93200b447` |
| Caliptra `dma_transfer_randomizer.sv` | `b1371eaa2a416910d648e685d01196116911eb81b75ffcf2256e45328b1a379f` |
| Temporary generator overlay | `a938bd7f0df56b07ac1cd120466b99fca6489561c4f8d2eb5a6f6700feacd004` |
| `docs/conformance/release_overlays/caliptra/dma_testcase_generator_overlay.py` | `4966bf4b57d4d66c0177d84c1a4fd37e3d434e4a057c5675a1b13f2a806745d5` |
| `dv/caliptra_bfm/uvm/tests/tb_caliptra_dma_testcase_generator_bfm.sv` | `7dfccfd8dceaa72bb1d13e7d62a061e6c9327aec66674f8a087c5ac2883083fe` |
| `dv/caliptra_bfm/uvm/tests/run_caliptra_dma_testcase_generator_bfm.sh` | `e9a0a56830ea207aff49de7dcc583a41a93cebaa5d8db10fd1db629ba92cfd9d` |
| `dma-testcase-generator-recovery-sequence-pass-20261006.log` | `22f12454e4d2fe222fd5c2080b1ba2ebdfe137ea959dc37d798b2dc283178bed` |
