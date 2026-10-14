# Generated-name AHB compatibility smoke on latest published Icarus — 2026-10-09

A live remote-head query confirmed published `iverilog-uvm` `main` at
`0d8815febc260928e62d5c2ce82b14afd2e38dc3`. The clean build included
Accellera UVM submodule `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`.

The guarded `run_ahb_qvip_compat_env.sh` smoke passed four combinations:

| AHB profile | IEEE edition | Transfers | UVM summary |
| --- | --- | --- | --- |
| 64-bit | 2017 | 12 (5 reads, 7 writes; 1 error) | 5 info, 1 expected coverage warning, 0 errors, 0 fatals |
| 64-bit | 2023 | 12 (5 reads, 7 writes; 1 error) | 5 info, 1 expected coverage warning, 0 errors, 0 fatals |
| 32-bit | 2017 | 12 (5 reads, 7 writes; 1 error) | 5 info, 1 expected coverage warning, 0 errors, 0 fatals |
| 32-bit | 2023 | 12 (5 reads, 7 writes; 1 error) | 5 info, 1 expected coverage warning, 0 errors, 0 fatals |

Each run completed the generated-name active/passive analysis streams and
full/partial-error RAL burst prediction. The 64-bit profile covered 12/12
8-byte transfers; the 32-bit profile covered 12/12 4-byte transfers. Both
reported 23/47 pending wait cycles. The one warning records that internal
QVIP covergroups are not recreated; the test still sends monitored records to
the environment coverage consumer. Each run exited 0, with 0.35–0.36 GiB
maximum process-group RSS and at least 7.30 GiB available memory.

Reproduce from the QD repository root:

```sh
for profile in 64 32; do
  for ieee_edition in 2017 2023; do
    AHB_PROFILE=$profile SV_EDITION=$ieee_edition \
    IVERILOG_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/iverilog \
    VVP_BIN=/private/tmp/iverilog-uvm-origin-main-0d8815f/prefix/bin/vvp \
      sh dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
  done
done
```

SHA-256 fingerprints:

```text
603b78bbe4053c331a36e4f6a379bad46baa94571d54bb1496e383a9ff43223a  iverilog
07c11f031c2c5a79c0bb015320eac7ace0b67fd91dd27effcb7085a4b2b9a69c  vvp
23fdf5b5aca936e33a5b6f2283d4678b4a45e602294838ebab21127ea9a2aa16  dv/caliptra_bfm/uvm/tests/run_ahb_qvip_compat_env.sh
73a90fe46abaef0d12a62918e9d6a362b1bfc4de303f12951fb088d30b2b2a24  dv/caliptra_bfm/uvm/tests/tb_ahb_qvip_compat_env.sv
afa63b20041ebef82ff585b449c06cfd208ddc95e8ba2bfd18396fc6ddd931c4  dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f
4592ce31da201f0e56d4c2629aafbe3638f5d2970713fc382c3a4a5bff05bd9b  dv/caliptra_bfm/uvm/caliptra_ahb_qvip_compat_pkg.sv
0208f6d8c0fc6e83fa7533cf76990c58f4ad5a062d7cd7a943aea967bb8e4a35  dv/caliptra_bfm/uvm/caliptra_ahb_mvc_compat_pkg.sv
e78429a0ad7bfbdb38ed0fa70602021b56f44f95b6f9cf7abd7df8ede294788a  dv/caliptra_bfm/uvm/ahb_lite_caliptra_uvm_pkg.sv
520933e2b42ba6f2e5e58e1c5be3f48088e50823045c9cdba2c4700e30d57061  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_master.sv
ee3a6f9313dad251568011ac126f30f418de0f2ce15828d0e40dc0f42ffc2c05  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_checker.sv
8aa79664176666801084ce7fe96ac34fe91977845cf7e36573320d5ed80d999a  dv/caliptra_bfm/ahb_lite/ahb_lite_caliptra_monitor.sv
```

This is a synthetic-target compatibility smoke, not a generated Caliptra
UVMF/DUT run or qualification of licensed QVIP behavior.
