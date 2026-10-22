# AHB QVIP compatibility environment — 32-bit gate

Status: **PASS** on pinned Icarus 13.0, job 2765. This dedicated test is a complete QD-BFM AHB QVIP-compatible integration: it creates active and passive generated-name environments, drives single and burst transfers, verifies monitor-item typing and copy/compare, checks three analysis streams, and predicts full and partial-error bursts into a UVM RAL model.

This is not a generated-UVMF row from the 50-row M15 set. It verifies the AHB compatibility API and integrated BFM environment. The generated-row qualification remains separate.

## Run

- Host: DAN-DESKTOP.
- Simulator: Icarus 13.0 devel, source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`, `vvp` SHA256 `c2474d2a745aa7d896885202314a5244ee26af56a32dda59a6c8fbd3ba362e3a`.
- UVM: Accellera 1800.2 2020.3.1 bundled with the pinned Icarus.
- Profile: `AHB_PROFILE=32`, `SV_EDITION=2012`.
- Slurm: one CPU, 1 GiB, 15-minute job limit; 600-second process-group timeout. Run time was 27 seconds. Memory guard reported 0.36 GiB peak process-group RSS; the 1 GiB request was based on a prior 592,552 KiB compile peak.
- Result: explicit `PASS: AHB MVC copy/compare profile width=32` and `PASS: generated-name AHB QVIP streams and full/partial-error RAL burst prediction`; UVM summary reports 0 errors and 0 fatals; `$finish` at 490000 (1ps).

Icarus also emitted a timescale warning and one `AHB_QVIP_CVG` warning: internal proprietary QVIP covergroups are not recreated. The configured coverage stream is still exercised; proprietary coverage implementation itself is outside this test.

## Reproducibility

The run script, exact 155-file source snapshot, archive and per-file hashes, scheduler output, and submission metadata are preserved beside this README. Archive SHA256: `044860ce2efc9f5d94df2c0290c206c1f98639c525ddf5067b2b1a33de0d6d39`. The remote Slurm run directory was removed after copying the result and manifest.

Attempt 01 is recorded separately as **STAGING-FAIL; no test result** because it omitted the memory-guard helper. Attempt 02 is the passing run reported here.
