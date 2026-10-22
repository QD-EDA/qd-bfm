# Row 64 diagnostic trace

Temporary instrumented copy of the generated `compress_tb` overlay from row64 attempt 02. It adds only counters/prints for read requests, buffer stalls, and API writes; the pinned RTL, input vector generation, expected formula, and pass criteria are unchanged. Used to identify why the address-driven memory model gate did not capture the expected stream.

The run uses the same staged Adams Bridge pin and locally built Icarus source pin as the row gate. The debug copy is diagnostic only and is not a row result. See `raw/compile.log`, `raw/sim.log`, and the first-failure archive in the row64 attempt for the uninstrumented result.
