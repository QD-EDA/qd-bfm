# AXI width and ID parameter matrix — 2026-10-09

The guarded `run_parameter_matrix.sh` passed all nine configurations from a
clean QD-BFM checkout at `57aff65558d0c19dfa9a6aad5d4123f14659d1bd`, using
clean published Icarus `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`.
The Icarus source checkout was clean and contained that commit in `origin/main`;
a live remote check returned the same `main` SHA. Source-file and simulator
hashes, the tool version, Slurm script, raw output, and resource measurement
are retained here.

The 3×3 matrix crosses `DATA_WIDTH` 32, 64, and 128 with `ID_WIDTH` 1, 4, and
8. Each configuration exercises a 48-bit address interface, an unaligned
INCR write/read with byte-lane checking, a four-beat WRAP write/read, USER
propagation, and response-ID capture through the manager, checker, and SRAM
subordinate.

Slurm job 77 requested 1 GiB and 1 CPU. The nine compile/simulation cases ran
serially in 0.28 seconds with 17,684 KiB maximum RSS; exit status was zero.

This is representative parameter coverage, not every supported width, ID,
outstanding-depth, simulator, or Caliptra/UVMF configuration.
