# EL2 overlay rerun, Slurm job 574

Pinned Caliptra `49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e` and Icarus c339
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602` were compiled on DAN-DESKTOP.
The run-local overlay removed the four obsolete zero-tied memory DFT ports
from `el2_veer_wrapper_tb`; source archives and pinned checkouts were not
modified.

The patch applied successfully. Compilation exited 24 after 1.67 seconds with
24 errors: two unconnected wrapper memory-export interfaces and 22 errors
resolving static members through interface continuous assignments. The pinned-
only local c339 compile has the same 22 static-member errors. Simulation did
not run. Scheduler job 574 completed; the array script requested one CPU, 3
GiB, a 6,900-second process timeout, and a two-hour Slurm limit. Peak compiler
RSS was 262,892 KiB.

Raw evidence: `compile.log`, `compile.resource`, `stage-status.txt`,
`runner-status.txt`, `provenance.txt`, `iverilog-version.txt`,
`tool-binaries.sha256`, `overlay-hashes.txt`, and `slurm-574_0.out` in this
directory. Remote run root:
`/home/dsell/slurm-runs/caliptra-bfm/a2/m4-env-overlay-c339-20261011-03`.
