# SoC-IFC row 43 overlay gate, retry 9

Retry 8 stopped before compile due a Python loop variable shadowing the package Path. Retry 9 carries the corrected helper and adds per-run exact trailing-empty-argument overlays for cptra_ctrl_pkg, ss_mode_ctrl_pkg, and soc_ifc_status_pkg.

One-row gate after correction. Coverage transforms remain per-run only; no RTL, firmware, stimulus, expected values, assertions, or pass criteria change. Resources: 1 CPU / 4 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds.
