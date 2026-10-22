# Row 97 AHB pin-trace filelist gate

The previous full-clock trace patched the per-run `runtime/hdl_top.sv`, but the generated Icarus overlay filelist still compiled the protected shared Adams Bridge `hdl_top.sv`. This gate redirects the single per-run filelist source entry to the instrumented runtime copy; no shared source is modified.

The helper records SHA-256 for the source filelist and rewritten filelist in `m19_trace_manifest.json`, and checks that exactly one source entry was replaced and now points to the patched file. A local self-check against archived row97 inputs passed. It confirmed one runtime entry, the original shared entry removed, two trace markers present, and distinct before/after filelist hashes.

The trace displays pre-edge and post-edge AHB select, transfer, address, direction, ready, and read-data values on every `hdl_top.clk` rising edge. It changes no RTL, firmware, expected values, or pass criteria. Run only row97 as the gate; proceed to row93 only if the compiled simulation emits the markers.

- Source snapshot: `ce5ba73163820aea5c9c065f81bbd5758365f8fb0d78c5a2ca9949f300c2c284`.
- Icarus source pin: `cae035642e056644274a01e98e4422ce286685b4`; `iverilog` SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`.
- Resources: one CPU, 2 GiB, 3,600-second runner cap, 4,500-second Slurm limit.

Append the job ID, runtime marker count, terminal verdict, archive checksum, and remote cleanup size after completion.

## Terminal gate result

Job 3154_97 completed FAIL in 794.798 seconds (compile and sim exit 0; UVM_ERROR=1, UVM_FATAL=0). It emitted 27,356 PRE/POST trace lines. The archive `job-3154_97.tar.gz` SHA-256 is `42718028825c11bc01e1d6fbfdeced293a83facfa6c6fb21bdef80122898de2b`; local checksum validation and archived manifest/filelist/VVP checks passed. The row97 result and pin analysis are recorded in `row97-pin-analysis.txt`. The remote run tree was deleted after verification, freeing 120,396,749 bytes.
