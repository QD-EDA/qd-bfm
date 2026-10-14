# AXI master cross-simulator parameter matrix — 2026-10-10

Slurm job 196 passed all nine AXI parameter configurations under both clean,
published Icarus main and Verilator 5.032: `DATA_WIDTH` 32/64/128 crossed with
`ID_WIDTH` 1/4/8. It also passed three Verilator memory-target regressions:
the main burst/boundary/stall/response/reset/exclusive test, reset at the
AR/R/AW/W/B handshakes with recovery, and bounded multi-ID read/write queues.

The run followed a Verilator failure in the 32-bit, 1-bit-ID matrix case. The
master now derives task success from the latched response and reports the ID
of the matched response slot. The prior failure log is retained alongside the
passing run. The matrix checks write success, response, USER, and transaction
ID through the public master interface.

## Provenance and limits

The QD source was based on commit
`16ae08093aff9e7b7e49f463bd014bad8f9b0a03`, with the master source change in
`source-patch.patch`. Icarus was clean published main
`c339b9f2287a743aeb7ab6de6528e8d34a4dd602`; Verilator was 5.032 (Debian
5.032-1). Verilator emitted non-fatal width and incomplete-case warnings and
was run with `-Wno-fatal`. This is two-state simulator parity evidence, not
four-state or full-top/UVMF qualification.

The job requested 1 CPU and 1 GiB, based on a prior 339,016 KiB MaxRSS for the
same Verilator target suite and additional headroom for the parameter builds.
`/usr/bin/time` measured 1:19.83 elapsed and 354,072 KiB MaxRSS. The memory
guard reported exit 0, 0.40 GiB maximum process-group use, and 13.46 GiB
minimum available memory; the group cap was 750,000,000 bytes with a 6 GB
system reserve.

## Artifacts

- [`logs/run.log`](logs/run.log): 21 passing regression markers and build output.
- [`logs/slurm-196.out`](logs/slurm-196.out): simulator revisions and guard result.
- [`logs/time.log`](logs/time.log): elapsed time, peak RSS, and exit status.
- [`logs/verilator-initial-job-190.out`](logs/verilator-initial-job-190.out)
  and [`logs/verilator-initial-32x1-failure.log`](logs/verilator-initial-32x1-failure.log):
  pre-fix failure evidence.
- [`job.sbatch`](job.sbatch) and [`run-regressions.sh`](run-regressions.sh):
  resource request and regression commands.
- [`source-revisions.txt`](source-revisions.txt),
  [`source-files.sha256`](source-files.sha256),
  [`source-archive.sha256`](source-archive.sha256), and
  [`source-patch.patch`](source-patch.patch): source and tool provenance.
