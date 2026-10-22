# M17 ECC open-AHB row 54 gate

Job 2896 ran row 54 (`ECC_normal_test`) on DAN-DESKTOP with the pinned Icarus 13.0 development build (source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) and Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. It used 1 CPU, 4 GiB and a 600-second row timeout; compilation stopped in 1.995 seconds with exit 10, before VVP.

The corrected open-AHB filelist reached generated ECC packages. Compilation reports four blocking classes: >64-bit automatic coverpoint bins (`ECC_out_transaction_coverage.svh:17`, existing issue #667), string concatenation using `ECC_in_agent_config.convert2string`, unsupported nested class member path in the sequence base, and writes to `hrdata`/`hreadyout` through input-direction initiator modport signals. The compile log records ten elaboration errors in total; no testbench pass criteria or RTL were changed.

Raw archive: `raw/job-2896.tar.gz`; SHA-256: `53601a870f5512189f32ceadfbfd46a5f714682a71ec8b0c664f051891392778`. Its checksum is in `raw/job-2896.tar.gz.sha256`. The staged source snapshot hash is recorded in `source-files.sha256` and `run.sbatch` metadata.
