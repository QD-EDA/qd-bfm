# KeyVault full-environment gate, attempt 04

- Job 2800 on DAN-DESKTOP; row 8 (`kv_rand_wr_rd_test`), firmware commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`.
- Icarus 13.0 source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`; `iverilog` SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`.
- Python 3.14.4. One CPU, 4 GB requested; peak RSS 551,508 KiB, process wall time 3.07 s.
- Command: `python3 evidence/caliptra-bfm-keyvault-generated-hdl-20261004/run.py --runtime-ahb-burst-smoke` with pinned compiler/runtime, generated KeyVault filelist, and the current testbench/BFM overlay.
- Overlay source SHA-256 `0f7ab997e6b77ac675cd21497a4e2026191111d7f2e8aa610bd066ee9a9323e2`; runner SHA-256 `c60678de4f210641546485b62d2099714f7da8eabfaa23a4835b0564a016819b`.
- Result: **BLOCKED before VVP**. Icarus returned 1 during elaboration with 69 `sorry: Nested member path not yet supported for class properties` diagnostics; there were no hard `error:` lines and no VVP output. The failing generated sequences access `configuration.<agent-config>...` through a type-parameterized sequence base. This is the #672 class of issue; no simulation/pass result was produced.
- Full run directory archived as `raw/job-2800.tar.gz`, SHA-256 `d6712846147b389ff4f45609003c464fd1836f293e73ec7e9725f70cc24b1677`. The archive includes source snapshot, prepared overlay, file manifests, compiler summary, runner output, resource report, job metadata and Slurm output.
- Source snapshot SHA-256: `a9a2ee4e0bca8297da0ff8f3f4537b91bd002c6ab0faa3d07c677d662c7649ab`.
