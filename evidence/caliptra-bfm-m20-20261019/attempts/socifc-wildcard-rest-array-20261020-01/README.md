# SoC-IFC wildcard cohort remainder — current overlay gates

This array runs the remaining seven rows from the M19 fixed-array wildcard cohort (0–3, 43–45) with the same immutable runner and hash-guarded per-run overlay snapshot as the refreshed row-4 gate. It includes the exact wildcard-to-range translation and generated selector/callback/constructor/helper compatibility integration; pinned RTL, firmware, testcase intent, assertions, expected values, and pass criteria are unchanged.

The shared source-snapshot SHA-256 is `6256e558e67b1c18fa38770f199e6fa58f51d88cdb9206a3208cac28a71c5bc4`; the runner, focused tests, and selector-overlay helper hashes are checked in the Slurm script. Caliptra and Adams Bridge pins and the M20 Icarus source/binary hashes are also checked before execution.

Each task requests one CPU / 12 GiB with a 3,600-second runner cap and two-hour Slurm limit; the array throttle is one. The 12 GiB request is based on row 43's prior 8 GiB cap run with 8.38 GiB peak RSS. The array waits with `afterany:3286` for the refreshed row-4 gate to finish, then records one archive and SHA-256 sidecar per row. No row status changes until each terminal archive and verdict markers are copied and verified.

Submitted as array 3289 with dependency `afterany:3286`; remote root is `/home/dsell/slurm-runs/caliptra-bfm/a2/m20-socifc-wildcard-rest-array-20261020-01`. Submission and input hashes are recorded in `submission.txt`. No post-submission queue poll was performed.
