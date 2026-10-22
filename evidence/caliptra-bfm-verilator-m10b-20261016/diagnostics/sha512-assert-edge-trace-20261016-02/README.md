# SHA512 block clear edge trace attempt 1

This was a second focused run of the same smoke_test_sha512 row because the first transition trace observed the block become zero at time 6.296 us, but zeroize_reg, both write enables, and kv_read_data_present_reset were already low in that callback. This attempt added clock-edge and control-transition monitors around that event.

The attempt reproduced the assertion, but its trace emitted no monitor records: the monitor gated all output on absolute `$time` comparisons and the captured log showed only firmware messages plus the assertion. It therefore provides no causal signal evidence. The run archive is preserved for audit; a signal-triggered bounded monitor follows in [attempt 2](../sha512-assert-edge-trace-20261016-03/README.md).

Row: index 91, test ID 7acba2db04d9935d, smoke_test_sha512.
Pinned Caliptra RTL commit: 49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e.
Pinned SHA512 source SHA-256: 5656d5a09d1570a567bb674b1b419775a83a08b37ee70792d28ab72ae0510d82.
M10b AXI overlay SHA-256: d387d149e6956d5e19b7fc6c1f86c31b115f60b743439a37f1040fd2300968b1.

## Run evidence

Build job 1949 passed with Verilator 5.052, `--assert`, and `CLP_ASSERT_ON`; model SHA-256 `113cee6380085c353cf06d1e7edf5b2af6e6734b9cfccee50fa3fa5e820db175`. Simulation job 1950 reran only row 91 with a 600-second cap and reproduced `ERR_SHA_BLOCK_NOT_STABLE` at 6,296,000 after 41.716 seconds; peak RSS was 55,404 KiB. Firmware outcome remains FAIL. No `M10_SHA_*` monitor lines appeared, so no claim is made about the block-clear cause from this attempt. The archive `trace-run-1950-no-monitor.tar.gz` passed its local SHA-256 check (`991d1da94f5bc542ee355110f462ac8349772a07c1b70599398bf26df9705803`) and the per-result `FILE-SHA256SUMS` checks. Its remote build/output directory was removed after archival, freeing 728,618,081 bytes.
