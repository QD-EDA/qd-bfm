# M17 SoC-IFC AAXI row 43 gate

Job 2895 ran row 43 (`soc_ifc_trng_test`) on DAN-DESKTOP with the pinned Icarus 13.0 development build (source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`) and Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. It used 1 CPU, 4 GiB and a 600-second row timeout; compilation stopped in 0.518 seconds with exit 49, before VVP.

The open-AHB and AAXI overlays got past the earlier interface-file parse and ARM Axi4PC failures. The compile then hit wildcard-transition coverage syntax errors in pinned SoC-IFC source (`mbox_csr_covergroups.svh:64` earliest; existing issue #661), followed by the absent vendor include `avery_defines.svh` in the generated register-model package. No testbench pass criteria or RTL were changed.

Raw archive: `raw/job-2895.tar.gz`; SHA-256: `52d3f17b424a4aee6989f9cd7de13b6256e45d5b4e97735ccfcd75a25db57c05`. Its checksum is in `raw/job-2895.tar.gz.sha256`. The staged source snapshot hash is recorded in `source-files.sha256` and `run.sbatch` metadata.
