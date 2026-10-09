# Caliptra AXI-complex BFM on published Icarus — 2026-10-09

The standalone replacement for Caliptra's testbench AXI complex passed its
guarded regression with `CALIPTRA_BFM_CHECKER` enabled. The smoke exercised
one-shot SLVERR injection, SRAM/FIFO traffic, FIFO controls, recovery
availability, randomized channel stalls, and 208-dword burst readback. It
printed the pass marker and finished at `16580000` (1 ps precision).

This is module-level BFM evidence against Caliptra's real `axi_if` type and
testbench package. It does not instantiate the Caliptra DUT or run UVM.

## Reproduction

From the QD-BFM repository root:

```sh
CALIPTRA_RTL=/Users/danielellerbrock/projects/iverilog_uvm/caliptra-rtl \
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
  sh dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh
```

The QD-BFM runner is at commit `e1898db69e287d92cb2b6161e41bbc15edc86af6`.
Caliptra was clean at `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The Icarus
tools came from a clean source archive of published main
`127b887dfdc09283ab0187a2e618421dee3d5dcc`; the executable hashes are included
below. This is the latest published simulator revision available locally; the
remote main head could not be queried in this environment.

The runner compiled in IEEE 1800-2012 mode with `-DVERILATOR -DXCELIUM`
compatibility defines and `-DCALIPTRA_BFM_CHECKER`. Its output was:

```text
[0] TB: one-shot AXI SLVERR range 0xfa570000 to 0x123440000
PASS: Caliptra AXI complex BFM errors, SRAM/FIFO traffic, FIFO controls, recovery availability, randomized stalls, and 208-dword burst readback
... $finish called at 16580000 (1ps)
```

## Input hashes

| Input | SHA-256 |
| --- | --- |
| `dv/caliptra_bfm/axi/tests/run_caliptra_axi_complex_bfm.sh` | `1d6bfdb6fbc9bfa2bfdd7b2cc33fcd8b4a2f258b73c5f2dd30660844853972d9` |
| `dv/caliptra_bfm/axi/tests/tb_caliptra_top_tb_axi_complex_bfm.sv` | `2532d5f27216a8a6e71e4db3341b13aa4f0d6af540ef8e30c1d41da0091cefc8` |
| `dv/caliptra_bfm/axi/caliptra_top_tb_axi_complex_bfm.sv` | `2a5b59b60371e1508305014fdabcbb217b47e3978c2f84c12ed545ae1c85d400` |
| `dv/caliptra_bfm/axi/axi4_caliptra_checker.sv` | `a679cf9b4119ed5a34b260be9d8b800d16b33180aa7b701a2f245bf6c5512245` |
| `dv/caliptra_bfm/axi/axi4_caliptra_dma_subordinate.sv` | `71aedfb9de92064a6d63f4523ab0620ebcc55b84ee4b2955c04a54ab75c8c3a8` |
| `dv/caliptra_bfm/axi/axi4_caliptra_fifo_subordinate.sv` | `49416a58859e4664be14850e9f118191194d480a43d6459cc9842ceb7087fbf3` |
| `dv/caliptra_bfm/axi/axi4_caliptra_memory_subordinate.sv` | `0a59bb61380113bb60115d20b06628da2c55a11360f31a8355ea738cea46bd10` |
| `dv/caliptra_bfm/axi/axi4_caliptra_recovery_sequence.sv` | `49e9c8b74b1b74ffa41237ba180ff518971eb2799a693d816074b4d7d1250adf` |
| `dv/caliptra_bfm/axi/axi4_caliptra_recovery_avail.sv` | `ca4a3dadfc06c550722f489a40832fbfd6a8364cdcecb3816e363fc130476c8b` |
| `dv/caliptra_bfm/axi/axi4_caliptra_random_stalls.sv` | `6c828f9112d2895ea9f67d2132c157545bd2ac22a49acd2ad7736dd4b24f1924` |
| Caliptra `axi_pkg.sv` | `07991843e3a2b77e6aae9c6903ae8ff08927ddbb517d83a23f96abd89be3af29` |
| Caliptra `axi_if.sv` | `e03bd7a7654eb9c31bd532861b94d59c876810aa9798f9f67f7df2a5a3f5495c` |
| Caliptra `soc_ifc_pkg.sv` | `dd3c667d985e7cc26110e18abcc3b106a426ce5cc4e60bd5c886f1032edd4433` |
| Caliptra `caliptra_top_tb_pkg.sv` | `f4a46ecd06d0dd3dc333fe7f9d58d4813c8a0c2efa0ea5cde2534f0de4702425` |
| Icarus `iverilog` binary | `a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602` |
| Icarus `vvp` binary | `29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca` |
