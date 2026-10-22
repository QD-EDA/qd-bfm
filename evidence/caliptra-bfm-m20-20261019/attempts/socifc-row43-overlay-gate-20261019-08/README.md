# SoC-IFC row 43 overlay gate, retry 8

One-row gate after retry 7 exposed the remaining generated empty $psprintf calls in three package configurations. The per-run overlay now applies the same exact-argument removal to those three generated files and preserves the existing soc_ifc_ctrl_pkg fix.

This gate also tests whether retry 7's wide-coverage diagnostic persists with 4 GiB available. Coverage transforms remain per-run only; no RTL, firmware, stimulus, expected values, assertions, or pass criteria change.

Source pin and c339 compiler are unchanged. Resources: 1 CPU / 4 GiB; runner timeout 1,800 seconds; Slurm limit 2,100 seconds. Submit only this row as the one-row gate before any wider rerun.

Job 3253 failed before Icarus compile in one second: the new loop variable `package` shadowed the existing `Path` variable used for later overlay paths. This is a runner setup error, not a row result. The failure archive SHA-256 is `583de4e98940916e5dde3aabc18e0bc6f40c51883a373197d30178464987340b`, matching the remote sidecar. The traceback, runner resource, job metadata, and empty Slurm output are saved under `raw/`.
