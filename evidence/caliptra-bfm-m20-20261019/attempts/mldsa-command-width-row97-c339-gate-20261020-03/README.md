# Row 97 corrected full gate — pinned M20 Icarus

This reruns row 97 with the combined predictor and sequence command-width overlay used by row 93. The source snapshot is SHA-256 `352fddead2b8fa45be98b6916b77cccb5f2cc0cc05e0ea5117a30d49fa154ef9`; the prior local exact-pin run compiled and wrote nonzero signature data but reached its 1,800-second cap before a testcase verdict.

The gate uses the established M20 Icarus source pin `cae035642e056644274a01e98d4422ce286685b4`, compiler SHA-256 `6f64b9987e04069dde9904cd1f0790d3430e34dbebb7908db159e6ec5290e330`, and VVP SHA-256 `979d745f46bf952c86b1f09255e2256a6eec2bbef15b5c11634c8b4c95013309`. It requests one CPU, 2 GiB, a 90-minute Slurm limit, and a 3,600-second runner cap; the memory request is 1.25x the prior measured peak RSS.

The full run completed `PASS` in 2,965.259 seconds with compile_exit=0 and sim_exit=0. The testcase pass marker was present, with no failure marker or UVM_ERROR/UVM_FATAL. It is recorded as `PASS_OVERLAY`; archive SHA-256 `f8cb5e5a58c954c30d0aaff4235271999865d39da9a88da518da8d95898b3641` matches the copied remote sidecar.

Submitted as job 3285 on 2026-10-20 03:36 UTC in `/home/dsell/slurm-runs/caliptra-bfm/a2/m20-mldsa-row97-c339-gate-20261020-03`. The job uses one CPU / 2 GiB and the 3,600-second runner cap. Submission and input hashes are recorded in `submission.txt`.
