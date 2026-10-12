# Intra-assignment delay in a `bit` clock generator

**Status:** This bit-versus-logic comparison is not a confirmed reproducer for the Caliptra row. Issue #545 is labeled `needs-repro`; keep the row `blocked-by-#545 (unconfirmed)` until a reducer from `caliptra_top_tb.sv:138` fails on pinned c339 and passes on Verilator. Treat the results below as historical pending that comparison.

`core_clk = #5ns ~core_clk;` is a blocking assignment with an intra-assignment timing control. IEEE 1800-2023 §9.4.5 (p. 237) defines the delay as postponing the assignment, and §10.4.1 (p. 251) includes `variable_lvalue = delay_or_event_control expression` in blocking-assignment syntax.

Pinned Icarus c339 rejects this reproducer at the `always` statement with `always process does not have any delay`; the same reducer passes in Verilator 5.051 with timing enabled. Changing `bit core_clk` to `logic core_clk = 1'b0` makes the reducer pass in c339, isolating the trigger to the 2-state `bit` variable.

The source, c339 compile failure and tool hashes are under `../iverilog-c339/clock-bit-results/`. Job 524 ran on DAN-DESKTOP with Icarus source revision `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. Verilator was run locally under `~/codex-supervisor/localrun`; its version and invocation are recorded in `verilator.txt`.
