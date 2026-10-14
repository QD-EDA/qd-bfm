> Checkpoint copy: simulation logs and generated binaries are kept outside this feature branch.

# Caliptra AXI UVM agent reset-abort — 2026-10-06

The native UVM AXI driver has directed read and write reset-abort regressions.
`+RESET_ABORT` accepts an AXI read address while R is stalled; reset must return
the UVM item unsuccessfully within 200 cycles without publishing a completed
read. `+RESET_ABORT_WRITE` accepts AW and W, stalls B, then asserts reset; the
item must return unsuccessfully within 200 cycles without publishing a
completed write. Both paths then run the existing burst read/write smoke to
prove recovery. Address and data handshakes have a 128-cycle bound.

Both memory and DMA subordinate targets passed the read and write reset-abort
cases with zero UVM warnings, errors, or fatals. The read runs observed 75%
minimum free memory; the write runs observed 70%, all against a 60% floor.
Existing default memory and DMA agent regressions also passed; each reported
two `PREDICT_NOK` warnings from its injected-error RAL reads and zero UVM
errors or fatals. Their minimum free-memory readings were 74% and 73%,
respectively.

## Reproduction

Run from the BFM repository root with the matching BFM WORK Icarus build:

```sh
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  ./dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh +RESET_ABORT

CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  ./dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh +RESET_ABORT_WRITE
```

Use `run_uvm_dma_agent.sh +RESET_ABORT` for the DMA subordinate. The runners
also accept `run_uvm_dma_agent.sh +RESET_ABORT_WRITE`. They pass simulator
arguments through for the ordinary profiles:

```sh
./dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh
./dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh
```

The reset-profile logs were captured at `/private/tmp/qd-bfm-uvm-agent-reset.log`
and `/private/tmp/qd-bfm-uvm-dma-reset.log` during this run.

## Source hashes

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/uvm/tests/run_uvm_agent.sh` | `f3fed3f65ec424ef03d25526d673a3ab599eab2698d1fa6671e947fbbe02f404` |
| `dv/caliptra_bfm/uvm/tests/run_uvm_dma_agent.sh` | `b275649b654fb1158c0c5a5d2970c0a80e3d58f11d9fa784216da128f7b51a71` |
| `dv/caliptra_bfm/uvm/tests/tb_axi4_caliptra_uvm_agent.sv` | `4576c8595da33b7e418686f0e9b5ec3fe3b105b6233e4c67791e7f297c95c58b` |
