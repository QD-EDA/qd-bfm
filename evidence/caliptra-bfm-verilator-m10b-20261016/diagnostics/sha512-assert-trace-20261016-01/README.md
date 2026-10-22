# SHA512 block-stability assertion trace

This diagnostic reruns only smoke_test_sha512 (ID 7acba2db04d9935d) using the M10b AXI overlay and a read-only trace at each block_reg transition observed while reset_n && !ready_reg. It records zeroize_reg, software/gen-hash write controls, the previous/current block values, and the terminal assertion. Firmware, RTL behavior, assertion, and pass classifier are unchanged; the trace is an instrumentation-only source overlay.

The selected firmware row previously passed on c339 and failed with Verilator's ERR_SHA_BLOCK_NOT_STABLE at 6,296,000. The source assertion at the pinned RTL commit requires block_reg to remain stable whenever ready_reg is low. This diagnostic tests whether the block change coincides with the RTL's legitimate zeroize clear while the assertion guard remains active.

Pinned Caliptra RTL commit: 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e.
Pinned SHA512 source SHA-256: 5656d5a09d1570a567bb674b1b419775a83a08b37ee70792d28ab72ae0510d82.
M10b AXI overlay SHA-256: d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1.

## Run evidence

Build job 1944 passed on DAN-DESKTOP with Verilator 5.052, riscv-none-elf-gcc 15.2.0, Python 3.12.15, --assert, and CLP_ASSERT_ON. Build elapsed time was 3:49.29, peak RSS 2,380,728 KiB, model SHA-256 353c5073ea991c8753e5e2b8dea03822048caf470e35f294aa3d231e86699b42. The diagnostic SHA512 overlay hash is 93540823fec7514cacc978598e9a0d3825605e19ed9259f4a3698b32ef8f8c93.

Run job 1946 used the 600-second wrapper cap and terminated at the expected assertion after 42.95 seconds; peak RSS was 55,488 KiB. It reproduced ERR_SHA_BLOCK_NOT_STABLE at time 6,296,000 with reset_n=1 and ready_reg=0. The logged block changed from a value ending in 61626380 to zero, while zeroize_reg, gen_hash_block_write_en, kv_src_write_en, and kv_read_data_present_reset were already 0 at that callback. That trace identifies the asserted transition but not the control edge that caused it. The follow-up edge trace is in ../sha512-assert-edge-trace-20261016-02/. The diagnostic output archive is trace-run-1946.tar.gz (SHA-256 8f64990e5d0117d79b49cfd69fa595b24b62e9be9bd9b5af1331bc0f20ec4e1d); its result-file checksums passed. This diagnostic is not part of the official 103-row overlay table.
