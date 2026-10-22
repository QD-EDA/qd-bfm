# Row 97 full-clock AHB pin-trace gate

The previous gate proved the compiler hook executes and created its manifest, but its transaction trigger emitted no runtime lines. The exact select/transfer/address predicate did not match, so that run is a trace-tool miss, not evidence about pins.

This variant records pre- and post-edge AHB select, transfer, address, direction, ready, and read-data pins on every `hdl_top.clk` rising edge. It is observation-only and changes no RTL, firmware, expected values, or pass criteria. One-row row97 gate first; use the same trace only for row93 after runtime markers are confirmed.

- Source snapshot: `ce5ba73163820aea5c9c065f81bbd5758365f8fb0d78c5a2ca9949f300c2c284`.
- Icarus source pin: `cae035642e056644274a01e98d4422ce286685b4`; binary SHA-256: `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`.
- Prior run: job 3147, FAIL in 820.529 s, one UVM_ERROR, no pin lines; complete archive SHA-256 `41a3a69ea351800f55f8fc79e7c55803ea402d85ad3f730c7d0e8a668c61f841`.

Append job ID, trace counts, terminal verdict, and cleanup size after completion.
