# SoC-IFC row 43 overlay gate, retry 11

Retry 10 applied the wide-coverage summary transform and reached the 6 GiB memory cap during compile before simulation (peak 6,288,236 KiB). This retry uses the same source-preserving testbench overlay with 8 GiB memory; the runner remains capped at 1,800 seconds and Slurm at 2,100 seconds.

The transform preserves the wide transaction coverage categories in compact summaries and leaves existing per-bit covergroups intact. It changes no RTL, firmware, stimulus, expected values, assertions, or pass criteria. One-row gate: row 43, pinned Caliptra source and Icarus c339.
