# Actual DMA FIXED-mode smoke on merged Icarus — 2026-10-07

**Result: pass.** The open AXI target and UVM monitor drove Caliptra's actual
`axi_dma_top` through both component-register FIXED-address profiles using the
Icarus development build after merging the fetched upstream `origin/main` tip
`197f9ba` (merge commit `ac4532f`). Both runs ended normally with zero UVM
warnings, errors, or fatals. The memory guard observed 61% and 62% minimum free
memory on the two repeated executions against a 40% floor.

| Profile | Result |
|---|---|
| AXI2AHB FIXED read | Passed: read 65 FIXED-address SRAM words through the DMA component data register. |
| AHB2AXI FIXED write | Passed: sent 65 component-register words to one FIXED SRAM address. |

This is focused actual-DUT evidence for two modes. It does not qualify the full
Caliptra top, all DMA modes, or the generated UVMF environment. The Icarus
build was dirty and included the merge plus local simulator changes; the binary
hashes below identify what ran. Icarus also emitted non-fatal
`eval_object_select` fallback warnings while compiling `uvmf_base_pkg.sv`.

Reproduce from the QD-BFM repository root (replace paths for your machine):

```sh
CALIPTRA_RTL=/path/to/caliptra-rtl \
CALIPTRA_BFM_MIN_FREE_PERCENT=40 \
CALIPTRA_BFM_MEMORY_GUARD_TIMEOUT_SECONDS=300 \
IVERILOG_BIN=/path/to/merged-iverilog/bin/iverilog \
VVP_BIN=/path/to/merged-iverilog/bin/vvp \
dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh \
  --component-fixed-modes-only
```

## Source identity

| Input | Identity |
|---|---|
| QD-BFM source before this evidence update | `af7bf04ce500f89a48e5282a762b733fdd195d9f` |
| Caliptra RTL | `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` |
| Icarus merge | `ac4532fab037e91df2f903e67fb40f59baedccca` |
| Merged upstream tip | `197f9baece79e66d25524906fb7b54c9faa8f4e2` |
| `iverilog` SHA-256 | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| `vvp` SHA-256 | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |
| Runner SHA-256 | `1d01caefe894793246f6b982eba12daa97506be5b7c320646055b4230f76cbbf` |
| Testbench SHA-256 | `a07f28783a9e6f6c7760a2e8e22be52096339e0a332ac3aeaaa0ffbcdc1bf214` |

Both executions exited 0 and produced the expected PASS markers. The runner
removes its temporary compile output; no raw log or simulator binary is copied
into this evidence directory.
