# M19 one-row trace helper

`m19_trace_runner.py` wraps the pinned M18 row runner and inserts an observation-only trace after generated testbench files are staged but immediately before Icarus compiles them. `M19_TRACE_KIND=queue` logs `data_valid_o`, `zeroize`, valid-sample count, and expected-queue depth at the authored checker boundary. `M19_TRACE_KIND=ahb` logs AHB pin values around reads in `0xd8–0x114`.

The helper refuses to patch unless the expected source file, signals, and unique insertion anchor are present. It records source and instrumented SHA-256 values in `m19_trace_manifest.json`. It does not change RTL, firmware, expected values, or pass criteria.

The archived row 69 checker confirms that `data_valid_o` pops `expected_results` on `posedge clk_tb`, while a separate `posedge zeroize` process clears the queue. The PRE `$display` shares the active event region with those processes, so same-edge queue depth can be ordering-dependent; use the underflow timestamp, both control signals, and settled POST `$strobe` depth together. A simultaneous underflow and zeroize alone does not prove whether an extra DUT valid pulse occurred.

Self-check: `py_compile` passed. The patch functions were applied to archived M18 source copies in a temporary directory: both row 69 `exp_mask_tb.sv` copies and one row 93 `hdl_top.sv` were patched, manifest entries were produced, and trace markers were verified.
