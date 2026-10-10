# AXI outstanding read parameter matrix — 2026-10-09

The guarded `run_outstanding_depth_matrix.sh` passed all 27 combinations from
a clean QD-BFM checkout at `63283a712939e840f18c3d15bb1e22d1a8a8f457`, using
clean published Icarus `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
The run verified the Icarus commit is an ancestor of `origin/main`; a live
remote check returned the same `main` SHA. Source commits, file hashes,
simulator hashes and version, Slurm script, output, and resource measurement
are retained here.

The matrix crosses `DATA_WIDTH` 32, 64, and 128; `ID_WIDTH` 1, 4, and 8; and
`MAX_OUTSTANDING` 1, 2, and 4. Each configuration launches five queued read
tasks, checks the configured capacity, and verifies returned data and USER
metadata. At depths 2 and 4, the responder returns responses out of order across
IDs while preserving order for repeated IDs.

Slurm job 89 requested 1 GiB and 1 CPU. All 27 compile/simulation cases ran
serially in 0.53 seconds with 17,616 KiB maximum RSS; exit status was zero.

This covers the read side of the representative width/ID/outstanding matrix.
The concurrent write matrix and full Caliptra/UVMF qualification remain open.
