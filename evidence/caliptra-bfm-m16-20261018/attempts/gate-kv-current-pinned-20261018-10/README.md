# KeyVault row 6 transfer-type overlay, attempt 10

One-row runtime gate for generated KeyVault row 6 (`kv_rand_lock_test`) after applying the existing AHB transfer typedef workaround to ordinary runtime mode. Attempt 09 showed the HSEL issue was fixed, then hit the parameterized transfer cast failure already reduced in `diagnostics/ahb-uvm-factory-cast/` (#666). The overlay now rewrites the generated environment, configuration, scoreboard, and predictor transfer types to `ahb_lite_slave_0_transfer_t` for every KeyVault run; it also uses direct construction for the predictor output transaction. Only testbench/setup sources change. RTL, firmware, and pass criteria are unchanged.

- Target: row 6, `kv_rand_lock_test`; firmware commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; row YAML SHA-256 `17c86f0887cfdb3cb3a3ff4ff25ef65a5c932e1a4a8ad34c40cc36352ea2b66f`.
- Host: DAN-DESKTOP. Python 3.14.4.
- Icarus source commit: `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; version 13.0 (devel); `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Resources: 1 CPU, 4 GiB requested, 30-minute Slurm cap; 600-second per-test timeout.
- Runner: `run.py --runtime`, `CALIPTRA_UVM_TESTNAME=kv_rand_lock_test`. The runner still requires successful exit, zero UVM errors/fatals, testcase pass marker, and `$finish`.
- The run script preflights that the HSEL tie-off is absent and that normal-mode overlay generation completes.
- Source archive SHA-256: `31df4dfa78a91a37b9f17acb8fdf3bd3e3b1dd2b4018f587de640e91bc4ecbe9`.
- Overlay source SHA-256: `b75e24db5820f8132cc6039f9e96d5063a8377c1fdf5e8183bd4272f640ad53b`.
- Raw job archive SHA-256: `b58fef33e4f269e34c950ab0a19a5ddf26e9113be86bd227cb653d8f6ff73346`.

**PASS.** Job 2822 completed the normal-mode overlay preflight and generated the runtime image. `kv_rand_lock_test` reached `** TESTCASE PASSED` and `$finish` at 2,254,640,000 (1 ps); UVM_ERROR=0 and UVM_FATAL=0. There were 3,170 non-fatal runtime warnings and 76 compile warnings. Wall time was 1:44.10; peak RSS was 630,396 KiB. The new overlay path uses the generated transfer typedef throughout the environment, config, scoreboard, and predictor; the captured prepared scoreboard casts to `ahb_lite_slave_0_transfer_t`.

The full job archive is `raw/job-2822.tar.gz`. The run directory was removed from DAN-DESKTOP after archive verification.
