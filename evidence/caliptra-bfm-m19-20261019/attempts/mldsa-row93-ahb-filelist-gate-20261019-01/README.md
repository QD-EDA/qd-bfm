# Row 93 AHB pin-trace gate

Uses the verified M19 AHB observation helper that redirects exactly one per-run Icarus overlay filelist entry from the protected Adams Bridge `hdl_top.sv` to the instrumented runtime copy. The row97 gate must finish and confirm runtime markers before this row is submitted.

The helper's local archive self-check passed on row97 and will be repeated against the archived row93 output before staging. The trace is observation-only: no shared source, RTL, firmware, expected values, or pass criteria change.

- Source snapshot: `ce5ba73163820aea5c9c065f81bbd5758365f8fb0d78c5a2ca9949f300c2c284`.
- Icarus source pin: `cae035642e056644274a01e98e4422ce286685b4`; `iverilog` SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`.
- Intended resources: one CPU, 2 GiB, 3,600-second runner cap, 4,500-second Slurm limit.

## Terminal row93 result

Job 3157_93 completed FAIL in 1,560.735 seconds (compile and simulation exit 0; UVM_ERROR=16, UVM_FATAL=0). It emitted 46,436 trace lines. The archive `job-3157_93.tar.gz` SHA-256 is `8eb47addb8acfc4a510939ea81ccc17fd031390d1cfd1e376c16d3418926988e`; local checksum validation and archived manifest/filelist/VVP checks passed. See `row93-pin-analysis.txt`. The remote run tree was removed after evidence verification, freeing 121,779,059 bytes.
