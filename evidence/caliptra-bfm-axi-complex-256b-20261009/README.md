# Caliptra AXI complex 256-beat replay — 2026-10-09

The guarded `run_caliptra_axi_complex_bfm.sh` passed from a clean QD-BFM source
snapshot at `c8ce91584088cbdaa8d8f517d5ecc923f1fa4390`, with clean published
Icarus `main` `c339b9f2287a743aeb7ab6de6528e8d34a4dd602` and Caliptra RTL
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. The live `main` check is recorded
in [`live-icarus-main.txt`](live-icarus-main.txt). Each attempt retains its
Slurm script, tool/source hashes, output, and resource log.

Slurm job 94 passed the component regression, including 256-beat INCR write
and read traffic. It checks each payload word, WLAST/RLAST, response, ID, USER,
and B-response stability while stalled. The run also covered the existing
SRAM/FIFO paths, one-shot error range, recovery controls, randomized stalls,
and weighted delay distribution.

Job 94 requested 256 MiB and 1 CPU; it ran in 0.53 seconds with 17,536 KiB
maximum RSS and a 0.02 GiB maximum process-group footprint. Exit status was
zero.

The first attempt, job 93, exited 127 before simulation because the Icarus
runtime could not find `libz3.so.5.1`. Its log is retained separately. The
retry used the pinned toolchain dependency directory in `LD_LIBRARY_PATH` and
passed. Both attempts used the same clean source and simulator commits.

This is a module-level AXI complex BFM regression against Caliptra's real
interface types; it does not run Caliptra firmware or UVM.
