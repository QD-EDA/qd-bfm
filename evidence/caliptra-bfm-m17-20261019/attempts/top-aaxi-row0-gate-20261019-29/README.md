# Caliptra top AAXI row 0 fresh gate

One-row gate with the updated open-AAXI filelist overlay that drops the unused Axi4PC syntax-guard stub. Uses the existing AAXI compatibility package and generated environment open-AHB overlay. Limit: 600 s, 1 CPU, 4 GiB. Pass criteria unchanged. Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`.

Job 2941 reached Icarus after dropping the unused `Axi4PC.sv` stub. Compile exit was 49 after the wildcard-transition syntax defect in `mbox_csr_covergroups.svh:64` (#661); the log also reports missing vendor `avery_defines.svh`. Simulation did not start. Row 0 is `BLOCKED`. Raw archive `raw/job-2941.tar.gz`; SHA-256 `d897c4cdfc08397cbb2f4e30e0715f7df7a09af04fb3e76e444aed98de8a0080`.
