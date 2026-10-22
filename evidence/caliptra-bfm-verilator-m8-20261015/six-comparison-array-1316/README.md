# Six Icarus-PASS comparisons: Icarus c339 vs Verilator 2-state

The corrected Verilator model passed all six selected firmware cases. Each
case has exactly the same final mcycle as the pinned Icarus c339 baseline; the
scanner found one pass marker, no fail markers, and no bad or JTAG diagnostics.
The table in `summary.tsv` records both wall times and each case's speedup.
Across the six tests, per-case speedup ranges from 202.57x to 245.50x (mean
222.61x; ratio of total Icarus time to total Verilator time 221.18x).

Array job 1316 used 1 CPU and 3 GiB per task with a four-task throttle. Tasks
1–5 all ended PASS; task 0 was the separate pilot job 1315_0, also PASS. Each
task's full `result.json`, simulator log, firmware log, resource report, and
native-vector logs are retained under `results/`; Slurm task stdout is under
`logs/`. The six-case input and complete submission details are stored one
level up.

All simulations ran on DAN-DESKTOP using Verilator 5.052 model SHA-256
`b6ee29ade1b17547c4b31692ed9a0b48e22031c4551604fd9dc250a81e01ae79`, built
from the pinned QD-BFM source with the checker overlay documented in
`../top-build-1311-checker-success/README.md`. The 4-state comparison remains
separate and will be recorded after evaluating the experimental mode.
