# Row 4 SoC-IFC wildcard-coverage gate — generated-selector overlay

This is a fresh row-4 gate using the latest runner integration for the per-run generated case-selector, callback, constructor, and no-result-helper compatibility overlay. The previous gate, job 3276, used the older runner snapshot and stopped at generated lock-callback syntax before simulation. The new source snapshot replaces only the runner, its focused tests, and the new hash-guarded selector helper in the prior source bundle; Caliptra sources remain pinned and untouched.

Source snapshot SHA-256: `6256e558e67b1c18fa38770f199e6fa58f51d88cdb9206a3208cac28a71c5bc4`. The gate uses Caliptra pin `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and M20-pinned Icarus `cae035642e056644274a01e98d4422ce286685b4` (`iverilog` SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`, `vvp` SHA-256 `979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309`). It requests one CPU, 12 GiB, a two-hour Slurm limit, and a 3,600-second runner cap; 12 GiB is 1.25x the prior observed 8.38 GiB compile peak.

The corrected runner suite previously passed 85 tests, including two focused filelist checks. No row classification changes until the terminal result archive, markers, and SHA-256 sidecar are verified.

Submitted as job 3286 with dependency `afterany:3285`, so it starts after the longer row-97 gate ends. It requests one CPU / 12 GiB; scheduler status is not being polled. Submission and input hashes are in `submission.txt`.
