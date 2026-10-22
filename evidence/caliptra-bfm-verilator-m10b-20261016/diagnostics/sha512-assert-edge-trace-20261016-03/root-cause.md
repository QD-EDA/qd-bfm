# Row 91 SHA512 assertion discrepancy

## Finding

`smoke_test_sha512` (row 91, test ID `7acba2db04d9935d`) passes on c339 but Verilator reports `ERR_SHA_BLOCK_NOT_STABLE` at time 6,296,000, cycle 62939. The signal trace attributes the block change to the firmware's SHA512 ZEROIZE operation, not to an AXI write or unrelated data-path activity.

At the preceding logged transition (cycle 62938), `sw_zeroize=1`, `zeroize_reg=1`, `debug_unlock=0`, `ready_reg=1`, and the block hardware-clear inputs are high. `kv_read_data_present_reset=0`; `gen_hash_block_write_en`, `kv_src_write_en`, and the block write enables are all zero. At cycle 62939, with `reset_n=1`, the trace first samples the old block while ZEROIZE and `hwclr` remain high. In the same reported simulation time, `hwclr` and ZEROIZE fall, `ready_reg` is low, and `block_reg` changes from the digest input ending in `61626380` to all zero. The stability assertion then fails.

## Pinned RTL explanation

In pinned `src/sha512/rtl/sha512.sv` at commit `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`:

- `zeroize_reg` is driven by the software `SHA512_CTRL.ZEROIZE` bit or debug unlock.
- The sequential zeroize branch clears `ready_reg`.
- `SHA512_BLOCK[*].BLOCK.hwclr` is driven by `zeroize_reg | kv_read_data_present_reset`.
- `ERR_SHA_BLOCK_NOT_STABLE` asserts `$stable(block_reg)` and is disabled only for reset or `ready_reg` high; zeroize is not an exception in its guard.

The RTL intentionally clears the SHA input block during ZEROIZE. That clear and the ready transition happen at the same clock edge/time slot, so Verilator observes the block change as the assertion becomes active with `ready_reg=0`. The c339/Verilator disagreement is therefore an assertion sampling/guard issue around a legitimate ZEROIZE clear, not a firmware failure or an M10b AXI overlay defect. The assertion should account for ZEROIZE, but it was not changed because the M10b overlay is constrained to BFM handshake timing and preserves assertions and pass criteria.

The trace records the sampled signal values directly; the classification of the transition as a valid hardware clear follows from the pinned RTL assignments above. c339 reports PASS for the same selected row. The Verilator diagnostic terminates at the assertion and does not produce a firmware PASS result or final `mcycle`.

## Reproduction

The assertion-enabled diagnostic build and one-row run are archived in [`trace-run-1954-sha512-zeroize.tar.gz`](trace-run-1954-sha512-zeroize.tar.gz), SHA-256 `f7a1caf35bd44fec135effc588fc87cec28c122a98f0929ab18935b18931b3c0`. The trace-only source generator is [`add_sha512_trace.py`](add_sha512_trace.py); it verifies the pinned SHA512 source hash and adds read-only observers without modifying the assertion or RTL assignments. Result files passed their `FILE-SHA256SUMS` check before archival.
