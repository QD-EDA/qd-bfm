# M17 SHA-512 and ECC first open-AHB attempt

Array job 2887 used 1 CPU and 4 GiB per task with a 600-second per-row timeout; throttle was 3. Toolchain: Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66`, binary SHA-256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`; firmware pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Snapshot SHA-256 is `417ca8b53ec686899f48d44e607bc298c171c215f1cf3823d3e9e8454456a1e5`.

Rows 16/17 reached compile and each reported two errors: a wide automatic coverpoint (>64 bits) is unsupported, and `SHA512_in_agent_config.convert2string` is rejected as a non-string concatenation operand. VVP did not start. Rows 54/55 stopped earlier because the ECC environment was not yet selected by the open-AHB filelist helper and still referenced `/include/questa_mvc_svapi.svh`; this attempt exposed that missing helper selection and is not the final ECC result. Intern summarized all four logs as compile failures; the archived logs and result records confirm the diagnostics.

The raw scheduler archive SHA-256 is `00524157b190d6a300de3b722a2ce313496e5b29d72dce032abf71181879e880`. The full per-row records and compiler logs are in `raw/job-2887.tar.gz`; `results-summary.tsv` records the exact compile errors.
