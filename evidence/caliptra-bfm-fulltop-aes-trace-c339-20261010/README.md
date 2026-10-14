# Full-top AES trace A/B diagnostic

Run date: 2026-10-10. This evidence compares the selected short AES/DMA
firmware vector with and without the QD AXI VPI trace plugin.

Both runs use the same QD commit `53c44cf9fcffe4cde4f47e2d89accaae099ffbcf`,
clean published Icarus `c339b9f2287a743aeb7ab6de6528e8d34a4dd602`, UVM
submodule `78c06547a2a0a29b3dc9dcafae62b75b2ff61544`, and Caliptra commit
`49370266d12cb0c4a8f71b3a0ff7e54ba7d4866e`. Both compile with the native AXI
checker and select the short AES/DMA firmware vector at zero-based index 6.
Both are diagnostic runs: fast TRNG, automatic `.data`/`.bss` preload, one
AES vector, and skipped PQ-vector generation.

| Run | Slurm result | Simulation result |
| --- | --- | --- |
| Job 210, `--trace-axi` | Failed after about 5:11 | VVP exited `-11` (SIGSEGV); no pass/fail marker or normal finish. The last trace checkpoint is cycle 2200. Trace plugin SHA-256: `4b0f17e660ec38d239b2f36d0d3a1d8da10052f9153d980d676e4e24d0e5b7f6`. |
| Job 213, no `--trace-axi` | Completed, exit 0, 11:07 Slurm elapsed | VVP exited 0; one pass marker, zero fail markers, zero JTAG errors, normal finish at `minstret=1666`, `mcycle=4435`. Peak runner RSS was 1,860,440 kB. |

The A/B result implicates the trace-enabled path for vector index 6, but does
not yet distinguish a bug in `sim-axi-trace-vpi.c` from an Icarus VPI
interaction. The same trace source SHA-256
`cf378ed88ab6c3ec39fd38d3767d64a5598ad05a7afee63e90b5799743e09ae5` has
already passed traced vectors 7–11 on this Icarus and Caliptra revision (see
[`prior traced-vector evidence`](../caliptra-bfm-fulltop-aes-trace-fix-20261010/README.md)).
That makes the failure case-specific; the root cause remains open. The passing
run does not qualify stock firmware or the full AES suite because it uses the
diagnostic boot, TRNG, and vector-selection options above. No simulator source
was changed.

The traced run's original files are in this directory. The no-trace run's
captured files, Slurm status, command, and resource record are in [`no-trace/`](no-trace/).
`SHA256SUMS` covers both sets of retained artifacts.
