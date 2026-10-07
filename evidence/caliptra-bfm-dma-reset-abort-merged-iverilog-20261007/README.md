# Caliptra DMA reset-abort on merged Icarus — 2026-10-07

## Result

The focused `--reset-abort-only` test passed against Caliptra's actual
`axi_dma_top` using the Icarus binaries built after merging the latest recorded
`origin/main` simulator commit. The test holds B, waits for an accepted AW and
final W beat, confirms the response is pending but not presented, asserts
reset, checks that no write completion was published and the target queues
were cleared, then reprograms the DUT and verifies a full 65-word post-reset
DMA transfer. The exact pass marker and UVM summary are preserved in
[`verify.log`](verify.log).

UVM reported zero warnings, errors, or fatals. The memory guard had a 40% free
RAM floor; preflight and minimum observed free memory were both 53%. The
compiler emitted existing static-initialization, timescale, and
`eval_object_select` warnings; this run does not qualify away those warnings.

This is actual DMA block-level reset recovery evidence, not full Caliptra-top
firmware reset qualification or generated UVMF environment qualification.

## Reproduction

```sh
env CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
  CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
  CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
  IVERILOG_BIN=/private/tmp/bfm-work-install/bin/iverilog \
  VVP_BIN=/private/tmp/bfm-work-install/bin/vvp \
  dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --reset-abort-only
```

The Caliptra RTL is pinned at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
The binaries identify as Icarus Verilog 13.0 (devel), built from simulator
merge `ac4532fab037e91df2f903e67fb40f59baedccca`, merging
`origin/main` `197f9baece79e66d25524906fb7b54c9faa8f4e2`. Exact binary and source
hashes, plus transaction and guard details, are in [`result.json`](result.json).
