# Draft: SHA512 block-stability assertion does not allow ZEROIZE clear

**Status:** Local draft for user review only; not posted.

## Evidence

For `smoke_test_sha512` on pinned Caliptra RTL commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`, c339 passes while assertion-enabled Verilator reports `ERR_SHA_BLOCK_NOT_STABLE`. The signal trace shows software ZEROIZE asserting `SHA512_BLOCK[*].BLOCK.hwclr`; as `ready_reg` falls, the block is intentionally cleared to zero. `ERR_SHA_BLOCK_NOT_STABLE` checks `$stable(block_reg)` and its disable guard covers reset or `ready_reg`, but not ZEROIZE. The c339/Verilator disagreement is therefore in assertion sampling/guard behavior around a legitimate clear, not a firmware failure or AXI overlay effect.

The detailed edge sequence and pinned RTL explanation are in the [row 91 root-cause report](../../../caliptra-bfm-verilator-m10b-20261016/diagnostics/sha512-assert-edge-trace-20261016-03/root-cause.md); the trace and result checksums are preserved alongside it.

Array 1835 also reports the same `ERR_SHA_BLOCK_NOT_STABLE` assertion for `smoke_test_sha512_restore`, `pv_hash_and_sign`, and `pv_hash_zeroize`. Their raw logs are in the checksum-verified array archives. Only `smoke_test_sha512` has the focused ZEROIZE edge trace; the trigger is not independently confirmed for the other three. Their c339 baselines are `UNVERIFIED`, `UNVERIFIED`, and `FAIL`, respectively.

M12's assertion-only build-time guard passed the `smoke_test_sha512` gate (job 2126, mcycle 63,435, `sim_scan.bad=0`) and `smoke_test_sha512_restore` (job 2136, mcycle 73,221). The same array still failed `pv_hash_and_sign` and `pv_hash_zeroize` at `ERR_SHA_BLOCK_NOT_STABLE`. The ZEROIZE edge is traced only for `smoke_test_sha512`; the two remaining failures are retained because no independent traces prove the same trigger. The complete local evidence is in `evidence/caliptra-bfm-verilator-m12-20261017/sha512-zeroize/`.

## Expected behavior

The stability property should allow the block clear during the specified ZEROIZE operation while continuing to check stability during other active hashing cycles. No assertion change has been made in qd-bfm.
