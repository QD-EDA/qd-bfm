# Caliptra DMA 208-word mid-W reset replay — diagnostic — 2026-10-08

**Result: diagnostic pass, not qualification.** The available Icarus build is
dirty and unpublished. It is recorded as a diagnostic under the standing
evidence rule.

The test instantiates Caliptra's actual `axi_dma_top` against the open AXI
target. It asserts reset after an accepted AW and exactly 10 accepted W beats,
before WLAST. It checks that only those 10 SRAM words were written, the target
queues were cleared, and the aborted write was not published as a completed
UVM transaction. It then reprograms the DUT, completes a 208-word transfer,
and checks every destination word. The UVM monitor reports 5 AW, 208 W, 5 B,
4 AR, and 208 R handshakes; warning, error, and fatal counts are zero.

The focused command passed under the memory guard. The captured run reported
8.20 GiB available before launch, 7.47 GiB minimum available, and a 0.36 GiB
maximum child process group.

## Reproduction

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/driver/iverilog' \
VVP_BIN='/Users/danielellerbrock/projects/iverilog_uvm/BFM WORK/vvp/vvp' \
  sh dv/caliptra_bfm/uvm/tests/run_caliptra_axi_dma_top_uvm_bfm.sh --reset-abort-mid-w-only
```

The guarded run output is [`run.log`](run.log).

## Source identity

| Input | Identity |
|---|---|
| Caliptra RTL | `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` |
| Icarus source HEAD | `ac4532fab037e91df2f903e67fb40f59baedccca` — dirty, unpublished |
| Icarus version | `13.0 (devel) (ac4532fa-dirty)` |

| Artifact | SHA-256 |
|---|---|
| `tb_caliptra_axi_dma_top_uvm_bfm.sv` | `4785599bbaefbea6da12aab7af4ab32a72cbfa868d9267f43c9779fc18ef5070` |
| `run_caliptra_axi_dma_top_uvm_bfm.sh` | `a3c158ff2aaeb592ac16e7c413ac11aa1974a3b889237292e601d71dc2bd1b8e` |
| `run.log` | `76dbd396b38a31fb0dff3d751ff3e65b388807308f9c05a2286f33405eb9d0fe` |
| `BFM WORK/driver/iverilog` | `6e756b01d956e5686c9bb00fd443465dba00ef8f4c77d1ae91b45e78d641c114` |
| `BFM WORK/vvp/vvp` | `4bf80d6d22b44c22d518514c2f98f1f3fd485d77ba7c63bc97e68770d58b2867` |

This is actual DMA-block integration coverage, not a full Caliptra top or
firmware warm-reset run. Re-run on a clean, published Icarus revision before
using it in a qualification claim.
