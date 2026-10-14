# AXI memory-subordinate Verilator parity — 2026-10-10

Slurm job 189 passed all three directed memory-subordinate cases under
Verilator 5.032 from QD commit `bdc69ea2f7ae0de3f15f038928abff0bedecf77c`:

- Main burst, boundary, stalls, response, reset, and exclusive-access test.
- Reset at AR/R/AW/W/B handshakes and recovery.
- Bounded multi-ID read/write queue ordering and backpressure.

The source tree and simulator remained unchanged. Verilator emitted non-fatal
width and incomplete-case warnings; the run used `-Wno-fatal`, so this is
runtime parity evidence, not warning-free lint. Verilator is two-state, so the
run does not qualify X/Z behavior.

## Resources and provenance

The job requested 1 CPU and 1 GiB. `/usr/bin/time` measured 17.65 seconds and
339,016 KiB maximum RSS; the process-group guard measured a 0.39 GiB peak and
16.11 GiB minimum available memory, preserving the configured 6 GB reserve.
The process-group guard cap was 750,000,000 bytes. The exact source archive and
input hashes are recorded in `source-archive.sha256` and
`source-files.sha256`.

## Artifacts

- [`run.log`](logs/run.log): Verilator build output and three PASS markers.
- [`slurm-189.out`](logs/slurm-189.out): source revision, Verilator version,
  guard result, and command exit.
- [`time.log`](logs/time.log): elapsed time, peak RSS, and process status.
- [`job.sbatch`](job.sbatch) and [`run-regressions.sh`](run-regressions.sh):
  reproducible job and test commands.
- [`source-revisions.txt`](source-revisions.txt) and
  [`source-files.sha256`](source-files.sha256): source provenance.
