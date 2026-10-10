# AXI outstanding write parameter matrix — 2026-10-09

The guarded `run_write_outstanding_depth_matrix.sh` passed all 27 combinations
from a clean QD-BFM checkout at `368d64a8a9e3c42a5bf20c7ee3e6ee0f02304b18`,
using clean published Icarus `main`
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`. The run verified the Icarus
commit is an ancestor of `origin/main`; a live remote check returned the same
`main` SHA. Source commits, file hashes, simulator hashes and version, Slurm
script, output, and resource measurement are retained here.

The matrix crosses `DATA_WIDTH` 32, 64, and 128; `ID_WIDTH` 1, 4, and 8; and
`MAX_OUTSTANDING` 1, 2, and 4. Each configuration launches five concurrent
single-beat writes, checks manager capacity and AW/W payloads, holds W payload
stable through delayed WREADY, and routes BRESP/BUSER to the right caller. At
depths 2 and 4, the responder returns out of order across IDs while preserving
order for repeated IDs; caller 3 receives the expected SLVERR.

Slurm job 91 requested 1 GiB and 1 CPU. All 27 compile/simulation cases ran
serially in 0.53 seconds with 17,608 KiB maximum RSS; exit status was zero.

This is representative concurrent read/write parameter coverage, not the full
Caliptra/UVMF qualification matrix.
