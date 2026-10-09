# Caliptra protocol checker rerun on latest published Icarus main — 2026-10-09

A live `git ls-remote https://github.com/dsellerbrock/iverilog-uvm.git
refs/heads/main` check returned published `main` at
`0d8815febc260928e62d5c2ce82b14afd2e38dc3`. This matches the clean local
Icarus build already used by the 2026-10-09 Caliptra BFM smoke evidence; no
simulator source or branch changes were needed.

The guarded standalone checker regressions passed with that build:

- AXI accepted its legal reordered, same-ID, exclusive, and narrow transfers,
  and rejected all 41 injected protocol violations.
- AHB accepted legal transfer, two-cycle ERROR, and waited-transfer
  IDLE-to-NONSEQ cases, and rejected all 11 injected protocol violations.
- Both runs exited 0. Each memory-guard run reported 7.35 GiB minimum available
  memory; maximum process-group use was 0.01 GiB for AXI and 0.00 GiB for AHB.

Commands from the QD repository root:

```sh
IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
sh dv/caliptra_bfm/axi/tests/run_checker.sh

IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
sh dv/caliptra_bfm/ahb_lite/tests/run_checker.sh
```

SHA-256 fingerprints:

```text
603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a  iverilog
07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c  vvp
a679cf9b4119ed5a34b260be9d8b800d16b33180aa7b701a2f245bf6c5512245  dv/caliptra_bfm/axi/axi4_caliptra_checker.sv
78b3d9c434a85e2e8485efd5c3e0c811d6b09bd288a5fcf10eb834f46101a425  dv/caliptra_bfm/axi/tests/tb_axi4_caliptra_checker.sv
da715f0c8e63a93c4ecad79d3e1bdba8f136030ae80d6c8f9b27a87210c32abd  dv/caliptra_bfm/axi/tests/run_checker.sh
ee3a6f9313dad251568011ac126f30f418de0f2ce15828d0e40dc0f42ffc2c05  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_checker.sv
275d4b0e17dd52516beb1ab2eb3da2325d719913d639ca0f13f2358def172383  dv/caliptra_bfm/ahb_lite/tests/tb_ahb_lite_caliptra_checker.sv
c4c352d5bb72fc6fc2979f32fd697598bd79879ab1e7b957d9d25da9237ac4d1  dv/caliptra_bfm/ahb_lite/tests/run_checker.sh
```

This is standalone checker-unit evidence, not an actual-Caliptra integration
run or Axi4PC-equivalence claim.
