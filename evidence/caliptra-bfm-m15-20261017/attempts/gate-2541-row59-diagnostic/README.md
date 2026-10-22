# Row 59 diagnostic gate

Job 2541 ran row 59 (`norm_check_normal_test`) on DAN-DESKTOP with pinned Icarus source `9b5fad2afb4104caa816b257d5bccc40f01b8c66` and binary SHA256 `6cd9749cb1e981820f64fdc737ae458bf6c46e3fcad8927afaf92649ee9a3288`. Runner SHA256 was `7fe5d2ce648f06598aa33939e9edd3372cb95f6408e0e01145141d996029d9e0`; manifest SHA256 was `049ea8f7a78a72b32bdded08b8116f8691ac8ad43a13a7624529ec0398ae61ea`.

Result: BLOCKED at compile, exit 1, 0.04 seconds: `abr_config_defines.svh:19: Include file abr_sva.svh not found`. No simulation ran. The updated diagnostic matcher preserved this exact include error. The input row, exact command, compile log, resource record, result, job log, manifest, and gate script are preserved in this directory.
