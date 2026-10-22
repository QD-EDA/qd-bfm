# KeyVault row 6 full-environment gate, attempt 06

This one-row gate reran generated KeyVault row 6 (`kv_rand_lock_test`) on pinned Icarus after the environment overlay passed row 8. It used the same AHB BFM/filelist/setup overlay and did not change RTL, firmware, or pass criteria.

The evidence runner now reads `CALIPTRA_UVM_TESTNAME`, defaulting to `kv_rand_wr_rd_test`; the row-6 job sets it to `kv_rand_lock_test`. Runtime completion still requires a zero simulator exit, zero UVM errors/fatals, `** TESTCASE PASSED`, and `$finish`. This row does not enable the row-8-specific four-beat AHB smoke check.

- Host/toolchain: DAN-DESKTOP; Python 3.14.4; Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; `vvp` SHA-256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- Firmware commit: `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`; row-6 YAML SHA-256 `17c86f0887cfdb3cb3a3ff4ff25ef65a5c932e1a4a8ad34c40cc36352ea2b66f`.
- Overlay source SHA-256: `02db92d8a0ce38ac10ca16e12ac10b7300ecabe134772e410c22449ea23691a2`.
- Runner source SHA-256: `d0a8a0e31316be3cf58e54e7ed511b711addb725b46808482300669c6c182e7e`.
- Source archive SHA-256: `3f5b3ab8c3ea02e49bb1082f5fdaaff44ed88ebe5833d5b482646b434d9dbd7d`.
- Slurm script SHA-256: `4492f219138fd56f860321c1238aec55ed5c745aee9519a2c6ec351740fedc03`.

Job 2805 **BLOCKED before VVP** with one `sorry: Nested member path not yet supported for class properties` at generated `kv_ahb_sequence.svh:50`; the compile returned 1, with no `sim.log` or runtime image. The runner/overlay triage was checked against the full summary: the one diagnostic is from the AHB sequence, which the previous overlay only copied when `--runtime-ahb-burst-smoke` was active. The fix is to always emit the rewritten AHB sequence and keep only the burst-probe additions conditional. This attempt therefore does not evaluate `kv_rand_lock_test` at runtime.

Resources were 1 CPU, 4 GiB requested, 30-minute Slurm cap; process wall time was 3.07 s and peak RSS 554,656 KiB. The full run tree is archived as `raw/job-2805.tar.gz`, SHA-256 `123dd21102739eaa6c7f14ec8c0c590e1b6cf4c4e7c269efd007399a0b7322da`. VVP did not start; the remote run directory was removed after archive verification. A new one-row gate is required after the overlay fix.
