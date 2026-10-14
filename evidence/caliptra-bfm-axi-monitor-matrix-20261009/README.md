# AXI monitor width and ID matrix — 2026-10-09

The guarded `run_parameter_matrix.sh` passed all nine configurations from a
clean QD-BFM checkout at `ce6dcc47c9a993e893a20d0d22aa9960985d3bf9`, using
clean published Icarus `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
The run verified the Icarus commit is an ancestor of `origin/main`; a live
remote check returned the same `main` SHA. The source commits, file hashes,
simulator hashes and version, Slurm script, output, and resource measurement
are retained here.

The matrix crosses `DATA_WIDTH` 32, 64, and 128 with `ID_WIDTH` 1, 4, and 8.
Every configuration exercises unaligned INCR and four-beat WRAP traffic through
the manager, checker, SRAM subordinate, and passive channel monitor. The test
asserts accepted AW/W/B/AR/R counts of 2/6/2/6/6, two WLAST and RLAST beats,
one INCR and one WRAP burst on each address channel, and two partial W strobes.

Slurm job 79 requested 1 GiB and 1 CPU. The nine compile/simulation cases ran
serially in 0.28 seconds with 17,520 KiB maximum RSS; exit status was zero.

This is representative monitor parameter coverage, not the full supported
width, ID, outstanding-depth, simulator, or Caliptra/UVMF qualification matrix.
