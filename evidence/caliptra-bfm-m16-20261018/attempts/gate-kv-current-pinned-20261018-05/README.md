# KeyVault full-environment gate, attempt 05

Job 2802 ran on DAN-DESKTOP on 2026-10-18 after submission at 22:15:55 UTC as a single-row gate (1 CPU, 4 GiB requested, 30-minute job cap). It tested generated KeyVault row 8 (`kv_rand_wr_rd_test`) on current pinned Icarus 13.0 and firmware commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, using the existing testbench/BFM/setup overlay and AHB burst scoreboard checks. It did not modify RTL, firmware or pass criteria.

This overlay revision now source-pins and rewrites all 19 generated sequence sources that extend `kv_env_sequence_base`, including the nine omitted from attempt 04, and rewrites the special AHB smoke sequence to use that base's concrete `kv_cfg` alias. A preflight run of the overlay generator against the protected pinned firmware source produced 19 sequence outputs; no sequence output contains a remaining `configuration.` reference. The six remaining references are in non-sequence sources (`test_top`, predictor/environment), outside the compiler diagnostics seen in attempt 04.

- Overlay source SHA-256: `02db92d8a0ce38ac10ca16e12ac10b7300ecabe134772e410c22449ea23691a2`.
- Runner source SHA-256: `c60678de4f210641546485b62d2099714f7da8eabfaa23a4835b0564a016819b`.
- Source archive SHA-256: `332de7515fd07af05b06b154e8626f1b5ae194d69ac4d6b9ab5685ed02d45878`.
- Slurm script SHA-256: `df27354168dbbd84a46711c4471cb14ccdae995ef32d574cab6cb879b9b7ec71`.
- Host/toolchain: DAN-DESKTOP, Python 3.14.4, Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`, `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Pinned generated filelist SHA-256 `8b6954a0995ee6752c019af82c144b4223a175ac3d4333f067f7097dfac6824c`; generated `kv_env_configuration.svh` SHA-256 `52de073510ca16bb8d672d355f54170bedd60268acc00b097d7ad6bcd40b862a`.

**PASS with overlay.** Icarus compiled the runtime image under IEEE 2017 (76 compile warnings), and `kv_rand_wr_rd_test` completed with 409 AHB scoreboard matches, the generated four-beat read prediction marker, 89 runtime warnings, zero UVM errors/fatals, `** TESTCASE PASSED`, and `$finish`. The runner returned 0. Runtime wall time was 34.82 s with peak RSS 630,756 KiB. The unchanged runner's gates require every listed completion and error check; see `run.py` and the captured `runner.out`/`sim.log`.

The full Slurm run tree was archived as `raw/job-2802.tar.gz`, SHA-256 `e38f2ee95b41e84c0faeb3cb837da1019a3022dc5f1703a5fef3723e2f193f33`; it contains the generated overlay, source and run manifests, toolchain/firmware metadata, compiler/runtime logs, and resource report. The remote run directory was removed after archive verification.
