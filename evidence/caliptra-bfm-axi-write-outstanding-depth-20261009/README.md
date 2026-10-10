# AXI manager write outstanding-depth matrix — 2026-10-09

The guarded `run_write_outstanding_depth_matrix.sh` passed with
`MAX_OUTSTANDING` set to 1, 2, and 4 from a clean QD-BFM checkout at
`52266c0cb9116b9bbb2d34c39d762cbe657580d9`. It used clean published Icarus
`main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; the run checked that commit
was an ancestor of `origin/main`, and a live remote check returned the same
`main` SHA. Source and simulator hashes, version, Slurm script, output, and
resource measurement are retained here.

Each depth launches five single-beat writes, verifies the manager stays within
capacity, holds W payload stable during the target's delayed WREADY, and routes
responses by BID and BUSER. Responses arrive in reverse order across distinct
IDs; caller 3 receives the expected SLVERR.

Slurm job 90 requested 1 GiB and 1 CPU. All three compile/simulation cases ran
serially in 0.28 seconds with 17,560 KiB maximum RSS; exit status was zero.

This covers write concurrency at representative depths with 32-bit data and
8-bit IDs. The concurrent write width/ID cross-product and full Caliptra/UVMF
qualification remain open.
