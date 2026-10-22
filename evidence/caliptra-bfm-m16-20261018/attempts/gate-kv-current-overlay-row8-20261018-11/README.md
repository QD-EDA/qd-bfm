# KeyVault row 8 current-overlay no-regression gate, attempt 11

Re-run of generated KeyVault row 8 (`kv_rand_wr_rd_test`) against the current overlay after the HSEL and transfer-type fixes for row 6. This preserves the four-beat prediction gate and checks that the expanded normal-runtime compatibility rewrites do not regress the existing burst-smoke pass.

- Host: DAN-DESKTOP. Python 3.14.4.
- Firmware commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Row YAML SHA-256: `7999797f958d70e092128bb65778f6e75377d9ba5dad2af1384900cfe4447d9b`; pinned filelist SHA-256: `8b6954a0995ee6752c019af82c144b4223a175ac3d4333f067f7097dfac6824c`.
- Icarus source commit: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; version 13.0 (devel); `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Resources: 1 CPU, 4 GiB requested, 30-minute Slurm cap; 600-second per-test timeout.
- Runner: `run.py --runtime-ahb-burst-smoke`, `CALIPTRA_UVM_TESTNAME=kv_rand_wr_rd_test`; original scoreboard and four-beat pass gates unchanged.
- Source archive SHA-256: `aaab0bec92904660dcc385de06be342547de6c2513471d15e7f7af0ba719ad46`.
- Overlay source SHA-256: `b75e24db5820f8132cc6039f9e96d5063a8377c1fdf5e8183bd4272f640ad53b`.
- Raw job archive SHA-256: `d94c240a54412d0a7f3861ba0dabf909522a745368c2f09a34255ccc902ff1a6`.

**PASS; no regression.** Job 2824 compiled under IEEE 2017 (76 warnings). Row 8 completed with 409 AHB scoreboard matches and the four-beat prediction check, then reached `** TESTCASE PASSED` and `$finish` at 409,070,000 (1 ps). UVM_ERROR=0, UVM_FATAL=0, with 89 non-fatal runtime warnings. Wall time was 36.58 s; peak RSS was 630,600 KiB. UVM report ID `[SCBD_AHB]` appears 818 times because each matched transfer reports receipt and match; the runner's verified transaction-match count is 409.

The full run archive is `raw/job-2824.tar.gz`. The run directory was removed from DAN-DESKTOP after archive verification.
