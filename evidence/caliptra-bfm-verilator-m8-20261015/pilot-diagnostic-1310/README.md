# Verilator pilot diagnostic: job 1310

This is not a final comparison result. The 2-state model reached `* TESTCASE PASSED` and `Finished : minstret = 20314, mcycle = 60927`, matching the Icarus c339 mcycle for this test, but emitted 61,173 lines matched by the shared `scan_sim_log` error filter.

I independently checked every matched line: all contain the same `SVA ERROR: KV[0][0] debug flush failed` diagnostic, and none contains a different error signature. The message comes from the `$display` in the pinned upstream `caliptra_top_sva.sv` debug checker. The existing Icarus runner removes exactly that diagnostic print with its hash-pinned checker overlay; the underlying predicate and `return 1'b0` remain. This pilot model did not yet use that overlay, so the result is retained as a harness mismatch and is excluded from the final six-test table.

The comparison model was Verilator 5.052, SHA-256 `bd47c872d13d07ca1966a5bd6badb10120f470ab467fcb1fa9f0a55b378cd2f3`. The six-test run is being rebuilt with the same checker overlay used by the Icarus baseline.
