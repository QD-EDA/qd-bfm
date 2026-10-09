# Caliptra AXI and AHB checker run on published Icarus — 2026-10-09

The existing standalone profile-checker regressions passed using a clean
source archive of published Icarus main
`127b887dfdc09283ab0187a2e618421dee3d5dcc`:

- AXI accepted its legal, reordered, same-ID, exclusive-monitor, and narrow
  transfer cases, and rejected all 41 injected protocol violations.
- AHB accepted a legal transfer, a two-cycle ERROR response, and IDLE-to-NONSEQ
  during a waited transfer, and rejected all 11 injected violations.

These are checker-unit regressions, not full Caliptra integration or Axi4PC
equivalence. Each runner exited 0 after verifying its expected failure
diagnostics.

Commands:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
dv/caliptra_bfm/axi/tests/run_checker.sh

IVERILOG_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-latest-127b887/install/bin/vvp \
dv/caliptra_bfm/ahb_lite/tests/run_checker.sh
```

SHA-256 fingerprints:

```text
a89a2e29bf1b47b71a6e4f285e32692cd7a4877a21ee9bb554e066d6e9e27602  iverilog
29daf647fac57ec276dbed18fcc8978777f1f0a5c79064389838d05f8bc785ca  vvp
a679cf9b4119ed5a34b260be9d8b800d16b33180aa7b701a2f245bf6c5512245  dv/caliptra_bfm/axi/axi4_caliptra_checker.sv
78b3d9c434a85e2e8485efd5c3e0c811d6b09bd288a5fcf10eb834f46101a425  dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_checker.sv
da715f0c8e63a93c4ecad79d3e1bdba8f136030ae80d6c8f9b27a87210c32abd  dv/caliptra_bfm/axi/tests/run_checker.sh
ee3a6f9313dad251568011ac126f30f418de0f2ce15828d0e40dc0f42ffc2c05  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_checker.sv
275d4b0e17dd52516beb1ab2eb3da2325d719913d639ca0f13f2358def172383  dv/caliptra_bfm/ahb_lite/tests/tb_ahb_lite_caliptra_checker.sv
c4c352d5bb72fc6fc2979f32fd697598bd79879ab1e7b957d9d25da9237ac4d1  dv/caliptra_bfm/ahb_lite/tests/run_checker.sh
```
