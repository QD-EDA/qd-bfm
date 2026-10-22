# Icarus main wide-bin rerun — attempt 02

This retry corrects attempt 01's runner setup: `--repo-root` must expose the QD-BFM support filelist, while `CALIPTRA_ROOT` remains the pinned Caliptra checkout. The staged support archive contains the 37 files named by `dv/caliptra_bfm/uvm/caliptra_bfm_uvm.f`; every source was clean at QD-BFM commit `01589b77bd606db70a991d4f93e30db9eecd9625` and is hashed in `runner-support-sources.txt`.

The exact PR #697 build is Icarus 13.0 devel (`8c95b5cc`): `iverilog` SHA-256 `825148179dae25095eb5ec3d7804a5c5c0a09102c78dc47d2f86ffdf95141d6d`, `vvp` SHA-256 `36831eaf6a1902cd3625bc5db478636a1d3dc7bb8030c000e1d19a3d46f28375`. The PR's committed 512-bit regression passes under `-g2017`; see attempt 01 and the wide-bin diagnostic README.

Array 3360 reruns rows 16, 17, 54, and 55 with the pinned M15 runner, changing only its Icarus pin and binary hash. Each row has a 3,600-second timeout; array concurrency is two. Attempt 01 job 3355 did not compile or simulate and is preserved separately as a setup error.

## Results

| Row | Verdict | Evidence |
|---|---|---|
| 16 `example_derived_test` | `BLOCKED`: compile/simulation exit 0, but no testcase marker and zero scoreboard comparisons. The generated sequence has no body/checker at `sequences/src/example_derived_test_sequence.svh:18-26`. | `raw/rows-3360/job-3361_16.tar.gz`, SHA-256 `764c4a44dfc934a59e741e7d95d54d0219aa48e3dd3db87c288cc8d693b0fd0e` |
| 17 `SHA512_random_test` | `PASS`: compile/simulation exit 0, pass marker present, UVM_ERROR/UVM_FATAL both zero. | `raw/rows-3360/job-3362_17.tar.gz`, SHA-256 `975e61991a152ebec6942ce5eb4565f02298df8455dc368fc9e81e7bd492cf99` |
| 54 `ECC_normal_test` | `BLOCKED`: compile exit 2; no simulation. Generated BFM writes through input modport members at `ECC_in_driver_bfm.sv:135,137`. | `raw/rows-3360/job-3363_54.tar.gz`, SHA-256 `71fe38555a61d5a78ee7bbb97ec4e06218a261200672c77090d9f216e0fc0555` |
| 55 `ECC_otf_reset_test` | `BLOCKED`: compile exit 2; no simulation. Same generated BFM modport-direction blocker as row 54. | `raw/rows-3360/job-3360_55.tar.gz`, SHA-256 `e9dc758df251b4adbbaa9efdc4cab80e6ab677655bbdac663a9aa46f98b18891` |

The old wide-auto-bin diagnostic is absent from all four compile logs. Final M20 totals are **51 PASS / 12 PASS_OVERLAY / 3 FAIL / 22 BLOCKED / 20 TIMEOUT** (108 rows).
